"""Reads the maps out of a built ROM (with its .sym file): headers, blocks,
collision, warps, signs, sprites, connections and hidden objects. What the
game itself uses, so each build (the Japanese Red and Green keep the
original layouts) gets its own world."""
import re, os

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
STAY, WALK = 0xFF, 0xFE
ITEM, TRAINER = 0x80, 0x40
OVERWORLD, GYM = 0, 7


def consts(path, pat=r'const (\w+)'):
    out, n = {}, 0
    for line in open(os.path.join(REPO, path)):
        code = line.split(';')[0]
        m = re.match(r'\s*const_value\s*=\s*(\S+)', code) or re.match(r'\s*const_def(?:\s+(\S+))?', code)
        if m:
            n = int(m.group(1).replace('$', '0x'), 0) if m.group(1) else 0
            continue
        m = re.match(r'\s*' + pat, code)
        if m:
            out[m.group(1)] = n
            n += 1
    return out


class Rom:
    def __init__(self, name='pokered'):
        self.name = name
        self.data = open(os.path.join(REPO, name + '.gbc'), 'rb').read()
        self.sym = {}
        for l in open(os.path.join(REPO, name + '.sym')):
            if l[0] == ';' or not l.strip():
                continue
            b, rest = l.split(':')
            a, n = rest.split()
            self.sym.setdefault(n, (int(b, 16), int(a, 16)))
        self.map_names = {}
        for m in re.finditer(r'mapconst (\w+),\s*(\d+),\s*(\d+)\s*; \$([0-9A-F]+)',
                             open(os.path.join(REPO, 'constants/map_constants.asm')).read()):
            self.map_names[int(m.group(4), 16)] = m.group(1)
        self.map_ids = {v: k for k, v in self.map_names.items()}
        self.items = consts('constants/item_constants.asm')
        self.item_names = {v: k for k, v in self.items.items()}
        self.sprites = consts('constants/sprite_constants.asm')
        self.sprite_names = {v: k for k, v in self.sprites.items()}

    def b(self, bank, addr, n=1):
        off = addr if addr < 0x4000 else bank * 0x4000 + (addr - 0x4000)
        return self.data[off:off + n] if n > 1 else self.data[off]

    def w(self, bank, addr):
        return self.b(bank, addr) | self.b(bank, addr + 1) << 8

    def at(self, name):
        return self.sym[name]

    # ---- tilesets
    def tileset(self, tid):
        bank, base = self.at('Tilesets')
        a = base + tid * 12
        gbank = self.b(bank, a)
        blocks, gfx, coll = self.w(bank, a + 1), self.w(bank, a + 3), self.w(bank, a + 5)
        grass = self.b(bank, a + 10)
        passable = set()
        cbank = self.at('Underground_Coll')[0]  # all collision lists share a bank
        i = coll
        while self.b(cbank, i) != 0xFF:
            passable.add(self.b(cbank, i))
            i += 1
        return dict(bank=gbank, blocks=blocks, passable=passable, grass=grass)

    def blockset(self, ts, nblocks=256):
        return [list(self.b(ts['bank'], ts['blocks'] + k * 16, 16)) for k in range(nblocks)
                if ts['blocks'] + k * 16 + 16 <= 0x8000]

    # ---- maps
    def map(self, mid):
        pb, pa = self.at('MapHeaderPointers')
        bb, ba = self.at('MapHeaderBanks')
        bank = self.b(bb, ba + mid)
        h = self.w(pb, pa + mid * 2)
        if h < 0x4000:
            return None
        tileset, height, width = self.b(bank, h), self.b(bank, h + 1), self.b(bank, h + 2)
        blocks = self.w(bank, h + 3)
        cbyte = self.b(bank, h + 9)
        p = h + 10
        conns = {}
        for bit, d in ((3, 'north'), (2, 'south'), (1, 'west'), (0, 'east')):
            if cbyte & (1 << bit):
                conns[d] = dict(map=self.b(bank, p), yalign=sign8(self.b(bank, p + 7)),
                                xalign=sign8(self.b(bank, p + 8)))
                p += 11
        obj = self.w(bank, p)
        o = obj + 1
        warps = []
        for k in range(self.b(bank, o)):
            y, x, wid, dmap = self.b(bank, o + 1 + 4 * k, 4)
            warps.append(dict(x=x, y=y, dest_warp=wid, dest_map=dmap))
        o += 1 + 4 * len(warps)
        signs = []
        for k in range(self.b(bank, o)):
            y, x, t = self.b(bank, o + 1 + 3 * k, 3)
            signs.append(dict(x=x, y=y, text=t))
        o += 1 + 3 * len(signs)
        sprites = []
        n = self.b(bank, o)
        o += 1
        for k in range(n):
            spr, y, x, mov, rng, t = self.b(bank, o, 6)
            s = dict(index=k + 1, sprite=self.sprite_names.get(spr, spr), x=x - 4, y=y - 4,
                     movement=mov, range=rng, text=t & 0x3F)
            o += 6
            if t & TRAINER:
                s['trainer'] = (self.b(bank, o), self.b(bank, o + 1))
                o += 2
            elif t & ITEM:
                s['item'] = self.item_names.get(self.b(bank, o), self.b(bank, o))
                o += 1
            sprites.append(s)
        return dict(id=mid, name=self.map_names.get(mid, '?%02X' % mid), bank=bank, tileset=tileset,
                    height=height, width=width, blocks=list(self.b(bank, blocks, height * width)),
                    connections=conns, warps=warps, signs=signs, sprites=sprites)

    def shown(self):
        """(map id, sprite index) -> shown at the start of the game, for
        the people and items that scripts hide and show (missable objects)."""
        if hasattr(self, '_shown'):
            return self._shown
        pb, pa = self.at('MapHSPointers')
        out = self._shown = {}
        for mid in range(0xF8):
            p = self.w(pb, pa + 2 * mid)
            while 0x4000 <= p < 0x8000 and self.b(pb, p) != 0xFF:
                m, idx, state = self.b(pb, p, 3)
                out.setdefault((m, idx), state == 0x15)
                p += 3
        return out

    def hidden_objects(self):
        """map id -> [(x, y, arg, routine)]"""
        mb, ma = self.at('HiddenObjectMaps')
        pb, pa = self.at('HiddenObjectPointers')
        out = {}
        k = 0
        while self.b(mb, ma + k) != 0xFF:
            mid = self.b(mb, ma + k)
            p = self.w(pb, pa + 2 * k)
            lst = []
            while self.b(pb, p) != 0xFF:
                y, x, arg, rb = self.b(pb, p, 4)
                ra = self.w(pb, p + 4)
                lst.append(dict(x=x, y=y, arg=arg, routine=self.routine_name(rb, ra)))
                p += 6
            out.setdefault(mid, []).extend(lst)
            k += 1
        return out

    def routine_name(self, bank, addr):
        if not hasattr(self, '_rev'):
            self._rev = {}
            for n, (b, a) in self.sym.items():
                self._rev.setdefault((b, a), n)
        return self._rev.get((bank, addr), '%02x:%04x' % (bank, addr))


def sign8(v):
    return v - 256 if v >= 128 else v
