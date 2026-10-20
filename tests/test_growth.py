"""Spec tests for Gen 9's growth (design brief, Gen 9 rules pass, part 3).

Real 0-31 IVs packed in four bytes (tests/ivs.py), six EVs (252 a stat, 510 in
all), Gen 3+'s stat formula (tested with the natures in test_special_split),
the shiny and gender rules the IVs carry, the EVs a defeated mon gives, and
Gen 7+'s level-scaled experience, worked in 2.13 fixed point.
"""

import math
import random
import unittest

from harness import shared_game

H_QUOTIENT = 0xFF95  # 4 bytes (hram.asm)
from ivs import gender_byte, is_shiny, pack, unpack
from test_held_items import ITEMS
from ivs import model_stats
from test_special_split import SPECIES, base_stats
from test_species_data import TablesTest


def dex_number(name):
    import os
    import re
    from harness import REPO_ROOT
    with open(os.path.join(REPO_ROOT, "constants", "pokedex_constants.asm")) as f:
        for line in f:
            m = re.match(rf"\s*const DEX_{name}\s*; (\d+)", line)
            if m:
                return int(m.group(1))
    raise KeyError(name)


class IVTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_get_iv_and_unpack(self):
        g = self.game
        rng = random.Random(3)
        for _ in range(40):
            ivs = [rng.randint(0, 31) for _ in range(6)]
            flags = rng.randint(0, 3)
            data = pack(ivs, flags)
            g.reset()
            g.poke("wBuffer", *data)
            for stat in range(6):
                out = g.call("GetIV", hl=g.addr("wBuffer"), bc=0x1200 | stat + 1, de=0x3456)
                self.assertEqual(out["a"], ivs[stat])
                self.assertEqual((out["bc"], out["de"], out["hl"]), (0x1200 | stat + 1, 0x3456, g.addr("wBuffer")))
            g.call("UnpackIVs", hl=g.addr("wBuffer"))
            self.assertEqual(g.peek("wIVScratch", 6), ivs)

    def test_pack_keeps_the_flags(self):
        g = self.game
        g.reset()
        ivs = [31, 0, 17, 8, 30, 1]
        g.poke("wIVScratch", *ivs)
        g.poke("wBuffer", 0, 0, 0, 0b10)
        g.call("PackIVsKeepFlags", de=g.addr("wBuffer"))
        self.assertEqual(g.peek("wBuffer", 4), pack(ivs, 0b10))

    def test_shiny(self):
        g = self.game
        cases = [([2, 6, 10, 14, 18, 30], True), ([2, 6, 10, 14, 18, 31], False),
                 ([22] * 6, True), ([20] * 6, False)]
        for ivs, shiny in cases:
            for flags in range(4):
                data = pack(ivs, flags)
                self.assertEqual(is_shiny(data), shiny)
                g.reset()
                g.poke("wBuffer", *data)
                self.assertEqual(not g.call("ShinyIVsChecker", hl=g.addr("wBuffer"))["z"], shiny, (ivs, flags))

    def test_gender(self):
        g = self.game
        male, female = 0xEF, 0xF5
        for species, value, symbol in (
                ("PIKACHU", 0x7F, female), ("PIKACHU", 0x80, male),  # 1:1
                ("BULBASAUR", 0x1F, female), ("BULBASAUR", 0x20, male),  # 1:7
                ("CLEFAIRY", 0xBF, female), ("CLEFAIRY", 0xC0, male),  # 3:1
                ("NIDOKING", 0x00, male), ("MAGNEMITE", 0x00, 0)):  # male only, none
            with self.subTest(species=species, value=value):
                g.reset()
                out = g.call("DetermineMonGender", de=SPECIES[species] << 8 | value)
                self.assertEqual(out["de"] >> 8, symbol)
        self.assertEqual(gender_byte([0x12, 0xFF, 0x34, 0]), 0x12 ^ 0x34)


class EVTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def add(self, evs, stat, amount):
        g = self.game
        g.reset()
        g.poke("wBuffer", *evs)
        g.poke("wItemScratch", stat, amount)
        out = g.call("AddEVs", de=g.addr("wBuffer"))
        return g.peek("wBuffer", 6), out["carry"]

    def test_limits(self):
        self.assertEqual(self.add([0] * 6, 1, 10), ([0, 10, 0, 0, 0, 0], False))
        self.assertEqual(self.add([0, 250, 0, 0, 0, 0], 1, 10), ([0, 252, 0, 0, 0, 0], False))
        self.assertEqual(self.add([0, 252, 0, 0, 0, 0], 1, 10), ([0, 252, 0, 0, 0, 0], True))
        self.assertEqual(self.add([252, 252, 3, 0, 0, 0], 5, 10), ([252, 252, 3, 0, 0, 3], False))  # 510 in all
        self.assertEqual(self.add([252, 252, 6, 0, 0, 0], 5, 10), ([252, 252, 6, 0, 0, 0], True))
        self.assertEqual(self.add([0] * 6, 5, 3), ([0, 0, 0, 0, 0, 3], False))

    def give(self, species, evs):
        g = self.game
        g.reset()
        g.poke("wEnemyMonSpecies", SPECIES[species])
        g.poke("wPartyMon1EVs", *evs)
        g.call("GiveEnemyEVs", de=g.addr("wPartyMon1EVs"))
        return g.peek("wPartyMon1EVs", 6)

    def test_defeated_mons_yield(self):
        yields = TablesTest()
        yields.game = self.game
        for species in ("VENUSAUR", "CHANSEY", "ELECTRODE", "MEWTWO", "MACHAMP"):
            with self.subTest(species=species):
                expected = list(yields.ev_yield(dex_number(species)))
                self.assertEqual(self.give(species, [0] * 6), expected)
        self.assertEqual(self.give("CHANSEY", [251, 0, 0, 0, 0, 0]), [252, 0, 0, 0, 0, 0])


def scaled_exp_model(base, foe_level, level, share):
    """ScaledExp's 2.13 fixed-point steps."""
    b = base * foe_level // (5 * share)
    r = (2 * foe_level + 10) * 8192 // (foe_level + level + 10)
    r2 = r * r >> 13
    root = math.isqrt(r * 8192)
    r25 = r2 * root >> 13
    product = b * r25
    if product >> 29:
        return 0xFFFF
    return min((product >> 13) + 1, 0xFFFF)


class ExpTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def scaled(self, species, foe_level, level, share=1):
        g = self.game
        g.reset()
        g.poke("wEnemyMonSpecies", SPECIES[species])
        g.poke("wEnemyMonLevel", foe_level)
        g.poke("wExpScratch", level, share)
        g.call("ScaledExp", max_frames=600)
        return g.peek(H_QUOTIENT + 2) << 8 | g.peek(H_QUOTIENT + 3)

    def test_matches_the_model_and_gen9(self):
        tables = TablesTest()
        tables.game = self.game
        rng = random.Random(9)
        for species in ("RATTATA", "PIDGEY", "GEODUDE", "CHANSEY", "MEWTWO", "SNORLAX"):
            base = tables.base_exp(dex_number(species))
            for _ in range(6):
                foe, level, share = rng.randint(1, 100), rng.randint(1, 100), rng.choice([1, 2])
                with self.subTest(species=species, foe=foe, level=level, share=share):
                    got = self.scaled(species, foe, level, share)
                    self.assertEqual(got, scaled_exp_model(base, foe, level, share))
                    exact = base * foe / 5 / share * ((2 * foe + 10) / (foe + level + 10)) ** 2.5 + 1
                    self.assertLessEqual(abs(got - exact), max(1.5, exact * 0.005))

    def test_examples(self):
        # a level 5 mon beating a level 3 Pidgey: 50 x 3 / 5 x (16 / 18) ^ 2.5 + 1
        self.assertEqual(self.scaled("PIDGEY", 3, 5), 23)
        # the share halves it before the +1
        self.assertEqual(self.scaled("PIDGEY", 3, 5, 2), 12)
        # far below the foe, far more
        self.assertGreater(self.scaled("GEODUDE", 30, 10), 2 * self.scaled("GEODUDE", 30, 30))

    def test_past_evolution_level(self):
        g = self.game
        for species, level, past in (("CHARMANDER", 15, False), ("CHARMANDER", 16, True),
                                     ("CHARMELEON", 36, True), ("CHARIZARD", 100, False),
                                     ("PIKACHU", 50, False),  # a stone
                                     ("KADABRA", 50, False),  # a trade
                                     ("EEVEE", 50, False)):
            with self.subTest(species=species, level=level):
                g.reset()
                g.poke("wd0b5", SPECIES[species])
                g.poke("wExpScratch", level)
                self.assertEqual(g.call("PastEvolutionLevel")["carry"], past)

    def test_fifth_more(self):
        g = self.game
        for value in (0, 4, 5, 100, 1000, 54613, 60000):
            g.reset()
            g.poke(H_QUOTIENT, 0, 0, value >> 8, value & 0xFF)
            g.call("BoostExpByFifth")
            self.assertEqual(g.peek(H_QUOTIENT + 2) << 8 | g.peek(H_QUOTIENT + 3),
                             min(value + value // 5, 0xFFFF))


class TrainerEVTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_hard_mode_only(self):
        g = self.game
        for options, level, ev in ((0, 50, 0), (1 << 3, 50, 42), (1 << 3, 100, 85), (1 << 3, 1, 0)):
            g.reset()
            g.poke("wOptions", options)
            g.poke("wCurEnemyLVL", level)
            self.assertEqual(g.call("TrainerMonEV")["a"], ev)


if __name__ == "__main__":
    unittest.main()


class GainExperienceTest(unittest.TestCase):
    """The whole routine: who gains what, and the EVs."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_party(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.poke("wLinkState", 0)
        g.poke("wIsInBattle", 1)
        g.poke("wPlayerID", 0x12, 0x34)
        g.poke("wPartyCount", 3, SPECIES["CHARMANDER"], SPECIES["SQUIRTLE"], SPECIES["BULBASAUR"], 0xFF)
        for i, (species, hp) in enumerate((("CHARMANDER", 20), ("SQUIRTLE", 20), ("BULBASAUR", 0))):
            mon = f"wPartyMon{i + 1}"
            g.poke(mon + "Species", SPECIES[species])
            g.poke(mon + "Level", 10)
            g.poke(mon + "BoxLevel", 10)
            g.poke16(mon + "HP", hp)
            g.poke16(mon + "MaxHP", 30)
            g.poke(mon + "OTID", 0x12, 0x34)
            g.poke(mon + "CatchRate", 0)
            g.poke(mon + "Exp", 0, 0x03, 0xE8)  # 1000: level 10 is 560 for the medium-slow growth
            g.poke(mon + "EVs", *[0] * 6)
        g.poke("wPartyGainExpFlags", 0b001)  # only the first took part
        g.poke("wPartyFoughtCurrentEnemyFlags", 0b001)
        g.poke("wPlayerMonNumber", 0)
        g.poke("wEnemyMonSpecies", SPECIES["PIDGEY"])
        g.poke("wEnemyMonLevel", 8)
        g.call("GainExperience", max_frames=20000)

        def exp(i):
            data = g.peek(f"wPartyMon{i}Exp", 3)
            return data[0] << 16 | data[1] << 8 | data[2]
        full = scaled_exp_model(50, 8, 10, 1)
        half = scaled_exp_model(50, 8, 10, 2)
        self.assertEqual(exp(1) - 1000, full)
        self.assertEqual(exp(2) - 1000, half)
        self.assertEqual(exp(3), 1000)  # fainted
        self.assertEqual(g.peek("wPartyMon1EVs", 6), [0, 0, 0, 1, 0, 0])  # Pidgey: 1 speed
        self.assertEqual(g.peek("wPartyMon2EVs", 6), [0, 0, 0, 1, 0, 0])
        self.assertEqual(g.peek("wPartyMon3EVs", 6), [0] * 6)

    def test_level_up_uses_the_ivs_and_evs(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.poke("wLinkState", 0)
        g.poke("wIsInBattle", 1)
        g.poke("wPlayerID", 0x12, 0x34)
        g.poke("wPartyCount", 1, SPECIES["CHARMANDER"], 0xFF)
        ivs, evs = pack([31, 20, 10, 5, 25, 0], 1), [8, 40, 0, 4, 100, 0]
        g.poke("wPartyMon1Species", SPECIES["CHARMANDER"])
        g.poke("wPartyMon1Level", 10)
        g.poke16("wPartyMon1HP", 30)
        g.poke16("wPartyMon1MaxHP", 30)
        g.poke("wPartyMon1OTID", 0x12, 0x34)
        g.poke("wPartyMon1CatchRate", 0)
        g.poke("wPartyMon1Exp", 0, 0x02, 0xE4)  # 740: level 11 is 742
        g.poke("wPartyMon1EVs", *evs)
        g.poke("wPartyMon1IVs", *ivs)
        g.poke("wPartyGainExpFlags", 1)
        g.poke("wPartyFoughtCurrentEnemyFlags", 1)
        g.poke("wPlayerMonNumber", 1)  # not the one out
        g.poke("wEnemyMonSpecies", SPECIES["PIDGEY"])
        g.poke("wEnemyMonLevel", 8)
        g.call("GainExperience", max_frames=40000)
        self.assertEqual(g.peek("wPartyMon1Level"), 11)
        evs[3] += 1  # Pidgey's speed EV
        expected = model_stats(base_stats("CHARMANDER"), 11, ivs, evs)
        self.assertEqual([g.peek16(f"wPartyMon1{s}") for s in
                          ("MaxHP", "Attack", "Defense", "Speed", "SpecialAttack", "SpecialDefense")], expected)
