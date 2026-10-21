"""Drives SameBoy (an accurate emulator, independent of PyBoy) through
sbdrive, a line protocol around its core (tools/emu/sbdrive.c)."""
import subprocess, re, os
R='/home/user/shinpokered'
SBDRIVE=os.environ.get('SBDRIVE','/tmp/claude-0/sbdrive/sbdrive')
BOOT=os.environ.get('SB_BOOT','/tmp/claude-0/sameboy/build/bin/tester')
SYM={}
for l in open(R+'/pokered.sym'):
    if l[0]==';' or not l.strip(): continue
    b,rest=l.split(':'); a,n=rest.split(); SYM.setdefault(n,int(a,16))
CHARMAP={}
for k,v in re.findall(r'charmap "((?:[^"\\]|\\.)+)", \$([0-9A-Fa-f]+)', open(R+'/charmap.asm').read()):
    t=int(v,16)
    if t not in CHARMAP or (all(ord(c)<128 or c=='é' for c in k) and not all(ord(c)<128 or c=='é' for c in CHARMAP[t])): CHARMAP[t]=k

class SB:
    def __init__(self, model='cgb', rom=R+'/pokered.gbc', sav=None):
        args=[SBDRIVE, model, BOOT, rom]+([sav] if sav else [])
        self.p=subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True, bufsize=1)
    def cmd(self, c):
        self.p.stdin.write(c+'\n'); self.p.stdin.flush(); return self.p.stdout.readline().strip()
    def tick(self, n=1): self.cmd(f'frames {n}')
    def press(self, k, wait=20, hold=4):
        self.cmd(f'key {k} 1'); self.tick(hold); self.cmd(f'key {k} 0'); self.tick(wait)
    def hold(self, k, on): self.cmd(f'key {k} {int(on)}')
    def peek(self, a, n=1):
        a=SYM[a] if isinstance(a,str) else a
        h=self.cmd(f'peek {a:x} {n}'); v=[int(h[i:i+2],16) for i in range(0,len(h),2)]
        return v[0] if n==1 else v
    def poke(self, a, *vals):
        a=SYM[a] if isinstance(a,str) else a
        self.cmd(f'poke {a:x} '+' '.join(f'{v:x}' for v in vals))
    def regs(self): pc,sp=self.cmd('regs').split()[:2]; return int(pc,16),int(sp,16)
    def shot(self, path): self.cmd(f'shot {path}')
    def battery(self, path): self.cmd(f'battery {path}')
    def tiles(self): return self.peek('wTileMap', 360)
    def screen(self):
        t=self.tiles(); return '\n'.join(''.join('#' if x in (0x79,0x7A,0x7B,0x7C,0x7D,0x7E) else CHARMAP.get(x,'.') for x in t[r*20:r*20+20]) for r in range(18))
    def boxed(self):
        t=self.tiles()
        if t[240]!=0x79 or t[340]!=0x7D: return ''
        s=self.screen().split('\n'); return (s[14].strip('#').strip()+' / '+s[16].strip('#').strip())
    def close(self):
        try: self.cmd('quit')
        except Exception: pass
        self.p.wait(timeout=10)
