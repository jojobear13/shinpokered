"""The logic: sweep the world from the start, collecting what can be reached,
until nothing more opens up."""
from collections import defaultdict, deque
import logic as L


class Placement:
    """What each location holds: {('ball'|'hidden', map, index) or ('gift', name): item}."""


def locations(graph):
    """All item locations: (key, map id, square or sprite index, requirement, progression ok)."""
    rom = graph.rom
    out = []
    for l in graph.locations:
        out.append(dict(key=(l['kind'], l['map'], l['index']), map=l['map'], square=l['square'],
                        req=(), prog=l['kind'] == 'ball', item=l['item']))
    for name, (mapname, idx, item, req, prog) in L.GIFTS.items():
        mid = rom.map_ids[mapname]
        s = [x for x in graph.w.maps[mid]['sprites'] if x['index'] == idx][0]
        out.append(dict(key=('gift', name), map=mid, square=(s['x'], s['y']), req=tuple(req), prog=prog, item=item))
    return out


def near(mid, sq):
    x, y = sq
    return [(mid, (x + dx, y + dy)) for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0), (0, 0), (0, 2), (2, 0), (-2, 0))]


def event_squares(graph):
    out = {}
    for atom, (mapname, who) in L.EVENTS.items():
        mid = graph.rom.map_ids[mapname]
        if isinstance(who, tuple):
            out[atom] = (mid, who)
        else:
            s = [x for x in graph.w.maps[mid]['sprites'] if x['index'] == who][0]
            out[atom] = (mid, (s['x'], s['y']))
    return out


def sweep(graph, edges, placement, locs, start_have=()):
    """edges: [(a, b, req)] square edges (map moves and warps).
    placement: location key -> item. Returns (have, reached squares, locations reached in order)."""
    rom = graph.rom
    by_req = defaultdict(list)
    for a, b, req in edges:
        by_req[req].append((a, b))
    evs = event_squares(graph)
    have = L.derived(set(start_have) | {'POKEDEX'})
    start = (rom.map_ids[L.START[0]], L.START[1])
    got = []
    taken = set()
    while True:
        adj = defaultdict(list)
        for req, lst in by_req.items():
            if set(req) <= have:
                for a, b in lst:
                    adj[a].append(b)
        seen = {start}
        q = deque([start])
        while q:
            v = q.popleft()
            for u in adj[v]:
                if u not in seen:
                    seen.add(u)
                    q.append(u)
        new = set()
        for atom, sq in evs.items():
            if atom not in have and any(n in seen for n in near(*sq)):
                new.add(atom)
        took = False
        for l in locs:
            if l['key'] in taken or not set(l['req']) <= have:
                continue
            if any(n in seen for n in near(l['map'], l['square'])):
                taken.add(l['key'])
                got.append(l['key'])
                took = True
                it = placement.get(l['key'])
                if it:
                    new.add(it)
        grown = L.derived(have | new)
        if grown == have and not took:
            return have, seen, got
        have = grown
