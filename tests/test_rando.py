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
import randomizer  # noqa: E402

SEEDS = [1, 2, 3, 0xDEADBEEF, 0x12345678]
DOORS, KEYS, ITEMS = 1, 2, 4  # wRandoFlags
# what to shuffle -> the seeds to try it with
MODES = {
    DOORS | KEYS | ITEMS: SEEDS,
    DOORS | KEYS: SEEDS[:2],
    KEYS | ITEMS: SEEDS[:2],
    KEYS: SEEDS[:2],
    ITEMS: SEEDS[:2],
}
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

    def generate(self, seed, mode=DOORS | KEYS | ITEMS):
        g = self.game
        g.reset()
        g.poke("sRandoTag", *seed.to_bytes(4, "little"), mode)
        regs = g.call("RandoGenerate", max_frames=100000)
        n = len(self.tables.slots)
        raw = g.peek("sRandoPartner", 2 * n)
        partners = [raw[2 * i] | raw[2 * i + 1] << 8 for i in range(n)]
        place = g.peek("sRandoPlace", len(self.tables.C.locs))
        tries = 256 - g.peek("sRandoTries")
        return regs, partners, place, tries

    def test_matches_reference(self):
        for mode, seeds in MODES.items():
            for seed in seeds:
                with self.subTest(mode=mode, seed=hex(seed)):
                    self.check(mode, seed)

    def check(self, mode, seed):
        T = self.tables
        regs, partners, place, tries = self.generate(seed, mode)
        self.assertFalse(regs.get("carry"))
        self.assertEqual(self.game.peek("sRandoValid"), 1)
        py = T.Rz.generate(
            seed, max_tries=255, doors=bool(mode & DOORS), keys=bool(mode & KEYS),
            items=bool(mode & ITEMS),
        )
        self.assertEqual(tries, py["tries"])
        self.assertEqual(partners, [T.slot_of[py["pairing"][e]] for e in T.slots])
        self.assertEqual(
            place, [T.rom.items[py["placement"][l["key"]]] for l in T.C.locs]
        )

    def test_seed_hash(self):
        g = self.game
        for text, settings in [("PIKACHU", 7), ("pikachu", 7), ("PIKACHU", 3), ("Race 2026", 0x5F)]:
            g.reset()
            g.call("RandoHashStart")
            for b in randomizer.seed_codes(text) + [settings]:
                g.call("RandoHashByte", de=b)
            g.call("RandoHashResult")
            got = int.from_bytes(bytes(g.peek("wRandoSeed", 4)), "little")
            self.assertEqual(got, randomizer.seed_hash(randomizer.seed_codes(text), settings), text)

    # ---- the game's lookups (engine/rando/runtime.asm), on a built world
    def built(self, flags=DOORS | KEYS | ITEMS, seed=1):
        regs, partners, place, _ = self.generate(seed, flags)
        self.game.poke("wRandoFlags", flags)
        return partners, place

    def test_warp(self):
        g, T = self.game, self.tables
        partners, _ = self.built()
        g_ = T.g
        for e in T.slots[::17]:
            s = T.slot_of[e]
            mid, i = g_.entrances[e][0]
            g.poke("wWarpedFromWhichMap", mid)
            g.poke("wWarpedFromWhichWarp", i)
            g.poke(0xFF8B, 0xEE)  # hWarpDestinationMap
            g.call("RandoWarp")
            p = T.slots[partners[s]]
            self.assertEqual((g.peek(0xFF8B), g.peek("wDestinationWarpID")), g_.arrival[p], e)

    def test_warp_without_doors(self):
        g, T = self.game, self.tables
        self.built()
        g.poke("wRandoFlags", KEYS | ITEMS)
        mid, i = T.g.entrances[T.slots[5]][0]
        g.poke("wWarpedFromWhichMap", mid)
        g.poke("wWarpedFromWhichWarp", i)
        g.poke(0xFF8B, 0xEE)
        g.call("RandoWarp")
        self.assertEqual(g.peek(0xFF8B), 0xEE)

    def test_items(self):
        g, T = self.game, self.tables
        _, place = self.built()
        locs = T.C.locs
        for k, l in enumerate(locs):
            kind = l["key"][0]
            if kind == "ball":
                g.poke("wCurMap", l["map"])
                g.poke(0xFF8C, l["key"][2])  # hSpriteIndexOrTextID
                self.assertEqual(g.call("RandoBallItem", de=0x77)["de"] & 0xFF, place[k], l["key"])
            elif kind == "gift":
                got = g.call("RandoGiftItem", de=0x7700 | k)["de"] & 0xFF
                self.assertEqual(got, place[k], l["key"])
        hidden = [k for k, l in enumerate(locs) if l["key"][0] == "hidden"]
        table = g.peek(
            (g.bank("RandoHiddenLocs"), g.addr("RandoHiddenLocs")), len(gen_data.hidden_coords(T.rom))
        )
        for index, k in enumerate(table):
            if k in hidden:
                g.poke("wHiddenItemOrCoinsIndex", index)
                g.poke("wHiddenObjectFunctionArgument", 0x77)
                g.call("RandoHiddenItem")
                self.assertEqual(g.peek("wHiddenObjectFunctionArgument"), place[k])
                hidden.remove(k)
        self.assertEqual(hidden, [])

    def test_items_vanilla_when_off(self):
        g = self.game
        self.built()
        g.poke("wRandoFlags", 0)
        self.assertEqual(g.call("RandoGiftItem", de=0x7705)["de"] & 0xFF, 0x77)

    def test_marts(self):
        g, T = self.game, self.tables
        lists = randomizer.mart_lists(T.rom)
        for seed in (0, 1, 0xDEADBEEF):
            for i in range(len(lists)):
                g.reset()
                g.poke("wRandoFlags", 1 << 3)  # MARTS
                g.poke("wRandoSeed", *seed.to_bytes(4, "little"))
                g.poke("wItemScratch", i)
                g.call("LoadMartInventory")
                want = randomizer.mart(T.rom, lists, seed, i)
                got = g.peek("wItemList", len(want) + 2)
                self.assertEqual(got, [len(want)] + want + [0xFF], (seed, i))

    def test_marts_off(self):
        g, T = self.game, self.tables
        lists = randomizer.mart_lists(T.rom)
        g.poke("wRandoFlags", DOORS | KEYS | ITEMS)
        g.poke("wItemScratch", 1)
        g.call("LoadMartInventory")
        self.assertEqual(g.peek("wItemList", len(lists[1]) + 2), [len(lists[1])] + lists[1] + [0xFF])

    def trainer_team(self, seed, rng, flags=0x80):
        g = self.game
        g.reset()
        g.poke("wRandoFlags", flags)  # a seed was typed
        g.poke("wRandoSeed", *seed.to_bytes(4, "little"))
        events = g.addr("wEventFlags")
        g.poke(events + 0x8D8 // 8, g.peek(events + 0x8D8 // 8) | 1 << (0x8D8 % 8))  # RANDOM TRNR
        g.poke("wTrainerClass", 1)
        g.poke("wTrainerNo", 3)
        for addr, value in zip((0xFFD3, 0xFFD4, 0xFFF0, 0xFFF1), rng):
            g.poke(addr, value)
        g.call("RandoReadTrainer", max_frames=600)
        after = [g.peek(a) for a in (0xFFD3, 0xFFD4, 0xFFF0, 0xFFF1)]
        return g.peek("wEnemyPartyCount", 7), after

    def test_seeded_trainers(self):
        team, after = self.trainer_team(0x1234, (1, 2, 3, 4))
        self.assertEqual(after, [1, 2, 3, 4])  # the game's own numbers carry on
        self.assertEqual(self.trainer_team(0x1234, (9, 8, 7, 6))[0], team)
        teams = {tuple(self.trainer_team(seed, (1, 2, 3, 4))[0]) for seed in range(6)}
        self.assertGreater(len(teams), 1)

    def test_unseeded_trainers(self):
        teams = {tuple(self.trainer_team(0x1234, rng, flags=0)[0]) for rng in [(1, 2, 3, 4), (9, 8, 7, 6), (5, 5, 5, 5)]}
        self.assertGreater(len(teams), 1)

    # ---- levels scaled down
    GOLEM, GRAVELER, GEODUDE, ALAKAZAM, KADABRA = 0x31, 0x27, 0xA9, 0x95, 0x26

    def scale(self, routine, species, level, party=(10,), flags=DOORS | KEYS, boss=0):
        g = self.game
        g.reset()
        g.poke("wRandoFlags", flags)
        g.poke("wPartyCount", len(party))
        size = g.addr("wPartyMon2") - g.addr("wPartyMon1")
        for i, lv in enumerate(party):
            g.poke(g.addr("wPartyMon1Level") + i * size, lv)
        g.poke("wGymLeaderNo", boss)
        g.poke("wcf91", species)
        g.poke("wCurEnemyLVL", level)
        g.call(routine)
        return g.peek("wcf91"), g.peek("wCurEnemyLVL")

    def test_scale_down(self):
        self.assertEqual(self.scale("RandoScaleDown", self.GOLEM, 50), (self.GEODUDE, 12))
        self.assertEqual(self.scale("RandoScaleDown", self.GOLEM, 50, boss=1), (self.GEODUDE, 13))
        self.assertEqual(self.scale("RandoScaleDown", self.GOLEM, 50, party=(5, 27, 9)), (self.GRAVELER, 29))
        self.assertEqual(self.scale("RandoScaleDown", self.ALAKAZAM, 40, party=(20,)), (self.KADABRA, 22))
        self.assertEqual(self.scale("RandoScaleDownWild", self.GOLEM, 40, party=(26,)), (self.GRAVELER, 26))
        self.assertEqual(self.game.peek("wEnemyMonSpecies2"), self.GRAVELER)

    def test_scale_only_down(self):
        # below the cap: as it was, evolved or not
        self.assertEqual(self.scale("RandoScaleDown", self.GOLEM, 11), (self.GOLEM, 11))
        # only in worlds whose order is shuffled
        self.assertEqual(self.scale("RandoScaleDown", self.GOLEM, 50, flags=ITEMS), (self.GOLEM, 50))
        self.assertEqual(self.scale("RandoScaleDown", self.GOLEM, 50, flags=KEYS), (self.GEODUDE, 12))

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
