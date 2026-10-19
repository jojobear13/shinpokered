"""Spec tests for the special split (design brief, plan step E, part 1).

Special is now two stats, special attack and special defense, with Gen 2's
base stats and a DV each (the third DV byte's high nybble is the special
defense DV). Special stat experience stays shared, as in Gen 2. Amnesia and
Psychic's side effect work on special defense; Growth and X Special on special
attack. The Volcano Badge boosts both.
"""

import math
import os
import random
import re
import unittest

from harness import REPO_ROOT, shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN

STATS = ("MaxHP", "Attack", "Defense", "Speed", "SpecialAttack", "SpecialDefense")
STAT_EXPS = ("HPExp", "AttackExp", "DefenseExp", "SpeedExp", "SpecialExp")
BASE_NAMES = ("hp", "attack", "defense", "speed", "special attack", "special defense")

VOLCANOBADGE = 1 << 6
MOD_SPECIAL_DEFENSE = 6


def _constants(path, prefix=""):
    values = {}
    with open(os.path.join(REPO_ROOT, path)) as f:
        for line in f:
            m = re.match(r"\s*const (\w+)\s*; \$?([0-9A-Fa-f]+)", line)
            if m:
                values[m.group(1)] = int(m.group(2), 16)
    return values


MOVES = _constants("constants/move_constants.asm")
SPECIES = _constants("constants/pokemon_constants.asm")


def base_stats(species_name):
    """The six base stats from the species' data file."""
    name = species_name.lower().replace("_", "")
    path = os.path.join(REPO_ROOT, "data", "baseStats", name + ".asm")
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        text = f.read()
    return [int(re.search(rf"^db (\d+) ; base {stat}$", text, re.M).group(1)) for stat in BASE_NAMES]


