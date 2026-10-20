"""Spec tests for abilities, part 1: the infrastructure (design brief, plan
step E, part 4).

Each species has two abilities (Gen 9's non-hidden ones; a species with one
has it twice), and bit 0 of the third DV byte picks one. Abilities that need
weather, held items, infatuation or the Steel type are NO_ABILITY until those
exist. Each mon's ability is set when it is sent out; Neutralizing Gas stops
every other ability while it is out, and Mold Breaker ignores the target's
ability where the user's move meets it.
"""

import os
import re
import unittest

from harness import REPO_ROOT, shared_game
from suites.apply_attack import H_WHOSETURN
from test_special_split import SPECIES, TRAINER_DVS

SCREEN_WIDTH = 20


def _abilities():
    values = {}
    with open(os.path.join(REPO_ROOT, "constants", "ability_constants.asm")) as f:
        for line in f:
            m = re.match(r"\s*const (\w+)\s*; \$([0-9A-F]{2})", line)
            if m:
                values[m.group(1)] = int(m.group(2), 16)
    return values


def _table():
    """species name -> (slot 0, slot 1), from data/mon_abilities.asm"""
    table = []
    with open(os.path.join(REPO_ROOT, "data", "mon_abilities.asm")) as f:
        for line in f:
            m = re.match(r"\s*db (\w+),\s*(\w+)\s*; (\w+)", line)
            if m:
                table.append((m.group(3), (ABILITIES[m.group(1)], ABILITIES[m.group(2)])))
    return table


def _names():
    with open(os.path.join(REPO_ROOT, "data", "ability_names.asm")) as f:
        return re.findall(r'db "([^"@]*)@"', f.read())


ABILITIES = _abilities()
TABLE = _table()
NAMES = _names()

# Gen 9's non-hidden abilities, for a spread of species
SPOT_CHECKS = {
    "BULBASAUR": ("OVERGROW", "OVERGROW"),
    "PIKACHU": ("STATIC", "STATIC"),
    "GENGAR": ("CURSED_BODY", "CURSED_BODY"),
    "KOFFING": ("LEVITATE", "NEUTRALIZING_GAS"),
    "MACHOP": ("GUTS", "NO_GUARD"),
    "PORYGON": ("TRACE", "DOWNLOAD"),
    "STARMIE": ("ILLUMINATE", "NATURAL_CURE"),
    "KANGASKHAN": ("EARLY_BIRD", "SCRAPPY"),
    "PINSIR": ("HYPER_CUTTER", "MOLD_BREAKER"),
    "CHANSEY": ("NATURAL_CURE", "SERENE_GRACE"),
    "MAGNEMITE": ("MAGNET_PULL", "STURDY"),
    # weather and infatuation leave slots empty
    "CLEFAIRY": ("NO_ABILITY", "MAGIC_GUARD"),
    "GRIMER": ("STENCH", "STICKY_HOLD"),  # empty until held items
    "MEOWTH": ("PICKUP", "TECHNICIAN"),
    "ODDISH": ("NO_ABILITY", "NO_ABILITY"),
    "MAGIKARP": ("NO_ABILITY", "NO_ABILITY"),
}


def text(name):
    """The game's character codes for a name in capitals and spaces."""
    return [0x7F if c == " " else 0xE8 if c == "." else 0x80 + ord(c) - ord("A") for c in name]


class AbilityDataTest(unittest.TestCase):
    def test_every_species_has_a_row(self):
        self.assertEqual(len(TABLE), max(SPECIES.values()))
        self.assertEqual([name for name, _ in TABLE][SPECIES["MEWTWO"] - 1], "MEWTWO")

    def test_spot_checks(self):
        table = dict(TABLE)
        for species, pair in SPOT_CHECKS.items():
            self.assertEqual(table[species], tuple(ABILITIES[a] for a in pair), species)

    def test_unworkable_abilities_are_absent(self):
        for name in ("CHLOROPHYLL", "SWIFT_SWIM", "SAND_VEIL", "CLOUD_NINE", "LEAF_GUARD",
                     "HYDRATION", "CUTE_CHARM"):
            self.assertNotIn(name, ABILITIES)

    def test_names_fit(self):
        self.assertEqual(len(NAMES), len(ABILITIES))
        for name in NAMES:
            self.assertLessEqual(len(name), 12, name)


class GetMonAbilityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_every_species_and_slot(self):
        g = self.game
        g.reset()
        for index, (name, pair) in enumerate(TABLE, 1):
            for dv3 in (0x00, 0x01, 0xF0, 0xF1, 0x5E, 0x5F):
                out = g.call("GetMonAbility", a=index, bc=0x1200 | dv3, de=0x3456, hl=0x789A)
                with self.subTest(species=name, dv3=dv3):
                    self.assertEqual(out["a"], pair[dv3 & 1])
                    self.assertEqual((out["bc"], out["de"], out["hl"]), (0x1200 | dv3, 0x3456, 0x789A))

    def test_names(self):
        g = self.game
        for ability, name in enumerate(NAMES):
            with self.subTest(name=name):
                g.reset()
                out = g.call("GetAbilityName", a=ability)
                self.assertEqual(out["de"], g.addr("wcd6d"))
                self.assertEqual(g.peek("wcd6d", len(name) + 1), text(name) + [0x50])


class SlotBitTest(unittest.TestCase):
    """The DV generators roll the slot; trainers' fixed DVs give slot 0."""

    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_random_dv(self):
        g = self.game
        for slot_roll in (0x00, 0x01, 0xFE, 0x37):
            with self.subTest(roll=slot_roll):
                g.reset()
                g.poke("wOptions", 0)  # normal mode: no rerolls
                g.queue_random(0x12, 0x34, 0x5A, slot_roll)
                out = g.call("Random_DV")
                self.assertEqual((out["a"], out["bc"] >> 8, out["bc"] & 0xFF),
                                 (0x12, 0x34, 0x50 | slot_roll & 1))
                self.assertEqual(g.random_used(), 4)

    def test_random_bias_dv(self):
        g = self.game
        for slot_roll in (0x00, 0x01):
            with self.subTest(roll=slot_roll):
                g.reset()
                g.poke("wChannelSoundIDs", 0)
                g.poke("wCurOpponent", 0)
                g.queue_random(0x12, 0x34, 0x56, 0x78, 0x30, 0x40, slot_roll)
                out = g.call("Random_BiasDV")
                self.assertEqual((out["a"], out["bc"] >> 8, out["bc"] & 0xFF),
                                 (0x78, 0x56, 0x40 | slot_roll))

    def test_forced_shiny_wild_mon(self):
        g = self.game
        for roll in (0x50, 0x51):
            with self.subTest(roll=roll):
                g.reset()
                g.poke("wFontLoaded", 0x80)  # force a shiny
                g.poke("wBattleType", 0)
                g.poke("wFlags_D733", 0)
                g.poke("wCurMap", 0)
                g.queue_random(roll, 0x00)
                g.call("DetermineWildMonDVs")
                self.assertEqual(g.peek("wEnemyMonDVs", 3), [0x2A, 0xAA, roll])

    def test_trainer_dvs(self):
        self.assertEqual(TRAINER_DVS[2] & 1, 0)


class SendOutTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_player_send_out(self):
        g = self.game
        for species in ("KOFFING", "MACHOP", "CLEFAIRY"):
            for slot in (0, 1):
                with self.subTest(species=species, slot=slot):
                    g.reset()
                    g.poke("wPlayerAbility", 0xEE)
                    g.poke("wWhichPokemon", 0)
                    g.poke("wPlayerMonNumber", 0)
                    g.poke("wPartyMon1Species", SPECIES[species])
                    g.poke("wPartyMon1DVs", 0x99, 0x99, 0x90 | slot)
                    g.poke("wBattleMonSpecies2", SPECIES[species])
                    g.call("LoadBattleMonFromParty")
                    self.assertEqual(g.peek("wPlayerAbility"), dict(TABLE)[species][slot])

    def test_link_enemy_send_out(self):
        g = self.game
        for slot in (0, 1):
            with self.subTest(slot=slot):
                g.reset()
                g.poke("wEnemyAbility", 0xEE)
                g.poke("wWhichPokemon", 1)
                g.poke("wEnemyMon2Species", SPECIES["PORYGON"])
                g.poke("wEnemyMon2DVs", 0x99, 0x99, 0x90 | slot)
                g.call("LoadEnemyMonFromParty")
                self.assertEqual(g.peek("wEnemyAbility"), dict(TABLE)["PORYGON"][slot])

    def test_trainer_send_out(self):
        g = self.game
        g.reset()
        g.poke("wEnemyAbility", 0xEE)
        g.poke("wLinkState", 0)
        g.poke("wIsInBattle", 2)
        g.poke("wOptions", 0)  # fixed trainer DVs
        g.poke("wEnemyBattleStatus3", 0)
        g.poke("wWhichPokemon", 0)
        g.poke("wEnemyMonSpecies2", SPECIES["PINSIR"])
        g.poke("wCurEnemyLVL", 30)
        g.call("LoadEnemyMonData")
        self.assertEqual(g.peek("wEnemyMonDVs", 3), list(TRAINER_DVS))
        self.assertEqual(g.peek("wEnemyAbility"), ABILITIES["HYPER_CUTTER"])


class EffectiveAbilityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def side(self, side, player, enemy):
        g = self.game
        g.reset()
        g.poke("wPlayerAbility", ABILITIES[player], ABILITIES[enemy])
        out = g.call("GetSideAbility", a=side, bc=0x1234, de=0x5678, hl=0x9ABC)
        self.assertEqual((out["bc"], out["de"], out["hl"]), (0x1234, 0x5678, 0x9ABC))
        self.assertEqual(out["z"], out["a"] == 0)
        return out["a"]

    def test_plain(self):
        self.assertEqual(self.side(0, "STATIC", "LEVITATE"), ABILITIES["STATIC"])
        self.assertEqual(self.side(1, "STATIC", "LEVITATE"), ABILITIES["LEVITATE"])
        self.assertEqual(self.side(1, "STATIC", "NO_ABILITY"), 0)

    def test_neutralizing_gas_stops_the_other_side(self):
        gas = "NEUTRALIZING_GAS"
        self.assertEqual(self.side(0, "STATIC", gas), 0)
        self.assertEqual(self.side(1, gas, "LEVITATE"), 0)
        self.assertEqual(self.side(0, gas, "LEVITATE"), ABILITIES[gas])
        self.assertEqual(self.side(1, gas, gas), ABILITIES[gas])

    def test_user_and_target(self):
        g = self.game
        for turn in (0, 1):
            with self.subTest(turn=turn):
                g.reset()
                g.poke("wPlayerAbility", ABILITIES["GUTS"], ABILITIES["LEVITATE"])
                g.poke(H_WHOSETURN, turn)
                user, target = ("GUTS", "LEVITATE")[::1 - 2 * turn]
                self.assertEqual(g.call("UserAbility")["a"], ABILITIES[user])
                self.assertEqual(g.call("TargetAbility")["a"], ABILITIES[target])
                self.assertEqual(g.call("TargetAbilityForMove")["a"], ABILITIES[target])

    def test_mold_breaker(self):
        g = self.game
        for turn in (0, 1):
            with self.subTest(turn=turn):
                g.reset()
                pair = [ABILITIES["MOLD_BREAKER"], ABILITIES["LEVITATE"]]
                g.poke("wPlayerAbility", *pair[::1 - 2 * turn])
                g.poke(H_WHOSETURN, turn)
                out = g.call("TargetAbilityForMove")
                self.assertEqual((out["a"], out["z"]), (0, True))
                # abilities that react after a hit still work
                self.assertEqual(g.call("TargetAbility")["a"], ABILITIES["LEVITATE"])

    def test_gas_stops_mold_breaker(self):
        g = self.game
        g.reset()
        g.poke("wPlayerAbility", ABILITIES["MOLD_BREAKER"], ABILITIES["NEUTRALIZING_GAS"])
        g.poke(H_WHOSETURN, 0)
        self.assertEqual(g.call("TargetAbilityForMove")["a"], ABILITIES["NEUTRALIZING_GAS"])


class StatusScreenAbilityTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.game = shared_game()

    def test_name_under_the_pic(self):
        g = self.game
        tilemap = g.addr("wTileMap")
        for species, slot, name in (("KOFFING", 1, "NEUTRAL. GAS"), ("PIKACHU", 0, "STATIC"),
                                    ("ODDISH", 1, "NO ABILITY")):
            with self.subTest(species=species, slot=slot):
                g.reset()
                g.poke(tilemap, *[0x7F] * (SCREEN_WIDTH * 18))
                g.poke("wLoadedMonSpecies", SPECIES[species])
                g.poke("wLoadedMonDVs", 0x99, 0x99, 0x90 | slot)
                g.call("PrintStatusScreenAbility")
                row7 = tilemap + 7 * SCREEN_WIDTH
                self.assertEqual(g.peek(row7 + 8, 12), text(name) + [0x7F] * (12 - len(name)))


if __name__ == "__main__":
    unittest.main()
