"""Catch EXP: a benched mon (EXP. SHARE on) levels up from a catch; once its
stats box closes, the caught mon's pic must not come back."""
import sys
from story import *
from dxlib import screen
sys.path.insert(0, '/home/user/shinpokered/tests')
from test_bag import POCKET_OF
setup(items=[('MASTER_BALL', 5)], party=[('MEWTWO', 100, ['PSYCHIC_M']), ('PIDGEY', 5, ['TACKLE'])])
m[A('wOptions')] &= 0x7F  # battle animations on
m[A('wBagPocket')] = POCKET_OF.get(IT['MASTER_BALL'], 0); m[A('wBagCursor')] = 0; m[A('wBagScroll')] = 0
set_event('EVENT_EXP_SHARE_ON')
m[A('wCurOpponent')] = SP['RATTATA']; m[A('wCurEnemyLVL')] = 30
g.wait_text('FIGHT', n=2400)
g.press('down', 10); g.press('a', 40); g.press('a', 20)
if 'USE' in screen(g): g.press('a', 10)
stats = after = False; pic_back = False
for k in range(4000):
    g.tick(3)
    sc = screen(g)
    if 'ATTACK' in sc and 'SPEED' in sc: stats = True
    elif stats: after = True
    if 'New' in sc: break  # the #DEX page and the nickname screen come next
    if after:
        t = g.tiles()
        if any(t[r * 20 + c] != 0x7F for r in range(1, 7) for c in range(12, 19)): pic_back = True
    if not m[A('wIsInBattle')] and k > 50: break
    g.pb.button('a', 2)
print(('PASS' if stats and not pic_back else 'FAIL'), 'stats box seen', stats, 'pic came back', pic_back)
