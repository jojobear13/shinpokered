"""The randomizer's #MON (engine/rando/mons.asm, the RANDOM #MON options):
starters, trainers, wild and one-off #MON, trades, TMs and learnsets.

Everything is drawn from the seed when the game needs it, so these check
what the rules promise: the same seed gives the same answers, the answers
are the kind asked for (a line of three, a type theme, similar strength),
and with an option off nothing changes."""

import os
import sys
import unittest

from harness import REPO_ROOT, shared_game

sys.path.insert(0, os.path.join(REPO_ROOT, "tools", "rando"))
import mons as M  # noqa: E402
import rom as R  # noqa: E402

STARTER_LINES = [["BULBASAUR", "IVYSAUR", "VENUSAUR"], ["CHARMANDER", "CHARMELEON", "CHARIZARD"],
                 ["SQUIRTLE", "WARTORTLE", "BLASTOISE"]]


class RandoMonsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()
        cls.mons = M.Mons(R.Rom(os.path.splitext(os.path.basename(cls.game.rom_path))[0]))
        cls.sp = cls.mons.species

    def setup(self, seed, flags2=0, flags3=0, flags=0):
        g = self.game
        g.reset()
        g.poke("wRandoSeed", *seed.to_bytes(4, "little"))
        g.poke("wRandoFlags", flags)
        g.poke("wRandoFlags2", flags2)
        g.poke("wRandoFlags3", flags3)

    # ---- starters
    def starters(self, seed, mode):
        self.setup(seed, flags2=mode)
        out = []
        for line in STARTER_LINES:
            out.append([self.game.call("RandoStarterMonFar", de=self.sp[n])["de"] & 0xFF for n in line])
        return out

    def test_starters_off(self):
        self.assertEqual(self.starters(5, 0), [[self.sp[n] for n in l] for l in STARTER_LINES])

    def test_starters_random(self):
        lines = [l for l in self.mons.lines3()]
        seen = set()
        for seed in range(1, 25):
            got = self.starters(seed, 1)
            for l in got:
                self.assertIn(l, lines)
            self.assertEqual(len({l[0] for l in got}), 3)
            self.assertEqual(got, self.starters(seed, 1))  # the same seed, the same starters
            seen.add(tuple(map(tuple, got)))
        self.assertGreater(len(seen), 15)

    def test_starters_types(self):
        m = self.mons
        for seed in range(1, 25):
            grass, fire, water = (l[0] for l in self.starters(seed, 2))
            # as the originals: water beats fire beats grass beats water
            self.assertTrue(m.beats(water, fire) and m.beats(fire, grass) and m.beats(grass, water),
                            [m.name[x] for x in (grass, fire, water)])

    def test_other_species_unchanged(self):
        self.setup(3, flags2=1)
        self.assertEqual(self.game.call("RandoStarterMonFar", de=self.sp["PIDGEY"])["de"] & 0xFF,
                         self.sp["PIDGEY"])

    # ---- trainers
    ALL = 1 << 4

    def trainer_mon(self, cls, no, species, slot=0, seed=7, flags2=ALL):
        self.setup(seed, flags2=flags2)
        g = self.game
        g.poke("wTrainerClass", self.mons.trainer_classes[cls])
        g.poke("wTrainerNo", no)
        g.poke("wEnemyPartyCount", slot)
        g.poke("wcf91", self.sp[species])
        g.poke("wCurEnemyLVL", 20)
        g.poke("wPartyCount", 0)
        g.call("RandoTrainerMon", max_frames=600)
        return g.peek("wcf91")

    def test_trainers_off(self):
        self.assertEqual(self.trainer_mon("MISTY", 1, "STARMIE", flags2=0), self.sp["STARMIE"])

    def test_bosses_keep_their_type(self):
        m = self.mons
        for cls, team, kind in [("MISTY", ["STARYU", "STARMIE"], "WATER"), ("BROCK", ["GEODUDE", "ONIX"], "ROCK"),
                                ("AGATHA", ["HAUNTER", "GENGAR", "GOLBAT"], "GHOST"),
                                ("LANCE", ["GYARADOS", "DRAGONAIR", "DRAGONITE"], "DRAGON")]:
            for seed in range(1, 6):
                for slot, name in enumerate(team):
                    got = self.trainer_mon(cls, 1, name, slot, seed)
                    self.assertIn(M.TYPES[kind], m.types[got], (cls, m.name[got]))
                    self.assertNotIn(got, m.legendary)

    def test_similar_strength(self):
        m = self.mons
        far = 0
        for seed in range(1, 30):
            got = self.trainer_mon("YOUNGSTER", 1, "RATTATA", 0, seed)
            far += abs(m.bst[got] - m.bst[self.sp["RATTATA"]]) > m.bst[self.sp["RATTATA"]] // 4 + 4
        self.assertLessEqual(far, 2)

    def test_trainers_follow_the_seed(self):
        a = [self.trainer_mon("LASS", 2, "PIDGEY", k, 9) for k in range(3)]
        self.assertEqual(a, [self.trainer_mon("LASS", 2, "PIDGEY", k, 9) for k in range(3)])
        self.assertNotEqual(a, [self.trainer_mon("LASS", 2, "PIDGEY", k, 10) for k in range(3)])

    def test_rival_keeps_the_starter_line(self):
        self.assertEqual(self.trainer_mon("SONY3", 1, "BLASTOISE", 5), self.sp["BLASTOISE"])
        # with STARTERS too, the line in that slot
        got = self.trainer_mon("SONY3", 1, "BLASTOISE", 5, flags2=self.ALL | 1)
        self.assertEqual(got, self.starters(7, 1)[2][2])
        # with STARTERS alone, only the starter line changes
        self.assertEqual(self.trainer_mon("SONY1", 1, "PIDGEY", 0, flags2=1), self.sp["PIDGEY"])

    def test_boss_held_items(self):
        g = self.game
        self.setup(3, flags2=self.ALL)
        g.poke("wTrainerClass", self.mons.trainer_classes["BROCK"])
        g.poke("wTrainerNo", 1)
        g.poke("wEnemyPartyCount", 2)
        size = g.addr("wEnemyMon2") - g.addr("wEnemyMon1")
        g.poke("wEnemyMon1CatchRate", 0)
        g.poke(g.addr("wEnemyMon1CatchRate") + size, 0x72)  # BERRY: kept
        g.call("RandoTrainerHeld", max_frames=600)
        self.assertNotEqual(g.peek("wEnemyMon1CatchRate"), 0)
        self.assertEqual(g.peek(g.addr("wEnemyMon1CatchRate") + size), 0x72)


    # ---- wild
    AREA = 1 << 5

    def set_event(self, event, on=True):
        g = self.game
        a = g.addr("wEventFlags") + event // 8
        g.poke(a, g.peek(a) & ~(1 << event % 8) | on << event % 8)

    def rom_list(self, label):
        g = self.game
        bank, a = g.bank(label), g.addr(label)
        out = []
        while g.peek((bank, a)) != 0xFF:
            out.append(g.peek((bank, a)))
            a += 1
        return out

    def full_random(self, seed, species):
        self.setup(seed)
        self.set_event(0x8DE)
        self.set_event(0x8D7)
        self.set_event(0x8DA, False)
        g = self.game
        g.poke("wRandomizerSeed", 77)
        g.poke("wcf91", species)
        g.call("_ReplaceMon", max_frames=600)
        return g.peek("wcf91")

    def test_full_random_uses_the_whole_seed(self):
        lst = self.rom_list("MonListTrueRandom")
        maps = []
        for seed in (0x01020304, 0x01020305):
            got = [self.full_random(seed, sp) for sp in lst[:40]]
            self.assertEqual(len(set(got)), len(got))   # a shuffle
            self.assertTrue(set(got) <= set(lst))
            maps.append(got)
        self.assertNotEqual(maps[0], maps[1])           # a different seed, another shuffle

    def area_mon(self, number, water=0, seed=11):
        self.setup(seed, flags2=self.AREA)
        g = self.game
        g.call("RandoAreaMon", hl=number, bc=water, max_frames=600)
        return g.peek("wcf91")

    def test_area_has_every_basic(self):
        m = self.mons
        land = {sp for sp in m.all if m.basic(sp) and sp not in m.legendary}
        got = {self.area_mon(n) for n in range(len(land))}
        self.assertEqual(got, land)
        water = {sp for sp in land if M.TYPES["WATER"] in m.types[sp]}
        self.assertEqual({self.area_mon(n, 1) for n in range(len(water))}, water)

    def test_area_by_the_slot(self):
        g = self.game
        self.setup(11, flags2=self.AREA)
        route1 = 0x0C
        g.poke("wCurMap", route1)
        g.poke("wTileMap+%d" % (9 * 20 + 8), 0x00)       # not water
        g.poke("wCurEnemyLVL", 3)
        got = []
        for slot in range(10):
            g.poke("wcf91", self.sp["PIDGEY"])
            g.call("RandoWildArea", de=slot * 2, max_frames=600)
            got.append(g.peek("wcf91"))
            self.assertEqual(g.peek("wEnemyMonSpecies2"), got[-1])
        groups = g.peek((g.bank("RandoWildGroups"), g.addr("RandoWildGroups") + 2 * route1))
        want = [self.area_mon((groups - 1) * 10 + k) for k in range(10)]
        self.assertEqual(got, want)

    def test_area_off(self):
        g = self.game
        self.setup(11)
        g.poke("wCurMap", 0x0C)
        g.poke("wcf91", self.sp["PIDGEY"])
        g.call("RandoWildArea", de=0, max_frames=600)
        self.assertEqual(g.peek("wcf91"), self.sp["PIDGEY"])

    def test_area_pokedex(self):
        g = self.game
        m = self.mons
        bank, table = g.bank("RandoWildGroups"), g.addr("RandoWildGroups")
        groups = g.peek((bank, table), 2 * 248)
        where = {}
        for mid in range(248):
            gr = groups[2 * mid]
            if gr:
                for k in range(10):
                    where.setdefault(self.area_mon((gr - 1) * 10 + k), set()).add(mid)
        for sp in list(where)[:4] + [self.sp["MEWTWO"]]:
            self.setup(11, flags2=self.AREA)
            g.poke("wd11e", sp)
            g.poke("wCurMap", 0)
            regs = g.call("RandoAreaLocations", max_frames=3000)
            self.assertEqual(regs["de"] & 0xFF, 1)
            found = []
            for b in g.peek("wBuffer", 30):
                if b == 0xFF:
                    break
                found.append(b)
            self.assertEqual(set(found), where.get(sp, set()), m.name[sp])

    def test_wild_held_items(self):
        g = self.game
        self.setup(5)
        self.assertEqual(g.call("RandoWildHeldPick", de=self.sp["PIDGEY"])["de"] & 0xFF, 0xFF)
        self.setup(5, flags=1 << 2)  # ITEMS
        a = g.call("RandoWildHeldPick", de=self.sp["PIDGEY"])["de"] & 0xFF
        self.assertEqual(a, g.call("RandoWildHeldPick", de=self.sp["PIDGEY"])["de"] & 0xFF)
        picks = {g.call("RandoWildHeldPick", de=sp)["de"] & 0xFF for sp in self.mons.all[:30]}
        self.assertGreater(len(picks), 10)


if __name__ == "__main__":
    unittest.main()
