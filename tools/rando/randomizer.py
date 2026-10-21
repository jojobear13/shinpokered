"""The randomizer, as the game will run it: a seed, a door shuffle that
grows the world from the start, key items placed so the game can always be
finished, and the ground items shuffled into the rest.

Written to be ported to the Game Boy step for step: one random number
generator, every list in a fixed order, and the same calls in the same order."""
import logic as L
from regions import softlocks

ALL_ATOMS = None
GROW_BELOW = 6


class Rng:
    """xorshift32. rand(n) is the top 16 bits times n, top 16 bits of that."""

    def __init__(self, seed):
        self.x = seed & 0xFFFFFFFF or 0x2545F491

    def next(self):
        x = self.x
        x ^= (x << 13) & 0xFFFFFFFF
        x ^= x >> 17
        x ^= (x << 5) & 0xFFFFFFFF
        self.x = x
        return x

    def rand(self, n):
        assert 0 < n < 0x10000
        return ((self.next() >> 16) * n) >> 16

    def shuffle(self, lst):
        for i in range(len(lst) - 1, 0, -1):
            j = self.rand(i + 1)
            lst[i], lst[j] = lst[j], lst[i]


def seed_hash(codes, settings):
    """FNV-1a over the seed's characters (game charmap codes) and the settings byte."""
    h = 0x811C9DC5
    for c in list(codes) + [settings]:
        h ^= c
        h = (h * 0x01000193) & 0xFFFFFFFF
    return h


