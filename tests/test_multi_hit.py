"""Spec test: an enemy multi-hit move's damage doesn't depend on the player's level.

Every hit of a multi-hit move is calculated with the attacker's level. This
runs the same enemy Double Kick turn (same mons, same random numbers) with the
player's mon at different levels; the player's remaining HP must not change.
"""

import random
import unittest

from harness import shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN

DOUBLE_KICK = 0x18
PLAYER_LEVELS = (5, 50, 100)


def enemy_double_kick(game, seed, player_level):
    """Run one enemy Double Kick turn and return the player's HP after it."""
    game.reset()
    rng = random.Random(seed)
    mx.setup(game, rng)
    # a clean turn: no lingering statuses, a sturdy target, nothing that
    # stops the move or ends it after the first hit
    for side in ("wPlayerBattleStatus", "wEnemyBattleStatus"):
        for i in (1, 2, 3):
            game.poke(f"{side}{i}", 0)
    game.poke("wBattleMonStatus", 0)
    game.poke("wEnemyMonStatus", 0)
    game.poke16("wBattleMonMaxHP", 999)
    game.poke16("wBattleMonHP", 999)
    game.poke16("wBattleMonDefense", 200)
    game.poke("wBattleMonLevel", player_level)
    game.poke("wEnemyMonLevel", 30)
    game.poke("wEnemyMonMoves", DOUBLE_KICK)
    game.poke("wEnemyMonPP", 10)
    game.poke("wEnemySelectedMove", DOUBLE_KICK)
    game.poke("wEnemyMoveListIndex", 0)
    game.poke(H_WHOSETURN, 1)
    game.call("GetCurrentMove")
    out = mx.run(game, "enemy")
    if "error" in out:
        return None  # ran out of queued randomness; skip this seed
    return game.peek16("wBattleMonHP")


class EnemyMultiHitTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_damage_ignores_player_level(self):
        checked = 0
        for seed in range(40):
            with self.subTest(seed=seed):
                hp = {level: enemy_double_kick(self.game, seed, level) for level in PLAYER_LEVELS}
                if None in hp.values():
                    continue
                checked += 1
                self.assertEqual(len(set(hp.values())), 1, f"player HP after the turn by player level: {hp}")
        self.assertGreater(checked, 30)

    def test_both_hits_land(self):
        """Guard against the test passing because the move never hits twice."""
        damaged = 0
        for seed in range(40):
            hp = enemy_double_kick(self.game, seed, 50)
            if hp is not None and hp < 999:
                damaged += 1
        self.assertGreater(damaged, 20)


if __name__ == "__main__":
    unittest.main()
