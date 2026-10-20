"""Spec tests for Gen 9's damage (design brief, Gen 9 rules pass, part 4).

BaseDamage: (2 x level / 5 + 2) x power x A / D / 50 + 2, with A and D the
unmodified stats times Gen 9's stage ratios (2/8 ... 8/2), each 1-999; a
critical hit leaves out the attacker's drops and the defender's raises.
DamageModifiers, in Gen 9's order: x1.5 for a critical hit, x85-100% at
random, STAB, type, x1/2 for a burned attacker's physical move, x1/2 behind
Reflect or Light Screen (not on a critical hit), then abilities and items
(left out here); at least 1 unless the target is immune. CriticalHitTest:
Gen 9's stages.
"""

import random
import unittest

from harness import shared_game
from suites import damage as dmg
from test_types import TYPES, expected as type_factor

SEEDS = range(300)
BRN = 1 << 4
GETTING_PUMPED = 1 << 2
NAMES = {v: k for k, v in TYPES.items()}

SIDES = {
    # side: (attacker, defender, attacker unmodified, defender unmodified,
    #        attacker stages, defender stages, defender status 3, move)
    "player": ("wBattleMon", "wEnemyMon", "wPlayerMonUnmodified", "wEnemyMonUnmodified",
               "wPlayerMon", "wEnemyMon", "wEnemyBattleStatus3", "wPlayerMove"),
    "enemy": ("wEnemyMon", "wBattleMon", "wEnemyMonUnmodified", "wPlayerMonUnmodified",
              "wEnemyMon", "wPlayerMon", "wPlayerBattleStatus3", "wEnemyMove"),
}
RATIOS = [(2, 8), (2, 7), (2, 6), (2, 5), (2, 4), (2, 3), (2, 2),
          (3, 2), (4, 2), (5, 2), (6, 2), (7, 2), (8, 2)]


