"""Spec tests for the PC boxes, the day care and saving.

These pin down what step D (moving the current box to save RAM) must keep:
depositing and withdrawing, full boxes and parties, catching with a full
party, changing boxes, the day care, and saving and loading with checksums.
They read and write the box only through tests/boxes.py.
"""

import random
import unittest

import boxes as bx
from harness import shared_game
from suites.damage_vars import SPECIES

SEEDS = range(12)


class BoxTestCase(unittest.TestCase):
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
        return rng, party, box

    def move_mon(self, move_type, which, species):
        """What the PC and day care do: MoveMon, then RemovePokemon on the source.
        Returns True if MoveMon refused (destination full)."""
        g = self.game
        g.poke("wWhichPokemon", which)
        g.poke("wcf91", species)
        g.poke("wMoveMonType", move_type)
        if g.call("MoveMon")["carry"]:
            return True
        if move_type != bx.DAYCARE_TO_PARTY:
            g.poke("wRemoveMonFromBox", 1 if move_type == bx.BOX_TO_PARTY else 0)
            g.call("RemovePokemon")
        return False


class DepositWithdrawTest(BoxTestCase):
    def test_deposit_appends_to_box(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, random.Random(seed).randint(2, 6), seed % 20)
                which = rng.randrange(len(party))
                mon = party[which]
                self.assertFalse(self.move_mon(bx.PARTY_TO_BOX, which, mon["species"]))

                expected = list(mon["data"][:bx.BOX_STRUCT_LEN])
                expected[bx.BOX_LEVEL] = mon["data"][bx.LEVEL]  # the box keeps the party level here
                after = bx.read_current_box(self.game)
                self.assertEqual(after[:-1], box)
                self.assertEqual(after[-1], {"species": mon["species"], "data": expected,
                                             "ot": mon["ot"], "nick": mon["nick"]})
                self.assertEqual(bx.read_party(self.game), party[:which] + party[which + 1:])

    def test_withdraw_appends_to_party(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, seed % 6, 1 + seed % 20)
                which = rng.randrange(len(box))
                mon = box[which]
                self.assertFalse(self.move_mon(bx.BOX_TO_PARTY, which, mon["species"]))

                after = bx.read_party(self.game)
                self.assertEqual(after[:-1], party)
                new = after[-1]
                self.assertEqual((new["species"], new["ot"], new["nick"]),
                                 (mon["species"], mon["ot"], mon["nick"]))
                # the box data comes across unchanged; level and stats are recalculated
                self.assertEqual(new["data"][:bx.BOX_STRUCT_LEN], mon["data"])
                self.assertTrue(1 <= new["data"][bx.LEVEL] <= 100)
                self.assertNotEqual(new["data"][bx.STATS:bx.STATS + 10], [0] * 10)
                self.assertEqual(bx.read_current_box(self.game), box[:which] + box[which + 1:])

    def test_deposit_then_withdraw_keeps_the_mon(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, 2 + seed % 5, seed % 19)
                which = rng.randrange(len(party))
                mon = party[which]
                self.move_mon(bx.PARTY_TO_BOX, which, mon["species"])
                self.move_mon(bx.BOX_TO_PARTY, len(box), mon["species"])
                back = bx.read_party(self.game)[-1]
                for name, (start, end) in {"species/HP": (0, 3), "status/types/catch rate/moves/OT ID": (4, 0x0E),
                                           "stat exp/DVs/PP": (0x11, bx.BOX_STRUCT_LEN)}.items():
                    self.assertEqual(back["data"][start:end], mon["data"][start:end], name)
                self.assertEqual((back["ot"], back["nick"]), (mon["ot"], mon["nick"]))
                self.assertEqual(bx.read_current_box(self.game), box)

    def test_full_box_refuses_deposit(self):
        for seed in SEEDS[:4]:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, 3, bx.MONS_PER_BOX)
                self.assertTrue(self.move_mon(bx.PARTY_TO_BOX, 0, party[0]["species"]))
                self.assertEqual(bx.read_current_box(self.game), box)
                self.assertEqual(bx.read_party(self.game), party)

    def test_full_party_refuses_withdraw(self):
        for seed in SEEDS[:4]:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, bx.PARTY_LENGTH, 5)
                self.assertTrue(self.move_mon(bx.BOX_TO_PARTY, 0, box[0]["species"]))
                self.assertEqual(bx.read_current_box(self.game), box)
                self.assertEqual(bx.read_party(self.game), party)


class CatchTest(BoxTestCase):
    def test_caught_mon_goes_to_front_of_box_when_party_is_full(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, bx.PARTY_LENGTH, seed % 19)
                g = self.game
                species = rng.choice(SPECIES)
                level = rng.randint(2, 100)
                moves = [rng.randint(1, 165) for _ in range(4)]
                dvs = [rng.randint(0, 255), rng.randint(0, 255)]
                g.poke("wcf91", species)
                g.poke("wEnemyMonSpecies", species)
                g.poke("wEnemyMonLevel", level)
                g.poke("wEnemyMonMoves", *moves)
                g.poke("wEnemyMonDVs", *dvs)
                g.menu_choices(1)  # "Give it a nickname?" no
                g.call("SendNewMonToBox", max_frames=600)

                after = bx.read_current_box(g)
                self.assertEqual(len(after), len(box) + 1)
                caught = after[0]
                self.assertEqual(caught["species"], species)
                self.assertEqual(caught["data"][bx.BOX_LEVEL], level)
                self.assertEqual(caught["data"][bx.MOVES:bx.MOVES + 4], moves)
                self.assertEqual(caught["data"][bx.DVS:bx.DVS + 2], dvs)
                self.assertEqual(caught["ot"], g.peek("wPlayerName", bx.NAME_LENGTH))
                self.assertEqual(after[1:], box)
                self.assertEqual(bx.read_party(g), party)


