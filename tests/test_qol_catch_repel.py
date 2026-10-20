"""Two Gen 6+ conveniences: a caught wild mon gives the party experience and
EVs as one defeated would (CaughtMonExperience, not in the Safari Zone), and
when a repel wears off the game offers another of the same kind if the bag
has one (RepelWoreOff, remembering wLastRepelUsed)."""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game
from test_moves_screen import SPECIES

with open(os.path.join(REPO_ROOT, "constants", "item_constants.asm")) as f:
    ITEMS = {m.group(1): int(m.group(2), 16) for m in re.finditer(r"const (\w+)\s*; \$([0-9A-F]+)", f.read())}
REPEL, SUPER_REPEL, POTION = ITEMS["REPEL"], ITEMS["SUPER_REPEL"], ITEMS["POTION"]


class CatchExperienceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def catch(self, battle_type):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.poke("wLinkState", 0)
        g.poke("wIsInBattle", 1)
        g.poke("wBattleType", battle_type)
        g.poke("wPlayerID", 0x12, 0x34)
        g.poke("wPartyCount", 1, SPECIES["CHARMANDER"], 0xFF)
        g.poke("wPartyMon1Species", SPECIES["CHARMANDER"])
        g.poke("wPartyMon1Level", 10)
        g.poke("wPartyMon1BoxLevel", 10)
        g.poke16("wPartyMon1HP", 20)
        g.poke16("wPartyMon1MaxHP", 30)
        g.poke("wPartyMon1OTID", 0x12, 0x34)
        g.poke("wPartyMon1CatchRate", 0)
        g.poke("wPartyMon1Exp", 0, 0x03, 0xE8)
        g.poke("wPartyMon1EVs", *[0] * 6)
        g.poke("wPartyGainExpFlags", 1)
        g.poke("wPartyFoughtCurrentEnemyFlags", 1)
        g.poke("wPlayerMonNumber", 0)
        g.poke("wEnemyMonSpecies", SPECIES["PIDGEY"])
        g.poke("wEnemyMonLevel", 8)
        g.poke("wcf91", SPECIES["PIDGEY"])
        g.poke("wd11e", 16)
        g.call("CaughtMonExperience", max_frames=20000)
        exp = g.peek("wPartyMon1Exp", 3)
        return exp[0] << 16 | exp[1] << 8 | exp[2], g.peek("wPartyMon1EVs", 6)

    def test_party_gains(self):
        exp, evs = self.catch(0)
        self.assertGreater(exp, 1000)
        self.assertEqual(evs, [0, 0, 0, 1, 0, 0])  # Pidgey: 1 speed
        # the catch goes on with the caught mon's species where it was
        self.assertEqual(self.game.peek("wcf91"), SPECIES["PIDGEY"])
        self.assertEqual(self.game.peek("wd11e"), 16)

    def test_not_in_the_safari_zone(self):
        self.assertEqual(self.catch(2), (1000, [0] * 6))


class RepelPromptTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def wore_off(self, bag, last, answer=None):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.poke("wNumBagItems", len(bag))
        flat = [x for item in bag for x in (item, 3)]
        g.poke("wBagItems", *flat, 0xFF)
        g.poke("wLastRepelUsed", last)
        g.poke("wRepelRemainingSteps", 0)
        if answer is not None:
            g.menu_choices(answer)
        g.call("RepelWoreOff", max_frames=4000)
        n = g.peek("wNumBagItems")
        items = g.peek("wBagItems", 2 * n) if n else []
        return g.peek("wRepelRemainingSteps"), dict(zip(items[::2], items[1::2]))

    def test_yes_uses_another(self):
        steps, bag = self.wore_off([POTION, SUPER_REPEL], SUPER_REPEL, answer=0)
        self.assertEqual(steps, 200)
        self.assertEqual(bag[SUPER_REPEL], 2)

    def test_no(self):
        steps, bag = self.wore_off([SUPER_REPEL], SUPER_REPEL, answer=1)
        self.assertEqual(steps, 0)
        self.assertEqual(bag[SUPER_REPEL], 3)

    def test_only_the_same_kind(self):
        # a REPEL wore off and only a SUPER_REPEL is left: no offer (no menu)
        steps, bag = self.wore_off([SUPER_REPEL], REPEL)
        self.assertEqual(steps, 0)
        self.assertEqual(bag[SUPER_REPEL], 3)

    def test_using_one_remembers_it(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        g.poke("wIsInBattle", 0)
        g.poke("wNumBagItems", 1)
        g.poke("wBagItems", REPEL, 2, 0xFF)
        g.poke("wWhichPokemon", 0)
        g.poke("wcf91", REPEL)
        g.call("UseItem_", max_frames=4000)
        self.assertEqual(g.peek("wRepelRemainingSteps"), 100)
        self.assertEqual(g.peek("wLastRepelUsed"), REPEL)


if __name__ == "__main__":
    unittest.main()
