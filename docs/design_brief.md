# Design brief: modernizing this fork

This is the starting point for planning the next phase: bringing in mechanics
from later generations while keeping the game a Game Boy game. It records
what is known (measured from the code and the build, October 2026), the rules
the work follows, and the decisions that are still open.

Read it together with `tests/README.md`, which explains how changes are
checked.

## Goals and non-goals

- **Goal:** a single-player game with modern mechanics (Gen 9 style where it
  fits), new areas, and a codebase that is easy to extend.
- **Goal:** runs on an original Game Boy. A Game Boy Color, and to a lesser
  extent a Super Game Boy, get a better-looking version of the same game.
- **Goal:** runs on real hardware (flash carts), not only on emulators.
- **Non-goal:** compatibility with official games. Trading and battling with
  retail cartridges, Pokémon Stadium transfers and Gen 2 time capsule support
  may all be dropped.
- **Non-goal:** loading saves from earlier versions. Players start a new game.
- **Non-goal:** merging back into Shin Pokémon. This is its own fork.

## Budget: what is free

| Resource | Size | Free | Notes |
|---|---|---|---|
| ROM | 1 MB (64 banks) | ~169 KB inside the 51 switchable banks in use, plus banks 52-63 (192 KB) completely empty | The cartridge type (MBC3) allows 2 MB, so the ROM can double |
| ROM bank 0 (always loaded) | 16 KB | 123 bytes | Shared helpers must live here to be callable from every bank cheaply |
| Battle engine bank ($0F) | 16 KB | 198 bytes | Was 21 before the merges started; each merge frees more |
| WRAM | 8 KB | **6 bytes** (`$defa`-`$deff`) | **The real constraint.** Everything below depends on not needing more |
| Save RAM | 32 KB (4 banks) | ~7.4 KB | Bank 0: 1960, bank 1: 2780, banks 2-3: 1453 each |
| Event flags | 2560 bits (`wEventFlags`, 320 bytes, saved) | ~2000 | 2056 placeholder flags exist and only 44 are referenced by name. Some code computes flag numbers, so check before claiming a range |
| Map IDs | 1 byte | ~6-29 | 249 maps are defined; 22 of them look unused and could be reclaimed |

ROM space is plentiful. RAM is not: any new system has to justify every byte
of WRAM it uses, and saved state goes in save RAM or event flags.

## Rule 1: the Game Boy is the target, the Game Boy Color is a bonus

Game logic and saved state must fit an original Game Boy. Game Boy Color
features may change how the game looks and feels, never what happens.

- The game already detects the hardware at startup (`hGBC` in `hram.asm`:
  zero on DMG/SGB, nonzero on GBC) and already has GBC-only color and a 60 fps
  mode that uses double-speed CPU.
- GBC extras that fit this rule: per-tile color attributes, the second VRAM
  bank for animated tiles and richer move animations, faster VRAM transfers
  (HDMA), double speed for smoother effects.
- GBC extra WRAM (banks 2-7) may be used as a cache (for example
  pre-decompressed graphics) as long as the DMG path recomputes the same thing.
  It must never hold game state.
- Super Game Boy palettes and borders are fair game; the header already flags
  SGB support.

## Rule 2: derive state instead of storing it

When a new mechanic needs state, prefer computing it from data the game
already has. Ideas that fit, with what each costs:

| Mechanic | How | New RAM | Notes |
|---|---|---|---|
| Day/night | A 16-minute cycle from the play-time clock (`wPlayTimeMinutes` mod 16, e.g. four 4-minute phases) | 0 | The clock is saved already. It only runs during play (`wd732` bit 0) and **stops at 255 hours** (`wPlayTimeMaxed`), so the cycle needs another source after that |
| Night visuals | DMG: reuse the darkness mechanism from Rock Tunnel (`wMapPalOffset`). GBC: tint palettes | 0 | |
| Time-based encounters | Extra encounter tables in ROM | 0 | |
| Natures | Computed from the DVs, the way Gen 3 used a hidden value | 0 | Fixed for life, so breeding for nature means breeding for DVs |
| Abilities | From the species; one DV bit picks between two where a species has two | 0 | |
| Held items | The catch-rate byte every Pokémon carries (Gen 2 used it this way) | 0 | **Conflict:** `Mon1BCDScore` in `custom_functions/func_misc.asm` scores party mon 1 by its catch rate |
| Weather | From the map and time of day | 0 | Battle weather that moves change needs a battle-only byte |
| New world events | Spare event flags | 0 | |
| Battle-only state | Share space with overworld-only scratch RAM, as the game already does in many places | 0 | Needs a RAM audit to find safe overlaps |

## Rule 3: every change is tested, and refactors must not change behaviour

- `tests/compare_builds.py --base <ref>` builds an earlier commit and the
  working tree and runs randomized battle states through both. For a refactor,
  results and every byte of RAM must match. It has caught a real bug in my own
  merge work and a flaw in its own test data, so trust it over intuition.
