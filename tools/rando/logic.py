"""What the map data alone doesn't say: scripted checks, people who step
aside after an event, events the logic needs, and the gifts.

Requirements are atoms: item names (HM_01, S_S_TICKET, ...), badges
(BOULDERBADGE, ...), events (FUJI, SILPH, DRINK, CHAMPION) and abilities made
of an HM and its badge (CUT, SURF, STRENGTH). CHAMPION is never reached in
the logic: what needs it is post-game."""

# ---- squares a script won't let you onto without something: map -> {(x, y): atom}
SQUARES = {
    # a boy walks you to the gym until Brock is beaten
    'PEWTER_CITY': {(35, 17): 'BOULDERBADGE', (36, 17): 'BOULDERBADGE', (37, 18): 'BOULDERBADGE', (37, 19): 'BOULDERBADGE'},
    'ROUTE_22_GATE': {(4, 2): 'BOULDERBADGE', (5, 2): 'BOULDERBADGE'},
    # the thirsty guards
    'ROUTE_5_GATE': {(3, 3): 'DRINK', (4, 3): 'DRINK'},
    'ROUTE_6_GATE': {(3, 2): 'DRINK', (4, 2): 'DRINK'},
    'ROUTE_7_GATE': {(3, 3): 'DRINK', (3, 4): 'DRINK'},
    'ROUTE_8_GATE': {(2, 3): 'DRINK', (2, 4): 'DRINK'},
    # Cycling Road
    'ROUTE_16_GATE_1F': {(4, y): 'BICYCLE' for y in range(7, 11)},
    'ROUTE_18_GATE_1F': {(4, y): 'BICYCLE' for y in range(3, 7)},
    # doors that check
    'VIRIDIAN_CITY': {(32, 8): 'BADGES7'},
    'CINNABAR_ISLAND': {(18, 4): 'SECRET_KEY'},
    'VERMILION_CITY': {(18, 30): 'S_S_TICKET'},   # randomizer: always the ticket
    # the ghost Marowak
    'POKEMONTOWER_6': {(10, 16): 'SILPH_SCOPE'},
}
# Route 23's guards: each row needs its badge (the northmost only west of x=14)
for y, badge in zip((35, 56, 85, 96, 105, 119, 136),
                    ('EARTHBADGE', 'VOLCANOBADGE', 'MARSHBADGE', 'SOULBADGE', 'RAINBOWBADGE', 'THUNDERBADGE', 'CASCADEBADGE')):
    SQUARES.setdefault('ROUTE_23', {}).update({(x, y): badge for x in range(0, 14 if y == 35 else 40)})

# ---- people in the way until an event: (map, sprite index) -> atom (None: never in the way)
SPRITES = {
    ('SAFFRON_CITY', 1): 'SILPH', ('SAFFRON_CITY', 3): 'SILPH', ('SAFFRON_CITY', 4): 'SILPH',
    ('SAFFRON_CITY', 14): 'FUJI',
    ('CERULEAN_CITY', 10): 'CHAMPION',   # Cerulean Cave
    ('CERULEAN_CITY', 11): 'BILL',       # the officer at the burgled house, until Bill's gift
    ('ROUTE_12', 1): 'POKE_FLUTE', ('ROUTE_16', 7): 'POKE_FLUTE',
    ('VERMILION_CITY', 7): 'CAPTAIN',    # Shin's lazy Pokémon at the gym, gone once the captain's gift is taken
    ('VIRIDIAN_CITY', 5): None,
    ('MT_MOON_3', 6): None, ('MT_MOON_3', 7): None,   # the fossils: one taken, the other goes with the nerd    # the old man gets up once you have the Pokédex (always first)
}

# ---- events: reaching the person (or square) gives the atom
EVENTS = {
    'FUJI': ('POKEMONTOWER_7', 4),
    'BILL': ('BILLS_HOUSE', 1),
    'CAPTAIN': ('SS_ANNE_7', 1),
    'SILPH': ('SILPH_CO_11F', 3),
    'DRINK': ('CELADON_MART_ROOF', (12, 2)),   # the vending machines (reached from below)
    'BOULDERBADGE': ('PEWTER_GYM', 1), 'CASCADEBADGE': ('CERULEAN_GYM', 1),
    'THUNDERBADGE': ('VERMILION_GYM', 1), 'RAINBOWBADGE': ('CELADON_GYM', 1),
    'SOULBADGE': ('FUCHSIA_GYM', 1), 'MARSHBADGE': ('SAFFRON_GYM', 1),
    'VOLCANOBADGE': ('CINNABAR_GYM', 1), 'EARTHBADGE': ('VIRIDIAN_GYM', 1),
}
BADGES = ['BOULDERBADGE', 'CASCADEBADGE', 'THUNDERBADGE', 'RAINBOWBADGE',
          'SOULBADGE', 'MARSHBADGE', 'VOLCANOBADGE', 'EARTHBADGE']