class Randomizer:
    def __init__(self, C):
        self.C = C
        everything = set(L.KEY_ITEMS) | set(L.BADGES) | set(L.EVENTS) | {'POKEDEX'}
        everything.discard('CHAMPION')
        self.everything = frozenset(L.derived(everything))
        self.adj_fixed = C.adjacency({})
        self.prog_locs = [l for l in C.locs if l['prog']]
        self.kinds = self.area_kinds()
        self.leaving = {}
        for e, regs in C.leave.items():
            for r in regs:
                self.leaving.setdefault(r, []).append(e)

    # ---- doors
    def area_kinds(self, have=None):
        """For each shuffled entrance: the other shuffled entrances arriving
        through it reaches, with every item and without other shuffled warps."""
        C = self.C
        leaving = {}
        for e, regs in C.leave.items():
            for r in regs:
                leaving.setdefault(r, []).append(e)
        out = {}
        for f in C.leave:
            seen = {C.arrive[f]}
            st = [C.arrive[f]]
            while st:
                v = st.pop()
                for u, r in self.adj_fixed[v]:
                    if u not in seen and r <= (have or self.everything):
                        seen.add(u)
                        st.append(u)
            out[f] = sorted({x for v in seen for x in leaving.get(v, ()) if x != f})
        return out

    def reach_state(self):
        """Reach with every key item held and events earned by reaching them."""
        return dict(reach=set(), have=set(L.derived(set(L.KEY_ITEMS) | {'POKEDEX'})), blocked=[])

    def extend(self, st, pairing, starts):
        C = self.C
        work = [s for s in starts if s not in st['reach']]
        st['reach'].update(work)
        while True:
            while work:
                v = work.pop()
                nxt = list(self.adj_fixed[v])
                for e in self.leaving.get(v, ()):
                    if e in pairing:
                        nxt.append((C.arrive[pairing[e]], frozenset()))
                for u, r in nxt:
                    if u in st['reach']:
                        continue
                    if r <= st['have']:
                        st['reach'].add(u)
                        work.append(u)
                    else:
                        st['blocked'].append((u, r))
            new = {a for a, regs in C.events.items()
                   if a not in st['have'] and any(r in st['reach'] for r in regs)}
            if not new:
                return
            st['have'] = L.derived(st['have'] | new)
            still = []
            for u, r in st['blocked']:
                if u in st['reach']:
                    continue
                if r <= st['have']:
                    st['reach'].add(u)
                    work.append(u)
                else:
                    still.append((u, r))
            st['blocked'] = still

    def shuffle_doors(self, rng):
        """Attach the world to the start one entrance at a time: an entrance
        not reached yet is paired with a random open one (reached, not paired)
        of the kind that may lead to it; when everything is reached, the
        open ones left are paired among themselves."""
        C = self.C
        pool_of = {}
        for e in C.O:
            pool_of[e] = C.I
        for e in C.I:
            pool_of[e] = C.O
        for e in C.II:
            pool_of[e] = C.II
        order = sorted(pool_of)
        pairing = {}
        st = self.reach_state()
        self.extend(st, pairing, [C.start])
        kinds_have = None
        while True:
            reach = st['reach']
            if kinds_have != st['have']:
                kinds_have = set(st['have'])
                self.kinds = self.area_kinds(frozenset(kinds_have))
            is_open = {e for e in order if e not in pairing and any(r in reach for r in C.leave[e])}
            unreached = [f for f in order if f not in pairing and f not in is_open
                         and any(p in is_open for p in pool_of[f])]
            if not unreached:
                break
            # keep a doorway open for every kind still needed
            kind = lambda x: 0 if x in C.O else 1 if x in C.I else 2
            need = {0: 1, 1: 0, 2: 2}          # an outside door needs an open inside one, ...
            open_n = [0, 0, 0]
            for x in is_open:
                open_n[kind(x)] += 1
            demand = [0, 0, 0]
            for x in unreached:
                demand[need[kind(x)]] += 1
            growers, leaves, anchored = [], [], []
            spare_stairs = open_n[2] > sum(1 for x in unreached if kind(x) == 2 and not any(
                y not in pairing and y not in is_open for y in self.kinds[x]))
            for x in unreached:
                t = need[kind(x)]
                more = [y for y in self.kinds[x] if y not in pairing and y not in is_open]
                if more:
                    # a floor that also has a door to the outside: through that
                    # door, unless there are stairs to spare
                    if kind(x) == 2 and not spare_stairs and any(kind(y) != 2 for y in more):
                        anchored.append(x)
                    else:
                        growers.append(x)
                elif open_n[t] >= 2 or demand[t] == 1:
                    leaves.append(x)
            # the most constrained first: dead ends while there are doorways
            # of their kind to spare, then areas that open more doors
            if leaves:
                unreached = leaves
            elif growers:
                unreached = growers
            elif anchored:
                unreached = anchored
            f = unreached[rng.rand(len(unreached))]
            opens = [p for p in pool_of[f] if p in is_open]
            e = opens[rng.rand(len(opens))]
            pairing[e] = f
            pairing[f] = e
            self.extend(st, pairing, [C.arrive[f]])
        left = [e for e in order if e not in pairing]
        if any(not any(r in st['reach'] for r in C.leave[e]) for e in left):
            return None     # some of the world is cut off
        for pool in (C.O, C.II):
            rest = [e for e in pool if e not in pairing]
            others = rest if pool is C.II else [e for e in C.I if e not in pairing]
            while rest:
                a = rest.pop(0)
                if pool is C.II:
                    b = rest.pop(rng.rand(len(rest)))
                else:
                    b = others.pop(rng.rand(len(others)))
                pairing[a] = b
                pairing[b] = a
        return pairing

    def grows(self, st, pairing, p, e):
        """Would arriving through p reach an entrance still to pair (other than p)?"""
        trial = dict(pairing)
        trial[e] = p
        trial[p] = e
        st2 = dict(reach=set(st['reach']), have=set(st['have']), blocked=list(st['blocked']))
        self.extend(st2, trial, [self.C.arrive[p]])
        return any(x not in trial and any(r in st2['reach'] and r not in st['reach'] for r in self.C.leave[x])
                   for x in self.C.leave)

    # ---- items
    def place_items(self, rng, pairing):
        """Assumed fill for the items the logic needs; the other key items
        anywhere a key item may go; the ground items into the rest."""
        C = self.C
        keys = list(L.PROGRESSION)
        rng.shuffle(keys)
        placement = {}
        for i, item in enumerate(keys):
            have, seen, order = C.sweep(pairing, placement, start_have=keys[i + 1:])
            got = set(order)
            cands = [l for l in self.prog_locs if l['key'] not in placement and l['key'] in got]
            if not cands:
                return None
            placement[cands[rng.rand(len(cands))]['key']] = item
        others = [k for k in L.KEY_ITEMS if k not in L.PROGRESSION]
        for item in others:
            cands = [l for l in self.prog_locs if l['key'] not in placement]
            placement[cands[rng.rand(len(cands))]['key']] = item
        rest = [l['item'] for l in C.locs]
        for k in L.KEY_ITEMS:
            rest.remove(k)
        rng.shuffle(rest)
        free = [l['key'] for l in C.locs if l['key'] not in placement]
        assert len(free) == len(rest)
        placement.update(zip(free, rest))
        return placement

    def generate(self, seed, max_tries=50):
        rng = Rng(seed)
        for tries in range(1, max_tries + 1):
            pairing = self.shuffle_doors(rng)
            if pairing is None:
                continue
            # with every key item, the events (badges, Fuji, ...) must all be reachable too
            have, seen, _ = self.C.sweep(pairing, {}, start_have=L.KEY_ITEMS)
            if not self.C.beaten(have, seen):
                continue
            placement = self.place_items(rng, pairing)
            if placement is None:
                continue
            have, seen, _ = self.C.sweep(pairing, placement)
            if self.C.beaten(have, seen) and not softlocks(self.C, pairing, placement):
                return dict(pairing=pairing, placement=placement, tries=tries)
        return None