def scaled(stat, stage):
    n, d = RATIOS[stage - 1]
    return max(1, min(999, stat * n // d))


def model(game, side, roll):
    attacker, defender, a_unmod, d_unmod, a_mods, d_mods, status3, move = SIDES[side]
    power = game.peek(move + "Power")
    if power == 0:
        return None
    special = dmg.category(game.peek(move + "Num")) == "SPECIAL"
    crit = game.peek("wCriticalHitOrOHKO") == 1
    a_stage = game.peek(a_mods + ("SpecialAttackMod" if special else "AttackMod"))
    d_stage = game.peek(d_mods + ("SpecialDefenseMod" if special else "DefenseMod"))
    if crit:
        a_stage, d_stage = max(a_stage, 7), min(d_stage, 7)
    attack = scaled(game.peek16(a_unmod + ("SpecialAttack" if special else "Attack")), a_stage)
    defense = scaled(game.peek16(d_unmod + ("SpecialDefense" if special else "Defense")), d_stage)
    level = game.peek(attacker + "Level")
    base = min((2 * level // 5 + 2) * power * attack // defense // 50 + 2, 0xFFFF)
    damage = base
    if crit:
        damage = min(damage * 3 // 2, 0xFFFF)
    damage = damage * (85 + (roll & 15)) // 100
    move_type = game.peek(move + "Type")
    if move_type in game.peek(attacker + "Type", 2):
        damage = min(damage + damage // 2, 0xFFFF)
    types = game.peek(defender + "Type", 2)
    factor = 10
    for t in (types if types[0] != types[1] else types[:1]):
        if move_type in NAMES and t in NAMES and NAMES[move_type] != "TYPELESS" and NAMES[t] != "TYPELESS":
            f = type_factor(NAMES[move_type], NAMES[t])
            factor = 0 if f == 0 else factor * 2 if f == 20 else factor // 2 if f == 5 else factor
    if factor == 0:
        return {"base": base, "wDamage": 0}
    for limit, op in ((3, "halve"), (10, "halve"), (11, "double"), (21, "double")):
        if op == "halve" and factor < limit:
            damage //= 2
        elif op == "double" and factor >= limit:
            damage = min(damage * 2, 0xFFFF)
    if not special and game.peek(attacker + "Status") & BRN:
        damage //= 2
    screen = 1 << (1 if special else 2)
    if not crit and game.peek(status3) & screen:
        damage //= 2
    return {"base": base, "wDamage": max(damage, 1)}


class DamageTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def check(self, side, seed):
        g = self.game
        g.reset()
        g.clear_random()
        rng = random.Random(seed)
        dmg.setup(g, rng)
        g.poke("wLinkState", 0)
        roll = rng.randint(0, 255)
        g.queue_random(roll)
        expected = model(g, side, roll)
        out = dmg.run(g, side)
        if expected is None:
            self.assertTrue(out["z"])
            return
        self.assertFalse(out["z"])
        self.assertEqual(out["base"], expected["base"])
        self.assertEqual(out["wDamage"], expected["wDamage"])

    def test_player_matches_model(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                self.check("player", seed)

    def test_enemy_matches_model(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                self.check("enemy", 1000 + seed)

    def setup_simple(self, crit=0, status=0, screens=0, a_stage=7, d_stage=7, move_type=0x00):
        g = self.game
        g.reset()
        g.clear_random()
        dmg.setup(g, random.Random(5))
        g.poke("wLinkState", 0)
        g.poke("wCriticalHitOrOHKO", crit)
        g.poke("wPlayerMoveNum", 0x21)  # Tackle: physical
        g.poke("wPlayerMovePower", 80)
        g.poke("wPlayerMoveType", move_type)
        g.poke("wBattleMonType", 0x15, 0x15)  # Water: no STAB on Normal
        g.poke("wEnemyMonType", 0x15, 0x15)
        g.poke("wBattleMonLevel", 50)
        g.poke("wBattleMonStatus", status)
        g.poke("wEnemyBattleStatus3", screens)
        g.poke16("wPlayerMonUnmodifiedAttack", 100)
        g.poke16("wEnemyMonUnmodifiedDefense", 100)
        g.poke("wPlayerMonAttackMod", a_stage)
        g.poke("wEnemyMonDefenseMod", d_stage)
        g.queue_random(15)  # 100%
        return dmg.run(g, "player")

    def test_examples(self):
        # level 50, 80 power, 100 against 100: 22 x 80 x 100 / 100 / 50 + 2 = 37
        self.assertEqual(self.setup_simple()["wDamage"], 37)
        self.assertEqual(self.setup_simple(crit=1)["wDamage"], 55)
        self.assertEqual(self.setup_simple(status=BRN)["wDamage"], 18)
        self.assertEqual(self.setup_simple(screens=1 << 2)["wDamage"], 18)  # Reflect
        self.assertEqual(self.setup_simple(screens=1 << 2, crit=1)["wDamage"], 55)  # not on a crit
        self.assertEqual(self.setup_simple(screens=1 << 1)["wDamage"], 37)  # Light Screen: special only
        # crits leave out the attacker's drops and the defender's raises
        self.assertEqual(self.setup_simple(a_stage=5, crit=1)["wDamage"], 55)
        self.assertEqual(self.setup_simple(d_stage=9, crit=1)["wDamage"], 55)
        self.assertLess(self.setup_simple(a_stage=5)["wDamage"], 37)
        # but keep the attacker's raises: +2 is x2
        self.assertEqual(self.setup_simple(a_stage=9)["base"], 22 * 80 * 200 // 100 // 50 + 2)

    def test_at_least_one_unless_immune(self):
        g = self.game
        out = self.setup_simple(move_type=0x00)
        self.assertGreater(out["wDamage"], 0)
        g.reset()
        g.clear_random()
        dmg.setup(g, random.Random(6))
        g.poke("wLinkState", 0)
        g.poke("wCriticalHitOrOHKO", 0)
        g.poke("wPlayerMoveNum", 0x21)
        g.poke("wPlayerMovePower", 10)
        g.poke("wPlayerMoveType", TYPES["GRASS"])
        g.poke("wBattleMonType", 0x15, 0x15)
        g.poke("wEnemyMonType", TYPES["FIRE"], TYPES["DRAGON"])  # x1/4
        g.poke("wBattleMonLevel", 2)
        g.poke("wBattleMonStatus", 0)
        g.poke("wEnemyBattleStatus3", 0)
        g.poke16("wPlayerMonUnmodifiedAttack", 5)
        g.poke16("wEnemyMonUnmodifiedDefense", 999)
        g.poke("wPlayerMonAttackMod", 7)
        g.poke("wEnemyMonDefenseMod", 7)
        g.queue_random(0)
        out = dmg.run(g, "player")
        self.assertEqual((out["wDamage"], out["wMoveMissed"]), (1, 0))


class CriticalHitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def crit(self, roll, move=0x21, power=40, pumped=False, item=0, target_ability="NO_ABILITY"):
        from test_abilities import ABILITIES
        g = self.game
        g.reset()
        g.clear_random()
        g.poke("wLinkState", 0)
        g.poke(0xFFF3, 0)
        g.poke("wPlayerMoveNum", move)
        g.poke("wPlayerMovePower", power)
        g.poke("wPlayerBattleStatus2", GETTING_PUMPED if pumped else 0)
        g.poke("wBattleMonCatchRate", item)
        g.poke("wBattleMonSpecies", 0x01)
        g.poke("wPlayerAbility", 0, ABILITIES[target_ability])
        g.queue_random(roll)
        g.call("CriticalHitTest")
        return g.peek("wCriticalHitOrOHKO") == 1, g.random_used()

    def test_stages(self):
        from test_held_items import ITEMS
        slash = 0xA3
        self.assertEqual(self.crit(10), (True, 1))  # 1/24: under 11
        self.assertEqual(self.crit(11), (False, 1))
        self.assertEqual(self.crit(31, move=slash), (True, 1))  # +1: 1/8
        self.assertEqual(self.crit(32, move=slash), (False, 1))
        self.assertEqual(self.crit(127, pumped=True), (True, 1))  # Focus Energy +2: 1/2
        self.assertEqual(self.crit(128, pumped=True), (False, 1))
        self.assertEqual(self.crit(255, move=slash, pumped=True), (True, 0))  # +3: always, no roll
        self.assertEqual(self.crit(0, item=ITEMS["SCOPE_LENS"], pumped=True), (True, 0))
        self.assertEqual(self.crit(0, target_ability="BATTLE_ARMOR"), (False, 0))
        self.assertEqual(self.crit(0, power=1), (False, 0))  # fixed damage


if __name__ == "__main__":
    unittest.main()
