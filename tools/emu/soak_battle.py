"""Battle soak: random parties and options, full emulated battles, with
per-turn invariants, stack depth, RAM-execution and hang checks."""
import sys, io, json, random
from lib import *
from dxlib import screen, box
sys.path.insert(0,'/home/user/shinpokered/tests')
import test_data_integrity as tdi
ENT={}
for l in open('/tmp/pk30emu/rom.sym'):
    if l[0]==';' or not l.strip(): continue
    b,rest=l.split(':'); a,n=rest.split(); ENT[n]=(int(b,16),int(a,16))
A=lambda n: ENT[n][1]
seed=int(sys.argv[1]); count=int(sys.argv[2])
rng=random.Random(seed)
g=G(); m=g.m
sys.path.insert(0,'/home/user/shinpokered/tests')
from harness import Game
hg=Game()
def build_party(party):
    hg.reset(); hg.skip_delays(); hg.skip_sound_waits(); hg.auto_buttons(); hg.poke('wIsInBattle',0)
    hg.poke('wPartyCount',0); hg.poke('wPartySpecies',0xFF)
    for sp,lv,moves,_t,extra in party:
        hg.poke('wcf91',SP[sp]); hg.poke('wd11e',SP[sp]); hg.poke('wCurEnemyLVL',lv); hg.poke('wMonDataLocation',0)
        hg.clear_random(); hg.queue_random(*[rng.randint(0,255) for _ in range(60)])
        hg.call('AddPartyMon', max_frames=20000)
        k=hg.peek('wPartyCount')-1; o=k*44
        mv=[MV[x] for x in moves]+[0]*(4-len(moves))
        hg.poke(f'wPartyMon1Moves+{o}',*mv)
        hg.poke(f'wPartyMon1PP+{o}',*[g.move_pp(x) if x else 0 for x in mv])
        hg.poke(f'wPartyMon1CatchRate+{o}',extra['item'])
    start=hg.addr('wPartyDataStart'); end=hg.addr('wPartyDataEnd')
    data=hg.peek('wPartyDataStart', end-start)
    for i,v in enumerate(data): m[start+i]=v
INVSP={v:k for k,v in SP.items() if not k.startswith(('MISSINGNO','FOSSIL_')) and k!='MON_GHOST'}
NUM_ATTACKS=tdi.NUM_ATTACKS
def rom(b,a,n=1): return [m[(b if a>=0x4000 else 0),a+i] for i in range(n)]
eb,et=ENT['EvosMovesPointerTable']
def learnset(idx):
    p=rom(eb,et+2*(idx-1),2); a=p[0]|p[1]<<8
    while True:
        k=rom(eb,a)[0]
        if k==0: a+=1; break
        a+= 4 if k==2 else 3
    out=[]
    while True:
        lv=rom(eb,a)[0]
        if lv==0: break
        out.append((lv,rom(eb,a+1)[0])); a+=2
    return out
LEARN={i:learnset(i) for i in INVSP}
# level-1 moves from base stats
bb,bt=ENT['BaseStats']
MV_NAME={v:k for k,v in MV.items()}
HELD=[v for k,v in IT.items() if IT['BLACK_BELT']<=v<IT['DEXREPEL']]
TYPES={}
for i,n in INVSP.items():
    pass
base=io.BytesIO(); g.pb.save_state(base)
# watchers
minsp=[0xFFFF]; crash=[0]; ramexec=[0]
def on_delay(_):
    sp=g.pb.register_file.SP
    if sp<minsp[0]: minsp[0]=sp
g.pb.hook_register(0,A('DelayFrame'),on_delay,None)
cur_tag=['']
def on38(_):
    rf=g.pb.register_file
    if crash[0]==0:
        sp=rf.SP
        crash_info.append(dict(tag=cur_tag[0], sp=hex(sp), bank=hex(m[0xFFB8]), stack=[hex(m[sp+2*k]|m[sp+2*k+1]<<8) for k in range(12)]))
        with open(f'/tmp/pk30emu/out/crash_{seed}_{len(crash_info)}.state','wb') as fh: g.pb.save_state(fh)
    crash[0]+=1
    rf.SP=0xDFFF; rf.PC=0x0100   # reboot instead of looping in rst $38
crash_info=[]
g.pb.hook_register(0,0x38,on38,None)
dumped=[0]; problems=[]; stats={'battles':0,'turns':0,'ended':0,'blackout':0}
def rand_mon(i):
    idx=rng.choice(list(INVSP)); sp=INVSP[idx]; lv=rng.randint(5,100)
    pool=sorted({mv for l,mv in LEARN[idx] if l<=lv})
    moves=rng.sample(pool, min(4,len(pool))) if pool else []
    if not moves: moves=[MV['TACKLE']]
    item=rng.choice(HELD) if rng.random()<0.6 else 0
    names=[MV_NAME[x] for x in moves]
    return (sp,lv,names,['NORMAL'],dict(item=item,flags=rng.randint(0,3),hp=lv*3+20))
def set_event(e,on):
    a=A('wEventFlags')+e//8; m[a]=(m[a]&~(1<<(e%8)))|(on<<(e%8))
