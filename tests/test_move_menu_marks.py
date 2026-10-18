"""Spec test for the move menu's category and effectiveness marks.

On the move menu, the line above the move's type shows its category (PHYS,
SPCL or STAT) on the left and its effectiveness against the enemy on the right:
two up triangles for 4x, one for 2x, nothing for 1x, one down triangle for
1/2x, two for 1/4x and a cross for no effect. Status moves get no mark, and
fixed-damage moves only show the cross.
"""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game

SCREEN_WIDTH = 20
UP, DOWN, CROSS, SPACE = 0xE9, 0xEE, 0xF1, 0x7F
TEXT = {"P": 0x8F, "H": 0x87, "Y": 0x98, "S": 0x92, "C": 0x82, "L": 0x8B, "T": 0x93, "A": 0x80}

NORMAL, FIGHTING, GROUND, ROCK, GHOST = 0x00, 0x01, 0x04, 0x05, 0x08
FIRE, WATER = 0x14, 0x15


def _constants(path, pattern):
    values = {}
    with open(os.path.join(REPO_ROOT, path)) as f:
        for line in f:
            m = re.match(pattern, line)
            if m:
                values[m.group(1)] = int(m.group(2), 16)
    return values


MOVES = _constants("constants/move_constants.asm", r"\s*const (\w+)\s*; ([0-9a-f]{2})\s*$")
MAPS = _constants("constants/map_constants.asm", r"\s*mapconst (\w+),.*; \$([0-9A-F]{2})")
ITEMS = _constants("constants/item_constants.asm", r"\s*const (\w+)\s*; \$([0-9A-F]{2})")
EFFECTS = _constants("constants/move_effect_constants.asm", r"\s*const (\w+)\s*; \$([0-9A-F]{2})")

CASES = [
    # move, its type, effect, enemy types, category text, mark on columns 8-9
    ("DOUBLE_KICK", FIGHTING, "NO_ADDITIONAL_EFFECT", (NORMAL, NORMAL), "PHYS", (SPACE, UP)),
    ("LICK", GHOST, "NO_ADDITIONAL_EFFECT", (NORMAL, NORMAL), "PHYS", (SPACE, CROSS)),
    ("NIGHT_SHADE", GHOST, "SPECIAL_DAMAGE_EFFECT", (NORMAL, NORMAL), "SPCL", (SPACE, CROSS)),
    ("SEISMIC_TOSS", FIGHTING, "SPECIAL_DAMAGE_EFFECT", (ROCK, ROCK), "PHYS", (SPACE, SPACE)),
    ("GROWL", NORMAL, "NO_ADDITIONAL_EFFECT", (GHOST, GHOST), "STAT", (SPACE, SPACE)),
    ("WATER_GUN", WATER, "NO_ADDITIONAL_EFFECT", (ROCK, GROUND), "SPCL", (UP, UP)),
    ("TACKLE", NORMAL, "NO_ADDITIONAL_EFFECT", (ROCK, GROUND), "PHYS", (SPACE, DOWN)),
    ("EMBER", FIRE, "NO_ADDITIONAL_EFFECT", (WATER, ROCK), "SPCL", (DOWN, DOWN)),
    ("WATER_GUN", WATER, "NO_ADDITIONAL_EFFECT", (WATER, ROCK), "SPCL", (SPACE, SPACE)),
]


class MoveMenuMarksTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_marks(self):
        g = self.game
        row = g.addr("wTileMap") + 9 * SCREEN_WIDTH
        for move, move_type, effect, enemy_types, text, mark in CASES:
            with self.subTest(move=move, enemy=enemy_types):
                g.reset()
                g.poke(row, *[SPACE] * SCREEN_WIDTH)
                g.poke("wPlayerMoveNum", MOVES[move])
                g.poke("wPlayerMoveEffect", EFFECTS[effect])
                g.poke("wPlayerMoveType", move_type)
                g.poke("wEnemyMonType1", *enemy_types)
                g.poke("wTypeEffectiveness", 0x5A)
                g.poke("wUnusedC000", 0)
                g.poke("wIsInBattle", 2)  # a trainer battle: never a ghost battle
                g.call("PrintMoveCategoryAndEffectiveness")
                self.assertEqual(g.peek(row + 1, 4), [TEXT[c] for c in text])
                self.assertEqual(tuple(g.peek(row + 8, 2)), mark)
                # the routine borrows these and puts them back
                self.assertEqual(g.peek("wTypeEffectiveness"), 0x5A)
                self.assertEqual(g.peek("wUnusedC000"), 0)

    def test_no_mark_against_an_unidentified_ghost(self):
        g = self.game
        row = g.addr("wTileMap") + 9 * SCREEN_WIDTH
        for scope in (False, True):
            with self.subTest(silph_scope=scope):
                g.reset()
                g.poke(row, *[SPACE] * SCREEN_WIDTH)
                g.poke("wPlayerMoveNum", MOVES["LICK"])
                g.poke("wPlayerMoveEffect", EFFECTS["NO_ADDITIONAL_EFFECT"])
                g.poke("wPlayerMoveType", GHOST)
                g.poke("wEnemyMonType1", NORMAL, NORMAL)
                g.poke("wIsInBattle", 1)
                g.poke("wCurMap", MAPS["POKEMONTOWER_3"])
                if scope:
                    g.poke("wNumBagItems", 1)
                    g.poke("wBagItems", ITEMS["SILPH_SCOPE"], 1, 0xFF)
                else:
                    g.poke("wNumBagItems", 0)
                    g.poke("wBagItems", 0xFF)
                g.call("PrintMoveCategoryAndEffectiveness")
                self.assertEqual(g.peek(row + 1, 4), [TEXT[c] for c in "PHYS"])
                self.assertEqual(tuple(g.peek(row + 8, 2)), (SPACE, CROSS) if scope else (SPACE, SPACE))


if __name__ == "__main__":
    unittest.main()
