# Tests

These tests run the built ROM in the [PyBoy](https://github.com/Baekalfen/PyBoy)
emulator and call game routines directly, so battle logic can be checked
without playing through the game.

## Setup

```bash
pip install pyboy
make red          # the tests use pokered.gbc and pokered.sym
```

## Running

```bash
make test
# or: python3 -m unittest discover -s tests -t tests
```

To test a different build, set `SHIN_ROM=/path/to/rom.gbc` (its `.sym` file
must sit next to it).

## Checking that a refactor changed nothing

`compare_builds.py` builds the ROM from a git ref and from your working tree,
runs every suite in `tests/suites/` on both with the same random battle states,
and reports any difference in results or in RAM afterwards.

```bash
python3 tests/compare_builds.py --base master --seeds 2000
```

Pass `--rgbds /path/to/rgbds/` if RGBDS 0.6.0 isn't on your PATH. RAM
variables that only exist in the new build are skipped, since there is nothing
to compare them against.

## Writing tests

- `harness.py` has `Game`, which boots the ROM once and restores that snapshot
  on every `reset()`.
- `game.poke("wSymbol", ...)` / `game.peek(...)` / `poke16` / `peek16` read and
  write RAM by symbol name (big-endian for 16-bit values, as the game stores
  them).
- `game.call("RoutineName", a=..., bc=..., de=..., hl=...)` runs a routine with
  interrupts off and returns the registers it left behind. Routines that wait
  for the next frame or for input need `skip_delays()` / `auto_buttons()`
  (below); ones that wait on sound or other interrupt-driven state can't be
  called this way yet.
- `game.skip_delays()` makes `DelayFrame` return at once, so routines that
  animate (HP bars draining, sliding pictures) can be called. What they write
  to RAM, including the tile map, is unchanged.
- `game.auto_buttons()` makes `Joypad` report A and B held, so text boxes
  print instantly and don't wait for the player.
- `game.patch(symbol, bytes...)` overwrites ROM; every patch is undone by
  `reset()`.
- `game.queue_random(...)` makes `Random` return chosen values. Using more
  values than were queued is an error, so a test always knows how much
  randomness a routine used.
- A suite in `tests/suites/` provides `setup(game, rng)`, `run(game, case)` and
  `cases()`, and is picked up automatically by `compare_builds.py`. Write
  setup using symbol names only, so the same seed gives the same state on two
  different builds.
