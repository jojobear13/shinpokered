"""PC IN MENU: CHANGE BOX from the start menu's PC (Rocket Hideout B1F), then
talk to the grunts: the map's texts must be its own (a stale saved text
pointer gave them the Pokemon Center nurse's)."""
from story import *
from dxlib import screen
evs=[e for e in EV if 'ROCKET_HIDEOUT' in e and 'BEAT' in e]+['EVENT_PC_IN_MENU']
setup(events=evs)
enter('ROCKET_HIDEOUT_1',pos=(21,16))
for k in range(10): g.tick(10)
tp=lambda: hex(m[A('wMapTextPtr')]|m[A('wMapTextPtr')+1]<<8)
print('map text ptr', tp())
g.press('start',30)
for k in range(10):
    if '▶PC' in screen(g): break
    g.press('down',10)
g.press('a',60)
log=[]
def step(want, key='a', n=200):
    for k in range(n):
        g.tick(4); s=screen(g)
        if want in s: return True
        g.pb.button('a' if k%3==0 else key,2) if key!='a' else g.pb.button('a',2)
    return False
# press through to the PC menu, choose BILL's/SOMEONE's PC, CHANGE BOX
for k in range(60):
    g.tick(6); s=screen(g)
    if 'WITHDRAW' in s or 'CHANGE' in s: break
    if "'s PC" in s or 'SOMEONE' in s: g.press('a',20)
    else: g.pb.button('a',2)
print(screen(g))
for k in range(3): g.press('down',10)
g.press('a',40)   # CHANGE BOX
print(screen(g))
for k in range(80):
    g.tick(6); s=screen(g)
    if 'BOX' in s and ('BOX 2' in s or '▶BOX' in s) and 'YES' not in s: break
    g.pb.button('a',2)
print(screen(g))
g.press('down',10); g.press('a',30)   # box 2
for k in range(400):
    g.tick(4); s=screen(g)
    if 'YES' in s: g.press('a',10)
    elif 'SEE YA' in s and 'BOX No. 2' in s: break
    else: g.pb.button('a',2)
print('box now', m[A('wCurrentBoxNum')]&0x7f, 'text ptr', tp())
for k in range(30): g.pb.button('b',3); g.tick(6)
print('after closing', tp())
for t in (1,2,3):
    snap=io.BytesIO(); g.pb.save_state(snap)
    r=run(talk=t); print(t, r['lines'][:3])
    snap.seek(0); g.pb.load_state(snap)
ok = tp() == hex(ENT['RocketHideout1TextPointers'][1])
print('PASS' if ok else 'FAIL', 'map text pointer back to its own')
