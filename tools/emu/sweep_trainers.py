"""Trainer sweep: battle every trainer party. Each enemy mon acts for two
turns against a topped-up Mewtwo, then is knocked out; enemy moves must be
real moves, no text may show an unknown tile, and the battle must end."""
import sys, io, json, re
sys.argv=[sys.argv[0]]+sys.argv[1:]
from lib import *
from dxlib import box, screen, row
sys.path.insert(0,'/home/user/shinpokered/tests')
import test_data_integrity as tdi
ENT={}
for l in open('/tmp/pk30emu/rom.sym'):
    if l[0]==';' or not l.strip(): continue
    b,rest=l.split(':'); a,n=rest.split(); ENT[n]=(int(b,16),int(a,16))
A=lambda n: ENT[n][1]
NUM_ATTACKS=tdi.NUM_ATTACKS
parties=tdi.PARTIES
sel=sys.argv[1] if len(sys.argv)>1 else None
if sel and ':' in sel:
    want={tuple(map(int,x.split(':'))) for x in sel.split(',')}
    parties=[p for p in parties if (p[0],p[1]) in want]
elif sel:
    a,b_=sel.split('-'); parties=parties[int(a):int(b_)]
g=G(); m=g.m
g.party(('MEWTWO',100,['SPLASH','TACKLE','PSYCHIC_M'],['PSYCHIC']))
m[A('wOptions')]=(m[A('wOptions')]&0x30)|0x01|0x80|0x40
st=io.BytesIO(); g.pb.save_state(st)
moves_seen=[]; crash=[0]
def on_enemy(_):
    moves_seen.append(m[A('wEnemySelectedMove')])
g.pb.hook_register(*ENT['ExecuteEnemyMove'],on_enemy,None)
g.pb.hook_register(0,0x38,lambda _:crash.__setitem__(0,crash[0]+1),None)
GHOST=0x08; DARK=0x1B
results={}
for cls,no,mons in parties:
    st.seek(0); g.pb.load_state(st)
    moves_seen.clear(); crash[0]=0
    m[A('wCurOpponent')]=cls+200; m[A('wTrainerNo')]=no
    started=False; menus={}; bad_text=set(); result='timeout'
    for f in range(3000):
        g.tick(6)
        inb=m[A('wIsInBattle')]
        if inb: started=True
        if crash[0]: result='crash'; break
        if started and not inb:
            result='ended'; break
        for r in range(12,18):
            t=row(g,r)
            if '{' in t: bad_text.add(t)
        scr=screen(g)
        if inb and 'FIGHT' in scr and 'RUN' in scr:
            pos=m[A('wEnemyMonPartyPos')]
            menus[pos]=menus.get(pos,0)+1
            m[A('wBattleMonHP')]=999>>8; m[A('wBattleMonHP')+1]=999&0xff
            m[A('wBattleMonStatus')]=0
            m[A('wPlayerDisabledMove')]=0; m[A('wPlayerDisabledMoveNumber')]=0
            t1,t2=m[A('wEnemyMonType1')],m[A('wEnemyMonType1')+1]
            if menus[pos]<=2: mv='SPLASH'
            elif GHOST in (t1,t2): mv='PSYCHIC_M'
            else: mv='TACKLE'
            m[A('wBattleMonMoves')]=MV[mv]; m[A('wBattleMonPP')]=30
            if menus[pos]>2: m[A('wEnemyMonHP')]=0; m[A('wEnemyMonHP')+1]=1
            m[A('wPlayerMoveListIndex')]=0
            g.press('a',8); g.press('a',8)
        elif 'YES' in scr and 'NO' in scr: g.press('b',8)
        else:
            g.pb.button('a',3)
    bad_moves=[x for x in moves_seen if not (1<=x<=NUM_ATTACKS)]
    results[f'{cls}:{no}']=dict(result=result, enemy_moves=len(moves_seen), bad_moves=bad_moves,
                                bad_text=sorted(bad_text), mons=len(mons), acted=len(menus))
    flag = result!='ended' or bad_moves or bad_text
    if flag:
        g.pb.screen.image.save(f'/tmp/pk30emu/out/tr_{cls}_{no}.png')
    print(f"{cls}:{no} {result} moves={len(moves_seen)} acted={len(menus)}/{len(mons)} bad_moves={bad_moves} bad_text={sorted(bad_text)[:2]}", flush=True)
json.dump(results, open(f'/tmp/pk30emu/out/trainers_{sel[:20].replace(':','_').replace(',','+')}.json','w'), indent=1)
