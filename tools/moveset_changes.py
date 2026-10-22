"""Writes docs/moveset_changes.md: every Pokémon's moves now against Red and
Blue's, with each change marked as Shin Pokémon's or this fork's.

Three sources: the original games (pret/pokered, a clone given as the first
argument), Shin Pokémon as this fork started from it (commit b1e9b4d), and
the working tree. Level-up moves, starting moves, TM/HM compatibility, the
TM list, new moves and changed move data.

    git clone --depth 1 https://github.com/pret/pokered /tmp/pokered
    python3 tools/moveset_changes.py /tmp/pokered
"""
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHIN = 'b1e9b4d'
OUT = os.path.join(REPO, 'docs', 'moveset_changes.md')


class Source:
    """Reads files from a directory, or from a commit of this repo."""
    def __init__(self, root=None, commit=None):
        self.root, self.commit = root, commit

    def read(self, path):
        if self.commit:
            return subprocess.run(['git', '-C', REPO, 'show', f'{self.commit}:{path}'],
                                  capture_output=True, text=True, check=True).stdout
        return open(os.path.join(self.root, path)).read()

    def ls(self, path):
        if self.commit:
            out = subprocess.run(['git', '-C', REPO, 'ls-tree', '--name-only', f'{self.commit}:{path}'],
                                 capture_output=True, text=True, check=True).stdout
            return out.split()
        return sorted(os.listdir(os.path.join(self.root, path)))


def strip(line):
    return line.split(';')[0].strip()


def species_order(src):
    """Internal species number -> constant name (1-190), from the constants."""
    out = {}
    for line in src.read('constants/pokemon_constants.asm').split('\n'):
        m = re.match(r'\s*const (\w+)\s*; \$([0-9A-Fa-f]{2})', line)
        if m and m.group(1) != 'NO_MON':
            out[int(m.group(2), 16)] = m.group(1)
    return out


def learnsets(src, path):
    """Pointer-table label order -> [(level, move)] per entry."""
    text = src.read(path)
    labels = re.findall(r'^\s*dw (\w+EvosMoves)', text, re.M)
    blocks = {}
    for m in re.finditer(r'^(\w+EvosMoves):(.*?)(?=^\w+EvosMoves:|\Z)', text, re.M | re.S):
        lines = [strip(l) for l in m.group(2).split('\n')]
        lines = [l for l in lines if l.startswith('db')]
        # evolutions up to the first "db 0", then the learnset up to the next
        k = lines.index('db 0')
        moves = []
        for l in lines[k + 1:]:
            if l == 'db 0':
                break
            level, move = [x.strip() for x in l[2:].split(',')]
            moves.append((int(level), move))
        blocks[m.group(1)] = moves
    return [blocks[l] for l in labels]


def tm_list_vanilla(src):
    tms, hms = [], []  # (pret lists the HMs first)
    for line in src.read('constants/item_constants.asm').split('\n'):
        m = re.match(r'\s*add_(tm|hm) (\w+)', line)
        if m:
            (tms if m.group(1) == 'tm' else hms).append(m.group(2))
    return tms + hms


def tm_list_here(src):
    tms = [strip(l)[2:].strip() for l in src.read('data/tms.asm').split('\n') if strip(l).startswith('db ')]
    return tms + ['CUT', 'FLY', 'SURF', 'STRENGTH', 'FLASH']


