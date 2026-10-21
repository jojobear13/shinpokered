# Emulator sweeps, soaks and story checkpoints

The scripts behind phases 2-4 of `docs/verification_plan.md`. They drive the
built Red ROM in PyBoy (as the tests do) from a workspace in `/tmp/pk30emu`,
and assume the repo is at `/home/user/shinpokered`.

    make && tools/emu/setup.sh
    cd /tmp/pk30emu/rs
    python3 sweep_maps.py [00-FF ranges]   # every map: loads, runs, moves; screenshots
    python3 sweep_npcs.py [ranges]         # every person and sign; dialogue dump
    python3 sweep_trainers.py [from-to]    # every trainer party battled
    python3 sweep_items.py field|battle    # every item used
    python3 soak_battle.py SEED COUNT      # random whole battles with invariants
    python3 story_gyms.py                  # the 8 gym leaders: badge, TM, text
    python3 story_events.py [names]        # story events, the Elite Four, Hall of Fame
    python3 story_save.py                  # save and CONTINUE, NEW GAME+

Results and screenshots go to `/tmp/pk30emu/out`. `lib.py` and `dxlib.py`
are the shared helpers (party set-up, screen text from the charmap); `story.py`
the checkpoint framework (setting flags, entering a map, approaching a person,
playing a battle through). The link and breeding soaks are in `tests/`.
