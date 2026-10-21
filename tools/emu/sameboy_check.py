"""The same game in SameBoy on Game Boy Color, the original Game Boy and the
Super Game Boy: a save made in PyBoy is continued in SameBoy, which plays a
wild battle, gives a held item, walks and saves; that save is continued back
in PyBoy. Screenshots of each model go to out/sb_<model>_*.png.
  python3 sameboy_check.py [cgb dmg sgb]"""
import sys
from story import *
from sb import SB
sys.path.insert(0, REPO+'/tests')
from test_bag import POCKET_OF
from PIL import Image

OUT=ROOT+'/out'
def sram_get():
    return bytes(m[b,a] for b in range(4) for a in range(0xA000,0xC000))
def sram_put(data):
    for b in range(4):
        for a in range(0x2000): m[b,0xA000+a]=data[b*0x2000+a]

def to_main_menu():
    g.pb.register_file.PC=0x0100; g.pb.register_file.SP=0xDFFF
    for k in range(60):
        g.tick(30)
        if 'CONTINUE' in screen(g): return True
        g.pb.button('start',3)
    return False

def pyboy_save():
    g.press('start',40)
    for k in range(8):
        if '▶SAVE' in screen(g): break
        g.press('down',12)
    g.press('a',60)
    for k in range(60):
        if 'saved the game' in boxed(): break
        g.press('a',20)
    for k in range(4): g.press('b',20)

def party_of(peek):
    n=peek('wPartyCount')
    return n, [peek(A('wPartySpecies')+i) for i in range(n)], peek(A('wPartyMon1CatchRate'))

def png(sb, name):
    p=f'{OUT}/sb_{name}.ppm'; sb.shot(p)
    Image.open(p).resize(Image.open(p).size if 'sgb' in name else (320,288), Image.NEAREST).save(p[:-4]+'.png'); os.remove(p)

# --- a save made in PyBoy
setup(badges=0xFF, events=['EVENT_BEAT_CHAMPION_RIVAL'], items=[('LEFTOVERS',1),('POTION',3)],
      party=[('MEWTWO',100,['SURF','PSYCHIC_M']),('PIKACHU',30,['THUNDERSHOCK'])])
enter('VIRIDIAN_CITY', pos=(23,26)); run()
pyboy_save()
start_sav=sram_get()
want=party_of(lambda a: m[A(a) if isinstance(a,str) else a])
spot=(m[A('wCurMap')],m[A('wXCoord')],m[A('wYCoord')])
open(f'{OUT}/sb_start.sav','wb').write(start_sav)
results={}

def check(model):
    r={}; sb=SB(model, rom=ROOT+'/rom.gbc', sav=f'{OUT}/sb_start.sav')
    pk=lambda a: sb.peek(A(a) if isinstance(a,str) else a)
    # title -> main menu -> CONTINUE
    for k in range(80):
        sb.tick(30)
        if 'CONTINUE' in sb.screen(): break
        if k==6: png(sb, model+'_title')
        sb.press('start',10)
    r['menu']='CONTINUE' in sb.screen()
    sb.press('a',60); sb.press('a',120)
    for k in range(20): sb.tick(30)
    r['continued']=(pk('wCurMap'),pk('wXCoord'),pk('wYCoord'))==spot and party_of(pk)==want
    png(sb, model+'_field')
    # a wild battle, fought through
    sb.poke(A('wCurOpponent'),SP['RATTATA']); sb.poke(A('wCurEnemyLVL'),5)
    seen=False; shot=False
    for k in range(400):
        sb.tick(6); inb=pk('wIsInBattle'); scr=sb.screen()
        if inb: seen=True
        if seen and not inb and not sb.boxed(): break
        if 'FIGHT' in scr and 'RUN' in scr:
            if not shot: png(sb, model+'_battle'); shot=True
            sb.press('a',10)
        else: sb.press('a',6)
    r['battle']=seen and not pk('wIsInBattle')
    pc,sp=sb.regs(); r['pc_ok']=pc<0x8000 and sp>0xC000
    # give the Leftovers from the bag
    for k in range(20): sb.press('b',8)
    bag=A('wBagItems'); sb.poke(A('wBagPocket'),POCKET_OF.get(IT['LEFTOVERS'],0)); sb.poke(A('wBagCursor'),0); sb.poke(A('wBagScroll'),0)
    sb.press('start',40)
    for k in range(8):
        if '▶ITEM' in sb.screen(): break
        sb.press('down',12)
    sb.press('a',60)
    for k in range(10):
        s=sb.screen()
        if 'LEFTOVERS' in s and '▶LEFTOVERS' not in s: sb.press('up',10)
        else: break
    sb.press('a',30)
    if 'USE' in sb.screen(): sb.press('a',30)
    lines=[]
    for k in range(60):
        b=sb.boxed()
        if b and (not lines or lines[-1]!=b): lines.append(b)
        s=sb.screen()
        if k>5 and not b and 'CANCEL' not in s and 'POKé' not in s and 'ITEM' not in s: break
        sb.press('a' if k<12 else 'b',15)
    r['held']=pk('wPartyMon1CatchRate')==IT['LEFTOVERS']
    r['held_text']=any('holding' in l for l in lines)
    for k in range(4): sb.press('b',15)
    x0,y0=pk('wXCoord'),pk('wYCoord')
    for d in ('down','left','up','right'):
        sb.hold(d,1); sb.tick(40); sb.hold(d,0); sb.tick(20)
        if (pk('wXCoord'),pk('wYCoord'))!=(x0,y0): break
    r['walks']=(pk('wXCoord'),pk('wYCoord'))!=(x0,y0) and pk('wUpdateSpritesEnabled')==1
    png(sb, model+'_after')
    # save there, then continue in PyBoy
    sb.press('start',40)
    for k in range(8):
        if '▶SAVE' in sb.screen(): break
        sb.press('down',12)
    sb.press('a',60)
    for k in range(60):
        if 'saved the game' in sb.boxed(): break
        sb.press('a',20)
    sb.tick(60)
    there=(pk('wCurMap'),pk('wXCoord'),pk('wYCoord'))
    sb.battery(f'{OUT}/sb_{model}.sav'); sb.close()
    sav=open(f'{OUT}/sb_{model}.sav','rb').read()
    base.seek(0); g.pb.load_state(base); sram_put(sav[:0x8000]); to_main_menu()
    g.press('a',60); g.press('a',120)
    for k in range(10): g.tick(30)
    r['back_in_pyboy']=(m[A('wCurMap')],m[A('wXCoord')],m[A('wYCoord')])==there and m[A('wPartyMon1CatchRate')]==IT['LEFTOVERS']
    r['lines']=lines[-2:]
    return r

for model in (sys.argv[1:] or ['cgb','dmg','sgb']):
    r=check(model); results[model]=r
    ok=all(v for k,v in r.items() if k!='lines')
    print(model, 'PASS' if ok else 'FAIL', {k:v for k,v in r.items() if k!='lines'}, r['lines'])
json.dump(results, open(f'{OUT}/sameboy.json','w'), indent=1)
