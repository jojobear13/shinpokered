"""Badge boosts (engine/battle/core.asm ApplyBadgeStatBoosts): each badge
multiplies its stat of the player's mon by 1.125, and only a stat just
recalculated from its stage gets its boost, so they never stack. The
CHALLENGE option BADGE BOOST (EVENT_NO_BADGE_BOOSTS) and link battles turn
them off.

Spec test: an accuracy or evasion change doesn't re-apply badge boosts.
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
NO_BOOSTS = 0x8D2  # EVENT_NO_BADGE_BOOSTS


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
        flags = g.addr("wEventFlags") + NO_BOOSTS // 8  # BADGE BOOST on
        g.poke(flags, g.peek(flags) & ~(1 << NO_BOOSTS % 8))
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


ALL_STATS = ["Attack", "Defense", "Speed", "SpecialAttack", "SpecialDefense"]
ALL_BADGES = 0xFF
BOULDER = 1 << 0
MOD_DEFENSE = 1
ATTACK_UP1_EFFECT = 0x0A


class BadgeBoostTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(3))
        g.poke("wLinkState", 0)
        g.poke("wObtainedBadges", ALL_BADGES)
        g.poke("wPlayerMonAttackMod", *[7] * 7)
        g.poke("wBattleMonStatus", 0)
        self.event(False)
        for s in ALL_STATS:
            g.poke16("wPlayerMonUnmodified" + s, 200)
            g.poke16("wBattleMon" + s, 200)

    def event(self, on):
        g = self.game
        a = g.addr("wEventFlags") + NO_BOOSTS // 8
        bit = 1 << NO_BOOSTS % 8
        g.poke(a, g.peek(a) | bit if on else g.peek(a) & ~bit)

    def stats(self):
        return [self.game.peek16("wBattleMon" + s) for s in ALL_STATS]

    def test_every_badge_boosts_its_stat(self):
        self.game.call("ApplyAllBadgeStatBoosts")
        self.assertEqual(self.stats(), [225] * 5)

    def test_only_the_badges_held(self):
        self.game.poke("wObtainedBadges", BOULDER)
        self.game.call("ApplyAllBadgeStatBoosts")
        self.assertEqual(self.stats(), [225, 200, 200, 200, 200])

    def test_one_stat_after_its_change(self):
        g = self.game
        g.poke("wUnusedD71B", MOD_DEFENSE + 1)
        g.call("ApplyBadgeStatBoosts")
        self.assertEqual(self.stats(), [200, 225, 200, 200, 200])
        self.assertEqual(g.peek("wUnusedD71B"), 0)

    def test_all_ignores_a_stale_stat_change(self):
        g = self.game
        g.poke("wUnusedD71B", MOD_DEFENSE + 1)  # an enemy's stat-up leaves it set
        g.call("ApplyAllBadgeStatBoosts")
        self.assertEqual(self.stats(), [225] * 5)

    def test_capped_at_999(self):
        g = self.game
        g.poke16("wBattleMonAttack", 950)
        g.call("ApplyAllBadgeStatBoosts")
        self.assertEqual(g.peek16("wBattleMonAttack"), 999)

    def test_option_off(self):
        self.event(True)
        self.game.call("ApplyAllBadgeStatBoosts")
        self.assertEqual(self.stats(), [200] * 5)

    def test_not_in_link_battles(self):
        self.game.poke("wLinkState", 4)  # LINK_STATE_BATTLING
        self.game.call("ApplyAllBadgeStatBoosts")
        self.assertEqual(self.stats(), [200] * 5)

    def test_stat_up_doesnt_stack(self):
        g = self.game
        g.call("ApplyAllBadgeStatBoosts")  # as the mon came in
        for _ in range(2):
            g.poke(H_WHOSETURN, 0)
            g.poke("wPlayerMoveEffect", ATTACK_UP1_EFFECT)
            g.call("StatModifierUpEffect", max_frames=6000)
        # +2: 200 * 2 = 400, boosted once: 450; the rest keep their one boost
        self.assertEqual(self.stats(), [450, 225, 225, 225, 225])

    def test_haze_boosts_once(self):
        g = self.game
        g.call("ApplyAllBadgeStatBoosts")
        g.poke(H_WHOSETURN, 0)
        g.call("HazeEffect_", max_frames=6000)
        self.assertEqual(self.stats(), [225] * 5)


if __name__ == "__main__":
    unittest.main()