def model_stats(base, level, dvs, exps):
    """Gen 1's stat formula, with special defense using its own base stat and
    DV and the shared special stat exp."""
    attack, defense = dvs[0] >> 4, dvs[0] & 0xF
    speed, special_attack = dvs[1] >> 4, dvs[1] & 0xF
    special_defense = dvs[2] >> 4
    hp = (attack & 1) << 3 | (defense & 1) << 2 | (speed & 1) << 1 | (special_attack & 1)
    stat_dvs = (hp, attack, defense, speed, special_attack, special_defense)
    stat_exps = list(exps) + [exps[4]]
    raised, lowered = divmod(nature(dvs), 5)
    out = []
    for i in range(6):
        exp = stat_exps[i]
        root = min(max(math.isqrt(exp - 1) + 1, 1) if exp else 1, 255)
        value = ((base[i] + stat_dvs[i]) * 2 + root // 4) * level // 100
        value += level + 10 if i == 0 else 5
        if i and raised != lowered:
            if i - 1 == raised:
                value = value * 110 // 100
            elif i - 1 == lowered:
                value = value * 90 // 100
        out.append(min(value, 999))
    return out


TRAINER_DVS = (0x98, 0x88, 0x80)


def nature(dvs):
    """0-24 in Gen 3's order (5 * raised + lowered, from attack): the DVs as one
    number without the spare low nybble, offset so the trainer DVs are HARDY."""
    def value(d):
        return d[0] << 16 | d[1] << 8 | (d[2] & 0xF0)
    return (value(dvs) - value(TRAINER_DVS)) % 25


def badge_boost(value):
    return min(value + (value >> 3), 999)


class CalcStatsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def calc(self, species, level, dvs, exps):
        g = self.game
        g.reset()
        g.poke("wd0b5", species)
        g.call("GetMonHeader")
        g.poke("wCurEnemyLVL", level)
        for name, exp in zip(STAT_EXPS, exps):
            g.poke16("wPartyMon1" + name, exp)
        g.poke("wPartyMon1DVs", *dvs)
        g.call("CalcStats", hl=g.addr("wPartyMon1HPExp") - 1, de=g.addr("wPartyMon1MaxHP"), bc=0x0100)
        return [g.peek16("wPartyMon1" + name) for name in STATS]

    def test_every_species_matches_the_model(self):
        rng = random.Random(0)
        checked = 0
        for name, species in sorted(SPECIES.items()):
            base = base_stats(name)
            if base is None:
                continue  # not a real Pokemon (ghost, fossils, missingno slots)
            with self.subTest(species=name):
                level = rng.randint(1, 100)
                dvs = [rng.randint(0, 255), rng.randint(0, 255), rng.randint(0, 15) << 4]
                exps = [rng.choice([0, 1, rng.randint(0, 0xFFFF), 0xFFFF]) for _ in STAT_EXPS]
                self.assertEqual(self.calc(species, level, dvs, exps), model_stats(base, level, dvs, exps))
                header = [self.game.peek("wMonHBase" + s) for s in
                          ("HP", "Attack", "Defense", "Speed", "SpecialAttack", "SpecialDefense")]
                self.assertEqual(header, base, "GetMonHeader should load the six base stats")
                checked += 1
        self.assertEqual(checked, 151)

    def test_gen2_split_values(self):
        # Chansey's Gen 1 special of 105 became 35 special attack and 105
        # special defense; Charizard's 85 became 109 and 85
        self.assertEqual(base_stats("CHANSEY")[4:], [35, 105])
        self.assertEqual(base_stats("CHARIZARD")[4:], [109, 85])

    def test_special_defense_dv_is_the_high_nybble_of_the_third_byte(self):
        species = SPECIES["MEWTWO"]
        low = self.calc(species, 100, [0, 0, 0x00], [0] * 5)
        high = self.calc(species, 100, [0, 0, 0xF0], [0] * 5)
        spare = self.calc(species, 100, [0, 0, 0x0F], [0] * 5)
        base = base_stats("MEWTWO")
        self.assertEqual(low, model_stats(base, 100, [0, 0, 0x00], [0] * 5))
        self.assertEqual(high, model_stats(base, 100, [0, 0, 0xF0], [0] * 5))
        self.assertNotEqual(high[5], low[5])
        self.assertEqual(spare, low, "the low nybble is spare and doesn't change the nature")


class StatStageMoveTest(unittest.TestCase):
    """Whole turns through ExecutePlayerMove."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def player_uses(self, seed, move):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(seed))
        for side in ("wPlayerBattleStatus", "wEnemyBattleStatus"):
            for i in (1, 2, 3):
                g.poke(f"{side}{i}", 0)
        g.poke("wBattleMonStatus", 0)
        g.poke("wEnemyMonStatus", 0)
        g.poke("wPlayerDisabledMove", 0)
        g.poke16("wEnemyMonMaxHP", 999)
        g.poke16("wEnemyMonHP", 999)
        g.poke("wBattleMonMoves", move, 0, 0, 0)
        g.poke("wBattleMonPP", 10, 0, 0, 0)
        g.poke("wPlayerSelectedMove", move)
        g.poke("wPlayerMoveListIndex", 0)
        for side in ("wPlayerMon", "wEnemyMon"):
            g.poke(side + "StatMods", *[7] * 8)
        for prefix, unmodified in (("wBattleMon", "wPlayerMonUnmodified"), ("wEnemyMon", "wEnemyMonUnmodified")):
            for name, value in (("SpecialAttack", 200), ("SpecialDefense", 300)):
                g.poke16(unmodified + name, value)
                g.poke16(prefix + name, value)
        g.poke(H_WHOSETURN, 0)
        g.call("GetCurrentMove")
        return mx.run(g, "player")

    def test_amnesia_raises_special_defense_by_two(self):
        g = self.game
        for seed in range(5):
            with self.subTest(seed=seed):
                out = self.player_uses(seed, MOVES["AMNESIA"])
                self.assertNotIn("error", out)
                self.assertEqual(g.peek("wPlayerMonSpecialDefenseMod"), 9)
                self.assertEqual(g.peek("wPlayerMonSpecialAttackMod"), 7)
                # 300 doubled, then the Volcano Badge's boost reapplied to it alone
                self.assertEqual(g.peek16("wBattleMonSpecialDefense"), badge_boost(600))
                self.assertEqual(g.peek16("wBattleMonSpecialAttack"), 200)

    def test_growth_raises_special_attack_by_one(self):
        g = self.game
        for seed in range(5):
            with self.subTest(seed=seed):
                out = self.player_uses(seed, MOVES["GROWTH"])
                self.assertNotIn("error", out)
                self.assertEqual(g.peek("wPlayerMonSpecialAttackMod"), 8)
                self.assertEqual(g.peek("wPlayerMonSpecialDefenseMod"), 7)
                self.assertEqual(g.peek16("wBattleMonSpecialAttack"), badge_boost(300))
                self.assertEqual(g.peek16("wBattleMonSpecialDefense"), 300)

    def test_psychic_side_effect_lowers_special_defense(self):
        g = self.game
        lowered = 0
        for seed in range(60):
            with self.subTest(seed=seed):
                out = self.player_uses(seed, MOVES["PSYCHIC_M"])
                if "error" in out:
                    continue
                self.assertEqual(g.peek("wEnemyMonSpecialAttackMod"), 7)
                self.assertEqual(g.peek16("wEnemyMonSpecialAttack"), 200)
                mod = g.peek("wEnemyMonSpecialDefenseMod")
                self.assertIn(mod, (6, 7))
                if mod == 6:
                    lowered += 1
                    self.assertEqual(g.peek16("wEnemyMonSpecialDefense"), 300 * 66 // 100)
        self.assertGreater(lowered, 0, "the side effect should have triggered in some turns")


class BadgeBoostTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def boost(self, badges, changed_stage):
        g = self.game
        g.reset()
        g.poke("wLinkState", 0)
        g.poke("wOptions", 0)
        g.poke("wObtainedBadges", badges)
        g.poke("wUnusedD71B", changed_stage)
        values = {"Attack": 100, "Defense": 120, "Speed": 140, "SpecialAttack": 160, "SpecialDefense": 180}
        for name, value in values.items():
            g.poke16("wBattleMon" + name, value)
        g.call("ApplyBadgeStatBoosts")
        return {name: g.peek16("wBattleMon" + name) for name in values}

    def test_volcano_badge_boosts_both_specials(self):
        out = self.boost(VOLCANOBADGE, 0)
        self.assertEqual(out, {"Attack": 100, "Defense": 120, "Speed": 140,
                               "SpecialAttack": badge_boost(160), "SpecialDefense": badge_boost(180)})

    def test_after_a_special_defense_change_only_it_is_boosted(self):
        out = self.boost(0xFF, MOD_SPECIAL_DEFENSE + 1)
        self.assertEqual(out, {"Attack": 100, "Defense": 120, "Speed": 140,
                               "SpecialAttack": 160, "SpecialDefense": badge_boost(180)})


class StatExpTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_gain_adds_base_stats_to_the_five_fields_and_leaves_dvs(self):
        g = self.game
        g.reset()
        base = [45, 49, 49, 45, 65, 65]  # Bulbasaur: special exp gains special attack
        g.poke("wBuffer", *base, 64)
        g.poke("wPartyGainExpFlags", 1)
        for name in STAT_EXPS:
            g.poke16("wPartyMon1" + name, 1000)
        g.poke("wPartyMon1DVs", 0x12, 0x34, 0x50)
        g.call("GiveStatExp")
        self.assertEqual([g.peek16("wPartyMon1" + name) for name in STAT_EXPS], [1000 + b for b in base[:5]])
        self.assertEqual(g.peek("wPartyMon1DVs", 3), [0x12, 0x34, 0x50])


class WildDVsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_third_random_number_gives_the_special_defense_dv(self):
        g = self.game
        for third in (0x00, 0x7F, 0xA5, 0xFF):
            with self.subTest(third=third):
                g.reset()
                g.poke("wOptions", 0)  # normal mode: no rerolls
                g.poke("wFontLoaded", 0)  # no forced shiny
                g.poke("wCurMap", 0)  # not the Safari Zone
                g.queue_random(0x12, 0x34, third)
                g.call("DetermineWildMonDVs")
                self.assertEqual(g.peek("wEnemyMonDVs", 3), [0x12, 0x34, third & 0xF0])


if __name__ == "__main__":
    unittest.main()
