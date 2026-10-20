"""Spec tests for abilities, part 3a: protection, side effects, accuracy and
HP (design brief, plan step E, part 4).

Status moves: Insomnia and Vital Spirit keep off sleep (and Rest), Immunity
poison, Limber paralysis, Own Tempo confusion; Clear Body any stat drop, Hyper
Cutter attack drops, Keen Eye and Illuminate accuracy drops. Damaging moves'
side effects: those, plus Water Veil (burn) and Inner Focus (flinch); Shield
Dust stops them all and Serene Grace doubles their chance. Damp stops
Explosion, Sturdy stops one-hit KO moves and survives a knockout at full HP,
Battle Armor and Shell Armor stop critical hits, Skill Link always hits five
times. Accuracy: Compound Eyes, Keen Eye, Illuminate, Tangled Feet, No Guard.
HP: Magic Guard, Rock Head, Liquid Ooze.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from test_abilities import ABILITIES
from test_ability_damage import MOVES, SIDES, mx_effects

EFFECTS = mx_effects()
GHOST, POISON_TYPE, NORMAL = 0x08, 0x03, 0x00
PSN, PAR = 1 << 3, 1 << 6
INVULNERABLE, CONFUSED, FLINCHED = 1 << 6, 1 << 7, 1 << 3
SEEDED = 1 << 7
STURDY_ENDURED = 1 << 2


def set_abilities(game, turn, user, target):
    game.poke("wPlayerAbility", *[ABILITIES[user], ABILITIES[target]][::1 - 2 * turn])


class GateTest(unittest.TestCase):
    """AbilityBlocksMove: status moves, Damp, Sturdy against one-hit KOs."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def blocked(self, move, target, turn=0, user="NO_ABILITY"):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(MOVES[move]))
        set_abilities(g, turn, user, target)
        prefix = SIDES[turn][0]
        g.poke(prefix + "SelectedMove", MOVES[move])
        g.poke(H_WHOSETURN, turn)
        g.call("GetCurrentMove")
        g.poke(SIDES[1 - turn][0] + "BattleStatus1", 0)
        return g.call("AbilityBlocksMove", max_frames=2000)["carry"]

    def test_status_moves(self):
        cases = [
            ("SING", "INSOMNIA"), ("HYPNOSIS", "VITAL_SPIRIT"), ("SPORE", "INSOMNIA"),
            ("TOXIC", "IMMUNITY"), ("POISONPOWDER", "IMMUNITY"),
            ("THUNDER_WAVE", "LIMBER"), ("GLARE", "LIMBER"), ("STUN_SPORE", "LIMBER"),
            ("CONFUSE_RAY", "OWN_TEMPO"), ("SUPERSONIC", "OWN_TEMPO"),
            ("GROWL", "HYPER_CUTTER"), ("GROWL", "CLEAR_BODY"), ("SCREECH", "CLEAR_BODY"),
            ("STRING_SHOT", "CLEAR_BODY"), ("SAND_ATTACK", "KEEN_EYE"), ("FLASH", "ILLUMINATE"),
            ("SMOKESCREEN", "CLEAR_BODY"),
        ]
        for move, ability in cases:
            for turn in (0, 1):
                with self.subTest(move=move, ability=ability, turn=turn):
                    self.assertTrue(self.blocked(move, ability, turn))

    def test_what_gets_through(self):
        cases = [
            ("LEER", "HYPER_CUTTER"), ("SAND_ATTACK", "HYPER_CUTTER"), ("GROWL", "KEEN_EYE"),
            ("SING", "LIMBER"), ("TOXIC", "INSOMNIA"),
            ("BODY_SLAM", "LIMBER"), ("AURORA_BEAM", "HYPER_CUTTER"), ("PSYCHIC_M", "CLEAR_BODY"),
            ("EMBER", "WATER_VEIL"),  # side effects are only kept off, not the hit
            ("SWORDS_DANCE", "CLEAR_BODY"),
        ]
        for move, ability in cases:
            with self.subTest(move=move, ability=ability):
                self.assertFalse(self.blocked(move, ability))
        self.assertFalse(self.blocked("SING", "INSOMNIA", user="MOLD_BREAKER"))
        self.assertFalse(self.blocked("THUNDER_WAVE", "LIMBER", user="NEUTRALIZING_GAS"))

    def test_damp(self):
        for move in ("EXPLOSION", "SELFDESTRUCT"):
            for turn in (0, 1):
                with self.subTest(move=move, turn=turn):
                    self.assertTrue(self.blocked(move, "DAMP", turn))
                    self.assertTrue(self.blocked(move, "NO_ABILITY", turn, user="DAMP"))
                    self.assertFalse(self.blocked(move, "DAMP", turn, user="MOLD_BREAKER"))
                    self.assertFalse(self.blocked(move, "STURDY", turn))
                    # the user is still standing
                    self.blocked(move, "DAMP", turn)
                    self.assertNotEqual(self.game.peek16(SIDES[turn][1] + "HP"), 0)

    def test_sturdy_stops_one_hit_ko_moves(self):
        for move in ("FISSURE", "HORN_DRILL", "GUILLOTINE"):
            self.assertTrue(self.blocked(move, "STURDY"))
            self.assertFalse(self.blocked(move, "STURDY", user="MOLD_BREAKER"))
        self.assertFalse(self.blocked("TACKLE", "STURDY"))


