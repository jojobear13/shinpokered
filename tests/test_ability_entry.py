"""Spec tests for abilities, part 4: entry, contact and field abilities
(design brief, plan step E, part 4).

Entry (once both mons are out, the faster first): Intimidate, Download,
Trace, Forewarn, and the announcements. Contact: Static, Poison Point, Flame
Body, Effect Spore. Field: Arena Trap, Run Away. Also Rivalry, and Transform
copying the ability.
"""

import random
import unittest

from test_options import decode

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from test_abilities import ABILITIES
from test_ability_damage import MOVES, SIDES, scaled
from test_ability_protection import set_abilities
from test_ability_reactions import ReactionTest
from test_special_split import SPECIES

NORMAL, FLYING, GHOST, GRASS, ELECTRIC, WATER = 0x00, 0x02, 0x08, 0x16, 0x17, 0x15
PSN, BRN, PAR = 1 << 3, 1 << 4, 1 << 6
BADLY_POISONED = 1 << 0
ENTRY_PLAYER, ENTRY_ENEMY = 1 << 3, 1 << 4
HAS_SUBSTITUTE_UP = 1 << 4
MOD_ATTACK, MOD_SPECIAL_ATTACK = 0, 3


class EntryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setup(self, player, enemy, pending=ENTRY_PLAYER | ENTRY_ENEMY, speeds=(100, 50)):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(0))
        g.clear_random()
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        g.poke("wPlayerMistTurns", 0, 0)
        for mon, prefix in (("wBattleMon", "wPlayerMon"), ("wEnemyMon", "wEnemyMon")):
            g.poke16(mon + "HP", 100)
            g.poke(mon + "Status", 0)
            for stat in ("Attack", "Defense", "SpecialAttack", "SpecialDefense"):
                g.poke16(mon + stat, 100)
                g.poke16(prefix + "Unmodified" + stat, 100)
            g.poke(prefix + "AttackMod", *[7] * 7)
        g.poke16("wBattleMonSpeed", speeds[0])
        g.poke16("wEnemyMonSpeed", speeds[1])
        g.poke("wObtainedBadges", 0)
        g.poke("wPlayerAbility", ABILITIES[player], ABILITIES[enemy])
        g.poke("wAbilityFlags", pending)
        g.poke(H_WHOSETURN, 1)

    def run_entry(self):
        g = self.game
        g.call("EntryAbilities", max_frames=6000)
        self.assertEqual(g.peek("wAbilityFlags") & (ENTRY_PLAYER | ENTRY_ENEMY), 0)
        self.assertEqual(g.peek(H_WHOSETURN), 1)  # put back

    def mods(self, side):
        return self.game.peek(("wPlayerMon", "wEnemyMon")[side] + "AttackMod", 7)

    def test_intimidate(self):
        g = self.game
        for side in (0, 1):
            abilities = ["NO_ABILITY", "NO_ABILITY"]
            abilities[side] = "INTIMIDATE"
            with self.subTest(side=side):
                self.setup(*abilities)
                self.run_entry()
                self.assertEqual(self.mods(1 - side)[MOD_ATTACK], 6)
                self.assertEqual(g.peek16(("wBattleMon", "wEnemyMon")[1 - side] + "Attack"), 66)
                self.assertEqual(self.mods(side)[MOD_ATTACK], 7)

    def test_intimidate_stopped(self):
        for blocker in ("HYPER_CUTTER", "CLEAR_BODY", "OBLIVIOUS", "INNER_FOCUS", "OWN_TEMPO", "SCRAPPY"):
            with self.subTest(blocker=blocker):
                self.setup("INTIMIDATE", blocker)
                self.run_entry()
                self.assertEqual(self.mods(1)[MOD_ATTACK], 7)
        for blocked in ("substitute", "mist"):
            with self.subTest(blocked=blocked):
                self.setup("INTIMIDATE", "NO_ABILITY")
                if blocked == "substitute":
                    self.game.poke("wEnemyBattleStatus2", HAS_SUBSTITUTE_UP)
                else:
                    self.game.poke("wEnemyMistTurns", 3)
                self.run_entry()
                self.assertEqual(self.mods(1)[MOD_ATTACK], 7)
        self.setup("INTIMIDATE", "NEUTRALIZING_GAS")
        self.run_entry()
        self.assertEqual(self.mods(1)[MOD_ATTACK], 7)

    def test_intimidate_into_competitive(self):
        self.setup("INTIMIDATE", "COMPETITIVE")
        self.run_entry()
        self.assertEqual((self.mods(1)[MOD_ATTACK], self.mods(1)[MOD_SPECIAL_ATTACK]), (6, 9))

    def test_both_sides_intimidate(self):
        for speeds in ((100, 50), (50, 100)):
            with self.subTest(speeds=speeds):
                self.setup("INTIMIDATE", "INTIMIDATE", speeds=speeds)
                self.run_entry()
                self.assertEqual((self.mods(0)[MOD_ATTACK], self.mods(1)[MOD_ATTACK]), (6, 6))

    def test_only_pending_sides(self):
        self.setup("INTIMIDATE", "INTIMIDATE", pending=ENTRY_ENEMY)
        self.run_entry()
        self.assertEqual((self.mods(0)[MOD_ATTACK], self.mods(1)[MOD_ATTACK]), (6, 7))

    def test_download(self):
        g = self.game
        for defense, special_defense, raised in ((80, 120, MOD_ATTACK), (120, 80, MOD_SPECIAL_ATTACK),
                                                 (100, 100, MOD_SPECIAL_ATTACK), (255, 256, MOD_ATTACK)):
            for side in (0, 1):
                with self.subTest(defense=defense, special_defense=special_defense, side=side):
                    abilities = ["NO_ABILITY", "NO_ABILITY"]
                    abilities[side] = "DOWNLOAD"
                    self.setup(*abilities, pending=(ENTRY_PLAYER, ENTRY_ENEMY)[side])
                    foe = ("wBattleMon", "wEnemyMon")[1 - side]
                    g.poke16(foe + "Defense", defense)
                    g.poke16(foe + "SpecialDefense", special_defense)
                    self.run_entry()
                    expected = [7] * 7
                    expected[raised] = 8
                    self.assertEqual(self.mods(side), expected)

    def test_trace(self):
        g = self.game
        self.setup("TRACE", "INTIMIDATE", pending=ENTRY_PLAYER)
        self.run_entry()
        self.assertEqual(g.peek("wPlayerAbility"), ABILITIES["INTIMIDATE"])
        self.assertEqual(self.mods(1)[MOD_ATTACK], 6)  # the traced Intimidate acted
        for foe in ("TRACE", "NO_ABILITY"):
            with self.subTest(foe=foe):
                self.setup("TRACE", foe, pending=ENTRY_PLAYER)
                self.run_entry()
                self.assertEqual(g.peek("wPlayerAbility"), ABILITIES["TRACE"])

    def test_announcements_and_forewarn_change_nothing(self):
        g = self.game
        for ability in ("PRESSURE", "MOLD_BREAKER", "NEUTRALIZING_GAS", "FOREWARN"):
            with self.subTest(ability=ability):
                self.setup(ability, "NO_ABILITY")
                g.poke("wEnemyMonMoves", MOVES["TACKLE"], MOVES["FISSURE"], 0, 0)
                self.run_entry()
                self.assertEqual(self.mods(0), [7] * 7)
                self.assertEqual(self.mods(1), [7] * 7)

    def test_forewarn_names_the_move(self):
        g = self.game
        self.setup("FOREWARN", "NO_ABILITY")
        g.poke("wEnemyMonMoves", MOVES["TACKLE"], MOVES["FISSURE"], 0, 0)
        self.run_entry()
        name = [g.peek(f"wcd6d+{i}") for i in range(13)]
        self.assertEqual(decode(name[:name.index(0x50)]), "FISSURE")

    def test_forewarn_power(self):
        g = self.game
        for move, power in (("FISSURE", 150), ("COUNTER", 120), ("SEISMIC_TOSS", 80), ("DRAGON_RAGE", 80),
                            ("HYPER_BEAM", 150), ("TACKLE", 40), ("SWORDS_DANCE", 0)):
            with self.subTest(move=move):
                g.reset()
                self.assertEqual(g.call("ForewarnPower", a=MOVES[move])["a"], power)


