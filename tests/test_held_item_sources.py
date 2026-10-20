"""Spec tests for held items, part 4: where they come from (design brief,
plan step E, part 5).

Wild mons hold their species' common item 23% of the time (Random < 59) and
its rare one 2% (59-63). Gym leaders', the Elite Four's and the champion's
aces hold items. Marts sell type boosters and berries: the mart lists live
in bank $34 now, and a mart's text keeps only $FE and the list's index.
Some field items are held items.
"""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game
from test_held_items import ITEMS
from test_special_split import SPECIES


def _trainer_classes():
    values = {}
    with open(os.path.join(REPO_ROOT, "constants", "trainer_constants.asm")) as f:
        for line in f:
            m = re.match(r"\s*trainer_const (\w+)\s*; \$([0-9A-Fa-f]+)", line)
            if m:
                values[m.group(1)] = int(m.group(2), 16)
    return values


TRAINERS = _trainer_classes()


def _read(path):
    with open(os.path.join(REPO_ROOT, path)) as f:
        return f.read()


def _mart_lists():
    """Each mart's items, in index order, from data/mart_lists.asm."""
    lists = []
    for m in re.finditer(r"^\tdb (\d+), (.*), \$FF$", _read("data/mart_lists.asm"), re.M):
        items = [name.strip() for name in m.group(2).split(",")]
        assert len(items) == int(m.group(1)), m.group(0)
        lists.append(items)
    return lists


def _mart_indexes():
    """Each mart text's label and the index it names."""
    return {m.group(1): int(m.group(2)) for m in re.finditer(
        r"^(\w+)::\n(?:\t;.*\n)?\tdb \$FE, (\d+)", _read("data/mart_inventories.asm"), re.M)}


class WildHeldItemTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def held(self, species, *rolls):
        g = self.game
        g.reset()
        g.clear_random()
        if rolls:
            g.queue_random(*rolls)
        g.poke("wIsInBattle", 1)
        g.poke("wEnemyMonSpecies", SPECIES[species])
        g.poke("wEnemyMonCatchRate", 0xAA)
        g.call("GetEnemyHeldItem", de=g.addr("wEnemyMonCatchRate"))
        self.assertEqual(g.random_used(), len(rolls))
        return g.peek("wEnemyMonCatchRate")

    def test_rolls(self):
        self.assertEqual(self.held("PIKACHU", 0), ITEMS["BERRY"])
        self.assertEqual(self.held("PIKACHU", 58), ITEMS["BERRY"])
        self.assertEqual(self.held("PIKACHU", 59), ITEMS["LIGHT_BALL"])
        self.assertEqual(self.held("PIKACHU", 63), ITEMS["LIGHT_BALL"])
        self.assertEqual(self.held("PIKACHU", 64), 0)
        self.assertEqual(self.held("PIKACHU", 255), 0)
        self.assertEqual(self.held("SNORLAX", 63), ITEMS["LEFTOVERS"])

    def test_species_without_items(self):
        self.assertEqual(self.held("RATTATA"), 0)  # no roll at all

    def test_table(self):
        rows = re.findall(r"^\tdb (\w+),\s*(\w+),\s*(\w+)", _read("data/wild_held_items.asm"), re.M)
        self.assertGreater(len(rows), 20)
        species = [row[0] for row in rows]
        self.assertEqual(len(species), len(set(species)))
        for name, common, rare in rows:
            self.assertIn(name, SPECIES)
            for item in (common, rare):
                self.assertTrue(item == "0" or item in ITEMS, item)


class TrainerHeldItemTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def party_items(self, trainer, number):
        g = self.game
        g.reset()
        g.poke("wIsInBattle", 2)
        g.poke("wTrainerClass", TRAINERS[trainer])
        g.poke("wTrainerNo", number)
        g.call("ReadTrainer", max_frames=600)
        count = g.peek("wEnemyPartyCount")
        return [g.peek(f"wEnemyMon{i + 1}CatchRate") for i in range(count)]

    def test_leader_ace(self):
        self.assertEqual(self.party_items("BROCK", 1), [0, ITEMS["BERRY"]])
        self.assertEqual(self.party_items("LANCE", 1)[-1], ITEMS["DRAGON_FANG"])

    def test_rival_champion(self):
        for number in (1, 2, 3):
            items = self.party_items("SONY3", number)
            self.assertEqual(len(items), 6)
            self.assertEqual(items[5], ITEMS["LEFTOVERS"])

    def test_ordinary_trainer_holds_nothing(self):
        items = self.party_items("YOUNGSTER", 1)
        self.assertTrue(items)
        self.assertEqual(set(items), {0})


class MartTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_lists_load(self):
        g = self.game
        lists = _mart_lists()
        indexes = sorted(_mart_indexes().values())
        self.assertEqual(len(indexes), len(set(indexes)))
        self.assertEqual(len(indexes), len(lists) - 1)  # the bike shop's list has no label
        self.assertLess(indexes[-1], len(lists))
        for index, items in enumerate(lists):
            g.reset()
            g.poke("wItemScratch", index)
            g.call("LoadMartInventory")
            data = g.peek("wItemList", len(items) + 2)
            self.assertEqual(data, [len(items)] + [ITEMS[name] for name in items] + [0xFF])

    def test_lists_fit(self):
        for items in _mart_lists():
            self.assertLessEqual(len(items) + 2, 16)  # wItemList

    def test_held_items_on_sale(self):
        indexes = _mart_indexes()
        lists = _mart_lists()
        celadon4 = lists[indexes["CeladonMart4ClerkText"]]
        self.assertIn("CHARCOAL", celadon4)
        sold = {item for items in lists for item in items}
        self.assertTrue({"BERRY", "PRZCUREBERRY", "MINT_BERRY"} <= sold)


class SourcesTest(unittest.TestCase):
    def test_field_items(self):
        found = set()
        folder = os.path.join(REPO_ROOT, "data", "mapObjects")
        for name in os.listdir(folder):
            with open(os.path.join(folder, name)) as f:
                found |= set(re.findall(r"object SPRITE_BALL, .*, (\w+)$", f.read(), re.M))
        held = {name for name in found if ITEMS.get(name, 0) in range(ITEMS["BLACK_BELT"], ITEMS["FOCUS_SASH"] + 1)}
        self.assertGreaterEqual(len(held), 15)
