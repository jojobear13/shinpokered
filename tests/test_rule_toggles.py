"""Two of the OPTION screen's EXTRAS (engine/menu/options.asm), both off by
default as the original game had neither: HEAL ON WIN (the party is healed
after a trainer win) and WARP BACK (after blacking out, an offer to go back
to where it happened)."""

import unittest

from harness import shared_game

# EVENT_WIN_HEAL is event $8CA and EVENT_BLACKOUT_RETURN $8CB: bits 2 and 3 of
# the byte at wEventFlags + $8CA / 8
EVENT_BYTE = 0x8CA // 8
WIN_HEAL, BLACKOUT_RETURN = 1 << 2, 1 << 3


class RuleTogglesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def blackout(self, option_on):
        g = self.game
        g.reset()
        g.poke(f"wEventFlags+{EVENT_BYTE}", BLACKOUT_RETURN if option_on else 0)
        g.poke("wCurMap", 0)  # Pallet Town: not an Elite Four room
        g.call("SaveBlackoutPosition", max_frames=1000)
        return g.peek("wBlackoutReturnFlag")

    def test_blackout_return(self):
        self.assertEqual(self.blackout(option_on=True), 1)
        self.assertEqual(self.blackout(option_on=False), 0)

    def test_new_game_keeps_them(self):
        """Both are among the event flags NEW GAME carries over (RuleFlags:
        each flag's address and mask)."""
        g = self.game
        g.reset()
        bank, base = g.bank("RuleFlags"), g.addr("RuleFlags")
        count = (g.addr("RuleFlagsEnd") - base) // 3
        flags = [tuple(g.peek((bank, base + 3 * i), 3)) for i in range(count)]
        address = g.addr("wEventFlags") + EVENT_BYTE
        self.assertIn((address & 0xFF, address >> 8, WIN_HEAL), flags)
        self.assertIn((address & 0xFF, address >> 8, BLACKOUT_RETURN), flags)
