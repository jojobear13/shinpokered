"""Spec tests for Gen 9's status conditions (design brief, Gen 9 rules pass,
part 5).

Sleep lasts 1-3 turns (a counter of 2-4; the mon wakes when it reaches 0 and
moves that turn). A frozen mon thaws out 20% of the time at the start of its
turn and moves. Paralysis halves speed and stops the mon 25% of the time.
Confusion makes it hurt itself 1/3 of the time. Poison and Leech Seed take
1/8 of max HP, burn 1/16, bad poison 1/16 times a counter that goes up each
turn; bad poison stays bad poison through a switch (the TOX status bit), its
counter starting again. Fire types can't be burned, Ice types frozen,
Electric types paralyzed, Poison and Steel types poisoned.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from test_ability_damage import mx_effects
from test_types import TYPES

SLP_MASK, PSN, BRN, FRZ, PAR, TOX = 0b111, 1 << 3, 1 << 4, 1 << 5, 1 << 6, 1 << 7
CONFUSED = 1 << 7
SEEDED = 1 << 7
BADLY_POISONED = 1 << 0
EFFECTS = mx_effects()
HYPNOSIS = 0x5F


class TurnStartTest(unittest.TestCase):
    """CheckPlayerStatusConditions: nz to go ahead with the move."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def check(self, status, *randoms, confused=0):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(4))
        g.clear_random()
        g.queue_random(*randoms)
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        g.poke("wBattleMonStatus", status)
        g.poke("wPlayerDisabledMove", 0)
        if confused:
            g.poke("wPlayerBattleStatus1", CONFUSED)
            g.poke("wPlayerConfusedCounter", confused)
        g.poke(H_WHOSETURN, 0)
        out = g.call("CheckPlayerStatusConditions", max_frames=5000)
        return not out["z"], g.peek("wBattleMonStatus"), g.random_used()

    def test_freeze_thaws_one_time_in_five(self):
        self.assertEqual(self.check(FRZ, 50), (True, 0, 1))  # thawed, and moves
        self.assertEqual(self.check(FRZ, 51), (False, FRZ, 1))

    def test_full_paralysis_one_time_in_four(self):
        self.assertEqual(self.check(PAR, 63)[:2], (False, PAR))
        self.assertEqual(self.check(PAR, 64)[:2], (True, PAR))

    def test_confusion_hurts_one_time_in_three(self):
        moved, _, _ = self.check(0, 170, confused=3)
        self.assertTrue(moved)
        moved, _, _ = self.check(0, 171, 15, confused=3)  # (the self-hit's random factor)
        self.assertFalse(moved)


class SleepTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_counter_is_2_to_4(self):
        g = self.game
        for rolls, counter in (((0,), 2), ((1,), 3), ((2,), 4), ((3, 6), 4), ((0xFF, 0xFD), 3)):
            with self.subTest(rolls=rolls):
                g.reset()
                g.skip_delays()
                g.skip_sound_waits()
                g.auto_buttons()
                mx.setup(g, random.Random(5))
                g.clear_random()
                for i in (1, 2, 3):
                    g.poke(f"wPlayerBattleStatus{i}", 0)
                    g.poke(f"wEnemyBattleStatus{i}", 0)
                g.poke("wEnemyMonStatus", 0)
                g.poke("wPlayerMoveAccuracy", 255)
                g.poke("wPlayerMonStatMods", *[7] * 8)
                g.poke("wEnemyMonStatMods", *[7] * 8)
                g.poke("wPlayerAbility", 0, 0)
                g.poke("wPlayerMoveNum", HYPNOSIS)  # not a powder, and it has an accuracy
                g.poke("wEnemyMonType1", TYPES["NORMAL"], TYPES["NORMAL"])
                g.poke(H_WHOSETURN, 0)
                g.queue_random(0, *rolls)  # the hit test, then the counter
                g.call("SleepEffect", max_frames=5000)
                self.assertEqual(g.peek("wEnemyMonStatus") & SLP_MASK, counter)


class ResidualTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def residual(self, status, toxic=False, seeded=False, times=1, max_hp=160):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.poke("wPlayerAbility", 0, 0)
        g.poke(H_WHOSETURN, 0)
        g.poke16("wBattleMonMaxHP", max_hp)
        g.poke16("wBattleMonHP", max_hp)
        g.poke16("wEnemyMonMaxHP", max_hp)
        g.poke16("wEnemyMonHP", 1)
        g.poke("wBattleMonStatus", status)
        g.poke("wPlayerBattleStatus2", SEEDED if seeded else 0)
        g.poke("wPlayerBattleStatus3", BADLY_POISONED if toxic else 0)
        g.poke("wPlayerToxicCounter", 0)
        g.poke("wBattleMonCatchRate", 0)
        losses = []
        for _ in range(times):
            before = g.peek16("wBattleMonHP")
            g.call("HandlePoisonBurnLeechSeed", max_frames=5000)
            losses.append(before - g.peek16("wBattleMonHP"))
        return losses

    def test_fractions(self):
        self.assertEqual(self.residual(PSN), [20])  # 1/8
        self.assertEqual(self.residual(BRN), [10])  # 1/16
        self.assertEqual(self.residual(0, seeded=True), [20])  # 1/8
        self.assertEqual(self.residual(PSN | TOX, toxic=True, times=3, max_hp=400), [25, 50, 75])
        self.assertEqual(self.residual(PSN, max_hp=7), [1])  # at least 1


class BadPoisonTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_stays_bad_poison_on_send_out(self):
        g = self.game
        for status, badly in ((PSN | TOX, True), (PSN, False), (TOX, False), (BRN, False)):
            with self.subTest(status=status):
                g.reset()
                g.poke("wEnemyMonStatus", status)
                g.poke("wEnemyBattleStatus3", 0)
                g.poke("wEnemyToxicCounter", 5)
                g.call("RestoreEnemyBadPoison")
                self.assertEqual(bool(g.peek("wEnemyBattleStatus3") & BADLY_POISONED), badly)
                self.assertEqual(g.peek("wEnemyToxicCounter"), 0)


class TypeImmunityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def immune(self, status, types):
        g = self.game
        g.reset()
        g.poke("wBuffer", *(TYPES[t] for t in types))
        out = g.call("StatusTypeImmune", a=status, hl=g.addr("wBuffer"), bc=0x1234, de=0x5678)
        self.assertEqual((out["bc"], out["de"], out["hl"]), (0x1234, 0x5678, g.addr("wBuffer")))
        return out["carry"]

    def test_rules(self):
        self.assertTrue(self.immune(BRN, ("FIRE", "FLYING")))
        self.assertTrue(self.immune(FRZ, ("WATER", "ICE")))
        self.assertTrue(self.immune(PAR, ("ELECTRIC", "STEEL")))
        self.assertTrue(self.immune(PSN, ("POISON", "POISON")))
        self.assertTrue(self.immune(PSN, ("ELECTRIC", "STEEL")))
        self.assertFalse(self.immune(PAR, ("NORMAL", "NORMAL")))  # Gen 1 kept Body Slam off Normal types
        self.assertFalse(self.immune(BRN, ("WATER", "WATER")))
        self.assertFalse(self.immune(FRZ, ("FIRE", "FIRE")))

    def test_thunder_wave_on_an_electric_type(self):
        g = self.game
        for types, paralyzed in ((("ELECTRIC", "ELECTRIC"), False), (("NORMAL", "NORMAL"), True),
                                 (("WATER", "GROUND"), False)):
            with self.subTest(types=types):
                g.reset()
                g.skip_delays()
                g.skip_sound_waits()
                g.auto_buttons()
                mx.setup(g, random.Random(6))
                g.clear_random()
                g.queue_random(*[0] * 8)
                for i in (1, 2, 3):
                    g.poke(f"wPlayerBattleStatus{i}", 0)
                    g.poke(f"wEnemyBattleStatus{i}", 0)
                g.poke("wEnemyMonStatus", 0)
                g.poke("wEnemyMonType", *(TYPES[t] for t in types))
                g.poke("wPlayerMoveType", TYPES["ELECTRIC"])
                g.poke("wPlayerMoveAccuracy", 255)
                g.poke("wPlayerMonStatMods", *[7] * 8)
                g.poke("wEnemyMonStatMods", *[7] * 8)
                g.poke("wPlayerAbility", 0, 0)
                g.poke(H_WHOSETURN, 0)
                g.call("ParalyzeEffect_", max_frames=5000)
                self.assertEqual(g.peek("wEnemyMonStatus") == PAR, paralyzed)


class SpeedTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_paralysis_halves_speed(self):
        g = self.game
        for speed, halved in ((200, 100), (301, 150), (1, 1)):
            g.reset()
            g.poke(H_WHOSETURN, 1)  # the enemy's turn: the player's mon
            g.poke("wBattleMonStatus", PAR)
            g.poke16("wBattleMonSpeed", speed)
            g.call("HalveSpeedDueToParalysis")
            self.assertEqual(g.peek16("wBattleMonSpeed"), halved)


if __name__ == "__main__":
    unittest.main()


class DefrostTest(unittest.TestCase):
    """A frozen mon using a move that thaws its user (Gen 9's defrost flag:
    Flame Wheel, Flare Blitz...) thaws without the 20% roll. No Gen 1 move
    has the flag, so the test gives it to Tackle."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_defrost_move_thaws(self):
        g = self.game
        for defrost, thawed, used in ((True, True, 0), (False, False, 1)):
            with self.subTest(defrost=defrost):
                g.reset()
                mx.setup(g, random.Random(4))
                g.clear_random()
                g.queue_random(255)
                tackle = 0x21
                flags = g.peek((g.bank("MoveFlags"), g.addr("MoveFlags") + tackle - 1))
                if defrost:
                    g.patch((g.bank("MoveFlags"), g.addr("MoveFlags") + tackle - 1), flags | 1 << 4)
                for i in (1, 2, 3):
                    g.poke(f"wPlayerBattleStatus{i}", 0)
                    g.poke(f"wEnemyBattleStatus{i}", 0)
                g.poke("wBattleMonStatus", FRZ)
                g.poke("wPlayerSelectedMove", tackle)
                g.poke(H_WHOSETURN, 0)
                g.call("CheckPlayerStatusConditions", max_frames=5000)
                self.assertEqual((g.peek("wBattleMonStatus") == 0, g.random_used()), (thawed, used))
