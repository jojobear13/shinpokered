"""Link soak (verification plan, phase 3): the link mirror test's one-turn
check on many more seeds, with random abilities, moves and held items on
both sides. Not part of `make test` (it is slow): run as
    python3 tests/soak_link.py FIRST_SEED COUNT
and it prints each seed where the two games disagree."""

import random
import sys
import unittest

sys.path.insert(0, __import__("os").path.dirname(__file__))
from test_link_mirror import LinkMirrorTest  # noqa: E402
from test_held_items import ITEMS  # noqa: E402

HELD = [v for k, v in ITEMS.items() if ITEMS["BLACK_BELT"] <= v < ITEMS["DEXREPEL"]]
HELD_NAMES = {v: k for k, v in ITEMS.items()}


def main(first, count):
    LinkMirrorTest.setUpClass()
    t = LinkMirrorTest()
    bad = compared = 0
    for seed in range(first, first + count):
        rng = random.Random(seed)
        held = tuple(HELD_NAMES[rng.choice(HELD)] if rng.random() < 0.5 else 0 for _ in range(2))
        try:
            results = t.mirror(seed, held=held)
        except Exception as error:
            print(f"seed {seed} held {held}: error {error}", flush=True)
            bad += 1
            continue
        if (results[0] is None) != (results[1] is None):
            print(f"seed {seed} held {held}: only one game called Random: {results}", flush=True)
            bad += 1
            continue
        if results[0] is not None:
            continue
        compared += 1
        sa = t.without_pp(t.a, t.state(t.a, 0, parties=False))
        sb = t.without_pp(t.b, t.state(t.b, 1, parties=False))
        if sa != sb:
            diff = [k for k in sa if sa[k] != sb.get(k)]
            print(f"seed {seed} held {held}: games disagree on {diff}", flush=True)
            bad += 1
    print(f"LINK SOAK seeds {first}..{first + count - 1}: compared {compared}, disagreements {bad}", flush=True)


if __name__ == "__main__":
    main(int(sys.argv[1]), int(sys.argv[2]))
