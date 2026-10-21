from story import *
def snap(names):
    out={}
    for n,l in names: out[n]=[m[A(n)+i] for i in range(l)]
    return out
KEEP=[('wPartyCount',1+6+1),('wPartyMon1',44*2),('wNumBagItems',1+2*4),('wEventFlags',320),('wTMsOwned',7),
      ('wTypeChartSeen',46),('wDisplayOptions',1),('wObtainedBadges',1),('wCurMap',1),('wXCoord',1),('wYCoord',1),
      ('wPokedexOwned',19),('wPlayerMoney',3),('wLastRepelUsed',1)]
setup(badges=0xFF, events=['EVENT_908','EVENT_BEAT_CHAMPION_RIVAL','EVENT_BEAT_BROCK'], items=[('POTION',3),('DEXREPEL',1)],
      party=[('MEWTWO',100,['SURF','PSYCHIC_M']),('PIKACHU',30,['THUNDERSHOCK'])])
for i in range(7): m[A('wTMsOwned')+i]=0x55
for i in range(46): m[A('wTypeChartSeen')+i]=(i*37)&0xFF
m[A('wDisplayOptions')]=0x0D; m[A('wLastRepelUsed')]=IT['SUPER_REPEL']
for i in range(19): m[A('wPokedexOwned')+i]=0xFF; m[A('wPokedexSeen')+i]=0xFF
enter('VIRIDIAN_CITY', pos=(23,26)); run()
before=snap(KEEP)
# save from the start menu
g.press('start',40)
for k in range(8):
    if '▶SAVE' in screen(g): break
    g.press('down',12)
g.press('a',60)
lines=[]
for k in range(60):
    b=boxed()
    if b and (not lines or lines[-1]!=b): lines.append(b)
    scr=screen(g)
    if 'YES' in scr: g.press('a',30)
    else: g.press('a',20)
    if 'saved the game' in ' '.join(lines): break
print('save text:', lines[-2:])
for k in range(4): g.press('b',20)
# soft reset, CONTINUE
def to_main_menu():
    g.pb.register_file.PC=0x0100; g.pb.register_file.SP=0xDFFF
    for k in range(60):
        g.tick(30)
        if 'CONTINUE' in screen(g): return True
        g.pb.button('start',3)
    return False
to_main_menu()
print('menu:', [l for l in screen(g).split('\n') if 'CONTINUE' in l or 'NEW' in l][:3])
g.press('a',60); g.press('a',120)
for k in range(10): g.tick(30)
after=snap(KEEP)
diff=[n for n in before if before[n]!=after[n]]
ev_diff=[]
for i,(x,y) in enumerate(zip(before['wEventFlags'],after['wEventFlags'])):
    for b_ in range(8):
        if (x^y)>>b_&1: ev_diff.append(i*8+b_)
if ev_diff==[EV['EVENT_9FF']]: diff.remove('wEventFlags')   # Shin's "a save exists" flag, set by saving
print('SAVE/LOAD', 'PASS' if not diff else 'FAIL', diff)
# NEW GAME+: reset, choose NEW GAME holding SELECT
to_main_menu()
for k in range(4):
    if '▶NEW GAME' in screen(g): break
    g.press('down',12)
g.pb.button_press('select'); g.tick(10); g.pb.button('a',4); g.tick(900); g.pb.button_release('select')
lines=[]
for k in range(400):
    g.tick(10)
    b=boxed()
    if b and (not lines or lines[-1]!=b): lines.append(b)
    scr=screen(g)
    if 'YES' in scr and 'NO' in scr: g.press('b',10)   # keep the trainer ID
    elif 'NEW NAME' in scr: g.press('down',10); g.press('a',30)   # first preset name
    else: g.pb.button('a',3)
    if m[A('wCurMap')]==MAPS['REDS_HOUSE_2F'][0] and not boxed() and k>100: break
ng=snap(KEEP)
kept=dict(tms=ng['wTMsOwned']==before['wTMsOwned'], type_chart=ng['wTypeChartSeen']==before['wTypeChartSeen'],
          dex=ng['wPokedexOwned']==before['wPokedexOwned'], options=ng['wDisplayOptions']==before['wDisplayOptions'])
cleared=dict(party=ng['wPartyCount'][0]==0, badges=ng['wObtainedBadges'][0]==0, brock=not event('EVENT_BEAT_BROCK'),
             in_reds_room=ng['wCurMap'][0]==MAPS['REDS_HOUSE_2F'][0])
print('NEW GAME+', 'PASS' if all(kept.values()) and all(cleared.values()) else 'FAIL', kept, cleared)
print('  ', [l for l in lines if 'ID' in l or 'jingle' in l][:3])
