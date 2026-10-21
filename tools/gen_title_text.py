#!/usr/bin/env python3
"""Draws the title screen's subtitle ("Red 30th Anniversary", and Blue and
Green for those builds) as gfx/title_<version>.png, 1bpp tiles loaded at
tile $60. The letters follow the original "Red Version" text: 2px strokes,
capitals and digits 5 rows tall, lowercase 4. Each line is centred under
the logo (screen pixel 80); this prints the tile column and tile count
that PrintGameVersionOnTitleScreen uses.

Usage: tools/gen_title_text.py <repo root>
"""
import sys
from PIL import Image

GLYPHS = {
    'R': ["####.", "##.##", "####.", "##.##", "##.##"],
    'B': ["####.", "##.##", "####.", "##.##", "####."],
    'G': [".####", "##...", "##.##", "##.##", ".####"],
    'A': [".###.", "##.##", "#####", "##.##", "##.##"],
    '3': ["####.", "...##", ".###.", "...##", "####."],
    '0': [".###.", "##.##", "##.##", "##.##", ".###."],
    'a': [".....", ".####", "##.##", "##.##", ".####"],
    'd': ["...##", ".####", "##.##", "##.##", ".####"],
    'e': ["....", ".###", "##.#", "###.", ".###"],
    'h': ["##...", "####.", "##.##", "##.##", "##.##"],
    'i': ["##", "..", "##", "##", "##"],
    'l': ["##", "##", "##", "##", "##"],
    'n': ["....", "###.", "##.#", "##.#", "##.#"],
    'r': ["....", "####", "##..", "##..", "##.."],
    's': [".....", ".####", "###..", "..###", "####."],
    't': [".##.", "####", ".##.", ".##.", "..##"],
    'u': ["....", "##.#", "##.#", "##.#", ".###"],
    'v': [".....", "##.##", "##.##", ".###.", "..#.."],
    'y': [".....", "##.##", "##.##", ".####", "...##", "####."],  # descender
    ' ': ["..", "..", "..", "..", ".."],
}
TOP = 2  # capitals on rows 2-6, the descender on row 7
CENTRE = 80


def width(text):
    return sum(len(GLYPHS[c][0]) + 1 for c in text) - 1


def render(text):
    w = width(text)
    left = CENTRE - w // 2
    column, offset = divmod(left, 8)
    tiles = (offset + w + 7) // 8
    im = Image.new('1', (tiles * 8, 8), 1)
    x = offset
    for c in text:
        for dy, row in enumerate(GLYPHS[c]):
            for dx, p in enumerate(row):
                if p == '#':
                    im.putpixel((x + dx, TOP + dy), 0)
        x += len(GLYPHS[c][0]) + 1
    return im, column, tiles


repo = sys.argv[1]
for version in ("Red", "Blue", "Green"):
    im, column, tiles = render(f"{version} 30th Anniversary")
    im.save(f"{repo}/gfx/title_{version.lower()}.png")
    print(f"{version}: column {column}, {tiles} tiles")
