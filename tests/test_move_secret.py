"""Shin's secret: a Pikachu that wins the S.S. Anne tournament can learn SURF,
and a Dragonite that leads against Lance can learn FLY. Shin marked the mon
with catch rate 168, a byte that is now the held item, so the feats are event
flags (EVENT_SURFING_PIKACHU, EVENT_FLYING_DRAGONITE) and CanLearnTM honours
them for the species."""

import unittest

from harness import shared_game
from test_moves_screen import SPECIES
from suites.apply_attack import _constants

MOVES = _constants("move_constants.asm", ["SURF", "FLY"])

SURFING_PIKACHU, FLYING_DRAGONITE = 0x8CF, 0x8D0


class MoveSecretTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def can_learn(self, species, move, event=None):
        g = self.game
        g.reset()
        byte = 0x8CF // 8
        g.poke(f"wEventFlags+{byte}", 0)
        g.poke(f"wEventFlags+{byte + 1}", 0)
        if event is not None:
            g.poke(f"wEventFlags+{event // 8}", 1 << event % 8)
        g.poke("wcf91", SPECIES[species])
        g.poke("wMoveNum", MOVES[move])
        return g.call("CanLearnTM", max_frames=100)["c"] != 0

    def test_pikachu_surf(self):
        self.assertFalse(self.can_learn("PIKACHU", "SURF"))
        self.assertTrue(self.can_learn("PIKACHU", "SURF", SURFING_PIKACHU))
        self.assertFalse(self.can_learn("PIKACHU", "SURF", FLYING_DRAGONITE))

    def test_dragonite_fly(self):
        self.assertFalse(self.can_learn("DRAGONITE", "FLY"))
        self.assertTrue(self.can_learn("DRAGONITE", "FLY", FLYING_DRAGONITE))

    def test_others_unchanged(self):
        self.assertFalse(self.can_learn("RAICHU", "FLY", FLYING_DRAGONITE))
        self.assertTrue(self.can_learn("LAPRAS", "SURF"))


if __name__ == "__main__":
    unittest.main()
