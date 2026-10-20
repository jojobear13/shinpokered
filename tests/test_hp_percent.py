"""The DISPLAY option HP PERCENT (engine/battle/hp_percent.asm): the enemy's
HP as a percentage, rounded down but at least 1 while it has HP, drawn in
two tiles in place of the HUD's "HP:"."""

import unittest

from harness import shared_game


class HPPercentTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def percent(self, hp, max_hp):
        g = self.game
        g.reset()
        g.poke16("wEnemyMonHP", hp)
        g.poke16("wEnemyMonMaxHP", max_hp)
        return g.call("EnemyHPPercent")["a"]

    def test_values(self):
        for hp, max_hp in ((100, 100), (50, 100), (1, 100), (0, 100), (1, 999), (999, 999),
                           (500, 999), (37, 60), (255, 256), (256, 300)):
            expected = hp * 100 // max_hp if hp else 0
            got = self.percent(hp, max_hp)
            if hp:
                self.assertGreaterEqual(got, 1)
            # max HP over 255 is scaled to one byte first: within 2 points
            self.assertLessEqual(abs(got - max(expected, 1 if hp else 0)), 2, (hp, max_hp, got))
        self.assertEqual(self.percent(100, 100), 100)
        self.assertEqual(self.percent(0, 100), 0)

    def test_hud_tiles(self):
        g = self.game
        g.reset()
        g.poke("wDisplayOptions", 1 << 3)
        g.poke16("wEnemyMonHP", 73)
        g.poke16("wEnemyMonMaxHP", 100)
        tiles = g.addr("wTileMap") + 2 * 20 + 2
        g.poke(0xFF40, g.peek(0xFF40) & 0x7F)  # LCD off: the tiles go to VRAM at once
        out = g.call("DrawEnemyHPPercent", de=0x1234, max_frames=100)
        self.assertEqual(out["de"], 0x1234)  # the bar's pixels, for its color
        self.assertEqual(g.peek(tiles, 2), [0xD0, 0xD1])
        # "73%": the second tile's ones digit is a 3, then the % sign, and the
        # bar's left end in its last column on rows 3 and 4
        rows = g.peek("wHPPercentTiles", 32)
        second = rows[16::2]
        self.assertEqual(second[1] >> 5, 0b111)  # 3's top row
        self.assertEqual(second[3] & 1, 1)
        self.assertEqual(second[0], 0)

    def test_off(self):
        g = self.game
        g.reset()
        g.poke("wDisplayOptions", 0)
        tiles = g.addr("wTileMap") + 2 * 20 + 2
        g.poke(tiles, 0x71, 0x62)
        g.call("DrawEnemyHPPercent")
        self.assertEqual(g.peek(tiles, 2), [0x71, 0x62])


if __name__ == "__main__":
    unittest.main()
