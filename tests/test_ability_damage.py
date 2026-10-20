"""Spec tests for abilities, part 2: the abilities that change damage or stop
a move (design brief, plan step E, part 4).

Stopping a move: once a move is announced, before accuracy (as from Gen 5),
the target's Levitate, Volt Absorb, Water Absorb, Dry Skin, Lightning Rod,
Flash Fire or Soundproof can take it. Damage: Technician, Iron Fist, Reckless,
Adaptability, Tinted Lens, Sniper, Guts, Overgrow, Blaze, Torrent, Swarm and an
active Flash Fire raise the user's damage; Thick Fat, Filter and Dry Skin
change the target's. Scrappy lets Normal and Fighting moves hit Ghosts.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from test_abilities import ABILITIES
from test_move_categories import MOVES


NORMAL, FIGHTING, GROUND, BUG, GHOST = 0x00, 0x01, 0x04, 0x07, 0x08
POISON = 0x03
FIRE, WATER, GRASS, ELECTRIC, ICE = 0x14, 0x15, 0x16, 0x17, 0x19
STAB = 0x80
SLP, PSN, BRN, PAR = 0x03, 1 << 3, 1 << 4, 1 << 6
SPECIAL_SIDE = 1 << 1  # hBattleSide: the move uses the special stats
MOD_SPECIAL_ATTACK = 3
FLASH_FIRE_PLAYER, FLASH_FIRE_ENEMY = 1 << 0, 1 << 1
SIDES = {0: ("wPlayer", "wBattleMon", "wEnemyMon"), 1: ("wEnemy", "wEnemyMon", "wBattleMon")}


def h_battle_side(game):
    return game.addr("hBattleSide") if "hBattleSide" in game.symbols else 0xFFE2


def scaled(damage, *ratios):
    for n, d in ratios:
        damage = min(damage * n // d, 0xFFFF) or 1
    return damage


class DamageModifierTest(unittest.TestCase):
    """AbilityDamageModifiers (stage S3), on the damage after type effectiveness."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def run_s3(self, turn=0, user="NO_ABILITY", target="NO_ABILITY", move="TACKLE", move_type=NORMAL,
               power=40, effect=None, damage=100, multipliers=10, crit=0, status=0, hp=(100, 100),
               special=False, flags=0, fixed=False):
        g = self.game
        g.reset()
        prefix, user_mon, _ = SIDES[turn]
        g.poke(H_WHOSETURN, turn)
        g.poke(h_battle_side(g), turn | (SPECIAL_SIDE if special else 0))
        abilities = [ABILITIES[user], ABILITIES[target]][::1 - 2 * turn]
        g.poke("wPlayerAbility", *abilities)
        g.poke("wAbilityFlags", flags)
        g.poke(prefix + "MoveNum", MOVES[move])
        if effect is not None:
            g.poke(prefix + "MoveEffect", effect)
        g.poke(prefix + "MovePower", power)
        g.poke(prefix + "MoveType", move_type)
        g.poke16("wDamage", damage)
        g.poke("wDamageMultipliers", multipliers)
        g.poke("wCriticalHitOrOHKO", crit)
        g.poke(user_mon + "Status", status)
        g.poke16(user_mon + "HP", hp[0])
        g.poke16(user_mon + "MaxHP", hp[1])
        g.poke("wUnusedC000", 1 << 4 if fixed else 0)
        g.call("AbilityDamageModifiers")
        return g.peek16("wDamage")

    def test_no_ability(self):
        for turn in (0, 1):
            self.assertEqual(self.run_s3(turn=turn), 100)

    def test_technician(self):
        for turn in (0, 1):
            self.assertEqual(self.run_s3(turn, "TECHNICIAN", power=60), 150)
            self.assertEqual(self.run_s3(turn, "TECHNICIAN", power=61), 100)

    def test_iron_fist(self):
        self.assertEqual(self.run_s3(0, "IRON_FIST", move="FIRE_PUNCH", move_type=FIRE), 120)
        self.assertEqual(self.run_s3(1, "IRON_FIST", move="COMET_PUNCH"), 120)
        self.assertEqual(self.run_s3(0, "IRON_FIST", move="KARATE_CHOP"), 100)

    def test_reckless(self):
        effects = mx_effects()
        self.assertEqual(self.run_s3(0, "RECKLESS", move="DOUBLE_EDGE", effect=effects["RECOIL_EFFECT"]), 120)
        self.assertEqual(self.run_s3(1, "RECKLESS", move="HI_JUMP_KICK", effect=effects["JUMP_KICK_EFFECT"]), 120)
        self.assertEqual(self.run_s3(0, "RECKLESS", move="STRUGGLE", effect=effects["RECOIL_EFFECT"]), 100)
        self.assertEqual(self.run_s3(0, "RECKLESS", move="TACKLE", effect=0), 100)

    def test_adaptability(self):
        self.assertEqual(self.run_s3(0, "ADAPTABILITY", damage=150, multipliers=STAB | 10), 200)
        self.assertEqual(self.run_s3(1, "ADAPTABILITY", damage=150, multipliers=10), 150)

    def test_tinted_lens(self):
        self.assertEqual(self.run_s3(0, "TINTED_LENS", multipliers=5), 200)
        self.assertEqual(self.run_s3(1, "TINTED_LENS", multipliers=2), 200)
        self.assertEqual(self.run_s3(0, "TINTED_LENS", multipliers=10), 100)

    def test_sniper(self):
        self.assertEqual(self.run_s3(0, "SNIPER", crit=1), 150)
        self.assertEqual(self.run_s3(1, "SNIPER", crit=0), 100)

    def test_guts(self):
        for status in (SLP, PSN, PAR):
            self.assertEqual(self.run_s3(0, "GUTS", status=status), 150)
        # burn halves damage in DamageModifiers, which Guts skips: here it's just x1.5
        self.assertEqual(self.run_s3(1, "GUTS", status=BRN), 150)
        self.assertEqual(self.run_s3(0, "GUTS", status=BRN, crit=1), 150)
        self.assertEqual(self.run_s3(0, "GUTS", status=PSN, special=True), 100)
        self.assertEqual(self.run_s3(0, "GUTS", status=0), 100)

    def test_pinch_abilities(self):
        for ability, move_type in (("OVERGROW", GRASS), ("BLAZE", FIRE), ("TORRENT", WATER), ("SWARM", BUG)):
            for turn in (0, 1):
                with self.subTest(ability=ability, turn=turn):
                    self.assertEqual(self.run_s3(turn, ability, move_type=move_type, hp=(33, 99)), 150)
                    self.assertEqual(self.run_s3(turn, ability, move_type=move_type, hp=(34, 99)), 100)
                    self.assertEqual(self.run_s3(turn, ability, move_type=NORMAL, hp=(1, 99)), 100)

    def test_flash_fire_boost(self):
        self.assertEqual(self.run_s3(0, "FLASH_FIRE", move_type=FIRE, flags=FLASH_FIRE_PLAYER), 150)
        self.assertEqual(self.run_s3(0, "FLASH_FIRE", move_type=FIRE, flags=FLASH_FIRE_ENEMY), 100)
        self.assertEqual(self.run_s3(1, "FLASH_FIRE", move_type=FIRE, flags=FLASH_FIRE_ENEMY), 150)
        self.assertEqual(self.run_s3(1, "FLASH_FIRE", move_type=WATER, flags=FLASH_FIRE_ENEMY), 100)

    def test_target_abilities(self):
        for turn in (0, 1):
            self.assertEqual(self.run_s3(turn, target="THICK_FAT", move_type=FIRE), 50)
            self.assertEqual(self.run_s3(turn, target="THICK_FAT", move_type=ICE), 50)
            self.assertEqual(self.run_s3(turn, target="THICK_FAT", move_type=WATER), 100)
            self.assertEqual(self.run_s3(turn, target="FILTER", multipliers=20), 75)
            self.assertEqual(self.run_s3(turn, target="FILTER", multipliers=STAB | 40), 75)
            self.assertEqual(self.run_s3(turn, target="FILTER", multipliers=10), 100)
            self.assertEqual(self.run_s3(turn, target="DRY_SKIN", move_type=FIRE), 125)

    def test_mold_breaker_and_gas(self):
        self.assertEqual(self.run_s3(0, "MOLD_BREAKER", "THICK_FAT", move_type=FIRE), 100)
        self.assertEqual(self.run_s3(0, "NEUTRALIZING_GAS", "THICK_FAT", move_type=FIRE), 100)
        self.assertEqual(self.run_s3(0, "TECHNICIAN", "NEUTRALIZING_GAS", power=40), 100)

    def test_both_sides_and_rounding(self):
        self.assertEqual(self.run_s3(0, "TECHNICIAN", "THICK_FAT", move_type=FIRE, power=40, damage=101),
                         scaled(101, (3, 2), (1, 2)))
        self.assertEqual(self.run_s3(0, target="THICK_FAT", move_type=ICE, damage=1), 1)  # at least 1
        self.assertEqual(self.run_s3(0, "TINTED_LENS", multipliers=5, damage=0x9000), 0xFFFF)

    def test_fixed_damage_is_untouched(self):
        self.assertEqual(self.run_s3(0, "TECHNICIAN", "THICK_FAT", move_type=FIRE, fixed=True), 100)


