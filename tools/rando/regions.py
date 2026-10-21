"""The square graph squeezed into regions: squares that reach each other
freely are one region; what's left are edges with requirements, the
entrances' squares, and where the locations and events are reached from.
This is what the randomizer (and later the game) searches."""
from collections import defaultdict
from world import tarjan
import logic as L
import pools as P
import solve as S


class Regions:
    def __init__(self, g):
        self.g = g
        O, I, II = P.pools(g)
        self.O, self.I, self.II = O, I, II
        shuffled = set(O) | set(I) | set(II)
        self.shuffled = shuffled
        # edges that never change: map moves, elevator rides, and the warps not shuffled
        fixed = list(g.w.square_edges)
        for e, grp in enumerate(g.entrances):
            if e in shuffled:
                continue
            for k in grp:
                if k in g.dest:
                    fixed.append((g.warp_square(*k), g.warp_square(*g.arrival[g.entrance_of[g.dest[k]]]), ()))
        # regions: SCCs of the free fixed edges
        free = defaultdict(list)
        nodes = set()
        for a, b, req in fixed:
            nodes |= {a, b}
            if not req:
                free[a].append(b)
        for mid, grid in g.w.grids.items():
            for p in grid.tile:
                nodes.add((mid, p))
        comp = tarjan(sorted(nodes), free)
        self.comp = comp
        # requirement-labelled region edges, weakest sets only
        red = defaultdict(set)
        for a, b, req in fixed:
            ca, cb = comp[a], comp[b]
            if ca != cb:
                red[(ca, cb)].add(frozenset(req))
        self.edges = {}
        for k, reqs in red.items():
            self.edges[k] = [r for r in reqs if not any(o < r for o in reqs)]
        # entrances: where you leave (any warp square) and arrive
        self.leave = {e: sorted({comp[g.warp_square(*k)] for k in g.entrances[e]}) for e in shuffled}
        self.arrive = {e: comp[g.warp_square(*g.arrival[e])] for e in shuffled}
        # locations and events: the regions they're reached from
        self.locs = S.locations(g)
        for l in self.locs:
            l['regions'] = sorted({comp[n] for n in S.near(l['map'], l['square']) if n in comp})
        self.events = {a: sorted({comp[n] for n in S.near(*sq) if n in comp})
                       for a, sq in S.event_squares(g).items()}
        self.start = comp[(g.rom.map_ids[L.START[0]], L.START[1])]
        lobby = g.rom.map_ids[L.GOAL[0]]
        self.goal = sorted({c for (mid, p), c in comp.items() if mid == lobby})

    def sweep(self, pairing, placement, start_have=()):
        """pairing: entrance -> entrance for the shuffled ones.
        placement: location key -> item. Returns (have, reached regions, keys in the order taken)."""
        adj = defaultdict(list)
        for (a, b), reqs in self.edges.items():
            for r in reqs:
                adj[a].append((b, r))
        for e, p in pairing.items():
            for r in self.leave[e]:
                adj[r].append((self.arrive[p], frozenset()))
        have = L.derived(set(start_have) | {'POKEDEX'})
        seen = {self.start}
        frontier = [self.start]
        blocked = []          # (to, req) not yet open
        taken, order = set(), []
        while True:
            while frontier:
                v = frontier.pop()
                for u, r in adj[v]:
                    if u in seen:
                        continue
                    if r <= have:
                        seen.add(u)
                        frontier.append(u)
                    else:
                        blocked.append((u, r))
            new = set()
            for a, regs in self.events.items():
                if a not in have and any(r in seen for r in regs):
                    new.add(a)
            for l in self.locs:
                if l['key'] in taken or not set(l['req']) <= have:
                    continue
                if any(r in seen for r in l['regions']):
                    taken.add(l['key'])
                    order.append(l['key'])
                    it = placement.get(l['key'])
                    if it:
                        new.add(it)
            grown = L.derived(have | new)
            if grown == have:
                return have, seen, order
            have = grown
            still = []
            for u, r in blocked:
                if u in seen:
                    continue
                if r <= have:
                    seen.add(u)
                    frontier.append(u)
                else:
                    still.append((u, r))
            blocked = still

    def beaten(self, have, seen):
        return 'BADGES8' in have and any(r in seen for r in self.goal)


