"""Spec tests for Gen 9's species data (design brief, Gen 9 rules pass,
part 2): base stats (with the Gen 6 and 7 buffs), catch rates, and the EV
yield and base experience tables that part 3's growth reads.
"""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game

STATS = ("hp", "attack", "defense", "speed", "special attack", "special defense")


def base_stats(name):
    with open(os.path.join(REPO_ROOT, "data", "baseStats", name + ".asm")) as f:
        text = f.read()
    stats = tuple(int(re.search(rf"^db (\d+) ; base {s}$", text, re.M).group(1)) for s in STATS)
    catch = int(re.search(r"^db (\d+) ; catch rate$", text, re.M).group(1))
    return stats, catch


class BaseStatsTest(unittest.TestCase):
    def test_gen9_values(self):
        # HP, Attack, Defense, Speed, Special Attack, Special Defense
        cases = {
            "pidgeot": (83, 80, 75, 101, 70, 70),
            "alakazam": (55, 50, 45, 120, 135, 95),
            "golem": (80, 120, 130, 45, 55, 65),
            "arbok": (60, 95, 69, 80, 65, 79),
            "dugtrio": (35, 100, 50, 120, 50, 70),
            "pikachu": (35, 55, 40, 90, 50, 50),
            "clefable": (95, 70, 73, 60, 95, 90),
            "venusaur": (80, 82, 83, 80, 100, 100),
            "mewtwo": (106, 110, 90, 130, 154, 90),
        }
        for name, stats in cases.items():
            self.assertEqual(base_stats(name)[0], stats, name)

    def test_catch_rates(self):
        self.assertEqual(base_stats("pikachu")[1], 190)
        self.assertEqual(base_stats("kadabra")[1], 100)
        self.assertEqual(base_stats("mewtwo")[1], 3)


class TablesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def rom(self, label, offset, length):
        g = self.game
        bank, addr = g.bank(label), g.addr(label)
        return [g.peek((bank, addr + offset + i)) for i in range(length)]

    def ev_yield(self, dex):
        b1, b2 = self.rom("EVYields", 2 * (dex - 1), 2)
        return (b1 >> 6, b1 >> 4 & 3, b1 >> 2 & 3, b1 & 3, b2 >> 6, b2 >> 4 & 3)

    def base_exp(self, dex):
        lo, hi = self.rom("BaseExpYields", 2 * (dex - 1), 2)
        return lo | hi << 8

    def test_ev_yields(self):
        # HP, Attack, Defense, Speed, Special Attack, Special Defense
        self.assertEqual(self.ev_yield(1), (0, 0, 0, 0, 1, 0))  # Bulbasaur
        self.assertEqual(self.ev_yield(3), (0, 0, 0, 0, 2, 1))  # Venusaur
        self.assertEqual(self.ev_yield(113), (2, 0, 0, 0, 0, 0))  # Chansey
        self.assertEqual(self.ev_yield(143), (2, 0, 0, 0, 0, 0))  # Snorlax
        self.assertEqual(self.ev_yield(150), (0, 0, 0, 0, 3, 0))  # Mewtwo
        self.assertEqual(self.ev_yield(101), (0, 0, 0, 2, 0, 0))  # Electrode

    def test_base_exp(self):
        self.assertEqual(self.base_exp(1), 64)
        self.assertEqual(self.base_exp(113), 395)  # Chansey, over a byte
        self.assertEqual(self.base_exp(150), 306)
        self.assertEqual(self.base_exp(151), 270)


if __name__ == "__main__":
    unittest.main()
