"""Breeding soak (verification plan, phase 3): eggs from many random pairs
that can breed, made with the game's own random numbers, each checked: the
mother's (non-Ditto parent's) first form (or the other Nidoran), level 1,
no HP, its egg cycles, real moves with full PP and none twice or after a
gap, each one the egg may have, IVs 0-31 and an ability slot of 0 or 1.
Not part of `make test`: run as
    python3 tests/soak_breeding.py SEED COUNT"""

import os
import random
import sys

sys.path.insert(0, os.path.dirname(__file__))
from test_breeding import (BreedingTest, GROUPS, CYCLES, BASE, EGG_MOVES, BOX, MON, DAY_CARE_LEN,  # noqa: E402
                           unpack)
from test_moves_screen import MOVES, SPECIES, LEARNSETS, base_stats  # noqa: E402
from test_held_items import ITEMS  # noqa: E402

NAMES = {v: k for k, v in SPECIES.items()}
NIDORAN = {"NIDORAN_M", "NIDORAN_F"}


def can_breed(a, b):
    ga, gb = set(GROUPS[a]), set(GROUPS[b])
    return bool(ga & gb) or "EGG_DITTO" in ga | gb


def main(seed, count):
    rng = random.Random(seed)
    BreedingTest.setUpClass()
    t = BreedingTest()
    g = t.game
    names = [n for n in GROUPS if "EGG_NONE" not in GROUPS[n]]
    made = bad = 0
    for i in range(count):
        t.setUp()
        a = rng.choice(names)
        b = rng.choice([n for n in names if can_breed(a, n) and not (n == "DITTO" == a)])
        parents = []
        for slot, name in enumerate((a, b)):
            lv_moves = sorted({m for lv, m in LEARNSETS.get(name, [])} | set(EGG_MOVES.get(name, [])))
            moves = [k for k, v in MOVES.items() if v in rng.sample(lv_moves, min(4, len(lv_moves)))] \
                if lv_moves else []
            item = rng.choice([0, 0, ITEMS["EVERSTONE"]])
            ivs = [rng.randint(0, 31) for _ in range(6)]
            t.parent(slot, name, female=rng.random() < 0.5 if name != "DITTO" else None, ivs=ivs,
                     ability=rng.randint(0, 1), item=item, moves=moves,
                     otid=(0x12, 0x34) if rng.random() < 0.5 else (0x56, 0x78))
            parents.append((name, [MOVES[m] for m in moves]))
        chance = g.call("DayCareCompatibility", max_frames=200)["a"]
        if not chance:
            continue
        mother = g.peek("wBreedMother")
        g.call("DayCareMakeEgg", max_frames=4000)
        bank, addr = g.symbols["sDayCareEggName"]
        egg = [g.memory[bank, addr + k] for k in range(DAY_CARE_LEN)]
        mon = egg[MON:]
        made += 1
        problems = []
        mom = parents[mother][0] if parents[mother][0] != "DITTO" else parents[1 - mother][0]
        want = {BASE[mom]} | (NIDORAN if BASE[mom] in NIDORAN else set())
        species = NAMES.get(mon[BOX["species"]], hex(mon[BOX["species"]]))
        if species not in want:
            problems.append(f"species {species}, want {want}")
        if mon[BOX["level"]] != 1:
            problems.append(f"level {mon[BOX['level']]}")
        if mon[BOX["hp"]:BOX["hp"] + 2] != [0, 0]:
            problems.append("has HP")
        if species in CYCLES and mon[BOX["item"]] != CYCLES[species]:
            problems.append(f"cycles {mon[BOX['item']]} want {CYCLES[species]}")
        moves = mon[BOX["moves"]:BOX["moves"] + 4]
        known = [m for m in moves if m]
        if moves[:len(known)] != known:
            problems.append(f"gap in moves {moves}")
        if len(set(known)) != len(known):
            problems.append(f"move twice {moves}")
        if species in SPECIES:
            fname = {"NIDORAN_M": "nidoranm", "NIDORAN_F": "nidoranf", "MR_MIME": "mrmime"}.get(species, species)
            starting, _ = base_stats(fname)
            allowed = set(m for m in starting if m) | {m for lv, m in LEARNSETS.get(species, [])} | set(EGG_MOVES.get(species, []))
            for m in known:
                if m not in allowed:
                    problems.append(f"move {m} not the egg's")
        for k, m in enumerate(moves):
            if m:
                g.call("MovesGetData", a=m, max_frames=50)
                if mon[BOX["pp"] + k] != g.peek("wMovesData", 6)[5]:
                    problems.append(f"PP of move {m}")
        ivs, flags = unpack(mon[BOX["ivs"]:BOX["ivs"] + 4])
        if flags not in (0, 1):
            problems.append(f"ability slot {flags}")
        if problems:
            bad += 1
            print(f"#{i} {a} x {b} (mother {mother}) -> {species}: {problems}", flush=True)
    print(f"BREEDING SOAK seed {seed}: {made} eggs, {bad} with problems", flush=True)


if __name__ == "__main__":
    main(int(sys.argv[1]), int(sys.argv[2]))