def derived(have):
    """Abilities and counts that follow from what is held."""
    out = set(have)
    rules = (('CUT', 'HM_01', 'CASCADEBADGE'), ('SURF', 'HM_03', 'SOULBADGE'),
             ('STRENGTH', 'HM_04', 'RAINBOWBADGE'), ('FLASH', 'HM_05', 'BOULDERBADGE'),
             ('FLY', 'HM_02', 'THUNDERBADGE'))
    for a, hm, badge in rules:
        if hm in out and badge in out:
            out.add(a)
    if all(b in out for b in BADGES[:7]):
        out.add('BADGES7')
    if all(b in out for b in BADGES):
        out.add('BADGES8')
    return out


# ---- gifts: name -> (map, sprite index, vanilla item, requirement, may hold progression)
GIFTS = {
    'BILL': ('BILLS_HOUSE', 1, 'S_S_TICKET', (), True),
    'SS_CAPTAIN': ('SS_ANNE_7', 1, 'HM_01', (), True),
    'ROUTE16_GIRL': ('ROUTE_16_HOUSE', 1, 'HM_02', (), True),
    'SAFARI_SECRET': ('SAFARI_ZONE_SECRET_HOUSE', 1, 'HM_03', (), True),
    'WARDEN': ('FUCHSIA_HOUSE_2', 1, 'HM_04', ('GOLD_TEETH',), True),
    'AIDE_ROUTE2': ('ROUTE_2_GATE', 1, 'HM_05', (), False),       # 10 Pokémon owned
    'AIDE_ROUTE11': ('ROUTE_11_GATE_2F', 2, 'ITEMFINDER', (), False),
    'AIDE_ROUTE15': ('ROUTE_15_GATE_2F', 1, 'EXP_ALL', (), False),
    'BIKE_SHOP': ('BIKE_SHOP', 1, 'BICYCLE', ('BIKE_VOUCHER',), True),
    'FAN_CLUB': ('POKEMON_FAN_CLUB', 5, 'BIKE_VOUCHER', (), True),
    'DINER': ('CELADON_DINER', 3, 'COIN_CASE', (), True),
    'MUSEUM': ('MUSEUM_1F', 3, 'OLD_AMBER', (), True),
    'OLD_ROD_GURU': ('VERMILION_HOUSE_2', 1, 'OLD_ROD', (), True),
    'GOOD_ROD_GURU': ('ROUTE_12_HOUSE', 1, 'GOOD_ROD', (), True),
    'SUPER_ROD_GURU': ('FUCHSIA_HOUSE_3', 1, 'SUPER_ROD', (), True),
    'FUJI': ('POKEMONTOWER_7', 4, 'POKE_FLUTE', ('FUJI',), True),   # given in his house after the rescue
    'DAISY': ('BLUES_HOUSE', 1, 'TOWN_MAP', (), True),
}
# key items and HMs shuffled with logic (the rest of the pool is the ground items)
KEY_ITEMS = ['S_S_TICKET', 'HM_01', 'HM_02', 'HM_03', 'HM_04', 'HM_05', 'BICYCLE', 'BIKE_VOUCHER',
             'COIN_CASE', 'OLD_AMBER', 'OLD_ROD', 'GOOD_ROD', 'SUPER_ROD', 'POKE_FLUTE', 'TOWN_MAP',
             'ITEMFINDER', 'EXP_ALL', 'SILPH_SCOPE', 'LIFT_KEY', 'CARD_KEY', 'SECRET_KEY', 'GOLD_TEETH']

# ---- doors that stay put
# maps whose warps all stay (and the warp on the other side of each)
STATIC_MAPS = {'REDS_HOUSE_1F', 'REDS_HOUSE_2F', 'OAKS_LAB', 'VIRIDIAN_MART', 'CELADON_MART_ELEVATOR',
               'SILPH_CO_ELEVATOR', 'ROCKET_HIDEOUT_ELEVATOR', 'TRASHED_HOUSE_COPY', 'PATH_ENTRANCE_ROUTE_6_COPY',
               'PATH_ENTRANCE_ROUTE_7_COPY', 'CINNABAR_MART_COPY'}