class ContactTest(unittest.TestCase):
    """Static, Poison Point, Flame Body, Effect Spore (through AbilityAfterMove)."""

    setUpClass = classmethod(ReactionTest.setUpClass.__func__)
    setup = ReactionTest.setup
    after = ReactionTest.after
    hit = ReactionTest.hit

    def contact(self, turn, target, move="TACKLE", roll=0, user="NO_ABILITY", user_types=(NORMAL, NORMAL),
                holder_badly_poisoned=False):
        g = self.game
        self.setup(turn, user, target, move)
        g.poke(SIDES[turn][1] + "Type1", *user_types)
        if holder_badly_poisoned:
            g.poke(SIDES[1 - turn][0] + "BattleStatus3", BADLY_POISONED)
        self.hit(turn)
        self.after(randoms=(roll,))
        return g.peek(SIDES[turn][1] + "Status")

    def test_contact_statuses(self):
        g = self.game
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.assertEqual(self.contact(turn, "STATIC", roll=76), PAR)
                self.assertEqual(self.contact(turn, "STATIC", roll=77), 0)
                self.assertEqual(self.contact(turn, "STATIC", "EMBER"), 0)  # no contact
                self.assertEqual(self.contact(turn, "STATIC", user_types=(ELECTRIC, ELECTRIC)), 0)
                self.assertEqual(self.contact(turn, "STATIC", user="LIMBER"), 0)
                self.assertEqual(self.contact(turn, "POISON_POINT", holder_badly_poisoned=True), PSN)
                self.assertEqual(g.peek(SIDES[turn][0] + "BattleStatus3") & BADLY_POISONED, 0)
                self.assertEqual(self.contact(turn, "FLAME_BODY"), BRN)
                self.assertEqual(g.peek16(SIDES[turn][1] + "Attack"), 100)  # burn halves damage, not the stat

    def test_effect_spore(self):
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.assertEqual(self.contact(turn, "EFFECT_SPORE", roll=27), 3)  # asleep
                self.assertEqual(self.contact(turn, "EFFECT_SPORE", roll=28), PSN)
                self.assertEqual(self.contact(turn, "EFFECT_SPORE", roll=50), PSN)
                self.assertEqual(self.contact(turn, "EFFECT_SPORE", roll=51), PAR)
                self.assertEqual(self.contact(turn, "EFFECT_SPORE", roll=76), PAR)
                self.assertEqual(self.contact(turn, "EFFECT_SPORE", roll=77), 0)
                self.assertEqual(self.contact(turn, "EFFECT_SPORE", roll=0, user="INSOMNIA"), 0)
                self.assertEqual(self.contact(turn, "EFFECT_SPORE", roll=0, user_types=(GRASS, WATER)), 0)

    def test_no_contact_effect_without_damage(self):
        g = self.game
        self.setup(0, "NO_ABILITY", "STATIC")
        self.after(randoms=(0,))
        self.assertEqual(g.peek("wBattleMonStatus"), 0)


class FieldTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def trapped(self, routine, abilities, types=(NORMAL, NORMAL), link=False):
        g = self.game
        g.reset()
        g.poke("wPlayerAbility", *[ABILITIES[a] for a in abilities])
        g.poke("wLinkState", 4 if link else 0)
        side = "wBattleMon" if routine == "PlayerTrapped" else "wEnemyMon"
        g.poke(side + "Type1", *types)
        return g.call(routine)["carry"]

    def test_arena_trap(self):
        self.assertTrue(self.trapped("PlayerTrapped", ("NO_ABILITY", "ARENA_TRAP")))
        self.assertTrue(self.trapped("EnemyTrapped", ("ARENA_TRAP", "NO_ABILITY")))
        self.assertFalse(self.trapped("PlayerTrapped", ("ARENA_TRAP", "NO_ABILITY")))
        self.assertFalse(self.trapped("PlayerTrapped", ("NO_ABILITY", "ARENA_TRAP"), (NORMAL, FLYING)))
        self.assertFalse(self.trapped("EnemyTrapped", ("ARENA_TRAP", "NO_ABILITY"), (GHOST, GHOST)))
        self.assertFalse(self.trapped("PlayerTrapped", ("LEVITATE", "ARENA_TRAP")))
        self.assertFalse(self.trapped("PlayerTrapped", ("NO_ABILITY", "ARENA_TRAP"), link=True))
        self.assertFalse(self.trapped("PlayerTrapped", ("NEUTRALIZING_GAS", "ARENA_TRAP")))

    def test_running(self):
        g = self.game
        for abilities, carry, z in ((("RUN_AWAY", "ARENA_TRAP"), True, None), (("NO_ABILITY", "ARENA_TRAP"), False, False),
                                    (("NO_ABILITY", "NO_ABILITY"), False, True)):
            with self.subTest(abilities=abilities):
                g.reset()
                g.poke("wPlayerAbility", *[ABILITIES[a] for a in abilities])
                g.poke("wLinkState", 0)
                g.poke("wBattleMonType1", NORMAL, NORMAL)
                out = g.call("RunAwayOrTrapped")
                self.assertEqual(out["carry"], carry)
                if z is not None:
                    self.assertEqual(out["z"], z)

    def test_transform_copies_the_ability(self):
        g = self.game
        for turn in (0, 1):
            g.reset()
            g.poke("wPlayerAbility", *[ABILITIES["LIMBER"], ABILITIES["STATIC"]][::1 - 2 * turn])
            g.poke(H_WHOSETURN, turn)
            g.call("TransformAbility")
            self.assertEqual(g.peek("wPlayerAbility", 2), [ABILITIES["STATIC"]] * 2)


class RivalryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def damage(self, user_species, foe_species, foe_gender_byte=0xFF, turn=0):
        g = self.game
        g.reset()
        g.poke(H_WHOSETURN, turn)
        set_abilities(g, turn, "RIVALRY", "NO_ABILITY")
        user, foe = SIDES[turn][1], SIDES[turn][2]
        g.poke(user + "Species", SPECIES[user_species])
        g.poke(user + "IVs", 0xFF, 0xFF, 0x00, 0xFC)  # gender byte $FF: male if it can be
        g.poke(foe + "Species", SPECIES[foe_species])
        g.poke(foe + "IVs", foe_gender_byte, 0xFF, 0x00, 0xFC)  # the first byte xor the third
        g.poke(SIDES[turn][0] + "MovePower", 80)
        g.poke(SIDES[turn][0] + "MoveType", NORMAL)
        g.poke16("wDamage", 100)
        g.poke("wDamageMultipliers", 10)
        g.poke("wUnusedC000", 0)
        g.call("AbilityDamageModifiers")
        return g.peek16("wDamage")

    def test_rivalry(self):
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.assertEqual(self.damage("NIDOKING", "NIDOKING", turn=turn), 125)
                self.assertEqual(self.damage("NIDOKING", "NIDOQUEEN", turn=turn), 75)
                self.assertEqual(self.damage("NIDOQUEEN", "CHANSEY", turn=turn), 125)
                self.assertEqual(self.damage("NIDOKING", "MAGNEMITE", turn=turn), 100)
                self.assertEqual(self.damage("NIDOKING", "PIKACHU", 0x80, turn), 125)  # a male Pikachu
                self.assertEqual(self.damage("NIDOKING", "PIKACHU", 0x7F, turn), 75)  # a female one


if __name__ == "__main__":
    unittest.main()
