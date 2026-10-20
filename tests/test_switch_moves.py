"""Spec tests for Gen 9's switching moves in trainer battles (design brief, Gen
9 rules pass, part 6): Whirlwind and Roar drag out a random other mon of the
target's, Teleport switches the user out, and each fails without a mon that
could come in. Conversion makes the user the type of its first move.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN, _constants
from test_types import TYPES

MOVES = _constants("move_constants.asm", ["ROAR", "WHIRLWIND", "TELEPORT", "TACKLE", "CONVERSION",
                                          "EMBER"])


class SwitchMovesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        mx.setup(g, random.Random(21))
        g.clear_random()
        g.poke("wIsInBattle", 2)
        g.poke("wPlayerBoundTurns", 0, 0)
        g.poke("wForcedSwitchSlot", 0)
        g.poke("wEnemyBattleStatus3", 0)
        g.poke("wPlayerBattleStatus3", 0)

    def hp(self, party, *hps):
        g = self.game
        size = g.addr("wPartyMon2") - g.addr("wPartyMon1")
        g.poke(("wPartyCount", "wEnemyPartyCount")[party == "wEnemyMon"], len(hps))
        for i, hp in enumerate(hps):
            g.poke16(g.addr(party + "1HP") + i * size, hp)

    def test_slots_that_can_come_in(self):
        g = self.game
        self.hp("wEnemyMon", 50, 0, 30)
        g.poke("wEnemyMonPartyPos", 0)
        can = [not g.call("SlotCanSwitchIn", bc=b << 8, de=1)["z"] for b in range(6)]
        self.assertEqual(can, [False, False, True, False, False, False])
        self.hp("wEnemyMon", 50, 0)
        self.assertTrue(g.call("HasSwitchIn", de=1)["z"])  # none

    def test_random_pick_rerolls(self):
        g = self.game
        self.hp("wEnemyMon", 50, 0, 30)
        g.poke("wEnemyMonPartyPos", 0)
        g.queue_random(0, 1, 7, 2)
        g.call("PickRandomSwitchIn", de=1)
        self.assertEqual((g.peek("wWhichPokemon"), g.random_used()), (2, 4))

    def test_roar_drags_out_the_enemys(self):
        g = self.game
        self.hp("wEnemyMon", 50, 0, 30)
        g.poke("wEnemyMonPartyPos", 0)
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerMoveNum", MOVES["ROAR"])
        g.queue_random(*[2] * 32)
        g.call("SwitchAndTeleportEffect", max_frames=20000)
        self.assertEqual(g.peek("wEnemyMonPartyPos"), 2)
        self.assertEqual(g.peek("wEnemySelectedMove"), 0xFF)
        self.assertEqual(g.peek(H_WHOSETURN), 0)

    def test_whirlwind_drags_out_the_players(self):
        g = self.game
        self.hp("wPartyMon", 50, 40)
        g.poke("wPlayerMonNumber", 0)
        g.poke(H_WHOSETURN, 1)
        g.poke("wEnemyMoveNum", MOVES["WHIRLWIND"])
        g.queue_random(*[1] * 32)
        g.call("SwitchAndTeleportEffect", max_frames=20000)
        self.assertEqual(g.peek("wPlayerMonNumber"), 1)
        self.assertEqual(g.peek(H_WHOSETURN), 1)

    def test_fails_without_another_mon(self):
        g = self.game
        self.hp("wEnemyMon", 50, 0)
        g.poke("wEnemyMonPartyPos", 0)
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerMoveNum", MOVES["ROAR"])
        g.call("SwitchAndTeleportEffect", max_frames=20000)
        self.assertEqual(g.peek("wEnemyMonPartyPos"), 0)
        self.assertEqual(g.random_used(), 0)

    def test_enemy_teleport_switches_itself(self):
        g = self.game
        self.hp("wEnemyMon", 50, 30)
        g.poke("wEnemyMonPartyPos", 0)
        g.poke(H_WHOSETURN, 1)
        g.poke("wEnemyMoveNum", MOVES["TELEPORT"])
        g.queue_random(*[1] * 32)
        g.call("SwitchAndTeleportEffect", max_frames=20000)
        self.assertEqual(g.peek("wEnemyMonPartyPos"), 1)

    def test_conversion(self):
        g = self.game
        g.poke(H_WHOSETURN, 0)
        g.poke("wBattleMonMoves", MOVES["EMBER"], MOVES["CONVERSION"], 0, 0)
        g.poke("wBattleMonType1", TYPES["NORMAL"], TYPES["NORMAL"])
        g.call("ConversionEffect_", max_frames=6000)
        self.assertEqual(g.peek("wBattleMonType1", 2), [TYPES["FIRE"]] * 2)
        g.poke("wBattleMonType1", TYPES["WATER"], TYPES["FIRE"])  # already Fire: fails
        g.call("ConversionEffect_", max_frames=6000)
        self.assertEqual(g.peek("wBattleMonType1", 2), [TYPES["WATER"], TYPES["FIRE"]])
