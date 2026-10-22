"""Explosion: a mon that faints by its own move leaves before the other
side moves (a faster wild GEODUDE with only SELFDESTRUCT, then the player's
mon using it first). Prints the order of the moves run."""
from story import *
order=[]
for name in ('ExecutePlayerMove','ExplodeEffect','HandleEnemyMonFainted','ExecuteEnemyMove'):
    b,a=ENT[name]; g.pb.hook_register(b,a,lambda n: order.append(n),name)
for case in ('enemy_first','player_first'):
    setup(); del order[:]; texts=[]
    m[A('wCurOpponent')]=SP['GEODUDE']; m[A('wCurEnemyLVL')]=30
    g.wait_text('FIGHT',n=2400)
    if case=='enemy_first':
        m[A('wEnemyMonMoves')]=MV['SELFDESTRUCT']; m[A('wEnemyMonMoves')+1]=0; m[A('wEnemyMonMoves')+2]=0; m[A('wEnemyMonMoves')+3]=0
        m[A('wEnemyMonSpeed')]=0x03; m[A('wBattleMonSpeed')]=0
        m[A('wBattleMonHP')]=0x03; m[A('wBattleMonMaxHP')]=0x03  # survives? set high
        m[A('wBattleMonHP')+1]=0xE7; m[A('wBattleMonMaxHP')+1]=0xE7
    else:
        m[A('wBattleMonMoves')]=MV['SELFDESTRUCT']
        m[A('wBattleMonSpeed')]=0x03; m[A('wEnemyMonSpeed')]=0
        m[A('wEnemyMonHP')]=0x03; m[A('wEnemyMonHP')+1]=0xE7; m[A('wEnemyMonMaxHP')]=0x03; m[A('wEnemyMonMaxHP')+1]=0xE7
        m[A('wEnemyMonMoves')]=MV['TACKLE']; m[A('wEnemyMonMoves')+1]=0; m[A('wEnemyMonMoves')+2]=0; m[A('wEnemyMonMoves')+3]=0
    g.press('a',20); g.press('a',20)  # FIGHT, first move
    for k in range(600):
        g.tick(6)
        if 'ExplodeEffect' in order and (len(order)>6 or not m[A('wIsInBattle')]): break
        b=boxed()
        if b and (not texts or texts[-1]!=b): texts.append(b)
        g.pb.button('a' if k%4 else 'b',3)
    i=order.index('ExplodeEffect') if 'ExplodeEffect' in order else -1
    print(case, order[:8], hex(m[A('wEnemySelectedMove')]), hex(m[A('wPlayerSelectedMove')]), m[A('wIsInBattle')], flush=True); print(texts[:12])
