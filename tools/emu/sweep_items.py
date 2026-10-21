"""Item sweep: use every item from the bag, in the field and in a wild
battle, on a damaged, poisoned first mon; record the text, check the game
gets back to the bag/overworld/battle menu, and whether the item was used."""
import sys, io, json
from lib import *
from dxlib import box, screen, row
sys.path.insert(0,'/home/user/shinpokered/tests')
from test_bag import POCKET_OF
ENT={}
for l in open('/tmp/pk30emu/rom.sym'):
    if l[0]==';' or not l.strip(): continue
    b,rest=l.split(':'); a,n=rest.split(); ENT[n]=(int(b,16),int(a,16))
A=lambda n: ENT[n][1]
mode=sys.argv[1]  # field or battle
items=[(n,v) for n,v in IT.items() if 1<=v<=0x97 and not n.startswith('FLOOR')]
if len(sys.argv)>2: items=[(n,v) for n,v in items if n in sys.argv[2:]]
g=G(); m=g.m
g.party(('PIKACHU',20,['THUNDERSHOCK','GROWL'],['ELECTRIC'],dict(hp=20)),('CLEFAIRY',20,['POUND'],['FAIRY']))
g.poke('wPartyMon1Status',0x08)  # poisoned
g.poke16('wPartyMon1MaxHP',80)
st=io.BytesIO(); g.pb.save_state(st)
crash=[0]; g.pb.hook_register(0,0x38,lambda _:crash.__setitem__(0,crash[0]+1),None)
res={}
def boxed():
    tl=g.tiles()
    return box(g).strip() if tl[12*20]==0x79 and tl[17*20]==0x7D else ''
for name,iid in items:
    st.seek(0); g.pb.load_state(st); crash[0]=0
    m[A('wNumBagItems')]=1; m[A('wBagItems')]=iid; m[A('wBagItems')+1]=5; m[A('wBagItems')+2]=0xFF
    m[A('wBagPocket')]=POCKET_OF.get(iid,0); m[A('wBagCursor')]=0; m[A('wBagScroll')]=0
    lines=[]; result='timeout'
    if mode=='field':
        g.press('start',40); g.press('down',12); g.press('a',60)   # ITEM
    else:
        m[A('wCurOpponent')]=SP['RATTATA']; m[A('wCurEnemyLVL')]=5
        g.wait_text('FIGHT',n=2400); g.tick(20)
        g.press('down',10); g.press('a',60)
    opened='CANCEL' in screen(g)
    g.press('a',20)            # the item
    if mode=='field' and 'USE' in screen(g): g.press('a',10)
    for f in range(400):
        g.tick(6)
        b=boxed()
        if b and (not lines or lines[-1]!=b): lines.append(b)
        if crash[0]: result='crash'; break
        scr=screen(g)
        if f>4 and 'CANCEL' in scr and 'POCKET' not in scr and not b and m[A('wBagItems')]!=0xEE:
            result='back to bag'; break
        if mode=='battle' and f>4 and 'FIGHT' in scr and 'RUN' in scr: result='back to battle menu'; break
        if mode=='battle' and not m[A('wIsInBattle')] and f>4: result='battle ended'; break
        if mode=='field' and f>10 and not b and 'CANCEL' not in scr and 'ITEM' not in scr and 'POKé' not in scr: result='back to field'; break
        if 'YES' in scr and 'NO' in scr: g.pb.button('b',3)
        else: g.pb.button('a' if f%5 else 'b',3)
    qty=m[A('wBagItems')+1] if m[A('wBagItems')]==iid else 0
    # dedupe growing text
    out=[]
    for l in lines:
        c=l.replace(' ','').replace('/','')
        if out and c.startswith(out[-1][1]): out[-1]=(l,c)
        elif not out or out[-1][1]!=c: out.append((l,c))
    res[name]=dict(opened=opened,result=result,left=qty,text=[l for l,_ in out])
    bad=[l for l,_ in out if '{' in l]
    print(f"{name:13} {result:20} left={qty} {'BADTEXT '+str(bad) if bad else ''} | {' || '.join(l for l,_ in out)[:150]}", flush=True)
    if result in ('timeout','crash') or bad:
        g.pb.screen.image.save(f'/tmp/pk30emu/out/item_{mode}_{name}.png')
json.dump(res, open(f'/tmp/pk30emu/out/items_{mode}.json','w'), indent=1)
