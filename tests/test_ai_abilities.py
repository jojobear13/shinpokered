"""Spec tests for the trainer AI and abilities (design brief, plan step E).

The AI's move scoring (layer 3, the one that already weighs typing) treats a
move the player's mon's ability stops as having no effect, and its switching
doesn't flee a super-effective move this mon's ability stops. Both ask
MoveBlockedByAbility, the side-effect-free half of the battle's own gate
(AbilityBlocksMove), so they can't disagree with it.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from test_abilities import ABILITIES
from test_ability_damage import MOVES, SIDES
from test_held_item_sources import TRAINERS
from test_special_split import SPECIES

BLOCKERS = ["NO_ABILITY", "LEVITATE", "VOLT_ABSORB", "WATER_ABSORB", "DRY_SKIN", "LIGHTNING_ROD",
            "FLASH_FIRE", "SOUNDPROOF", "STURDY", "DAMP", "INSOMNIA", "VITAL_SPIRIT", "IMMUNITY",
            "LIMBER", "OWN_TEMPO", "CLEAR_BODY", "HYPER_CUTTER", "KEEN_EYE", "ILLUMINATE",
            "MOLD_BREAKER", "NEUTRALIZING_GAS"]
TYPES = {"NORMAL": 0x00, "GROUND": 0x04, "FIRE": 0x14, "WATER": 0x15, "ELECTRIC": 0x17}
# moves the abilities above stop, so a good share of the random cases are blocked
RELEVANT = ["THUNDERBOLT", "THUNDER_WAVE", "SURF", "EMBER", "EARTHQUAKE", "DIG", "SING", "GROWL",
            "SUPERSONIC", "FISSURE", "EXPLOSION", "SELFDESTRUCT", "SPORE", "TOXIC", "GLARE",
            "CONFUSE_RAY", "SCREECH", "SAND_ATTACK", "FLASH", "HYPNOSIS"]


class AgreementTest(unittest.TestCase):
    """The AI's answer is the battle's, for either side's move."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_matches_the_gate(self):
        g = self.game
        rng = random.Random(26)
        moves = sorted(name for name in MOVES if MOVES[name] <= 0xA4)  # Gen 1's, whose mix the count below expects
        blocked = 0
        for case in range(300):
            turn = case & 1
            move = rng.choice(RELEVANT if case % 4 < 2 else moves)
            user, target = rng.choice(BLOCKERS), rng.choice(BLOCKERS)
            with self.subTest(case=case, move=move, user=user, target=target, turn=turn):
                answers = []
                for routine in ("AI", "AbilityBlocksMove"):
                    g.reset()
                    mx.setup(g, random.Random(case))
                    g.poke("wPlayerAbility", *[ABILITIES[user], ABILITIES[target]][::1 - 2 * turn])
                    g.poke(SIDES[turn][0] + "SelectedMove", MOVES[move])
                    g.poke(H_WHOSETURN, turn)
                    g.call("GetCurrentMove")
                    g.poke(SIDES[1 - turn][0] + "BattleStatus1", 0)
                    if routine == "AI":
                        g.poke(H_WHOSETURN, 1 - turn)  # the AI's call puts it back
                        name = "AIEnemyMoveBlocked" if turn else "AIPlayerMoveBlocked"
                        answers.append(g.call(name)["carry"])
                        self.assertEqual(g.peek(H_WHOSETURN), 1 - turn)
                    else:
                        answers.append(g.call("AbilityBlocksMove", max_frames=2000)["carry"])
                self.assertEqual(answers[0], answers[1])
                blocked += answers[0]
        self.assertGreater(blocked, 20)


