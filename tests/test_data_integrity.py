"""Whole-game data checks (verification plan, phase 1).

Trainer parties are read by the game's own ReadTrainer, so the check covers
the data as built, with Shin's special movesets, held items and the trainer
options: every party has the species and levels its source line gives, and
every mon has real moves and no move twice. Shin's two MISSINGNO superboss
parties (level 128) are the only mons outside the 151 or above level 100.
Level scaling raises a party to the player's level plus up to 3 (6 for a
boss), so a level 100 team meets trainers up to level 106.
"""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game

MON_SIZE = 44  # wEnemyMon2 - wEnemyMon1


def _consts(filename):
    values = {}
    for line in open(os.path.join(REPO_ROOT, "constants", filename)):
        m = re.match(r"\s*const (\w+)\s*; \$?([0-9A-Fa-f]+)", line)
        if m:
            values[m.group(1)] = int(m.group(2), 16)
    return values


ALL_SPECIES = _consts("pokemon_constants.asm")
SPECIES = {k: v for k, v in ALL_SPECIES.items() if not k.startswith("MISSINGNO")}
MOVES = _consts("move_constants.asm")
NUM_ATTACKS = MOVES["STRUGGLE"]

EVENTS = {  # Shin's trainer options
    "ALT_MOVES": 0x8C9, "RANDOM_TRAINERS": 0x8D8, "MIRROR_MATCH": 0x8DF,
    "RANDOM_ROSTER": 0x90A, "SCALING": 0x90C, "RANDOM_ROSTER3": 0x90D,
}


def trainer_parties():
    """[(class number, trainer number, [(level, species name)])] from the
    source, in TrainerDataPointers order."""
    text = open(os.path.join(REPO_ROOT, "data", "trainer_parties.asm")).read()
    table = text.split("TrainerDataPointers:", 1)[1].split("\n\n", 1)[0]
    order = re.findall(r"\tdw (\w+)", table)
    blocks = {}
    label = None
    for line in text.splitlines():
        m = re.match(r"^(\w+Data):", line)
        if m:
            label = m.group(1)
            blocks[label] = []
            continue
        m = re.match(r"^\tdb (.*?),\s*0\s*(;.*)?$", line)
        if label and m:
            items = [x.strip() for x in m.group(1).split(",")]
            if items[0] == "$FF":
                mons = [(int(items[i]), items[i + 1]) for i in range(1, len(items), 2)]
            else:
                mons = [(int(items[0]), s) for s in items[1:]]
            blocks[label].append(mons)
    out = []
    for cls, label in enumerate(order, 1):
        for no, mons in enumerate(blocks.get(label, []), 1):
            out.append((cls, no, mons))
    return out


PARTIES = trainer_parties()


class TrainerPartyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        g.skip_delays()
        for event in EVENTS.values():
            self.set_event(event, False)
        g.poke("wLinkState", 0)

    def set_event(self, event, on):
        g = self.game
        address = f"wEventFlags+{event // 8}"
        g.poke(address, g.peek(address) & ~(1 << event % 8) | on << event % 8)

    def read(self, cls, no):
        g = self.game
        g.poke("wTrainerClass", cls)
        g.poke("wTrainerNo", no)
        g.call("ReadTrainer", max_frames=200)
        count = g.peek("wEnemyPartyCount")
        mons = []
        for i in range(count):
            base = f"wEnemyMon1Species+{i * MON_SIZE}"
            mons.append({
                "species": g.peek(base),
                "level": g.peek(f"wEnemyMon1Level+{i * MON_SIZE}"),
                "moves": [g.peek(f"wEnemyMon1Moves+{i * MON_SIZE + k}") for k in range(4)],
                "item": g.peek(f"wEnemyMon1CatchRate+{i * MON_SIZE}"),
            })
        return mons

    def check_mon(self, where, mon, max_level=100):
        if mon["species"] == ALL_SPECIES["MISSINGNO_B5"] and mon["level"] == 128:
            return  # Shin's superboss
        self.assertIn(mon["species"], SPECIES.values(), where)
        self.assertTrue(1 <= mon["level"] <= max_level, (where, mon["level"]))
        moves = [m for m in mon["moves"] if m]
        self.assertTrue(moves, (where, "no moves"))
        self.assertEqual(mon["moves"][:len(moves)], moves, (where, "gap in moves", mon["moves"]))
        for m in moves:
            self.assertTrue(1 <= m <= NUM_ATTACKS, (where, "move", m))
        self.assertEqual(len(moves), len(set(moves)), (where, "repeated move", mon["moves"]))

    def test_source_parsed(self):
        self.assertGreater(len(PARTIES), 300)

    def test_every_party_as_written(self):
        for cls, no, mons in PARTIES:
          with self.subTest(trainer=(cls, no)):
            got = self.read(cls, no)
            where = (cls, no)
            self.assertEqual([(m["level"], m["species"]) for m in got],
                             [(lv, ALL_SPECIES[s]) for lv, s in mons], where)
            for mon in got:
                self.check_mon(where, mon)

    def test_every_party_with_alt_moves(self):
        self.set_event(EVENTS["ALT_MOVES"], True)
        for cls, no, mons in PARTIES:
          with self.subTest(trainer=(cls, no)):
            got = self.read(cls, no)
            self.assertEqual([m["species"] for m in got], [ALL_SPECIES[s] for _, s in mons], (cls, no))
            for mon in got:
                self.check_mon((cls, no, "alt moves"), mon)

    def test_special_move_already_known_swaps_slots(self):
        # Bruno's first Onix: Rock Slide, Screech, Slam, Dig, as Shin wrote
        # it. Its Gen 9 learnset gives it DIG by 53, and with SLAM written
        # over that slot the moves are still four different ones
        bruno = next(cls for cls, no, mons in PARTIES if mons and mons[0] == (53, "ONIX"))
        onix = self.read(bruno, 1)[0]
        self.assertEqual(onix["moves"], [MOVES["ROCK_SLIDE"], MOVES["SCREECH"], MOVES["SLAM"], MOVES["DIG"]])

    def set_party_levels(self, level):
        g = self.game
        g.poke("wPartyCount", 6)
        g.poke("wStartBattleLevels", *[level] * 6)
        g.poke("wPartyMon1Level", level)

    def test_every_party_scaled_and_randomized(self):
        for option, level, max_level in (("SCALING", 50, 100), ("SCALING", 100, 106),
                                         ("RANDOM_TRAINERS", 50, 100)):
            self.set_party_levels(level)
            self.set_event(EVENTS[option], True)
            self.set_event(EVENTS["ALT_MOVES"], level == 100)
            for cls, no, mons in PARTIES:
              with self.subTest(trainer=(cls, no), option=option, level=level):
                got = self.read(cls, no)
                self.assertTrue(got, (cls, no, option))
                for mon in got:
                    self.check_mon((cls, no, option, level), mon, max_level)
            self.set_event(EVENTS[option], False)


if __name__ == "__main__":
    unittest.main()