class SideEffectChanceTest(unittest.TestCase):
    """AbilitySideEffectChance, on wSideEffectChance before the roll."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def chance(self, effect, target="NO_ABILITY", user="NO_ABILITY", chance=0x4D, turn=0):
        g = self.game
        g.reset()
        set_abilities(g, turn, user, target)
        g.poke(H_WHOSETURN, turn)
        g.poke(SIDES[turn][0] + "MoveEffect", EFFECTS[effect])
        g.poke("wSideEffectChance", chance)
        g.call("AbilitySideEffectChance")
        return g.peek("wSideEffectChance")

    def test_unchanged_without_abilities(self):
        for effect in ("PARALYZE_SIDE_EFFECT2", "BURN_SIDE_EFFECT1", "FLINCH_SIDE_EFFECT2"):
            self.assertEqual(self.chance(effect), 0x4D)

    def test_immunities(self):
        cases = [
            ("PARALYZE_SIDE_EFFECT1", "LIMBER"), ("PARALYZE_SIDE_EFFECT2", "LIMBER"),
            ("BURN_SIDE_EFFECT1", "WATER_VEIL"), ("BURN_SIDE_EFFECT2", "WATER_VEIL"),
            ("POISON_SIDE_EFFECT1", "IMMUNITY"), ("POISON_SIDE_EFFECT2", "IMMUNITY"),
            ("FLINCH_SIDE_EFFECT1", "INNER_FOCUS"), ("FLINCH_SIDE_EFFECT2", "INNER_FOCUS"),
            ("CONFUSION_SIDE_EFFECT", "OWN_TEMPO"),
            ("ATTACK_DOWN_SIDE_EFFECT", "HYPER_CUTTER"), ("ATTACK_DOWN_SIDE_EFFECT", "CLEAR_BODY"),
            ("SPECIAL_DEFENSE_DOWN_SIDE_EFFECT", "CLEAR_BODY"), ("SPEED_DOWN_SIDE_EFFECT", "CLEAR_BODY"),
        ]
        for effect, ability in cases:
            for turn in (0, 1):
                with self.subTest(effect=effect, ability=ability, turn=turn):
                    self.assertEqual(self.chance(effect, ability, turn=turn), 0)
        self.assertEqual(self.chance("DEFENSE_DOWN_SIDE_EFFECT", "HYPER_CUTTER"), 0x4D)
        self.assertEqual(self.chance("FREEZE_SIDE_EFFECT", "WATER_VEIL"), 0x4D)
        self.assertEqual(self.chance("PARALYZE_SIDE_EFFECT1", "INSOMNIA"), 0x4D)

    def test_shield_dust(self):
        for effect in ("FREEZE_SIDE_EFFECT", "FLINCH_SIDE_EFFECT1", "SPECIAL_DOWN_SIDE_EFFECT"):
            self.assertEqual(self.chance(effect, "SHIELD_DUST"), 0)
        self.assertEqual(self.chance("FREEZE_SIDE_EFFECT", "SHIELD_DUST", "MOLD_BREAKER"), 0x4D)

    def test_serene_grace(self):
        self.assertEqual(self.chance("FLINCH_SIDE_EFFECT2", user="SERENE_GRACE", chance=0x4D), 0x9A)
        self.assertEqual(self.chance("FLINCH_SIDE_EFFECT2", user="SERENE_GRACE", chance=0x90, turn=1), 0xFF)
        self.assertEqual(self.chance("FLINCH_SIDE_EFFECT2", "INNER_FOCUS", "SERENE_GRACE"), 0)

    def test_roll_uses_one_random_number(self):
        g = self.game
        for roll, chance, target, happens in ((0x10, 0x1A, "NO_ABILITY", True), (0x1A, 0x1A, "NO_ABILITY", False),
                                              (0x00, 0x1A, "SHIELD_DUST", False)):
            with self.subTest(roll=roll, target=target):
                g.reset()
                set_abilities(g, 0, "NO_ABILITY", target)
                g.poke(H_WHOSETURN, 0)
                g.poke("wLinkState", 0)
                g.poke("wPlayerMoveEffect", EFFECTS["FLINCH_SIDE_EFFECT1"])
                g.queue_random(roll)
                out = g.call("RollSideEffect", bc=chance << 8 | 0x34, de=0x5678, hl=0x9ABC)
                self.assertEqual(out["carry"], happens)
                self.assertEqual((out["bc"], out["de"], out["hl"]), (chance << 8 | 0x34, 0x5678, 0x9ABC))
                self.assertEqual(g.random_used(), 1)


class AccuracyTest(unittest.TestCase):
    """CalcHitChance (moved to bank 9 with the abilities)."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def model(self, accuracy, acc_mod, eva_mod):
        """Gen 9: one net stage, accuracy minus evasion, from -6 to +6."""
        net = max(-6, min(6, acc_mod - eva_mod))
        n, d = (3 + net, 3) if net >= 0 else (3, 3 - net)
        return min(max(accuracy * n // d, 1), 255)

    def hit_chance(self, accuracy, acc_mod=7, eva_mod=7, user="NO_ABILITY", target="NO_ABILITY", turn=0,
                   confused=False):
        g = self.game
        g.reset()
        set_abilities(g, turn, user, target)
        g.poke(H_WHOSETURN, turn)
        prefix = SIDES[turn][0]
        target_prefix = SIDES[1 - turn][0]
        g.poke(prefix + "MoveAccuracy", accuracy)
        g.poke(prefix + "MonAccuracyMod", acc_mod)
        g.poke(target_prefix + "MonEvasionMod", eva_mod)
        g.poke(target_prefix + "BattleStatus1", CONFUSED if confused else 0)
        g.call("CalcHitChance")
        return g.peek(prefix + "MoveAccuracy")

    def test_matches_gen9_without_abilities(self):
        rng = random.Random(3)
        for _ in range(60):
            accuracy, acc_mod, eva_mod, turn = rng.randint(1, 255), rng.randint(1, 13), rng.randint(1, 13), rng.randint(0, 1)
            with self.subTest(accuracy=accuracy, acc=acc_mod, eva=eva_mod, turn=turn):
                self.assertEqual(self.hit_chance(accuracy, acc_mod, eva_mod, turn=turn),
                                 self.model(accuracy, acc_mod, eva_mod))

    def test_compound_eyes(self):
        self.assertEqual(self.hit_chance(178, user="COMPOUND_EYES"), 178 * 13 // 10)
        self.assertEqual(self.hit_chance(255, user="COMPOUND_EYES", turn=1), 255)

    def test_keen_eye_ignores_raised_evasion(self):
        for ability in ("KEEN_EYE", "ILLUMINATE"):
            self.assertEqual(self.hit_chance(255, eva_mod=10, user=ability), 255)
            self.assertEqual(self.hit_chance(200, eva_mod=4, user=ability), self.model(200, 7, 4))
        self.assertEqual(self.hit_chance(255, eva_mod=10), self.model(255, 7, 10))

    def test_tangled_feet(self):
        self.assertEqual(self.hit_chance(255, target="TANGLED_FEET", confused=True), 127)
        self.assertEqual(self.hit_chance(255, target="TANGLED_FEET"), 255)
        self.assertEqual(self.hit_chance(255, target="TANGLED_FEET", user="MOLD_BREAKER", confused=True), 255)

    def test_no_guard(self):
        for user, target in (("NO_GUARD", "NO_ABILITY"), ("NO_ABILITY", "NO_GUARD")):
            self.assertEqual(self.hit_chance(30, acc_mod=1, eva_mod=13, user=user, target=target), 255)

    def test_no_guard_hits_through_fly_and_dig(self):
        g = self.game
        for user, missed in (("NO_GUARD", 0), ("NO_ABILITY", 1)):
            with self.subTest(user=user):
                g.reset()
                mx.setup(g, random.Random(1))
                set_abilities(g, 0, user, "NO_ABILITY")
                g.poke("wPlayerSelectedMove", MOVES["TACKLE"])
                g.poke(H_WHOSETURN, 0)
                g.call("GetCurrentMove")
                g.poke("wEnemyBattleStatus1", INVULNERABLE)
                g.poke("wEnemyBattleStatus2", 0)
                g.poke("wMoveMissed", 0)
                g.call("MoveHitTest")
                self.assertEqual(g.peek("wMoveMissed"), missed)


class HPTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setup_mons(self, seed=0):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(seed))
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        for mon in ("wBattleMon", "wEnemyMon"):
            g.poke16(mon + "MaxHP", 200)
            g.poke16(mon + "HP", 200)
            g.poke(mon + "Status", 0)
        g.poke("wAbilityFlags", 0)

    def test_sturdy(self):
        g = self.game
        for turn in (0, 1):
            target = SIDES[turn][2]
            routine = "ApplyDamageToEnemyPokemon" if turn == 0 else "ApplyDamageToPlayerPokemon"
            for target_ability, user, hp, survives in (("STURDY", "NO_ABILITY", 200, True),
                                                       ("STURDY", "NO_ABILITY", 199, False),
                                                       ("STURDY", "MOLD_BREAKER", 200, False),
                                                       ("NO_ABILITY", "NO_ABILITY", 200, False)):
                with self.subTest(turn=turn, ability=target_ability, user=user, hp=hp):
                    self.setup_mons()
                    set_abilities(g, turn, user, target_ability)
                    g.poke(H_WHOSETURN, turn)
                    g.poke16(target + "HP", hp)
                    g.poke16("wDamage", 500)
                    g.call(routine, max_frames=2000)
                    self.assertEqual(g.peek16(target + "HP"), 1 if survives else 0)
                    self.assertEqual(bool(g.peek("wAbilityFlags") & STURDY_ENDURED), survives)
                    g.call("AbilityAfterMove", max_frames=2000)
                    self.assertEqual(g.peek("wAbilityFlags") & STURDY_ENDURED, 0)
        # damage to its own side (a crash) isn't a foe's hit
        self.setup_mons()
        set_abilities(g, 0, "STURDY", "NO_ABILITY")
        g.poke(H_WHOSETURN, 0)
        g.poke16("wDamage", 500)
        g.call("ApplyDamageToPlayerPokemon", max_frames=2000)
        self.assertEqual(g.peek16("wBattleMonHP"), 0)

    def test_magic_guard_residual(self):
        g = self.game
        for turn in (0, 1):
            mon = SIDES[turn][1]
            prefix = SIDES[turn][0]
            for ability, expected in (("MAGIC_GUARD", 200), ("NO_ABILITY", 200 - 25 - 25)):
                with self.subTest(turn=turn, ability=ability):
                    self.setup_mons()
                    set_abilities(g, turn, ability, "NO_ABILITY")
                    g.poke(H_WHOSETURN, turn)
                    g.poke(mon + "Status", PSN)
                    g.poke(prefix + "BattleStatus2", SEEDED)
                    out = g.call("HandlePoisonBurnLeechSeed", max_frames=3000)
                    self.assertEqual(g.peek16(mon + "HP"), expected)
                    self.assertFalse(out["z"])

    def test_liquid_ooze_leech_seed(self):
        g = self.game
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.setup_mons()
                set_abilities(g, turn, "LIQUID_OOZE", "NO_ABILITY")
                g.poke(H_WHOSETURN, turn)
                g.poke(SIDES[turn][0] + "BattleStatus2", SEEDED)
                g.call("HandlePoisonBurnLeechSeed", max_frames=3000)
                self.assertEqual(g.peek16(SIDES[turn][1] + "HP"), 200 - 25)  # Leech Seed: 1/8
                self.assertEqual(g.peek16(SIDES[turn][2] + "HP"), 200 - 25)  # the seeder

    def test_liquid_ooze_drain(self):
        g = self.game
        for turn in (0, 1):
            for target, user, expected in (("LIQUID_OOZE", "NO_ABILITY", 150 - 30),
                                           ("LIQUID_OOZE", "MAGIC_GUARD", 150),
                                           ("LIQUID_OOZE", "MOLD_BREAKER", 150 - 30),
                                           ("NO_ABILITY", "NO_ABILITY", 150 + 30)):
                with self.subTest(turn=turn, target=target, user=user):
                    self.setup_mons()
                    set_abilities(g, turn, user, target)
                    g.poke(H_WHOSETURN, turn)
                    g.poke(SIDES[turn][0] + "MoveEffect", EFFECTS["DRAIN_HP_EFFECT"])
                    g.poke16(SIDES[turn][1] + "HP", 150)
                    g.poke16("wDamage", 60)
                    g.call("DrainHPEffect", max_frames=3000)
                    self.assertEqual(g.peek16(SIDES[turn][1] + "HP"), expected)

    def test_recoil(self):
        g = self.game
        for move, ability, expected in (("DOUBLE_EDGE", "ROCK_HEAD", 200), ("DOUBLE_EDGE", "MAGIC_GUARD", 200),
                                        ("DOUBLE_EDGE", "NO_ABILITY", 200 - 33), ("STRUGGLE", "ROCK_HEAD", 200 - 50),
                                        ("STRUGGLE", "MAGIC_GUARD", 200)):
            for turn in (0, 1):
                with self.subTest(move=move, ability=ability, turn=turn):
                    self.setup_mons()
                    set_abilities(g, turn, ability, "NO_ABILITY")
                    g.poke(H_WHOSETURN, turn)
                    g.poke(SIDES[turn][0] + "MoveNum", MOVES[move])
                    g.poke16("wDamage", 100)
                    g.call("RecoilEffect", max_frames=3000)
                    self.assertEqual(g.peek16(SIDES[turn][1] + "HP"), expected)

    def test_magic_guard_stops_crash_damage(self):
        g = self.game
        for ability, crashed in (("MAGIC_GUARD", False), ("NO_ABILITY", True)):
            with self.subTest(ability=ability):
                self.setup_mons(4)
                set_abilities(g, 0, ability, "NO_ABILITY")
                g.poke("wBattleMonMoves", MOVES["HI_JUMP_KICK"], 0, 0, 0)
                g.poke("wBattleMonPP", 10, 0, 0, 0)
                g.poke("wPlayerSelectedMove", MOVES["HI_JUMP_KICK"])
                g.poke("wPlayerMoveListIndex", 0)
                g.poke(H_WHOSETURN, 0)
                g.call("GetCurrentMove")
                g.poke("wEnemyBattleStatus1", INVULNERABLE)  # in the air: the kick misses
                out = mx.run(g, "player")
                self.assertNotIn("error", out)
                self.assertEqual(g.peek16("wBattleMonHP") < 200, crashed)


class MiscTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_skill_link(self):
        g = self.game
        for turn in (0, 1):
            for ability, hits in (("SKILL_LINK", 5), ("NO_ABILITY", None)):
                with self.subTest(turn=turn, ability=ability):
                    g.reset()
                    set_abilities(g, turn, ability, "NO_ABILITY")
                    g.poke(H_WHOSETURN, turn)
                    g.poke("wLinkState", 0)
                    prefix = SIDES[turn][0]
                    g.poke(prefix + "BattleStatus1", 0)
                    g.poke(prefix + "MoveEffect", EFFECTS["TWO_TO_FIVE_ATTACKS_EFFECT"])
                    g.queue_random(0, 0)
                    g.call("TwoToFiveAttacksEffect")
                    if hits:
                        self.assertEqual(g.peek(prefix + "NumAttacksLeft"), 5)
                        self.assertEqual(g.random_used(), 0)
                    else:
                        self.assertEqual(g.peek(prefix + "NumAttacksLeft"), 2)
        # Double Kick still hits twice
        g.reset()
        set_abilities(g, 0, "SKILL_LINK", "NO_ABILITY")
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerBattleStatus1", 0)
        g.poke("wPlayerMoveEffect", EFFECTS["ATTACK_TWICE_EFFECT"])
        g.call("TwoToFiveAttacksEffect")
        self.assertEqual(g.peek("wPlayerNumAttacksLeft"), 2)

    def test_armor_stops_critical_hits(self):
        g = self.game
        for turn in (0, 1):
            for target, user, crit in (("BATTLE_ARMOR", "NO_ABILITY", 0), ("SHELL_ARMOR", "NO_ABILITY", 0),
                                       ("SHELL_ARMOR", "MOLD_BREAKER", 1), ("NO_ABILITY", "NO_ABILITY", 1)):
                with self.subTest(turn=turn, target=target, user=user):
                    g.reset()
                    set_abilities(g, turn, user, target)
                    g.poke(H_WHOSETURN, turn)
                    g.poke("wLinkState", 0)
                    g.poke("wBattleMonSpecies", 0x28)  # any species: the rate comes from its base speed
                    g.poke("wEnemyMonSpecies", 0x28)
                    g.poke(SIDES[turn][0] + "BattleStatus2", 0)
                    g.poke(SIDES[turn][0] + "MoveNum", MOVES["SLASH"])
                    g.poke(SIDES[turn][0] + "MovePower", 70)
                    g.queue_random(0)  # would always be a critical hit
                    g.call("CriticalHitTest")
                    self.assertEqual(g.peek("wCriticalHitOrOHKO"), crit)

    def test_insomnia_stops_rest(self):
        g = self.game
        for ability, slept in (("INSOMNIA", False), ("VITAL_SPIRIT", False), ("NO_ABILITY", True)):
            with self.subTest(ability=ability):
                g.reset()
                mx.setup(g, random.Random(2))
                set_abilities(g, 0, ability, "NO_ABILITY")
                g.poke(H_WHOSETURN, 0)
                g.poke("wPlayerMoveNum", MOVES["REST"])
                g.poke("wPlayerMoveEffect", EFFECTS["HEAL_EFFECT"])
                g.poke16("wBattleMonMaxHP", 200)
                g.poke16("wBattleMonHP", 100)
                g.poke("wBattleMonStatus", 0)
                g.call("HealEffect", max_frames=3000)
                self.assertEqual(g.peek("wBattleMonStatus") != 0, slept)
                self.assertEqual(g.peek16("wBattleMonHP"), 200 if slept else 100)


if __name__ == "__main__":
    unittest.main()
