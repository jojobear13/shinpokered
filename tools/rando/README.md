# Randomizer logic (reference)

The world model and the reference randomizer behind the RANDOMIZER options.
They read a built ROM (`pokered.gbc` and its `.sym`), so each build gets its
own world (the Japanese Red and Green keep the original layouts).

- `rom.py`: maps, warps, sprites, connections, hidden objects and the
  hide/show table, read from the ROM.
- `world.py`: every square of every map and the moves between them
  (walking, ledges one way, Cut, Surf, Strength, the game's tile-pair rules),
  plus map edges.
- `logic.py`: what the map data doesn't say: scripted checks (badge guards,
  the thirsty Saffron guards, Cycling Road, the card key doors), people who
  step aside after an event, events (badges, Bill, the captain, Mr. Fuji,
  Silph Co., the drink), the gifts, the key items, and the doors that stay put.
- `graph.py`: warps grouped into entrances and their vanilla pairs.
- `pools.py`: the entrances the door shuffle moves: outside doors with the
  insides they led to, and stairs between inside maps among themselves.
- `regions.py`: the squares squeezed into regions, then compressed to 497
  nodes and 721 edges (exact: same answers as the square graph), the sweep,
  and the softlock check.
- `randomizer.py`: the seeded shuffle: doors grown from the start so the whole
  world is attached, key items by assumed fill, ground items into the rest,
  then a check that the game can be finished and that no place a player can
  walk into leaves it unfinishable.
- `gen_data.py`: writes `data/rando/{intl,jp}_*.asm`, the tables the game's
  generator (`engine/rando/`) and its runtime lookups use. Run it after a
  change to the maps or the logic, then build again:
  `python3 tools/rando/gen_data.py && make`.

The game does what `randomizer.py` does, step for step, so for a seed both
give the same world; `tests/test_rando.py` checks that for every mode, and
`randomizer.seed_hash` gives the seed a typed seed becomes. Doors only
(without key items) isn't offered: with the key items where they were, a
shuffled world can rarely be finished.
