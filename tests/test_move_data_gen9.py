"""Spec tests for Gen 9's move data (design brief, Gen 9 rules pass, part 7):
the numbers in data/moves.asm match PokeAPI's, and the remapped effects
(Tri Attack, Growth, Skull Bash's charge, a Poison type's Toxic) work.
"""

import csv
import os
import random
import re
import unittest

from harness import REPO_ROOT, shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN, _constants
from test_types import TYPES

POKEAPI = "/tmp/claude-0/pokeapi/moves.csv"
MOVES = _constants("move_constants.asm", ["TRI_ATTACK", "GROWTH", "SKULL_BASH", "TOXIC", "TACKLE"])
BRN, FRZ, PAR = 1 << 4, 1 << 5, 1 << 6
TRI_ATTACK_EFFECT, GROWTH_EFFECT, CHARGE_EFFECT = 0x49, 0x4A, 0x27
MOD_ATTACK, MOD_DEFENSE, MOD_SPECIAL_ATTACK = 0, 1, 3


def rows():
    with open(os.path.join(REPO_ROOT, "data", "moves.asm")) as f:
        lines = f.read().splitlines()
    for line in lines:
        m = re.match(r"\s*move (\w+),\s*(\w+),\s*(\d+),\s*(\w+),\s*(\d+),\s*(\d+)", line)
        if m:
            yield m.groups()


class DataTest(unittest.TestCase):
    @unittest.skipUnless(os.path.exists(POKEAPI), "PokeAPI's CSVs aren't here")
    def test_numbers_are_gen9s(self):
        with open(POKEAPI) as f:
            api = {int(r["id"]): r for r in csv.DictReader(f)}
        for i, (name, effect, power, typ, accuracy, pp) in enumerate(rows(), 1):
            if i > 164:  # Struggle keeps its own row
                break
            r = api[i]
            with self.subTest(name=name):
                if r["power"] and name != "LOW_KICK":
                    self.assertEqual(int(power), int(r["power"]))
                self.assertEqual(int(accuracy), int(r["accuracy"] or 100))
                self.assertEqual(int(pp), int(r["pp"]))


class EffectsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        mx.setup(g, random.Random(31))
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
        g.poke("wEnemyMonStatus", 0)
        g.poke("wBattleMonStatus", 0)

    def test_tri_attack(self):
        g = self.game
        for pick, status in ((0, BRN), (1, FRZ), (2, PAR), (3, None)):
            with self.subTest(pick=pick):
                self.setUp()
                g.poke("wPlayerMoveNum", MOVES["TRI_ATTACK"])
                g.poke("wPlayerMoveEffect", TRI_ATTACK_EFFECT)
                g.queue_random(*([3, 0, 0] if status is None else [pick, 0]))  # the pick, then the 20% roll
                g.call("TriAttackEffect", max_frames=6000)
                self.assertEqual(g.peek("wEnemyMonStatus"), status or BRN)  # 3 rerolls to burn
                self.assertEqual(g.peek("wPlayerMoveEffect"), TRI_ATTACK_EFFECT)

    def test_growth(self):
        g = self.game
        g.poke("wPlayerMoveNum", MOVES["GROWTH"])
        g.poke("wPlayerMoveEffect", GROWTH_EFFECT)
        g.call("GrowthEffect", max_frames=6000)
        mods = g.peek("wPlayerMonStatMods", 7)
        self.assertEqual((mods[MOD_ATTACK], mods[MOD_SPECIAL_ATTACK]), (8, 8))
        self.assertEqual(g.peek("wPlayerMoveEffect"), GROWTH_EFFECT)

    def test_skull_bash_raises_defense(self):
        g = self.game
        g.poke("wPlayerMoveNum", MOVES["SKULL_BASH"])
        g.poke("wPlayerMoveEffect", CHARGE_EFFECT)
        g.call("ChargeEffect", max_frames=6000)
        self.assertEqual(g.peek("wPlayerMonStatMods", 7)[MOD_DEFENSE], 8)
        self.assertEqual(g.peek("wPlayerMoveEffect"), CHARGE_EFFECT)

    def test_poison_types_toxic_never_misses(self):
        g = self.game
        for types, used in ((("POISON", "GROUND"), 0), (("NORMAL", "NORMAL"), 1)):
            with self.subTest(types=types):
                self.setUp()
                g.poke("wBattleMonType1", *[TYPES[t] for t in types])
                g.poke("wPlayerMoveNum", MOVES["TOXIC"])
                g.poke("wPlayerMoveAccuracy", 0)
                g.queue_random(200)
                g.call("MoveHitTest", max_frames=6000)
                self.assertEqual(g.random_used(), used)
