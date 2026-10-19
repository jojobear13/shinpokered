"""Spec tests for natures (design brief, plan step E, part 3).

A mon's nature comes from its DVs: the three DV bytes as one number (without
the spare low nybble), offset so that the fixed DVs of trainers' Pokemon give
HARDY, mod 25, in Gen 3's order. A nature raises one stat by 10% and lowers
another by 10%; the five that would raise and lower the same stat are neutral.
"""

import random
import unittest

from harness import shared_game
from test_special_split import (SPECIES, STATS, STAT_EXPS, TRAINER_DVS, base_stats, model_stats,
                                nature)

NAMES = ("HARDY LONELY BRAVE ADAMANT NAUGHTY BOLD DOCILE RELAXED IMPISH LAX TIMID HASTY "
         "SERIOUS JOLLY NAIVE MODEST MILD QUIET BASHFUL RASH CALM GENTLE SASSY CAREFUL QUIRKY").split()
SCREEN_WIDTH = 20
UP, DOWN, SPACE = 0xE9, 0xEE, 0x7F


def dvs_for(target, rng):
    """Some DVs whose nature is `target`."""
    while True:
        dvs = [rng.randint(0, 255), rng.randint(0, 255), rng.randint(0, 15) << 4]
        if nature(dvs) == target:
            return dvs


def plain_stats(base, level, dvs, exps):
    """Gen 1's formula with the split specials and no nature."""
    import math
    attack, defense, speed, special = dvs[0] >> 4, dvs[0] & 0xF, dvs[1] >> 4, dvs[1] & 0xF
    hp = (attack & 1) << 3 | (defense & 1) << 2 | (speed & 1) << 1 | (special & 1)
    stat_dvs = (hp, attack, defense, speed, special, dvs[2] >> 4)
    out = []
    for i, exp in enumerate(list(exps) + [exps[4]]):
        root = min(math.isqrt(exp - 1) + 1 if exp else 1, 255)
        value = ((base[i] + stat_dvs[i]) * 2 + root // 4) * level // 100
        out.append(value + (level + 10 if i == 0 else 5))  # uncapped: the nature applies first
    return out


def text(name):
    """The game's character codes for a name in capitals."""
    return [0x80 + ord(c) - ord("A") for c in name]


class NatureLookupTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def lookup(self, dvs):
        g = self.game
        g.reset()
        g.poke("wBuffer", *dvs)
        out = g.call("GetNatureFromDVs", hl=g.addr("wBuffer"), bc=0x1234, de=0x5678)
        self.assertEqual((out["bc"], out["de"], out["hl"]), (0x1234, 0x5678, g.addr("wBuffer")))
        self.assertEqual(g.peek("wCalcStatNature"), out["a"])
        return out["a"]

    def test_matches_the_model(self):
        rng = random.Random(0)
        for _ in range(200):
            dvs = [rng.randint(0, 255) for _ in range(3)]
            with self.subTest(dvs=dvs):
                self.assertEqual(self.lookup(dvs), nature(dvs))

    def test_trainer_dvs_are_hardy(self):
        self.assertEqual(self.lookup(list(TRAINER_DVS)), NAMES.index("HARDY"))

    def test_the_spare_nybble_does_not_count(self):
        for spare in range(16):
            self.assertEqual(self.lookup([0x12, 0x34, 0x50 | spare]), self.lookup([0x12, 0x34, 0x50]))


class NatureStatsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_every_nature(self):
        g = self.game
        rng = random.Random(1)
        species, base = SPECIES["MEWTWO"], base_stats("MEWTWO")
        for n, name in enumerate(NAMES):
            with self.subTest(nature=name):
                dvs = dvs_for(n, rng)
                exps = [rng.randint(0, 0xFFFF) for _ in STAT_EXPS]
                g.reset()
                g.poke("wd0b5", species)
                g.call("GetMonHeader")
                g.poke("wCurEnemyLVL", 100)
                for stat, exp in zip(STAT_EXPS, exps):
                    g.poke16("wPartyMon1" + stat, exp)
                g.poke("wPartyMon1DVs", *dvs)
                g.call("CalcStats", hl=g.addr("wPartyMon1HPExp") - 1, de=g.addr("wPartyMon1MaxHP"), bc=0x0100)
                stats = [g.peek16("wPartyMon1" + stat) for stat in STATS]
                self.assertEqual(stats, model_stats(base, 100, dvs, exps))
                # independently of the model: 10% up and down on the stats without a nature
                plain = plain_stats(base, 100, dvs, exps)
                raised, lowered = divmod(n, 5)
                expected = list(plain)
                if raised != lowered:
                    expected[1 + raised] = min(plain[1 + raised] * 110 // 100, 999)
                    expected[1 + lowered] = plain[1 + lowered] * 90 // 100
                self.assertEqual(stats, expected)


class StatusScreenNatureTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_name_and_marks(self):
        g = self.game
        rng = random.Random(2)
        tilemap = g.addr("wTileMap")
        for n, name in enumerate(NAMES):
            with self.subTest(nature=name):
                g.reset()
                g.poke(tilemap, *[SPACE] * (SCREEN_WIDTH * 18))
                g.poke("wLoadedMonDVs", *dvs_for(n, rng))
                g.call("PrintStatusScreenNature")
                row5 = tilemap + 5 * SCREEN_WIDTH
                self.assertEqual(g.peek(row5 + 9, len(name)), text(name))
                marks = {k: g.peek(tilemap + (9 + 2 * k) * SCREEN_WIDTH + 5) for k in range(5)}
                raised, lowered = divmod(n, 5)
                expected = {k: SPACE for k in range(5)}
                if raised != lowered:
                    expected[raised], expected[lowered] = UP, DOWN
                self.assertEqual(marks, expected)


if __name__ == "__main__":
    unittest.main()
