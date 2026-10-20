"""Spec tests for the Steel, Dark and Fairy types (design brief, Gen 9 rules
pass, part 1).

The type chart is Gen 6+'s, the species have Gen 9's types (Clefairy's and
Jigglypuff's lines and Mr. Mime are part Fairy, Magnemite's line part
Steel), and the moves Gen 2 retyped have their new types (Bite is Dark, Gust
Flying, Karate Chop Fighting, Sand-Attack Ground). Steel types can't be
poisoned, and Magnet Pull keeps them from fleeing or switching.
"""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game
from suites import move_execution as mx
from suites.apply_attack import H_WHOSETURN
from test_abilities import ABILITIES
from test_ability_damage import mx_effects

TYPES = {"NORMAL": 0x00, "FIGHTING": 0x01, "FLYING": 0x02, "POISON": 0x03, "GROUND": 0x04,
         "ROCK": 0x05, "TYPELESS": 0x06, "BUG": 0x07, "GHOST": 0x08, "STEEL": 0x09,
         "FIRE": 0x14, "WATER": 0x15, "GRASS": 0x16, "ELECTRIC": 0x17, "PSYCHIC": 0x18,
         "ICE": 0x19, "DRAGON": 0x1A, "DARK": 0x1B, "FAIRY": 0x1C}
REAL = [t for t in TYPES if t != "TYPELESS"]

# Gen 6+: attacking type -> (super effective against, not very effective against, no effect on)
CHART = {
    "NORMAL": ("", "ROCK STEEL", "GHOST"),
    "FIRE": ("GRASS ICE BUG STEEL", "FIRE WATER ROCK DRAGON", ""),
    "WATER": ("FIRE GROUND ROCK", "WATER GRASS DRAGON", ""),
    "ELECTRIC": ("WATER FLYING", "ELECTRIC GRASS DRAGON", "GROUND"),
    "GRASS": ("WATER GROUND ROCK", "FIRE GRASS POISON FLYING BUG DRAGON STEEL", ""),
    "ICE": ("GRASS GROUND FLYING DRAGON", "FIRE WATER ICE STEEL", ""),
    "FIGHTING": ("NORMAL ICE ROCK DARK STEEL", "POISON FLYING PSYCHIC BUG FAIRY", "GHOST"),
    "POISON": ("GRASS FAIRY", "POISON GROUND ROCK GHOST", "STEEL"),
    "GROUND": ("FIRE ELECTRIC POISON ROCK STEEL", "GRASS BUG", "FLYING"),
    "FLYING": ("GRASS FIGHTING BUG", "ELECTRIC ROCK STEEL", ""),
    "PSYCHIC": ("FIGHTING POISON", "PSYCHIC STEEL", "DARK"),
    "BUG": ("GRASS PSYCHIC DARK", "FIRE FIGHTING POISON FLYING GHOST STEEL FAIRY", ""),
    "ROCK": ("FIRE ICE FLYING BUG", "FIGHTING GROUND STEEL", ""),
    "GHOST": ("PSYCHIC GHOST", "DARK", "NORMAL"),
    "DRAGON": ("DRAGON", "STEEL", "FAIRY"),
    "DARK": ("PSYCHIC GHOST", "FIGHTING DARK FAIRY", ""),
    "STEEL": ("ICE ROCK FAIRY", "FIRE WATER ELECTRIC STEEL", ""),
    "FAIRY": ("FIGHTING DRAGON DARK", "FIRE POISON STEEL", ""),
}


def expected(attack, defend):
    strong, weak, none = (set(group.split()) for group in CHART[attack])
    return 20 if defend in strong else 5 if defend in weak else 0 if defend in none else 10


class TypeChartTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()
        cls.game.reset()

    def damage(self, move_type, defender_types):
        g = self.game
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerAbility", ABILITIES["NO_ABILITY"], ABILITIES["NO_ABILITY"])
        attacker = "NORMAL" if move_type == "TYPELESS" else "TYPELESS"
        g.poke("wBattleMonType", TYPES[attacker], TYPES[attacker])  # no STAB
        g.poke("wEnemyMonType", *(TYPES[t] for t in defender_types))
        g.poke("wPlayerMoveType", TYPES[move_type])
        g.poke("wUnusedC000", 0)
        g.poke("wDamage", 0, 100)
        g.poke("wMoveMissed", 0)
        g.call("AdjustDamageForMoveType")
        return g.peek("wDamage") << 8 | g.peek("wDamage+1")

    def test_every_pair(self):
        for attack in REAL:
            for defend in REAL:
                with self.subTest(attack=attack, defend=defend):
                    self.assertEqual(self.damage(attack, (defend, defend)), expected(attack, defend) * 10)

    def test_two_types(self):
        self.assertEqual(self.damage("GROUND", ("ELECTRIC", "STEEL")), 400)  # Magneton
        self.assertEqual(self.damage("FIGHTING", ("ELECTRIC", "STEEL")), 200)
        self.assertEqual(self.damage("POISON", ("PSYCHIC", "FAIRY")), 200)  # Mr. Mime
        self.assertEqual(self.damage("DARK", ("PSYCHIC", "FAIRY")), 100)
        self.assertEqual(self.damage("STEEL", ("NORMAL", "FAIRY")), 200)  # Jigglypuff
        self.assertEqual(self.damage("GHOST", ("NORMAL", "FAIRY")), 0)

    def test_typeless_is_neutral(self):
        for defend in REAL:
            self.assertEqual(self.damage("TYPELESS", (defend, defend)), 100)


