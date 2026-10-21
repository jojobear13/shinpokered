"""Which entrances the door shuffle may move, and in which pool."""
import logic as L

OUTSIDE_TILESETS = (0, 23)   # OVERWORLD, PLATEAU (CheckIfInOutsideMap)


def pools(g):
    """(outside side, inside side, inside pairs): entrances of the vanilla
    pairs to shuffle. An outside door keeps leading inside; stairs between
    two inside maps are shuffled among themselves."""
    O, I, II = [], [], []
    seen = set()
    for e, p in sorted(g.vanilla.items()):
        if e in seen or g.vanilla.get(p) != e or e == p:
            continue
        ma, mb = g.entrances[e][0][0], g.entrances[p][0][0]
        na, nb = g.name(ma), g.name(mb)
        if ma == mb or not (g.usable[e] and g.usable[p]):
            continue
        if na in L.STATIC_MAPS or nb in L.STATIC_MAPS or L.same_inside(na, nb):
            continue
        seen |= {e, p}
        oa = g.w.maps[ma]['tileset'] in OUTSIDE_TILESETS
        ob = g.w.maps[mb]['tileset'] in OUTSIDE_TILESETS
        if oa and not ob:
            O.append(e); I.append(p)
        elif ob and not oa:
            O.append(p); I.append(e)
        elif not oa and not ob:
            II += [e, p]
        else:
            raise ValueError('outside to outside: %s %s' % (na, nb))
    return O, I, II