class RomTableTest(unittest.TestCase):
    """The game's own tables, read from the built ROM."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def rom(self, bank, addr, n=1):
        g = self.game
        if addr < 0x4000:
            bank = 0
        return [g.memory[bank, addr + i] for i in range(n)]

    def word(self, bank, addr):
        lo, hi = self.rom(bank, addr, 2)
        return lo | hi << 8

    def table(self, name):
        return self.game.bank(name), self.game.addr(name)

    def test_wild_tables(self):
        bank, table = self.table("WildDataPointers")
        end = self.game.addr("WildDataLabelEnd") if "WildDataLabelEnd" in self.game.symbols else None
        maps = 0
        for i in range(256):
            ptr = self.word(bank, table + 2 * i)
            if ptr == 0xFFFF or (end and table + 2 * i >= self.game.addr("NoMons")):
                break
            maps += 1
            addr = ptr
            for kind in ("grass", "water"):
                rate = self.rom(bank, addr)[0]
                addr += 1
                if not rate:
                    continue
                for slot in range(10):
                    level, species = self.rom(bank, addr, 2)
                    addr += 2
                    with self.subTest(map=i, kind=kind, slot=slot):
                        self.assertIn(species, SPECIES.values())
                        self.assertTrue(1 <= level <= 100, level)
        self.assertGreater(maps, 200)

    def test_marts(self):
        g = self.game
        bank, table = self.table("MartInventories")
        n = 0
        while True:
            ptr = self.word(bank, table + 2 * n)
            if not (0x4000 <= ptr < 0x8000) or ptr == table + 2 * n:
                break
            count = self.rom(bank, ptr)[0]
            items = self.rom(bank, ptr + 1, count + 1)
            with self.subTest(mart=n):
                self.assertEqual(items[-1], 0xFF, "count doesn't match the list")
                for item in items[:-1]:
                    self.assertIn(item, ITEM_IDS)
                    if item < ITEMS["HM_01"] and item != ITEMS["BICYCLE"]:  # the bike shop's own script
                        p = self.rom(self.game.bank("ItemPrices"), self.game.addr("ItemPrices") + 3 * (item - 1), 3)
                        self.assertNotEqual(p, [0, 0, 0], f"item {item:#x} has no price")
            n += 1
            if self.word(bank, table + 2 * n) <= ptr and n > 1:
                break
        self.assertEqual(n, 17)

    def test_trades(self):
        bank, table = self.table("TradeMons")
        for i in range(10):
            give, get, _ = self.rom(bank, table + 14 * i, 3)
            nick = self.rom(bank, table + 14 * i + 3, 11)
            with self.subTest(trade=i):
                self.assertIn(give, SPECIES.values())
                self.assertIn(get, SPECIES.values())
                self.assertIn(0x50, nick)

    def test_evolutions(self):
        bank, table = self.table("EvosMovesPointerTable")
        for index in range(1, 191):
            name = [k for k, v in ALL_SPECIES.items() if v == index][0]
            if name.startswith("MISSINGNO"):
                continue
            addr = self.word(bank, table + 2 * (index - 1))
            with self.subTest(species=name):
                while True:
                    kind = self.rom(bank, addr)[0]
                    if kind == 0:
                        break
                    if kind == 2:  # EV_ITEM: item, minimum level, species
                        item, level, species = self.rom(bank, addr + 1, 3)
                        self.assertIn(item, ITEM_IDS)
                        addr += 4
                    else:  # EV_LEVEL or EV_TRADE: level, species
                        self.assertIn(kind, (1, 3))
                        level, species = self.rom(bank, addr + 1, 2)
                        addr += 3
                    self.assertIn(species, SPECIES.values())
                    self.assertTrue(1 <= level <= 100, level)


ITEMS = _consts("item_constants.asm")
ITEM_IDS = set(ITEMS.values())


class SaveLayoutTest(unittest.TestCase):
    """What this fork keeps between sessions is in the saved, checksummed
    block (wMainDataStart up to wMainDataEnd); what it adds at the end of
    WRAM stays clear of the stack's 256 bytes below $e000."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_kept_data_is_saved(self):
        g = self.game
        start, end = g.addr("wMainDataStart"), g.addr("wMainDataEnd")
        for name in ("wTMsOwned", "wDisplayOptions", "wDayCareEggReady", "wEggStepCounter",
                     "wTypeChartSeen", "wLastRepelUsed", "wDayCareInUse"):
            with self.subTest(name=name):
                self.assertTrue(start <= g.addr(name) < end)

    def test_wram_clear_of_the_stack(self):
        g = self.game
        last = max(addr for name, (bank, addr) in g.symbols.items()
                   if 0xC000 <= addr < 0xE000 and name != "wStack" and "." not in name)
        self.assertLess(last, 0xDF00, hex(last))