- New behaviour gets spec tests (`tests/test_*.py`) describing the intended
  rules.
- Before pushing: `make test`, the comparison against the previous commit,
  all eight ROM variants build, and a short battle in the emulator.

## Refactor status

Mirrored player/enemy battle routines are being merged into single routines
that take the side as input. Done:

- `GetDamageVars` (attack/defense selection for damage), side and move
  category in `wDamageVarsIndex`
- `ApplyAttackToPokemon` / `ApplyDamageToPokemon`, target in `wDamageTarget`

Patterns established:

- `GetAddrFromTable` looks up an address from a small table indexed by side.
  It lives in the battle bank; move it to bank 0 when another bank needs it.
- The side is passed explicitly by the old entry points rather than read from
  `H_WHOSETURN`, because about 20 places change that flag, and in at least one
  case (a confused Pokémon hurting itself) the target is not the side whose
  turn it is. Switching to `H_WHOSETURN` needs a proof per call site.
- Each merge has used one byte of WRAM for its side variable. With 6 bytes
  left, **that pattern cannot continue**; see the first open decision.

### Remaining player/enemy pairs

The two merges above were true mirrors: the same logic with different
addresses. The remaining pairs in `engine/battle/core.asm` are not, so merging
them is a redesign that needs the open decisions below settled first.

| Pair | How they differ | Recommendation |
|---|---|---|
| `CheckIf{Player,Enemy}NeedsToChargeUp` / `{Player,Enemy}CanExecuteMove` / `{Player,Enemy}CalcMoveDamage` | Mid-sections of the two move-execution flows. Only the player's spends PP here; only the enemy's looks up the move name and clears disobedience; the enemy's swaps the two mons' levels three times around the critical-hit and damage steps so the damage formula reads the right level | Merge as part of the staged damage pipeline (decision 3), which removes the need for the level swapping |
| `Check{Player,Enemy}StatusConditions` | ~300 lines each. Local labels now match (renamed with byte-identical ROMs); 139 normalized lines in 16 places still differ, all real behaviour: sleep animation number, text before vs after animations, player-only branches such as disobedience | Merge with the 16 differences kept as explicit side checks, once decision 1 settles how the side is passed |
| `Draw{Player,Enemy}HUDAndHPBar` | Different jobs: the player's copies the mon into `wLoadedMon`, draws the EXP bar and drives the low-health alarm; the enemy's computes its HP bar by hand | Leave separate, or share only the HP bar maths |
| `Handle{Player,Enemy}MonFainted` and other turn-flow routines | Player and enemy fainting lead to different flows (party menu vs trainer sending out the next mon) | Leave separate |

## Open decisions

These are the questions the next planning session should settle, roughly in
the order they block other work.

1. **Where merged routines keep their side.** Options: one shared byte with a
   rule against nesting; the stack; a register convention; proving
   `H_WHOSETURN` correct per call site and using it. This decides how the
   remaining merges are written.
2. **RAM strategy.** How much can a RAM audit reclaim by overlapping
   battle-only and overworld-only scratch areas? Is it worth building a tool
   that maps which routines touch which RAM, so overlaps can be proven safe?
3. **The staged damage pipeline (Step 2).** The order of stages (base damage,
   critical hit, same-type bonus, type effectiveness, screens and burn, random
   factor) and the hook points that natures, abilities, held items and weather
   will use.
4. **Map IDs.** Widen to two bytes, or add a "region" byte that selects a
   second set of 256 maps? Either touches warps, connections, the fly list and
   save data.
5. **Day/night details.** Cycle length and phases, what happens after the
   play-time clock stops at 255 hours, and which systems react to time (encounters,
   palettes, NPCs, events).
6. **Where saved per-Pokémon data goes** if derived values aren't enough
   (for example EVs): the box and party structures in save RAM, at what cost
   per box.
7. **Link play between two copies of this fork.** Keep the existing protocol,
   or replace it with one that shares the random seed up front and checks
   battle state each turn so desyncs are detected.

## Known facts that are easy to get wrong

- 16-bit values are big-endian in battle and party structures, but the HP bar
  variables (`wHPBarOldHP`, `wHPBarNewHP`, `wHPBarMaxHP`) are little-endian.
- `BattleRandom` calls `Random` outside link battles; link battles use a
  shared list of nine numbers.
- `MON_GHOST` (`$B8`) and the two fossil species are display-only placeholders
  that can only be the enemy; drawing one in the player's slot reads garbage.
- Predef calls record `hl`, `de` and `bc` in `wPredefRegisters`, so a refactor
  that changes register values at a predef call shows up as a RAM difference
  even when behaviour is the same.
- Stats are capped at 999; the HP bar animates one point at a time, so test
  data far outside real ranges just makes tests slow.
