"""Spec tests for held items, part 1: the items and holding them (design
brief, plan step E, part 5).

A mon's held item is the catch-rate byte of its data (decision 6), 0 for
none. Gen 2's held items plus a few later staples are new item ids from
FIRST_HELD_ITEM. Using one from the bag gives it to a party mon (one it held
goes back in the bag); TAKE on the party menu takes it. Nuzlocke mode's
"dead" mark, which used that byte, is a bit of the IVs' flags byte now.
"""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game
from test_special_split import SPECIES

TERMINATOR = 0x50
NUZLOCKE_DEAD = 1 << 1


def _items():
    values = {}
    with open(os.path.join(REPO_ROOT, "constants", "item_constants.asm")) as f:
        for line in f:
            m = re.match(r"\s*const (\w+)\s*; \$([0-9A-F]{2})", line)
            if m:
                values[m.group(1)] = int(m.group(2), 16)
    return values


ITEMS = _items()
HELD = [name for name, value in sorted(ITEMS.items(), key=lambda kv: kv[1]) if ITEMS["BLACK_BELT"] <= value < 0xC4]
TAKE_ITEM_MENU_ENTRY = 10


def _hram(name):
    with open(os.path.join(REPO_ROOT, "hram.asm")) as f:
        for line in f:
            m = re.match(rf"{name}\s+EQU\s+\$([0-9A-Fa-f]+)", line)
            if m:
                return int(m.group(1), 16)
    raise KeyError(name)


H_ITEM_PRICE = _hram("hItemPrice")


def text(name):
    out = []
    i = 0
    while i < len(name):
        c = name[i]
        out.append(0x7F if c == " " else 0xE8 if c == "." else 0xE0 if c == "'" else 0x80 + ord(c) - ord("A"))
        i += 1
    return out


def item_names():
    with open(os.path.join(REPO_ROOT, "text", "item_names.asm")) as f:
        return re.findall(r'db "([^"]*)@"', f.read())


class ItemDataTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_ids(self):
        self.assertEqual(ITEMS["ZINC"], 0x62)  # Gen 2's vitamin, just before them
        self.assertEqual(ITEMS[HELD[0]], 0x63)
        self.assertEqual(len(HELD), 52)  # with the new types' Metal Coat, BlackGlasses, Fairy Feather
        self.assertEqual(ITEMS[HELD[-1]], 0x63 + 51)

    def test_names(self):
        g = self.game
        names = item_names()
        names = names[names.index("ZINC") + 1:]  # the held items' names follow Zinc's
        self.assertEqual(len(names), len(HELD))
        for item, name in zip(HELD, names):
            with self.subTest(item=item):
                g.reset()
                g.poke("wd11e", ITEMS[item])
                g.call("GetItemName")
                self.assertEqual(g.peek("wcd6d", len(name) + 1), text(name.upper()) + [TERMINATOR])
                self.assertLessEqual(len(name), 12)

    def test_not_key_items(self):
        g = self.game
        for item, key in (("LEFTOVERS", 0), ("FOCUS_SASH", 0), ("CHARCOAL", 0), ("BICYCLE", 1), ("POTION", 0),
                          ("SUPER_ROD", 1), ("MAX_ELIXER", 0)):
            with self.subTest(item=item):
                g.reset()
                g.poke("wcf91", ITEMS[item])
                g.call("IsKeyItem_")
                self.assertEqual(g.peek("wIsKeyItem"), key)

    def test_prices(self):
        g = self.game
        for item, price in (("CHARCOAL", 3000), ("BERRY", 200), ("LEFTOVERS", 200), ("POTION", 300)):
            with self.subTest(item=item):
                g.reset()
                g.poke("wcf91", ITEMS[item])
                g.poke("wListMenuID", 0)
                addr = g.addr("ItemPrices")
                g.poke("wItemPrices", addr & 0xFF, addr >> 8)
                g.call("GetItemPrice")
                bcd = g.peek(H_ITEM_PRICE, 3)
                self.assertEqual(int("".join(f"{b:02x}" for b in bcd)), price)


class HoldingTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def party(self, items=(0, 0)):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        species = [SPECIES["SNORLAX"], SPECIES["PIKACHU"]]
        g.poke("wPartyCount", 2, *species, 0xFF)
        for i, (s, item) in enumerate(zip(species, items)):
            mon = f"wPartyMon{i + 1}"
            g.poke(mon + "Species", s)
            g.poke16(mon + "HP", 50)
            g.poke16(mon + "MaxHP", 60)
            g.poke(mon + "Level", 20)
            g.poke(mon + "Status", 0)
            g.poke(mon + "CatchRate", item)
        nick = [0x80, 0x81, TERMINATOR] + [TERMINATOR] * 8
        g.poke("wPartyMonNicks", *(nick + nick))
        g.poke("wIsInBattle", 0)

    def bag(self, *entries):
        g = self.game
        flat = []
        for item, n in entries:
            flat += [ITEMS[item], n]
        g.poke("wNumBagItems", len(entries), *flat, 0xFF)

    def bag_contents(self):
        g = self.game
        n = g.peek("wNumBagItems")
        raw = g.peek(g.addr("wNumBagItems") + 1, 2 * n)
        return {raw[i]: raw[i + 1] for i in range(0, 2 * n, 2)}

    def give(self, slot, mon):
        g = self.game
        g.poke("wWhichPokemon", slot)
        g.poke("wcf91", g.peek(g.addr("wNumBagItems") + 1 + 2 * slot))
        g.menu_choices(mon)
        g.call("UseItem_", max_frames=4000)

    def test_give(self):
        g = self.game
        self.party()
        self.bag(("POTION", 3), ("LEFTOVERS", 1))
        self.give(1, 1)
        self.assertEqual(g.peek("wPartyMon2CatchRate"), ITEMS["LEFTOVERS"])
        self.assertEqual(self.bag_contents(), {ITEMS["POTION"]: 3})

    def test_give_swaps(self):
        g = self.game
        self.party(items=(ITEMS["CHARCOAL"], 0))
        self.bag(("SITRUS_BERRY", 2))
        self.give(0, 0)
        self.assertEqual(g.peek("wPartyMon1CatchRate"), ITEMS["SITRUS_BERRY"])
        self.assertEqual(self.bag_contents(), {ITEMS["SITRUS_BERRY"]: 1, ITEMS["CHARCOAL"]: 1})

    def test_no_giving_in_battle(self):
        g = self.game
        self.party()
        self.bag(("LEFTOVERS", 1))
        g.poke("wIsInBattle", 1)
        g.poke("wWhichPokemon", 0)
        g.poke("wcf91", ITEMS["LEFTOVERS"])
        g.call("UseItem_", max_frames=4000)
        self.assertEqual(self.bag_contents(), {ITEMS["LEFTOVERS"]: 1})
        self.assertEqual(g.peek("wPartyMon1CatchRate"), 0)

    def test_take(self):
        g = self.game
        self.party(items=(0, ITEMS["QUICK_CLAW"]))
        self.bag(("POTION", 1))
        g.poke("wWhichPokemon", 1)
        g.call("TakeHeldItem", max_frames=4000)
        self.assertEqual(g.peek("wPartyMon2CatchRate"), 0)
        self.assertEqual(self.bag_contents(), {ITEMS["POTION"]: 1, ITEMS["QUICK_CLAW"]: 1})

    def test_take_with_a_full_bag(self):
        g = self.game
        self.party(items=(ITEMS["LEFTOVERS"], 0))
        full = [(name, 1) for name in HELD[:20]]  # 20 kinds: the bag's limit
        self.bag(*full)
        g.poke("wWhichPokemon", 0)
        g.call("TakeHeldItem", max_frames=4000)
        self.assertEqual(g.peek("wPartyMon1CatchRate"), ITEMS["LEFTOVERS"])

    def test_take_is_on_the_menu_when_holding(self):
        g = self.game
        for item, listed in ((ITEMS["LEFTOVERS"], True), (0, False)):
            with self.subTest(item=item):
                self.party(items=(item, 0))
                g.poke("wPartyMon1Moves", 1, 0, 0, 0)  # POUND: no field moves
                g.poke("wWhichPokemon", 0)
                g.poke("wFieldMoves", 0, 0, 0, 0, 0, 0, 12)
                g.call("GetMonFieldMoves")
                self.assertEqual(g.peek("wNumFieldMoves"), 1 if listed else 0)
                if listed:
                    self.assertEqual(g.peek("wFieldMoves"), TAKE_ITEM_MENU_ENTRY)


class BattleItemTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_enemy_item(self):
        g = self.game
        for in_battle, expected in ((2, ITEMS["KINGS_ROCK"]), (1, 0)):
            with self.subTest(in_battle=in_battle):
                g.reset()
                g.poke("wIsInBattle", in_battle)
                g.poke("wWhichPokemon", 2)
                g.poke("wEnemyMon3CatchRate", ITEMS["KINGS_ROCK"])
                de = g.addr("wEnemyMonCatchRate")
                g.poke(de, 0x77)
                out = g.call("GetEnemyHeldItem", de=de)
                self.assertEqual(out["de"], de)
                self.assertEqual(g.peek(de), expected)

    def test_new_mons_hold_nothing(self):
        g = self.game
        g.reset()
        g.poke("wPartyCount", 0, 0xFF)
        g.poke("wcf91", SPECIES["SNORLAX"])
        g.poke("wCurEnemyLVL", 30)
        g.poke("wMonDataLocation", 0)
        g.poke("wIsInBattle", 0)
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.menu_choices(1)  # no nickname
        g.call("_AddPartyMon", max_frames=4000)
        self.assertEqual(g.peek("wPartyCount"), 1)
        self.assertEqual(g.peek("wPartyMon1CatchRate"), 0)  # not Snorlax's catch rate (25)

    def test_transform_keeps_the_users_item(self):
        g = self.game
        from suites import move_execution as mx
        import random
        from suites.apply_attack import H_WHOSETURN
        for turn in (0, 1):
            with self.subTest(turn=turn):
                g.reset()
                mx.setup(g, random.Random(4))
                g.clear_random()
                g.queue_random(*[0] * 16)
                user, target = (("wBattleMon", "wEnemyMon"), ("wEnemyMon", "wBattleMon"))[turn]
                g.poke(user + "CatchRate", ITEMS["LEFTOVERS"])
                g.poke(target + "CatchRate", ITEMS["CHARCOAL"])
                for i in (1, 2, 3):
                    g.poke(f"wPlayerBattleStatus{i}", 0)
                    g.poke(f"wEnemyBattleStatus{i}", 0)
                g.poke(H_WHOSETURN, turn)
                g.call("TransformEffect", max_frames=4000)
                self.assertEqual(g.peek(user + "Species"), g.peek(target + "Species"))
                self.assertEqual(g.peek(user + "CatchRate"), ITEMS["LEFTOVERS"])

    def test_status_screen(self):
        g = self.game
        tilemap = g.addr("wTileMap")
        for item, name in (("FOCUS_SASH", "FOCUS SASH"), ("KINGS_ROCK", "KING'S ROCK")):
            with self.subTest(item=item):
                g.reset()
                g.poke(tilemap, *[0x7F] * 360)
                g.poke("wLoadedMonCatchRate", ITEMS[item])
                g.call("PrintStatusScreenHeldItem")
                expected = text(name)
                self.assertEqual(g.peek(tilemap + 2 * 20 + 8, len(expected)), expected)
        g.reset()
        g.poke(tilemap, *[0x7F] * 360)
        g.poke("wLoadedMonCatchRate", 0)
        g.call("PrintStatusScreenHeldItem")
        self.assertEqual(g.peek(tilemap + 2 * 20 + 8, 12), [0x7F] * 12)


class NuzlockeTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_dead_mark_is_an_iv_flag(self):
        g = self.game
        g.reset()
        g.poke("wUnusedD721", 1 << 6)  # nuzlocke on
        g.poke("wPartyMon2CatchRate", ITEMS["LEFTOVERS"])
        for flags, dead in ((0x54 | NUZLOCKE_DEAD, True), (0x55, False), (0x57, True)):
            with self.subTest(flags=flags):
                g.poke("wPartyMon2IVs", 0x12, 0x34, 0x56, flags)
                g.poke("wUsedItemOnWhichPokemon", 1)
                self.assertEqual(g.call("IsPartyMonDead")["z"], dead)

    def test_one_hp_dead_mons(self):
        g = self.game
        g.reset()
        g.poke("wPartyCount", 2)
        g.poke("wPartyMon1IVs", 0, 0, 0, NUZLOCKE_DEAD)
        g.poke("wPartyMon2IVs", 0, 0, 0, 0)
        g.poke16("wPartyMon1HP", 0)
        g.poke16("wPartyMon2HP", 0)
        g.call("OneHPDeadMons")
        self.assertEqual((g.peek16("wPartyMon1HP"), g.peek16("wPartyMon2HP")), (1, 0))


if __name__ == "__main__":
    unittest.main()
