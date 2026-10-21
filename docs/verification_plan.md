# PK30 verification plan (v0.9.0)

The goal is a ROM that can be played start to finish on all builds without
a crash, a softlock, broken text or a wrong number, before calling it 1.0.

What exists already: 399 unit tests in 53 files (`make test`). Almost all of
them run single routines (battle maths, menus, items) on the Red build. What
nothing checks yet is the game played as a whole: every map, script, trainer,
item and NPC with this fork's data, the other builds, saves and the link.

The plan runs from cheap and broad to slow and deep. Each phase ends with its
findings written up in `docs/design_brief.md` (fixed bugs with a test), and
anything I can't fix alone goes to you.

## Phase 1: static checks (whole ROM, no emulator)

Fast scripts that read the source or the built ROM and catch whole classes
of mistakes at once. Each becomes a test so it stays checked.

1. **Builds**: all 8 ROMs build with no warnings; `tests/compare_builds.py`
   shows only the expected differences between them.
2. **Space**: free bytes per ROM bank, WRAM, HRAM and SRAM; no bank within a
   few bytes of full (bank 3 and 4 already are).
3. **Data validity**: every learnset, TM/HM list, evolution, egg move,
   trainer party, wild table, mart, gift and trade names a real species,
   move or item, at a legal level; no trainer mon knows a move it can't.
4. **Text**: every string fits its box (18 columns, line counts), move,
   ability, item and type names fit every screen they appear on.
5. **Flags and memory**: no event flag, WRAM or SRAM byte claimed twice
   (this fork's `$8CC`-`$8D1` against Shin's); the save checksum covers every
   saved byte this fork added.

## Phase 2: automated sweeps (emulator, every map and NPC)

Scripts that visit everything instead of playing it.

1. **Map sweep**: warp into every map; check it loads, the player can move,
   and no tile, sprite or palette is garbage (screenshot each one for a
   quick visual pass).
2. **NPC sweep**: talk to every person and sign on every map; every text
   ends and returns control. Item balls and hidden items give what they say.
3. **Trainer sweep**: start a battle with every trainer party in the game and
   play a few AI-vs-AI turns: no crash, no invalid move, sensible damage.
   Gym leaders, the rival and the Elite Four in full.
4. **Wild sweep**: one encounter from every wild table (grass, water, each
   rod), checking species and levels against the data.
5. **Item sweep**: use every item from the bag, in and out of battle, on a
   valid and an invalid target.

## Phase 3: soak tests (long random runs)

1. **Battle soak**: thousands of random battles (random mons, moves,
   abilities, held items, statuses, both sides AI) with invariants checked
   every turn: HP within 0..max, PP and stat stages in range, no stack
   overflow, no stray jump, battle ends. Run with the options on and off
   (EXP. SHARE, HP PERCENT, TYPE HINT, the clauses and challenges).
2. **Link soak**: extend the link mirror test so both games run the same
   random battles and must agree on every turn.
3. **Breeding soak**: many eggs from random compatible pairs: legal species,
   moves and IVs, hatches at level 1.

## Phase 4: story checkpoints (emulator, scripted)

Drive the main story's key events with scripts and save states, so each can
be rerun after any fix: starter and rival, Oak's parcel, each gym and badge,
Mt. Moon fossils, S.S. Anne and HM01, Rock Tunnel (Flash and darkness),
Pokémon Tower and the Silph Scope, Silph Co., Safari Zone, the Game Corner,
Cinnabar, Victory Road, the Elite Four and Hall of Fame, then NEW GAME+ and
the post-game (Cerulean Cave, Mewtwo, Mew). Each checkpoint is saved and
loaded once to test the save.

## Phase 5: builds, hardware modes and saves

1. **Every build**: run the unit tests and a short story slice on Blue,
   Green, Red-JP, Blue-JP and the `_origback` builds, not only Red.
2. **Display modes**: Game Boy Color, original Game Boy (DMG) and Super Game
   Boy palettes and borders, with COLOR FIX and MORE COLOR on and off.
3. **Saves**: save and load from every menu that can, all 12 PC boxes full,
   a save made mid-NEW GAME+, and the "old save" refusal.
