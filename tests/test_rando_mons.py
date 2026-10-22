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


if __name__ == "__main__":
    unittest.main()
