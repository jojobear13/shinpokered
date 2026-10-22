"""The bag's item descriptions (engine/menu/item_descriptions.asm): every
item that can be in the bag has two lines, each fitting the box's 18 tiles."""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game

NEXT, END, POKE = 0x4E, 0x50, 0x54  # "#" prints as POKé: 4 tiles


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


if __name__ == "__main__":
    unittest.main()
