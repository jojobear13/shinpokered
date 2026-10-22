"""The type matchups the player has seen (engine/battle/type_chart.asm) and
the DISPLAY option TYPE HINT: OFF, ON, or LEARNED. A matchup is an attacking
type against a defending type, one way; an attacking move with ordinary
damage records its type against each of its target's types, whichever side
used it. Status moves record nothing; fixed-damage moves (power 1, like
Dragon Rage) record their matchups too."""

import unittest

from harness import shared_game
from test_held_items import _hram

H_WHOSETURN = _hram("H_WHOSETURN")
FIGHTING, POISON, FIRE, WATER, GRASS = 0x01, 0x03, 0x14, 0x15, 0x16
EMBER, GROWL = 0x34, 0x2D
FIRE_SPECIAL_DAMAGE = 0  # not SUPER_FANG_EFFECT nor SPECIAL_DAMAGE_EFFECT
HINT_ON, HINT_LEARNED = 0b010, 0b100
QUESTION, UP = 0xE6, 0xE9


def index(t):
    return t if t < FIRE else t - FIRE + 10


class TypeChartTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        g.poke("wTypeChartSeen", *[0] * 46)

    def seen(self, attacker, defender):
        n = index(attacker) * 19 + index(defender)
        return bool(self.game.peek(f"wTypeChartSeen+{n // 8}") >> n % 8 & 1)

    def attack(self, turn, power, move_type, target_types):
        g = self.game
        g.poke(H_WHOSETURN, turn)
        if turn == 0:
            g.poke("wPlayerMovePower", power)
            g.poke("wPlayerMoveType", move_type)
            g.poke("wEnemyMonType", *target_types)
        else:
            g.poke("wEnemyMovePower", power)
            g.poke("wEnemyMoveType", move_type)
            g.poke("wBattleMonType", *target_types)
        g.call("RecordTypeMatchup", de=0x1234)

    def test_dual_type_counts_both(self):
        self.attack(0, 40, FIRE, (GRASS, POISON))
        self.assertTrue(self.seen(FIRE, GRASS))
        self.assertTrue(self.seen(FIRE, POISON))
        self.assertFalse(self.seen(GRASS, FIRE))  # one way only
        self.assertFalse(self.seen(FIRE, WATER))

    def test_either_side(self):
        self.attack(1, 40, WATER, (FIRE, FIRE))
        self.assertTrue(self.seen(WATER, FIRE))
        self.assertFalse(self.seen(FIRE, WATER))

    def test_status_moves_dont_count(self):
        self.attack(0, 0, FIRE, (GRASS, GRASS))  # a status move
        self.assertFalse(self.seen(FIRE, GRASS))

    def test_fixed_damage_counts(self):
        self.attack(0, 1, FIGHTING, (GRASS, GRASS))  # Seismic Toss
        self.assertTrue(self.seen(FIGHTING, GRASS))

    def test_every_matchup_has_its_own_bit(self):
        g = self.game
        types = [t for t in list(range(0x0A)) + list(range(FIRE, 0x1D))]
        seen = set()
        for a in types:
            for d in types:
                hl = g.call("TypeMatchupBit", de=a << 8 | d)
                key = (hl["hl"], hl["a"])
                self.assertNotIn(key, seen)
                self.assertEqual(bin(hl["a"]).count("1"), 1)
                seen.add(key)
                self.assertLess(hl["hl"] - g.addr("wTypeChartSeen"), 46)
                self.assertEqual(hl["de"], a << 8 | d)

    def mark(self, mode, move=EMBER, move_type=FIRE, target=(GRASS, GRASS)):
        g = self.game
        g.poke("wDisplayOptions", mode)
        g.poke("wPlayerMoveNum", move)
        g.poke("wPlayerMoveType", move_type)
        g.poke("wPlayerMoveEffect", FIRE_SPECIAL_DAMAGE)
        g.poke("wEnemyMonType", *target)
        g.poke("wIsInBattle", 2)  # a trainer: no ghost check
        tiles = g.addr("wTileMap") + 9 * 20 + 8
        g.poke(tiles, 0x7F, 0x7F)
        g.call("PrintMoveCategoryAndEffectiveness", max_frames=100)
        return g.peek(tiles, 2)

    def test_hint_off_on(self):
        self.assertEqual(self.mark(0), [0x7F, 0x7F])
        self.assertEqual(self.mark(HINT_ON), [0x7F, UP])

    def test_hint_learned(self):
        self.assertEqual(self.mark(HINT_LEARNED), [0x7F, QUESTION])
        self.attack(1, 40, FIRE, (GRASS, GRASS))
        self.assertEqual(self.mark(HINT_LEARNED), [0x7F, UP])

    def test_learned_dual_type_needs_both(self):
        self.attack(0, 40, FIRE, (GRASS, GRASS))
        self.assertEqual(self.mark(HINT_LEARNED, target=(GRASS, POISON)), [0x7F, QUESTION])
        self.attack(0, 40, FIRE, (POISON, POISON))
        self.assertEqual(self.mark(HINT_LEARNED, target=(GRASS, POISON)), [0x7F, UP])

    def test_status_moves_get_no_mark(self):
        self.assertEqual(self.mark(HINT_ON, move=GROWL, move_type=0), [0x7F, 0x7F])


if __name__ == "__main__":
    unittest.main()
