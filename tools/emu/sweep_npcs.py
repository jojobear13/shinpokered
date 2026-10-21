"""NPC sweep: in every map, open each sprite's and sign's text through
DisplayTextID (injected at the overworld loop), press through it, and check
the game returns to the overworld loop. Records every text box shown."""
exec(open('sweep_maps.py').read().split("for mid,name,h,w in maps:")[0])
from dxlib import box, screen
H_TEXTID=0xFF8C
inject=[None]; state={'loops':0}
def on_loop(_):
    state['loops']+=1
    t=inject[0]
    if t is None: return
    inject[0]=None
    m[H_TEXTID]=t
    rf=g.pb.register_file
    sp=rf.SP-2; ret=ENT['OverworldLoop'][1]
    m[sp]=ret&0xff; m[sp+1]=ret>>8; rf.SP=sp
    rf.PC=ENT['DisplayTextID'][1]
g.pb.hook_deregister(0,ENT['OverworldLoop'][1])
g.pb.hook_register(0,ENT['OverworldLoop'][1],on_loop,None)
out={}; tag=sys.argv[1] if len(sys.argv)>1 else 'all'
dump=open(f'/tmp/pk30emu/out/dialogue_{tag}.txt','w')
for mid,name,h,w in maps:
    if name.startswith('UNUSED') or (only and mid not in only): continue
    st.seek(0); g.pb.load_state(st)
    wp=first_warp(mid); x,y=wp if wp else (w,h)
    target[0]=(mid,name,h,w,x,y)
    m[ENT['wDestinationMap'][1]]=0; m[ENT['wd732'][1]] |= 1<<3
    for k in range(40): g.tick(10)
    for k in range(6): g.press('b',20)
    if m[ENT['wCurMap'][1]]!=mid: continue
    ms=io.BytesIO(); g.pb.save_state(ms)
    nspr=m[ENT['wNumSprites'][1]]; nsign=m[ENT['wNumSigns'][1]]
    ids=[('sprite',i) for i in range(1,nspr+1)]+[('sign',m[ENT['wSignTextIDs'][1]+k]) for k in range(nsign)]
    for kind,tid in ids:
        ms.seek(0); g.pb.load_state(ms)
        crash[0]=0; state['loops']=0
        inject[0]=tid
        g.tick(2)
        lines=[]; result='timeout'
        for f in range(240):
            g.tick(8)
            tl=g.tiles()
            b=box(g).strip() if tl[12*20]==0x79 and tl[17*20]==0x7D else ''
            c=b.replace(' ','').replace('/','').replace('.','')
            if c:
                if lines and c.startswith(lines[-1][1]): lines[-1]=(b,c)
                elif not lines or lines[-1][1]!=c: lines.append((b,c))
            if m[ENT['wIsInBattle'][1]]: result='battle'; break
            if crash[0]: result='crash'; break
            if f>6 and state['loops']>3 and inject[0] is None: result='ok'; break
            if f%3==0: g.pb.button('a' if (f//3)%4 else 'b',4)
        lines=[l for l,_ in lines]
        out[f'{name}:{kind}{tid}']=dict(result=result, lines=lines)
        dump.write(f'== {name} {kind} {tid}: {result}\n'+''.join('   '+l+'\n' for l in lines))
        if result not in ('ok','battle'):
            g.pb.screen.image.save(f'/tmp/pk30emu/out/npc_{mid:02X}_{kind}{tid}.png')
            print(f"{mid:02X} {name} {kind}{tid} {result} last={lines[-1] if lines else ''}", flush=True)
    print(f"{mid:02X} {name}: {len(ids)} done", flush=True)
json.dump(out, open(f'/tmp/pk30emu/out/npcs_{tag}.json','w'), indent=1)
