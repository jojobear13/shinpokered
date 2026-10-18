"""Spec tests for the physical/special split (design brief, plan step E, part 2).

Each move has a category from Gen 4 on, and the category, not the move's type,
decides whether it hits with attack against defense or special attack against
special defense.
"""

import os
import random
import re
import unittest

from harness import REPO_ROOT, shared_game
from suites import damage_vars

SIDES = {
    "player": ("wBattleMon", "wEnemyMon", "wPlayerMove"),
    "enemy": ("wEnemyMon", "wBattleMon", "wEnemyMove"),
}


def _moves():
    values = {}
    with open(os.path.join(REPO_ROOT, "constants", "move_constants.asm")) as f:
        for line in f:
            m = re.match(r"\s*const (\w+)\s*; ([0-9a-f]{2})\s*$", line)
            if m:
                values[m.group(1)] = int(m.group(2), 16)
    return values


MOVES = _moves()
FIRE, WATER, GRASS, ELECTRIC, ICE, NORMAL, FLYING, FIGHTING = 0x14, 0x15, 0x16, 0x17, 0x19, 0x00, 0x02, 0x01

# moves whose Gen 4 category differs from what their Gen 1 type made them
CROSSOVERS = {
    "CRABHAMMER": ("PHYSICAL", WATER),
    "WATERFALL": ("PHYSICAL", WATER),
    "CLAMP": ("PHYSICAL", WATER),
    "FIRE_PUNCH": ("PHYSICAL", FIRE),
    "ICE_PUNCH": ("PHYSICAL", ICE),
    "THUNDERPUNCH": ("PHYSICAL", ELECTRIC),
    "RAZOR_LEAF": ("PHYSICAL", GRASS),
    "VINE_WHIP": ("PHYSICAL", GRASS),
    "GUST": ("SPECIAL", NORMAL),
    "TRI_ATTACK": ("SPECIAL", NORMAL),
    "SWIFT": ("SPECIAL", NORMAL),
    "HYPER_BEAM": ("SPECIAL", NORMAL),
}


class GetMoveCategoryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_every_move_matches_the_table(self):
        g = self.game
        names = {"PHYSICAL": 0, "SPECIAL": 1, "STATUS": 2}
        for move_id in range(0, 256):
            with self.subTest(move=move_id):
                g.reset()
                out = g.call("GetMoveCategory", a=move_id, bc=0x1234, de=0x5678, hl=0x9ABC)
                self.assertEqual(out["a"], names[damage_vars.category(move_id)])
                self.assertEqual((out["bc"], out["de"], out["hl"]), (0x1234, 0x5678, 0x9ABC))
        self.assertEqual(len(damage_vars.CATEGORIES), 165)  # POUND through STRUGGLE

    def test_crossover_moves(self):
        for name, (expected, _) in CROSSOVERS.items():
            self.assertEqual(damage_vars.category(MOVES[name]), expected, name)


class DamageStatsTest(unittest.TestCase):
    """GetDamageVars picks the stats by category, whatever the move's type."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_crossover_moves_use_their_categorys_stats(self):
        g = self.game
        for name, (expected, move_type) in CROSSOVERS.items():
            for side, (attacker, defender, move) in SIDES.items():
                with self.subTest(move=name, side=side):
                    g.reset()
                    damage_vars.setup(g, random.Random(MOVES[name]))
                    g.poke("wCriticalHitOrOHKO", 0)
                    for status3 in ("wPlayerBattleStatus3", "wEnemyBattleStatus3"):
                        g.poke(status3, 0)
                    g.poke(move + "Num", MOVES[name])
                    g.poke(move + "Power", 80)
                    g.poke(move + "Type", move_type)
                    g.poke16(attacker + "Attack", 11)
                    g.poke16(attacker + "SpecialAttack", 22)
                    g.poke16(defender + "Defense", 33)
                    g.poke16(defender + "SpecialDefense", 44)
                    out = damage_vars.run(g, side)
                    stats = (11, 33) if expected == "PHYSICAL" else (22, 44)
                    self.assertEqual((out["b"], out["c"]), stats)


if __name__ == "__main__":
    unittest.main()


class CounterTest(unittest.TestCase):
    """Counter strikes back at physical moves, as from Gen 2, whatever their type."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def counter_after(self, seed, enemy_move):
        """The player uses Counter after the enemy's `enemy_move` did 50 damage;
        returns the enemy's HP after (999 before) or None if the turn didn't
        get to Counter."""
        from suites import move_execution as mx
        from suites.apply_attack import H_WHOSETURN
        g = self.game
        g.reset()
        mx.setup(g, random.Random(seed))
        for prefix in ("wPlayerBattleStatus", "wEnemyBattleStatus"):
            for i in (1, 2, 3):
                g.poke(f"{prefix}{i}", 0)
        for prefix in ("wBattleMon", "wEnemyMon"):
            g.poke(prefix + "Status", 0)
        g.poke("wPlayerDisabledMove", 0)
        g.poke16("wEnemyMonMaxHP", 999)
        g.poke16("wEnemyMonHP", 999)
        g.poke("wUnusedC000", 0)
        counter = MOVES["COUNTER"]
        g.poke("wBattleMonMoves", counter, 0, 0, 0)
        g.poke("wBattleMonPP", 10, 0, 0, 0)
        g.poke("wPlayerSelectedMove", counter)
        g.poke("wPlayerMoveListIndex", 0)
        g.poke(H_WHOSETURN, 0)
        g.call("GetCurrentMove")
        g.poke("wEnemySelectedMove", MOVES[enemy_move])
        g.poke("wEnemyMovePower", 80)
        g.poke16("wDamage", 50)
        out = mx.run(g, "player")
        if "error" in out:
            return None
        return g.peek16("wEnemyMonHP")

    def test_physical_moves_are_countered_whatever_their_type(self):
        for move in ("CRABHAMMER", "ROCK_THROW", "TACKLE"):
            results = [self.counter_after(seed, move) for seed in range(8)]
            hits = [hp for hp in results if hp is not None and hp != 999]
            self.assertTrue(hits, move)
            self.assertEqual(set(hits), {899}, move)  # twice the 50 damage

    def test_special_moves_are_not_countered_even_normal_ones(self):
        for move in ("EMBER", "GUST", "SWIFT"):
            for seed in range(8):
                with self.subTest(move=move, seed=seed):
                    self.assertIn(self.counter_after(seed, move), (999, None))