def compress(R):
    """A smaller graph with the same answers: drop regions no path between
    the regions that matter uses, then remove the rest one by one, joining
    each in-edge to each out-edge (requirements added up) where that doesn't
    make more edges. Returns (keep: old region -> new id, edges: list of
    (a, b, frozenset requirement))."""
    keep = {R.start} | set(R.goal)
    for e in R.shuffled:
        keep |= set(R.leave[e]) | {R.arrive[e]}
    for l in R.locs:
        keep |= set(l['regions'])
    for regs in R.events.values():
        keep |= set(regs)
    out_e = defaultdict(dict)   # a -> {b: [reqs]}
    in_e = defaultdict(dict)
    for (a, b), reqs in R.edges.items():
        out_e[a][b] = list(reqs)
        in_e[b][a] = list(reqs)
    # regions on some path from a kept region to a kept region
    def closure(start, nxt):
        seen = set(start)
        st = list(start)
        while st:
            v = st.pop()
            for u in nxt[v]:
                if u not in seen:
                    seen.add(u)
                    st.append(u)
        return seen
    useful = closure(keep, out_e) & closure(keep, in_e)
    for v in list(out_e):
        if v not in useful:
            for b in out_e.pop(v):
                in_e[b].pop(v, None)
    for v in list(in_e):
        if v not in useful:
            for a in in_e.pop(v):
                out_e[a].pop(v, None)

    def add(a, b, r):
        lst = out_e[a].setdefault(b, [])
        if any(o <= r for o in lst):
            return
        lst[:] = [o for o in lst if not r <= o] + [r]
        in_e[b][a] = lst

    changed = True
    while changed:
        changed = False
        for v in sorted(useful - keep):
            if v not in out_e and v not in in_e:
                continue
            ins = [(a, r) for a, rs in in_e.get(v, {}).items() if a != v for r in rs]
            outs = [(b, r) for b, rs in out_e.get(v, {}).items() if b != v for r in rs]
            if len(ins) * len(outs) > len(ins) + len(outs):
                continue
            for a, _ in ins:
                out_e[a].pop(v, None)
            for b, _ in outs:
                in_e[b].pop(v, None)
            out_e.pop(v, None)
            in_e.pop(v, None)
            for a, ra in ins:
                for b, rb in outs:
                    if a != b:
                        add(a, b, ra | rb)
            changed = True
    nodes = sorted({v for v in keep} | {a for a in out_e if out_e[a]} | {b for b in in_e if in_e[b]})
    ids = {v: i for i, v in enumerate(nodes)}
    edges = [(ids[a], ids[b], r) for a, bs in out_e.items() for b, rs in bs.items() for r in rs]
    return ids, edges


class Compact:
    """The compressed world: what the randomizer (Python and the game) uses."""

    def __init__(self, R):
        ids, edges = compress(R)
        self.R = R
        m = lambda regs: sorted({ids[r] for r in regs if r in ids})
        self.n = len(set(ids.values()))
        self.edges = edges
        self.start = ids[R.start]
        self.goal = m(R.goal)
        self.O, self.I, self.II = R.O, R.I, R.II
        self.leave = {e: m(R.leave[e]) for e in R.shuffled}
        self.arrive = {e: ids[R.arrive[e]] for e in R.shuffled}
        self.locs = [dict(l, nodes=m(l['regions'])) for l in R.locs]
        self.events = {a: m(regs) for a, regs in R.events.items()}

    def adjacency(self, pairing):
        adj = defaultdict(list)
        for a, b, r in self.edges:
            adj[a].append((b, r))
        for e, p in pairing.items():
            for r in self.leave[e]:
                adj[r].append((self.arrive[p], frozenset()))
        return adj

    def sweep(self, pairing, placement, start_have=()):
        adj = self.adjacency(pairing)
        have = L.derived(set(start_have) | {'POKEDEX'})
        seen = {self.start}
        taken, order = set(), []
        while True:
            st = list(seen)
            while st:
                v = st.pop()
                for u, r in adj[v]:
                    if u not in seen and r <= have:
                        seen.add(u)
                        st.append(u)
            new = {a for a, regs in self.events.items() if a not in have and any(r in seen for r in regs)}
            for l in self.locs:
                if l['key'] not in taken and set(l['req']) <= have and any(r in seen for r in l['nodes']):
                    taken.add(l['key'])
                    order.append(l['key'])
                    if placement.get(l['key']):
                        new.add(placement[l['key']])
            grown = L.derived(have | new)
            if grown == have:
                return have, seen, order
            have = grown

    def beaten(self, have, seen):
        return 'BADGES8' in have and any(r in seen for r in self.goal)


