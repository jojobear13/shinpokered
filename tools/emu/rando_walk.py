"""Walk through doors in a randomized world (the world from the Python
reference, put into save RAM) and check where the player arrives."""
import sys
sys.path.insert(0, '/home/user/shinpokered/tools/rando')
from story import *
import gen_data as GD
T = GD.Tables('pokered'); Rz = T.Rz
SEED = int(sys.argv[1]) if len(sys.argv) > 1 else 1
py = Rz.generate(SEED, max_tries=255)
part = [T.slot_of[py['pairing'][e]] for e in T.slots]
place = [T.rom.items[py['placement'][l['key']]] for l in T.C.locs]

def put_world():
    m[A('wRandoFlags')] = 0x0f
    for i, v in enumerate(SEED.to_bytes(4, 'little')): m[A('wRandoSeed') + i] = v
    def sram(name, vals):
        a = ENT[name][1]
        for i, v in enumerate(vals): m[1, a + i] = v
    sram('sRandoPartner', [b for p in part for b in (p & 0xff, p >> 8)])
    sram('sRandoPlace', place)
    sram('sRandoTag', list(SEED.to_bytes(4, 'little')) + [7])
    sram('sRandoValid', [1])

names = {v[0]: k for k, v in MAPS.items()}
ok = bad = 0
checks = [('PALLET_TOWN', None), ('VIRIDIAN_CITY', None), ('PEWTER_CITY', None), ('CERULEAN_CITY', None)]
for town, _ in checks:
    mid = MAPS[town][0]
    for i, (x, y) in enumerate(warps(mid)):
        slot = None
        for e in T.slots:
            if (mid, i) in T.g.entrances[e]:
                slot = T.slot_of[e]
        if slot is None:
            continue
        setup()
        put_world()
        if not enter(town, (x, y + 1)):
            print('could not enter', town); continue
        g.pb.button('up', 8)
        for k in range(30): g.tick(10)
        want = T.g.arrival[T.slots[part[slot]]]
        got = (m[A('wCurMap')], )
        res = got[0] == want[0]
        ok += res; bad += not res
        print('%-14s warp %d (%d,%d) -> %-24s %s' % (town, i, x, y, names.get(got[0], got[0]),
              'ok' if res else 'WANT %s' % names.get(want[0], want[0])))
print('ok', ok, 'bad', bad)

# round trips: in through a door, then straight back out
print('round trips')
for town, i in [('PEWTER_CITY', 0), ('PEWTER_CITY', 2), ('PEWTER_CITY', 6), ('CERULEAN_CITY', 0), ('CERULEAN_CITY', 3), ('VIRIDIAN_CITY', 2)]:
    mid = MAPS[town][0]
    x, y = warps(mid)[i]
    setup(); put_world(); enter(town, (x, y + 1))
    g.pb.button('up', 8)
    for k in range(30): g.tick(10)
    inside = m[A('wCurMap')]
    for k in range(4):
        g.pb.button('down', 8)
        for j in range(12): g.tick(10)
        if m[A('wCurMap')] != inside: break
    back = (m[A('wCurMap')], m[A('wXCoord')], m[A('wYCoord')])
    print('%-14s %d: in %-22s back %-14s (%d,%d)  %s' % (town, i, names.get(inside), names.get(back[0]), back[1], back[2],
          'ok' if back[0] == mid else 'NO'))