def base_stats(src, here):
    """species constant -> (starting moves, set of TM/HM moves)"""
    out = {}
    folder = 'data/baseStats' if here else 'data/pokemon/base_stats'
    tms = tm_list_here(src) if here else tm_list_vanilla(src)
    for name in src.ls(folder):
        text = src.read(f'{folder}/{name}')
        dex = re.search(r'db DEX_(\w+)', text)
        if not dex:
            continue  # (not a species: MissingNo.)
        dex = dex.group(1)
        if here:
            # the four db lines before the growth rate
            lines = [strip(l) for l in text.split('\n')]
            g = next(i for i, l in enumerate(text.split('\n')) if 'growth rate' in l)
            start = [l[2:].strip() for l in lines[:g] if l.startswith('db')][-4:]
            start = [s for s in start if s not in ('0', 'NO_MOVE')]
            nums = set()
            for line in text.split('\n'):
                c = strip(line)
                if c.startswith('tmlearn'):
                    nums |= {int(x) for x in c[7:].split(',') if x.strip() and int(x) != 0}
            learn = {tms[n - 1] for n in nums}
        else:
            m = re.search(r'db (\w+), (\w+), (\w+), (\w+) ; level 1 learnset', text)
            start = [s for s in m.groups() if s != 'NO_MOVE']
            t = re.search(r'tmhm(.*?); end', text, re.S).group(1)
            learn = {w for w in re.findall(r'\b[A-Z][A-Z0-9_]+\b', t)} & set(tms)  # (Mew's UNUSED)
        out[dex] = (start, learn)
    return out


def moves_data(src, here):
    path = 'data/moves.asm' if here else 'data/moves/moves.asm'
    out = {}
    for line in src.read(path).split('\n'):
        m = re.match(r'\s*move (\w+),\s*(\w+),\s*(\d+),\s*(\w+),\s*(\d+),\s*(\d+)', line)
        if m:
            name, effect, power, typ, acc, pp = m.groups()
            out[name] = dict(effect=effect, power=int(power), type=typ, acc=int(acc), pp=int(pp))
    return out


NAMES = {}


def load_names():
    """move constant -> its in-game name, title-cased"""
    consts = []
    for line in open(os.path.join(REPO, 'constants/move_constants.asm')):
        m = re.match(r'\s*const (\w+)', line)
        if m and m.group(1) != 'NO_MOVE':
            consts.append(m.group(1))
    names = re.findall(r'db "([^"@]*)@"', open(os.path.join(REPO, 'text/move_names.asm')).read())
    for c, n in zip(consts, names):
        NAMES[c] = n


def pretty(move):
    if move in NAMES and move not in ('PSYCHIC_M',):
        name = NAMES[move].title().replace("'S", "'s")
        fixes = {'Doubleslap': 'DoubleSlap', 'Thunderpunch': 'ThunderPunch', 'Solarbeam': 'SolarBeam',
                 'Thundershock': 'ThunderShock', 'Sonicboom': 'SonicBoom', 'Dragonbreath': 'DragonBreath',
                 'Poisonpowder': 'PoisonPowder', 'Smokescreen': 'SmokeScreen', 'Vicegrip': 'ViceGrip',
                 'Hi Jump Kick': 'Hi Jump Kick', 'Ancientpower': 'AncientPower', 'Dynamicpunch': 'DynamicPunch',
                 'Extremespeed': 'ExtremeSpeed', 'Bubblebeam': 'BubbleBeam', 'X-Scissor': 'X-Scissor'}
        return fixes.get(name, name)
    special = {'PSYCHIC_M': 'Psychic', 'DOUBLESLAP': 'DoubleSlap', 'THUNDERPUNCH': 'ThunderPunch',
               'SOLARBEAM': 'SolarBeam', 'THUNDERSHOCK': 'ThunderShock', 'SONICBOOM': 'SonicBoom',
               'DRAGONBREATH': 'DragonBreath', 'SELFDESTRUCT': 'Selfdestruct', 'SMOKESCREEN': 'SmokeScreen',
               'SOFTBOILED': 'Softboiled', 'HI_JUMP_KICK': 'Hi Jump Kick', 'POISONPOWDER': 'PoisonPowder',
               'DOUBLE_EDGE': 'Double-Edge', 'U_TURN': 'U-turn', 'X_SCISSOR': 'X-Scissor',
               'WILL_O_WISP': 'Will-O-Wisp', 'LOCK_ON': 'Lock-On', 'BABY_DOLL_EYES': 'Baby-Doll Eyes',
               'LEECH_LIFE': 'Leech Life', 'VICEGRIP': 'ViceGrip', 'FAINT_ATTACK': 'Faint Attack'}
    return special.get(move, move.replace('_', ' ').title())


