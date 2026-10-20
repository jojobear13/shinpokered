"""Randomized states for CheckPlayerStatusConditions / CheckEnemyStatusConditions.

These run at the start of each side's move and decide whether the move goes
ahead: sleep, freeze, being trapped, flinching, Hyper Beam recharge, Disable,
confusion (including hurting itself), paralysis, Bide, Thrash, multi-turn
moves and Rage. Statuses are much more common here than in move_execution.

A routine returns with the zero flag set and hl pointing at where the move
flow should continue, or with it clear to carry on normally. hl is a ROM
address, which moves whenever code moves, so it is compared by label name.
"""

from harness import HarnessError
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN

NAME = "status_checks"

ROUTINES = {"player": "CheckPlayerStatusConditions", "enemy": "CheckEnemyStatusConditions"}
PREFIX = {"player": ("wBattleMon", "wPlayer"), "enemy": ("wEnemyMon", "wEnemy")}

SLP_MASK = 0b111
FRZ = 1 << 5
PAR = 1 << 6


def _status(rng):
    roll = rng.random()
    if roll < 0.35:
        return 0
    if roll < 0.6:
        return rng.randint(1, SLP_MASK)  # asleep, 1-7 turns
    return rng.choice([FRZ, PAR, PAR, 1 << 3, 1 << 4])  # freeze, paralysis, poison, burn


def setup(game, rng):
    mx.setup(game, rng)
    for case in ("player", "enemy"):
        mon, side = PREFIX[case]
        game.poke(mon + "Status", _status(rng))
        # one to three of each status byte's flags, often none
        for i in (1, 2, 3):
            flags = 0
            for _ in range(rng.choice([0, 0, 1, 1, 2, 3])):
                flags |= 1 << rng.randint(0, 7)
            game.poke(f"{side}BattleStatus{i}", flags)
        for name in ("NumAttacksLeft", "ConfusedCounter", "DisabledMoveNumber", "DisabledMove",
                     "BideAccumulatedDamage", "NumHits"):
            symbol = f"{side}{name}"
            if symbol in game.symbols:
                game.poke(symbol, rng.choice([0, 1, 2, rng.randint(0, 7)]))


def _label(game, routine, addr):
    bank = game.bank(routine)
    names = sorted(n for n, (b, a) in game.symbols.items() if a == addr and b in (bank, 0))
    return names[0] if names else f"unlabelled {addr:#06x}"


def run(game, case):
    game.poke(H_WHOSETURN, 0 if case == "player" else 1)
    routine = ROUTINES[case]
    try:
        out = game.call(routine, max_frames=600)
    except HarnessError as error:
        if "more random values" not in str(error):
            raise
        return {"error": "random queue exhausted", "random_used": game.random_used()}
    result = {"z": out["z"], "random_used": game.random_used()}
    if out["z"]:
        result["continue_at"] = _label(game, routine, out["hl"])
    return result


def cases():
    return [("player", "player"), ("enemy", "enemy")]
