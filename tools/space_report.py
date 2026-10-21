#!/usr/bin/env python3
"""Free space per bank from rgblink's .map files.

Usage: tools/space_report.py [map ...] [--under N]
Prints each bank's slack (unused bytes) for every map given (default: all
*.map in the current directory), and with --under N only banks with fewer
than N bytes free.
"""
import glob, re, sys

args = sys.argv[1:]
under = None
if "--under" in args:
    i = args.index("--under")
    under = int(args[i + 1])
    del args[i:i + 2]
maps = args or sorted(glob.glob("*.map"))


def banks(path):
    out = {}
    bank = None
    for line in open(path):
        m = re.match(r"(\w+) bank #(\d+):", line)
        if m:
            bank = (m.group(1), int(m.group(2)))
        m = re.match(r"\s*SLACK: \$([0-9a-f]+) bytes", line)
        if m and bank:
            out[bank] = int(m.group(1), 16)
    return out


all_banks = {p: banks(p) for p in maps}
keys = sorted(set(k for b in all_banks.values() for k in b))
print("bank".ljust(10) + "".join(p.replace(".map", "")[:14].rjust(15) for p in maps))
for k in keys:
    vals = [all_banks[p].get(k) for p in maps]
    if under is not None and all(v is None or v >= under for v in vals):
        continue
    name = f"{k[0]} {k[1]:02X}" if k[0] != "ROMX" else f"bank {k[1]:02X}"
    print(name.ljust(10) + "".join(("-" if v is None else str(v)).rjust(15) for v in vals))
