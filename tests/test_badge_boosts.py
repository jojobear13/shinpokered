"""Spec test: an accuracy or evasion change doesn't re-apply badge boosts.

Badge boosts multiply the player's stats by 1.125 when they are computed.
After a stat stage changes, only the changed stat is recalculated, so only its
boost may be applied again. Accuracy and evasion have no stat to recalculate,
so changing them must leave every stat as it was.
"""

import os
import random
import re
import unittest

from harness import REPO_ROOT, shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN

STATS = ("Attack", "Defense", "Speed")


def _moves():
    values = {}
    with open(os.path.join(REPO_ROOT, "constants", "move_constants.asm")) as f:
        for line in f:
            m = re.match(r"\s*const (\w+)\s*; \$?([0-9A-Fa-f]+)", line)
            if m:
                values[m.group(1)] = int(m.group(2), 16)
    return values


MOVES = _moves()


class AccuracyEvasionBadgeBoostTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def turn(self, seed, side, move):
        """One whole turn of `move` by `side`, with every badge, stats at 100,
        120 and 140 and all stages neutral; returns the player's stats after."""
        g = self.game
        g.reset()
        mx.setup(g, random.Random(seed))
        for prefix in ("wPlayerBattleStatus", "wEnemyBattleStatus"):
            for i in (1, 2, 3):
                g.poke(f"{prefix}{i}", 0)
        for prefix in ("wBattleMon", "wEnemyMon"):
            g.poke(prefix + "Status", 0)
        g.poke("wPlayerDisabledMove", 0)
        g.poke("wEnemyDisabledMove", 0)
        g.poke("wObtainedBadges", 0xFF)
        g.poke("wOptions", g.peek("wOptions") & ~(1 << 6))  # not hard mode, so boosts apply
        for prefix in ("wPlayerMon", "wEnemyMon"):
            g.poke(prefix + "StatMods", *[7] * 8)
        for name, value in zip(STATS, (100, 120, 140)):
            g.poke16("wBattleMon" + name, value)
        mon, selected, index, turn = {
            "player": ("wBattleMon", "wPlayerSelectedMove", "wPlayerMoveListIndex", 0),
            "enemy": ("wEnemyMon", "wEnemySelectedMove", "wEnemyMoveListIndex", 1),
        }[side]
        g.poke(mon + "Moves", move, 0, 0, 0)
        g.poke(mon + "PP", 10, 0, 0, 0)
        g.poke(selected, move)
        g.poke(index, 0)
        g.poke(H_WHOSETURN, turn)
        g.call("GetCurrentMove")
        out = mx.run(g, side)
        return out, {name: g.peek16("wBattleMon" + name) for name in STATS}

    def test_double_team_leaves_the_players_stats(self):
        for seed in range(5):
            with self.subTest(seed=seed):
                out, stats = self.turn(seed, "player", MOVES["DOUBLE_TEAM"])
                self.assertNotIn("error", out)
                self.assertEqual(self.game.peek("wPlayerMonEvasionMod"), 8)
                self.assertEqual(stats, {"Attack": 100, "Defense": 120, "Speed": 140})

    def test_sand_attack_on_the_player_leaves_the_players_stats(self):
        lowered = 0
        for seed in range(20):
            with self.subTest(seed=seed):
                out, stats = self.turn(seed, "enemy", MOVES["SAND_ATTACK"])
                if "error" in out:
                    continue
                if self.game.peek("wPlayerMonAccuracyMod") == 6:
                    lowered += 1
                self.assertEqual(stats, {"Attack": 100, "Defense": 120, "Speed": 140})
        self.assertGreater(lowered, 0, "Sand-Attack should have hit in some turns")


if __name__ == "__main__":
    unittest.main()
