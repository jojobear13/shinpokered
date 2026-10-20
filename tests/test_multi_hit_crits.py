"""Spec test: each hit of a multi-hit move rolls its own critical hit (Gen 9),
so a critical first hit doesn't make the rest critical, for either side.
PrintCriticalOHKOText runs once per hit; a hook there records each hit's
critical flag and damage."""

import random
import re
import unittest

from harness import REPO_ROOT, shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN

with open(f"{REPO_ROOT}/constants/move_constants.asm") as f:
    MOVES = {m.group(1): int(m.group(2), 16)
             for m in re.finditer(r"const (\w+)\s*; ([0-9a-f]{2})\s*$", f.read(), re.M)}
FURY_ATTACK = MOVES["FURY_ATTACK"]


class MultiHitCritsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def turns(self, side, seeds=300):
        g = self.game
        bank, addr = g.symbols["PrintCriticalOHKOText"]
        hits = []
        damage = g.addr("wDamage")
        hook = lambda _: hits.append((g.memory[g.addr("wCriticalHitOrOHKO")],
                                      g.memory[damage] << 8 | g.memory[damage + 1]))
        g.pyboy.hook_register(bank, addr, hook, None)
        user, target = ("wBattleMon", "wEnemyMon") if side == "player" else ("wEnemyMon", "wBattleMon")
        prefix = "Player" if side == "player" else "Enemy"
        out = []
        try:
            for seed in range(seeds):
                g.reset()
                mx.setup(g, random.Random(seed))
                for s in ("wPlayerBattleStatus", "wEnemyBattleStatus"):
                    for i in (1, 2, 3):
                        g.poke(f"{s}{i}", 0)
                g.poke("wBattleMonStatus", 0)
                g.poke("wEnemyMonStatus", 0)
                g.poke16(target + "MaxHP", 999)
                g.poke16(target + "HP", 999)
                g.poke16(target + "Defense", 300)
                g.poke(user + "Moves", FURY_ATTACK)
                g.poke(user + "PP", 20)
                g.poke(f"w{prefix}SelectedMove", FURY_ATTACK)
                g.poke(f"w{prefix}MoveListIndex", 0)
                g.poke(H_WHOSETURN, 0 if side == "player" else 1)
                g.call("GetCurrentMove")
                hits.clear()
                if "error" in mx.run(g, side) or len(hits) < 2:
                    continue
                out.append(list(hits))
        finally:
            g.pyboy.hook_deregister(bank, addr)
        return out

    def check(self, side):
        turns = self.turns(side)
        self.assertGreater(len(turns), 150)
        later = [hit for turn in turns for hit in turn[1:]]
        crit_first = [turn for turn in turns if turn[0][0]]
        self.assertTrue(crit_first, "no critical first hit to check")
        # after a critical first hit, the rest roll anew: not all critical
        after_crit = [hit for turn in crit_first for hit in turn[1:]]
        self.assertLess(sum(c for c, _ in after_crit), len(after_crit))
        # and over all later hits, about 1 in 24 is critical
        rate = sum(c for c, _ in later) / len(later)
        self.assertLess(rate, 0.12)

    def test_player(self):
        self.check("player")

    def test_enemy(self):
        self.check("enemy")


if __name__ == "__main__":
    unittest.main()
