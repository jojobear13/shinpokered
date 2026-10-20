"""The extra options' SPRITES: GEN 2 (engine/gen2_pics.asm). With it on,
GetMonHeader takes each species' front and back pics, their size and bank
from Gen2PicHeaders (Crystal's, from pret's pokecrystal); with it off, from
the base stats as before. NEW GAME+ keeps the option."""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game
from test_moves_screen import SPECIES

with open(os.path.join(REPO_ROOT, "constants", "pokedex_constants.asm")) as f:
    DEX = {m.group(1): int(m.group(2)) for m in re.finditer(r"const DEX_(\w+)\s*; (\d+)", f.read())}
PRET = {"NIDORAN_F": "nidoran_f", "NIDORAN_M": "nidoran_m", "FARFETCHD": "farfetch_d", "MR_MIME": "mr__mime"}


def label(name):
    return "Gen2" + "".join(p.title() for p in PRET.get(name, name.lower()).split("_") if p)


class Gen2SpritesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        self.game.reset()

    def header(self, species):
        g = self.game
        g.poke("wd0b5", species)
        g.call("GetMonHeader", max_frames=100)
        pointers = g.peek("wMonHFrontSprite", 4)  # little-endian
        return (g.peek("wMonHSpriteDim"), pointers[0] | pointers[1] << 8, pointers[2] | pointers[3] << 8,
                g.peek("wMonHPicBank"))

    def test_every_species(self):
        g = self.game
        for name, n in DEX.items():
            with self.subTest(name=name):
                g.poke("wDisplayOptions", 0)
                dim, front, back, bank = self.header(SPECIES[name])
                g.poke("wDisplayOptions", 1)
                dim2, front2, back2, bank2 = self.header(SPECIES[name])
                fbank, faddr = g.symbols[label(name) + "Front"]
                bbank, baddr = g.symbols[label(name) + "Back"]
                self.assertEqual((front2, back2, bank2), (faddr, baddr, fbank))
                self.assertEqual(bbank, fbank)  # one bank for both
                size = {0x55: 40, 0x66: 48, 0x77: 56}[dim2]
                pic = os.path.join(REPO_ROOT, "pic", "gen2mon", PRET.get(name, name.lower()) + ".pic")
                with open(pic, "rb") as f:
                    self.assertEqual(f.read(1)[0], dim2)
                self.assertIn(size, (40, 48, 56))
                self.assertNotEqual((front, back), (front2, back2))  # Gen 1's otherwise

    def test_special_pics_stay(self):
        g = self.game
        ghost = SPECIES["MON_GHOST"] if "MON_GHOST" in SPECIES else 0xB8
        g.poke("wDisplayOptions", 0)
        off = self.header(ghost)[:2]
        g.poke("wDisplayOptions", 1)
        self.assertEqual(self.header(ghost)[:2], off)

    def test_new_game_plus_keeps_it(self):
        g = self.game
        g.poke("wDisplayOptions", 1)
        g.call("DoNewGamePlus", max_frames=2000)
        self.assertEqual(g.peek("wDisplayOptions"), 1)


if __name__ == "__main__":
    unittest.main()
