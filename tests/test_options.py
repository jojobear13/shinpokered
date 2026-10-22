"""The OPTION screen (engine/menu/options.asm): pages of options, each with a
two-line explanation. Every option starts as the original game played, the
values cycle, the explanations fit their box, and the options that are event
flags survive NEW GAME."""

import unittest

from harness import shared_game

OPT_LENGTH = 12

# the value each option shows after InitOptions on a new save (None: none)
DEFAULTS = [
    ["MEDIUM", "ON", "SHIFT", "MONO", "OFF", None],  # GAME
    ["30", "GEN 1", "OFF", "OFF", "OFF", "OFF", "OFF"],  # DISPLAY
    ["OFF"] * 6 + ["ON"],  # CHALLENGE (BADGE BOOST, Gen 1's, is on)
    ["OFF"] * 4,  # CLAUSES
    ["OFF"] * 5,  # EXTRAS
    ["OFF"] * 5,  # RANDOMIZER
    ["OFF"] * 7,  # RANDOM #MON
]
RANDOMIZER = 5
RANDOM_MONS = 6
DOORS, KEYS, ITEMS, MARTS = 1, 2, 4, 8  # wRandoFlags


def decode(data):
    text = ""
    for b in data:
        if 0x80 <= b <= 0x99:
            text += chr(ord("A") + b - 0x80)
        elif 0xF6 <= b <= 0xFF:
            text += chr(ord("0") + b - 0xF6)
        elif b == 0x7F:
            text += " "
        else:
            text += {0xE8: ".", 0xE3: "-", 0xDE: ":L"}.get(b, "?")
    return text


class OptionsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        for i in range(0x100 // 8, 0xA00 // 8):  # every event flag but the story's first
            g.poke(f"wEventFlags+{i}", 0)
        g.poke("wDisplayOptions", 0)
        g.poke("wRandoFlags", 0)
        g.poke("wOptionsInGame", 0)
        g.call("InitOptions")

    def string(self, address, limit=40):
        bank = self.game.bank("OptionPages")
        out = []
        for i in range(limit):
            b = self.game.peek((bank if address < 0x8000 else 0, address + i))
            if b == 0x50:
                return out
            out.append(b)
        self.fail("unterminated string")

    def options(self, page):
        g = self.game
        g.poke("wOptionsPage", page)
        count = g.call("GetOptionCount")["a"]
        return [g.call("GetOptionEntry", a=i)["hl"] for i in range(count)]

    def value(self, entry):
        result = self.game.call("GetOptionValueName", hl=entry, max_frames=100)
        if result["f"] & 0x80:  # z: no value
            return None
        return decode(self.string(result["de"]))

    def test_defaults(self):
        g = self.game
        self.assertEqual(g.peek("wOptions"), 3)  # MEDIUM text, the rest off
        self.assertEqual(g.peek("wUnusedD721"), 1 << 3)  # trainers don't switch with thought
        for page, expected in enumerate(DEFAULTS):
            self.assertEqual([self.value(e) for e in self.options(page)], expected, page)

    def test_explanations_fit(self):
        """Two lines of at most 18 letters ("#" prints as POKé's 4)."""
        g = self.game
        bank = g.bank("OptionPages")
        for page in range(len(DEFAULTS)):
            for entry in self.options(page):
                help_text = g.peek((bank, entry + 2), 2)
                text = self.string(help_text[0] | help_text[1] << 8)
                lines = [[]]
                for b in text:
                    if b == 0x4E:
                        lines.append([])
                    else:
                        lines[-1].append(b)
                self.assertEqual(len(lines), 2)
                for line in lines:
                    self.assertLessEqual(sum(4 if b == 0x54 else 1 for b in line), 18, decode(line))

    def change(self, entry, value):
        self.game.call("SetOptionValue", a=value, hl=entry, max_frames=100)

    def test_text_speed(self):
        g = self.game
        speed = self.options(0)[0]
        for value, name, delay in [(0, "INST.", 0), (1, "FAST", 1), (3, "SLOW", 5), (2, "MEDIUM", 3)]:
            self.change(speed, value)
            self.assertEqual(g.peek("wOptions") & 7, delay)
            self.assertEqual(self.value(speed), name)

    def test_random_wild(self):
        g = self.game
        wild = self.options(RANDOM_MONS)[1]
        events = g.addr("wEventFlags")
        for value, name, flags in [(1, "TIER", (0, 1)), (2, "FULL", (1, 1)), (3, "AREA", (0, 0)), (0, "OFF", (0, 0))]:
            self.change(wild, value)
            full = g.peek(events + 0x8D7 // 8) >> (0x8D7 % 8) & 1  # EVENT_8D7
            randomized = g.peek(events + 0x8DE // 8) >> (0x8DE % 8) & 1  # EVENT_8DE
            self.assertEqual((full, randomized), flags)
            self.assertEqual(self.value(wild), name)

    def test_bit_options_toggle(self):
        g = self.game
        hard = self.options(2)[0]
        self.change(hard, 1)
        self.assertEqual(g.peek("wOptions"), 3 | 1 << 3)
        self.assertEqual(self.value(hard), "ON")
        switching = self.options(2)[1]
        self.change(switching, 0)
        self.assertEqual(g.peek("wUnusedD721"), 0)
        self.assertEqual(self.value(switching), "ON")

    def test_badge_boost_off(self):
        g = self.game
        boost = self.options(2)[6]
        events = g.addr("wEventFlags")
        self.change(boost, 1)
        self.assertEqual(self.value(boost), "OFF")
        self.assertEqual(g.peek(events + 0x8D2 // 8) >> (0x8D2 % 8) & 1, 1)  # EVENT_NO_BADGE_BOOSTS
        self.change(boost, 0)
        self.assertEqual(self.value(boost), "ON")

    def test_level_cap_shows_the_cap(self):
        g = self.game
        cap = self.options(2)[2]
        self.change(cap, 1)
        self.assertRegex(self.value(cap), r"^:L\d+$")

    def test_randomizer_choices(self):
        g = self.game
        doors, keys, items, marts = self.options(RANDOMIZER)[:4]
        self.change(items, 1)
        self.change(marts, 1)
        self.assertEqual(g.peek("wRandoFlags"), ITEMS | MARTS)
        # shuffled doors need shuffled key items, both ways
        self.change(doors, 1)
        self.assertEqual(g.peek("wRandoFlags"), DOORS | KEYS | ITEMS | MARTS)
        self.change(keys, 0)
        self.assertEqual(g.peek("wRandoFlags"), ITEMS | MARTS)
        self.change(keys, 1)
        self.assertEqual(g.peek("wRandoFlags"), KEYS | ITEMS | MARTS)
        self.assertEqual([self.value(e) for e in (doors, keys, items, marts)], ["OFF", "ON", "ON", "ON"])

    def test_randomizer_locked_in_game(self):
        g = self.game
        g.skip_sound_waits()
        g.poke("wOptionsInGame", 1)
        for entry in self.options(RANDOMIZER) + self.options(RANDOM_MONS):
            self.change(entry, 1)
        self.assertEqual([g.peek(f) for f in ("wRandoFlags", "wRandoFlags2", "wRandoFlags3")], [0, 0, 0])

    def test_random_mon_fields(self):
        g = self.game
        starters, wild, trainers, special, tm_moves, compat, learn = self.options(RANDOM_MONS)
        for entry, value, name in [(starters, 2, "TYPES"), (trainers, 2, "ALL"), (special, 1, "ON"),
                                   (tm_moves, 1, "ON"), (compat, 3, "FULL"), (learn, 3, "METRONOME"),
                                   (wild, 3, "AREA")]:
            self.change(entry, value)
            self.assertEqual(self.value(entry), name)
        self.assertEqual(g.peek("wRandoFlags2"), 2 | 1 << 2 | 1 << 4 | 1 << 5)
        self.assertEqual(g.peek("wRandoFlags3"), 1 | 3 << 1 | 3 << 3)
        self.change(trainers, 1)
        self.assertEqual(self.value(trainers), "ON")
        self.assertEqual(g.peek("wRandoFlags2") & 1 << 4, 0)
        events = g.addr("wEventFlags")
        self.assertTrue(g.peek(events + 0x8D8 // 8) & 1 << (0x8D8 % 8))

    def test_rules_survive_new_game(self):
        g = self.game
        bank, base = g.bank("RuleFlags"), g.addr("RuleFlags")
        count = (g.addr("RuleFlagsEnd") - base) // 3
        flags = [g.peek((bank, base + 3 * i), 3) for i in range(count)]
        for lo, hi, mask in flags:
            address = lo | hi << 8
            g.poke(address, g.peek(address) | mask)
        g.call("SaveRuleFlags")
        for lo, hi, mask in flags:
            g.poke(lo | hi << 8, 0)
        g.call("RestoreRuleFlags")
        for lo, hi, mask in flags:
            self.assertTrue(g.peek(lo | hi << 8) & mask)


if __name__ == "__main__":
    unittest.main()
