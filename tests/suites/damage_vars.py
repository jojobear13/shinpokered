"""Randomized battle states for GetDamageVarsForPlayerAttack/EnemyAttack.

setup() fills every piece of state those routines can read: both battle
structs, both party blocks, the selected moves, screens, critical hits, stat
experience pointers for trainer battles, and link battle state.
"""

import os
import re

from harness import REPO_ROOT

NAME = "damage_vars"

PARTY_LENGTH = 6
MOVE_STRUCT_LEN = 6
NUM_MOVES = 4
# attack, defense, speed, special attack, accuracy, evasion, special defense
NUM_USED_STAT_MODS = 7
STATS = ("MaxHP", "Attack", "Defense", "Speed", "SpecialAttack", "SpecialDefense")


# struct sizes and offsets come from the symbols, so they follow layout changes
def battle_struct_len(game):
    return game.addr("wBattleMonPP") + NUM_MOVES - game.addr("wBattleMon")


def party_struct_len(game):
    return game.addr("wPartyMon2") - game.addr("wPartyMon1")


def party_offset(game, field):
    return game.addr("wPartyMon1" + field) - game.addr("wPartyMon1")

FIRE = 0x14
HAS_LIGHT_SCREEN_UP = 1
HAS_REFLECT_UP = 2
LINK_STATE_BATTLING = 4

ROUTINES = {
    "player": "GetDamageVarsForPlayerAttack",
    "enemy": "GetDamageVarsForEnemyAttack",
}


# species ids that aren't real Pokemon: the Pokemon Tower ghost and the
# fossil pictures can only ever be the enemy's mon
ENEMY_ONLY_SPECIES = ("MON_GHOST", "FOSSIL_KABUTOPS", "FOSSIL_AERODACTYL")


def _species_ids(include_enemy_only):
    path = os.path.join(REPO_ROOT, "constants", "pokemon_constants.asm")
    ids = []
    for line in open(path):
        m = re.match(r"\s*const (\w+)\s*; \$([0-9A-Fa-f]+)", line)
        if not m or m.group(1).startswith("MISSINGNO"):
            continue
        if m.group(1) in ENEMY_ONLY_SPECIES and not include_enemy_only:
            continue
        ids.append(int(m.group(2), 16))
    return ids


SPECIES = _species_ids(include_enemy_only=False)


def _categories():
    """Each move's category (PHYSICAL, SPECIAL or STATUS), by move id - 1."""
    path = os.path.join(REPO_ROOT, "data", "move_categories.asm")
    with open(path) as f:
        return [m.group(1) for m in re.finditer(r"^\s*db (\w+)", f.read(), re.M)]


CATEGORIES = _categories()


def category(move_id):
    """What GetMoveCategory returns: STATUS for ids that aren't moves."""
    if 1 <= move_id <= len(CATEGORIES):
        return CATEGORIES[move_id - 1]
    return "STATUS"


ENEMY_SPECIES = _species_ids(include_enemy_only=True)

# type ids that exist in the type table, including both sides of the
# physical/special boundary at FIRE
TYPES = [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x07, 0x08, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A]


def stat(rng):
    """A 16-bit stat, weighted toward realistic values but covering the
    edges that matter here: 0, the 255/256 scaling boundary, and 999+."""
    roll = rng.random()
    if roll < 0.55:
        return rng.randint(1, 255)
    if roll < 0.85:
        return rng.randint(256, 999)
    return rng.choice([0, 1, 255, 256, 511, 512, 998, 999, 1000, 1023, 1024, 0xFFFF, rng.randint(0, 0xFFFF)])


def _fill(game, rng, symbol, length):
    game.poke(symbol, *[rng.randint(0, 255) for _ in range(length)])


def _battle_mon(game, rng, prefix):
    _fill(game, rng, prefix, battle_struct_len(game))
    game.poke(prefix + "Species", rng.choice(ENEMY_SPECIES if prefix == "wEnemyMon" else SPECIES))
    game.poke(prefix + "Level", rng.randint(1, 100))
    for name in STATS:
        game.poke16(prefix + name, stat(rng))


def _party(game, rng, prefix):
    length = party_struct_len(game)
    for i in range(PARTY_LENGTH):
        base = game.addr(prefix) + i * length
        game.poke(base, *[rng.randint(0, 255) for _ in range(length)])
        game.poke(base, rng.choice(SPECIES))
        game.poke(base + party_offset(game, "Level"), rng.randint(1, 100))
        for name in STATS:
            game.poke16(base + party_offset(game, name), stat(rng))


def _move(game, rng, prefix):
    _fill(game, rng, prefix + "Num", MOVE_STRUCT_LEN)
    game.poke(prefix + "Num", rng.randint(1, len(CATEGORIES)))  # a real move, so it has a category
    power = 0 if rng.random() < 0.08 else rng.choice([rng.randint(1, 255), 40, 80, 120, 150])
    game.poke(prefix + "Power", power)
    game.poke(prefix + "Type", rng.choice(TYPES))


def setup(game, rng):
    """Write a random battle state. Uses only symbol names, so the same rng
    seed produces the same state on two different builds."""
    _battle_mon(game, rng, "wBattleMon")
    _battle_mon(game, rng, "wEnemyMon")
    _party(game, rng, "wPartyMons")
    _party(game, rng, "wEnemyMons")
    _move(game, rng, "wPlayerMove")
    _move(game, rng, "wEnemyMove")

    for side in ("wPlayerBattleStatus", "wEnemyBattleStatus"):
        for i in (1, 2):
            game.poke(f"{side}{i}", rng.randint(0, 255))
        screens = rng.choice([0, 1 << HAS_LIGHT_SCREEN_UP, 1 << HAS_REFLECT_UP, 0b110])
        game.poke(f"{side}3", (rng.randint(0, 255) & ~0b110) | screens)
    _fill(game, rng, "wPlayerMonAttackMod", NUM_USED_STAT_MODS)
    _fill(game, rng, "wEnemyMonAttackMod", NUM_USED_STAT_MODS)

    game.poke("wCriticalHitOrOHKO", rng.choice([0, 0, 1]))
    game.poke("wPlayerMonNumber", rng.randint(0, PARTY_LENGTH - 1))
    game.poke("wPartyCount", PARTY_LENGTH)
    game.poke("wEnemyPartyCount", PARTY_LENGTH)
    game.poke("wEnemyMonPartyPos", rng.randint(0, PARTY_LENGTH - 1))
    game.poke("wIsInBattle", rng.choice([1, 2]))
    game.poke("wLinkState", LINK_STATE_BATTLING if rng.random() < 0.15 else 0)

    # trainer battles read stat exp through this pointer (HPExp - 1 of the
    # enemy's party mon)
    pos = rng.randint(0, PARTY_LENGTH - 1)
    ptr = game.addr("wEnemyMons") + pos * party_struct_len(game) + party_offset(game, "HPExp") - 1
    game.poke16("wUnusedD153", ptr)

    game.poke16("wDamage", rng.randint(0, 0xFFFF))


def run(game, side):
    """Call the routine for one side and collect everything it produces."""
    out = game.call(ROUTINES[side])
    return {
        "z": out["z"],
        "a": out["a"],
        "b": out["b"],
        "c": out["c"],
        "d": out["d"],
        "e": out["e"],
        "hl": out["hl"],
        "wDamage": game.peek16("wDamage"),
        "wCriticalHitOrOHKO": game.peek("wCriticalHitOrOHKO"),
    }


def cases():
    """(label, side) pairs; each is run once per random seed."""
    return [("player", "player"), ("enemy", "enemy")]