def mon_name(const):
    special = {'NIDORAN_M': 'Nidoran♂', 'NIDORAN_F': 'Nidoran♀', 'MR_MIME': 'Mr. Mime',
               'FARFETCHD': "Farfetch'd"}
    return special.get(const, const.title())


def levelup_changes(old, new):
    """[(kind, text)] going from learnset old to new (lists of (level, move))"""
    o = {}
    for lv, mv in old:
        o.setdefault(mv, lv)
    n = {}
    for lv, mv in new:
        n.setdefault(mv, lv)
    out = []
    for mv, lv in n.items():
        if mv not in o:
            out.append((mv, f'+{pretty(mv)} {lv}'))
        elif o[mv] != lv:
            out.append((mv, f'{pretty(mv)} {o[mv]}→{lv}'))
    for mv, lv in o.items():
        if mv not in n:
            out.append((mv, f'−{pretty(mv)} (was {lv})'))
    return out


def main(pret):
    load_names()
    van, shin, here = Source(pret), Source(commit=SHIN), Source(REPO)
    order = species_order(here)
    order_van = species_order(van)
    ls = {k: learnsets(s, p) for k, s, p in (('van', van, 'data/pokemon/evos_moves.asm'),
                                              ('shin', shin, 'data/evos_moves.asm'),
                                              ('here', here, 'data/evos_moves.asm'))}
    bs = {'van': base_stats(van, False), 'shin': base_stats(shin, True), 'here': base_stats(here, True)}
    mv = {'van': moves_data(van, False), 'shin': moves_data(shin, True), 'here': moves_data(here, True)}
    dexnum = {}
    for line in here.read('constants/pokedex_constants.asm').split('\n'):
        m = re.match(r'\s*const DEX_(\w+)\s*; (\d+)', line)
        if m:
            dexnum[m.group(1)] = int(m.group(2))
    species = sorted((dexnum[name], sp, name) for sp, name in order.items() if name in dexnum)
    vsp = {name: sp for sp, name in order_van.items()}

    L = []
    w = L.append
    w('# Moveset changes')
    w('')
    w("What every Pokémon learns in PK30 against the original Red and Blue: level-up")
    w('moves, starting moves and TM/HM compatibility, then the TM list, the new')
    w("moves and the old moves whose data changed. Each change is marked **S** if")
    w('Shin Pokémon (the base of this fork) already made it, or **P** if PK30 made')
    w('it. Generated by `tools/moveset_changes.py` from the source.')
    w('')
    w('In each list: `+Move 12` is new, at level 12; `Move 20→12` moved from')
    w('level 20; `−Move (was 20)` is no longer learned. Starting moves are those a')
    w('Pokémon has at level 1.')
    w('')

    def tag(change_key, old_list, shin_list, kind):
        """S if Shin's data already has this change"""
        return 'S' if change_key in shin_list else 'P'

    w('## Level-up and starting moves')
    w('')
    totals = {'S': 0, 'P': 0}
    for dex, sp, name in species:
        v = ls['van'][vsp[name] - 1]
        s = ls['shin'][sp - 1]
        h = ls['here'][sp - 1]
        ch = levelup_changes(v, h)
        sh = {t for _, t in levelup_changes(v, s)}
        vstart, vtm = bs['van'][name]
        sstart, stm = bs['shin'][name]
        hstart, htm = bs['here'][name]
        startch = []
        for m_ in hstart:
            if m_ not in vstart:
                startch.append(('S' if m_ in sstart else 'P', f'+{pretty(m_)}'))
        for m_ in vstart:
            if m_ not in hstart:
                startch.append(('S' if m_ not in sstart else 'P', f'−{pretty(m_)}'))
        if not ch and not startch:
            continue
        w(f'**#{dex:03d} {mon_name(name)}**')
        if startch:
            w(f'- Start: ' + ', '.join(f'{t} ({k})' for k, t in startch))
        if ch:
            parts = []
            for _, t in ch:
                k = 'S' if t in sh else 'P'
                totals[k] += 1
                parts.append(f'{t} ({k})')
            w('- Level-up: ' + ', '.join(parts))
        w('')

    w('## TM and HM compatibility')
    w('')
    w('Moves a Pokémon can now learn from a machine (+) or no longer can (−).')
    w('')
    for dex, sp, name in species:
        _, vtm = bs['van'][name]
        _, stm = bs['shin'][name]
        _, htm = bs['here'][name]
        add = sorted(htm - vtm, key=pretty)
        rem = sorted(vtm - htm, key=pretty)
        if not add and not rem:
            continue
        parts = [f'+{pretty(m_)} ({"S" if m_ in stm else "P"})' for m_ in add]
        parts += [f'−{pretty(m_)} ({"S" if m_ not in stm else "P"})' for m_ in rem]
        w(f'- **#{dex:03d} {mon_name(name)}**: ' + ', '.join(parts))
    w('')

    w('## The TM list')
    w('')
    vt, st, ht = tm_list_vanilla(van), tm_list_here(shin), tm_list_here(here)
    rows = [(i, a, b) for i, (a, b) in enumerate(zip(vt, ht)) if a != b]
    if rows:
        w('| Machine | Red/Blue | Now |')
        w('|---|---|---|')
        for i, a, b in rows:
            label = f'TM{i + 1:02d}' if i < 50 else f'HM{i - 49:02d}'
            w(f'| {label} | {pretty(a)} | {pretty(b)} ({"S" if st[i] == b else "P"}) |')
    else:
        w('Unchanged from Red and Blue: the machines teach the same moves.')
    w('')

    w('## New moves')
    w('')
    learners = {}
    for dex, sp, name in species:
        for lv, m_ in ls['here'][sp - 1]:
            learners.setdefault(m_, []).append(f'{mon_name(name)} {lv}')
        for m_ in bs['here'][name][0]:
            learners.setdefault(m_, []).append(f'{mon_name(name)} start')
    new = [m_ for m_ in mv['here'] if m_ not in mv['van']]
    w('| Move | Type | Power | Acc. | PP | Learned by | |')
    w('|---|---|---|---|---|---|---|')
    for m_ in new:
        d = mv['here'][m_]
        power = '—' if d['power'] == 0 else ('fixed' if d['power'] == 1 else d['power'])
        who = ', '.join(learners.get(m_, [])) or 'none (by level)'
        w(f"| {pretty(m_)} | {d['type'].title()} | {power} | {d['acc']} | {d['pp']} | {who} | "
          f"{'S' if m_ in mv['shin'] else 'P'} |")
    w('')

    w('## Old moves with new data')
    w('')
    w("Type, power, accuracy and PP against Red and Blue's (effects are in the")
    w('design brief, Gen 9 rules pass, part 6).')
    w('')
    w('| Move | Type | Power | Acc. | PP | |')
    w('|---|---|---|---|---|---|')
    for m_, d in mv['here'].items():
        o = mv['van'].get(m_)
        if not o:
            continue
        cols = []
        changed = False
        for key in ('type', 'power', 'acc', 'pp'):
            a, b = o[key], d[key]
            if key == 'type':
                a, b = a.title(), b.title()
            if a != b:
                changed = True
                cols.append(f'{a}→{b}')
            else:
                cols.append('')
        if changed:
            s = mv['shin'].get(m_)
            k = 'S' if s and all(s[x] == d[x] for x in ('type', 'power', 'acc', 'pp')) else 'P'
            w(f'| {pretty(m_)} | ' + ' | '.join(cols) + f' | {k} |')
    w('')
    open(OUT, 'w').write('\n'.join(L))
    print('wrote', OUT, totals)


if __name__ == '__main__':
    main(sys.argv[1])
