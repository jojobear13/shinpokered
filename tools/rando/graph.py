"""Warps grouped into entrances, the vanilla pairing of entrances, and the
item locations, on top of the square graph from world.py."""
from collections import defaultdict, deque
from world import World

LAST_MAP = 0xFF


class Graph:
    def __init__(self, rom_name='pokered', logic=None):
        self.w = w = World(rom_name, logic)
        self.rom = w.rom
        self.logic = logic
        self.resolve_warps()
        self.group_entrances()
        self.find_locations()

    def name(self, mid):
        return self.rom.map_names.get(mid, '?%02X' % mid)

    # ---- warps
    def resolve_warps(self):
        """dest (map, warp) of every warp, with wLastMap ($FF) resolved from
        the maps that lead in."""
        w = self.w
        into = defaultdict(set)
        for mid, m in w.maps.items():
            for i, wp in enumerate(m['warps']):
                if wp['dest_map'] != LAST_MAP:
                    into[wp['dest_map']].add(mid)
        self.dest = {}
        self.ambiguous = []
        overrides = {}
        if self.logic:
            for (mn, i), (dn, di) in getattr(self.logic, 'DEST', {}).items():
                overrides[(self.rom.map_ids[mn], i)] = (self.rom.map_ids[dn], di)
        for mid, m in w.maps.items():
            for i, wp in enumerate(m['warps']):
                if (mid, i) in overrides:
                    self.dest[(mid, i)] = overrides[(mid, i)]
                    continue
                dm = wp['dest_map']
                if dm == LAST_MAP:
                    # wLastMap is only ever an outside map (tileset OVERWORLD or PLATEAU)
                    srcs = sorted(s for s in into[mid] - {mid} if w.maps[s]['tileset'] in (0, 23))
                    if len(srcs) != 1:
                        # several maps lead in: the one whose warp points back here
                        back = [s for s in srcs if any(x['dest_map'] == mid for x in w.maps[s]['warps'])
                                and wp['dest_warp'] < len(w.maps[s]['warps'])
                                and w.maps[s]['warps'][wp['dest_warp']]['dest_map'] == mid]
                        if len(back) != 1:
                            self.ambiguous.append((mid, i, srcs))
                            continue
                        srcs = back
                    dm = srcs[0]
                if dm not in w.maps or wp['dest_warp'] >= len(w.maps[dm]['warps']):
                    self.ambiguous.append((mid, i, dm))
                    continue
                self.dest[(mid, i)] = (dm, wp['dest_warp'])

    def warp_square(self, mid, i):
        wp = self.w.maps[mid]['warps'][i]
        return (mid, (wp['x'], wp['y']))

    def group_entrances(self):
        """Warps of one map that lead to the same place are one entrance:
        next to each other with the same destination map, or leading to the
        same warp (or to warps next to each other)."""
        w = self.w

        def adjacent(a, b):
            wa, wb = w.maps[a[0]]['warps'][a[1]], w.maps[b[0]]['warps'][b[1]]
            return a[0] == b[0] and abs(wa['x'] - wb['x']) + abs(wa['y'] - wb['y']) <= 1

        self.entrance_of = {}
        self.entrances = []   # list of [(mid, i), ...]
        for mid, m in w.maps.items():
            ws = m['warps']
            parent = list(range(len(ws)))

            def find(a):
                while parent[a] != a:
                    parent[a] = parent[parent[a]]
                    a = parent[a]
                return a
            for i in range(len(ws)):
                for j in range(i):
                    di, dj = self.dest.get((mid, i)), self.dest.get((mid, j))
                    if di is None or dj is None:
                        continue
                    if (adjacent((mid, i), (mid, j)) and di[0] == dj[0]) or di == dj or \
                            (di[0] == dj[0] and adjacent(di, dj)):
                        parent[find(i)] = find(j)
            groups = defaultdict(list)
            for i in range(len(ws)):
                groups[find(i)].append((mid, i))
            for g in sorted(groups.values()):
                e = len(self.entrances)
                self.entrances.append(g)
                for k in g:
                    self.entrance_of[k] = e
        # vanilla partner: where the entrance's first warp leads
        self.vanilla = {}
        for e, g in enumerate(self.entrances):
            d = self.dest.get(g[0])
            if d:
                self.vanilla[e] = self.entrance_of[d]
        # where you arrive through an entrance: its first warp you can step off
        incoming = defaultdict(int)
        for a, b, req in w.square_edges:
            if a != b:
                incoming[b] += 1
        self.usable = {}
        self.arrival = {}
        for e, g in enumerate(self.entrances):
            ok = [k for k in g if incoming[self.warp_square(*k)]]
            self.usable[e] = bool(ok)
            self.arrival[e] = (ok or g)[0]

    def warp_edges(self, pairing=None):
        """Square edges for walking into each warp: to the partner entrance's
        first warp. pairing: entrance -> entrance (default vanilla)."""
        out = []
        for e, g in enumerate(self.entrances):
            p = (pairing or self.vanilla).get(e)
            if p is None:
                continue
            if pairing and e not in pairing:
                p = self.vanilla.get(e)
            to = self.warp_square(*self.arrival[p]) if pairing else None
            for k in g:
                src = self.warp_square(*k)
                if pairing:
                    out.append((src, to, ()))
                elif k in self.dest:
                    out.append((src, self.warp_square(*self.dest[k]), ()))
        return out

    # ---- locations
    def find_locations(self):
        """Item balls and hidden items (the ground items), by map and index."""
        self.locations = []
        hidden = self.rom.hidden_objects()
        for mid, m in sorted(self.w.maps.items()):
            for s in m['sprites']:
                if 'item' in s and s['sprite'] == 'SPRITE_BALL':
                    self.locations.append(dict(kind='ball', map=mid, index=s['index'], item=s['item'],
                                               square=(s['x'], s['y'])))
            for k, h in enumerate(hidden.get(mid, [])):
                if h['routine'] == 'HiddenItems':
                    self.locations.append(dict(kind='hidden', map=mid, index=k,
                                               item=self.rom.item_names.get(h['arg'], h['arg']),
                                               square=(h['x'], h['y'])))

    # ---- reachability
    def adjacency(self, have, extra_edges=()):
        adj = defaultdict(list)
        for a, b, req in self.w.square_edges + list(extra_edges):
            if set(req) <= have:
                adj[a].append(b)
        return adj

    def reach(self, start, have, extra_edges=()):
        adj = self.adjacency(have, extra_edges)
        seen = {start}
        q = deque([start])
        while q:
            v = q.popleft()
            for u in adj[v]:
                if u not in seen:
                    seen.add(u)
                    q.append(u)
        return seen

    def location_reached(self, loc, seen):
        x, y = loc['square']
        mid = loc['map']
        return any((mid, (x + dx, y + dy)) in seen for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0), (0, 0)))
