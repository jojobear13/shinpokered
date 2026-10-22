"""Spec tests for held items, part 3: outside the moves (design brief, plan
step E, part 5).

Lucky Egg: x1.5 experience. Exp. Share: its holder counts as having fought.
Amulet Coin: a trainer's prize money doubles. Everstone: no level-up
evolution. Pickup: after a battle, a mon with it that holds nothing picks
up an item 10% of the time. (Cleanse Tag, in the wild encounter roll, has no test of its own:
the roll needs a whole map.)
"""

import unittest

from harness import shared_game
from test_held_items import ITEMS
from test_abilities import ABILITIES, TABLE
from test_special_split import SPECIES


class ExperienceItemTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def gain(self, item, traded=False):
        g = self.game
        g.reset()
        g.poke("wPlayerID", 0x12, 0x34)
        g.poke("wPartyMon1OTID", 0x12, 0x99 if traded else 0x34)
        g.poke("wPartyMon1CatchRate", ITEMS[item] if item else 0)
        g.poke("wPartyMon1Exp", 0, 0, 0)
        g.poke(0xFF95, 0, 0, 0, 100)  # H_QUOTIENT: the experience to give
        g.call("AddExpToPokemon", hl=g.addr("wPartyMon1OTID"))
        exp = g.peek("wPartyMon1Exp", 3)
        return exp[0] << 16 | exp[1] << 8 | exp[2], g.peek("wGainBoostedExp")

    def test_lucky_egg(self):
        self.assertEqual(self.gain(0), (100, 0))
        self.assertEqual(self.gain("LUCKY_EGG"), (150, 1))
        self.assertEqual(self.gain("LUCKY_EGG", traded=True), (225, 1))
        self.assertEqual(self.gain("CHARCOAL"), (100, 0))

    def test_exp_share(self):
        g = self.game
        g.reset()
        g.poke("wPartyCount", 4)
        for i, item in enumerate((0, "EXP_SHARE", 0, "EXP_SHARE")):
            g.poke(f"wPartyMon{i + 1}CatchRate", ITEMS[item] if item else 0)
        g.poke("wPartyGainExpFlags", 0b0001)
        g.call("ExpShareHolders")
        self.assertEqual(g.peek("wPartyGainExpFlags"), 0b1011)


class MoneyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def money(self, item):
        g = self.game
        g.reset()
        g.poke("wPartyCount", 3)
        for i in range(3):
            g.poke(f"wPartyMon{i + 1}CatchRate", 0)
        if item:
            g.poke("wPartyMon3CatchRate", ITEMS[item])
        g.poke("wAmountMoneyWon", 0x01, 0x23, 0x45)
        g.call("AmuletCoinMoney")
        return g.peek("wAmountMoneyWon", 3)

    def test_amulet_coin(self):
        self.assertEqual(self.money("AMULET_COIN"), [0x02, 0x46, 0x90])
        self.assertEqual(self.money(None), [0x01, 0x23, 0x45])
        self.assertEqual(self.money("LUCKY_EGG"), [0x01, 0x23, 0x45])


class EverstoneTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def evolve(self, item):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.poke("wPartyCount", 1, SPECIES["CHARMANDER"], 0xFF)
        g.poke("wPartyMon1Species", SPECIES["CHARMANDER"])
        g.poke("wPartyMon1Level", 20)
        g.poke("wPartyMon1BoxLevel", 20)
        g.poke16("wPartyMon1HP", 50)
        g.poke("wPartyMon1CatchRate", ITEMS[item] if item else 0)
        g.poke("wPartyMonNicks", 0x80, 0x50)
        g.poke("wStartBattleLevels", 19)
        g.poke("wIsInBattle", 0)
        g.poke("wLinkState", 0)
        g.poke("wForceEvolution", 0)
        g.poke("wWhichPokemon", 0)
        # the evolution scene can't run in the harness (no V-blank): stop
        # where it would start
        started = []
        bank, addr = g.symbols["EvolveMon"]
        g.pyboy.hook_register(bank, addr, lambda _: started.append(True), None)
        try:
            g.call("TryEvolvingMon", max_frames=60)
        except Exception:
            pass
        finally:
            g.pyboy.hook_deregister(bank, addr)
        return bool(started), g.peek("wPartyMon1Species")

    def test_everstone(self):
        self.assertEqual(self.evolve("EVERSTONE"), (False, SPECIES["CHARMANDER"]))
        started, _ = self.evolve(None)
        self.assertTrue(started)


class PickupTest(unittest.TestCase):
    """PartyPickup, which EndOfBattle calls outside link battles."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def pickup(self, mons, *rolls):
        """mons: (species, ability slot, held item) per party mon."""
        g = self.game
        g.reset()
        g.clear_random()
        if rolls:
            g.queue_random(*rolls)
        g.poke("wPartyCount", len(mons))
        for i, (species, slot, item) in enumerate(mons):
            g.poke(f"wPartyMon{i + 1}Species", SPECIES[species])
            g.poke(f"wPartyMon{i + 1}IVs", 0xFF, 0xFF, 0xFF, 0xFC | slot)
            g.poke(f"wPartyMon{i + 1}CatchRate", ITEMS[item] if item else 0)
        g.call("PartyPickup")
        self.assertEqual(g.random_used(), len(rolls))
        return [g.peek(f"wPartyMon{i + 1}CatchRate") for i in range(len(mons))]

    def test_odds_and_items(self):
        self.assertEqual(dict(TABLE)["MEOWTH"][0], ABILITIES["PICKUP"])
        meowth = ("MEOWTH", 0, None)
        self.assertEqual(self.pickup([meowth], 26), [0])  # the 10% roll fails
        cases = [(0, "SUPER_POTION"), (76, "SUPER_POTION"), (77, "FULL_HEAL"), (154, "RARE_CANDY"),
                 (232, "NUGGET"), (233, "PROTEIN"), (246, "PP_UP"), (252, "PP_UP"),
                 (253, "KINGS_ROCK"), (255, "KINGS_ROCK")]
        for roll, item in cases:
            with self.subTest(roll=roll):
                self.assertEqual(self.pickup([meowth], 25, roll), [ITEMS[item]])

    def test_who_picks_up(self):
        mons = [("MEOWTH", 1, None),  # Technician
                ("PIKACHU", 0, None),
                ("MEOWTH", 0, "LEFTOVERS"),  # already holding something
                ("MEOWTH", 0, None)]
        self.assertEqual(self.pickup(mons, 0, 0), [0, 0, ITEMS["LEFTOVERS"], ITEMS["SUPER_POTION"]])
        self.assertEqual(self.pickup([]), [])


if __name__ == "__main__":
    unittest.main()
