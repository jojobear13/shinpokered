"""The RANDOM #MON options played through: gifts, SNORLAX, MEWTWO, the
ELITE FOUR and the champion with every option on, checking that the #MON
changed, the bosses kept their types and nothing crashed."""
import sys
from story import *
sys.path.insert(0, '/home/user/shinpokered/tools/rando')
import mons as MN, rom as RM
MD = MN.Mons(RM.Rom('pokered'))
SEED = int(sys.argv[1]) if len(sys.argv) > 1 else 1234
results = {}
foes = []
b, a = ENT['LoadEnemyMonData']
g.pb.hook_register(b, a, lambda _: foes.append(m[A('wEnemyMonSpecies2')]), None)

def play():
    """run() until a battle has been fought (it can give up during a long
    battle transition)"""
    del foes[:]
    total = 0
    for _ in range(4):
        r = run()
        total += r['battles']
        if total:
            break
    r['battles'] = total
    return r

def rando():
    for i, v in enumerate(SEED.to_bytes(4, 'little')):
        m[A('wRandoSeed') + i] = v
    m[A('wRandoFlags')] = 0x84                  # ITEMS, a seed typed
    m[A('wRandoFlags2')] = 2 | 1 << 2 | 1 << 3 | 1 << 4 | 1 << 5   # STARTERS TYPES, SPECIAL, TRADES, TRAINERS ALL, WILD AREA
    m[A('wRandoFlags3')] = 1 | 1 << 1 | 1 << 3  # TM MOVES, TM COMPAT. TYPE, LEARNSETS TYPE

def check(name, **conds):
    ok = all(conds.values()) and not crash[0]
    results[name] = ok
    print(('PASS ' if ok else 'FAIL ') + name, {k: v for k, v in conds.items()}, 'crash' if crash[0] else '', flush=True)

def enemy_types():
    """the types of the enemy party's #MON"""
    n = m[A('wEnemyPartyCount')]
    return [MD.types.get(m[A('wEnemyPartyMons') + k], (None, None)) for k in range(n)]

# gifts change
setup(events=['EVENT_BEAT_SILPH_CO_GIOVANNI', 'EVENT_BEAT_SILPH_CO_RIVAL'], badges=0x1F)
rando(); n = m[A('wPartyCount')]
approach('SILPH_CO_7F', 1); run()
got = m[A('wPartySpecies') + n]
check('lapras_gift', party_grew=m[A('wPartyCount')] == n + 1, not_lapras=got != SP['LAPRAS'], species=MD.name.get(got))
setup(events=[e for e in EV if e.startswith('EVENT_BEAT_FIGHTING_DOJO_TRAINER')] + ['EVENT_BEAT_KARATE_MASTER', 'EVENT_DEFEATED_FIGHTING_DOJO'], badges=0x1F)
rando(); n = m[A('wPartyCount')]
approach('FIGHTING_DOJO', 6); run()
got = m[A('wPartySpecies') + n]
check('dojo_gift', party_grew=m[A('wPartyCount')] == n + 1, changed=got not in (SP['HITMONLEE'], SP['HITMONCHAN']), species=MD.name.get(got))
# SNORLAX and MEWTWO: other ones of their strength
setup(badges=0x1F, items=[('POKE_FLUTE', 1)])
rando()
approach('ROUTE_12', 1); r = play()
foe = foes[0] if foes else None
check('snorlax', battles=r['battles'] == 1, beat=event('EVENT_BEAT_ROUTE12_SNORLAX'), foe=MD.name.get(foe),
      changed=foe not in (None, SP['SNORLAX']))
setup(badges=0xFF, events=['EVENT_BEAT_CHAMPION_RIVAL'])
rando()
approach('UNKNOWN_DUNGEON_3', 1); r = play()
foe = foes[0] if foes else None
check('mewtwo', battles=r['battles'] == 1, legendary=foe in MD.legendary, foe=MD.name.get(foe))
# the ELITE FOUR keep their types
for room, ev, kind in (('LORELEIS_ROOM', 'EVENT_BEAT_LORELEIS_ROOM_TRAINER_0', 'ICE'),
                       ('BRUNOS_ROOM', 'EVENT_BEAT_BRUNOS_ROOM_TRAINER_0', 'FIGHTING'),
                       ('AGATHAS_ROOM', 'EVENT_BEAT_AGATHAS_ROOM_TRAINER_0', 'GHOST'),
                       ('LANCES_ROOM', 'EVENT_BEAT_LANCES_ROOM_TRAINER_0', 'DRAGON')):
    setup(badges=0xFF)
    rando()
    approach(room, 1); r = play()
    types = enemy_types()
    check(room.lower(), battles=r['battles'] == 1, beat=event(ev), themed=all(MN.TYPES[kind] in t for t in types) and len(types) > 0,
          team=[MD.name.get(m[A('wEnemyPartyMons') + k]) for k in range(m[A('wEnemyPartyCount')])])
print('passed', sum(results.values()), 'of', len(results))
