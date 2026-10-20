"""The MOVES screen and TMs that are owned, not carried (design brief, cleanup
after the Gen 9 pass).

Getting a TM or HM sets its flag in wTMsOwned instead of putting it in the
bag. The MOVES screen lists what can go in a slot: REMOVE (unless it's the
mon's only move), its starting moves, its learnset up to its level, and the
owned TMs and HMs it can learn; the field move slot takes field moves only.
"""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game
from test_held_items import ITEMS, _hram
from test_learnsets import learnsets

FIELD_SLOT = 4
REMOVE = (0, 0)


def _consts(path):
    with open(os.path.join(REPO_ROOT, "constants", path)) as f:
        return {m.group(1): int(m.group(2), 16)
                for m in re.finditer(r"^\s*const (\w+)\s*; \$?([0-9A-Fa-f]+)", f.read(), re.M)}


MOVES = _consts("move_constants.asm")
SPECIES = _consts("pokemon_constants.asm")
with open(os.path.join(REPO_ROOT, "data", "tms.asm")) as f:
    MACHINES = [MOVES[m] for m in re.findall(r"^\tdb (\w+)", f.read(), re.M)]
FIELD_MOVES = {MOVES[m] for m in ("CUT", "FLY", "SURF", "STRENGTH", "FLASH", "DIG", "TELEPORT", "SOFTBOILED")}
LEARNSETS = {name.upper(): [(level, MOVES[move]) for level, move in entries] for name, entries in learnsets()}


def machine_item(index):
    return ITEMS["TM_01"] + index if index < 50 else ITEMS["HM_01"] + index - 50


def base_stats(name):
    with open(os.path.join(REPO_ROOT, "data", "baseStats", name.lower() + ".asm")) as f:
        text = f.read()
    starting = re.search(r"; attacks known at lvl 0\n((?:db \w+\n){4})", text).group(1)
    starting = [0 if m == "0" else MOVES[m] for m in re.findall(r"db (\w+)", starting)]
    compatible = {int(n) for line in re.findall(r"tmlearn ([\d,]+)", text) for n in line.split(",")}
    return starting, compatible


def model(name, level, moves, temp, owned, slot):
    """The choices for a slot, as (move, where from) pairs."""
    starting, compatible = base_stats(name)
    known = [m for m in moves if m]
    out = []
    current = temp if slot == FIELD_SLOT else moves[slot]
    if current and (slot == FIELD_SLOT or len(known) > 1):
        out.append(REMOVE)

    def add(move, source):
        if not move or move in known or any(c[0] == move for c in out):
            return
        if slot == FIELD_SLOT and (move == temp or move not in FIELD_MOVES):
            return
        out.append((move, source))

    for move in starting:
        add(move, 1)
    for lv, move in LEARNSETS[name]:
        if lv <= level:
            add(move, lv)
    for i, move in enumerate(MACHINES):
        if i in owned and i + 1 in compatible:
            add(move, machine_item(i))
    return out


class MovesScreenTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def setUp(self):
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()

    def set_mon(self, name, level, moves, temp=0, pp=None):
        g = self.game
        g.poke("wPartyCount", 1)
        g.poke("wPartySpecies", SPECIES[name], 0xFF)
        g.poke("wPartyMon1Species", SPECIES[name])
        g.poke("wPartyMon1Level", level)
        g.poke("wPartyMon1CatchRate", 0)  # no held item
        g.poke("wPartyMon1Moves", *moves)
        g.poke("wPartyMon1PP", *(pp or [10, 11, 12, 13]))
        g.poke("wTempFieldMoveSlots", temp)
        g.poke("wWhichPokemon", 0)

    def own(self, indexes):
        flags = [0] * 7
        for i in indexes:
            flags[i // 8] |= 1 << (i % 8)
        self.game.poke("wTMsOwned", *flags)

    def choices(self):
        g = self.game
        n = g.peek("wMovesChoices")
        raw = g.peek(g.addr("wMovesChoices") + 1, 2 * n) if n else []
        if n == 1:
            raw = list(raw)
        return [(raw[2 * i], raw[2 * i + 1]) for i in range(n)]

    def build(self, slot):
        self.game.poke("wMovesSlot", slot)
        self.game.call("MovesBuildChoices", max_frames=200)
        return self.choices()

    def test_machine_index(self):
        g = self.game
        for i in range(55):
            out = g.call("MachineIndex", a=machine_item(i))
            self.assertEqual(out["a"], i)

    def test_getting_a_tm_marks_it_owned(self):
        g = self.game
        self.own([])
        g.poke("wNumBagItems", 1, ITEMS["POTION"], 3, 0xFF)
        for i in (0, 27, 49, 50, 54):
            with self.subTest(machine=i):
                out = g.call("GiveItem", bc=(machine_item(i) << 8) | 1, max_frames=200)
                self.assertTrue(out["carry"])
                self.assertNotEqual(g.call("CheckMachineOwned", a=machine_item(i))["a"], 0)
        self.assertEqual(g.peek("wNumBagItems", 4), [1, ITEMS["POTION"], 3, 0xFF])
        self.assertEqual(g.call("CheckMachineOwned", a=machine_item(1))["a"], 0)

    def test_choices_match_the_model(self):
        cases = [
            ("CHARMANDER", 30, ["SCRATCH", "GROWL", 0, 0], 0, range(55)),
            ("CHARMANDER", 5, ["SCRATCH", 0, 0, 0], 0, range(55)),
            ("PIKACHU", 40, ["THUNDERSHOCK", "GROWL", "QUICK_ATTACK", "THUNDER_WAVE"], "FLASH", [0, 23, 44, 50, 54]),
            ("MEW", 60, ["POUND", "TRANSFORM", "PSYCHIC_M", 0], 0, range(0, 55, 3)),
            ("MAGIKARP", 30, ["SPLASH", "TACKLE", 0, 0], 0, range(55)),
            ("VAPOREON", 50, ["WATER_GUN", "TACKLE", "SURF", "BITE"], "STRENGTH", []),
        ]
        for name, level, moves, temp, owned in cases:
            moves = [MOVES[m] if m else 0 for m in moves]
            temp = MOVES[temp] if temp else 0
            for slot in range(5):
                with self.subTest(name=name, level=level, slot=slot):
                    self.set_mon(name, level, moves, temp)
                    self.own(owned)
                    self.assertEqual(self.build(slot), model(name, level, moves, temp, set(owned), slot))

    def test_learnsets_fit_the_buffer(self):
        with open(os.path.join(REPO_ROOT, "constants", "misc_constants.asm")) as f:
            length = int(re.search(r"MOVES_LEARNSET_LENGTH EQU (\d+)", f.read()).group(1))
        with open(os.path.join(REPO_ROOT, "data", "evos_moves.asm")) as f:
            text = f.read()
        for name, body in re.findall(r"^(\w+)EvosMoves:\n(.*?)\n(?=\w+EvosMoves:|\Z)", text, re.M | re.S):
            size = sum(len(l.split(";")[0][3:].split(",")) for l in body.splitlines() if l.startswith("\tdb "))
            self.assertLessEqual(size, length, name)

    def apply(self, slot, choices, cursor):
        g = self.game
        flat = [b for c in choices for b in c]
        g.poke("wMovesChoices", len(choices), *flat)
        g.poke("wMovesSlot", slot)
        g.poke("wMovesCursor", cursor)
        g.call("MovesApply", max_frames=100)

    def test_learning_replaces_with_full_pp(self):
        m = MOVES
        self.set_mon("CHARMANDER", 30, [m["SCRATCH"], m["GROWL"], m["EMBER"], 0], pp=[0xC5, 40, 25, 0])
        self.apply(0, [REMOVE, (m["FLAMETHROWER"], 34)], 1)
        g = self.game
        self.assertEqual(g.peek("wPartyMon1Moves", 4), [m["FLAMETHROWER"], m["GROWL"], m["EMBER"], 0])
        self.assertEqual(g.peek("wPartyMon1PP"), 15)  # Gen 9's, and the old move's PP Ups are gone

    def test_learning_into_an_empty_slot_fills_the_first(self):
        m = MOVES
        self.set_mon("CHARMANDER", 30, [m["SCRATCH"], m["GROWL"], 0, 0], pp=[35, 40, 0, 0])
        self.apply(3, [(m["EMBER"], 9)], 0)
        g = self.game
        self.assertEqual(g.peek("wPartyMon1Moves", 4), [m["SCRATCH"], m["GROWL"], m["EMBER"], 0])
        self.assertEqual(g.peek("wPartyMon1PP", 4), [35, 40, 25, 0])

    def test_remove_moves_the_rest_up(self):
        m = MOVES
        for slot in range(4):
            with self.subTest(slot=slot):
                moves = [m["SCRATCH"], m["GROWL"], m["EMBER"], m["LEER"]]
                self.set_mon("CHARMANDER", 30, moves, pp=[1, 2, 3, 4])
                self.apply(slot, [REMOVE], 0)
                g = self.game
                self.assertEqual(g.peek("wPartyMon1Moves", 4), moves[:slot] + moves[slot + 1:] + [0])
                self.assertEqual(g.peek("wPartyMon1PP", 4), [1, 2, 3, 4][:slot] + [1, 2, 3, 4][slot + 1:] + [0])

    def test_field_slot(self):
        m = MOVES
        self.set_mon("CHARMANDER", 30, [m["SCRATCH"], 0, 0, 0])
        self.apply(FIELD_SLOT, [(m["CUT"], ITEMS["HM_01"])], 0)
        self.assertEqual(self.game.peek("wTempFieldMoveSlots"), m["CUT"])
        self.assertEqual(self.game.peek("wPartyMon1Moves"), m["SCRATCH"])
        self.apply(FIELD_SLOT, [REMOVE], 0)
        self.assertEqual(self.game.peek("wTempFieldMoveSlots"), 0)

    def test_new_game_owns_no_machines(self):
        g = self.game
        self.own(range(55))
        g.poke(_hram("hJoyHeld"), 0)
        g.call("InitPlayerData", max_frames=2000)
        self.assertEqual(g.peek("wTMsOwned", 7), [0] * 7)

    def test_new_game_plus_keeps_them(self):
        g = self.game
        self.own([0, 9, 50, 54])
        owned = g.peek("wTMsOwned", 7)
        g.poke("wNumBagItems", 1, ITEMS["POTION"], 3, 0xFF)
        g.call("DoNewGamePlus", max_frames=2000)
        g.poke(_hram("hJoyHeld"), 0x04)  # SELECT, as NEW GAME+ needs
        g.call("InitPlayerData", max_frames=2000)
        self.assertEqual(g.peek("wTMsOwned", 7), owned)
        self.assertEqual(g.peek("wNumBagItems"), 0)  # the bag is still emptied


if __name__ == "__main__":
    unittest.main()