class MoveChoiceTest(unittest.TestCase):
    """AIEnemyTrainerChooseMoves for a Sailor, whose layers are 1 and 3."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def choices(self, moves, ability, player_type="NORMAL", enemy_type="NORMAL"):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(5))
        g.clear_random()
        g.queue_random(*[0xFF] * 32)
        g.poke("wIsInBattle", 2)
        g.poke("wTrainerClass", TRAINERS["SAILOR"])
        g.poke("wEnemyMonMoves", *[MOVES[m] for m in moves], *[0] * (4 - len(moves)))
        g.poke("wEnemyMonPP", 20, 20, 20, 20)
        g.poke("wEnemyDisabledMove", 0)
        g.poke("wActionResultOrTookBattleTurn", 0)
        g.poke("wUnusedC000", 0)
        g.poke("wBattleMonStatus", 0)
        g.poke("wPlayerBattleStatus1", 0, 0, 0)
        g.poke("wBattleMonType", TYPES[player_type], TYPES[player_type])
        g.poke("wEnemyMonType", TYPES[enemy_type], TYPES[enemy_type])
        g.poke("wPlayerAbility", ABILITIES["NO_ABILITY"] if ability is None else ABILITIES[ability],
               ABILITIES["NO_ABILITY"])
        g.call("AIEnemyTrainerChooseMoves", max_frames=600)
        chosen = g.peek("wBuffer", 4)
        names = {v: k for k, v in MOVES.items()}
        return {names[v] for v in chosen if v}

    def test_type_immunities(self):
        # each pair: what a STAB move's user picks with no ability in the way,
        # and with one
        cases = [
            ("THUNDERBOLT", "VOLT_ABSORB", "NORMAL", "ELECTRIC"),
            ("THUNDERBOLT", "LIGHTNING_ROD", "NORMAL", "ELECTRIC"),
            ("SURF", "WATER_ABSORB", "NORMAL", "WATER"),
            ("SURF", "DRY_SKIN", "NORMAL", "WATER"),
            ("EMBER", "FLASH_FIRE", "NORMAL", "FIRE"),
            ("EARTHQUAKE", "LEVITATE", "ELECTRIC", "GROUND"),  # super effective, too
        ]
        for move, ability, player_type, enemy_type in cases:
            with self.subTest(move=move, ability=ability):
                self.assertEqual(self.choices([move, "TACKLE"], None, player_type, enemy_type), {move})
                self.assertEqual(self.choices([move, "TACKLE"], ability, player_type, enemy_type), {"TACKLE"})
                self.assertEqual(self.choices([move, "TACKLE"], "MOLD_BREAKER", player_type, enemy_type), {move})

    def scores(self, moves, ability):
        """The moves' scores before the AI picks the lowest (lower is better)."""
        self.choices(moves, ability)
        return self.game.peek("wBuffer", 8)[4:4 + len(moves)]

    def test_status_moves(self):
        # no effect: the same 5 points layer 3 adds for a type immunity
        cases = [
            ("THUNDER_WAVE", "LIMBER"), ("SING", "INSOMNIA"), ("SING", "SOUNDPROOF"),
            ("CONFUSE_RAY", "OWN_TEMPO"), ("TOXIC", "IMMUNITY"), ("GROWL", "HYPER_CUTTER"),
            ("SCREECH", "CLEAR_BODY"), ("SAND_ATTACK", "KEEN_EYE"),
        ]
        for move, ability in cases:
            with self.subTest(move=move, ability=ability):
                before = self.scores([move], None)[0]
                self.assertEqual(self.scores([move], ability)[0], before + 5)
        self.assertEqual(self.choices(["THUNDER_WAVE", "SING"], None), {"THUNDER_WAVE", "SING"})
        self.assertEqual(self.choices(["THUNDER_WAVE", "SING"], "LIMBER"), {"SING"})
        self.assertEqual(self.choices(["THUNDER_WAVE", "SING"], "INSOMNIA"), {"THUNDER_WAVE"})

    def test_what_still_works(self):
        for move, ability in (("BODY_SLAM", "LIMBER"), ("LEER", "HYPER_CUTTER"), ("TACKLE", "STURDY")):
            with self.subTest(move=move, ability=ability):
                self.assertEqual(self.scores([move], ability), self.scores([move], None))

    def test_the_enemys_mold_breaker(self):
        g = self.game
        original = g.poke

        def poke(where, *values):
            if where == "wPlayerAbility":
                values = (values[0], ABILITIES["MOLD_BREAKER"])
            return original(where, *values)

        g.poke = poke
        try:
            chosen = self.choices(["THUNDERBOLT", "TACKLE"], "VOLT_ABSORB", "NORMAL", "ELECTRIC")
        finally:
            g.poke = original
        self.assertEqual(chosen, {"THUNDERBOLT"})


if __name__ == "__main__":
    unittest.main()
