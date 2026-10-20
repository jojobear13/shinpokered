"""Spec tests for Gen 9's per-move data (design brief, Gen 9 rules pass,
part 6): priority brackets and each move's secondary effect chance.

ComparePriority returns carry when the priorities decide who moves first,
then nz for the player and z for the enemy. MoveSecondaryChance puts the Gen
9 chance (out of 256) of the move's side effect in wSideEffectChance; 255
means always.
"""

import unittest

from harness import shared_game
from suites.apply_attack import H_WHOSETURN, _constants

MOVES = _constants("move_constants.asm", ["TACKLE", "QUICK_ATTACK", "COUNTER", "WHIRLWIND",
                                          "STOMP", "EMBER", "BITE", "BIND", "POUND"])


class PriorityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def order(self, player, enemy):
        g = self.game
        g.reset()
        g.poke("wPlayerSelectedMove", MOVES[player])
        g.poke("wEnemySelectedMove", MOVES[enemy])
        g.poke("wPlayerBattleStatus3", 0)
        g.poke("wEnemyBattleStatus3", 0)
        out = g.call("ComparePriority")
        if not out["carry"]:
            return "speed"
        return "enemy" if out["z"] else "player"

    def test_brackets(self):
        self.assertEqual(self.order("TACKLE", "TACKLE"), "speed")
        self.assertEqual(self.order("QUICK_ATTACK", "TACKLE"), "player")
        self.assertEqual(self.order("TACKLE", "QUICK_ATTACK"), "enemy")
        self.assertEqual(self.order("COUNTER", "TACKLE"), "enemy")
        self.assertEqual(self.order("WHIRLWIND", "COUNTER"), "enemy")  # -6 after -5
        self.assertEqual(self.order("QUICK_ATTACK", "QUICK_ATTACK"), "speed")


class SecondaryChanceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def chance(self, move, turn=0, before=0x55):
        g = self.game
        g.reset()
        g.poke(H_WHOSETURN, turn)
        g.poke("wPlayerMoveNum" if turn == 0 else "wEnemyMoveNum", MOVES[move])
        g.poke("wSideEffectChance", before)
        g.call("MoveSecondaryChance")
        return g.peek("wSideEffectChance")

    def test_gen9_chances(self):
        self.assertEqual(self.chance("STOMP"), 77)  # 30%
        self.assertEqual(self.chance("EMBER", turn=1), 26)  # 10%
        self.assertEqual(self.chance("BITE"), 77)
        self.assertEqual(self.chance("BIND"), 255)

    def test_no_entry_keeps_the_effects_own(self):
        self.assertEqual(self.chance("POUND"), 0x55)
