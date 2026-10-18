"""Randomized whole turns: ExecutePlayerMove and ExecuteEnemyMove.

Each case picks a real move for the attacker, loads it the way the game does
(GetCurrentMove), and runs the attacker's entire move: status checks, the
"<mon> used <move>!" text, PP, critical hits, damage, the hit test, applying
damage and the move's effect. Battle animations are turned off in the
options; delays, sound waits and button presses are skipped.
"""

from harness import HarnessError
from suites.apply_attack import H_WHOSETURN, NAME_LENGTH, TERMINATOR, _hp
from suites.damage_vars import (BATTLE_STRUCT_LEN, ENEMY_SPECIES, PARTY_LENGTH, SPECIES, TYPES,
                                _party, stat)

NAME = "move_execution"

NUM_MOVES = 4
NUM_ATTACKS = 165  # moves 1-165; STRUGGLE (165) included
BATTLE_ANIMATION_OFF = 1 << 7  # wOptions
TEXT_SPEED_FAST = 1

# offsets into the battle struct
SPECIES_OFFSET = 0x00
STATUS_OFFSET = 0x04
TYPE1_OFFSET = 0x05
MOVES_OFFSET = 0x08
LEVEL_OFFSET = 0x0E
PP_OFFSET = 0x19

ROUTINES = {"player": "ExecutePlayerMove", "enemy": "ExecuteEnemyMove"}


def _status(rng):
    roll = rng.random()
    if roll < 0.85:
        return 0
    return rng.choice([rng.randint(1, 7), 1 << 3, 1 << 4, 1 << 5, 1 << 6])  # sleep, PSN, BRN, FRZ, PAR


def _battle_flags(rng):
    """Mostly clear: most set bits (flinching, recharging, Bide, ...) end the
    turn before the move is used, which would starve the damage path."""
    return 0 if rng.random() < 0.85 else 1 << rng.randint(0, 7)


def _mon(game, rng, prefix, nick, species_pool):
    base = game.addr(prefix)
    game.poke(base, *[rng.randint(0, 255) for _ in range(BATTLE_STRUCT_LEN)])
    game.poke(base + SPECIES_OFFSET, rng.choice(species_pool))
    game.poke(base + LEVEL_OFFSET, rng.randint(2, 100))
    game.poke(base + STATUS_OFFSET, _status(rng))
    game.poke(base + TYPE1_OFFSET, rng.choice(TYPES), rng.choice(TYPES))
    moves = [rng.randint(1, NUM_ATTACKS) for _ in range(NUM_MOVES)]
    game.poke(base + MOVES_OFFSET, *moves)
    game.poke(base + PP_OFFSET, *[rng.choice([0, 1, rng.randint(1, 40)]) for _ in range(NUM_MOVES)])
    for name in ("Attack", "Defense", "Speed", "Special"):
        game.poke16(prefix + name, min(stat(rng), 999) or 1)
    max_hp = max(_hp(rng), 1)
    game.poke16(prefix + "MaxHP", max_hp)
    game.poke16(prefix + "HP", rng.randint(1, max_hp))
    name = [rng.randint(0x80, 0x99) for _ in range(rng.randint(1, NAME_LENGTH - 1))]
    game.poke(nick, *(name + [TERMINATOR]))
    return moves


def setup(game, rng):
    game.skip_delays()
    game.skip_sound_waits()
    game.auto_buttons()

    player_moves = _mon(game, rng, "wBattleMon", "wBattleMonNick", SPECIES)
    enemy_moves = _mon(game, rng, "wEnemyMon", "wEnemyMonNick", ENEMY_SPECIES)
    _party(game, rng, "wPartyMons")
    _party(game, rng, "wEnemyMons")

    for side in ("wPlayerBattleStatus", "wEnemyBattleStatus"):
        for i in (1, 2, 3):
            game.poke(f"{side}{i}", _battle_flags(rng))
    for name in ("wPlayerMonAttackMod", "wEnemyMonAttackMod"):
        game.poke(name, *[rng.choice([7, 7, 7, rng.randint(1, 13)]) for _ in range(6)])
    for name in ("wPlayerSubstituteHP", "wEnemySubstituteHP", "wPlayerDisabledMove", "wEnemyDisabledMove",
                 "wPlayerNumAttacksLeft", "wEnemyNumAttacksLeft", "wPlayerConfusedCounter",
                 "wEnemyConfusedCounter", "wPlayerToxicCounter", "wEnemyToxicCounter",
                 "wPlayerBideAccumulatedDamage", "wEnemyBideAccumulatedDamage"):
        if name in game.symbols:
            game.poke(name, 0 if rng.random() < 0.7 else rng.randint(0, 5))

    game.poke("wObtainedBadges", 0xFF)  # otherwise mons over level 10 disobey
    game.poke("wPlayerMonNumber", rng.randint(0, PARTY_LENGTH - 1))
    game.poke("wPartyCount", PARTY_LENGTH)
    game.poke("wEnemyPartyCount", PARTY_LENGTH)
    game.poke("wEnemyMonPartyPos", rng.randint(0, PARTY_LENGTH - 1))
    game.poke("wIsInBattle", rng.choice([1, 2]))
    game.poke("wLinkState", 0)
    game.poke("wBattleType", 0)
    game.poke("wOptions", BATTLE_ANIMATION_OFF | TEXT_SPEED_FAST)
    game.poke("wCriticalHitOrOHKO", 0)
    game.poke16("wDamage", 0)

    # choose each side's move and load it the way the game does
    player_index = rng.randint(0, NUM_MOVES - 1)
    enemy_index = rng.randint(0, NUM_MOVES - 1)
    game.poke("wPlayerSelectedMove", player_moves[player_index])
    game.poke("wPlayerMoveListIndex", player_index)
    game.poke("wEnemySelectedMove", enemy_moves[enemy_index])
    game.poke("wEnemyMoveListIndex", enemy_index)
    game.poke(H_WHOSETURN, 0)
    game.call("GetCurrentMove")
    game.poke(H_WHOSETURN, 1)
    game.call("GetCurrentMove")

    game.queue_random(*[rng.randint(0, 255) for _ in range(64)])


def run(game, case):
    game.poke(H_WHOSETURN, 0 if case == "player" else 1)
    try:
        out = game.call(ROUTINES[case], max_frames=600)
    except HarnessError as error:
        if "more random values" not in str(error):
            raise
        return {"error": "random queue exhausted", "random_used": game.random_used()}
    # The battle loop only reads b after a move (0 = the defender fainted);
    # everything else a turn does is in RAM, which compare_builds checks in
    # full. The other registers are leftovers, often pointers into ROM that
    # shift whenever code moves, so comparing them would flag layout changes
    # as behaviour changes.
    return {
        "b": out["b"],
        "random_used": game.random_used(),
    }


def cases():
    return [("player", "player"), ("enemy", "enemy")]
