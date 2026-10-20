"""Spec tests for the learnset audit's learnsets (design brief, Gen 9 rules
pass, part 9): the sheet is fully applied, every learnset is in level order
with real moves, and a mon learns its level 1 moves (the hook evolution uses).
"""

import os
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

from harness import REPO_ROOT, shared_game
from suites.apply_attack import _constants

AUDIT = "/root/.claude/uploads/d6690a75-b162-5573-9c11-1a26110a1d0f/d20e57bd-Gen1_Remaster_Learnset_Audit.xlsx"
MOVES = _constants("move_constants.asm", ["WATER_GUN", "TACKLE", "QUICK_ATTACK", "SAND_ATTACK"])
SPECIES = _constants("pokemon_constants.asm", ["VAPOREON"])


def learnsets():
    with open(os.path.join(REPO_ROOT, "data", "evos_moves.asm")) as f:
        text = f.read()
    for name, body in re.findall(r"^(\w+)EvosMoves:\n(.*?)\n(?=\w+EvosMoves:|\Z)", text, re.M | re.S):
        if "; Learnset\n" not in body:
            continue
        part = body.split("; Learnset\n", 1)[1].split("\tdb 0\n", 1)[0]
        yield name, [(int(l), m) for l, m in re.findall(r"\tdb (\d+), (\w+)", part)]


class LearnsetDataTest(unittest.TestCase):
    def test_in_level_order_with_real_moves(self):
        with open(os.path.join(REPO_ROOT, "constants", "move_constants.asm")) as f:
            moves = set(re.findall(r"^\s*const (\w+)", f.read(), re.M))
        for name, entries in learnsets():
            with self.subTest(name=name):
                levels = [l for l, m in entries]
                self.assertEqual(levels, sorted(levels))
                self.assertTrue(all(m in moves for l, m in entries))
                self.assertTrue(all(1 <= l <= 100 for l in levels))

    @unittest.skipUnless(os.path.exists(AUDIT), "the audit spreadsheet isn't here")
    def test_audit_fully_applied(self):
        with tempfile.TemporaryDirectory() as tmp:
            for part in ("data", "constants"):
                shutil.copytree(os.path.join(REPO_ROOT, part), os.path.join(tmp, part))
            subprocess.run([sys.executable, os.path.join(REPO_ROOT, "tools", "apply_learnset_audit.py"),
                            AUDIT, tmp], check=True, capture_output=True)
            for path in ("data/evos_moves.asm",) + tuple(
                    os.path.join("data", "baseStats", n) for n in os.listdir(os.path.join(tmp, "data", "baseStats"))):
                with self.subTest(path=path):
                    with open(os.path.join(tmp, path)) as a, open(os.path.join(REPO_ROOT, path)) as b:
                        self.assertEqual(a.read(), b.read())


class LevelOneMovesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_vaporeon_learns_water_gun_at_level_1(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.poke("wPartyCount", 1)
        g.poke("wPartyMon1Moves", MOVES["TACKLE"], MOVES["QUICK_ATTACK"], 0, 0)
        g.poke("wWhichPokemon", 0)
        g.poke("wMonDataLocation", 0)
        g.poke("wd11e", SPECIES["VAPOREON"])
        g.poke("wCurEnemyLVL", 1)
        g.call("LearnMoveFromLevelUp", max_frames=20000)
        self.assertEqual(g.peek("wPartyMon1Moves", 4)[:3], [MOVES["TACKLE"], MOVES["QUICK_ATTACK"], MOVES["WATER_GUN"]])