def check(where):
    pr=[]
    def hp(addr): return m[addr]<<8|m[addr+1]
    if hp(A('wBattleMonHP'))>hp(A('wBattleMonMaxHP')): pr.append('player HP>max')
    if hp(A('wEnemyMonHP'))>hp(A('wEnemyMonMaxHP')): pr.append('enemy HP>max')
    for side in ('wPlayerMonStatMods','wEnemyMonStatMods'):
        mods=[m[A(side)+k] for k in range(7)]
        if any(not 1<=x<=13 for x in mods): pr.append(f'{side} {mods}')
    for side in ('wBattleMonMoves','wEnemyMonMoves'):
        mv=[m[A(side)+k] for k in range(4)]
        if any(x>NUM_ATTACKS for x in mv): pr.append(f'{side} {mv}')
    for k in range(m[A('wPartyCount')]):
        o=k*44
        if hp(A('wPartyMon1HP')+o)>hp(A('wPartyMon1MaxHP')+o): pr.append(f'party{k} HP>max')
    for k in range(min(6,m[A('wEnemyPartyCount')])):
        if k==m[A('wEnemyMonPartyPos')]: continue  # its party copy's max HP is stale by design
        o=k*44
        if hp(A('wEnemyMon1HP')+o)>hp(A('wEnemyMon1MaxHP')+o): pr.append(f'enemy party{k} HP>max: {hp(A("wEnemyMon1HP")+o)}/{hp(A("wEnemyMon1MaxHP")+o)} species {m[A("wEnemyMon1HP")+o-1]} lv {m[A("wEnemyMon1MaxHP")+o-1]} active {m[A("wEnemyMonPartyPos")]} activeHP {hp(A("wEnemyMonHP"))}/{hp(A("wEnemyMonMaxHP"))}')
    if pr:
        problems.append((where,pr))
        if not dumped[0]:
            dumped[0]=1
            with open(f'/tmp/pk30emu/out/hpmax_{seed}.state','wb') as fh: g.pb.save_state(fh)
    return pr
for n in range(count):
    base.seek(0); g.pb.load_state(base)
    party=[rand_mon(i) for i in range(rng.randint(1,6))]
    build_party(party)
    opts={}
    for name,e in (('expshare',0x8D1),('sleepclause',0x8DC),('freezeclause',0x8DD),('itemclause',0x8DB),
                   ('trapclause',0x8C5),('hbclause',0x8C8),('altmoves',0x8C9),('scaling',0x90C),('randtrainers',0x8D8)):
        opts[name]=rng.random()<0.3; set_event(e,opts[name])
    o=m[A('wOptions')]&0x30
    o|=rng.choice([1,3,5])
    if rng.random()<0.3: o|=0x08; opts['hard']=True
    if rng.random()<0.5: o|=0x40; opts['set']=True
    if rng.random()<0.85: o|=0x80
    else: opts['anims']=True
    m[A('wOptions')]=o
    m[A('wDisplayOptions')]=rng.randint(0,15)
    if rng.random()<0.7:
        cls,no,mons=rng.choice(tdi.PARTIES); m[A('wCurOpponent')]=cls+200; m[A('wTrainerNo')]=no; foe=f'trainer {cls}:{no}'
    else:
        sp=rng.choice(list(INVSP.values())); lv=rng.randint(2,100)
        m[A('wCurOpponent')]=SP[sp]; m[A('wCurEnemyLVL')]=lv; foe=f'wild {sp} {lv}'
    crash[0]=0; started=False; result='timeout'; turns=0
    tag=f'seed {seed} #{n} vs {foe} party={[(p[0],p[1],p[2],p[4]["item"]) for p in party]} opts={opts}'
    cur_tag[0]=tag
    for f in range(9000):
        g.tick(4)
        pc=g.pb.register_file.PC
        if 0xC000<=pc<0xFF80 and not ramexec[0] and not crash[0]:
            ramexec[0]=pc; problems.append((tag,[f'executing RAM at {pc:04x}']))
        inb=m[A('wIsInBattle')]
        if inb: started=True
        if crash[0]: result='crash'; break
        if started and not inb: result='ended'; break
        scr=screen(g)
        if inb and 'FIGHT' in scr and 'RUN' in scr:
            turns+=1
            check(tag+f' turn {turns}')
            dis=(m[A('wPlayerDisabledMove')]>>4)-1
            valid=[k for k in range(4) if m[A('wBattleMonMoves')+k] and (m[A('wBattleMonPP')+k]&0x3F) and k!=dis]
            lock=m[A('wPlayerChoiceLock')]-1
            if lock>=0 and lock in valid: valid=[lock]
            m[A('wPlayerMoveListIndex')]=rng.choice(valid) if valid else 0
            g.press('a',6); g.press('a',6)
        elif 'YES' in scr and 'NO' in scr:
            if 'Abandon' in scr or 'Use next' in scr or 'next POK' in scr: g.press('a',6)
            else: g.press('b',6)
        elif 'Bring out which' in scr or 'Choose a POK' in scr:
            g.press('down',4); g.press('a',6)
        else:
            g.pb.button('a',3)
    if m[A('wCurMap')]!=0x26 and result=='ended': stats['blackout']+=1
    stats['battles']+=1; stats['turns']+=turns
    if result=='ended': stats['ended']+=1
    else:
        problems.append((tag,[result]))
        g.pb.screen.image.save(f'/tmp/pk30emu/out/soak_{seed}_{n}.png')
    if result!='ended' or (problems and problems[-1][0].startswith(tag)):
        print(result, tag, problems[-1][1] if problems else '', flush=True)
print('STATS', seed, stats, 'min SP', hex(minsp[0]), 'problems', len(problems), flush=True)
json.dump(dict(stats=stats, minsp=minsp[0], problems=problems, crashes=crash_info), open(f'/tmp/pk30emu/out/soak_{seed}.json','w'), indent=1)
