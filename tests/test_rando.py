"""The randomizer's generator (engine/rando/) against its Python reference.

tools/rando/randomizer.py is the reference: for a seed, the Game Boy must
pair the same doors and place the same items, after the same number of
tries. Both layouts are checked (the international one and Red/Green JP),
as are the generated tables (data/rando/), which must be what
tools/rando/gen_data.py writes from the built ROMs.
"""

import os
import sys
import tempfile
import unittest

from harness import REPO_ROOT, Game

sys.path.insert(0, os.path.join(REPO_ROOT, "tools", "rando"))
import gen_data  # noqa: E402

SEEDS = [1, 2, 3, 0xDEADBEEF, 0x12345678]
LAYOUTS = [("pokered", "intl"), ("pokeredjp", "jp")]


def rom_path(label):
    return os.path.join(REPO_ROOT, label + ".gbc")


class GeneratorTestCase(unittest.TestCase):
    label = None

    @classmethod
    def setUpClass(cls):
        if not os.path.exists(rom_path(cls.label)):
            raise unittest.SkipTest(cls.label + ".gbc not built")
        cls.tables = gen_data.Tables(cls.label)
        cls.game = Game(rom_path(cls.label))

    def generate(self, seed):
        g = self.game
        g.reset()
        g.poke("sRandoTag", *seed.to_bytes(4, "little"), 0)
        regs = g.call("RandoGenerate", max_frames=100000)
        n = len(self.tables.slots)
        raw = g.peek("sRandoPartner", 2 * n)
        partners = [raw[2 * i] | raw[2 * i + 1] << 8 for i in range(n)]
        place = g.peek("sRandoPlace", len(self.tables.C.locs))
        tries = 256 - g.peek("sRandoTries")
        return regs, partners, place, tries

    def test_matches_reference(self):
        T = self.tables
        for seed in SEEDS:
            with self.subTest(seed=hex(seed)):
                regs, partners, place, tries = self.generate(seed)
                self.assertFalse(regs.get("carry"))
                self.assertEqual(self.game.peek("sRandoValid"), 1)
                py = T.Rz.generate(seed, max_tries=255)
                self.assertEqual(tries, py["tries"])
                self.assertEqual(partners, [T.slot_of[py["pairing"][e]] for e in T.slots])
                self.assertEqual(
                    place, [T.rom.items[py["placement"][l["key"]]] for l in T.C.locs]
                )

    def test_pairs_are_mutual(self):
        _, partners, _, _ = self.generate(7)
        for s, p in enumerate(partners):
            self.assertEqual(partners[p], s)

    def test_tables_up_to_date(self):
        base = "intl" if self.label == "pokered" else "jp"
        with tempfile.TemporaryDirectory() as d:
            self.tables.write(os.path.join(d, base), self.label)
            for name in sorted(os.listdir(d)):
                with open(os.path.join(d, name)) as new, open(
                    os.path.join(REPO_ROOT, "data", "rando", name)
                ) as old:
                    self.assertEqual(new.read(), old.read(), name)


class IntlGeneratorTest(GeneratorTestCase):
    label = "pokered"


class JPGeneratorTest(GeneratorTestCase):
    label = "pokeredjp"


del GeneratorTestCase

if __name__ == "__main__":
    unittest.main()
