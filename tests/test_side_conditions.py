"""Spec tests for Gen 9's binding moves and side conditions (design brief,
Gen 9 rules pass, part 6).

Wrap, Bind, Fire Spin and Clamp bind the target for 4-5 turns (a count of
5-6 that goes down after each of its turns; the last frees it): it takes
1/8 of its max HP each time and can't switch out unless it's a Ghost type,
but it still moves. A mon leaving the field frees the binding. Reflect,
Light Screen and Mist last 5 turns on their side, counting down as each turn
ends. Haze resets stat stages only.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN, _constants
from test_types import TYPES

MOVES = _constants("move_constants.asm", ["WRAP", "REFLECT", "MIST"])
LIGHT_SCREEN_EFFECT, REFLECT_EFFECT = 0x40, 0x41
PSN, PAR = 1 << 3, 1 << 6
SEEDED = 1 << 7
SIDE_CONDITIONS = ("wPlayerBoundTurns", "wEnemyBoundTurns", "wPlayerBoundMove", "wEnemyBoundMove",
                   "wPlayerReflectTurns", "wEnemyReflectTurns", "wPlayerLightScreenTurns",
                   "wEnemyLightScreenTurns", "wPlayerMistTurns", "wEnemyMistTurns", "wTurnPending")


class SideConditionsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(9))
        g.clear_random()
        for name in SIDE_CONDITIONS:
            g.poke(name, 0)

    def bind(self, *randoms, target_types=("NORMAL", "NORMAL")):
        g = self.game
        g.queue_random(*randoms)
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerMoveNum", MOVES["WRAP"])
        g.poke("wPlayerMoveType", TYPES["NORMAL"])
        g.poke("wEnemyMonType1", *[TYPES[t] for t in target_types])
        g.call("BindTarget", max_frames=3000)
        return g.peek("wEnemyBoundTurns"), g.peek("wEnemyBoundMove")

    def test_binds_for_4_or_5_turns(self):
        self.assertEqual(self.bind(0), (5, MOVES["WRAP"]))
        self.setUp()
        self.assertEqual(self.bind(1), (6, MOVES["WRAP"]))

    def test_not_again_or_through_immunity(self):
        self.game.poke("wEnemyBoundTurns", 2)
        self.assertEqual(self.bind()[0], 2)
        self.setUp()
        self.assertEqual(self.bind(target_types=("GHOST", "GHOST"))[0], 0)

    def test_turn_end_hurts_then_frees(self):
        g = self.game
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerBoundMove", MOVES["WRAP"])
        for turns, hurt, left in ((3, True, 2), (2, True, 1), (1, False, 0), (0, False, 0)):
            with self.subTest(turns=turns):
                g.poke("wPlayerBoundTurns", turns)
                out = g.call("BoundTurnEnd", max_frames=3000)
                self.assertEqual((out["carry"], g.peek("wPlayerBoundTurns")), (hurt, left))

    def test_residual_eighth(self):
        g = self.game
        g.poke(H_WHOSETURN, 0)
        g.poke("wBattleMonStatus", 0)
        g.poke("wPlayerBattleStatus2", 0)
        g.poke16("wBattleMonMaxHP", 160)
        g.poke16("wBattleMonHP", 100)
        g.poke("wPlayerBoundTurns", 4)
        g.poke("wPlayerBoundMove", MOVES["WRAP"])
        g.call("HandlePoisonBurnLeechSeed", max_frames=6000)
        self.assertEqual(g.peek16("wBattleMonHP"), 80)
        self.assertEqual(g.peek("wPlayerBoundTurns"), 3)

    def test_bound_cant_switch_unless_ghost(self):
        g = self.game
        g.poke("wPlayerAbility", 0, 0)
        g.poke("wBattleMonType1", TYPES["NORMAL"], TYPES["NORMAL"])
        self.assertFalse(g.call("PlayerTrapped")["carry"])
        g.poke("wPlayerBoundTurns", 3)
        self.assertTrue(g.call("PlayerTrapped")["carry"])
        g.poke("wBattleMonType1", TYPES["NORMAL"], TYPES["GHOST"])
        self.assertFalse(g.call("PlayerTrapped")["carry"])

    def test_bound_mon_still_moves(self):
        g = self.game
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        g.poke("wBattleMonStatus", 0)
        g.poke("wPlayerDisabledMove", 0)
        g.poke("wPlayerBoundTurns", 3)
        g.poke(H_WHOSETURN, 0)
        self.assertFalse(g.call("CheckPlayerStatusConditions", max_frames=5000)["z"])

    def test_leaving_frees(self):
        g = self.game
        g.poke("wPlayerBoundTurns", 3, 4)
        g.call("LoadEnemyAbility")
        self.assertEqual(g.peek("wPlayerBoundTurns", 2), [0, 0])

    def test_screens_last_five_turns(self):
        g = self.game
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerMoveEffect", REFLECT_EFFECT)
        g.call("ReflectLightScreenEffect_", max_frames=3000)
        g.poke("wPlayerMoveEffect", LIGHT_SCREEN_EFFECT)
        g.call("ReflectLightScreenEffect_", max_frames=3000)
        self.assertEqual((g.peek("wPlayerReflectTurns"), g.peek("wPlayerLightScreenTurns")), (5, 5))
        g.poke("wPlayerReflectTurns", 2)
        g.call("ReflectLightScreenEffect_", max_frames=3000)  # already up: fails
        self.assertEqual(g.peek("wPlayerLightScreenTurns"), 5)
        g.poke(H_WHOSETURN, 1)
        g.call("MistEffect_", max_frames=3000)
        self.assertEqual(g.peek("wEnemyMistTurns"), 5)

    def test_end_of_turn_countdown(self):
        g = self.game
        g.poke("wPlayerReflectTurns", 1)
        g.poke("wEnemyLightScreenTurns", 3)
        g.poke("wEnemyMistTurns", 2)
        g.call("SideConditionsEndOfTurn", max_frames=3000)  # no turn yet
        self.assertEqual(g.peek("wPlayerReflectTurns"), 1)
        g.poke("wTurnPending", 1)
        g.call("SideConditionsEndOfTurn", max_frames=6000)
        self.assertEqual([g.peek(n) for n in ("wPlayerReflectTurns", "wEnemyLightScreenTurns",
                                              "wEnemyMistTurns", "wTurnPending")], [0, 2, 1, 0])

    def test_haze_resets_stages_only(self):
        g = self.game
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerMonAttackMod", 9, 3, 13, 1, 7, 7, 11)
        g.poke("wEnemyMonAttackMod", 1, 1, 1, 1, 1, 1, 1)
        g.poke("wBattleMonStatus", PAR)
        g.poke("wEnemyMonStatus", PSN)
        g.poke("wEnemyBattleStatus2", SEEDED)
        g.poke16("wPlayerMonUnmodifiedSpeed", 101)
        g.call("HazeEffect_", max_frames=6000)
        self.assertEqual(g.peek("wPlayerMonAttackMod", 7), [7] * 7)
        self.assertEqual(g.peek("wEnemyMonAttackMod", 7), [7] * 7)
        self.assertEqual((g.peek("wBattleMonStatus"), g.peek("wEnemyMonStatus")), (PAR, PSN))
        self.assertEqual(g.peek("wEnemyBattleStatus2"), SEEDED)
        self.assertEqual(g.peek16("wBattleMonSpeed"), 50)  # paralysis still halves it
