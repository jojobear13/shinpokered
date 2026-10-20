"""Spec test for a bug the physical/special split brought in: a confused
mon hurting itself picked its stats by the move number left from its last
move, so after a special move it hit itself with its Special Attack against
the foe's Special Defense. The self-hit has no move: Attack against its own
Defense, whatever the last move was.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from test_ability_damage import MOVES

SIDES = {
    0: ("HandleSelfConfusionDamage", "wPlayerMoveNum", "wBattleMon", "wEnemyMon"),
    1: ("EnemyHandleSelfConfusionDamage", "wEnemyMoveNum", "wEnemyMon", "wBattleMon"),
}


class SelfHitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def damage(self, turn, last_move):
        routine, move_num, user, foe = SIDES[turn]
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        mx.setup(g, random.Random(7))
        g.poke("wPlayerBattleStatus3", 0)
        g.poke("wEnemyBattleStatus3", 0)
        g.poke16(user + "HP", 500)
        g.poke16(user + "MaxHP", 500)
        g.poke16(user + "Attack", 100)
        g.poke16(user + "Defense", 100)
        g.poke16(user + "SpecialAttack", 300)
        g.poke16(user + "SpecialDefense", 300)
        g.poke16(foe + "Defense", 50)
        g.poke16(foe + "SpecialDefense", 20)
        g.poke(move_num, MOVES[last_move])
        g.poke(H_WHOSETURN, turn)
        g.call(routine, max_frames=3000)
        self.assertEqual(g.peek(move_num), MOVES[last_move])  # put back
        return 500 - g.peek16(user + "HP")

    def test_last_move_doesnt_matter(self):
        for turn in (0, 1):
            with self.subTest(turn=turn):
                physical = self.damage(turn, "TACKLE")
                self.assertGreater(physical, 0)
                self.assertEqual(self.damage(turn, "PSYCHIC_M"), physical)
                self.assertEqual(self.damage(turn, "GROWL"), physical)


if __name__ == "__main__":
    unittest.main()
