import re, sys
from pyboy import PyBoy
from PIL import Image
sys.path.insert(0,'/home/user/shinpokered/tests')
from ivs import pack
R='/home/user/shinpokered'
OUT=R+'/screenshots/fork'
sym={}
for l in open('/tmp/pk30emu/rom.sym'):
    if l.startswith(';') or not l.strip(): continue
    a,n=l.split(); b,ad=a.split(':'); sym.setdefault(n,int(ad,16))
def consts(path, pat):
    d={}
    for l in open(R+'/'+path):
        m=re.match(pat,l)
        if m: d[m.group(1)]=int(m.group(2),16)
    return d
SP=consts('constants/pokemon_constants.asm', r'\s*const (\w+)\s*; \$([0-9A-F]+)')
MV=consts('constants/move_constants.asm', r'\s*const (\w+)\s*; ([0-9a-f]{2})\s*$')
IT=consts('constants/item_constants.asm', r'\s*const (\w+)\s*; \$([0-9A-F]+)')
TY={'NORMAL':0,'FIGHTING':1,'FLYING':2,'POISON':3,'GROUND':4,'ROCK':5,'BUG':7,'GHOST':8,'STEEL':9,'FIRE':0x14,'WATER':0x15,'GRASS':0x16,'ELECTRIC':0x17,'PSYCHIC':0x18,'ICE':0x19,'DRAGON':0x1A,'DARK':0x1B,'FAIRY':0x1C}
CH={c:0x80+i for i,c in enumerate('ABCDEFGHIJKLMNOPQRSTUVWXYZ')}
CH[' ']=0x7F
CH.update({c:0xA0+i for i,c in enumerate('abcdefghijklmnopqrstuvwxyz')})
def text(s,n=11): return ([CH[c] for c in s]+[0x50]*n)[:n]

import glob as _glob
GROWTH={}
for _f in _glob.glob(R+'/data/baseStats/*.asm'):
    _t=open(_f).read()
    _m=re.search(r'db (\d+) ; growth rate', _t); _n=re.search(r'db DEX_(\w+)', _t)
    if _m and _n: GROWTH[_n.group(1)]=int(_m.group(1))
def exp_for(species, n):
    r=GROWTH.get(species.replace('_',''), GROWTH.get(species, 0))
    if r==3: return max(0, 6*n**3//5 - 15*n*n + 100*n - 140)  # medium slow
    if r==4: return 4*n**3//5   # fast
    if r==5: return 5*n**3//4   # slow
    return n**3                 # medium fast (and the unused slightly fast/slow)

class G:
    def __init__(self, state='/tmp/pk30emu/st_g9'):
        self.pb=PyBoy('/tmp/pk30emu/rom.gbc',window='null',sound_emulated=False); self.pb.set_emulation_speed(0)
        if state: self.pb.load_state(open(state,'rb'))
        self.m=self.pb.memory
    def poke(self,n,*v,off=0):
        a=sym[n] if isinstance(n,str) else n
        for i,x in enumerate(v): self.m[a+off+i]=x
    def poke16(self,n,v,off=0): self.poke(n,v>>8,v&0xff,off=off)
    def peek(self,n,k=1): return [self.m[sym[n]+i] for i in range(k)]
    def tick(self,n): self.pb.tick(n)
    def press(self,b,w=30,hold=4): self.pb.button(b,hold); self.pb.tick(w)
    def shot(self,name):
        im=self.pb.screen.image.copy().convert('RGB')
        im.resize((320,288),Image.NEAREST).save(f'{OUT}/{name}.png')
        return im
    def tiles(self): return [self.m[sym['wTileMap']+i] for i in range(360)]
    def has(self,s):
        t=self.tiles(); seq=[CH[c] for c in s]
        return any(t[i:i+len(seq)]==seq for i in range(360-len(seq)))
    def wait_text(self,s,n=600,button='a',every=6):
        for i in range(n):
            if self.has(s): return True
            if button and i%every==every-1: self.pb.button(button,4)
            self.tick(5)
        return False
    def mon(self,i,species,level,moves,types,hp=None,item=0,ivs=(31,)*6,flags=0,evs=(0,)*6,name=None,nature=None):
        L=sym['wPartyMon2']-sym['wPartyMon1']; o=i*L
        hp=hp or level*3+20
        self.poke('wPartyMon1Species',SP[species],off=o)
        self.poke16('wPartyMon1HP',hp,off=o); self.poke('wPartyMon1BoxLevel',level,off=o); self.poke('wPartyMon1Status',0,off=o)
        self.poke('wPartyMon1Type1',TY[types[0]],TY[types[-1]],off=o)
        mv=[MV[x] for x in moves]+[0]*(4-len(moves)); self.poke('wPartyMon1Moves',*mv,off=o)
        self.poke('wPartyMon1PP',*[self.move_pp(x) if x else 0 for x in mv],off=o)
        e=exp_for(species,level); self.poke('wPartyMon1Exp',e>>16,(e>>8)&0xff,e&0xff,off=o)
        self.poke('wPartyMon1Level',level,off=o); self.poke('wPartyMon1CatchRate',item,off=o)
        self.poke('wPartyMon1OTID',*self.peek('wPlayerID',2),off=o)
        self.poke('wPartyMon1IVs',*pack(list(ivs),flags),off=o); self.poke('wPartyMon1EVs',*evs,off=o)
        for k,v in [('MaxHP',hp),('Attack',level*2+10),('Defense',level*2+10),('Speed',level*2+10),('SpecialAttack',level*2+10),('SpecialDefense',level*2+10)]:
            self.poke16('wPartyMon1'+k,v,off=o)
        nm=text(name or species.replace('_',' '))
        self.poke('wPartyMonNicks',*nm,off=11*i); self.poke('wPartyMonOT',*text('RED'),off=11*i)
    def move_pp(self, move):
        b=4; a=0x4000+6*(move-1)+5   # Moves (bank $0E): 6 bytes each, PP last
        return self.m[0x0E, a]
    def party(self,*mons):
        self.poke('wPartyCount',len(mons)); self.poke('wPartySpecies',*[SP[x[0]] for x in mons],0xff)
        for i,x in enumerate(mons): self.mon(i,*x[:4],**(x[4] if len(x)>4 else {}))
    def battle(self,species,level):
        self.poke('wCurOpponent',SP[species]); self.poke('wCurEnemyLVL',level)
        ok=self.wait_text('FIGHT',n=2400)
        self.tick(30); return ok
