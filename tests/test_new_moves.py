"""Spec tests for the learnset audit's 49 new moves (design brief, Gen 9 rules
pass, part 8): their names and priorities, and the ones with rules of their
own (Ancient Power, Close Combat, Poison Fang, Flare Blitz, Brine, Flame
Wheel thawing, Aerial Ace never missing, Hyper Voice through a substitute).
"""

import os
import random
import re
import unittest

from harness import REPO_ROOT, shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN, _constants
from test_types import TYPES

MOVES = _constants("move_constants.asm", [
    "ANCIENTPOWER", "CLOSE_COMBAT", "POISON_FANG", "FLARE_BLITZ", "BRINE", "FLAME_WHEEL",
    "AERIAL_ACE", "HYPER_VOICE", "EXTREMESPEED", "QUICK_ATTACK", "AQUA_JET", "MACH_PUNCH",
    "TACKLE", "SUBSTITUTE", "STRUGGLE", "X_SCISSOR"])
EFFECTS = {"ALL_STATS_UP_SIDE_EFFECT": 0x4B, "CLOSE_COMBAT_EFFECT": 0x57, "POISON_SIDE_EFFECT2": 0x21}
HAS_SUBSTITUTE_UP = 1 << 4
PSN, FRZ, TOX = 1 << 3, 1 << 5, 1 << 7
BADLY_POISONED = 1 << 0


class NamesTest(unittest.TestCase):
    def test_49_new_moves_before_struggle(self):
        self.assertEqual(MOVES["STRUGGLE"], 0xA5 + 49)
        with open(os.path.join(REPO_ROOT, "text", "move_names.asm")) as f:
            names = re.findall(r'db "([^"@]*)@"', f.read())
        self.assertEqual(len(names), MOVES["STRUGGLE"])
        self.assertEqual(names[MOVES["X_SCISSOR"] - 1], "X-SCISSOR")
        self.assertTrue(all(len(n) <= 12 for n in names))


class NewMovesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        mx.setup(g, random.Random(41))
        g.clear_random()
        g.poke(H_WHOSETURN, 0)
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        g.poke("wPlayerAbility", 0, 0)
        g.poke("wPlayerMonStatMods", *[7] * 8)
        g.poke("wEnemyMonStatMods", *[7] * 8)
        g.poke("wBattleMonType1", TYPES["NORMAL"], TYPES["NORMAL"])
        g.poke("wEnemyMonType1", TYPES["NORMAL"], TYPES["NORMAL"])
        g.poke("wBattleMonStatus", 0)
        g.poke("wEnemyMonStatus", 0)

    def use(self, move, effect=None):
        g = self.game
        g.poke("wPlayerSelectedMove", MOVES[move])
        g.call("GetCurrentMove")
        if effect is not None:
            g.poke("wPlayerMoveEffect", EFFECTS[effect])

    def test_ancient_power_raises_all_five(self):
        g = self.game
        for roll, raised in ((0, True), (255, False)):
            with self.subTest(roll=roll):
                self.setUp()
                self.use("ANCIENTPOWER")
                g.queue_random(roll)
                g.call("AllStatsUpSideEffect", max_frames=6000)
                expected = [8, 8, 8, 8, 7, 7, 8] if raised else [7] * 7
                self.assertEqual(g.peek("wPlayerMonStatMods", 7), expected)

    def test_close_combat_lowers_the_users_defenses(self):
        g = self.game
        self.use("CLOSE_COMBAT")
        g.call("CloseCombatEffect", max_frames=6000)
        self.assertEqual(g.peek("wPlayerMonStatMods", 7), [7, 6, 7, 7, 7, 7, 6])
        g.poke("wPlayerMonStatMods", 7, 1, 7, 7, 7, 7, 1)  # already -6
        g.call("CloseCombatEffect", max_frames=6000)
        self.assertEqual(g.peek("wPlayerMonStatMods", 7), [7, 1, 7, 7, 7, 7, 1])

    def test_poison_fang_badly_poisons(self):
        g = self.game
        self.use("POISON_FANG")
        g.queue_random(0, 0)
        g.call("PoisonEffect", max_frames=6000)
        self.assertEqual(g.peek("wEnemyMonStatus"), PSN | TOX)
        self.assertTrue(g.peek("wEnemyBattleStatus3") & BADLY_POISONED)

    def test_flare_blitz_recoil_a_third(self):
        g = self.game
        self.use("FLARE_BLITZ")
        g.poke16("wDamage", 90)
        g.poke16("wBattleMonMaxHP", 200)
        g.poke16("wBattleMonHP", 200)
        g.call("RecoilEffect_", max_frames=6000)
        self.assertEqual(g.peek16("wBattleMonHP"), 170)

    def test_brine_doubles_at_half_hp(self):
        g = self.game
        for hp, power in ((100, 130), (101, 65)):
            with self.subTest(hp=hp):
                g.poke(0xFFE2, 0)  # hBattleSide: the player attacks
                g.poke16("wEnemyMonMaxHP", 200)
                g.poke16("wEnemyMonHP", hp)
                g.poke("wDamageScratch", 65)
                g.call("BrinePower")
                self.assertEqual(g.peek("wDamageScratch"), power)

    def test_flame_wheel_thaws_its_user(self):
        g = self.game
        g.poke("wBattleMonStatus", FRZ)
        g.poke("wPlayerSelectedMove", MOVES["FLAME_WHEEL"])
        g.poke("wPlayerDisabledMove", 0)
        g.call("CheckPlayerStatusConditions", max_frames=5000)
        self.assertEqual((g.peek("wBattleMonStatus"), g.random_used()), (0, 0))

    def test_aerial_ace_never_misses(self):
        g = self.game
        self.use("AERIAL_ACE")
        g.poke("wPlayerMoveAccuracy", 0)
        g.poke("wMoveMissed", 0)
        g.call("MoveHitTest", max_frames=5000)
        self.assertEqual((g.peek("wMoveMissed"), g.random_used()), (0, 0))

    def test_hyper_voice_hits_through_a_substitute(self):
        g = self.game
        for move, through in (("HYPER_VOICE", True), ("TACKLE", False)):
            with self.subTest(move=move):
                self.setUp()
                self.use(move)
                g.poke("wEnemyBattleStatus2", HAS_SUBSTITUTE_UP)
                g.poke("wEnemySubstituteHP", 50)
                g.poke16("wEnemyMonHP", 100)
                g.poke16("wDamage", 30)
                g.poke("wUnusedD119", 0)
                g.call("ApplyDamageToEnemyPokemon", max_frames=6000)
                self.assertEqual(g.peek16("wEnemyMonHP"), 70 if through else 100)
                self.assertEqual(g.peek("wEnemySubstituteHP"), 50 if through else 20)

    def order(self, player, enemy):
        g = self.game
        g.poke("wPlayerSelectedMove", MOVES[player])
        g.poke("wEnemySelectedMove", MOVES[enemy])
        out = g.call("ComparePriority")
        return "speed" if not out["carry"] else ("enemy" if out["z"] else "player")

    def test_priorities(self):
        self.assertEqual(self.order("EXTREMESPEED", "QUICK_ATTACK"), "player")
        self.assertEqual(self.order("AQUA_JET", "MACH_PUNCH"), "speed")
        self.assertEqual(self.order("TACKLE", "MACH_PUNCH"), "enemy")

    def test_close_combat_once_per_use(self):
        """Through the whole move: the effect runs once (a bug the emulator showed)."""
        g = self.game
        g.poke("wBattleMonMoves", MOVES["CLOSE_COMBAT"], 0, 0, 0)
        g.poke("wBattleMonPP", 5, 0, 0, 0)
        g.poke("wPlayerMoveListIndex", 0)
        g.poke("wPlayerSelectedMove", MOVES["CLOSE_COMBAT"])
        g.poke16("wEnemyMonHP", 999)
        g.poke16("wEnemyMonMaxHP", 999)
        g.poke("wObtainedBadges", 0xFF)
        g.call("GetCurrentMove")
        g.queue_random(*[100] * 64)
        g.call("ExecutePlayerMove", max_frames=20000)
        mods = g.peek("wPlayerMonStatMods", 7)
        self.assertEqual((mods[1], mods[6]), (6, 6))
