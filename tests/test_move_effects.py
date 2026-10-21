"""Spec tests for Gen 9's numeric move rules (design brief, Gen 9 rules pass,
part 6).

Multi-hit moves hit 2 or 3 times 35% of the time each and 4 or 5 times 15%.
Recoil is 1/3 of the damage dealt for Double-Edge, 1/4 for Take Down and
Submission (rounded), and 1/4 of the user's max HP for Struggle. Jump Kick
and Hi Jump Kick cost half the user's max HP when they miss, not through its
substitute. Psywave deals the user's level times 50-150%. Low Kick's power
goes by the target's weight.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN, _constants

MOVES = _constants("move_constants.asm", ["DOUBLE_EDGE", "TAKE_DOWN", "SUBMISSION", "STRUGGLE",
                                          "FURY_ATTACK", "PSYWAVE", "LOW_KICK", "TACKLE"])
SPECIES = _constants("pokemon_constants.asm", ["SNORLAX", "PIKACHU", "ONIX", "MACHAMP"])
TWO_TO_FIVE_ATTACKS_EFFECT = 0x1D
HAS_SUBSTITUTE_UP = 1 << 4


class MoveEffectsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(3))
        g.clear_random()
        g.poke(H_WHOSETURN, 0)
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        g.poke("wPlayerAbility", 0, 0)

    def test_multi_hit_odds(self):
        g = self.game
        for roll, hits in ((0, 2), (89, 2), (90, 3), (179, 3), (180, 4), (217, 4), (218, 5), (255, 5)):
            with self.subTest(roll=roll):
                self.setUp()
                g.queue_random(roll)
                g.poke("wPlayerMoveNum", MOVES["FURY_ATTACK"])
                g.poke("wPlayerMoveEffect", TWO_TO_FIVE_ATTACKS_EFFECT)
                g.call("TwoToFiveAttacksEffect", max_frames=1000)
                self.assertEqual(g.peek("wPlayerNumAttacksLeft"), hits)

    def recoil(self, move, damage, max_hp=200):
        g = self.game
        self.setUp()
        g.poke("wPlayerMoveNum", MOVES[move])
        g.poke16("wDamage", damage)
        g.poke16("wBattleMonMaxHP", max_hp)
        g.poke16("wBattleMonHP", max_hp)
        g.call("RecoilEffect_", max_frames=3000)
        return max_hp - g.peek16("wBattleMonHP")

    def test_recoil(self):
        self.assertEqual(self.recoil("DOUBLE_EDGE", 100), 33)
        self.assertEqual(self.recoil("DOUBLE_EDGE", 101), 34)  # rounded
        self.assertEqual(self.recoil("TAKE_DOWN", 100), 25)
        self.assertEqual(self.recoil("SUBMISSION", 102), 26)
        self.assertEqual(self.recoil("TAKE_DOWN", 1), 1)  # at least 1
        self.assertEqual(self.recoil("STRUGGLE", 7, max_hp=201), 50)  # of max HP
        self.assertEqual(self.recoil("DOUBLE_EDGE", 500, max_hp=100), 100)  # down to 0

    def test_crash_half_max_hp_not_substitute(self):
        g = self.game
        g.poke16("wBattleMonMaxHP", 201)
        g.poke16("wBattleMonHP", 150)
        g.poke("wPlayerBattleStatus2", HAS_SUBSTITUTE_UP)
        g.poke("wPlayerSubstituteHP", 40)
        g.call("CrashDamage_", max_frames=3000)
        self.assertEqual(g.peek16("wBattleMonHP"), 50)
        self.assertEqual(g.peek("wPlayerSubstituteHP"), 40)

    def psywave(self, level, roll):
        g = self.game
        self.setUp()
        g.queue_random(roll)
        g.poke("wBattleMonLevel", level)
        g.call("PsywaveDamage", hl=g.addr("wBattleMonLevel"), max_frames=1000)
        return g.peek16("wDamage")

    def test_psywave(self):
        self.assertEqual(self.psywave(50, 0), 25)  # 50%
        self.assertEqual(self.psywave(50, 100), 75)  # 150%
        self.assertEqual(self.psywave(50, 50), 50)
        self.assertEqual(self.psywave(100, 0x80 | 100), 150)  # the top bit is dropped
        self.assertEqual(self.psywave(1, 0), 1)  # at least 1
        g = self.game
        self.setUp()
        g.queue_random(101, 127, 0)  # rerolled until 0-100
        g.call("PsywaveDamage", hl=g.addr("wBattleMonLevel"), max_frames=1000)
        self.assertEqual(g.random_used(), 3)

    def test_low_kick_by_weight(self):
        g = self.game
        for species, power in (("SNORLAX", 120), ("PIKACHU", 20), ("ONIX", 120), ("MACHAMP", 100)):
            with self.subTest(species=species):
                self.setUp()
                g.poke(0xFFE2, 0)  # hBattleSide: the player attacks
                g.poke("wEnemyMonSpecies", SPECIES[species])
                g.call("LowKickPower", max_frames=1000)
                self.assertEqual(g.peek("wDamageScratch"), power)


class OneHitKOTest(unittest.TestCase):
    """A one-hit KO move fails for a slower user, unless it's using X
    Accuracy: for either side (the player's skipped the X Accuracy check,
    which also put link battles out of step)."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def ohko(self, turn, x_accuracy):
        g = self.game
        g.reset()
        g.poke(H_WHOSETURN, turn)
        user, target = ("wBattleMon", "wEnemyMon") if turn == 0 else ("wEnemyMon", "wBattleMon")
        g.poke16(user + "Speed", 50)
        g.poke16(target + "Speed", 100)
        g.poke("wPlayerBattleStatus2", 1 if x_accuracy and turn == 0 else 0)  # USING_X_ACCURACY
        g.poke("wEnemyBattleStatus2", 1 if x_accuracy and turn == 1 else 0)
        g.poke("wMoveMissed", 0)
        g.call("OneHitKOEffect_", max_frames=50)
        return not g.peek("wMoveMissed")

    def test_x_accuracy_lets_a_slower_user_hit(self):
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.assertFalse(self.ohko(turn, False))
                self.assertTrue(self.ohko(turn, True))
