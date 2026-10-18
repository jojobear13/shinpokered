"""Spec tests that drive Bill's PC through its own menus.

test_pc_boxes.py calls the box routines directly. These go through the PC's
menus instead, so they also cover the list menu, which reads the current box
from save RAM (the count and species through a WRAM copy, the nicknames
directly; design brief, step D).
"""

import random
import unittest

import boxes as bx
from harness import shared_game
from suites.damage_vars import SPECIES

SEEDS = range(6)

WITHDRAW, DEPOSIT, RELEASE, SEE_YA = 0, 1, 2, 4
FIRST_ITEM = 0  # WITHDRAW/DEPOSIT in the submenu after picking a mon; YES in a yes/no box


def name(nick):
    """A name up to and including its terminator."""
    return nick[:nick.index(bx.TERMINATOR) + 1]


class PCMenuTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def fresh(self, seed, party_size, box_size):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        rng = random.Random(seed)
        party = [bx.random_mon(rng, SPECIES, party=True) for _ in range(party_size)]
        box = [bx.random_mon(rng, SPECIES, party=False) for _ in range(box_size)]
        bx.write_party(g, party)
        bx.write_current_box(g, box)
        # as if reached through another PC: no switch-on text or sound
        g.poke("wFlags_0xcd60", g.peek("wFlags_0xcd60") | 1 << 3)
        return rng, party, box

    def use_pc(self, *choices):
        self.game.menu_choices(*choices, SEE_YA)
        self.game.call("BillsPC_", max_frames=4000)

    def test_withdraw(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, 1 + seed % 5, 1 + seed * 3)
                which = rng.randrange(len(box))
                self.use_pc(WITHDRAW, which, FIRST_ITEM)
                after = bx.read_party(self.game)
                self.assertEqual(after[:-1], party)
                self.assertEqual((after[-1]["species"], after[-1]["nick"]),
                                 (box[which]["species"], box[which]["nick"]))
                self.assertEqual(bx.read_current_box(self.game), box[:which] + box[which + 1:])
                # the list menu copies the chosen entry's name to wcf4b
                nick = name(box[which]["nick"])
                self.assertEqual(self.game.peek("wcf4b", len(nick)), nick)

    def test_deposit(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, 2 + seed % 5, seed * 3)
                which = rng.randrange(len(party))
                self.use_pc(DEPOSIT, which, FIRST_ITEM)
                after = bx.read_current_box(self.game)
                self.assertEqual(after[:-1], box)
                self.assertEqual((after[-1]["species"], after[-1]["nick"]),
                                 (party[which]["species"], party[which]["nick"]))
                self.assertEqual(bx.read_party(self.game), party[:which] + party[which + 1:])

    def test_release(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, 3, 1 + seed * 3)
                which = rng.randrange(len(box))
                self.use_pc(RELEASE, which, FIRST_ITEM)
                self.assertEqual(bx.read_current_box(self.game), box[:which] + box[which + 1:])
                self.assertEqual(bx.read_party(self.game), party)
                nick = name(box[which]["nick"])
                self.assertEqual(self.game.peek("wcf4b", len(nick)), nick)


if __name__ == "__main__":
    unittest.main()
