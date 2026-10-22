"""The item descriptions (engine/menu/item_descriptions.asm): every item that
can be in the bag has two lines, each fitting the box's 18 tiles; the shop's
buy list shows them for the entry under its cursor (a TM or HM: its move)."""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game

NEXT, END, POKE = 0x4E, 0x50, 0x54  # "#" prints as POKé: 4 tiles


def decode(data):
    out = ""
    for b in data:
        if 0x80 <= b <= 0x99:
            out += chr(ord("A") + b - 0x80)
        elif 0xA0 <= b <= 0xB9:
            out += chr(ord("a") + b - 0xA0)
        elif 0xF6 <= b <= 0xFF:
            out += chr(ord("0") + b - 0xF6)
        else:
            out += {0x7F: " ", 0xE8: ".", 0xBA: "é", 0x54: "POKé"}.get(b, "?")
    return out


def item_constants():
    names = []
    with open(os.path.join(REPO_ROOT, "constants", "item_constants.asm")) as f:
        for line in f:
            m = re.match(r"\s*const (\w+)", line)
            if m:
                names.append(m.group(1))
            if "NUM_ITEMS_AND_FLOORS" in line:
                break
    return names


class ItemDescriptionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def text(self, item):
        g = self.game
        bank, table = g.symbols["ItemDescriptions"]
        lo, hi = g.peek((bank, table + 2 * (item - 1)), 2)
        address = lo | hi << 8
        if not address:
            return None
        out = []
        while True:
            b = g.peek((bank, address + len(out)))
            if b == END:
                return out
            out.append(b)

    def test_every_bag_item_has_two_lines_that_fit(self):
        for number, name in enumerate(item_constants(), 1):
            with self.subTest(item=name):
                text = self.text(number)
                if name.endswith("BADGE") or name.startswith("FLOOR_") or name == "COIN":
                    self.assertIsNone(text)  # never in the bag
                    continue
                self.assertIsNotNone(text)
                self.assertEqual(text.count(NEXT), 1)
                for line in (text[:text.index(NEXT)], text[text.index(NEXT) + 1:]):
                    self.assertLessEqual(sum(4 if b == POKE else 1 for b in line), 18)

    def mart_lines(self, items, entry):
        """MartDrawDescription with the buy list items (cursor on entry) ->
        the text box's two lines"""
        g = self.game
        g.reset()
        g.poke("wItemList", len(items), *items, 0xFF)
        g.poke("wListCount", len(items))
        g.poke("wListScrollOffset", 0)
        g.poke("wCurrentMenuItem", entry)
        g.poke("wRandoFlags3", 0)
        g.call("MartDrawDescription", max_frames=200)
        return [decode(g.peek(f"wTileMap+{row * 20 + 1}", 18)).strip() for row in (14, 16)]

    def test_mart_buy_list(self):
        names = {n: i for i, n in enumerate(item_constants(), 1)}
        potion, tm32 = names["POTION"], 0xC9 + 31
        self.assertEqual(self.mart_lines([potion, tm32], 0), ["Restores 20 HP", "to a POKéMON."])
        self.assertEqual(self.mart_lines([potion, tm32], 1), ["Teaches the move", "DOUBLE TEAM."])
        self.assertEqual(self.mart_lines([potion, tm32], 2), ["Done shopping.", ""])


if __name__ == "__main__":
    unittest.main()