# places that keep their insides (puzzles, a ship that sails, a timed game);
# only their ways out to other maps are shuffled
STATIC_INSIDES = [
    ('VERMILION_DOCK', 'SS_ANNE_'), ('SAFARI_ZONE_',), ('SILPH_CO_',), ('ROCKET_HIDEOUT_',),
    ('VICTORY_ROAD_',), ('SEAFOAM_ISLANDS_',), ('MANSION_',),
    ('INDIGO_PLATEAU_LOBBY', 'LORELEIS_ROOM', 'BRUNOS_ROOM', 'AGATHAS_ROOM', 'LANCES_ROOM', 'CHAMPIONS_ROOM', 'HALL_OF_FAME'),
]


def same_inside(a, b):
    return any(a.startswith(p) and b.startswith(q) for grp in STATIC_INSIDES for p in grp for q in grp)


# warps whose wLastMap the map's script picks (Route 22's gate: by the row)
DEST = {('ROUTE_22_GATE', 0): ('ROUTE_22', 0), ('ROUTE_22_GATE', 1): ('ROUTE_22', 0),
        ('ROUTE_22_GATE', 2): ('ROUTE_23', 0), ('ROUTE_22_GATE', 3): ('ROUTE_23', 1)}

# the ones some requirement needs: placed first, with the logic
PROGRESSION = ['S_S_TICKET', 'HM_01', 'HM_03', 'HM_04', 'BICYCLE', 'BIKE_VOUCHER', 'POKE_FLUTE',
               'SILPH_SCOPE', 'LIFT_KEY', 'CARD_KEY', 'SECRET_KEY', 'GOLD_TEETH']

START = ('REDS_HOUSE_2F', (3, 6))
GOAL = ('INDIGO_PLATEAU_LOBBY', 'BADGES8')    # reach the lobby with all eight badges


# blocks (2x2 squares) a script swaps in until an event: map -> {(block x, block y): atom}
BLOCKS = {
    'ROUTE_9': {(3, 4): 'CAPTAIN'},   # Shin's construction worker, until the S.S. Anne leaves
    'VICTORY_ROAD_1': {(4, 6): 'STRENGTH'}, 'VICTORY_ROAD_2': {(11, 7): 'STRENGTH'},
    'VICTORY_ROAD_3': {(3, 5): 'STRENGTH'},
}
# Silph Co.'s card key doors, from each floor's GateCoords (block y, block x)
SILPH_GATES = {2: [(2, 2), (5, 2)], 3: [(4, 4), (4, 8)], 4: [(6, 2), (4, 6)], 5: [(2, 3), (6, 3), (5, 7)],
               6: [(6, 2)], 7: [(3, 5), (2, 10), (6, 10)], 8: [(4, 3)], 9: [(4, 1), (2, 9), (5, 9), (6, 5)],
               10: [(4, 5)], 11: [(6, 3)]}
for floor, gates in SILPH_GATES.items():
    BLOCKS['SILPH_CO_%dF' % floor] = {(bx, by): 'CARD_KEY' for by, bx in gates}


def squares(rom):
    """map name -> {square: requirement}, for world.MapGrid."""
    out = {k: dict(v) for k, v in SQUARES.items()}
    for name, blocks in BLOCKS.items():
        d = out.setdefault(name, {})
        for (bx, by), req in blocks.items():
            for dx in (0, 1):
                for dy in (0, 1):
                    d[(2 * bx + dx, 2 * by + dy)] = req
    return out


# elevators choose their floor from a menu: elevator map -> requirement
ELEVATORS = {'CELADON_MART_ELEVATOR': (), 'SILPH_CO_ELEVATOR': (), 'ROCKET_HIDEOUT_ELEVATOR': ('LIFT_KEY',)}


def edges(world):
    """Square edges the map data doesn't have: elevator rides."""
    out = []
    rom = world.rom
    for name, req in ELEVATORS.items():
        e = rom.map_ids[name]
        ew = world.maps[e]['warps'][0]
        inside = (e, (ew['x'], ew['y']))
        for mid, m in world.maps.items():
            for wp in m['warps']:
                if wp['dest_map'] == e and mid != e:
                    out.append((inside, (mid, (wp['x'], wp['y'])), tuple(req)))
    return out