4. **Another emulator**: run the checkpoints in a second accurate emulator
   (SameBoy or mGBA, if they can be installed here) next to PyBoy. BGB on
   your side remains the reference.

## Phase 6: your playtest

You play; I keep the pipeline ready to take whatever you find:

- **Report**: what happened, where, and the build, plus a save or a BGB
  save state if you can. A screenshot helps for anything visual.
- **For each report** I reproduce it in the emulator, write a test that
  fails, fix it, and add it to the design brief.
- **Checklist**: a short list of what is new and worth poking at, in story
  order, so the playtest also covers what the scripts can't judge (feel,
  balance, text tone, music).

## Order and status

| Phase | Effort | Status |
|---|---|---|
| 1 Static checks | small | done (below) |
| 2 Sweeps | medium | done (below) |
| 3 Soak tests | medium | not started |
| 4 Story checkpoints | large | not started |
| 5 Builds, modes, saves | medium | not started |
| 6 Playtest support | ongoing | ready |

Phases 1-3 need no input from you and find the most per hour, so they go
first. Phase 4 is the slowest to build but gives a rerunnable playthrough.

## Phase 1 results

- **Builds**: all 8 build with no warnings (the Makefile's deprecated
  `rgbgfx -h` is now `-Z`).
- **Space**: `tools/space_report.py` prints each bank's free bytes from the
  link maps. About 236 KB of ROM is free (10 empty banks and slack), 476
  bytes of WRAM, and the last WRAM variable ends at `$dd25`, 730 bytes clear
  of the stack. Many of Shin's banks are within a few bytes of full, which
  only matters for code added to them.
- **Data**: `tests/test_data_integrity.py` reads every trainer party with
  the game's own `ReadTrainer` (as written, with the alternative movesets,
  scaled to a level 50 and a level 100 team, and randomized), every wild
  table, mart, in-game trade and evolution from the built ROM. It found one
  bug, fixed: a special trainer move the mon already knew gave it that move
  twice (Bruno's first Onix, with DIG twice, from this fork's learnsets;
  Sabrina and Koga with Shin's level scaling on).
- **Text**: `tools/text_lint.py` (and `tests/test_text_fit.py`) follows the
  text commands with the game's charmap and finds lines wider than the
  18-column box in the worst case. It found 16 of this fork's battle
  messages that ran past the box when the line began with an enemy's name
  ("Enemy " and up to 10 letters): all rewritten.
- **Flags and saves**: this fork's event flags ($8CC-$8D1) were unused in
  Shin. Everything it keeps between sessions is in the saved, checksummed
  block, now including the last repel used (it was outside, so a game
  loaded mid-repel couldn't offer another when it wore off); tested in
  `SaveLayoutTest`.

## Phase 2 results

Emulator sweeps (PyBoy, the Red build, from a new game with a test party):

- **Maps**: all 226 maps entered through a steered fly warp (any map, a
  door or the middle as the spawn): every one loads, runs the overworld
  loop and draws correctly (a contact sheet of all of them was checked by
  eye). Six couldn't be walked out of from the spawn chosen (the sea on
  Routes 19 and 21, the Cerulean Cave door, boulders on Seafoam B4F, a
  hemmed-in Saffron door, the Hall of Fame cutscene): all spawn artifacts.
- **People and signs**: all 1,146 texts opened through `DisplayTextID` and
  pressed through: 801 end and return to the field, 339 start their trainer
  battle, 6 run long or wait on an entry cutscene (Lance, the Hall of Fame)
  that ignores the joypad, all checked. The 4,240 lines of dialogue shown
  have no unknown tile.
- **Trainers**: all 362 parties battled to the end with each enemy mon
  acting: only real moves, no unknown tile in any battle text, no crash.
- **Items**: all 137 items used from the bag in the field and in a wild
  battle. Two bugs, fixed:
  - Giving a held item left sprite updates off and the map's sprite tiles
    overwritten (reported in the playtest too): the player vanished and
    couldn't move, or the game crashed.
  - "PIKACHU is now holding FOCUS BAND." ran past the box (the text
    checker missed lines continuing after an inserted name; it now follows
    them, and found one more edge: "<PLAYER> got ¥" with a 7-letter name
    and 6 digits of prize money).
