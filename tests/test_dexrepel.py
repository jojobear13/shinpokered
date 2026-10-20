"""The DEXREPEL, a key item PROF.OAK's aide upstairs in the Route 12 gate
gives for 80 kinds caught. Used from the bag it turns on or off
(EVENT_DEXREPEL_ON); on, wild mons whose species is owned don't appear
(WildRepelCheck, which TryDoWildEncounter asks along with the REPEL check)."""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game

with open(os.path.join(REPO_ROOT, "constants", "item_constants.asm")) as f:
    ITEMS = {m.group(1): int(m.group(2), 16) for m in re.finditer(r"const (\w+)\s*; \$([0-9A-F]+)", f.read())}
DEXREPEL = ITEMS["DEXREPEL"]
DEXREPEL_ON = 0x8CD
PIDGEY, RATTATA = 0x24, 0xA5  # Pokédex 16 and 19


class DexRepelTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        g.poke("wPokedexOwned", *[0] * 19)
        g.poke("wRepelRemainingSteps", 0)
        self.set_on(False)

    def set_on(self, on):
        g = self.game
        address = f"wEventFlags+{DEXREPEL_ON // 8}"
        value = g.peek(address) & ~(1 << DEXREPEL_ON % 8)
        g.poke(address, value | on << DEXREPEL_ON % 8)

    def is_on(self):
        return bool(self.game.peek(f"wEventFlags+{DEXREPEL_ON // 8}") >> DEXREPEL_ON % 8 & 1)

    def repelled(self, species, level=10, lead_level=5):
        g = self.game
        g.poke("wEnemyMonSpecies2", species)
        g.poke("wCurEnemyLVL", level)
        g.poke("wPartyMon1Level", lead_level)
        return bool(g.call("WildRepelCheck", max_frames=100)["f"] & 0x10)

    def own(self, dex):
        g = self.game
        g.poke(f"wPokedexOwned+{(dex - 1) // 8}", g.peek(f"wPokedexOwned+{(dex - 1) // 8}") | 1 << (dex - 1) % 8)

    def test_off(self):
        self.own(16)
        self.assertFalse(self.repelled(PIDGEY))

    def test_on_keeps_owned_away(self):
        self.set_on(True)
        self.own(16)
        self.assertTrue(self.repelled(PIDGEY))
        self.assertFalse(self.repelled(RATTATA))

    def test_repel_still_works(self):
        g = self.game
        g.poke("wRepelRemainingSteps", 50)
        self.assertTrue(self.repelled(RATTATA, level=3, lead_level=10))
        self.assertFalse(self.repelled(RATTATA, level=12, lead_level=10))

    def test_use_toggles(self):
        g = self.game
        g.skip_delays()
        g.auto_buttons()
        g.poke("wcf91", DEXREPEL)
        g.poke("wIsInBattle", 0)
        g.call("UseItem_", max_frames=4000)
        self.assertTrue(self.is_on())
        self.assertEqual(g.peek("wActionResultOrTookBattleTurn"), 1)
        g.call("UseItem_", max_frames=4000)
        self.assertFalse(self.is_on())

    def test_not_in_battle(self):
        g = self.game
        g.skip_delays()
        g.auto_buttons()
        g.poke("wcf91", DEXREPEL)
        g.poke("wIsInBattle", 1)
        g.call("UseItem_", max_frames=4000)
        self.assertFalse(self.is_on())

    def test_key_item(self):
        g = self.game
        g.poke("wcf91", DEXREPEL)
        g.call("IsKeyItem")
        self.assertEqual(g.peek("wIsKeyItem"), 1)
        pockets = g.bank("ItemPockets"), g.addr("ItemPockets")
        self.assertEqual(g.peek((pockets[0], pockets[1] + DEXREPEL - 1)), 5)  # POCKET_KEY


if __name__ == "__main__":
    unittest.main()
