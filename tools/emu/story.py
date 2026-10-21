"""Story checkpoints: set up the flags, party and bag a player would have,
enter the map, trigger the event, play it through, and check the outcome."""
import sys, io, re, json, os, glob
ROOT='/tmp/pk30emu/'.rstrip('/'); REPO='/home/user/shinpokered'
from lib import *
from dxlib import screen, box
sys.path.insert(0,'/home/user/shinpokered/tests')
from harness import Game
R='/home/user/shinpokered'
ENT={}
for l in open('/tmp/pk30emu/rom.sym'):
    if l[0]==';' or not l.strip(): continue
    b,rest=l.split(':'); a,n=rest.split(); ENT[n]=(int(b,16),int(a,16))
A=lambda n: ENT[n][1]
EV={m.group(1):int(m.group(2),16) for m in re.finditer(r'const (EVENT_\w+)[^\n]*?;\s*([0-9A-F]{3}), \(D', open(R+'/constants/event_constants.asm').read())}
MAPS={m.group(1):(int(m.group(4),16),int(m.group(2)),int(m.group(3))) for m in re.finditer(r'mapconst (\w+),\s*(\d+),\s*(\d+)\s*; \$([0-9A-F]+)', open(R+'/constants/map_constants.asm').read())}
ABIL={m.group(1):int(m.group(2),16) for m in re.finditer(r'const (\w+)\s*; \$([0-9A-F]+)', open(R+'/constants/ability_constants.asm').read())}
# map -> first warp, as the map sweep
hdr=re.findall(r'dw (\w+)', open(R+'/data/map_header_pointers.asm').read())
import glob
objfile={}
for f in glob.glob(R+'/data/mapObjects/*.asm'):
    for lab in re.findall(r'^(\w+Object):', open(f).read(), re.M): objfile[lab]=f
hdrobj={}
for f in glob.glob(R+'/data/mapHeaders/*.asm'):
    t=open(f).read()
    for h in re.findall(r'^(\w+_h):', t, re.M):
        o=re.findall(r'dw (\w+Object)', t)
        if o: hdrobj[h]=o[-1]
def warps(mid):
    t=preprocess(open(objfile[hdrobj[hdr[mid]]]).read())
    return [(int(x),int(y)) for x,y in re.findall(r'^\s*warp (\d+), (\d+)', t, re.M)]

g=G(); m=g.m
hg=Game()
base=io.BytesIO(); g.pb.save_state(base)
crash=[0]
def on38(_):
    crash[0]+=1; g.pb.register_file.SP=0xDFFF; g.pb.register_file.PC=0x0100
g.pb.hook_register(0,0x38,on38,None)
target=[None]; BUF=0xDD40
def on_copy(_):
    t=target[0]
    if t is None: return
    mid,h,w,x,y=t
    ptr=A('wOverworldMap')+7+w+(w+6)*(y>>1)+(x>>1)
    for i,v in enumerate([ptr&0xff,ptr>>8,y,x,y&1,x&1]): m[BUF+i]=v
    m[A('wCurMap')]=mid; g.pb.register_file.HL=BUF; target[0]=None
g.pb.hook_register(*ENT['LoadSpecialWarpData.copyWarpData2'],on_copy,None)
inject=[None]; loops=[0]
def on_loop(_):
    loops[0]+=1
    t=inject[0]
    if t is None: return
    inject[0]=None
    m[0xFF8C]=t
    rf=g.pb.register_file; sp=rf.SP-2; ret=A('OverworldLoop')
    m[sp]=ret&0xff; m[sp+1]=ret>>8; rf.SP=sp; rf.PC=A('DisplayTextID')
g.pb.hook_register(0,A('OverworldLoop'),on_loop,None)

def set_event(name,on=True):
    e=EV[name]; a=A('wEventFlags')+e//8; m[a]=(m[a]&~(1<<(e%8)))|(on<<(e%8))
