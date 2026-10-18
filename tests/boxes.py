"""Reading and writing the party, the current PC box, saved boxes and the day
care, for tests.

Step D of the design brief moved the current box and the day-care mon from
WRAM to save RAM; only the readers and writers in this module changed, and
the tests that use them stayed the same.
"""

BOX_STRUCT_LEN = 0x22   # 33 bytes before the special split gave the DVs a third byte
PARTY_STRUCT_LEN = 0x2F
NAME_LENGTH = 11
MONS_PER_BOX = 20
PARTY_LENGTH = 6
NUM_BOXES = 12
TERMINATOR = 0x50  # "@"

# offsets into a party or box struct
SPECIES = 0x00
HP = 0x01
BOX_LEVEL = 0x03
MOVES = 0x08
OT_ID = 0x0C
EXP = 0x0E
DVS = 0x1B    # 3 bytes: attack/defense, speed/special attack, special defense/spare
NUM_DVS = 3
PP = 0x1E
LEVEL = 0x22  # party struct only
STATS = 0x23  # party struct only: max HP, attack, defense, speed, special attack, special defense
NUM_STATS = 6

BOX_TO_PARTY = 0
PARTY_TO_BOX = 1
DAYCARE_TO_PARTY = 2
PARTY_TO_DAYCARE = 3


def _name(game, where):
    return game.peek(where, NAME_LENGTH)


def _mon(species, data, ot, nick):
    return {"species": species, "data": list(data), "ot": list(ot), "nick": list(nick)}


# ----------------------------------------------------------------- party

def read_party(game):
    count = game.peek("wPartyCount")
    mons = []
    for i in range(count):
        base = game.addr("wPartyMons") + i * PARTY_STRUCT_LEN
        mons.append(_mon(
            game.peek(game.addr("wPartySpecies") + i),
            game.peek(base, PARTY_STRUCT_LEN),
            _name(game, game.addr("wPartyMonOT") + i * NAME_LENGTH),
            _name(game, game.addr("wPartyMonNicks") + i * NAME_LENGTH),
        ))
    return mons


def write_party(game, mons):
    game.poke("wPartyCount", len(mons))
    game.poke("wPartySpecies", *([m["species"] for m in mons] + [0xFF]))
    for i, m in enumerate(mons):
        game.poke(game.addr("wPartyMons") + i * PARTY_STRUCT_LEN, *m["data"])
        game.poke(game.addr("wPartyMonOT") + i * NAME_LENGTH, *m["ot"])
        game.poke(game.addr("wPartyMonNicks") + i * NAME_LENGTH, *m["nick"])


# ----------------------------------------------------------- current box
# Since step D the current box is in save RAM bank 0 (sBoxDataStart), read
# and written by bank so it doesn't matter whether the game has SRAM enabled.

def _at(game, name, offset=0):
    return game.bank(name), game.addr(name) + offset

def _box_layout(read, base):
    """Parse a box in the in-memory layout (count, species list, structs,
    OT names, nicknames), using read(offset, length)."""
    count = read(0, 1)[0]
    species_at = 1
    mons_at = species_at + MONS_PER_BOX + 1
    ot_at = mons_at + MONS_PER_BOX * BOX_STRUCT_LEN
    nicks_at = ot_at + MONS_PER_BOX * NAME_LENGTH
    mons = []
    for i in range(count):
        mons.append(_mon(
            read(species_at + i, 1)[0],
            read(mons_at + i * BOX_STRUCT_LEN, BOX_STRUCT_LEN),
            read(ot_at + i * NAME_LENGTH, NAME_LENGTH),
            read(nicks_at + i * NAME_LENGTH, NAME_LENGTH),
        ))
    return mons


def read_current_box(game):
    bank, base = _at(game, "sBoxDataStart")
    return _box_layout(lambda off, n: [game.memory[bank, base + off + i] for i in range(n)], base)


def write_current_box(game, mons):
    game.poke("sNumInBox", len(mons))
    game.poke("sBoxSpecies", *([m["species"] for m in mons] + [0xFF]))
    for i, m in enumerate(mons):
        game.poke(_at(game, "sBoxMons", i * BOX_STRUCT_LEN), *m["data"])
        game.poke(_at(game, "sBoxMonOT", i * NAME_LENGTH), *m["ot"])
        game.poke(_at(game, "sBoxMonNicks", i * NAME_LENGTH), *m["nick"])


def current_box_number(game):
    """0-11; bit 7 of wCurrentBoxNum only records that boxes were set up."""
    return game.peek("wCurrentBoxNum") & 0x7F


# ------------------------------------------------------- saved boxes

def read_saved_box(game, number):
    """Box `number` (0-11) as stored in save RAM."""
    bank, addr = game.symbols[f"sBox{number + 1}"]
    return _box_layout(lambda off, n: [game.memory[bank, addr + off + i] for i in range(n)], addr)


# ------------------------------------------------------------ day care

def read_day_care(game):
    if not game.peek("wDayCareInUse"):
        return None
    return _mon(
        game.peek("sDayCareMonSpecies"),
        game.peek("sDayCareMon", BOX_STRUCT_LEN),
        _name(game, "sDayCareMonOT"),
        _name(game, "sDayCareMonName"),
    )


def write_day_care(game, mon):
    """Put a box-format mon in the day care and mark it in use."""
    game.poke("wDayCareInUse", 1)
    game.poke("sDayCareMon", *mon["data"])
    game.poke("sDayCareMonOT", *mon["ot"])
    game.poke("sDayCareMonName", *mon["nick"])


# ------------------------------------------------------- random mons

def random_name(rng):
    letters = [rng.randint(0x80, 0x99) for _ in range(rng.randint(1, NAME_LENGTH - 1))]
    return letters + [TERMINATOR] * (NAME_LENGTH - len(letters))


def random_mon(rng, species_pool, party=True):
    """A party mon (44 bytes) or box mon (33 bytes) with plausible fields."""
    data = [rng.randint(0, 255) for _ in range(PARTY_STRUCT_LEN if party else BOX_STRUCT_LEN)]
    species = rng.choice(species_pool)
    level = rng.randint(2, 100)
    data[SPECIES] = species
    data[BOX_LEVEL] = level
    data[MOVES:MOVES + 4] = [rng.randint(1, 165) for _ in range(4)]
    # experience is capped when gained, so it never exceeds the level 100
    # amount; 800000 is that amount for the fastest growth rate
    exp = rng.randint(0, 800000)
    data[EXP:EXP + 3] = [exp >> 16, (exp >> 8) & 0xFF, exp & 0xFF]
    if party:
        data[LEVEL] = level
        max_hp = rng.randint(10, 400)
        data[STATS], data[STATS + 1] = max_hp >> 8, max_hp & 0xFF
        hp = rng.randint(0, max_hp)
        data[HP], data[HP + 1] = hp >> 8, hp & 0xFF
    data[DVS + 2] &= 0xF0  # the third DV byte's low nybble is spare and always 0
    return _mon(species, data, random_name(rng), random_name(rng))