def stranded(C, pairing, placement):
    """Regions a player could walk into but not back out of to the start,
    at any point of the playthrough (after each round of the sweep).
    Returns [(have, [regions])] for the rounds where some exist."""
    adj = C.adjacency(pairing)
    radj = defaultdict(list)
    for a, lst in adj.items():
        for b, r in lst:
            radj[b].append((a, r))
    have = L.derived({'POKEDEX'})
    taken = set()
    out = []
    while True:
        seen = {C.start}
        st = [C.start]
        while st:
            v = st.pop()
            for u, r in adj[v]:
                if u not in seen and r <= have:
                    seen.add(u)
                    st.append(u)
        back = {C.start}
        st = [C.start]
        while st:
            v = st.pop()
            for u, r in radj[v]:
                if u not in back and r <= have:
                    back.add(u)
                    st.append(u)
        bad = seen - back
        if bad:
            out.append((set(have), sorted(bad)))
        new = {a for a, regs in C.events.items() if a not in have and any(r in seen for r in regs)}
        for l in C.locs:
            if l['key'] not in taken and set(l['req']) <= have and any(r in seen for r in l['nodes']):
                taken.add(l['key'])
                if placement.get(l['key']):
                    new.add(placement[l['key']])
        grown = L.derived(have | new)
        if grown == have:
            return out
        have = grown


def sweep_from(C, adj, start, have, taken, placement):
    """Sweep from a region with what is held; returns (have, seen)."""
    have = set(have)
    taken = set(taken)
    seen = {start}
    while True:
        st = list(seen)
        while st:
            v = st.pop()
            for u, r in adj[v]:
                if u not in seen and r <= have:
                    seen.add(u)
                    st.append(u)
        new = {a for a, regs in C.events.items() if a not in have and any(r in seen for r in regs)}
        for l in C.locs:
            if l['key'] not in taken and set(l['req']) <= have and any(r in seen for r in l['nodes']):
                taken.add(l['key'])
                if placement.get(l['key']):
                    new.add(placement[l['key']])
        grown = L.derived(have | new)
        if grown == have:
            return have, seen
        have = grown


def softlocks(C, pairing, placement):
    """Places a player could walk into, at some point of the playthrough,
    from which the game can no longer be finished. [(round, region)]"""
    adj = C.adjacency(pairing)
    radj = defaultdict(list)
    for a, lst in adj.items():
        for b, r in lst:
            radj[b].append((a, r))
    have = L.derived({'POKEDEX'})
    taken = set()
    out = []
    rnd = 0
    while True:
        seen = {C.start}
        st = [C.start]
        while st:
            v = st.pop()
            for u, r in adj[v]:
                if u not in seen and r <= have:
                    seen.add(u)
                    st.append(u)
        back = {C.start}
        st = [C.start]
        while st:
            v = st.pop()
            for u, r in radj[v]:
                if u not in back and r <= have:
                    back.add(u)
                    st.append(u)
        bad = seen - back
        # only the bad regions that reach no other bad region outside their
        # own component need checking: every bad region drains into one
        for v in sinks(adj, bad, have):
            h2, s2 = sweep_from(C, adj, v, have, taken, placement)
            if not C.beaten(h2, s2):
                out.append((rnd, v))
        SINKS.append(len(sinks(adj, bad, have)))
        new = {a for a, regs in C.events.items() if a not in have and any(r in seen for r in regs)}
        for l in C.locs:
            if l['key'] not in taken and set(l['req']) <= have and any(r in seen for r in l['nodes']):
                taken.add(l['key'])
                if placement.get(l['key']):
                    new.add(placement[l['key']])
        grown = L.derived(have | new)
        if grown == have:
            return out
        have = grown
        rnd += 1


SINKS = []


def sinks(adj, bad, have):
    """One region from each sink component of the bad regions."""
    out = []
    done = set()
    for v in sorted(bad):
        if v in done:
            continue
        # forward closure within bad
        clo = {v}
        st = [v]
        while st:
            x = st.pop()
            for u, r in adj[x]:
                if u in bad and u not in clo and r <= have:
                    clo.add(u)
                    st.append(u)
        # v is in a sink component iff everything it reaches reaches back to v
        if all(v in reach_within(adj, u, bad, have) for u in clo):
            out.append(v)
            done |= clo
    return out


def reach_within(adj, v, bad, have):
    clo = {v}
    st = [v]
    while st:
        x = st.pop()
        for u, r in adj[x]:
            if u in bad and u not in clo and r <= have:
                clo.add(u)
                st.append(u)
    return clo
