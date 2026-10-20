"""A gift mon (the starters, and every mon AddPartyMon makes outside battle)
starts at full HP. PackIVs used to clobber de, so AddPartyMon worked out the
current HP from the wrong IVs and the starter came 1-2 HP short."""

import unittest

from harness import shared_game
from suites.apply_attack import _constants

SPECIES = _constants("pokemon_constants.asm", ["BULBASAUR", "CHARMANDER", "SQUIRTLE", "EEVEE"])


class GiftMonTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_full_hp(self):
        g = self.game
        for name, species in SPECIES.items():
            for seed in range(4):
                with self.subTest(species=name, seed=seed):
                    g.reset()
                    g.skip_delays()
                    g.skip_sound_waits()
                    g.auto_buttons()
                    g.poke("wPartyCount", 0)
                    g.poke("wPartySpecies", 0xFF)
                    g.poke("wIsInBattle", 0)
                    g.poke("wMonDataLocation", 0)
                    g.poke("wCurEnemyLVL", 5 + seed * 10)
                    g.poke("wcf91", species)
                    g.poke("wd11e", species)
                    g.queue_random(*[(seed * 37 + i * 11) & 0xFF for i in range(64)])
                    g.call("AddPartyMon", max_frames=20000)
                    self.assertEqual(g.peek16("wPartyMon1HP"), g.peek16("wPartyMon1MaxHP"))

    def test_pack_ivs_keeps_de(self):
        g = self.game
        g.reset()
        out = g.call("PackIVs", a=0, de=0x1234, hl=g.addr("wPartyMon1IVs"))
        self.assertEqual(out["de"], 0x1234)
