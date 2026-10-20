#!/usr/bin/env python3
"""Writes gfx/party_icons_1.png and gfx/party_icons_2.png: each party icon's
first and second frame, 16x16, one under another by Pokédex number, then the
egg's (from gfx/sources/egg_icon_frames.png, its white light grey). They come from gfx/sources/minidex_001-251.gif ("MINIDEX 001-251", by
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

# the egg's two frames: gfx/sources/egg_icon_frames.png, two 16x16 panels
# drawn at 12x, inside a 2-pixel border with an 8-pixel gap between them
EGG_SHEET = f"{repo}/gfx/sources/egg_icon_frames.png"
EGG_PANELS = (2, 206)  # each panel's left edge
EGG_COLOURS = {(147, 187, 236): WHITE, (248, 248, 248): LIGHT, (168, 168, 168): DARK, (0, 0, 0): BLACK}


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
    egg = Image.open(EGG_SHEET).convert("RGB")
    for y in range(16):
        for x in range(16):
            out.putpixel((x, 16 * 151 + y),
                         EGG_COLOURS[egg.getpixel((EGG_PANELS[frame] + 12 * x + 6, 1 + 12 * y + 6))])
    out.save(f"{repo}/gfx/party_icons_{frame + 1}.png")
print("152 icons, 2 frames")
