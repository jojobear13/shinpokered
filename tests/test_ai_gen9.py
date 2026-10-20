"""Spec tests for the AI's Gen 9 follow-up (design brief, Gen 9 rules pass,
part 10): AIMoveChoiceModification1 discourages Growth only with both
attack and special attack at +6, and Whirlwind, Roar or Teleport only
without a mon that could come in.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import _constants

MOVES = _constants("move_constants.asm", ["GROWTH", "ROAR", "TACKLE", "TELEPORT"])
MOD_ATTACK, MOD_SPECIAL_ATTACK = 0, 3


class AIGen9Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def scores(self, mods=7, player_hps=(50, 40), enemy_hps=(50,)):
        g = self.game
        g.reset()
        mx.setup(g, random.Random(51))
        g.poke("wIsInBattle", 2)
        for i in (1, 2, 3):
            g.poke(f"wPlayerBattleStatus{i}", 0)
            g.poke(f"wEnemyBattleStatus{i}", 0)
        g.poke("wPlayerAbility", 0, 0)
        for mon in ("wBattleMon", "wEnemyMon"):
            g.poke(mon + "Status", 0)
            g.poke16(mon + "MaxHP", 200)
            g.poke16(mon + "HP", 200)
        g.poke("wUnusedC000", 0)
        g.poke("wEnemyMonMoves", MOVES["GROWTH"], MOVES["ROAR"], MOVES["TELEPORT"], MOVES["TACKLE"])
        stages = [7] * 7
        stages[MOD_ATTACK] = stages[MOD_SPECIAL_ATTACK] = mods
        g.poke("wEnemyMonStatMods", *stages)
        size = g.addr("wPartyMon2") - g.addr("wPartyMon1")
        for party, count, hps in (("wPartyMon1HP", "wPartyCount", player_hps),
                                  ("wEnemyMon1HP", "wEnemyPartyCount", enemy_hps)):
            g.poke(count, len(hps))
            for i, hp in enumerate(hps):
                g.poke16(g.addr(party) + i * size, hp)
        g.poke("wPlayerMonNumber", 0)
        g.poke("wEnemyMonPartyPos", 0)
        g.poke("wBuffer", 20, 20, 20, 20)
        g.poke("wAILastMovePower", 40)  # its last move did damage: no spam protection
        g.clear_random()
        g.queue_random(*[60] * 32)  # its random bias on status moves: neither way
        g.call("AIMoveChoiceModification1", max_frames=20000)
        growth, roar, teleport, tackle = g.peek("wBuffer", 4)
        return growth - tackle, roar - tackle, teleport - tackle

    def test_growth(self):
        self.assertLessEqual(self.scores(mods=7)[0], 0)
        self.assertLessEqual(self.scores(mods=13 - 1)[0], 0)  # one stat can still rise
        self.assertGreater(self.scores(mods=13)[0], 0)

    def test_switch_moves(self):
        _, roar, teleport = self.scores(player_hps=(50, 40), enemy_hps=(50, 30))
        self.assertLessEqual((roar, teleport), (0, 0))
        _, roar, teleport = self.scores(player_hps=(50, 0), enemy_hps=(50,))
        self.assertGreater(roar, 0)
        self.assertGreater(teleport, 0)
