from story import *
GYMS=[('PEWTER_GYM','EVENT_BEAT_BROCK',34,0),('CERULEAN_GYM','EVENT_BEAT_MISTY',11,1),('VERMILION_GYM','EVENT_BEAT_LT_SURGE',24,2),
      ('CELADON_GYM','EVENT_BEAT_ERIKA',21,3),('FUCHSIA_GYM','EVENT_BEAT_KOGA',6,4),('SAFFRON_GYM','EVENT_BEAT_SABRINA',46,5),
      ('CINNABAR_GYM','EVENT_BEAT_BLAINE',38,6),('VIRIDIAN_GYM','EVENT_BEAT_VIRIDIAN_GYM_GIOVANNI',27,7)]
out={}
for mapname,ev,tm,bit in GYMS:
    setup(badges=(1<<bit)-1, events=[e for e in EV if e.startswith('EVENT_BEAT_'+mapname+'_TRAINER')])
    ok=approach(mapname, 1)
    r=run()
    text=' '.join(r['lines'])
    res=dict(talked=ok, result=r['result'], battles=r['battles'], beat=event(ev), badge=bool(m[A('wObtainedBadges')]>>bit&1),
             tm=tm_owned(tm), tm_text=('received' in text and f'TM{tm:02d}' in text), crash=crash[0])
    out[mapname]=dict(res, lines=r['lines'])
    print(mapname, res, flush=True)
json.dump(out, open('/tmp/pk30emu/out/story_gyms.json','w'), indent=1)
