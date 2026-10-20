"""Randomized states for ApplyAttackTo{Enemy,Player}Pokemon and the
ApplyDamageTo{Enemy,Player}Pokemon entry points.

Covers ordinary damage, OHKO moves, Super Fang, the fixed-damage moves
(Seismic Toss, Night Shade, Sonic Boom, Dragon Rage, Psywave), trapping moves
clearing Hyper Beam recharge, substitutes, and damage larger than the
target's HP. The HP bar animation runs with DelayFrame skipped.
"""

import os
import re

from harness import REPO_ROOT, HarnessError
from suites.damage_vars import battle_struct_len, ENEMY_SPECIES, SPECIES

NAME = "apply_attack"

HAS_SUBSTITUTE_UP = 4
NEEDS_TO_RECHARGE = 5
NAME_LENGTH = 11
TERMINATOR = 0x50  # "@"


def _constants(filename, names):
    values = {}
    path = os.path.join(REPO_ROOT, "constants", filename)
    for line in open(path):
        # the comments give each value in hex, with or without a "$"
        m = re.match(r"\s*const (\w+)\s*; \$?([0-9A-Fa-f]+)", line)
        if m and m.group(1) in names:
            values[m.group(1)] = int(m.group(2), 16)
    missing = set(names) - values.keys()
    assert not missing, missing
    return values


EFFECTS = _constants("move_effect_constants.asm",
                     ["OHKO_EFFECT", "SUPER_FANG_EFFECT", "SPECIAL_DAMAGE_EFFECT", "TRAPPING_EFFECT"])
def _hram(name):
    path = os.path.join(REPO_ROOT, "hram.asm")
    for line in open(path):
        m = re.match(rf"{name}\s+EQU\s+\$([0-9A-Fa-f]+)", line)
        if m:
            return int(m.group(1), 16)
    raise KeyError(name)


H_WHOSETURN = _hram("H_WHOSETURN")
MOVES = _constants("move_constants.asm",
                   ["SEISMIC_TOSS", "NIGHT_SHADE", "SONICBOOM", "DRAGON_RAGE", "PSYWAVE"])

ROUTINES = {
    "attack enemy": "ApplyAttackToEnemyPokemon",
    "attack player": "ApplyAttackToPlayerPokemon",
    "damage enemy": "ApplyDamageToEnemyPokemon",
    "damage player": "ApplyDamageToPlayerPokemon",
}


def _hp(rng):
    """HP within the game's 999 stat cap (the HP bar animates one point at
    a time, so absurd values just make a call very slow)."""
    roll = rng.random()
    if roll < 0.1:
        return rng.choice([0, 1, 2])
    if roll < 0.9:
        return rng.randint(1, 400)
    return rng.choice([255, 256, 703, 999, rng.randint(0, 999)])


def _mon(game, rng, prefix, nick):
    game.poke(prefix, *[rng.randint(0, 255) for _ in range(battle_struct_len(game))])
    game.poke(prefix + "Species", rng.choice(ENEMY_SPECIES if prefix == "wEnemyMon" else SPECIES))
    game.poke(prefix + "Level", rng.randint(1, 100))
    game.poke(prefix + "CatchRate", 0)  # no held item: items have their own tests
    max_hp = max(_hp(rng), 1)
    game.poke16(prefix + "MaxHP", max_hp)
    game.poke16(prefix + "HP", rng.randint(0, max_hp) if rng.random() < 0.9 else _hp(rng))
    # the HUD prints the nickname, so it needs a terminator
    name = [rng.randint(0x80, 0x99) for _ in range(rng.randint(1, NAME_LENGTH - 1))]
    game.poke(nick, *(name + [TERMINATOR]))


def _move(game, rng, prefix):
    game.poke(prefix + "Num", *[rng.randint(0, 255) for _ in range(6)])
    roll = rng.random()
    if roll < 0.15:
        effect = EFFECTS["SPECIAL_DAMAGE_EFFECT"]
        game.poke(prefix + "Num", rng.choice(list(MOVES.values()) + [rng.randint(1, 165)]))
    elif roll < 0.25:
        effect = EFFECTS["SUPER_FANG_EFFECT"]
    elif roll < 0.32:
        effect = EFFECTS["OHKO_EFFECT"]
    elif roll < 0.42:
        effect = EFFECTS["TRAPPING_EFFECT"]
    else:
        effect = rng.randint(0, 0x56)
    game.poke(prefix + "Effect", effect)
    game.poke(prefix + "Power", 0 if rng.random() < 0.1 else rng.randint(1, 255))


def setup(game, rng):
    game.skip_delays()
    game.auto_buttons()  # the substitute takes damage with a message
    _mon(game, rng, "wBattleMon", "wBattleMonNick")
    _mon(game, rng, "wEnemyMon", "wEnemyMonNick")
    _move(game, rng, "wPlayerMove")
    _move(game, rng, "wEnemyMove")
    for side in ("wPlayerBattleStatus", "wEnemyBattleStatus"):
        for i in (1, 2, 3):
            game.poke(f"{side}{i}", rng.randint(0, 255))
    for side in ("wPlayerSubstituteHP", "wEnemySubstituteHP"):
        game.poke(side, rng.randint(0, 255))
    game.poke(H_WHOSETURN, rng.randint(0, 1))
    game.poke("wLinkState", 0)
    damage = rng.choice([0, rng.randint(1, 50), rng.randint(1, 400), rng.randint(0, 0xFFFF)])
    game.poke16("wDamage", damage)

    # Psywave rerolls until it gets a value in range; give it plenty to pick
    # from, mostly small enough to be accepted
    game.queue_random(*[rng.randint(0, 120) if rng.random() < 0.8 else rng.randint(0, 255) for _ in range(32)])


def run(game, case):
    try:
        out = game.call(ROUTINES[case])
    except HarnessError as error:
        # running out of queued randomness is a result too: both builds
        # must run out at the same point
        if "random" not in str(error):
            raise
        return {"error": "random queue exhausted", "random_used": game.random_used()}
    return {
        "a": out["a"],
        "f": out["f"],
        "bc": out["bc"],
        "de": out["de"],
        "hl": out["hl"],
        "random_used": game.random_used(),
    }


def cases():
    return [(name, name) for name in ROUTINES]
