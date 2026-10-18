"""Check that a refactor didn't change behaviour.

Builds the ROM from a base git ref and from the working tree, then runs every
suite in tests/suites on both with the same random seeds. For each case it
compares the routine's results and, when the two builds share a RAM layout,
every byte of WRAM and HRAM afterwards.

    python3 tests/compare_builds.py --base master --seeds 2000

Needs RGBDS 0.6.0 on PATH, or pass --rgbds /path/to/rgbds/ (with the trailing
slash, as for make).
"""

import argparse
import bisect
import importlib
import os
import pkgutil
import random
import shutil
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import suites  # noqa: E402
from harness import HRAM, REPO_ROOT, WRAM, Game, load_symbols  # noqa: E402

ROM = "pokered.gbc"


def build(tree, rgbds):
    cmd = ["make", ROM]
    if rgbds:
        cmd.append(f"RGBDS={rgbds}")
    result = subprocess.run(cmd, cwd=tree, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"build failed in {tree}:\n{result.stdout}{result.stderr}")
    return os.path.join(tree, ROM)


def ram_symbols(sym_path):
    """Name -> address for every WRAM/HRAM symbol."""
    out = {}
    for name, (_, addr) in load_symbols(sym_path).items():
        if WRAM[0] <= addr < WRAM[1] or HRAM[0] <= addr < HRAM[1]:
            out[name] = addr
    return out


def same_ram_layout(old_sym, new_sym):
    old, new = ram_symbols(old_sym), ram_symbols(new_sym)
    shared = old.keys() & new.keys()
    moved = sorted(n for n in shared if old[n] != new[n])
    return not moved, moved


def new_only_ram(old_sym, new_sym):
    """Snapshot indexes of RAM variables that only exist in the new build.

    There is nothing to compare them against, so they are skipped. Each new
    variable is assumed to run up to the next symbol's address.
    """
    old, new = ram_symbols(old_sym), ram_symbols(new_sym)
    starts = sorted(set(new.values()))
    skip = set()
    for name in new.keys() - old.keys():
        if "." in name:
            continue
        start = new[name]
        if start in old.values():
            continue  # a new name for RAM that existed before
        nxt = next((a for a in starts if a > start), start + 1)
        skip.update(range(start, nxt))
    wram_len = WRAM[1] - WRAM[0]
    indexes = set()
    for addr in skip:
        if WRAM[0] <= addr < WRAM[1]:
            indexes.add(addr - WRAM[0])
        elif HRAM[0] <= addr < HRAM[1]:
            indexes.add(wram_len + addr - HRAM[0])
    return indexes


def snapshot_addr(index):
    wram_len = WRAM[1] - WRAM[0]
    return WRAM[0] + index if index < wram_len else HRAM[0] + index - wram_len


def describe(addr, sym_path, _cache={}):
    if sym_path not in _cache:
        pairs = sorted((a, n) for n, a in ram_symbols(sym_path).items() if "." not in n)
        _cache[sym_path] = ([a for a, _ in pairs], [n for _, n in pairs])
    addrs, names = _cache[sym_path]
    i = bisect.bisect_right(addrs, addr) - 1
    if i < 0:
        return f"${addr:04x}"
    offset = addr - addrs[i]
    return f"${addr:04x} ({names[i]}{f'+{offset}' if offset else ''})"


def load_suites(only):
    found = []
    for info in pkgutil.iter_modules(suites.__path__):
        module = importlib.import_module(f"suites.{info.name}")
        if only and module.NAME not in only:
            continue
        found.append(module)
    return found


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--base", default="HEAD", help="git ref to compare against (default: HEAD)")
    parser.add_argument("--seeds", type=int, default=1000, help="random states per case (default: 1000)")
    parser.add_argument("--suite", action="append", help="only run this suite (repeatable)")
    parser.add_argument("--rgbds", default=os.environ.get("RGBDS", ""), help="RGBDS install prefix")
    parser.add_argument("--keep", action="store_true", help="keep the base build's worktree")
    args = parser.parse_args()

    workdir = tempfile.mkdtemp(prefix="shin-compare-")
    base_tree = os.path.join(workdir, "base")
    subprocess.run(["git", "worktree", "add", "--detach", base_tree, args.base],
                   cwd=REPO_ROOT, check=True, capture_output=True)
    try:
        print(f"building base ({args.base}) ...")
        old_rom = build(base_tree, args.rgbds)
        print("building working tree ...")
        new_rom = build(REPO_ROOT, args.rgbds)

        old_sym = os.path.splitext(old_rom)[0] + ".sym"
        new_sym = os.path.splitext(new_rom)[0] + ".sym"
        compare_ram, moved = same_ram_layout(old_sym, new_sym)
        skip = new_only_ram(old_sym, new_sym) if compare_ram else set()
        if skip:
            names = sorted(n for n in ram_symbols(new_sym).keys() - ram_symbols(old_sym).keys() if "." not in n)
            print(f"skipping RAM that only exists in the new build: {', '.join(names)}")
        if not compare_ram:
            print(f"RAM layout changed ({len(moved)} symbols moved, e.g. {', '.join(moved[:5])}); "
                  "comparing routine results only")

        old, new = Game(old_rom), Game(new_rom)
        failures = 0
        for suite in load_suites(args.suite):
            for label, case in suite.cases():
                bad = 0
                for seed in range(args.seeds):
                    results = []
                    for game in (old, new):
                        game.reset()
                        suite.setup(game, random.Random(seed))
                        out = suite.run(game, case)
                        results.append((out, game.snapshot_ram() if compare_ram else None))
                    (old_out, old_ram), (new_out, new_ram) = results

                    problems = []
                    if old_out != new_out:
                        diffs = {k: (old_out[k], new_out.get(k)) for k in old_out if old_out[k] != new_out.get(k)}
                        problems.append(f"results differ (old, new): {diffs}")
                    if compare_ram and old_ram != new_ram:
                        changed = [i for i, (x, y) in enumerate(zip(old_ram, new_ram)) if x != y and i not in skip]
                    else:
                        changed = []
                    if changed:
                        where = ", ".join(
                            f"{describe(snapshot_addr(i), new_sym)} {old_ram[i]:#04x}->{new_ram[i]:#04x}"
                            for i in changed[:6]
                        )
                        problems.append(f"{len(changed)} RAM bytes differ: {where}")
                    if problems:
                        bad += 1
                        if bad <= 5:
                            print(f"  FAIL {suite.NAME}/{label} seed {seed}: " + "; ".join(problems))
                status = "ok" if not bad else f"{bad} FAILED"
                print(f"{suite.NAME}/{label}: {args.seeds} states, {status}")
                failures += bad
        print("all builds match" if not failures else f"{failures} mismatches")
        return 1 if failures else 0
    finally:
        if not args.keep:
            subprocess.run(["git", "worktree", "remove", "--force", base_tree], cwd=REPO_ROOT, capture_output=True)
            shutil.rmtree(workdir, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
