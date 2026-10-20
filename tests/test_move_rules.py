"""Spec tests for Gen 9's move rules (design brief, Gen 9 rules pass, part 6):
Disable, Mimic, Mirror Move, Bide, Rage, Substitute, and the move flags that
make powders miss Grass types, let some moves never miss and let sound moves
through a substitute.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN, _constants
from test_types import TYPES

MOVES = _constants("move_constants.asm", [
    "TACKLE", "SWORDS_DANCE", "THUNDERBOLT", "SLEEP_POWDER", "ABSORB", "SWIFT", "GROWL",
    "MIMIC", "BIDE", "RAGE", "STRUGGLE", "TRANSFORM", "MIRROR_MOVE", "SUBSTITUTE"])
HAS_SUBSTITUTE_UP = 1 << 4
USING_RAGE = 1 << 6
STORING_ENERGY = 1 << 0


class MoveRulesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(11))
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
        g.poke("wPlayerMimicSlot", 0, 0)
        g.poke("wPlayerDisabledMove", 0)
        g.poke("wEnemyDisabledMove", 0)

    def use(self, routine, move, accuracy=255, *randoms):
        g = self.game
        g.poke("wPlayerMoveNum", MOVES[move])
        g.poke("wPlayerMoveAccuracy", accuracy)
        g.queue_random(*(randoms or (0,) * 8))
        return g.call(routine, max_frames=6000)

    # Disable: the target's last move, for 4 of its turns
    def test_disable_last_move(self):
        g = self.game
        g.poke("wEnemyMonMoves", MOVES["GROWL"], MOVES["TACKLE"], 0, 0)
        g.poke("wEnemyMonPP", 10, 10, 0, 0)
        g.poke("wEnemyUsedMove", MOVES["TACKLE"])
        self.use("DisableEffect", "TACKLE")
        self.assertEqual(g.peek("wEnemyDisabledMove"), 0x25)  # slot 2, 5 (freed as it reaches 0)
        self.assertEqual(g.peek("wEnemyDisabledMoveNumber"), MOVES["TACKLE"])

    def test_disable_fails(self):
        g = self.game
        for used, pp in ((0, 10), (MOVES["TACKLE"], 0), (MOVES["STRUGGLE"], 10), (MOVES["SWIFT"], 10)):
            with self.subTest(used=used, pp=pp):
                self.setUp()
                g.poke("wEnemyMonMoves", MOVES["GROWL"], MOVES["TACKLE"], 0, 0)
                g.poke("wEnemyMonPP", 10, pp, 0, 0)
                g.poke("wEnemyUsedMove", used)
                self.use("DisableEffect", "TACKLE")
                self.assertEqual(g.peek("wEnemyDisabledMove"), 0)

    # Mimic: the target's last move, with its full PP, in Mimic's slot
    def test_mimic(self):
        g = self.game
        g.poke("wBattleMonMoves", MOVES["TACKLE"], MOVES["MIMIC"], 0, 0)
        g.poke("wBattleMonPP", 30, 7, 0, 0)
        g.poke("wPlayerMoveListIndex", 1)
        g.poke("wEnemyUsedMove", MOVES["THUNDERBOLT"])
        self.use("MimicEffect", "MIMIC")
        self.assertEqual(g.peek("wBattleMonMoves", 2), [MOVES["TACKLE"], MOVES["THUNDERBOLT"]])
        self.assertEqual(g.peek("wBattleMonPP", 2), [30, 15])
        self.assertEqual((g.peek("wPlayerMimicSlot"), g.peek("wPlayerMimicPP")), (2, 7))

    def test_mimic_fails(self):
        g = self.game
        for used in (0, MOVES["TACKLE"], MOVES["TRANSFORM"], MOVES["STRUGGLE"]):
            with self.subTest(used=used):
                self.setUp()
                g.poke("wBattleMonMoves", MOVES["TACKLE"], MOVES["MIMIC"], 0, 0)
                g.poke("wPlayerMoveListIndex", 1)
                g.poke("wEnemyUsedMove", used)
                self.use("MimicEffect", "MIMIC")
                self.assertEqual(g.peek("wBattleMonMoves+1"), MOVES["MIMIC"])
                self.assertEqual(g.peek("wPlayerMimicSlot"), 0)

    def test_mimicked_pp_not_the_party_mons(self):
        g = self.game
        g.poke("wPlayerMimicSlot", 2)
        g.poke("wPlayerMoveListIndex", 1)
        g.poke("wPlayerMonNumber", 0)
        g.poke("wBattleMonPP", 30, 15, 0, 0)
        g.poke("wPartyMon1PP", 30, 7, 0, 0)
        g.poke("wPlayerSelectedMove", MOVES["THUNDERBOLT"])
        g.call("DecrementPP", de=g.addr("wPlayerSelectedMove"))
        self.assertEqual(g.peek("wBattleMonPP+1"), 14)
        self.assertEqual(g.peek("wPartyMon1PP+1"), 7)

    # Mirror Move: only moves that target another mon
    def test_mirror_move(self):
        g = self.game
        for used, copied in (("TACKLE", True), ("SWORDS_DANCE", False), ("MIRROR_MOVE", False)):
            with self.subTest(used=used):
                self.setUp()
                g.poke("wEnemyUsedMove", MOVES[used])
                out = self.use("MirrorMoveCopyMove", "MIRROR_MOVE")
                self.assertEqual(not out["z"], copied)
                if copied:
                    self.assertEqual(g.peek("wPlayerMoveNum"), MOVES[used])

    # move flags in the hit test
    def test_powder_misses_grass(self):
        g = self.game
        g.poke("wEnemyMonType1", TYPES["GRASS"], TYPES["POISON"])
        self.use("MoveHitTest", "SLEEP_POWDER")
        self.assertEqual(g.peek("wMoveMissed"), 2)  # "is unaffected"
        self.setUp()
        self.use("MoveHitTest", "SLEEP_POWDER")
        self.assertEqual(g.peek("wMoveMissed"), 0)

    def test_never_miss(self):
        g = self.game
        self.use("MoveHitTest", "SWIFT", 0)
        self.assertEqual((g.peek("wMoveMissed"), g.random_used()), (0, 0))
        self.setUp()
        self.use("MoveHitTest", "TACKLE", 0, 200)
        self.assertEqual((g.peek("wMoveMissed"), g.random_used()), (1, 1))

    def test_sound_goes_through_substitute(self):
        g = self.game
        g.poke("wEnemyBattleStatus2", HAS_SUBSTITUTE_UP)
        for move, blocked in (("GROWL", False), ("TACKLE", True)):
            with self.subTest(move=move):
                g.poke("wPlayerMoveNum", MOVES[move])
                self.assertEqual(not g.call("CheckTargetSubstitute")["z"], blocked)

    def test_drain_hits_substitute(self):
        g = self.game
        g.poke("wEnemyBattleStatus2", HAS_SUBSTITUTE_UP)
        self.use("MoveHitTest", "ABSORB", 255, 0)
        self.assertEqual(g.peek("wMoveMissed"), 0)

    # Substitute
    def substitute(self, hp, max_hp):
        g = self.game
        self.setUp()
        g.poke16("wBattleMonMaxHP", max_hp)
        g.poke16("wBattleMonHP", hp)
        self.use("SubstituteEffect_", "SUBSTITUTE")
        return bool(g.peek("wPlayerBattleStatus2") & HAS_SUBSTITUTE_UP), g.peek16("wBattleMonHP")

    def test_substitute_needs_more_than_a_quarter(self):
        self.assertEqual(self.substitute(50, 200), (False, 50))
        self.assertEqual(self.substitute(51, 200), (True, 1))
        self.assertEqual(self.substitute(356, 400), (True, 256))  # Gen 1 failed this one

    def test_broken_substitute_takes_its_hp(self):
        g = self.game
        g.poke("wEnemyBattleStatus2", HAS_SUBSTITUTE_UP)
        g.poke("wEnemySubstituteHP", 30)
        g.poke16("wDamage", 100)
        g.poke("wUnusedD119", 0)
        g.call("_AttackSubstitute", max_frames=6000)
        self.assertEqual(g.peek16("wDamage"), 30)
        self.assertEqual(g.peek("wEnemyBattleStatus2") & HAS_SUBSTITUTE_UP, 0)

    def test_substitute_breaks_at_zero(self):
        g = self.game
        g.poke("wEnemyBattleStatus2", HAS_SUBSTITUTE_UP)
        g.poke("wEnemySubstituteHP", 30)
        g.poke16("wDamage", 30)
        g.poke("wUnusedD119", 0)
        g.call("_AttackSubstitute", max_frames=6000)
        self.assertEqual(g.peek("wEnemyBattleStatus2") & HAS_SUBSTITUTE_UP, 0)

    # Bide and Rage
    def test_bide_two_turns(self):
        g = self.game
        self.use("BideEffect", "BIDE")
        self.assertEqual(g.peek("wPlayerNumAttacksLeft"), 2)
        self.assertEqual(g.random_used(), 0)

    def test_rage_ends_with_another_move(self):
        g = self.game
        g.poke("wBattleMonStatus", 0)
        g.poke("wPlayerBattleStatus2", USING_RAGE)
        g.poke("wPlayerSelectedMove", MOVES["RAGE"])
        g.call("CheckPlayerStatusConditions", max_frames=5000)
        self.assertTrue(g.peek("wPlayerBattleStatus2") & USING_RAGE)
        g.poke("wPlayerSelectedMove", MOVES["TACKLE"])
        out = g.call("CheckPlayerStatusConditions", max_frames=5000)
        self.assertFalse(out["z"])  # it moves
        self.assertFalse(g.peek("wPlayerBattleStatus2") & USING_RAGE)
