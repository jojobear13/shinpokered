#!/usr/bin/env python3
"""Lines of dialogue too wide for the 18-column text box.

Follows text/line/cont/para/next and the TX_RAM, TX_NUM and TX_BCD inserts
that continue a line, and counts each visible line's width: "#" is POKé,
<PLAYER> and <RIVAL> 7, <USER>/<TARGET> "Enemy " and a name (16), a TX_RAM
name 10 and a TX_NUM its digits. Prints lines over 18 columns: "over" when
the literal text alone is too wide, "maybe" when only the inserts' longest
case is.

Usage: tools/text_lint.py [files...]   (default: every .asm under the repo)
"""
import glob, re, sys

WIDTH = 18
# expansions wider than one tile, and control codes with no tile
EXPAND = {"#": 4, "<PLAYER>": 7, "<RIVAL>": 7, "<USER>": 16, "<TARGET>": 16, "<pkmn>": 2}
NAME = 12
CHARMAP = sorted({m.group(1) for m in re.finditer(r'charmap "((?:[^"\\]|\\.)+)", \$([0-9A-Fa-f]+)', open("charmap.asm").read())},
                 key=len, reverse=True)
ZERO = {k for k, v in re.findall(r'charmap "((?:[^"\\]|\\.)+)", \$([0-9A-Fa-f]+)', open("charmap.asm").read())
        if int(v, 16) < 0x60 and k not in EXPAND and len(k) > 1}


def width(s):
    s = s.split("@")[0]
    w = literal = i = 0
    while i < len(s):
        tok = next((t for t in CHARMAP if s.startswith(t, i)), s[i])
        i += len(tok)
        n = EXPAND.get(tok, 0 if tok in ZERO else 1)
        w += n
        if tok not in ("<USER>", "<TARGET>"):
            literal += n
    return w, literal


def lint(path):
    out = []
    cur = None  # [width, literal width, start line number, text]
    def close():
        if cur and cur[0] > WIDTH:
            out.append((path, cur[2], "over" if cur[1] > WIDTH else "maybe", cur[0], cur[3]))
    for n, line in enumerate(open(path, encoding="utf-8", errors="replace"), 1):
        code = line.split(";")[0] if '"' not in line.split(";")[0] else line
        m = re.match(r'\s*(text|line|cont|para|next)\s*"((?:[^"\\]|\\.)*)"', code)
        if m:
            close()
            w, lit = width(m.group(2))
            cur = [w, lit, n, m.group(2)]
            if "@" in m.group(2):
                close(); cur = None
            continue
        m = re.match(r"\s*(TX_RAM|TX_NUM|TX_BCD)\b\s*([^;]*)", line)
        if m and cur is not None:
            args = [a.strip() for a in m.group(2).split(",")]
            add = NAME
            if m.group(1) == "TX_NUM" and len(args) >= 3:
                add = int(args[2], 0)
            elif m.group(1) == "TX_BCD" and len(args) >= 2:
                add = 7
            cur[0] += add
            cur[3] += f"<{args[0]}>"
            continue
        m = re.match(r"\s*(prompt|done|db\s+\"@\"|TX_|text_end)", line)
        if m:
            close(); cur = None
        elif re.match(r"^\S", line):
            close(); cur = None
    close()
    return out


files = sys.argv[1:] or [f for f in glob.glob("**/*.asm", recursive=True)]
found = []
for f in sorted(files):
    found += lint(f)
for path, n, kind, w, s in found:
    print(f"{path}:{n}: {kind} {w}: {s}")
print(len(found), "lines", file=sys.stderr)