def event(name):
    e=EV[name]; return bool(m[A('wEventFlags')+e//8]>>(e%8)&1)
def tm_owned(n, hm=False):
    i=(50+n-1) if hm else n-1; return bool(m[A('wTMsOwned')+i//8]>>(i%8)&1)
def bag():
    return {m[A('wBagItems')+2*k]:m[A('wBagItems')+2*k+1] for k in range(m[A('wNumBagItems')])}
def build_party(mons):
    hg.reset(); hg.skip_delays(); hg.skip_sound_waits(); hg.auto_buttons(); hg.poke('wIsInBattle',0)
    hg.poke('wPartyCount',0); hg.poke('wPartySpecies',0xFF); hg.poke('wPlayerID',m[A('wPlayerID')],m[A('wPlayerID')+1])
    hg.poke('wPlayerName',*[m[A('wPlayerName')+i] for i in range(11)])
    for sp,lv,moves in mons:
        hg.poke('wcf91',SP[sp]); hg.poke('wd11e',SP[sp]); hg.poke('wCurEnemyLVL',lv); hg.poke('wMonDataLocation',0)
        hg.clear_random(); hg.queue_random(*[(i*37+11)&0xFF for i in range(60)])
        hg.call('AddPartyMon', max_frames=20000)
        k=hg.peek('wPartyCount')-1; o=k*44
        mv=[MV[x] for x in moves]+[0]*(4-len(moves))
        hg.poke(f'wPartyMon1Moves+{o}',*mv); hg.poke(f'wPartyMon1PP+{o}',*[g.move_pp(x) if x else 0 for x in mv])
    start=hg.addr('wPartyDataStart'); end=hg.addr('wPartyDataEnd')
    for i,v in enumerate(hg.peek('wPartyDataStart', end-start)): m[start+i]=v
STRONG=[('MEWTWO',100,['SURF','PSYCHIC_M','STRENGTH','FLY'])]

def setup(events=(), badges=0, items=(), party=STRONG):
    base.seek(0); g.pb.load_state(base); crash[0]=0
    build_party(party)
    for e in ('EVENT_GOT_STARTER','EVENT_GOT_POKEDEX','EVENT_OAK_GOT_PARCEL','EVENT_BATTLED_RIVAL_IN_OAKS_LAB')+tuple(events):
        if e in EV: set_event(e)
    m[A('wObtainedBadges')]=badges
    m[A('wNumBagItems')]=len(items)
    for k,(it,q) in enumerate(items): m[A('wBagItems')+2*k]=IT[it]; m[A('wBagItems')+2*k+1]=q
    m[A('wBagItems')+2*len(items)]=0xFF
    m[A('wOptions')]=(m[A('wOptions')]&0x30)|0x01|0x80|0x40   # fast text, no animations, SET

def enter(mapname, pos=None):
    mid,h,w=MAPS[mapname]
    if pos is None:
        ws=warps(mid); pos=ws[0] if ws else (w,h)
    target[0]=(mid,h,w,pos[0],pos[1])
    m[A('wDestinationMap')]=0; m[A('wd732')] |= 1<<3
    for k in range(40): g.tick(10)
    return m[A('wCurMap')]==mid

def boxed():
    tl=g.tiles(); return box(g).strip() if tl[12*20]==0x79 and tl[17*20]==0x7D else ''

def run(talk=None, yes=True, frames=60000, log=None):
    """Play until the field is idle (no text, no battle, joypad free) for a while."""
    if talk is not None: inject[0]=talk
    lines=[]; idle=0; battles=0; inb_prev=False; seen=[]
    for f in range(frames//6):
        g.tick(6)
        if crash[0]: return dict(result='crash', lines=lines, battles=battles)
        b=boxed()
        c=b.replace(' ','').replace('/','')
        if c:
            if seen and c.startswith(seen[-1]): seen[-1]=c; lines[-1]=b
            elif not seen or seen[-1]!=c: seen.append(c); lines.append(b)
        inb=m[A('wIsInBattle')]
        if inb and not inb_prev: battles+=1
        inb_prev=inb
        scr=screen(g)
        if inb and 'FIGHT' in scr and 'RUN' in scr:
            m[A('wBattleMonHP')]=m[A('wBattleMonMaxHP')]; m[A('wBattleMonHP')+1]=m[A('wBattleMonMaxHP')+1]
            m[A('wBattleMonStatus')]=0; m[A('wPlayerDisabledMove')]=0
            ab=m[A('wEnemyAbility')]
            slot=1 if ab==ABIL.get('WATER_ABSORB',-1) else 0
            m[A('wPlayerMoveListIndex')]=slot
            m[A('wEnemyMonHP')]=0; m[A('wEnemyMonHP')+1]=1
            g.press('a',6); g.press('a',6); idle=0; continue
        if 'YES' in scr and 'NO' in scr:
            nick=('nickname' in scr) or ('NICKNAME' in scr)
            g.press('a' if (yes and not nick) else 'b',8); idle=0; continue
        if inb or b or m[A('wJoyIgnore')]:
            g.pb.button('a',3); idle=0; continue
        idle+=1
        if idle>40: return dict(result='idle', lines=lines, battles=battles)
        if idle%10==5: g.pb.button('b',3)
    return dict(result='timeout', lines=lines, battles=battles)

def build_defs():
    """The -D flags of the build the workspace ROM came from (by matching it
    against the repo's built ROMs and reading the Makefile)."""
    rom=open(ROOT+'/rom.gbc','rb').read()
    for f in glob.glob(REPO+'/*.gbc'):
        if open(f,'rb').read()==rom:
            name=os.path.basename(f)[:-4]
            mk=re.search(r'^\$\(%s_obj\):\s*RGBASMFLAGS \+=(.*)$' % name, open(REPO+'/Makefile').read(), re.M)
            return set(re.findall(r'-D (\w+)', mk.group(1))) if mk else set()
    return set()
DEFS=build_defs()

def preprocess(t):
    """Keep the IF DEF(x)/ELSE/ENDC branches this build assembles."""
    out=[]; stack=[]
    for line in t.split('\n'):
        c=line.split(';')[0].strip()
        mo=re.match(r'IF\s+(!?)DEF\((\w+)\)', c)
        if mo: stack.append((mo.group(2) in DEFS) != bool(mo.group(1))); continue
        if c=='ELSE' and stack: stack[-1]=not stack[-1]; continue
        if c=='ENDC' and stack: stack.pop(); continue
        if all(stack): out.append(line)
    return '\n'.join(out)

def objects(mapname):
    mid=MAPS[mapname][0]
    t=preprocess(open(objfile[hdrobj[hdr[mid]]]).read())
    return [(int(x),int(y)) for x,y in re.findall(r'^\s*object \w+, (\d+), (\d+),', t, re.M)]

def approach(mapname, n, sides=None):
    """Stand next to object n (1-based), facing it, and press A; True if a
    text box opened."""
    ox,oy=objects(mapname)[n-1]
    sides=sides or [((ox,oy+1),'up'),((ox-1,oy),'right'),((ox+1,oy),'left'),((ox,oy-1),'down')]
    snap=io.BytesIO(); g.pb.save_state(snap)
    for pos,face in sides:
        snap.seek(0); g.pb.load_state(snap)
        if not enter(mapname, pos=pos): continue
        if (m[A('wXCoord')],m[A('wYCoord')])!=pos: continue
        m[A('wGrassRate')]=0  # no wild battle on the way (a cave's whole floor)
        g.press(face,20); g.press('a',10)
        for k in range(30):
            g.tick(4)
            if boxed() or m[A('wIsInBattle')]: return True
    return False
