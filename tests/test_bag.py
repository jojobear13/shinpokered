"""The bag screen: one pocket at a time, the bag kept in pocket order.

SortBag puts the bag in ItemSortList's order (pocket by pocket, as
data/item_pockets.asm lists them) when the bag screen, the PC's deposit list
or the mart's sell list opens; BagLoadPocket lists the bag's entries in one
pocket; BagMenu returns the chosen item's real index in the bag."""

import os
import random
import re
import unittest

from harness import REPO_ROOT, shared_game
from test_held_items import ITEMS

POCKETS = ["POCKET_ITEMS", "POCKET_MEDICINE", "POCKET_BALLS", "POCKET_BATTLE",
           "POCKET_BERRIES", "POCKET_TMHM", "POCKET_KEY"]


def _pocket_data():
    pockets = {}
    order = []
    section = None
    with open(os.path.join(REPO_ROOT, "data", "item_pockets.asm")) as f:
        for line in f:
            if line.startswith("ItemPockets"):
                section = "pockets"
            elif line.startswith("ItemSortList"):
                section = "sort"
            m = re.match(r"\s*db (\w+)\s*; (\w+)", line)
            if section == "pockets" and m:
                pockets[ITEMS[m.group(2)]] = POCKETS.index(m.group(1))
                continue
            m = re.match(r"\s*db (\w+)(?: \+ (\d+))?\s*$", line)
            if section == "sort" and m and m.group(1) in ITEMS:
                order.append(ITEMS[m.group(1)] + int(m.group(2) or 0))
    return pockets, order


POCKET_OF, SORT_ORDER = _pocket_data()


def pocket(item):
    return POCKETS.index("POCKET_TMHM") if item >= ITEMS["HM_01"] else POCKET_OF[item]


class BagTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()

    def fill_bag(self, entries):
        flat = []
        for item, qty in entries:
            flat += [item, qty]
        self.game.poke("wNumBagItems", len(entries), *flat, 0xFF)

    def bag(self):
        n = self.game.peek("wNumBagItems")
        raw = self.game.peek(self.game.addr("wNumBagItems") + 1, 2 * n + 1)
        self.assertEqual(raw[-1], 0xFF)
        return [(raw[2 * i], raw[2 * i + 1]) for i in range(n)]

    def sample(self, seed, n=20):
        rng = random.Random(seed)
        items = rng.sample(SORT_ORDER, n)
        return [(item, rng.randint(1, 99)) for item in items]

    def test_sort_list_covers_every_item(self):
        self.assertEqual(sorted(SORT_ORDER), sorted(set(SORT_ORDER)))
        self.assertLessEqual(set(SORT_ORDER), set(POCKET_OF) | set(range(ITEMS["HM_01"], ITEMS["TM_50"] + 1)))
        self.assertLessEqual(set(range(ITEMS["HM_01"], ITEMS["TM_50"] + 1)), set(SORT_ORDER))
        pockets = [pocket(item) for item in SORT_ORDER]
        self.assertEqual(pockets, sorted(pockets))

    def test_sort_order(self):
        g = self.game
        for seed in range(6):
            with self.subTest(seed=seed):
                g.reset()
                entries = self.sample(seed)
                self.fill_bag(entries)
                out = g.call("SortBag", bc=0x1234, de=0x5678, hl=0x9ABC, max_frames=50)
                self.assertEqual(self.bag(), sorted(entries, key=lambda e: SORT_ORDER.index(e[0])))  # one stack each
                self.assertEqual((out["bc"], out["de"], out["hl"]), (0x1234, 0x5678, 0x9ABC))

    def test_second_stacks_stay_together(self):
        g = self.game
        potion, ball, repel = ITEMS["POTION"], ITEMS["POKE_BALL"], ITEMS["REPEL"]
        self.fill_bag([(potion, 99), (ball, 3), (potion, 5), (repel, 1), (ball, 99)])
        g.call("SortBag", max_frames=50)
        bag = self.bag()
        self.assertEqual([item for item, _ in bag], [repel, potion, potion, ball, ball])
        self.assertEqual(sorted(bag), sorted([(repel, 1), (potion, 99), (potion, 5), (ball, 3), (ball, 99)]))

    def test_item_pocket(self):
        g = self.game
        for item in SORT_ORDER:
            with self.subTest(item=item):
                out = g.call("ItemPocket", a=item, bc=0x1234, hl=0x5678)
                self.assertEqual(out["a"], pocket(item))
                self.assertEqual((out["bc"], out["hl"]), (0x1234, 0x5678))

    def test_pocket_lists(self):
        g = self.game
        entries = self.sample(7, 30)
        self.fill_bag(entries)
        for p in range(len(POCKETS)):
            with self.subTest(pocket=POCKETS[p]):
                g.poke("wBagPocket", p)
                g.poke("wBagCursor", 0)
                g.poke("wBagScroll", 0)
                g.call("BagLoadPocket")
                n = g.peek("wBagPocketList")
                listed = list(g.peek(g.addr("wBagPocketList") + 1, n)) if n > 1 else [g.peek(g.addr("wBagPocketList") + 1)] if n else []
                self.assertEqual(listed, [i for i, (item, _) in enumerate(entries) if pocket(item) == p])

    def test_choose_gives_the_real_index(self):
        g = self.game
        g.auto_buttons()  # A (and B) at once: the entry under the cursor
        entries = [e for e in self.sample(11, 30) if e[0] not in (ITEMS["POTION"], ITEMS["ANTIDOTE"])]
        self.fill_bag(entries + [(ITEMS["POTION"], 4), (ITEMS["ANTIDOTE"], 7)])
        g.call("SortBag", max_frames=50)
        bag = self.bag()
        medicine = [i for i, (item, _) in enumerate(bag) if pocket(item) == POCKETS.index("POCKET_MEDICINE")]
        self.assertGreater(len(medicine), 1)
        g.poke("wBagPocket", POCKETS.index("POCKET_MEDICINE"))
        g.poke("wBagCursor", 1)
        g.poke("wBagScroll", 0)
        out = g.call("BagMenu", max_frames=600)
        self.assertFalse(out["carry"])
        self.assertEqual(g.peek("wWhichPokemon"), medicine[1])
        self.assertEqual(g.peek("wcf91"), bag[medicine[1]][0])
        self.assertEqual(g.peek("wMaxItemQuantity"), bag[medicine[1]][1])

    def test_cancel_entry(self):
        g = self.game
        g.auto_buttons()
        self.fill_bag([(ITEMS["POTION"], 1)])
        g.poke("wBagPocket", POCKETS.index("POCKET_MEDICINE"))
        g.poke("wBagCursor", 1)  # CANCEL
        g.poke("wBagScroll", 0)
        out = g.call("BagMenu", max_frames=600)
        self.assertTrue(out["carry"])


if __name__ == "__main__":
    unittest.main()