def _read(path):
    with open(os.path.join(REPO_ROOT, path)) as f:
        return f.read()


class DataTest(unittest.TestCase):
    def test_species_types(self):
        cases = {"clefairy": ("FAIRY", "FAIRY"), "clefable": ("FAIRY", "FAIRY"),
                 "jigglypuff": ("NORMAL", "FAIRY"), "wigglytuff": ("NORMAL", "FAIRY"),
                 "mrmime": ("PSYCHIC", "FAIRY"), "magnemite": ("ELECTRIC", "STEEL"),
                 "magneton": ("ELECTRIC", "STEEL"), "gengar": ("GHOST", "POISON")}
        for name, pair in cases.items():
            text = _read(f"data/baseStats/{name}.asm")
            got = re.findall(r"^db (\w+) ; species type [12]$", text, re.M)
            self.assertEqual(tuple(got), pair, name)

    def test_move_types(self):
        text = _read("data/moves.asm")
        for move, kind in (("BITE", "DARK"), ("GUST", "FLYING"), ("KARATE_CHOP", "FIGHTING"),
                           ("SAND_ATTACK", "GROUND")):
            self.assertRegex(text, rf"move {move},\s+\w+,\s+\d+, {kind}\s*,")

    def test_names(self):
        g = shared_game()
        bank, table = g.bank("TypeNames"), g.addr("TypeNames")
        charmap = {0x80 + i: chr(ord("A") + i) for i in range(26)}
        for name, value in TYPES.items():
            pointer = g.peek((bank, table + 2 * value)) | g.peek((bank, table + 2 * value + 1)) << 8
            text = ""
            while (c := g.peek((bank, pointer + len(text)))) != 0x50:
                text += charmap[c]
            self.assertEqual(text, name, hex(value))


class SteelTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_magnet_pull(self):
        g = self.game
        for enemy_ability, player_types, trapped in (
                ("MAGNET_PULL", ("ELECTRIC", "STEEL"), True),
                ("MAGNET_PULL", ("STEEL", "STEEL"), True),
                ("MAGNET_PULL", ("ELECTRIC", "ELECTRIC"), False),
                ("NO_ABILITY", ("STEEL", "STEEL"), False)):
            with self.subTest(ability=enemy_ability, types=player_types):
                g.reset()
                g.poke("wLinkState", 0)
                g.poke("wPlayerAbility", ABILITIES["NO_ABILITY"], ABILITIES[enemy_ability])
                g.poke("wBattleMonType1", *(TYPES[t] for t in player_types))
                self.assertEqual(g.call("PlayerTrapped")["carry"], trapped)

    def poisoned(self, target_types):
        import random
        g = self.game
        g.reset()
        g.skip_delays()
        g.skip_sound_waits()
        g.auto_buttons()
        mx.setup(g, random.Random(3))
        g.poke(H_WHOSETURN, 0)
        g.poke("wPlayerAbility", ABILITIES["NO_ABILITY"], ABILITIES["NO_ABILITY"])
        g.poke("wPlayerMoveEffect", mx_effects()["POISON_EFFECT"])
        g.poke("wEnemyBattleStatus2", 0)
        g.poke("wEnemyMonStatus", 0)
        g.poke("wEnemyMonType", *(TYPES[t] for t in target_types))
        g.call("PoisonEffect", max_frames=2000)
        return g.peek("wEnemyMonStatus") != 0

    def test_steel_cant_be_poisoned(self):
        self.assertTrue(self.poisoned(("NORMAL", "NORMAL")))
        self.assertFalse(self.poisoned(("STEEL", "STEEL")))
        self.assertFalse(self.poisoned(("ELECTRIC", "STEEL")))
        self.assertFalse(self.poisoned(("POISON", "POISON")))
