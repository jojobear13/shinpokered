"""EXTRAS > PC IN MENU: the start menu gets a PC item, after ITEM, that opens
the PC as a Pokémon Center's does (engine/menu/draw_start_menu.asm). The
item count, the wrap-around and EXIT's softlock check follow wMaxMenuItem."""

import unittest

from harness import shared_game

GOT_POKEDEX = 0x025
PC_IN_MENU = 0x8CC

# StartMenuChoice's actions: 0 POKéDEX, 1 POKéMON, 2 ITEM, 3 the player,
# 4 SAVE, 5 OPTION, 6 EXIT (the PC itself runs inside it)
NAMES = ["POKEDEX", "POKEMON", "ITEM", "PLAYER", "SAVE", "OPTION", "EXIT"]


class StartMenuPCTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setup(self, pokedex, pc):
        g = self.game
        g.reset()
        for event, on in ((GOT_POKEDEX, pokedex), (PC_IN_MENU, pc)):
            address = f"wEventFlags+{event // 8}"
            value = g.peek(address) & ~(1 << event % 8)
            g.poke(address, value | (on << event % 8))
        g.poke("wd72e", g.peek("wd72e") & ~0x40)  # not in a link room

    def choices(self):
        """What each item does, by StartMenuChoice; the PC (which it would
        run) is the item after ITEM when StartMenuHasPC says nz."""
        g = self.game
        count = g.call("StartMenuItemCount")["a"]
        has_pc = not g.call("StartMenuHasPC")["f"] & 0x80
        pokedex = g.peek(f"wEventFlags+{GOT_POKEDEX // 8}") >> GOT_POKEDEX % 8 & 1
        out = []
        for item in range(count):
            if has_pc and item == 2 + pokedex:
                out.append("PC")
                continue
            g.poke("wCurrentMenuItem", item)
            out.append(NAMES[g.call("StartMenuChoice")["de"] & 0xFF])
        return out

    def test_menus(self):
        expect = {
            (0, 0): ["POKEMON", "ITEM", "PLAYER", "SAVE", "OPTION", "EXIT"],
            (1, 0): ["POKEDEX", "POKEMON", "ITEM", "PLAYER", "SAVE", "OPTION", "EXIT"],
            (0, 1): ["POKEMON", "ITEM", "PC", "PLAYER", "SAVE", "OPTION", "EXIT"],
            (1, 1): ["POKEDEX", "POKEMON", "ITEM", "PC", "PLAYER", "SAVE", "OPTION", "EXIT"],
        }
        for (dex, pc), items in expect.items():
            self.setup(dex, pc)
            self.assertEqual(self.choices(), items, (dex, pc))

    def test_not_in_link_rooms(self):
        g = self.game
        self.setup(1, 1)
        g.poke("wd72e", g.peek("wd72e") | 0x40)
        self.assertEqual(g.call("StartMenuItemCount")["a"], 7)


if __name__ == "__main__":
    unittest.main()
