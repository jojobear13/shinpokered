"""IVs and EVs, for tests (design brief, Gen 9 rules pass, part 3).

A mon's IVs are four bytes, one 32-bit number, high byte first: six 5-bit IVs
(HP, attack, defense, speed, special attack, special defense, from the top),
then the Nuzlocke mark (bit 1) and the ability slot (bit 0). Its EVs are six
bytes, one per stat in the same order.
"""

STAT_EVS = ("HPEV", "AttackEV", "DefenseEV", "SpeedEV", "SpecialAttackEV", "SpecialDefenseEV")
TRAINER_IVS = (17, 19, 17, 17, 17, 17)  # attack 19, the rest 17
SHINY_IV_BITS = 0b10
MAX_EV = 252
MAX_TOTAL_EVS = 510


def pack(ivs, flags=0):
    """Six IVs (0-31) and the flags -> the four IV bytes."""
    value = 0
    for iv in ivs:
        assert 0 <= iv < 32
        value = value << 5 | iv
    value = value << 2 | flags
    return list(value.to_bytes(4, "big"))


def unpack(data):
    """The four IV bytes -> (six IVs, flags)."""
    value = int.from_bytes(bytes(data), "big")
    return [(value >> (27 - 5 * i)) & 31 for i in range(6)], value & 3


def nature(data):
    """0-24 in Gen 3's order (5 * raised + lowered, from attack): the IVs as one
    number without the flags, offset so the trainer IVs are HARDY."""
    def value(d):
        return int.from_bytes(bytes(d), "big") & ~3
    return (value(data) - value(pack(TRAINER_IVS))) % 25


def gender_byte(data):
    return data[0] ^ data[2]


def is_shiny(data):
    ivs, _ = unpack(data)
    return all(iv & 3 == SHINY_IV_BITS for iv in ivs)


def model_stats(base, level, iv_bytes, evs):
    """Gen 3+'s stat formula, with the nature, capped at 999."""
    ivs, _ = unpack(iv_bytes)
    raised, lowered = divmod(nature(iv_bytes), 5)
    out = []
    for i in range(6):
        value = (2 * base[i] + ivs[i] + evs[i] // 4) * level // 100
        value += level + 10 if i == 0 else 5
        if i and raised != lowered:
            if i - 1 == raised:
                value = value * 110 // 100
            elif i - 1 == lowered:
                value = value * 90 // 100
        out.append(min(value, 999))
    return out
