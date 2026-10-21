"""Spec tests for held items, part 2: what they do in battle (design brief,
plan step E, part 5).

Damage (stage S3): the type boosters (x6/5), Choice Band and Specs (x3/2),
Life Orb (x13/10, and 1/10 of max HP after the move), Light Ball (Pikachu,
x2), Thick Club (Cubone and Marowak, physical, x2), the target's Eviolite (if
it can evolve, x2/3) and Metal Powder (an untransformed Ditto, physical,
x1/2). Critical hits: Scope Lens x2, the Stick and Lucky Punch x4 for their
species. BrightPowder: x9/10 accuracy against its holder. Focus Sash and
Focus Band. Quick Claw and Choice Scarf. Choice locking. Leftovers, the
berries, King's Rock, MysteryBerry, Smoke Ball.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from test_abilities import ABILITIES
from test_ability_damage import MOVES, SIDES
from test_ability_protection import set_abilities
from test_ability_reactions import ReactionTest
from test_held_items import ITEMS
from test_special_split import SPECIES

NORMAL, FIRE, WATER = 0x00, 0x14, 0x15
SPECIAL_SIDE = 1 << 1
TRANSFORMED = 1 << 3
SLP, PSN, BRN, FRZ, PAR = 0x03, 1 << 3, 1 << 4, 1 << 5, 1 << 6
CONFUSED = 1 << 7
FLINCHED = 1 << 3
STURDY_ENDURED = 1 << 2
H_SERIAL = 0xFFAA


def items(game, player=0, enemy=0):
    game.poke("wBattleMonCatchRate", ITEMS[player] if player else 0)
    game.poke("wEnemyMonCatchRate", ITEMS[enemy] if enemy else 0)


class DamageItemTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def s3(self, user_item=0, target_item=0, turn=0, move_type=NORMAL, special=False, user_species="RATTATA",
           target_species="RATTATA", transformed=False, damage=100):
        g = self.game
        g.reset()
        g.poke(H_WHOSETURN, turn)
        g.poke(0xFFE2, turn | (SPECIAL_SIDE if special else 0))  # hBattleSide
        g.poke("wPlayerAbility", 0, 0)
        user, target = SIDES[turn][1], SIDES[turn][2]
        g.poke(user + "CatchRate", ITEMS[user_item] if user_item else 0)
        g.poke(target + "CatchRate", ITEMS[target_item] if target_item else 0)
        g.poke(user + "Species", SPECIES[user_species])
        g.poke(target + "Species", SPECIES[target_species])
        g.poke(SIDES[1 - turn][0] + "BattleStatus3", TRANSFORMED if transformed else 0)
        prefix = SIDES[turn][0]
        g.poke(prefix + "MoveNum", MOVES["TACKLE"])
        g.poke(prefix + "MovePower", 80)
        g.poke(prefix + "MoveType", move_type)
        g.poke16("wDamage", damage)
        g.poke("wDamageMultipliers", 10)
        g.poke("wCriticalHitOrOHKO", 0)
        g.poke("wUnusedC000", 0)
        g.call("AbilityDamageModifiers")
        return g.peek16("wDamage")

    def test_type_boosters(self):
        for turn in (0, 1):
            self.assertEqual(self.s3("CHARCOAL", move_type=FIRE, turn=turn), 120)
            self.assertEqual(self.s3("CHARCOAL", move_type=WATER, turn=turn), 100)
            self.assertEqual(self.s3("MYSTIC_WATER", move_type=WATER, turn=turn), 120)
            self.assertEqual(self.s3("PINK_BOW", move_type=NORMAL, turn=turn), 120)

    def test_choice_and_life_orb(self):
        for turn in (0, 1):
            self.assertEqual(self.s3("CHOICE_BAND", turn=turn), 150)
            self.assertEqual(self.s3("CHOICE_BAND", special=True, turn=turn), 100)
            self.assertEqual(self.s3("CHOICE_SPECS", special=True, turn=turn), 150)
            self.assertEqual(self.s3("CHOICE_SPECS", turn=turn), 100)
            self.assertEqual(self.s3("CHOICE_SCARF", turn=turn), 100)
            self.assertEqual(self.s3("LIFE_ORB", turn=turn), 130)

    def test_species_items(self):
        for turn in (0, 1):
            self.assertEqual(self.s3("LIGHT_BALL", user_species="PIKACHU", special=True, turn=turn), 200)
            self.assertEqual(self.s3("LIGHT_BALL", user_species="RAICHU", turn=turn), 100)
            self.assertEqual(self.s3("THICK_CLUB", user_species="MAROWAK", turn=turn), 200)
            self.assertEqual(self.s3("THICK_CLUB", user_species="CUBONE", turn=turn), 200)
            self.assertEqual(self.s3("THICK_CLUB", user_species="CUBONE", special=True, turn=turn), 100)

    def test_target_items(self):
        for turn in (0, 1):
            self.assertEqual(self.s3(target_item="EVIOLITE", target_species="CHARMANDER", turn=turn), 66)
            self.assertEqual(self.s3(target_item="EVIOLITE", target_species="EEVEE", turn=turn), 66)
            self.assertEqual(self.s3(target_item="EVIOLITE", target_species="CHARIZARD", turn=turn), 100)
            self.assertEqual(self.s3(target_item="METAL_POWDER", target_species="DITTO", turn=turn), 50)
            self.assertEqual(self.s3(target_item="METAL_POWDER", target_species="DITTO", special=True, turn=turn), 100)
            self.assertEqual(self.s3(target_item="METAL_POWDER", target_species="DITTO", transformed=True,
                                     turn=turn), 100)


class CritAndAccuracyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def stage(self, item, species="RATTATA", stage=0, target_ability="NO_ABILITY", turn=0):
        g = self.game
        g.reset()
        g.poke(H_WHOSETURN, turn)
        set_abilities(g, turn, "NO_ABILITY", target_ability)
        g.poke(SIDES[turn][1] + "CatchRate", ITEMS[item] if item else 0)
        g.poke(SIDES[turn][1] + "Species", SPECIES[species])
        g.poke("wSideEffectChance", stage)
        g.call("CritStageModifiers")
        return g.peek("wSideEffectChance")

    def test_crit_items(self):
        # Gen 9's critical hit stages: Scope Lens +1, the Stick and Lucky Punch +2
        for turn in (0, 1):
            self.assertEqual(self.stage(0, turn=turn), 0)
            self.assertEqual(self.stage("SCOPE_LENS", turn=turn), 1)
            self.assertEqual(self.stage("SCOPE_LENS", stage=2, turn=turn), 3)
            self.assertEqual(self.stage("STICK", "FARFETCHD", turn=turn), 2)
            self.assertEqual(self.stage("STICK", "RATTATA", turn=turn), 0)
            self.assertEqual(self.stage("LUCKY_PUNCH", "CHANSEY", stage=1, turn=turn), 3)
            self.assertEqual(self.stage("SCOPE_LENS", target_ability="SHELL_ARMOR", turn=turn), 0xFF)

    def test_bright_powder(self):
        g = self.game
        for turn in (0, 1):
            g.reset()
            g.poke(H_WHOSETURN, turn)
            g.poke("wPlayerAbility", 0, 0)
            g.poke(SIDES[turn][2] + "CatchRate", ITEMS["BRIGHTPOWDER"])
            prefix, target_prefix = SIDES[turn][0], SIDES[1 - turn][0]
            g.poke(prefix + "MoveAccuracy", 255)
            g.poke(prefix + "MonAccuracyMod", 7)
            g.poke(target_prefix + "MonEvasionMod", 7)
            g.poke(target_prefix + "BattleStatus1", 0)
            g.call("CalcHitChance")
            self.assertEqual(g.peek(prefix + "MoveAccuracy"), 255 * 9 // 10)


class FocusTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def hit(self, item, hp=200, roll=None, turn=0, in_battle=2):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(1))
        g.clear_random()
        if roll is not None:
            g.queue_random(roll)
        g.poke("wPlayerAbility", 0, 0)
        g.poke("wIsInBattle", in_battle)
        g.poke("wAbilityFlags", 0)
        target = SIDES[turn][2]
        g.poke(target + "CatchRate", ITEMS[item])
        g.poke16(target + "MaxHP", 200)
        g.poke16(target + "HP", hp)
        g.poke(target_prefix_of(turn) + "BattleStatus2", 0)
        g.poke("wEnemyMonPartyPos", 1)
        g.poke("wEnemyMon2CatchRate", ITEMS[item])
        g.poke("wPlayerMonNumber", 2)
        g.poke("wPartyMon3CatchRate", ITEMS[item])
        g.poke(H_WHOSETURN, turn)
        g.poke16("wDamage", 500)
        g.call("ApplyDamageToEnemyPokemon" if turn == 0 else "ApplyDamageToPlayerPokemon", max_frames=3000)
        return g.peek16(target + "HP"), g.peek(target + "CatchRate")

    def test_focus_sash(self):
        g = self.game
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.assertEqual(self.hit("FOCUS_SASH", turn=turn), (1, 0))  # used up
                roster = "wEnemyMon2CatchRate" if turn == 0 else "wPartyMon3CatchRate"
                self.assertEqual(g.peek(roster), 0)
                self.assertEqual(g.peek("wEnduredBy"), ITEMS["FOCUS_SASH"])
                self.assertEqual(self.hit("FOCUS_SASH", hp=199, turn=turn), (0, ITEMS["FOCUS_SASH"]))

    def test_focus_band(self):
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.assertEqual(self.hit("FOCUS_BAND", hp=50, roll=25, turn=turn), (1, ITEMS["FOCUS_BAND"]))
                self.assertEqual(self.hit("FOCUS_BAND", hp=50, roll=26, turn=turn), (0, ITEMS["FOCUS_BAND"]))

    def test_wild_mon_sash(self):
        self.assertEqual(self.hit("FOCUS_SASH", turn=0, in_battle=1), (1, 0))


def target_prefix_of(turn):
    return SIDES[1 - turn][0]


class TurnOrderTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def order(self, player=0, enemy=0, speeds=(100, 100), rolls=(), serial=1):
        g = self.game
        g.reset()
        g.poke("wLinkState", 0)
        g.poke(H_SERIAL, serial)
        items(g, player, enemy)
        g.poke16("wBattleMonSpeed", speeds[0])
        g.poke16("wEnemyMonSpeed", speeds[1])
        g.clear_random()
        g.queue_random(*rolls)
        out = g.call("ItemTurnOrder")
        if not out["carry"]:
            return None
        return "player" if not out["z"] else "enemy"

    def test_quick_claw(self):
        self.assertEqual(self.order("QUICK_CLAW", speeds=(50, 100), rolls=(50,)), "player")
        self.assertEqual(self.order("QUICK_CLAW", speeds=(50, 100), rolls=(51,)), "enemy")
        self.assertEqual(self.order(enemy="QUICK_CLAW", speeds=(100, 50), rolls=(0,)), "enemy")
        # both go off: speed decides
        self.assertEqual(self.order("QUICK_CLAW", "QUICK_CLAW", speeds=(50, 100), rolls=(0, 0)), "enemy")

    def test_link_roll_order(self):
        # the internal-clock game rolls its enemy's claw first
        self.assertEqual(self.order("QUICK_CLAW", speeds=(50, 100), rolls=(50,), serial=2), "player")
        self.assertEqual(self.order("QUICK_CLAW", "QUICK_CLAW", speeds=(50, 100), rolls=(0, 200), serial=2), "enemy")
        self.assertEqual(self.order("QUICK_CLAW", "QUICK_CLAW", speeds=(50, 100), rolls=(200, 0), serial=2), "player")

    def test_choice_scarf(self):
        self.assertEqual(self.order("CHOICE_SCARF", speeds=(100, 140)), "player")
        self.assertEqual(self.order("CHOICE_SCARF", speeds=(100, 160)), "enemy")
        self.assertEqual(self.order(enemy="CHOICE_SCARF", speeds=(140, 100)), "enemy")
        self.assertIsNone(self.order("CHOICE_SCARF", speeds=(100, 150)))  # a tie
        self.assertEqual(self.order(speeds=(101, 100)), "player")


class ChoiceLockTest(unittest.TestCase):
    setUpClass = classmethod(ReactionTest.setUpClass.__func__)
    setup = ReactionTest.setup
    after = ReactionTest.after
    hit = ReactionTest.hit
    def test_lock_and_menu(self):
        g = self.game
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.setup(turn, "NO_ABILITY", "NO_ABILITY")
                g.poke(SIDES[turn][1] + "CatchRate", ITEMS["CHOICE_BAND"])
                g.poke("wPlayerChoiceLock", 0, 0)
                self.after()
                lock = "wPlayerChoiceLock" if turn == 0 else "wEnemyChoiceLock"
                self.assertEqual(g.peek(lock), 3)  # MoveListIndex 2
        g.poke("wPlayerChoiceLock", 3)
        g.poke("wBattleMonPP", 5, 5, 5, 5)
        for slot, locked in ((0, True), (2, False)):
            g.poke("wCurrentMenuItem", slot)
            self.assertEqual(g.call("PlayerChoiceLocked", max_frames=3000)["carry"], locked)
        g.poke("wBattleMonPP", 5, 5, 0, 5)  # the locked move is out of PP
        g.poke("wCurrentMenuItem", 0)
        self.assertFalse(g.call("PlayerChoiceLocked", max_frames=3000)["carry"])

    def test_enemy_move_choice(self):
        g = self.game
        for lock, pps, slot, allowed in ((2, (5, 5, 5, 5), 1, False), (2, (5, 5, 5, 5), 2, True),
                                         (2, (5, 0, 5, 5), 1, True), (0, (5, 5, 5, 5), 3, True)):
            with self.subTest(lock=lock, pps=pps, slot=slot):
                g.reset()
                g.poke("wIsInBattle", 1)
                g.poke("wEnemyChoiceLock", lock)
                g.poke("wEnemyDisabledMove", 0)
                g.poke("wEnemyBattleStatus3", 0)
                g.poke("wEnemyMonMoves", MOVES["TACKLE"], MOVES["EMBER"], MOVES["GROWL"], MOVES["BITE"])
                g.poke("wEnemyMonPP", *pps)
                move = g.addr("wEnemyMonMoves") + slot - 1
                g.poke("wUnusedCF8D", move >> 8, move & 0xFF)
                out = g.call("ChooseMovePPTrack", de=slot)
                self.assertEqual(out["de"] & 0xFF != 0, allowed)
                self.assertEqual(g.peek("wEnemyMonPP", 4)[slot - 1], pps[slot - 1] - (1 if allowed else 0))

    def test_send_out_clears_the_lock(self):
        g = self.game
        g.reset()
        g.poke("wPlayerChoiceLock", 2, 3)
        g.call("LoadPlayerAbility")
        g.call("LoadEnemyAbility")
        self.assertEqual(g.peek("wPlayerChoiceLock", 2), [0, 0])


class AfterMoveItemTest(unittest.TestCase):
    setUpClass = classmethod(ReactionTest.setUpClass.__func__)
    setup = ReactionTest.setup
    after = ReactionTest.after
    hit = ReactionTest.hit
    def test_life_orb(self):
        g = self.game
        for turn in (0, 1):
            for ability, expected in (("NO_ABILITY", 180), ("MAGIC_GUARD", 200)):
                with self.subTest(turn=turn, ability=ability):
                    self.setup(turn, ability, "NO_ABILITY")
                    g.poke(SIDES[turn][1] + "CatchRate", ITEMS["LIFE_ORB"])
                    self.hit(turn)
                    self.after()
                    self.assertEqual(g.peek16(SIDES[turn][1] + "HP"), expected)
            # even when the target fainted
            self.setup(turn, "NO_ABILITY", "NO_ABILITY")
            g.poke(SIDES[turn][1] + "CatchRate", ITEMS["LIFE_ORB"])
            self.hit(turn, damage=200)
            self.after()
            self.assertEqual(g.peek16(SIDES[turn][1] + "HP"), 180)

    def test_kings_rock(self):
        g = self.game
        for turn in (0, 1):
            for roll, flinched in ((25, True), (26, False)):
                with self.subTest(turn=turn, roll=roll):
                    self.setup(turn, "NO_ABILITY", "NO_ABILITY")
                    g.poke(SIDES[turn][1] + "CatchRate", ITEMS["KINGS_ROCK"])
                    self.hit(turn)
                    self.after(randoms=(roll,))
                    self.assertEqual(bool(g.peek(SIDES[1 - turn][0] + "BattleStatus1") & FLINCHED), flinched)

    def test_mystery_berry(self):
        g = self.game
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.setup(turn, "NO_ABILITY", "NO_ABILITY")
                mon = SIDES[turn][1]
                g.poke(mon + "CatchRate", ITEMS["MYSTERYBERRY"])
                g.poke(mon + "PP", 9, 9, 0xC0, 9)  # the move used (slot 3) is out, with PP Ups
                g.poke("wPlayerMonNumber", 0)
                g.poke("wPartyMon1PP", 9, 9, 0xC0, 9)
                g.poke(SIDES[turn][0] + "BattleStatus3", 0)
                self.after()
                self.assertEqual(g.peek(mon + "PP", 4), [9, 9, 0xC5, 9])
                self.assertEqual(g.peek(mon + "CatchRate"), 0)
                if turn == 0:
                    self.assertEqual(g.peek("wPartyMon1PP", 4), [9, 9, 0xC5, 9])

    def test_mystery_berry_not_in_link_battles(self):
        # each game spends only its own player's PP, so the other would never
        # see the move run out: the berry stays out of link battles
        g = self.game
        self.setup(0, "NO_ABILITY", "NO_ABILITY")
        mon = SIDES[0][1]
        g.poke(mon + "CatchRate", ITEMS["MYSTERYBERRY"])
        g.poke(mon + "PP", 9, 9, 0xC0, 9)
        g.poke("wLinkState", 4)  # LINK_STATE_BATTLING
        g.poke(SIDES[0][0] + "BattleStatus3", 0)
        self.after()
        g.poke("wLinkState", 0)
        self.assertEqual(g.peek(mon + "PP", 4), [9, 9, 0xC0, 9])
        self.assertEqual(g.peek(mon + "CatchRate"), ITEMS["MYSTERYBERRY"])


class BerryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def berry(self, item, side=0, hp=80, status=0, confused=False, in_battle=2):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.poke("wIsInBattle", in_battle)
        mon, prefix = ("wBattleMon", "wPlayer") if side == 0 else ("wEnemyMon", "wEnemy")
        g.poke(mon + "CatchRate", ITEMS[item])
        g.poke16(mon + "MaxHP", 200)
        g.poke16(mon + "HP", hp)
        g.poke(mon + "Status", status)
        g.poke(prefix + "BattleStatus1", CONFUSED if confused else 0)
        g.poke(prefix + "BattleStatus3", 0)
        g.poke16(mon + "Attack", 50)
        g.poke16(mon + "Speed", 50)  # paralysis halves it
        g.poke("wPlayerMonNumber", 1)
        g.poke("wPartyMon2CatchRate", ITEMS[item])
        g.poke("wEnemyMonPartyPos", 3)
        g.poke("wEnemyMon4CatchRate", ITEMS[item])
        g.call("CheckBerries", a=side, max_frames=4000)
        return (g.peek16(mon + "HP"), g.peek(mon + "Status"), bool(g.peek(prefix + "BattleStatus1") & CONFUSED),
                g.peek(mon + "CatchRate"))

    def test_hp_berries(self):
        b = ITEMS
        for side in (0, 1):
            with self.subTest(side=side):
                self.assertEqual(self.berry("BERRY", side, 80), (90, 0, False, 0))
                self.assertEqual(self.berry("BERRY", side, 100), (110, 0, False, 0))  # exactly half
                self.assertEqual(self.berry("BERRY", side, 101), (101, 0, False, b["BERRY"]))
                self.assertEqual(self.berry("GOLD_BERRY", side, 80), (110, 0, False, 0))
                self.assertEqual(self.berry("SITRUS_BERRY", side, 50), (100, 0, False, 0))
                self.assertEqual(self.berry("BERRY", side, 0), (0, 0, False, b["BERRY"]))  # fainted

    def test_status_berries(self):
        b = ITEMS
        for side in (0, 1):
            with self.subTest(side=side):
                self.assertEqual(self.berry("PRZCUREBERRY", side, 150, PAR)[1:], (0, False, 0))
                self.assertEqual(self.game.peek16(("wBattleMon", "wEnemyMon")[side] + "Speed"), 100)  # undone
                self.assertEqual(self.berry("MINT_BERRY", side, 150, 3)[1:], (0, False, 0))
                self.assertEqual(self.berry("PSNCUREBERRY", side, 150, PSN)[1:], (0, False, 0))
                self.assertEqual(self.berry("ICE_BERRY", side, 150, BRN)[1:], (0, False, 0))
                self.assertEqual(self.game.peek16(("wBattleMon", "wEnemyMon")[side] + "Attack"), 50)  # burn left the stat alone
                self.assertEqual(self.berry("BURNT_BERRY", side, 150, FRZ)[1:], (0, False, 0))
                self.assertEqual(self.berry("BITTER_BERRY", side, 150, confused=True)[1:], (0, False, 0))
                self.assertEqual(self.berry("MIRACLEBERRY", side, 150, PSN)[1:], (0, False, 0))
                self.assertEqual(self.berry("MIRACLEBERRY", side, 150, confused=True)[1:], (0, False, 0))
                self.assertEqual(self.berry("MINT_BERRY", side, 150, PSN)[1:], (PSN, False, b["MINT_BERRY"]))
                self.assertEqual(self.berry("BITTER_BERRY", side, 150)[1:], (0, False, b["BITTER_BERRY"]))

    def test_used_up_in_the_party_data(self):
        g = self.game
        self.berry("BERRY", 0, 80)
        self.assertEqual(g.peek("wPartyMon2CatchRate"), 0)
        self.berry("BERRY", 1, 80)
        self.assertEqual(g.peek("wEnemyMon4CatchRate"), 0)
        self.berry("BERRY", 1, 80, in_battle=1)  # a wild mon's roster isn't touched
        self.assertEqual(g.peek("wEnemyMon4CatchRate"), ITEMS["BERRY"])


class ResidualItemTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def residual(self, turn, item, hp, status=0):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(9))
        g.clear_random()
        g.poke("wPlayerAbility", 0, 0)
        g.poke(H_WHOSETURN, turn)
        g.poke("wLinkState", 0)
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        mon = SIDES[turn][1]
        g.poke(mon + "CatchRate", ITEMS[item])
        g.poke16(mon + "MaxHP", 160)
        g.poke16(mon + "HP", hp)
        g.poke(mon + "Status", status)
        g.call("HandlePoisonBurnLeechSeed", max_frames=4000)
        return g.peek16(mon + "HP")

    def test_leftovers(self):
        for turn in (0, 1):
            self.assertEqual(self.residual(turn, "LEFTOVERS", 100), 110)
            self.assertEqual(self.residual(turn, "LEFTOVERS", 160), 160)
            self.assertEqual(self.residual(turn, "LEFTOVERS", 155), 160)  # capped
            self.assertEqual(self.residual(turn, "LEFTOVERS", 100, PSN), 90)  # +10, then poison's 20 (1/8)

    def test_berry_at_the_end_of_a_turn(self):
        for turn in (0, 1):
            self.assertEqual(self.residual(turn, "SITRUS_BERRY", 60), 100)


class FleeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_smoke_ball(self):
        g = self.game
        g.reset()
        g.poke("wPlayerAbility", 0, ABILITIES["ARENA_TRAP"])
        g.poke("wLinkState", 0)
        g.poke("wBattleMonType1", NORMAL, NORMAL)
        items(g, "SMOKE_BALL")
        self.assertTrue(g.call("RunAwayOrTrapped")["carry"])


if __name__ == "__main__":
    unittest.main()
