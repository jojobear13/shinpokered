#!/usr/bin/env python3
"""Writes gfx/party_icons_1.png and gfx/party_icons_2.png: each party icon's
first and second frame, 16x16, one under another by Pokédex number, then the
egg's. They come from gfx/sources/minidex_001-251.gif ("MINIDEX 001-251", by
Chamber, Solo993, Blue Emerald, Lake, Neslug and Pikachu25), whose colours
become the Game Boy's: the peach skin light grey, the body colour dark grey,
the outline black, the background transparent (white).

Usage: tools/gen_party_icons.py <repo root>
"""
import sys
from PIL import Image

repo = sys.argv[1]
SHEET = f"{repo}/gfx/sources/minidex_001-251.gif"
BACKGROUND = (218, 229, 214)
WHITE, LIGHT, DARK, BLACK = 255, 170, 85, 0

# the egg's left half (the icon is symmetric), its second frame one pixel lower
EGG = [
    "......33",
    ".....311",
    "....3111",
    "...31111",
    "...31221",
    "..311222",
    "..311122",
    ".3111111",
    ".3111111",
    ".3122111",
    ".3122211",
    ".3112211",
    ".3111111",
    "..311111",
    "...33111",
    ".....333",
]


def shade(rgb):
    if rgb == BACKGROUND:
        return WHITE
    if rgb == (0, 0, 0):
        return BLACK
    r, g, b = rgb
    return LIGHT if r >= 240 and g >= 140 else DARK  # the peach skin, or the body colour


gif = Image.open(SHEET)
for frame in (0, 1):
    gif.seek(frame)
    rgb = gif.convert("RGB")
    out = Image.new("L", (16, 16 * 152), WHITE)
    for n in range(151):
        x0, y0 = 10 + 34 * (n % 15), 37 + 25 * (n // 15)
        for y in range(16):
            for x in range(16):
                out.putpixel((x, 16 * n + y), shade(rgb.getpixel((x0 + x, y0 + y))))
    for y, row in enumerate(EGG):
        for x, c in enumerate(row + row[::-1]):
            if y + frame < 16:
                out.putpixel((x, 16 * 151 + y + frame), {".": WHITE, "1": LIGHT, "2": DARK, "3": BLACK}[c])
    out.save(f"{repo}/gfx/party_icons_{frame + 1}.png")
print("152 icons, 2 frames")