def mx_effects():
    import os
    import re
    from harness import REPO_ROOT
    values = {}
    with open(os.path.join(REPO_ROOT, "constants", "move_effect_constants.asm")) as f:
        for line in f:
            m = re.match(r"\s*const (\w+)\s*; \$([0-9A-F]{2})", line)
            if m:
                values[m.group(1)] = int(m.group(2), 16)
    return values


class BlockingTest(unittest.TestCase):
    """AbilityBlocksMove, with the user's move loaded the way the game does."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def block(self, move, target_ability, turn=0, user_ability="NO_ABILITY", hp=(50, 200),
              invulnerable=False, special_attack_stage=7, flags=0):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(MOVES[move]))
        prefix, _, target_mon = SIDES[turn]
        target_prefix = SIDES[1 - turn][0]
        abilities = [ABILITIES[user_ability], ABILITIES[target_ability]][::1 - 2 * turn]
        g.poke("wPlayerAbility", *abilities)
        g.poke("wAbilityFlags", flags)
        g.poke(prefix + "SelectedMove", MOVES[move])
        g.poke(H_WHOSETURN, turn)
        g.call("GetCurrentMove")
        g.poke(target_prefix + "BattleStatus1", 1 << 6 if invulnerable else 0)
        g.poke16(target_mon + "HP", hp[0])
        g.poke16(target_mon + "MaxHP", hp[1])
        g.poke(target_prefix + "MonAttackMod", 7, 7, 7, special_attack_stage, 7, 7, 7)
        g.poke16(("wPlayerMonUnmodified" if turn else "wEnemyMonUnmodified") + "SpecialAttack", 100)
        g.poke16(target_mon + "SpecialAttack", 100)
        out = g.call("AbilityBlocksMove", max_frames=2000)
        return out["carry"]

    def target_hp(self, turn=0):
        return self.game.peek16(SIDES[turn][2] + "HP")

    def test_levitate(self):
        for turn in (0, 1):
            with self.subTest(turn=turn):
                self.assertTrue(self.block("EARTHQUAKE", "LEVITATE", turn))
                self.assertTrue(self.block("FISSURE", "LEVITATE", turn))
                self.assertFalse(self.block("SAND_ATTACK", "LEVITATE", turn))  # not an attack
                self.assertFalse(self.block("TACKLE", "LEVITATE", turn))

    def test_absorbing_heals_a_quarter(self):
        for move, ability in (("THUNDERBOLT", "VOLT_ABSORB"), ("THUNDER_WAVE", "VOLT_ABSORB"),
                              ("SURF", "WATER_ABSORB"), ("WATER_GUN", "DRY_SKIN")):
            for turn in (0, 1):
                with self.subTest(move=move, turn=turn):
                    self.assertTrue(self.block(move, ability, turn, hp=(50, 201)))
                    self.assertEqual(self.target_hp(turn), 100)
                    self.assertTrue(self.block(move, ability, turn, hp=(190, 201)))
                    self.assertEqual(self.target_hp(turn), 201)
                    self.assertTrue(self.block(move, ability, turn, hp=(201, 201)))
                    self.assertEqual(self.target_hp(turn), 201)
                    self.assertTrue(self.block(move, ability, turn, hp=(1, 3)))
                    self.assertEqual(self.target_hp(turn), 2)  # at least 1
        self.assertFalse(self.block("WITHDRAW", "WATER_ABSORB"))  # a water move on the user itself

    def test_lightning_rod(self):
        for turn in (0, 1):
            with self.subTest(turn=turn):
                target_prefix = SIDES[1 - turn][0]
                target_mon = SIDES[turn][2]
                self.assertTrue(self.block("THUNDERSHOCK", "LIGHTNING_ROD", turn))
                self.assertEqual(self.game.peek(target_prefix + "MonAttackMod", 7), [7, 7, 7, 8, 7, 7, 7])
                # 100 at +1 is 150 (no badge boosts since the Gen 9 pass)
                self.assertEqual(self.game.peek16(target_mon + "SpecialAttack"), 150)
                self.assertTrue(self.block("THUNDER_WAVE", "LIGHTNING_ROD", turn, special_attack_stage=13))
                self.assertEqual(self.game.peek(target_prefix + "MonAttackMod", 7)[MOD_SPECIAL_ATTACK], 13)

    def test_flash_fire(self):
        self.assertTrue(self.block("EMBER", "FLASH_FIRE", 0))
        self.assertEqual(self.game.peek("wAbilityFlags"), FLASH_FIRE_ENEMY)
        self.assertTrue(self.block("FLAMETHROWER", "FLASH_FIRE", 1))
        self.assertEqual(self.game.peek("wAbilityFlags"), FLASH_FIRE_PLAYER)

    def test_soundproof(self):
        for move in ("GROWL", "ROAR", "SING", "SUPERSONIC", "SCREECH"):
            for turn in (0, 1):
                with self.subTest(move=move, turn=turn):
                    self.assertTrue(self.block(move, "SOUNDPROOF", turn))
        self.assertFalse(self.block("TACKLE", "SOUNDPROOF"))
        self.assertFalse(self.block("HYPNOSIS", "SOUNDPROOF"))

    def test_what_gets_through(self):
        self.assertFalse(self.block("EARTHQUAKE", "LEVITATE", invulnerable=True))  # misses instead
        self.assertFalse(self.block("EARTHQUAKE", "LEVITATE", user_ability="MOLD_BREAKER"))
        self.assertFalse(self.block("THUNDERBOLT", "VOLT_ABSORB", user_ability="NEUTRALIZING_GAS"))
        self.assertFalse(self.block("THUNDERBOLT", "LEVITATE"))
        self.assertFalse(self.block("EARTHQUAKE", "NO_ABILITY"))


class TurnTest(unittest.TestCase):
    """Whole moves: a stopped move does nothing else."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_levitate_takes_no_damage(self):
        g = self.game
        for seed in range(6):
            with self.subTest(seed=seed):
                g.reset()
                mx.setup(g, random.Random(seed))
                for i in (1, 2, 3):
                    g.poke(f"wPlayerBattleStatus{i}", 0)
                    g.poke(f"wEnemyBattleStatus{i}", 0)
                g.poke("wBattleMonStatus", 0)
                g.poke("wEnemyAbility", ABILITIES["LEVITATE"])
                g.poke("wBattleMonMoves", MOVES["EARTHQUAKE"], 0, 0, 0)
                g.poke("wBattleMonPP", 10, 0, 0, 0)
                g.poke("wPlayerSelectedMove", MOVES["EARTHQUAKE"])
                g.poke("wPlayerMoveListIndex", 0)
                g.poke(H_WHOSETURN, 0)
                g.call("GetCurrentMove")
                before = g.peek16("wEnemyMonHP")
                out = mx.run(g, "player")
                self.assertNotIn("error", out)
                self.assertEqual(g.peek16("wEnemyMonHP"), before)
                self.assertEqual(g.peek("wBattleMonPP"), 9)  # the move was still used


class ScrappyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def effectiveness(self, ability, move_type, types):
        g = self.game
        g.reset()
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerAbility", ABILITIES[ability], 0)
        g.poke("wBattleMonType1", WATER, WATER)  # no same-type bonus
        g.poke("wEnemyMonType1", *types)
        g.poke("wPlayerMoveType", move_type)
        g.poke16("wDamage", 100)
        g.poke("wUnusedC000", 0)
        g.poke("wMoveMissed", 0)
        g.call("AdjustDamageForMoveType")
        return g.peek16("wDamage")

    def test_scrappy_hits_ghosts(self):
        self.assertEqual(self.effectiveness("NO_ABILITY", NORMAL, (GHOST, GHOST)), 0)
        self.assertEqual(self.effectiveness("SCRAPPY", NORMAL, (GHOST, GHOST)), 100)
        self.assertEqual(self.effectiveness("SCRAPPY", FIGHTING, (GHOST, GHOST)), 100)
        self.assertEqual(self.effectiveness("SCRAPPY", FIGHTING, (GHOST, POISON)), 50)
        self.assertEqual(self.effectiveness("SCRAPPY", NORMAL, (POISON, GHOST)), 100)
        self.assertEqual(self.effectiveness("SCRAPPY", GROUND, (GHOST, POISON)), 200)  # other types as usual
        self.assertEqual(self.effectiveness("SCRAPPY", FIGHTING, (NORMAL, NORMAL)), 200)


if __name__ == "__main__":
    unittest.main()
