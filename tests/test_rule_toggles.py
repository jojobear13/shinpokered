"""The two rules the project started with are now RULES page toggles, both
on by default (their event flags mean "off"): HEAL ON WIN (the party is
healed after a trainer win) and BLACKOUT RTN (after blacking out, an offer to
go back to where it happened)."""

import unittest

from harness import shared_game

# EVENT_NO_WIN_HEAL is event $8CA and EVENT_NO_BLACKOUT_RETURN $8CB: bits 2 and
# 3 of the byte at wEventFlags + $8CA / 8
EVENT_BYTE = 0x8CA // 8
NO_WIN_HEAL, NO_BLACKOUT_RETURN = 1 << 2, 1 << 3


class RuleTogglesTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def blackout(self, rule_off):
        g = self.game
        g.reset()
        g.poke(f"wEventFlags+{EVENT_BYTE}", NO_BLACKOUT_RETURN if rule_off else 0)
        g.poke("wCurMap", 0)  # Pallet Town: not an Elite Four room
        g.call("SaveBlackoutPosition", max_frames=1000)
        return g.peek("wBlackoutReturnFlag")

    def test_blackout_return(self):
        self.assertEqual(self.blackout(rule_off=False), 1)
        self.assertEqual(self.blackout(rule_off=True), 0)

    def test_rules_page_entries(self):
        """Each entry: label, flag address, mask, and the mask again if the rule
        is inverted; the last two rows are the new inverted ones."""
        g = self.game
        g.reset()
        rows = (g.addr("RuleFlagsRowsEnd") - g.addr("RuleFlags")) // 6
        base = (g.bank("RuleFlags"), g.addr("RuleFlags"))
        entries = [g.peek((base[0], base[1] + 6 * i), 6) for i in range(rows)]
        flag_byte = g.addr("wEventFlags") + EVENT_BYTE
        heal, blackout = entries[-2], entries[-1]
        self.assertEqual((heal[2] | heal[3] << 8, heal[4], heal[5]), (flag_byte, NO_WIN_HEAL, NO_WIN_HEAL))
        self.assertEqual((blackout[2] | blackout[3] << 8, blackout[4], blackout[5]),
                         (flag_byte, NO_BLACKOUT_RETURN, NO_BLACKOUT_RETURN))
        self.assertTrue(all(e[5] == 0 for e in entries[:-2]))
