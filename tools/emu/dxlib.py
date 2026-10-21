from lib import *
INV={v:k for k,v in CH.items()}
INV.update({0xE0:"'",0xE8:'.',0xE6:'?',0xE7:'!',0xF4:',',0xEE:'v',0xBA:'e',0xF6:'0',0xF7:'1',0xF8:'2',0xF9:'3',0xFA:'4',0xFB:'5',0xFC:'6',0xFD:'7',0xFE:'8',0xFF:'9',0x7F:' ',0xE3:'-',0x54:'POKé',0xED:'>',0xEC:'>'})
for i in range(10): INV[0xF6+i]=str(i)
import re as _re
_CM={}
for _k,_v in _re.findall(r'charmap "((?:[^"\\]|\\.)+)", \$([0-9A-Fa-f]+)', open('/home/user/shinpokered/charmap.asm').read()):
    _t=int(_v,16)
    if _t not in _CM or (all(ord(c)<128 or c=='é' for c in _k) and not all(ord(c)<128 or c=='é' for c in _CM[_t])): _CM[_t]=_k
_FRAME={0x79,0x7A,0x7B,0x7C,0x7D,0x7E}
def row(g,r): return ''.join('#' if t in _FRAME else _CM.get(t, '{%02X}'%t) for t in g.tiles()[r*20:(r+1)*20])
def row_old(g,r): return ''.join(INV.get(t,'#' if t in (0x79,0x7A,0x7B,0x7C,0x7D,0x7E) else '.') for t in g.tiles()[r*20:(r+1)*20])
def box(g): return row(g,14).strip('#')+' / '+row(g,16).strip('#')
def screen(g): return '\n'.join(row(g,r) for r in range(18))
def read_all(g, n=40, w=40):
    out=[]
    for i in range(n):
        g.tick(w)
        b=box(g)
        if not out or out[-1]!=b: out.append(b)
        g.press('a',10)
    return out
