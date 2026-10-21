"""Map sweep: enter every map through a steered fly warp, check it loads,
runs the overworld loop, and lets the player move; screenshot each."""
from lib import *
import re, os, sys, json, glob
R='/home/user/shinpokered'
ENT={}
for l in open('/tmp/pk30emu/rom.sym'):
    if l[0]==';' or not l.strip(): continue
    b,rest=l.split(':'); a,n=rest.split(); ENT[n]=(int(b,16),int(a,16))
maps=[]
for l in open(R+'/constants/map_constants.asm'):
    m=re.match(r'\s*mapconst (\w+),\s*(\d+),\s*(\d+)\s*; \$([0-9A-F]+)',l)
    if m: maps.append((int(m.group(4),16),m.group(1),int(m.group(2)),int(m.group(3))))
# header label per map, then its object label, then the first warp
hdr=re.findall(r'dw (\w+)', open(R+'/data/map_header_pointers.asm').read())
objfile={}
for f in glob.glob(R+'/data/mapObjects/*.asm'):
    for lab in re.findall(r'^(\w+Object):', open(f).read(), re.M): objfile[lab]=f
hdrobj={}
for f in glob.glob(R+'/data/mapHeaders/*.asm'):
    t=open(f).read()
    for h in re.findall(r'^(\w+_h):', t, re.M):
        o=re.findall(r'dw (\w+Object)', t)
        if o: hdrobj[h]=o[-1]
def first_warp(i):
    try:
        t=open(objfile[hdrobj[hdr[i]]]).read()
        m=re.search(r'^\s*warp (\d+), (\d+)', t, re.M)
        return (int(m.group(1)), int(m.group(2))) if m else None
    except (KeyError, IndexError): return None
BUF=0xDD40
only=[]
for x in sys.argv[1:]:
    if '-' in x: a,b_=x.split('-'); only+=list(range(int(a,16),int(b_,16)+1))
    else: only.append(int(x,16))
results={}
g=G(); m=g.m
g.party(('MEWTWO',70,['CONFUSION','SURF','FLY','STRENGTH'],['PSYCHIC']))
base=g.pb.save_state  # noqa
import io
st=io.BytesIO(); g.pb.save_state(st)
target=[None]
def on_copy(_):
    t=target[0]
    if t is None: return
    mid,name,h,w,x,y=t
    ptr=ENT['wOverworldMap'][1]+7+w+(w+6)*(y>>1)+(x>>1)
    for i,v in enumerate([ptr&0xff,ptr>>8,y,x,y&1,x&1]): m[BUF+i]=v
    m[ENT['wCurMap'][1]]=mid
    g.pb.register_file.HL=BUF
    target[0]=None
b,a=ENT['LoadSpecialWarpData.copyWarpData2']
g.pb.hook_register(b,a,on_copy,None)
loops=[0]
g.pb.hook_register(0,ENT['OverworldLoop'][1],lambda _:loops.__setitem__(0,loops[0]+1),None)
crash=[0]
g.pb.hook_register(0,0x38,lambda _:crash.__setitem__(0,crash[0]+1),None)
for mid,name,h,w in maps:
    if name.startswith('UNUSED') or (only and mid not in only): continue
    st.seek(0); g.pb.load_state(st)
    wp=first_warp(mid)
    x,y=wp if wp else (w, h)  # a door, else the middle (steps are 2 per block)
    target[0]=(mid,name,h,w,x,y)
    m[ENT['wDestinationMap'][1]]=0  # PALLET_TOWN's fly data, then swapped
    m[ENT['wd732'][1]] |= 1<<3
    loops[0]=0; crash[0]=0
    for k in range(40): g.tick(10)
    for k in range(4): g.press('b',20)
    cur=m[ENT['wCurMap'][1]]
    l0=loops[0]
    p0=(m[ENT['wXCoord'][1]],m[ENT['wYCoord'][1]])
    moved=False
    for d in ('down','up','left','right'):
        g.pb.button(d,12); g.tick(30)
        if (m[ENT['wXCoord'][1]],m[ENT['wYCoord'][1]])!=p0 or m[ENT['wCurMap'][1]]!=cur: moved=True; break
    g.shot_path=f'/tmp/pk30emu/out/{mid:02X}_{name}.png'
    g.pb.screen.image.save(g.shot_path)
    results[name]=dict(id=mid, loaded=cur==mid, cur=cur, loops=loops[0], crash=crash[0], moved=moved, spawn=(x,y), warp=bool(wp))
    print(f"{mid:02X} {name:28} loaded={cur==mid} loops={l0} crash={crash[0]} moved={moved}", flush=True)
json.dump(results, open('/tmp/pk30emu/out/maps.json','w'), indent=1)