class ChangeBoxTest(BoxTestCase):
    def change_box(self, number):
        self.game.menu_choices(0, number)  # yes, then the box
        self.game.call("ChangeBox", max_frames=2000)

    def test_first_change_saves_box_and_starts_others_empty(self):
        for seed in SEEDS[:6]:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, 3, 1 + seed % 20)
                self.game.poke("wCurrentBoxNum", 0)  # never changed boxes: bit 7 clear
                target = rng.randint(1, bx.NUM_BOXES - 1)
                self.change_box(target)
                self.assertEqual(bx.current_box_number(self.game), target)
                self.assertEqual(bx.read_current_box(self.game), [])
                self.assertEqual(bx.read_saved_box(self.game, 0), box)

    def test_changing_back_restores_each_box(self):
        for seed in SEEDS[:6]:
            with self.subTest(seed=seed):
                rng, party, first = self.fresh(seed, 3, 1 + seed % 20)
                self.game.poke("wCurrentBoxNum", 0)
                other = rng.randint(1, bx.NUM_BOXES - 1)
                self.change_box(other)
                second = [bx.random_mon(rng, SPECIES, party=False) for _ in range(1 + rng.randrange(20))]
                bx.write_current_box(self.game, second)

                self.change_box(0)
                self.assertEqual(bx.read_current_box(self.game), first)
                self.assertEqual(bx.read_saved_box(self.game, other), second)
                self.change_box(other)
                self.assertEqual(bx.read_current_box(self.game), second)
                self.assertEqual(bx.read_saved_box(self.game, 0), first)


class DayCareTest(BoxTestCase):
    def test_day_care_round_trip(self):
        for seed in SEEDS:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, 2 + seed % 5, 0)
                which = rng.randrange(len(party))
                mon = party[which]
                self.assertFalse(self.move_mon(bx.PARTY_TO_DAYCARE, which, mon["species"]))
                self.game.poke("wDayCareInUse", 1)

                expected = list(mon["data"][:bx.BOX_STRUCT_LEN])
                expected[bx.BOX_LEVEL] = mon["data"][bx.LEVEL]
                self.assertEqual(bx.read_day_care(self.game), {"species": mon["species"], "data": expected,
                                                                "ot": mon["ot"], "nick": mon["nick"]})
                self.assertEqual(bx.read_party(self.game), party[:which] + party[which + 1:])

                self.assertFalse(self.move_mon(bx.DAYCARE_TO_PARTY, 0, mon["species"]))
                back = bx.read_party(self.game)[-1]
                self.assertEqual((back["species"], back["ot"], back["nick"]),
                                 (mon["species"], mon["ot"], mon["nick"]))
                self.assertEqual(back["data"][:bx.BOX_STRUCT_LEN], expected)


class SaveTest(BoxTestCase):
    def save(self):
        self.game.call("SaveSAVtoSRAM", max_frames=2000)

    def load(self):
        self.game.call("LoadSAV", max_frames=2000)
        return self.game.peek("wSaveFileStatus")

    def test_save_and_load_restore_party_box_and_day_care(self):
        for seed in SEEDS[:6]:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, 1 + seed % 6, seed % 21)
                g = self.game
                day_care = bx.random_mon(rng, SPECIES, party=False)
                g.poke("wDayCareInUse", 1)
                g.poke("wDayCareMon", *day_care["data"])
                g.poke("wDayCareMonOT", *day_care["ot"])
                g.poke("wDayCareMonName", *day_care["nick"])
                self.save()

                # scramble what was saved, then load it back
                bx.write_party(g, [bx.random_mon(rng, SPECIES) for _ in range(2)])
                bx.write_current_box(g, [bx.random_mon(rng, SPECIES, party=False)])
                g.poke("wDayCareMon", *[0] * bx.BOX_STRUCT_LEN)
                self.assertEqual(self.load(), 2, "checksum should be good")
                self.assertEqual(bx.read_party(g), party)
                self.assertEqual(bx.read_current_box(g), box)
                self.assertEqual(bx.read_day_care(g), day_care)

    def test_corrupt_current_box_is_detected(self):
        for seed in SEEDS[:6]:
            with self.subTest(seed=seed):
                rng, party, box = self.fresh(seed, 2, 1 + seed % 20)
                self.save()
                bank, addr = self.game.symbols["sCurBoxData"]
                offset = rng.randrange(1 + 21 + len(box) * bx.BOX_STRUCT_LEN)
                self.game.memory[bank, addr + offset] ^= 0x01
                self.assertEqual(self.load(), 1, "a changed box byte should fail the checksum")


if __name__ == "__main__":
    unittest.main()
