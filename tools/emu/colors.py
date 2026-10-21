"""COLOR FIX and MORE COLOR, each on and off: the same places shot in every
combination (out/colors.png), and COLOR FIX kept through a save."""
from story import *
from PIL import Image
OUT=ROOT+'/out'
shots=[]
for more in (0,1):
    for fix in (0,1):
        row=[]
        for place in ('PALLET_TOWN','VIRIDIAN_FOREST','ROUTE_1','battle','menu'):
            setup(badges=0xFF)
            m[A('wUnusedD721')]=(m[A('wUnusedD721')]&0x7F)|(0x80 if more else 0)
            m[0xFFFE]=2 if fix else 1
            enter(place if place in MAPS else 'VIRIDIAN_CITY', pos=None if place in MAPS else (23,26)); run()
            if place=='battle': g.battle('PIKACHU',5)
            if place=='menu': g.press('start',40)
            row.append(g.pb.screen.image.copy().convert('RGB'))
        shots.append(row)
W=Image.new('RGB',(160*5,144*4),'white')
for r,row in enumerate(shots):
    for c,im in enumerate(row): W.paste(im,(c*160,r*144))
W.save(OUT+'/colors.png')
# COLOR FIX is saved (EVENT_9FE) and comes back on CONTINUE
setup(badges=0xFF); m[0xFFFE]=2
enter('VIRIDIAN_CITY', pos=(23,26)); run()
g.press('start',40)
for k in range(8):
    if '▶SAVE' in screen(g): break
    g.press('down',12)
g.press('a',60)
for k in range(60):
    if 'saved the game' in boxed(): break
    g.press('a',20)
g.pb.register_file.A=0x11; g.pb.register_file.PC=0x0100; g.pb.register_file.SP=0xDFFF  # as the CGB boot ROM leaves it
for k in range(60):
    g.tick(30)
    if 'CONTINUE' in screen(g): break
    g.pb.button('start',3)
g.press('a',60); g.press('a',120)
for k in range(10): g.tick(30)
print('COLOR FIX kept', 'PASS' if m[0xFFFE]==2 else 'FAIL', m[0xFFFE])
