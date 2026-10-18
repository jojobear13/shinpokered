"""Spec tests for GetDamageVarsForPlayerAttack/EnemyAttack.

These pin down the current rules for picking the attack and defense values fed
into CalculateDamage, using a small Python model of the non-critical-hit path.
The critical-hit path is covered by compare_builds.py instead, which checks a
refactor against the previous build bit for bit.
"""

import random
import unittest

from harness import shared_game
from suites import damage_vars

SEEDS = range(300)

SIDES = {
    # side: (attacker battle struct, defender battle struct, defender status 3,
    #        move prefix)
    "player": ("wBattleMon", "wEnemyMon", "wEnemyBattleStatus3", "wPlayerMove"),
    "enemy": ("wEnemyMon", "wBattleMon", "wPlayerBattleStatus3", "wEnemyMove"),
}


def model(game, side):
    """What the routine should produce for a non-critical hit."""
    attacker, defender, status3, move = SIDES[side]
    power = game.peek(move + "Power")
    if power == 0:
        return {"z": True, "d": 0, "wDamage": 0}

    special = game.peek(move + "Type") >= damage_vars.FIRE
    screen_bit = damage_vars.HAS_LIGHT_SCREEN_UP if special else damage_vars.HAS_REFLECT_UP
    stat = "Special" if special else "Defense"
    defense = game.peek16(defender + stat)
    if game.peek(status3) & (1 << screen_bit):
        defense = min((defense << 1) & 0xFFFF, 999)
    attack = game.peek16(attacker + ("Special" if special else "Attack"))

    # stats over 255 can't fit in a byte, so both are divided by 4
    if attack >> 8 or defense >> 8:
        defense >>= 2
        attack >>= 2
        if attack == 0:
            attack = 1
        if defense == 0:
            defense = 1

    return {
        "z": False,
        "a": 1,
        "b": attack & 0xFF,
        "c": defense & 0xFF,
        "d": power,
        "e": game.peek(attacker + "Level"),
        "wDamage": 0,
    }


class DamageVarsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def check_against_model(self, side, crit):
        for seed in SEEDS:
            with self.subTest(side=side, seed=seed):
                self.game.reset()
                damage_vars.setup(self.game, random.Random(seed))
                self.game.poke("wCriticalHitOrOHKO", crit)
                expected = model(self.game, side)
                actual = damage_vars.run(self.game, side)
                self.assertEqual({k: actual[k] for k in expected}, expected)

    def test_player_attack_matches_model(self):
        self.check_against_model("player", crit=0)

    def test_enemy_attack_matches_model(self):
        self.check_against_model("enemy", crit=0)

    def test_reflect_doubles_physical_defense(self):
        for side in SIDES:
            attacker, defender, status3, move = SIDES[side]
            self.game.reset()
            damage_vars.setup(self.game, random.Random(1))
            self.game.poke("wCriticalHitOrOHKO", 0)
            self.game.poke(move + "Power", 50)
            self.game.poke(move + "Type", 0)  # normal: physical
            self.game.poke16(attacker + "Attack", 100)
            self.game.poke16(defender + "Defense", 60)
            self.game.poke(status3, 1 << damage_vars.HAS_REFLECT_UP)
            out = damage_vars.run(self.game, side)
            self.assertEqual((out["b"], out["c"]), (100, 120), side)

    def test_light_screen_doubles_special_and_caps_at_999(self):
        for side in SIDES:
            attacker, defender, status3, move = SIDES[side]
            self.game.reset()
            damage_vars.setup(self.game, random.Random(2))
            self.game.poke("wCriticalHitOrOHKO", 0)
            self.game.poke(move + "Power", 90)
            self.game.poke(move + "Type", damage_vars.FIRE)
            self.game.poke16(attacker + "Special", 400)
            self.game.poke16(defender + "Special", 600)
            self.game.poke(status3, 1 << damage_vars.HAS_LIGHT_SCREEN_UP)
            out = damage_vars.run(self.game, side)
            # 600 doubled is capped at 999, then both stats are divided by 4
            self.assertEqual((out["b"], out["c"]), (100, 999 >> 2), side)

    def test_zero_power_move_returns_early(self):
        for side in SIDES:
            move = SIDES[side][3]
            self.game.reset()
            damage_vars.setup(self.game, random.Random(3))
            self.game.poke(move + "Power", 0)
            out = damage_vars.run(self.game, side)
            self.assertTrue(out["z"], side)
            self.assertEqual(out["wDamage"], 0, side)

    def test_critical_hit_keeps_power_and_level(self):
        """The crit path swaps in different attack/defense values, but power,
        level and the crit flag come out the same as for a normal hit."""
        for side in SIDES:
            for seed in range(60):
                with self.subTest(side=side, seed=seed):
                    self.game.reset()
                    damage_vars.setup(self.game, random.Random(seed))
                    self.game.poke("wCriticalHitOrOHKO", 0)
                    normal = damage_vars.run(self.game, side)

                    self.game.reset()
                    damage_vars.setup(self.game, random.Random(seed))
                    self.game.poke("wCriticalHitOrOHKO", 1)
                    crit = damage_vars.run(self.game, side)

                    self.assertEqual(crit["z"], normal["z"])
                    self.assertEqual((crit["d"], crit["e"]), (normal["d"], normal["e"]))
                    self.assertEqual(crit["wCriticalHitOrOHKO"], 1)


if __name__ == "__main__":
    unittest.main()
