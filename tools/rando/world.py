"""The world as a graph for the randomizer's logic.

Each map's walkable squares are joined by what it takes to move between them
(walking, a ledge one way, Cut, Surf, Strength, or a requirement written in
logic.py), then squeezed into regions: the squares that can reach each other
freely. Regions join across maps by map edges and warps. Item balls, hidden
items and gifts are placed in the regions they are reached from."""
from collections import defaultdict
from rom import Rom, STAY, OVERWORLD, GYM

SHIP_PORT, CAVERN, FACILITY, PLATEAU, FOREST, DOJO, SHIP = 14, 17, 22, 23, 3, 5, 13
WATER_TILESETS = {OVERWORLD, FOREST, DOJO, GYM, SHIP, SHIP_PORT, CAVERN, FACILITY, PLATEAU}
DIRS = {'up': (0, -1), 'down': (0, 1), 'left': (-1, 0), 'right': (1, 0)}


class MapGrid:
    """Squares (steps) of one map and the moves between them."""

    def __init__(self, rom, m, extra=None, logic=None):
        self.m = m
        self.w, self.h = m['width'] * 2, m['height'] * 2
        ts = rom.tileset(m['tileset'])
        self.tileset = m['tileset']
        self.passable = ts['passable']
        bs = rom.blockset(ts)
        W = m['width']

        def tile(tx, ty):
            blk = m['blocks'][(ty // 4) * W + tx // 4]
            return bs[blk][(ty % 4) * 4 + tx % 4] if blk < len(bs) else 0

        self.tile = {(x, y): tile(2 * x, 2 * y + 1) for y in range(self.h) for x in range(self.w)}
        self.pairs_land = self.pairs_water = set()
        self.blocked = {}   # square -> requirement to stand there (None: never)
        shown = rom.shown()
        overrides = (logic.SPRITES if logic else {})
        for s in m['sprites']:
            key = (m['name'], s['index'])
            if key in overrides:
                if overrides[key]:
                    self.blocked[(s['x'], s['y'])] = overrides[key]
            elif not shown.get((m['id'], s['index']), True) or 'item' in s:
                continue    # hidden at the start, or an item ball (gone once picked up)
            elif s['sprite'] == 'SPRITE_BOULDER':
                self.blocked[(s['x'], s['y'])] = 'STRENGTH'
            elif s['movement'] == STAY:
                self.blocked[(s['x'], s['y'])] = None
        self.extra = extra or {}

    def inside(self, p):
        return 0 <= p[0] < self.w and 0 <= p[1] < self.h

    def is_water(self, t):
        if self.tileset not in WATER_TILESETS:
            return False
        return t == 0x14 or t == 0x48 or (t == 0x32 and self.tileset != SHIP_PORT)

    def cut_tree(self, t):
        return (self.tileset == OVERWORLD and t == 0x3D) or (self.tileset == GYM and t == 0x50)

    def moves(self, pair_land, pair_water, ledges):
        """(from, to, requirement) for every step inside the map."""
        out = []
        warps = {(wp['x'], wp['y']) for wp in self.m['warps']}
        for p, t in self.tile.items():
            # only from a square one can stand on (or arrive on, through a warp)
            if not (t in self.passable or self.is_water(t) or self.cut_tree(t) or p in self.blocked or p in warps):
                continue
            for d, (dx, dy) in DIRS.items():
                q = (p[0] + dx, p[1] + dy)
                if not self.inside(q):
                    continue
                u = self.tile[q]
                req = []
                if self.is_water(u):
                    if (self.tileset, t, u) in pair_water or (self.tileset, u, t) in pair_water:
                        continue
                    if not self.is_water(t):
                        req.append('SURF')
                elif u in self.passable:
                    pairs = pair_water if self.is_water(t) else pair_land   # surfing onto land, or walking
                    if (self.tileset, t, u) in pairs or (self.tileset, u, t) in pairs:
                        continue
                elif self.cut_tree(u):
                    req.append('CUT')
                else:
                    if self.tileset == OVERWORLD and (d, t, u) in ledges:
                        r = (p[0] + 2 * dx, p[1] + 2 * dy)
                        if self.inside(r):
                            out.append((p, r, ()))
                    continue
                if q in self.blocked:
                    if self.blocked[q] is None:
                        continue
                    req.append(self.blocked[q])
                x = self.extra.get(q)
                if x:
                    if x == 'WALL':
                        continue
                    req.extend(x if isinstance(x, tuple) else (x,))
                out.append((p, q, tuple(sorted(set(req)))))
        return out


def tables(rom):
    def triples(name):
        bank, a = rom.at(name)
        out = set()
        while rom.b(bank, a) != 0xFF:
            out.add(tuple(rom.b(bank, a, 3)))
            a += 3
        return out
    ledges = set()
    bank, a = rom.at('LedgeTiles')
    face = {0x00: 'down', 0x04: 'up', 0x08: 'left', 0x0C: 'right'}
    while rom.b(bank, a) != 0xFF:
        f, stand, ledge, _ = rom.b(bank, a, 4)
        ledges.add((face[f], stand, ledge))
        a += 4
    return triples('TilePairCollisionsLand'), triples('TilePairCollisionsWater'), ledges


class World:
    def __init__(self, rom_name='pokered', logic=None):
        self.rom = rom = Rom(rom_name)
        self.logic = logic
        pl, pw, ledges = tables(rom)
        self.maps = {}
        for mid, name in rom.map_names.items():
            m = rom.map(mid)
            if m and m['width'] and m['height'] and m['tileset'] < 24 and not name.startswith('UNUSED'):
                self.maps[mid] = m
        self.grids = {}
        self.square_edges = []  # ((mid,p), (mid,q), req)
        extra_all = logic.squares(rom) if logic else {}
        for mid, m in self.maps.items():
            g = MapGrid(rom, m, extra_all.get(m['name']), logic)
            self.grids[mid] = g
            for p, q, req in g.moves(pl, pw, ledges):
                self.square_edges.append(((mid, p), (mid, q), req))
        self.connect_edges()
        if logic:
            self.square_edges += logic.edges(self)

    def connect_edges(self):
        """Walking off a map's edge onto the connected map."""
        for mid, m in self.maps.items():
            g = self.grids[mid]
            for d, c in m['connections'].items():
                if c['map'] not in self.grids:
                    continue
                h = self.grids[c['map']]
                if d in ('north', 'south'):
                    y0 = 0 if d == 'north' else g.h - 1
                    for x in range(g.w):
                        q = (x + c['xalign'], c['yalign'])
                        if h.inside(q) and (h.tile[q] in h.passable or h.is_water(h.tile[q])):
                            req = ('SURF',) if h.is_water(h.tile[q]) and not g.is_water(g.tile[(x, y0)]) else ()
                            self.square_edges.append(((mid, (x, y0)), (c['map'], q), req))
                else:
                    x0 = 0 if d == 'west' else g.w - 1
                    for y in range(g.h):
                        q = (c['xalign'], y + c['yalign'])
                        if h.inside(q) and (h.tile[q] in h.passable or h.is_water(h.tile[q])):
                            req = ('SURF',) if h.is_water(h.tile[q]) and not g.is_water(g.tile[(x0, y)]) else ()
                            self.square_edges.append(((mid, (x0, y)), (c['map'], q), req))

    # ---- regions
    def regions(self):
        """Strongly connected components of the free moves; returns
        (region of each square, edges between regions with requirements)."""
        free = defaultdict(list)
        nodes = set()
        for a, b, req in self.square_edges:
            nodes.add(a)
            nodes.add(b)
            if not req:
                free[a].append(b)
        for mid, g in self.grids.items():
            for p in g.tile:
                nodes.add((mid, p))
        comp = tarjan(sorted(nodes), free)
        redges = defaultdict(set)
        for a, b, req in self.square_edges:
            ca, cb = comp[a], comp[b]
            if ca != cb:
                redges[(ca, cb)].add(req)
        # keep only the weakest requirement sets between two regions
        out = {}
        for k, reqs in redges.items():
            reqs = [set(r) for r in reqs]
            keep = [r for r in reqs if not any(o < r for o in reqs)]
            out[k] = sorted({tuple(sorted(r)) for r in keep})
        return comp, out


def tarjan(nodes, adj):
    index, low, onstack, stack, comp = {}, {}, set(), [], {}
    counter = [0]
    ncomp = [0]
    for v0 in nodes:
        if v0 in index:
            continue
        work = [(v0, iter(adj.get(v0, ())))]
        index[v0] = low[v0] = counter[0]; counter[0] += 1
        stack.append(v0); onstack.add(v0)
        while work:
            v, it = work[-1]
            pushed = False
            for w in it:
                if w not in index:
                    index[w] = low[w] = counter[0]; counter[0] += 1
                    stack.append(w); onstack.add(w)
                    work.append((w, iter(adj.get(w, ()))))
                    pushed = True
                    break
                elif w in onstack:
                    low[v] = min(low[v], index[w])
            if pushed:
                continue
            work.pop()
            if work:
                low[work[-1][0]] = min(low[work[-1][0]], low[v])
            if low[v] == index[v]:
                while True:
                    w = stack.pop(); onstack.discard(w)
                    comp[w] = ncomp[0]
                    if w == v:
                        break
                ncomp[0] += 1
    return comp
