"""Breeding and eggs, as from Gen 6 (design brief, cleanup after the Gen 9
pass).

The day care's two mons make an egg if one is a Ditto and the other can breed,
or they're a male and a female sharing an egg group; the chance each 256-step
cycle depends on species and original trainer. The egg is the first of the
mother's line (the non-Ditto parent's), at level 1, with its level 1 moves,
the learnset moves both parents know and the egg moves either knows; three
IVs from the parents; the mother's ability slot 80% of the time; an
Everstone holder's nature. It hatches after its egg cycles in the party."""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game
from test_held_items import ITEMS, _hram
from test_moves_screen import MOVES, SPECIES, LEARNSETS, base_stats

EGG = 0xFD
DAY_CARE_LEN = 53  # DAY_CARE_DATA_LENGTH
NAME_LEN = 11
MON = 2 * NAME_LEN
BOX = {"species": 0, "hp": 1, "level": 3, "type1": 5, "item": 7, "moves": 8, "otid": 0xC, "exp": 0xE,
       "evs": 0x11, "ivs": 0x17, "pp": 0x1B}
TERMINATOR = 0x50
H_RANDOM_ADD = _hram("hRandomAdd")


def _breeding_data():
    with open(os.path.join(REPO_ROOT, "data", "breeding.asm")) as f:
        text = f.read()
    sections = dict(re.findall(r"^(\w+):\n((?:\t[^\n]*\n)+)", text, re.M))
    groups = {m: (a, b) for a, b, m in re.findall(r"\tdb (\w+), (\w+) ; (\w+)", sections["EggGroups"])}
    cycles = {m: int(n) for n, m in re.findall(r"\tdb (\d+) ; (\w+)", sections["EggCycles"])}
    base = {m: b for b, m in re.findall(r"\tdb (\w+) ; (\w+)", sections["BaseForms"])}
    pointers = {m: label for label, m in re.findall(r"\tdw (\w+) ; (\w+)", sections["EggMovePointers"])}
    lists = {label: [x.strip() for x in body.strip()[3:].split(",")][:-1]
             for label, body in sections.items() if label.startswith("EggMoves") or label == "NoEggMoves"}
    egg_moves = {m: [MOVES[x] for x in lists[label]] for m, label in pointers.items()}
    return groups, cycles, base, egg_moves


GROUPS, CYCLES, BASE, EGG_MOVES = _breeding_data()


def ivs_bytes(ivs, flags=0):
    n = 0
    for iv in ivs:
        n = n << 5 | iv
    n = n << 2 | flags
    return list(n.to_bytes(4, "big"))


def unpack(raw):
    n = int.from_bytes(bytes(raw), "big")
    return [(n >> (27 - 5 * i)) & 31 for i in range(6)], n & 3


def gendered_ivs(ivs, female):
    """IVs like these, but with the gender byte (bytes 0 xor 2) 0 for a
    female or $FF for a male."""
    raw = ivs_bytes(ivs)
    want = raw[2] if female else raw[2] ^ 0xFF
    hp, atk_hi = want >> 3, want & 7
    ivs = [hp, atk_hi << 2 | (ivs[1] & 3)] + list(ivs[2:])
    assert (ivs_bytes(ivs)[0] ^ ivs_bytes(ivs)[2]) == (0 if female else 0xFF)
    return ivs


class BreedingTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.poke("wPlayerID", 0x12, 0x34)
        g.poke("wPlayerName", 0x91, 0x84, 0x83, TERMINATOR)  # RED

    # ----------------------------------------------------------- helpers

    def parent(self, slot, name, female=None, ivs=(10, 11, 12, 13, 14, 15), ability=0, item=0,
               moves=(), otid=(0x12, 0x34)):
        g = self.game
        prefix = "sDayCareMon2" if slot else "sDayCareMon"
        ivs = gendered_ivs(list(ivs), female) if female is not None else list(ivs)
        moves = [MOVES[m] for m in moves] + [0] * (4 - len(moves))
        g.poke(prefix + "Species", SPECIES[name])
        g.poke(prefix + "CatchRate", item)
        g.poke(prefix + "Moves", *moves)
        g.poke(prefix + "OTID", *otid)
        g.poke(prefix + "IVs", *ivs_bytes(ivs, ability))
        g.poke("wDayCareInUse", 2)
        return ivs

    def compatibility(self):
        out = self.game.call("DayCareCompatibility", max_frames=200)
        return out["a"], self.game.peek("wBreedMother")

    def make_egg(self, randoms):
        g = self.game
        chance, _ = self.compatibility()
        self.assertGreater(chance, 0)
        before = g.random_used()
        g.queue_random(*randoms)
        g.call("DayCareMakeEgg", max_frames=2000)
        self.assertEqual(g.random_used() - before, len(randoms))
        bank, addr = g.symbols["sDayCareEggName"]
        return [g.memory[bank, addr + i] for i in range(DAY_CARE_LEN)]

    # ------------------------------------------------------------- tests

    def test_data(self):
        self.assertEqual(len(GROUPS), 151)
        for name, base in BASE.items():
            self.assertEqual(BASE[base], base, name)  # a base form is its own
            self.assertGreater(CYCLES[name], 0)
        self.assertEqual(BASE["CHARIZARD"], "CHARMANDER")
        self.assertEqual(BASE["PIKACHU"], "PIKACHU")
        self.assertEqual(GROUPS["DITTO"], ("EGG_DITTO", "EGG_DITTO"))
        self.assertEqual(GROUPS["MEW"], ("EGG_NONE", "EGG_NONE"))
        self.assertIn(MOVES["DRAGON_RUSH"], EGG_MOVES["CHARIZARD"])  # the line's
        self.assertTrue(EGG_MOVES["PIKACHU"])  # Pichu's

    def test_compatibility(self):
        other = (0x56, 0x78)
        cases = [
            # (parent 0, parent 1, chance, mother)
            (("CHARMANDER", False, None), ("CHARMANDER", True, other), 70, 1),
            (("CHARMANDER", True, None), ("CHARMELEON", False, None), 20, 0),
            (("CHARMANDER", False, None), ("CHARMANDER", True, None), 50, 1),
            (("CHARMANDER", False, None), ("SQUIRTLE", True, other), 50, 1),  # Monster
            (("CHARMANDER", False, None), ("SQUIRTLE", True, None), 20, 1),
            (("CHARMANDER", False, None), ("CHARMANDER", False, other), 0, None),  # two males
            (("CHARMANDER", True, None), ("PIDGEY", False, other), 0, None),  # no group in common
            (("DITTO", None, None), ("CHARMANDER", False, other), 50, 1),
            (("MAGNEMITE", None, None), ("DITTO", None, None), 20, 0),  # genderless with Ditto
            (("MAGNEMITE", None, None), ("VOLTORB", None, other), 0, None),
            (("DITTO", None, None), ("DITTO", None, other), 0, None),
            (("MEW", None, None), ("DITTO", None, other), 0, None),
            (("NIDOQUEEN", True, None), ("NIDOKING", False, other), 0, None),  # no eggs
        ]
        for a, b, chance, mother in cases:
            with self.subTest(a=a, b=b):
                self.setUp()
                self.parent(0, a[0], female=a[1], **({"otid": a[2]} if a[2] else {}))
                self.parent(1, b[0], female=b[1], **({"otid": b[2]} if b[2] else {}))
                got, got_mother = self.compatibility()
                self.assertEqual(got, chance)
                if mother is not None:
                    self.assertEqual(got_mother, mother)
        with self.subTest("one mon"):
            self.game.poke("wDayCareInUse", 1)
            self.assertEqual(self.compatibility()[0], 0)

    def test_egg(self):
        g = self.game
        father = self.parent(0, "CHARIZARD", female=False, ivs=(1, 2, 3, 4, 5, 6), ability=0,
                             moves=("SCRATCH", "DRAGON_RUSH", "SLASH", "FLAMETHROWER"))
        mother = self.parent(1, "CHARMELEON", female=True, ivs=(31, 30, 29, 28, 27, 26), ability=1,
                             moves=("SLASH", "BITE"), otid=(0x56, 0x78))
        own = [7, 8, 9, 10, 11, 12]
        # own IVs; then attack from the father, 9 (no stat), speed (twice: a repeat), SpD from the mother;
        # the ability slot kept (under 205)
        randoms = own + [1, 0, 9, 3, 1, 3, 5, 1, 100]
        egg = self.make_egg(randoms)
        mon = egg[MON:]
        self.assertEqual(egg[:4], [0x84, 0x86, 0x86, TERMINATOR])  # EGG
        self.assertEqual(egg[NAME_LEN:NAME_LEN + 4], [0x91, 0x84, 0x83, TERMINATOR])  # the player's
        self.assertEqual(mon[BOX["species"]], SPECIES["CHARMANDER"])
        self.assertEqual(mon[BOX["hp"]:BOX["hp"] + 2], [0, 0])
        self.assertEqual(mon[BOX["level"]], 1)
        self.assertEqual(mon[BOX["item"]], CYCLES["CHARMANDER"])
        self.assertEqual(mon[BOX["otid"]:BOX["otid"] + 2], [0x12, 0x34])
        self.assertEqual(mon[BOX["evs"]:BOX["evs"] + 6], [0] * 6)
        ivs, flags = unpack(mon[BOX["ivs"]:BOX["ivs"] + 4])
        expected = list(own)
        expected[1] = father[1]
        expected[3] = mother[3]
        expected[5] = mother[5]
        self.assertEqual(ivs, expected)
        self.assertEqual(flags, 1)  # the mother's slot
        # moves: level 1's, then SLASH (both know it), then the egg moves either knows
        starting, _ = base_stats("CHARMANDER")
        model = []
        for move in [m for m in starting if m] + [m for lv, m in LEARNSETS["CHARMANDER"] if lv < 2] + \
                [MOVES["SLASH"]] + [m for m in EGG_MOVES["CHARMANDER"] if m in (MOVES["DRAGON_RUSH"], MOVES["BITE"])]:
            if move not in model:
                model = (model + [move])[-4:]
        self.assertEqual(mon[BOX["moves"]:BOX["moves"] + 4], model + [0] * (4 - len(model)))
        pp = [g.call("MovesGetData", a=m, max_frames=50) and g.peek("wMovesData", 6)[5] if m else 0
              for m in mon[BOX["moves"]:BOX["moves"] + 4]]
        self.assertEqual(mon[BOX["pp"]:BOX["pp"] + 4], pp)

    def test_ability_slot_flips(self):
        self.parent(0, "CHARMANDER", female=False, ability=0)
        self.parent(1, "CHARMANDER", female=True, ability=1, otid=(0x56, 0x78))
        egg = self.make_egg([0] * 6 + [0, 0, 1, 0, 2, 0, 230])  # 230: the other slot
        self.assertEqual(unpack(egg[MON + BOX["ivs"]:MON + BOX["ivs"] + 4])[1], 0)

    def test_ditto_and_nidoran(self):
        for coin, expected in ((0, "NIDORAN_M"), (1, "NIDORAN_F")):
            with self.subTest(coin=coin):
                self.setUp()
                self.parent(0, "DITTO")
                self.parent(1, "NIDOKING", female=False, otid=(0x56, 0x78))
                egg = self.make_egg([coin] + [0] * 6 + [0, 0, 1, 0, 2, 0, 0])
                self.assertEqual(egg[MON + BOX["species"]], SPECIES[expected])

    def test_everstone(self):
        g = self.game
        for holder in (0, 1):
            with self.subTest(holder=holder):
                self.setUp()
                self.parent(0, "CHARMANDER", female=False, ivs=(3, 1, 4, 1, 5, 9),
                            item=ITEMS["EVERSTONE"] if holder == 0 else 0)
                self.parent(1, "CHARMANDER", female=True, ivs=(2, 7, 1, 8, 2, 8),
                            item=ITEMS["EVERSTONE"] if holder == 1 else 0, otid=(0x56, 0x78))
                prefix = "sDayCareMon2" if holder else "sDayCareMon"
                bank, addr = g.symbols[prefix + "IVs"]
                g.call("GetNatureFromIVs", hl=addr, max_frames=50)
                nature = g.peek("wCalcStatNature")
                egg = self.make_egg([5] * 6 + [0, 0, 1, 0, 2, 0, 0, 17])
                bank, addr = g.symbols["sDayCareEggIVs"]
                g.call("GetNatureFromIVs", hl=addr, max_frames=50)
                self.assertEqual(g.peek("wCalcStatNature"), nature)

    def test_egg_step(self):
        g = self.game
        self.parent(0, "CHARMANDER", female=False)
        self.parent(1, "CHARMANDER", female=True, otid=(0x56, 0x78))
        g.poke("wDayCareEggReady", 0)
        g.poke("wPartyCount", 1)
        g.poke("wPartySpecies", SPECIES["PIDGEY"], 0xFF)
        g.poke("wPartyMon1Species", SPECIES["PIDGEY"])
        g.poke("wEggStepCounter", 0)
        out = g.call("DayCareEggStep", max_frames=500)  # no cycle yet
        self.assertFalse(out["carry"])
        self.assertEqual(g.peek("wDayCareEggReady"), 0)
        g.poke("wEggStepCounter", 255)
        g.queue_random(179)  # 70%: 179 out of 256 lays nothing
        g.call("DayCareEggStep", max_frames=500)
        self.assertEqual(g.peek("wDayCareEggReady"), 0)
        g.clear_random()
        g.poke("wEggStepCounter", 255)
        g.queue_random(178, *([0] * 6 + [0, 0, 1, 0, 2, 0, 0]))
        g.call("DayCareEggStep", max_frames=2000)
        self.assertEqual(g.peek("wDayCareEggReady"), 1)

    def test_cycles_and_flame_body(self):
        g = self.game
        for warmer, left in ((None, 4), ("MAGMAR", 3)):
            with self.subTest(warmer=warmer):
                self.setUp()
                g.poke("wDayCareInUse", 0)
                g.poke("wDayCareEggReady", 0)
                species = [EGG] + ([SPECIES[warmer]] if warmer else [])
                g.poke("wPartyCount", len(species))
                g.poke("wPartySpecies", *species, 0xFF)
                g.poke("wPartyMon1Species", SPECIES["SQUIRTLE"])
                g.poke("wPartyMon1CatchRate", 5)
                if warmer:
                    g.poke("wPartyMon2Species", SPECIES[warmer])
                    g.poke("wPartyMon2IVs", 0, 0, 0, 0)
                g.poke("wEggStepCounter", 255)
                out = g.call("DayCareEggStep", max_frames=500)
                self.assertEqual(g.peek("wPartyMon1CatchRate"), left)
                self.assertFalse(out["carry"])
                g.poke("wPartyMon1CatchRate", 1)
                g.poke("wEggStepCounter", 255)
                out = g.call("DayCareEggStep", max_frames=500)
                self.assertEqual(g.peek("wPartyMon1CatchRate"), 0)
                self.assertTrue(out["carry"])
                self.assertEqual(g.peek("wWhichPokemon"), 0)

    def give_egg(self):
        g = self.game
        self.parent(0, "CHARMANDER", female=False)
        self.parent(1, "SQUIRTLE", female=True, otid=(0x56, 0x78))
        self.make_egg([0] * 6 + [0, 0, 1, 0, 2, 0, 0])
        g.poke("wPartyCount", 1)
        g.poke("wPartySpecies", SPECIES["PIDGEY"], 0xFF)
        g.call("GiveDayCareEgg", max_frames=500)

    def test_give_egg(self):
        g = self.game
        self.give_egg()
        self.assertEqual(g.peek("wPartySpecies", 3), [SPECIES["PIDGEY"], EGG, 0xFF])
        self.assertEqual(g.peek("wPartyCount"), 2)
        self.assertEqual(g.peek("wPartyMon2Species"), SPECIES["SQUIRTLE"])
        self.assertEqual(g.peek("wPartyMon2HP", 2), [0, 0])
        self.assertEqual(g.peek("wPartyMon2Level"), 1)
        self.assertGreater(g.peek16("wPartyMon2MaxHP"), 0)
        self.assertEqual(g.peek("wPartyMonNicks", 4, ) if False else g.peek(g.addr("wPartyMonNicks") + NAME_LEN, 4),
                         [0x84, 0x86, 0x86, TERMINATOR])
        self.assertEqual(g.peek("wDayCareEggReady"), 0)

    def test_hatch(self):
        g = self.game
        self.give_egg()
        g.poke("wPartyMon2CatchRate", 0)
        g.poke("wPokedexOwned", *([0] * 19))
        g.auto_buttons()
        g.menu_choices(1)  # no nickname
        g.call("HatchEggs", max_frames=20000)
        self.assertEqual(g.peek("wPartySpecies", 3), [SPECIES["PIDGEY"], SPECIES["SQUIRTLE"], 0xFF])
        self.assertEqual(g.peek16("wPartyMon2HP"), g.peek16("wPartyMon2MaxHP"))
        self.assertEqual(g.peek("wPartyMon2CatchRate"), 0)
        dex = 7 - 1  # Squirtle
        self.assertTrue(g.peek(g.addr("wPokedexOwned") + dex // 8) & (1 << dex % 8))
        name = [0x80 + ord(c) - ord("A") for c in "SQUIRTLE"] + [TERMINATOR]
        self.assertEqual(g.peek(g.addr("wPartyMonNicks") + NAME_LEN, len(name)), name)

    def test_load_mon_data_reads_the_real_species(self):
        g = self.game
        self.give_egg()
        g.poke("wWhichPokemon", 1)
        g.poke("wMonDataLocation", 0)
        g.call("LoadMonData", max_frames=200)
        self.assertEqual(g.peek("wcf91"), EGG)
        self.assertEqual(g.peek("wMonHIndex"), SPECIES["SQUIRTLE"])

    def test_egg_through_the_pc(self):
        g = self.game
        self.give_egg()
        g.poke("sNumInBox", 0, 0xFF)
        for move_type, which, remove in ((1, 1, 0), (0, 0, 1)):  # deposit the egg, withdraw it
            g.poke("wWhichPokemon", which)
            g.poke("wcf91", EGG)
            g.poke("wMoveMonType", move_type)
            self.assertFalse(g.call("MoveMon", max_frames=500)["carry"])
            g.poke("wRemoveMonFromBox", remove)
            g.call("RemovePokemon", max_frames=500)
        self.assertEqual(g.peek("wPartySpecies", 3), [SPECIES["PIDGEY"], EGG, 0xFF])
        self.assertEqual(g.peek("wPartyMon2Species"), SPECIES["SQUIRTLE"])
        self.assertEqual(g.peek("wPartyMon2HP", 2), [0, 0])
        self.assertEqual(g.peek("wPartyMon2Level"), 1)
        self.assertEqual(g.peek("wPartyMon2CatchRate"), CYCLES["SQUIRTLE"])

    def test_heal_party_leaves_eggs(self):
        g = self.game
        self.give_egg()
        g.poke("wPartyMon1HP", 0, 1)
        g.call("HealParty", max_frames=2000)
        self.assertEqual(g.peek16("wPartyMon1HP"), g.peek16("wPartyMon1MaxHP"))
        self.assertEqual(g.peek("wPartyMon2HP", 2), [0, 0])

    def test_egg_names_and_battlers(self):
        g = self.game
        g.poke("wd11e", EGG)
        g.call("GetMonName", max_frames=50)
        self.assertEqual(g.peek("wcd6d", 4), [0x84, 0x86, 0x86, TERMINATOR])
        g.poke("wPartySpecies", SPECIES["PIDGEY"], EGG, EGG, 0xFF)
        for which, other in ((0, False), (1, True), (2, True)):
            g.poke("wWhichPokemon", which)
            self.assertEqual(g.call("PartyHasOtherBattler", max_frames=50)["carry"], other)

    def test_day_care_gives_or_keeps_the_egg(self):
        g = self.game
        bank, addr = g.symbols["DayCareMText1"]
        for answer in (0, 1):
            with self.subTest(answer=answer):
                self.setUp()
                self.give_egg()  # (the party: PIDGEY and an egg)
                self.make_egg([0] * 6 + [0, 0, 1, 0, 2, 0, 0])
                g.auto_buttons()
                g.menu_choices(answer)
                g.call((bank, addr + 1), max_frames=20000)
                self.assertEqual(g.peek("wDayCareEggReady"), 0)
                self.assertEqual(g.peek("wPartyCount"), 3 if answer == 0 else 2)


if __name__ == "__main__":
    unittest.main()
