from story import *
import sys
results={}
def check(name, **conds):
    ok=all(conds.values())
    results[name]=dict(ok=ok, **{k:bool(v) for k,v in conds.items()}, crash=crash[0])
    print(('PASS ' if ok and not crash[0] else 'FAIL ')+name, {k:bool(v) for k,v in conds.items()}, 'crash' if crash[0] else '', flush=True)
def trainers(prefix):
    return [e for e in EV if e.startswith(prefix)]
only=sys.argv[1:]
def want(n): return not only or n in only

if want('fuji'):
    setup(events=trainers('EVENT_BEAT_POKEMONTOWER_7_TRAINER'), badges=0x0F)
    approach('POKEMONTOWER_7', 4); r=run()
    check('fuji', rescued=event('EVENT_RESCUED_MR_FUJI'), in_house=m[A('wCurMap')]==MAPS['LAVENDER_HOUSE_1'][0])
    approach('LAVENDER_HOUSE_1', 5); r=run()
    check('poke_flute', flute=IT['POKE_FLUTE'] in bag(), event=event('EVENT_GOT_POKE_FLUTE'))
if want('hideout'):
    setup(events=trainers('EVENT_BEAT_ROCKET_HIDEOUT_4_TRAINER'), badges=0x0F, items=[('LIFT_KEY',1)])
    approach('ROCKET_HIDEOUT_4', 1); r=run()
    beat=event('EVENT_BEAT_ROCKET_HIDEOUT_GIOVANNI')
    approach('ROCKET_HIDEOUT_4', 8, sides=[((25,3),'up'),((24,2),'right'),((26,2),'left')]); r2=run()
    check('rocket_hideout_giovanni', beat=beat, battles=r['battles']==1, silph_scope=IT['SILPH_SCOPE'] in bag())
if want('marowak'):
    setup(events=trainers('EVENT_BEAT_POKEMONTOWER_6_TRAINER'), badges=0x0F, items=[('SILPH_SCOPE',1)])
    enter('POKEMONTOWER_6', pos=(10,17)); g.press('up',30); r=run()
    check('ghost_marowak', beat=event('EVENT_BEAT_GHOST_MAROWAK'), battles=r['battles']==1)
if want('silph'):
    setup(events=trainers('EVENT_BEAT_SILPH_CO_11F_TRAINER')+['EVENT_BEAT_SILPH_CO_RIVAL','EVENT_SILPH_CO_11_UNLOCKED_DOOR'], badges=0x1F, items=[('CARD_KEY',1)])
    enter('SILPH_CO_11F', pos=(6,14)); g.press('up',30); r=run()   # Giovanni's trigger at (6,13)
    beat=event('EVENT_BEAT_SILPH_CO_GIOVANNI') and r['battles']==1
    approach('SILPH_CO_11F', 1); r2=run()
    check('silph_giovanni_and_master_ball', beat=beat, master_ball=IT['MASTER_BALL'] in bag(), event=event('EVENT_GOT_MASTER_BALL'))
    setup(events=['EVENT_BEAT_SILPH_CO_GIOVANNI','EVENT_BEAT_SILPH_CO_RIVAL'], badges=0x1F)
    n=m[A('wPartyCount')]
    approach('SILPH_CO_7F', 1); r=run()
    check('lapras_gift', party_grew=m[A('wPartyCount')]==n+1, lapras=m[A('wPartySpecies')+n]==SP['LAPRAS'])
if want('dojo'):
    setup(events=trainers('EVENT_BEAT_FIGHTING_DOJO_TRAINER')+['EVENT_BEAT_KARATE_MASTER','EVENT_DEFEATED_FIGHTING_DOJO'], badges=0x1F)
    n=m[A('wPartyCount')]
    approach('FIGHTING_DOJO', 6); r=run()
    check('dojo_gift', party_grew=m[A('wPartyCount')]==n+1, got=event('EVENT_GOT_HITMONLEE') or event('EVENT_GOT_HITMONCHAN'))
if want('warden'):
    setup(badges=0x1F, items=[('GOLD_TEETH',1)])
    approach('FUCHSIA_HOUSE_2', 1); r=run()
    check('warden_strength', hm04=tm_owned(4, hm=True), teeth_given=event('EVENT_GAVE_GOLD_TEETH'))
    setup(badges=0x1F)
    approach('SAFARI_ZONE_SECRET_HOUSE', 1); r=run()
    check('surf_house', hm03=tm_owned(3, hm=True), event=event('EVENT_GOT_HM03'))
if want('fossil'):
    setup(badges=0x7F, items=[('HELIX_FOSSIL',1)])
    enter('CINNABAR_LAB_4'); r=run(talk=1)   # the walking scientist
    gave=event('EVENT_GAVE_FOSSIL_TO_LAB') and IT['HELIX_FOSSIL'] not in bag()
    n=m[A('wPartyCount')]
    enter('CINNABAR_ISLAND'); run()          # its script: the fossil is ready
    enter('CINNABAR_LAB_4'); r=run(talk=1)
    check('fossil_revival', gave=gave, party_grew=m[A('wPartyCount')]==n+1, omanyte=m[A('wPartySpecies')+n]==SP['OMANYTE'])
if want('snorlax'):
    setup(badges=0x1F, items=[('POKE_FLUTE',1)])
    approach('ROUTE_12', 1); r=run()   # Shin plays the flute when you talk to it with one
    check('snorlax', battles=r['battles']==1, beat=event('EVENT_BEAT_ROUTE12_SNORLAX'))
if want('mewtwo'):
    setup(badges=0xFF, events=['EVENT_BEAT_CHAMPION_RIVAL'])
    approach('UNKNOWN_DUNGEON_3', 1, sides=[((27,14),'up'),((26,13),'right'),((28,13),'left')]); r=run()
    check('mewtwo', battles=r['battles']==1, beat=event('EVENT_BEAT_MEWTWO'))
if want('e4'):
    for room,ev in (('LORELEIS_ROOM','EVENT_BEAT_LORELEIS_ROOM_TRAINER_0'),('BRUNOS_ROOM','EVENT_BEAT_BRUNOS_ROOM_TRAINER_0'),
                    ('AGATHAS_ROOM','EVENT_BEAT_AGATHAS_ROOM_TRAINER_0'),('LANCES_ROOM','EVENT_BEAT_LANCES_ROOM_TRAINER_0')):
        setup(badges=0xFF)
        approach(room, 1); r=run()
        check(room.lower(), battles=r['battles']==1, beat=event(ev))
if want('champion'):
    setup(badges=0xFF, events=[e for e in EV if 'S_ROOM_TRAINER_0' in e])
    hof=m[A('wNumHoFTeams')]
    enter('CHAMPIONS_ROOM'); m[A('wGaryCurScript')]=1
    maps=set(); lines=[]
    for k in range(40):
        r=run(frames=12000); lines+=r['lines']; maps.add(m[A('wCurMap')])
        if r['result']=='idle' and k>3: break
    g.pb.screen.image.save('/tmp/pk30emu/out/story_champion_end.png')
    check('champion_and_hall_of_fame', beat=event('EVENT_BEAT_CHAMPION_RIVAL'), hall=MAPS['HALL_OF_FAME'][0] in maps, hof_count=m[A('wNumHoFTeams')]==hof+1)
    print('  last lines:', lines[-6:])
json.dump(results, open('/tmp/pk30emu/out/story_events.json','w'), indent=1)
