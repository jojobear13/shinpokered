"""Spec tests for the special split (design brief, plan step E, part 1).

Special is now two stats, special attack and special defense, with Gen 2's
base stats (Gen 9's since the Gen 9 pass), each with its own IV and EV (Gen
9's growth, tests/ivs.py). Amnesia and Psychic's side effect work on special
defense; Growth and X Special on special attack. The Volcano Badge boosts
both.
"""

import os
import random
import re
import unittest

from harness import REPO_ROOT, shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from ivs import STAT_EVS, TRAINER_IVS, model_stats, nature, pack, unpack  # noqa: F401 (re-exported)

STATS = ("MaxHP", "Attack", "Defense", "Speed", "SpecialAttack", "SpecialDefense")
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


def badge_boost(value):
    return min(value + (value >> 3), 999)


class CalcStatsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def calc(self, species, level, iv_bytes, evs):
        g = self.game
        g.reset()
        g.poke("wd0b5", species)
        g.call("GetMonHeader")
        g.poke("wCurEnemyLVL", level)
        g.poke("wPartyMon1EVs", *evs)
        g.poke("wPartyMon1IVs", *iv_bytes)
        g.call("CalcStats", hl=g.addr("wPartyMon1EVs"), de=g.addr("wPartyMon1MaxHP"), bc=0x0100)
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
                iv_bytes = pack([rng.randint(0, 31) for _ in range(6)], rng.randint(0, 3))
                evs = [rng.choice([0, 3, 4, rng.randint(0, 252), 252]) for _ in range(6)]
                self.assertEqual(self.calc(species, level, iv_bytes, evs), model_stats(base, level, iv_bytes, evs))
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

    def test_each_iv_and_ev_reaches_its_own_stat(self):
        species, base = SPECIES["MEWTWO"], base_stats("MEWTWO")
        neutral = pack(TRAINER_IVS)  # a HARDY nature
        none = self.calc(species, 100, neutral, [0] * 6)
        self.assertEqual(none, model_stats(base, 100, neutral, [0] * 6))
        for stat in range(6):
            with self.subTest(stat=stat):
                ivs, _ = unpack(neutral)
                ivs[stat] += 4
                evs = [0] * 6
                evs[stat] = 252
                iv_bytes = pack(ivs)
                got = self.calc(species, 100, iv_bytes, evs)
                self.assertEqual(got, model_stats(base, 100, iv_bytes, evs))
                flags = self.calc(species, 100, pack(ivs, 3), evs)
                self.assertEqual(flags, got, "the flags don't change the stats or the nature")


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


class WildIVsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_six_rolls_then_the_ability_slot(self):
        g = self.game
        for rolls in ((0x00, 0x1F, 0x25, 0xFF, 0x40, 0x13), (0x31,) * 6):
            for slot in (0, 1):
                with self.subTest(rolls=rolls, slot=slot):
                    g.reset()
                    g.clear_random()
                    g.poke("wOptions", 0)  # normal mode: no rerolls
                    g.poke("wFontLoaded", 0)  # no forced shiny
                    g.poke("wCurMap", 0)  # not the Safari Zone
                    g.queue_random(*rolls, slot)
                    g.call("DetermineWildMonIVs")
                    self.assertEqual(g.random_used(), 7)
                    self.assertEqual(g.peek("wEnemyMonIVs", 4), pack([r & 31 for r in rolls], slot))


if __name__ == "__main__":
    unittest.main()
