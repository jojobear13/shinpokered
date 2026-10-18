"""Check that a refactor didn't change behaviour.

Builds the ROM from a base git ref and from the working tree, then runs every
suite in tests/suites on both with the same random seeds. For each case it
compares the routine's results and every byte of WRAM and HRAM afterwards.

RAM is matched by variable name, so a variable that moved is compared at its
new address. Variables that exist in only one of the two builds are skipped
(and listed), since there is nothing to compare them against. HRAM variables
are constants in hram.asm rather than labels, so they are read from there.

    python3 tests/compare_builds.py --base master --seeds 2000

Needs RGBDS 0.6.0 on PATH, or pass --rgbds /path/to/rgbds/ (with the trailing
slash, as for make).
"""

import argparse
import bisect
import re
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

# Variables whose value between routines means nothing, because every routine
# that reads one sets it first. A refactor may leave a different value in
# them, so they are not compared. Keep this list short and justified.
SCRATCH = {
    # each merged battle routine sets it on entry (docs/design_brief.md,
    # decision 1)
    "hBattleSide",
}


def build(tree, rgbds):
    cmd = ["make", ROM]
    if rgbds:
        cmd.append(f"RGBDS={rgbds}")
    result = subprocess.run(cmd, cwd=tree, capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit(f"build failed in {tree}:\n{result.stdout}{result.stderr}")
    return os.path.join(tree, ROM)


HRAM_EQU = re.compile(r"^(\w+)\s+EQU\s+\$(FF[0-9A-Fa-f]{2})\b", re.IGNORECASE)


def ram_symbols(sym_path):
    """Name -> address for every WRAM/HRAM variable in a build: labels from
    the .sym file plus the HRAM constants in that tree's hram.asm."""
    out = {}
    for name, (_, addr) in load_symbols(sym_path).items():
        if "." in name:
            continue
        if WRAM[0] <= addr < WRAM[1] or HRAM[0] <= addr < HRAM[1]:
            out[name] = addr
    hram_asm = os.path.join(os.path.dirname(sym_path), "hram.asm")
    if os.path.exists(hram_asm):
        for line in open(hram_asm, encoding="utf-8", errors="ignore"):
            m = HRAM_EQU.match(line.strip())
            if m:
                addr = int(m.group(2), 16)
                if HRAM[0] <= addr < HRAM[1]:
                    out.setdefault(m.group(1), addr)
    return out


def snapshot_index(addr):
    wram_len = WRAM[1] - WRAM[0]
    if WRAM[0] <= addr < WRAM[1]:
        return addr - WRAM[0]
    return wram_len + addr - HRAM[0]


def _regions(symbols):
    """address -> (names starting there, length up to the next variable),
    within each of WRAM and HRAM."""
    by_addr = {}
    for name, addr in symbols.items():
        by_addr.setdefault(addr, []).append(name)
    out = {}
    for lo, hi in (WRAM, HRAM):
        starts = sorted(a for a in by_addr if lo <= a < hi)
        for i, a in enumerate(starts):
            end = starts[i + 1] if i + 1 < len(starts) else hi
            out[a] = (sorted(by_addr[a]), end - a)
    return out


def ram_pairs(old_sym, new_sym):
    """Which old snapshot byte to compare with which new one.

    Returns (pairs, skipped_old, skipped_new, moved): pairs is a list of
    (old index, new index); the others name the variables that were skipped
    because only one build has them, and the shared ones that moved.
    """
    old, new = ram_symbols(old_sym), ram_symbols(new_sym)
    old_regions, new_regions = _regions(old), _regions(new)
    shared = old.keys() & new.keys()
    moved = sorted(n for n in shared if old[n] != new[n])

    scratch_new = set()
    for name in SCRATCH:
        if name in new:
            start = new[name]
            scratch_new.update(range(start, start + new_regions[start][1]))

    pairs = []
    covered_new = set()
    skipped_old, skipped_new = set(), set()
    for lo, hi in (WRAM, HRAM):
        owner = None  # (old start, names, length) of the region an address is in
        for addr in range(lo, hi):
            if addr in old_regions:
                names, length = old_regions[addr]
                owner = (addr, names, length)
            if owner is None:
                target = addr  # before the first variable: compare in place
            else:
                start, names, length = owner
                both = [n for n in names if n in new]
                if not both:
                    skipped_old.update(names)
                    continue
                name = both[0]
                offset = addr - start
                new_start = new[name]
                new_length = new_regions[new_start][1]
                if offset >= new_length:
                    continue  # the variable shrank; the tail no longer exists
                target = new_start + offset
            covered_new.add(target)
            if target in scratch_new:
                continue
            pairs.append((snapshot_index(addr), snapshot_index(target)))

    # new variables at addresses nothing old maps onto
    for addr, (names, length) in new_regions.items():
        if any(n in SCRATCH for n in names):
            continue
        if not any(n in old for n in names):
            if not any(a in covered_new for a in range(addr, addr + length)):
                skipped_new.update(names)
    return pairs, sorted(skipped_old), sorted(skipped_new), moved


def snapshot_addr(index):
    wram_len = WRAM[1] - WRAM[0]
    return WRAM[0] + index if index < wram_len else HRAM[0] + index - wram_len


def describe(addr, sym_path, _cache={}):
    if sym_path not in _cache:
        pairs = sorted((a, n) for n, a in ram_symbols(sym_path).items())
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
        pairs, skipped_old, skipped_new, moved = ram_pairs(old_sym, new_sym)
        if moved:
            print(f"{len(moved)} RAM variables moved; comparing them at their new addresses "
                  f"(e.g. {', '.join(moved[:5])})")
        if skipped_old:
            print(f"skipping RAM that only exists in the base build: {', '.join(skipped_old)}")
        if skipped_new:
            print(f"skipping RAM that only exists in the new build: {', '.join(skipped_new)}")
        print(f"not comparing scratch variables: {', '.join(sorted(SCRATCH))}")

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
                        results.append((out, game.snapshot_ram()))
                    (old_out, old_ram), (new_out, new_ram) = results

                    problems = []
                    if old_out != new_out:
                        diffs = {k: (old_out[k], new_out.get(k)) for k in old_out if old_out[k] != new_out.get(k)}
                        problems.append(f"results differ (old, new): {diffs}")
                    changed = [(i, j) for i, j in pairs if old_ram[i] != new_ram[j]]
                    if changed:
                        where = ", ".join(
                            f"{describe(snapshot_addr(j), new_sym)} {old_ram[i]:#04x}->{new_ram[j]:#04x}"
                            for i, j in changed[:6]
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
