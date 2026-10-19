"""Spec tests for abilities, part 3b: abilities that react to a move or act
each turn (design brief, plan step E, part 4).

After a move (AbilityAfterMove, against a snapshot taken when the move
started): Anger Point, Cursed Body, Synchronize, Competitive, Stench. Each
turn (with the residual damage): Shed Skin, Early Bird. On leaving: Natural
Cure. Pressure makes a move aimed at its holder cost one more PP.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from test_abilities import ABILITIES
from test_ability_damage import MOVES, SIDES, mx_effects
from test_ability_protection import set_abilities

EFFECTS = mx_effects()
POISON_TYPE, FIRE, ELECTRIC, NORMAL, WATER = 0x03, 0x14, 0x17, 0x00, 0x15
PSN, BRN, PAR = 1 << 3, 1 << 4, 1 << 6
BADLY_POISONED = 1 << 0
FLINCHED = 1 << 3
MOD_ATTACK, MOD_DEFENSE, MOD_SPECIAL_ATTACK = 0, 1, 3


class ReactionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setup(self, turn, user, target, move="TACKLE"):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(MOVES[move]))
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        for mon in ("wBattleMon", "wEnemyMon"):
            g.poke16(mon + "MaxHP", 200)
            g.poke16(mon + "HP", 200)
            g.poke(mon + "Status", 0)
            g.poke(mon + "Type1", NORMAL, NORMAL)
            for stat in ("Attack", "Defense", "Speed", "SpecialAttack", "SpecialDefense"):
                g.poke16(mon + stat, 100)
        for prefix in ("wPlayerMon", "wEnemyMon"):
            for stat in ("Attack", "Defense", "Speed", "SpecialAttack", "SpecialDefense"):
                g.poke16(prefix + "Unmodified" + stat, 100)
            g.poke(prefix + "AttackMod", *[7] * 7)
        g.poke("wPlayerDisabledMove", 0)
        g.poke("wEnemyDisabledMove", 0)
        g.poke("wAbilityFlags", 0)
        g.poke("wEscapedFromBattle", 0)
        g.poke("wCriticalHitOrOHKO", 0)
        g.poke("wLinkState", 0)
        g.poke("wOptions", 0x81)  # no animations; not hard mode, so badge boosts apply
        g.poke("wObtainedBadges", 0)  # no badge boosts, to keep the numbers plain
        set_abilities(g, turn, user, target)
        prefix = SIDES[turn][0]
        g.poke(prefix + "SelectedMove", MOVES[move])
        g.poke(prefix + "MoveListIndex", 2)
        g.poke(H_WHOSETURN, turn)
        g.call("GetCurrentMove")
        g.call("TakeMoveSnapshot")

    def after(self, randoms=()):
        g = self.game
        g.clear_random()
        if randoms:
            g.queue_random(*randoms)
        g.call("AbilityAfterMove", max_frames=4000)

    def hit(self, turn, damage=50, crit=0):
        g = self.game
        target = SIDES[turn][2]
        g.poke16(target + "HP", g.peek16(target + "HP") - damage)
        g.poke("wCriticalHitOrOHKO", crit)

    # -- Anger Point
    def test_anger_point(self):
        g = self.game
        for turn in (0, 1):
            target_prefix = SIDES[1 - turn][0]
            for crit, stage in ((1, 13), (0, 7)):
                with self.subTest(turn=turn, crit=crit):
                    self.setup(turn, "NO_ABILITY", "ANGER_POINT")
                    self.hit(turn, crit=crit)
                    self.after()
                    self.assertEqual(g.peek(target_prefix + "MonAttackMod"), stage)
                    self.assertEqual(g.peek16(SIDES[turn][2] + "Attack"), 400 if stage == 13 else 100)
        # no damage, no anger
        self.setup(0, "NO_ABILITY", "ANGER_POINT")
        g.poke("wCriticalHitOrOHKO", 1)
        self.after()
        self.assertEqual(g.peek("wEnemyMonAttackMod"), 7)

    # -- Cursed Body
    def test_cursed_body(self):
        g = self.game
        for turn in (0, 1):
            prefix = SIDES[turn][0]
            with self.subTest(turn=turn):
                self.setup(turn, "NO_ABILITY", "CURSED_BODY")
                self.hit(turn)
                self.after(randoms=(76,))
                self.assertEqual(g.peek(prefix + "DisabledMove"), (2 + 1) << 4 | 12)
                self.assertEqual(g.peek(prefix + "DisabledMoveNumber"), MOVES["TACKLE"])
                self.setup(turn, "NO_ABILITY", "CURSED_BODY")
                self.hit(turn)
                self.after(randoms=(77,))
                self.assertEqual(g.peek(prefix + "DisabledMove"), 0)
        # a move already disabled: no roll
        self.setup(0, "NO_ABILITY", "CURSED_BODY")
        g.poke("wPlayerDisabledMove", 0x19)
        self.hit(0)
        self.after()
        self.assertEqual(g.peek("wPlayerDisabledMove"), 0x19)

    # -- Synchronize
    def synchronize(self, turn, status, user="NO_ABILITY", user_types=(NORMAL, NORMAL), toxic=False):
        g = self.game
        self.setup(turn, user, "SYNCHRONIZE", "TOXIC" if toxic else "TACKLE")
        g.poke(SIDES[turn][1] + "Type1", *user_types)
        g.poke(SIDES[turn][2] + "Status", status)
        if toxic:
            g.poke(SIDES[1 - turn][0] + "BattleStatus3", BADLY_POISONED)
        self.after()
        return g.peek(SIDES[turn][1] + "Status")

    def test_synchronize(self):
        g = self.game
        for turn in (0, 1):
            user_mon, user_prefix = SIDES[turn][1], SIDES[turn][0]
            with self.subTest(turn=turn):
                self.assertEqual(self.synchronize(turn, PSN), PSN)
                self.assertEqual(g.peek(user_prefix + "BattleStatus3") & BADLY_POISONED, 0)
                self.assertEqual(self.synchronize(turn, PSN, toxic=True), PSN)
                self.assertEqual(g.peek(user_prefix + "BattleStatus3") & BADLY_POISONED, BADLY_POISONED)
                self.assertEqual(self.synchronize(turn, BRN), BRN)
                self.assertEqual(g.peek16(user_mon + "Attack"), 50)
                self.assertEqual(self.synchronize(turn, PAR), PAR)
                self.assertEqual(g.peek16(user_mon + "Speed"), 25)
                # types and abilities that can't have it
                self.assertEqual(self.synchronize(turn, PSN, user_types=(POISON_TYPE, NORMAL)), 0)
                self.assertEqual(self.synchronize(turn, BRN, user_types=(WATER, FIRE)), 0)
                self.assertEqual(self.synchronize(turn, PAR, user_types=(ELECTRIC, ELECTRIC)), 0)
                self.assertEqual(self.synchronize(turn, PAR, user="LIMBER"), 0)
                self.assertEqual(self.synchronize(turn, PSN, user="IMMUNITY"), 0)
                self.assertEqual(self.synchronize(turn, 2), 0)  # sleep isn't passed on

    # -- Competitive
    def test_competitive(self):
        g = self.game
        for turn in (0, 1):
            target_prefix = SIDES[1 - turn][0]
            with self.subTest(turn=turn):
                self.setup(turn, "NO_ABILITY", "COMPETITIVE", "LEER")
                g.poke(target_prefix + "MonDefenseMod", 6)
                self.after()
                self.assertEqual(g.peek(target_prefix + "MonSpecialAttackMod"), 9)
                self.assertEqual(g.peek16(SIDES[turn][2] + "SpecialAttack"), 200)
                self.setup(turn, "NO_ABILITY", "COMPETITIVE", "HAZE")
                g.poke(target_prefix + "MonDefenseMod", 6)
                self.after()
                self.assertEqual(g.peek(target_prefix + "MonSpecialAttackMod"), 7)
                self.setup(turn, "NO_ABILITY", "COMPETITIVE", "SWORDS_DANCE")
                self.after()
                self.assertEqual(g.peek(target_prefix + "MonSpecialAttackMod"), 7)

    # -- Stench
    def test_stench(self):
        g = self.game
        for turn in (0, 1):
            target_prefix = SIDES[1 - turn][0]
            for move, target, roll, flinched in (("TACKLE", "NO_ABILITY", 25, True),
                                                 ("TACKLE", "NO_ABILITY", 26, False),
                                                 ("TACKLE", "INNER_FOCUS", 0, False),
                                                 ("TACKLE", "SHIELD_DUST", 0, False),
                                                 ("BITE", "NO_ABILITY", 0, False)):
                with self.subTest(turn=turn, move=move, target=target, roll=roll):
                    self.setup(turn, "STENCH", target, move)
                    self.hit(turn)
                    self.after(randoms=(roll,))
                    self.assertEqual(bool(g.peek(target_prefix + "BattleStatus1") & FLINCHED), flinched)

    def test_nothing_without_a_move(self):
        g = self.game
        self.setup(0, "NO_ABILITY", "ANGER_POINT")
        g.poke("wAbilitySnapshot", 0)
        self.hit(0, crit=1)
        self.after()
        self.assertEqual(g.peek("wEnemyMonAttackMod"), 7)


class TurnAbilityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def residual(self, turn, ability, status, randoms=()):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(9))
        g.clear_random()
        set_abilities(g, turn, ability, "NO_ABILITY")
        g.poke(H_WHOSETURN, turn)
        g.poke("wLinkState", 0)
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        mon = SIDES[turn][1]
        g.poke16(mon + "MaxHP", 160)
        g.poke16(mon + "HP", 160)
        g.poke(mon + "Status", status)
        if randoms:
            g.queue_random(*randoms)
        g.call("HandlePoisonBurnLeechSeed", max_frames=4000)
        return g.peek(mon + "Status"), g.peek16(mon + "HP")

    def test_shed_skin(self):
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.assertEqual(self.residual(turn, "SHED_SKIN", PSN, (85,)), (0, 160))  # cured before the damage
                self.assertEqual(self.residual(turn, "SHED_SKIN", PSN, (86,)), (PSN, 150))
                self.assertEqual(self.residual(turn, "SHED_SKIN", 3, (0,)), (0, 160))
                self.assertEqual(self.residual(turn, "SHED_SKIN", 0), (0, 160))  # no roll without a status

    def test_early_bird(self):
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.assertEqual(self.residual(turn, "EARLY_BIRD", 5)[0], 4)
                self.assertEqual(self.residual(turn, "EARLY_BIRD", 2)[0], 1)
                self.assertEqual(self.residual(turn, "EARLY_BIRD", 1)[0], 1)
                self.assertEqual(self.residual(turn, "NO_ABILITY", 5)[0], 5)

    def test_natural_cure(self):
        g = self.game
        g.reset()
        g.poke("wPlayerAbility", ABILITIES["NATURAL_CURE"], ABILITIES["NATURAL_CURE"])
        g.poke("wPlayerMonNumber", 1)
        g.poke("wBattleMonStatus", PSN)
        g.poke("wPartyMon2Status", PSN)
        g.poke("wEnemyMonStatus", PAR)
        g.call("NaturalCurePlayer")
        g.call("NaturalCureEnemy")
        self.assertEqual((g.peek("wBattleMonStatus"), g.peek("wPartyMon2Status"), g.peek("wEnemyMonStatus")),
                         (0, 0, 0))
        g.reset()
        g.poke("wPlayerAbility", 0, 0)
        g.poke("wBattleMonStatus", PSN)
        g.poke("wEnemyMonStatus", PAR)
        g.call("NaturalCurePlayer")
        g.call("NaturalCureEnemy")
        self.assertEqual((g.peek("wBattleMonStatus"), g.peek("wEnemyMonStatus")), (PSN, PAR))

    def test_pressure(self):
        g = self.game
        for move, extra in (("TACKLE", 1), ("GROWL", 1), ("ROAR", 1), ("SWORDS_DANCE", 0), ("RECOVER", 0)):
            for turn in (0, 1):
                with self.subTest(move=move, turn=turn):
                    g.reset()
                    mx.setup(g, random.Random(1))
                    set_abilities(g, turn, "NO_ABILITY", "PRESSURE")
                    prefix, mon = SIDES[turn][0], SIDES[turn][1]
                    g.poke(prefix + "BattleStatus1", 0)
                    g.poke(prefix + "BattleStatus2", 0)
                    g.poke(prefix + "BattleStatus3", 0)
                    g.poke(prefix + "SelectedMove", MOVES[move])
                    g.poke(prefix + "MoveListIndex", 1)
                    g.poke(mon + "PP", 10, 10, 10, 10)
                    g.poke(H_WHOSETURN, turn)
                    g.call("GetCurrentMove")
                    g.call("PressureCostsPP")
                    self.assertEqual(g.peek(mon + "PP", 4), [10, 10 - extra, 10, 10])
        # never below 0
        g.reset()
        set_abilities(g, 0, "NO_ABILITY", "PRESSURE")
        g.poke("wPlayerMoveNum", MOVES["TACKLE"])
        g.poke("wPlayerMovePower", 35)
        g.poke("wPlayerMoveListIndex", 0)
        g.poke("wBattleMonPP", 0xC0)  # no PP left, with PP Ups
        g.poke(H_WHOSETURN, 0)
        g.call("PressureCostsPP")
        self.assertEqual(g.peek("wBattleMonPP"), 0xC0)


class StatPenaltyTest(unittest.TestCase):
    """ChangeStatStage keeps burn's and paralysis's penalties on the stat."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_penalties(self):
        g = self.game
        for side, mon, prefix in ((0, "wBattleMon", "wPlayerMon"), (1, "wEnemyMon", "wEnemyMon")):
            for status, mod, stat, expected in ((BRN, MOD_ATTACK, "Attack", 75), (PAR, 2, "Speed", 37),
                                                (BRN, 2, "Speed", 150), (0, MOD_ATTACK, "Attack", 150)):
                with self.subTest(side=side, status=status, stat=stat):
                    g.reset()
                    g.poke("wLinkState", 4)  # no badge boosts
                    g.poke(mon + "Status", status)
                    g.poke(prefix + "AttackMod", *[7] * 7)
                    g.poke16(prefix + "Unmodified" + stat, 100)
                    out = g.call("ChangeStatStage", a=side, bc=1 << 8 | mod)
                    self.assertFalse(out["carry"])
                    self.assertEqual(g.peek16(mon + stat), expected)


if __name__ == "__main__":
    unittest.main()
