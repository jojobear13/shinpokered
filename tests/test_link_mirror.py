"""Mirror test for link battles (design brief, decision 7).

In a link battle both games run every turn, each from its own side: one
game's player is the other's enemy. They stay in step only if both draw the
same shared random numbers and reach the same result. This runs one mon's
move on two emulator instances, once as the player's move and once, with the
whole battle state mirrored, as the enemy's, then compares the random list
and the mirrored state. Abilities are random on both sides, so the abilities
that draw random numbers are covered.
"""

import random
import unittest

from harness import Game, shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from suites.damage_vars import battle_struct_len, party_struct_len
from test_abilities import ABILITIES
from test_ability_damage import MOVES

LINK_STATE_BATTLING = 4
PARTY_LENGTH = 6
NUM_LINK_RANDOMS = 9

# (player's, enemy's, length): what one game holds for its player, the other
# holds for its enemy
PAIRS = [
    ("wBattleMonNick", "wEnemyMonNick", 11),
    ("wPlayerBattleStatus1", "wEnemyBattleStatus1", 1),
    ("wPlayerBattleStatus2", "wEnemyBattleStatus2", 1),
    ("wPlayerBattleStatus3", "wEnemyBattleStatus3", 1),
    ("wPlayerMonUnmodifiedLevel", "wEnemyMonUnmodifiedLevel", 1 + 6 * 2),
    ("wPlayerMonStatMods", "wEnemyMonStatMods", 7),
    ("wPlayerSubstituteHP", "wEnemySubstituteHP", 1),
    ("wPlayerDisabledMove", "wEnemyDisabledMove", 1),
    ("wPlayerDisabledMoveNumber", "wEnemyDisabledMoveNumber", 1),
    ("wPlayerNumAttacksLeft", "wEnemyNumAttacksLeft", 1),
    ("wPlayerConfusedCounter", "wEnemyConfusedCounter", 1),
    ("wPlayerToxicCounter", "wEnemyToxicCounter", 1),
    ("wPlayerBideAccumulatedDamage", "wEnemyBideAccumulatedDamage", 2),
    ("wPlayerMonMinimized", "wEnemyMonMinimized", 1),
    ("wPlayerStatsToDouble", "wEnemyStatsToDouble", 1),
    ("wPlayerStatsToHalve", "wEnemyStatsToHalve", 1),
    ("wPlayerUsedMove", "wEnemyUsedMove", 1),
    ("wPlayerMoveNum", "wEnemyMoveNum", 6),
    ("wPlayerSelectedMove", "wEnemySelectedMove", 1),
    ("wPlayerMoveListIndex", "wEnemyMoveListIndex", 1),
    ("wPlayerAbility", "wEnemyAbility", 1),
    ("wPartyCount", "wEnemyPartyCount", 1),
]
# mirrored, but PP is spent differently by the two sides (the player's when it
# moves, the enemy's when it's chosen), so it's left out of the comparison
PP_PAIRS = []
SHARED = ["wDamage", "wCriticalHitOrOHKO", "wMoveMissed", "wDamageMultipliers"]


def _pairs(game):
    pairs = list(PAIRS)
    pairs.append(("wBattleMon", "wEnemyMon", battle_struct_len(game)))
    pairs.append(("wPartyMons", "wEnemyMons", PARTY_LENGTH * party_struct_len(game)))
    return pairs


def peek(game, name, length):
    value = game.peek(name, length)
    return value if isinstance(value, list) else [value]


def _swap_flags(flags):
    """wAbilityFlags: the FLASH_FIRE and ENTRY_PENDING bits come in player/enemy pairs."""
    out = flags & ~0b11011
    out |= (flags & 1) << 1 | (flags >> 1) & 1
    out |= (flags & 0b1000) << 1 | (flags >> 1) & 0b1000
    return out


class LinkMirrorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.a = shared_game()
        cls.b = Game()

    def state(self, game, side, parties=True):
        """The battle state seen from side 0 (the acting mon's player) or 1.
        After a turn the parties are left out: each game copies its own
        player's battle HP and status back to its party (draining moves do it
        mid-move), and never the foe's, so the copies differ by design."""
        out = {}
        for player, enemy, length in _pairs(game):
            if player == "wPartyMons" and not parties:
                continue
            mine, theirs = (player, enemy) if side == 0 else (enemy, player)
            out["mine:" + player] = peek(game, mine, length)
            out["theirs:" + player] = peek(game, theirs, length)
        # the enemy's party position is byte 3 of its battle struct, where the
        # player's struct has a copy of the level
        number = ("wPlayerMonNumber", "wEnemyMonPartyPos")
        out["mine:number"] = peek(game, number[side], 1)
        out["theirs:number"] = peek(game, number[1 - side], 1)
        for key in ("mine:wBattleMon", "theirs:wBattleMon"):
            out[key] = out[key][:3] + out[key][4:]
        for name in SHARED:
            out[name] = peek(game, name, 2 if name == "wDamage" else 1)
        out["links"] = game.peek("wLinkBattleRandomNumberList", NUM_LINK_RANDOMS)
        out["link index"] = game.peek("wLinkBattleRandomNumberListIndex")
        flags = game.peek("wAbilityFlags")
        out["ability flags"] = flags if side == 0 else _swap_flags(flags)
        return out

    def without_pp(self, game, state):
        """Drop the PP bytes from a state, in the battle structs and parties."""
        state = dict(state)
        pp = game.addr("wBattleMonPP") - game.addr("wBattleMon") - 1  # byte 3 is already out
        party_pp = game.addr("wPartyMon1PP") - game.addr("wPartyMon1")
        party_len = party_struct_len(game)
        for key in ("mine:wBattleMon", "theirs:wBattleMon"):
            state[key] = state[key][:pp] + state[key][pp + 4:]
        for key in ("mine:wPartyMons", "theirs:wPartyMons"):
            if key not in state:
                continue
            mons = state[key]
            state[key] = [b for i, b in enumerate(mons) if not party_pp <= i % party_len < party_pp + 4]
        return state

    def mirror(self, seed, abilities=None, move=None):
        """abilities: (the actor's, the target's) names, else random; move: the
        actor's move, made sure to be usable, else mx's random one."""
        a, b = self.a, self.b
        rng = random.Random(seed)
        # game A: the acting mon is the player's
        a.reset()
        mx.setup(a, rng)
        if move:
            a.poke("wPlayerSelectedMove", MOVES[move])
            a.poke(H_WHOSETURN, 0)
            a.call("GetCurrentMove")
            for i in (1, 2, 3):
                a.poke(f"wPlayerBattleStatus{i}", 0)
                a.poke(f"wEnemyBattleStatus{i}", 0)
            a.poke("wPlayerDisabledMove", 0)
            a.poke("wBattleMonStatus", 1 << 3 if abilities and abilities[0] == "SHED_SKIN" else 0)
            a.poke("wEnemyMonStatus", 0)
        a.clear_random()  # in a link battle, every battle random number comes from the shared list
        if abilities:
            a.poke("wPlayerAbility", ABILITIES[abilities[0]], ABILITIES[abilities[1]])
        else:
            pool = list(ABILITIES.values())
            a.poke("wPlayerAbility", rng.choice(pool), rng.choice(pool))
        a.poke("wAbilityFlags", 0)
        a.poke("wLinkState", LINK_STATE_BATTLING)
        a.poke("wLinkBattleRandomNumberList", *[rng.randint(0, 255) for _ in range(NUM_LINK_RANDOMS)])
        a.poke("wLinkBattleRandomNumberListIndex", rng.randint(0, NUM_LINK_RANDOMS - 1))
        a.poke("wIsInBattle", 2)
        a.poke("wSideEffectChance", 0)
        a.poke("wAbilitySnapshot", *[0] * 11)
        # game B: the same battle from the other side
        b.reset()
        b.skip_delays()
        b.skip_sound_waits()
        b.auto_buttons()
        b.queue_random()  # nothing queued: any call to Random fails, as in game A
        for player, enemy, length in _pairs(a):
            b.poke(enemy, *peek(a, player, length))
            b.poke(player, *peek(a, enemy, length))
        b.poke("wEnemyMonPartyPos", a.peek("wPlayerMonNumber"))
        b.poke("wPlayerMonNumber", a.peek("wEnemyMonPartyPos"))
        for name in ("wLinkState", "wIsInBattle", "wOptions", "wObtainedBadges", "wBattleType",
                     "wLinkBattleRandomNumberListIndex", "wSideEffectChance"):
            b.poke(name, a.peek(name))
        b.poke("wLinkBattleRandomNumberList", *a.peek("wLinkBattleRandomNumberList", NUM_LINK_RANDOMS))
        b.poke("wAbilityFlags", _swap_flags(a.peek("wAbilityFlags")))
        b.poke("wAbilitySnapshot", *[0] * 11)
        for name in ("wDamage", "wCriticalHitOrOHKO"):
            b.poke(name, *peek(a, name, 2 if name == "wDamage" else 1))
        before = self.state(a, 0)
        self.assertEqual(self.without_pp(b, self.state(b, 1)), self.without_pp(a, before))

        results = []
        for game, turn, routine in ((a, 0, "ExecutePlayerMoveThenAbilities"),
                                    (b, 1, "ExecuteEnemyMoveThenAbilities")):
            game.poke(H_WHOSETURN, turn)
            try:
                game.call(routine, max_frames=3000)
                game.poke(H_WHOSETURN, turn)
                if game.peek16(("wBattleMon", "wEnemyMon")[turn] + "HP"):
                    game.call("HandlePoisonBurnLeechSeed", max_frames=3000)
                results.append(None)
            except Exception as error:  # a call to Random, which a link battle must not make
                results.append(str(error))
        return results

    def test_both_games_agree(self):
        compared = 0
        for seed in range(80):
            with self.subTest(seed=seed):
                results = self.mirror(seed)
                self.assertEqual(results[0] is None, results[1] is None, results)
                if results[0] is not None:
                    continue
                compared += 1
                self.assertEqual(self.without_pp(self.b, self.state(self.b, 1, parties=False)),
                                 self.without_pp(self.a, self.state(self.a, 0, parties=False)))
        self.assertGreater(compared, 40)

    # abilities that draw random numbers, where they get to
    CASES = [(("NO_ABILITY", "STATIC"), "TACKLE"), (("NO_ABILITY", "EFFECT_SPORE"), "SCRATCH"),
             (("NO_ABILITY", "CURSED_BODY"), "TACKLE"), (("NO_ABILITY", "POISON_POINT"), "BODY_SLAM"),
             (("STENCH", "NO_ABILITY"), "TACKLE"), (("SERENE_GRACE", "NO_ABILITY"), "BODY_SLAM"),
             (("SHED_SKIN", "NO_ABILITY"), "TACKLE"), (("NO_ABILITY", "SHIELD_DUST"), "BITE")]

    def test_random_abilities_agree(self):
        for abilities, move in self.CASES:
            for seed in range(12):
                with self.subTest(abilities=abilities, move=move, seed=seed):
                    results = self.mirror(seed, abilities, move)
                    self.assertEqual(results, [None, None])
                    self.assertEqual(self.without_pp(self.b, self.state(self.b, 1, parties=False)),
                                     self.without_pp(self.a, self.state(self.a, 0, parties=False)))


if __name__ == "__main__":
    unittest.main()
