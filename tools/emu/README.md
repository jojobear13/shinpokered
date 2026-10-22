# Emulator sweeps, soaks and story checkpoints

The scripts behind phases 2-4 of `docs/verification_plan.md`. They drive the
built Red ROM in PyBoy (as the tests do) from a workspace in `/tmp/pk30emu`,
and assume the repo is at `/home/user/shinpokered`.

    make && tools/emu/setup.sh     # or setup.sh pokeblue: /tmp/pk30emu_pokeblue
    cd /tmp/pk30emu/rs
    python3 sweep_maps.py [00-FF ranges]   # every map: loads, runs, moves; screenshots
    python3 sweep_npcs.py [ranges]         # every person and sign; dialogue dump
    python3 sweep_trainers.py [from-to]    # every trainer party battled
    python3 sweep_items.py field|battle    # every item used
    python3 soak_battle.py SEED COUNT      # random whole battles with invariants
    python3 story_gyms.py                  # the 8 gym leaders: badge, TM, text
    python3 story_events.py [names]        # story events, the Elite Four, Hall of Fame
    python3 story_save.py                  # save and CONTINUE, NEW GAME+
    python3 colors.py                      # COLOR FIX and MORE COLOR combinations
    python3 sameboy_check.py [cgb dmg sgb] # the same save played in SameBoy
    python3 rando_walk.py [SEED]           # doors of a randomized world, walked through
    python3 rando_mons.py [SEED]           # RANDOM #MON: gifts, Snorlax, Mewtwo, the Elite Four
    python3 explode_check.py               # a self-fainted mon leaves before the other side moves

Results and screenshots go to `/tmp/pk30emu/out`. `lib.py` and `dxlib.py`
are the shared helpers (party set-up, screen text from the charmap); `story.py`
the checkpoint framework (setting flags, entering a map, approaching a person,
playing a battle through). The link and breeding soaks are in `tests/`.

## SameBoy

`sameboy_check.py` drives [SameBoy](https://github.com/LIJI32/SameBoy)
(Lior Halphon's accurate Game Boy emulator, MIT-licensed) through `sbdrive`,
a small line protocol (`frames`, `key`, `peek`, `poke`, `shot`, `battery`)
around its core; `sb.py` is the Python side. To build it:

    git clone https://github.com/LIJI32/SameBoy && cd SameBoy
    make tester            # builds the core objects and the boot ROMs
    S=$PWD; cd /path/to/sbdrive-dir
    clang -O2 -std=gnu11 -D_GNU_SOURCE -I$S -DGB_VERSION='"x"' \
        -DGB_COPYRIGHT_YEAR='"x"' -c sbdrive.c -o sbdrive.o
    clang -o sbdrive sbdrive.o $S/build/obj/Core/*.o -lm

Compile `sbdrive.c` with the same feature switches as the core (none
disabled, by default), or the structures disagree. Point `SBDRIVE` at the
binary and `SB_BOOT` at `build/bin/tester` (the boot ROMs).
