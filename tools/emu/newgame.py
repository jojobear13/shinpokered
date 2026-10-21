from pyboy import PyBoy
sym={}
for l in open('rom.sym'):
    if l.startswith(';') or not l.strip(): continue
    a,n=l.split(); b,ad=a.split(':'); sym.setdefault(n,int(ad,16))
pb=PyBoy('rom.gbc',window='null',sound_emulated=False); pb.set_emulation_speed(0)
m=pb.memory
NEWNAME=[0x8D,0x84,0x96,0x7F,0x8D,0x80,0x8C,0x84]
def tiles(): return [m[sym['wTileMap']+i] for i in range(360)]
def has(seq):
    t=tiles(); return any(t[i:i+len(seq)]==seq for i in range(360-len(seq)))
pb.tick(300)
for i in range(600):
    if has(NEWNAME):
        pb.button('down',4); pb.tick(20); pb.button('a',4); pb.tick(60); continue
    pb.button('a',4); pb.tick(40)
    if m[sym["wCurMap"]]==0x26 and i>250:
        break
pb.tick(600)
for _ in range(10): pb.button('b',4); pb.tick(40)
print('map', hex(m[sym['wCurMap']]), 'after', i)
pb.screen.image.save('newgame.png')
pb.save_state(open('st_g9','wb'))
