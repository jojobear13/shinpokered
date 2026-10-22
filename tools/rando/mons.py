"""Species, trainers and wild data read from a built ROM, for the Pokémon
side of the randomizer (gen_data.py writes the tables the game uses).

Species are numbered as the game numbers them internally (wcf91), 1-190;
the numbers no species has are left out."""
import os
import re

from rom import REPO, consts

TYPES = {m.group(1): int(m.group(2), 16) for m in re.finditer(
    r'^(\w+)\s+EQU \$([0-9A-Fa-f]+)', open(os.path.join(REPO, 'constants/type_constants.asm')).read(), re.M)}
TYPE_NAMES = {v: k for k, v in TYPES.items()}
LEGENDARY = ['ARTICUNO', 'ZAPDOS', 'MOLTRES', 'MEWTWO', 'MEW']
# the types the gym leaders and the Elite Four always keep
BOSS_THEMES = {'BROCK': 'ROCK', 'MISTY': 'WATER', 'LT_SURGE': 'ELECTRIC', 'ERIKA': 'GRASS',
               'KOGA': 'POISON', 'SABRINA': 'PSYCHIC', 'BLAINE': 'FIRE', 'GIOVANNI': 'GROUND',
               'LORELEI': 'ICE', 'BRUNO': 'FIGHTING', 'AGATHA': 'GHOST', 'LANCE': 'DRAGON'}
RIVALS = ['SONY1', 'SONY2', 'SONY3']
# the starters' lines, in the order of the vanilla starter slots the rival
# counters: STARTER3 (BULBASAUR) loses to STARTER1 (CHARMANDER), which loses
# to STARTER2 (SQUIRTLE), which loses to BULBASAUR
STARTER_LINES = [['BULBASAUR', 'IVYSAUR', 'VENUSAUR'], ['CHARMANDER', 'CHARMELEON', 'CHARIZARD'],
                 ['SQUIRTLE', 'WARTORTLE', 'BLASTOISE']]


class Mons:
    def __init__(self, rom):
        self.rom = rom
        self.species = consts('constants/pokemon_constants.asm')
        self.species.pop('NO_MON', None)
        self.name = {v: k for k, v in self.species.items()}
        self.trainer_classes = {}
        for line in open(os.path.join(REPO, 'constants/trainer_constants.asm')):
            m = re.match(r'\s*trainer_const (\w+)\s*; \$([0-9A-F]+)', line)
            if m:
                self.trainer_classes[m.group(1)] = int(m.group(2), 16)
        self.read_species()
        self.read_types()
        self.read_evolutions()

    # ---- species
    def read_species(self):
        rom = self.rom
        bank, order = rom.at('PokedexOrder')
        bbank, base = rom.at('BaseStats')
        size = rom.at('MonBaseStatsEnd')[1] - rom.at('MonBaseStats')[1]
        self.dex = {}
        self.types = {}
        self.bst = {}
        for sp in range(1, 191):
            dex = rom.b(bank, order + sp - 1)
            if dex == 0:
                continue
            a = base + (dex - 1) * size
            assert rom.b(bbank, a) == dex, sp
            self.dex[sp] = dex
            self.bst[sp] = sum(rom.b(bbank, a + 1 + k) for k in range(6))
            self.types[sp] = (rom.b(bbank, a + 7), rom.b(bbank, a + 8))
        self.all = sorted(self.dex)
        self.legendary = {self.species[n] for n in LEGENDARY}

    def type_set(self, sp):
        return set(self.types[sp])

    def num_moves(self):
        moves = consts('constants/move_constants.asm')
        return moves['STRUGGLE'] - 1    # NUM_ATTACKS: the moves before STRUGGLE

    # ---- the type chart
    def read_types(self):
        bank, a = self.rom.at('TypeEffects')
        self.chart = {}
        while self.rom.b(bank, a) != 0xFF:
            att, dfn, mult = self.rom.b(bank, a, 3)
            self.chart[(att, dfn)] = mult
            a += 3

    def effect(self, att, sp):
        """Multiplier x100 of type att against species sp."""
        out = 100
        for t in sorted(self.type_set(sp)):
            out = out * self.chart.get((att, t), 10) // 10
        return out

    def beats(self, a, b):
        """a's first type is super effective against b, and b's first type
        isn't against a."""
        return self.effect(self.types[a][0], b) > 100 and self.effect(self.types[b][0], a) <= 100

    # ---- evolutions
    def read_evolutions(self):
        bank, table = self.rom.at('EvosMovesPointerTable')
        self.evolves = {sp: [] for sp in self.all}
        self.prevo = {}
        for sp in self.all:
            a = self.rom.w(bank, table + 2 * (sp - 1))
            while True:
                kind = self.rom.b(bank, a)
                if kind == 0:
                    break
                to = self.rom.b(bank, a + (3 if kind == 2 else 2))
                a += 4 if kind == 2 else 3
                if to not in self.evolves[sp]:
                    self.evolves[sp].append(to)
                self.prevo[to] = sp

    def basic(self, sp):
        return sp not in self.prevo

    def lines3(self):
        """Every three-stage line, as [basic, middle, final], one per basic
        (the first evolution of each stage)."""
        out = []
        for sp in self.all:
            if self.basic(sp) and self.evolves[sp]:
                mid = self.evolves[sp][0]
                if self.evolves.get(mid):
                    out.append([sp, mid, self.evolves[mid][0]])
        return out

    def triangles(self, lines):
        """Ordered (a, b, c) of line indices where a's basic beats b's, b's
        beats c's and c's beats a's (the starters' rock-paper-scissors)."""
        out = []
        n = len(lines)
        for a in range(n):
            for b in range(n):
                for c in range(n):
                    if len({a, b, c}) < 3:
                        continue
                    x, y, z = lines[a][0], lines[b][0], lines[c][0]
                    if self.beats(x, y) and self.beats(y, z) and self.beats(z, x):
                        out.append((a, b, c))
        return out

    # ---- trainers
    def trainers(self):
        """class id -> [[species, ...] per trainer]"""
        rom = self.rom
        bank, table = rom.at('TrainerDataPointers')
        end = rom.at('RosterLabelEnd')[1]
        ptrs = [rom.w(bank, table + 2 * k) for k in range(len(self.trainer_classes))]
        bounds = sorted(set(ptrs + [end]))
        out = {}
        for k, p in enumerate(ptrs):
            stop = bounds[bounds.index(p) + 1]
            teams = []
            a = p
            while a < stop:
                first = rom.b(bank, a)
                team = []
                if first == 0xFF:
                    a += 1
                    while rom.b(bank, a):
                        team.append(rom.b(bank, a + 1))
                        a += 2
                else:
                    a += 1
                    while rom.b(bank, a):
                        team.append(rom.b(bank, a))
                        a += 1
                a += 1
                teams.append(team)
            out[k + 1] = teams
        return out

    def theme(self, team):
        """The type a whole team shares (the first one's first type when it
        has two that all share, unless that's NORMAL), or None."""
        if not team or any(sp not in self.dex for sp in team):
            return None
        common = set.intersection(*(self.type_set(sp) for sp in team))
        if not common:
            return None
        first = self.types[team[0]]
        for t in first:
            if t in common and t != TYPES['NORMAL']:
                return t
        return sorted(common)[0]
