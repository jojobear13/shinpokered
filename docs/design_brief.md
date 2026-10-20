# Design brief: modernizing this fork

This is the plan for the next phase: bringing in mechanics from later
generations while keeping the game a Game Boy game. It records what is known
(measured from the code and the build, October 2026), the rules the work
follows, the decisions taken, and the order of work.

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
| ROM | 1 MB (64 banks) | ~169 KB inside the 51 switchable banks in use, plus banks 52-63 (192 KB) completely empty | The cartridge type (MBC3, `-m 0x13`: RAM and battery, no real-time clock) allows 2 MB, so the ROM can double |
| ROM bank 0 (always loaded) | 16 KB | 98 bytes | Shared helpers must live here to be callable from every bank cheaply. Step D's accessors took 55 bytes, after removing the unused `FarCopyData3` (30). The fixed "Home" section at `$61` is full |
| ROM bank 3 | 16 KB | 1230 bytes | Holds the item, catching, `MoveMon`, status-screen and day-care code. Moving `DrawBadges` and its badge graphics out freed 1261; the special split took 34 |
| Battle engine bank ($0F) | 16 KB | 124 bytes | Was 21 before the merges started; the special split took 59, the physical/special split, move-menu marks and Counter most of the rest. Abilities live in bank 9 and cost bank $0F only their far-call hooks; moving `CalcHitChance` to bank 9 paid for most of part 3's |
| WRAM | 8 KB | **1088 bytes** (end of WRAM to `$deff`) | Step D moved the current box and the day-care mon to save RAM, freeing 1177 bytes; the special split took 53 (a third DV byte and a sixth stat in every party and battle struct), natures 1, abilities 15 (each side's ability in battle, a flags byte, a side effect's chance as abilities change it, and an 11-byte snapshot of the target before each move). Still allocate new state through this table |
| HRAM | 127 bytes | 4 bytes: `$FFA8`, `$FFD9`, `$FFDF`, `$FFE3` (`$FFE2` is `hBattleSide` since step A) | Checked against every named and literal reference in the source. `$FF9E` looks free but is the third byte of `H_SAVEDNUMTOPRINT`. Confirm each byte with a canary run (decision 2) before first use. `ldh` is a byte shorter and a cycle faster than a WRAM load, and `H_WHOFIRST`/`H_WHOSETURN` already set the precedent for battle flags here |
| Save RAM | 32 KB (4 banks) | ~6.3 KB | Bank 0: 783 (the live box and day care took 1177), bank 1: 2779, banks 2-3: 1453 each |
| Event flags | 2560 bits (`wEventFlags`, 320 bytes, saved) | ~2000 | 2056 placeholder flags exist and only 44 are referenced by name. Some code computes flag numbers, so check before claiming a range |
| Map IDs | 1 byte | 6 unallocated plus 22 defined-but-unused | 250 constants are defined (last is `$F7`) |

ROM space is plentiful. RAM is not: any new system has to justify every byte
of WRAM it uses, and saved state goes in save RAM or event flags. Every step
in the plan records the WRAM and HRAM it took or freed in this table.

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
| Day/night | A 24-minute cycle from the play-time clock (decision 5) | 0 | The clock is saved already and only runs during play (`wd732` bit 0). **Correction:** in this fork the hours byte carries into `wPlayTimeMaxed` (`engine/play_time.asm`), so the clock runs to 32,768 hours, not 255; `PrintPlayTime` in `custom_functions/func_misc.asm` prints it as a 16-bit hour count |
| Night visuals | DMG: reuse the palette-register mechanism behind Rock Tunnel's darkness (`wMapPalOffset`) with a milder value. GBC: tint palettes | 0 | |
| Time-based encounters | Extra encounter tables in ROM | 0 | |
| Natures | Computed from the DVs, the way Gen 3 used a hidden value | 0 | Fixed for life, so breeding for nature means breeding for DVs |
| Abilities | From the species; one bit picks between two where a species has two (the spare low nibble of the third DV byte, decision 6) | 2 battle-only bytes | Done in step E part 4: bit 0 of the third DV byte. The battle bytes exist because Trace changes an ability mid-battle |
| Held items | The catch-rate byte every Pokémon carries (Gen 2 used it this way) | 0 | The fork already reads it as a Gen 2 item in `CheckGorgeousBox` (`engine/items/tms.asm`), and the catch formula reads `wEnemyMonActualCatchRate`, not the struct byte. The one real reader of the byte as a catch rate is `Mon1BCDScore` in `custom_functions/func_misc.asm`; decision 6 resolves it |
| EVs | Already exist: the five 16-bit stat-experience fields in the box struct. Special Attack and Special Defense share the Special one, as in Gen 2 | 0 | |
| Weather | From the map and time of day | 1 battle-only byte | For weather that moves change during a battle |
| New world events | Spare event flags | 0 | |
| Battle-only state | Share space with overworld-only scratch RAM, as the game already does in many places | 0 | Decision 2 says how overlaps are proven safe |

## Rule 3: every change is tested, and refactors must not change behaviour

- `tests/compare_builds.py --base <ref>` builds an earlier commit and the
  working tree and runs randomized battle states through both. For a refactor,
  results and every byte of RAM must match. It has caught a real bug in my own
  merge work and a flaw in its own test data, so trust it over intuition.
- New behaviour gets spec tests (`tests/test_*.py`) describing the intended
  rules.
- Before pushing: `make test`, the comparison against the previous commit,
  all eight ROM variants build, and a short battle in the emulator.
- A structural change and a behaviour change never share a commit. The
  structural commit compares identical; the behaviour commit carries its spec
  test.

## Refactor status

Mirrored player/enemy battle routines are being merged into single routines
that take the side as input. Done:

- `GetDamageVars` (attack/defense selection for damage), side and move
  category in `hBattleSide` (step A replaced `wDamageVarsIndex`)
- `ApplyAttackToPokemon` / `ApplyDamageToPokemon`, target in `hBattleSide`
  (step A replaced `wDamageTarget`)

Patterns established:

- `GetAddrFromTable` looks up an address from a small table indexed by side.
  It lives in the battle bank; move it to bank 0 when another bank needs it.
- The side is passed explicitly by the old entry points rather than read from
  `H_WHOSETURN`, because 43 places write that flag and 111 places in the
  battle engine read it, and in at least one case (a confused Pokémon hurting
  itself) the target is not the side whose turn it is.
- Each merge so far used one byte of WRAM for its side variable. Decision 1
  replaces both bytes with one HRAM byte.

### Remaining player/enemy pairs

The two merges above were true mirrors: the same logic with different
addresses. The remaining pairs in `engine/battle/core.asm` are not, so merging
them is a redesign that follows the decisions below.

| Pair | How they differ | Plan |
|---|---|---|
| `CheckIf{Player,Enemy}NeedsToChargeUp` / `{Player,Enemy}CanExecuteMove` / `{Player,Enemy}CalcMoveDamage` | Mid-sections of the two move-execution flows. Only the player's spends PP here; only the enemy's looks up the move name and clears disobedience; the enemy's swaps the two mons' levels three times (`SwapPlayerAndEnemyLevels`) so `CriticalHitTest` and `CalculateDamage` read the right level | Merge as the first stage of the damage pipeline (decision 3, plan step B). Reading the level through the side table removes the swapping |
| `Check{Player,Enemy}StatusConditions` | ~300 lines each. Local labels now match (renamed with byte-identical ROMs); 139 normalized lines in 16 places still differ, all real behaviour: sleep animation number, text before vs after animations, player-only branches such as disobedience | Merge with the 16 differences kept as explicit side checks on `hBattleSide` (plan step C) |
| `Draw{Player,Enemy}HUDAndHPBar` | Different jobs: the player's copies the mon into `wLoadedMon`, draws the EXP bar and drives the low-health alarm; the enemy's computes its HP bar by hand | Leave separate; share only the HP bar maths if a later change touches it |
| `Handle{Player,Enemy}MonFainted` and other turn-flow routines | Player and enemy fainting lead to different flows (party menu vs trainer sending out the next mon) | Leave separate |

## Decisions

Settled in October 2026. Each one says what was chosen, why, what it costs,
and what it rules out. Reopen one only with a measurement that contradicts
its reasoning.

### 1. Merged routines keep their side in one HRAM byte, `hBattleSide`

**Decision.** One byte of HRAM at `$FFE2`, named `hBattleSide`. Bit 0 is the
side (0 = player's mon, 1 = enemy's mon, the same index `GetAddrFromTable`
takes). Bit 1 is the move category flag that `wDamageVarsIndex` carries today
(`DAMAGEVARS_SPECIAL`). It replaces both `wDamageVarsIndex` and
`wDamageTarget`, which frees two WRAM bytes (6 becomes 8).

**Rules for using it.**

- The old entry points stay as two-instruction shims (`xor a` or `ld a, 1`,
  then `ldh [hBattleSide], a`) that fall into the merged body. Nothing outside
  the battle engine learns a new calling convention.
- A merged routine reads `hBattleSide` at entry and may re-read it at any
  point. It may call another merged routine with a *different* side only if it
  restores `hBattleSide` afterwards (`push af` / `pop af` around the call, or
  set it again). Nested calls with the same side need nothing. This is the
  "shared byte" option with caller-saves instead of a ban on nesting.
- `H_WHOSETURN` is not the source of truth. A merged routine may be entered
  from `H_WHOSETURN` only at a call site that is the turn's own attacker flow
  (`ExecutePlayerMove` / `ExecuteEnemyMove` set the flag at their top, so that
  proof is trivial). Every other call site keeps passing the side explicitly.

**Why not the alternatives.** The stack has no cheap SP-relative addressing on
this CPU, and the ~300-line routines being merged already have push/pop pairs
around calls, so a stack slot would move with every one of them. A register
convention cannot survive 300 lines that use every register. Proving
`H_WHOSETURN` at 111 read sites is more work than the merges themselves, and
the confusion self-hit case shows the proof can fail.

**Cost.** One HRAM byte. The battle bank gains a byte per access (`ldh` vs
`ld a, [wXXX]`), which matters with 198 bytes left there.

### 2. RAM strategy: move the current box to save RAM; prove overlaps with canaries, not a static tool

**Decision, part one: the current box leaves WRAM.** The current box
(`wNumInBox` through `wBoxMonNicksEnd`, `$da80`-`$dee2`, 1122 bytes) sits in
WRAM only because Gen 1 kept it there; Gen 2 keeps the current box in save RAM
and reads it through the SRAM window. The save routine already mirrors it to
`sCurBoxData` in bank 1. Moving it is the only change that turns the WRAM
budget from "6 bytes" into "room for everything in this brief", so it is
scheduled early (plan step D), before any mechanic that needs more than the 8
bytes decision 1 leaves.

- All box access goes through one accessor that enables SRAM bank 1, does the
  read or write, and disables SRAM again. SRAM is never left enabled across a
  frame, so a power cut cannot corrupt an open bank.
- The current box gets its own checksum byte, updated by the accessor on every
  write, like the per-box checksums banks 2 and 3 already have. The main
  checksum range (`sPlayerName` to `sMainDataCheckSum`, which today covers
  `sCurBoxData`) shrinks to exclude it, since the box is no longer written at
  save time.
- Scope, measured: about 90 references to the box symbols across 15 files.
  The heavy ones are `engine/items/items.asm` (21), `engine/save.asm` (15),
  `engine/add_mon.asm` (15), `engine/remove_pokemon.asm`,
  `engine/printer/printer.asm` and `engine/menu/bills_pc.asm` (9 each). The
  rest are one or two reads each.
- The day-care mon (`wDayCareMon`, a 33-byte box struct just above the box)
  moves with it.
- *As built:* the box is still copied to bank 1 when saving, and that copy,
  not the live one, has the checksum. Keeping the box only in save RAM would
  let a deposit outlive a reset that the party does not, which clones the
  mon. See "Step D as done" under the plan.

**Decision, part two: overlaps are proven dynamically.** Where a battle-only
variable is to share space with overworld-only scratch, the proof is a canary
run in the existing harness: fill the candidate region with a pattern, run
every suite in `tests/suites/` plus a scripted full battle, and assert the
pattern survived. The reverse direction (nothing in the overworld reads the
region after a battle without writing it first) is a symbol-reference check
per reader. A region passes only when both hold.

**No static routine-to-RAM mapping tool.** The code computes addresses
(`AddNTimes` over structs, `hl` arithmetic, predef pointer tables), so a
static tool would miss accesses and give false confidence. A grep wrapper that
lists, per symbol, the files and banks that reference it is worth an afternoon
and is enough to drive the reader check.

**Standing targets.** Until the box move lands, new battle-only state comes
from the 8 free WRAM bytes and the 4 remaining HRAM bytes, and nothing else.
After it lands, the freed 1122 bytes are allocated through this table, not
first come first served.

### 3. The damage pipeline: fixed stage order, hooks as tables, random last

**Measured current order** (player and enemy flows, `engine/battle/core.asm`):
`CriticalHitTest`, `HandleCounterMove`, `GetDamageVars` (stat selection;
Reflect and Light Screen double the defending stat here; burn and paralysis
were already applied to the stored stats by `ApplyBurnAndParalysisPenalties`),
`CalculateDamage` (critical hit doubles the level; Explosion halves defense;
zero power exits; cap 999, minimum 1), `AdjustDamageForMoveType` (STAB, then
type effectiveness, accumulated in `wDamageMultipliers`), `RandomizeDamage`
(217-255 over 255), then `MoveHitTest`.

**Decision.** The merged pipeline keeps that order and adds one stage. Each
stage names its hook points; a hook is a table lookup by ability, item or
weather id that returns a multiplier or a stat change, so adding a mechanic
means adding a table row, not a branch.

| Stage | Routine | Hooks |
|---|---|---|
| S0 Select | `GetDamageVars` | Screens (exists). Stat-modifying abilities and items (Huge Power, Thick Club, Choice Band, Eviolite-style) as a register-disciplined call at the end, with the stats still in `bc`, so nothing new is stored |
| S1 Base | `CalculateDamage` | None. Level comes from the side table, which removes `SwapPlayerAndEnemyLevels` |
| S2 Type | `AdjustDamageForMoveType` | Before STAB: move-type changes (Pixilate-style abilities, type items). After effectiveness: immunity abilities (Levitate, Flash Fire, Volt Absorb), which set effectiveness to zero so the existing "doesn't affect" path fires |
| S3 Modifiers (new) | one multiply and divide | Weather, held-item boosts, remaining abilities. Each hook multiplies a running numerator that starts at 16; damage = damage × n / 16, applied once. Sixteenths cannot express Gen 2's 1.1; type-boost items use 18/16 |
| S4 Random | `RandomizeDamage` | None. Stays last so random-number consumption is identical before and after the restructuring, which `compare_builds.py` requires |
| S5 Hit test | `MoveHitTest` | Unchanged position (a Gen 1 quirk: damage is computed before the hit roll) |

**Why S3 sits between type and random.** One multiply means one rounding
point and one overflow analysis (the 3-byte multiply handles 999 × 255).
Putting it after S2 lets the structural commit ship with S3 empty and compare
byte-identical, including random consumption. Gen 9 places weather before the
critical-hit step; the difference is rounding only, and matching Gen 9's
rounding is not a goal.

**Two commits, never one.** Step B merges the flows and installs the empty
hook tables with results and RAM identical to the previous build. Each
mechanic then lands in its own commit with a spec test.

**Out of scope here.** Whether critical hits should become Gen 9's ×1.5 and
whether screens should halve damage instead of doubling a stat are balance
decisions. They get their own entry in this section after the pipeline lands,
not a quiet change inside it.

### 4. Map IDs stay one byte; a region byte selects the map set

**Decision.** Add `wCurRegion` (1 byte, in the saved main data). Region 0 is
Kanto with every existing table unchanged. Map IDs remain one byte everywhere.
Warps, connections and fly data never cross a region; cross-region travel
(boat, train, a specific door) is a scripted special warp that sets
`wCurRegion` and `wDestinationMap`, the same path fly and dungeon warps use
today through `wDestinationMap` and `wDungeonWarpDestinationMap`.

**What changes.** Every per-map table gains a region level: map header
pointers and banks, map music, wild encounter pointers, fly warp data, town map
data, trainer headers and event displacement tables. One accessor
(`GetMapTablePointer`, bank 0) picks the table base from `wCurRegion`; about
15 lookup sites call it. `wLastBlackoutMap` gains `wLastBlackoutRegion`.
`wLastMap` stays single-byte and is only meaningful within a region; a region
switch resets it. The fly list per extra region is a flag array in event
flags (Rule 2), since `wTownVisitedFlag` is 13 bits for Kanto.

**Why not 16-bit IDs.** Map IDs are compared at 102 `wCurMap` sites and 46
sites for the other map variables, and they are baked into the `warp`,
connection, `EMAP`/`IMAP` and fly data macros. Widening costs a byte per
stored ID: six variables, the 32-entry warp buffer (128 bytes today, 160
after), and `hWarpDestinationMap`, which is 38 or more WRAM bytes for a
problem that one byte solves.

**Cost.** Two WRAM bytes, taken from the box-move budget. ROM for the extra
tables, which is plentiful.

**When.** The 28 free Kanto IDs are used first for additions inside Kanto.
The region byte lands before the first map outside Kanto, but new code that
looks up a per-map table goes through the accessor from day one so the switch
is a table change, not a rewrite.

### 5. Day/night: a 24-minute play-time day, computed on demand, no clock hardware

**Decision.** One in-game day is 24 minutes of the play-time clock. The
minute-of-day is `(hours & 1) × 12 + minutes` (because 60 mod 24 is 12),
which ranges 0-71, then minus 24 while it is 24 or more (at most twice), so
no division. A 24-entry table in ROM maps the
minute to a phase:

| Phase | Minutes | DMG look | GBC/SGB look | Encounter table |
|---|---|---|---|---|
| Morning | 0-3 | day palette | warm tint | Morning |
| Day | 4-13 | day palette | normal | Day |
| Evening | 14-15 | day palette | dusk tint | Night |
| Night | 16-23 | darker palette register value, outdoors only, via the `wMapPalOffset` mechanism | dark tint | Night |

**Why play time and not a real-time clock.** The header is MBC3 without the
timer (`-m 0x13`); real-time-clock support on flash carts is inconsistent; a
play-time day is deterministic, which the test harness needs (poke
`wPlayTimeHours` and `wPlayTimeMinutes`, call the phase routine); and a
24-minute day means a player sees every phase in a normal sitting, which a
single-player game without a clock needs for night-only content to be
reachable. The cycle length is one table and two constants, so retuning is
cheap.

**No cached phase.** The phase is recomputed where needed: once per map load,
and in the overworld loop on the frame where play-time seconds and frames are
both zero (once per play-minute). If that frame falls inside a menu, the next
map load or step catches up. Zero RAM.

**What reacts.** Outdoor maps (tileset type 2): palettes and encounter tables.
Scripts and NPC text, through a bank-0 `GetTimeOfDay` that returns the phase
in `a`. Evolution conditions (time-of-day level-ups replace Gen 2 friendship
evolutions). Battle weather at battle start (decision 3, S3). **What does
not:** indoor and cave maps, anything during a battle, link battles (both
players' clocks differ; the cable club map has no weather), and the clock's
stop at 32,768 hours, which freezes the phase and is accepted.

### 6. One new per-Pokémon byte, for the Special Defense DV; the catch-rate byte is the held item

**Revised for step E.** Special splits into Special Attack and Special Defense
with separate DVs, so the DVs grow from 2 bytes to 3: the third byte's high
nibble is the Special Defense DV and its low nibble is spare (the ability slot
bit can live there). The box struct grows from 33 to 34 bytes, with the costs
listed under "If a byte is ever added" below; the current box is in save RAM
since step D, so none of it lands in WRAM except the party's 6 bytes. The
rest of this decision stands.


**Decision.** The planned mechanics need no new per-mon data. Natures, gender,
shininess and the ability slot derive from the DVs. EVs are the stat
experience fields that already exist. The held item is the catch-rate byte,
which the fork already reads as an item in `CheckGorgeousBox`.

- The byte holds a fork item id, 0 for none. The species' catch rate is
  always read from the base stats (`wMonHCatchRate` after `GetMonHeader`),
  never from a mon's struct. `Mon1BCDScore` mode 1 switches to that, which
  resolves the one conflict. Wild Pokémon get items from a ROM table at
  encounter time, as in Gen 2.
- Friendship, the ball a mon was caught in, and met-location data are
  rejected: friendship evolutions become time-of-day or item evolutions
  (decision 5), and the others are cosmetic.

**If a byte is ever added.** The box struct grows from 33 to 34 bytes. Cost:
20 bytes per box (240 across the 12 stored boxes, 120 per bank in banks 2 and
3, which fits), 20 WRAM bytes for the current box unless decision 2 has moved
it, 6 WRAM bytes for the party (the party struct grows too), and one byte in
every box-struct copy (day care, trade buffers). So no per-mon byte is added
before the box move lands, and the entry here is updated when it does.

### 7. Link play: keep the protocol, add a version check and a per-turn state check, last

**Decision.** The existing cable-club handshake and the nine shared random
numbers (`wLinkBattleRandomNumberList`, exchanged in `engine/cable_club.asm`,
consumed by `BattleRandom`) stay. Two additions, both through the existing
`LinkBattleExchangeData` path and with no new RAM:

- A protocol version byte exchanged before the battle starts. A mismatch
  (including a retail cartridge) ends the link cleanly with a message instead
  of a desync later.
- At the end of every turn, each side sends a one-byte checksum of both
  battle structs' HP, status and stat stages plus the random list index. A
  mismatch ends the battle as a draw through the existing link-error path.

**Rule for every mechanic.** Both sides must consume `BattleRandom`
identically. Derived values (natures, abilities, held items) travel inside the
party data the link already exchanges, so they agree by construction; time
and weather do not exist in link battles (decision 5). A mirror test (run the
same turn on two harness instances with sides swapped and compare random
consumption) is in the suite: `tests/test_link_mirror.py` (see "Link
mirror test" below).

**Why last.** Nothing in this brief depends on link play, and the per-turn
check is cheap to add once the pipeline and abilities exist. It is plan step
G.

### 8. Optional rules are options, not NPCs; new mechanics live on their own branch

**Chosen.** Every Shin rule that an NPC or object used to toggle (wild and
trainer randomizers, trainer scaling, alternate trainer moves, catch-up EXP,
the caught icon, the five battle clauses and the Safari event) is a row on
the RULES page of the extra options menu
(`custom_functions/func_rules_menu.asm`). The NPCs that Shin added for them
are gone; the Oak's Lab girl and aides, which are in the original game, say
their original lines again; the Viridian house is back to its original size.
Each rule is still the same event flag, so the code that follows a rule did
not change. `SetDefaultNames` carries the rule flags across the event-flag wipe
so they can be set from the title screen before NEW GAME.

This branch stays the Gen 1 game plus Shin's optional rules, all off by
default. New mechanics (decisions 3, 5 and 6 and anything else that changes
how battles or the overworld work) go on a separate branch cut from here, so
this one remains a mechanically untouched base to compare against. Behaviour-
preserving refactors (plan steps E onward that change no behaviour) still
land here first.

The Shimmer (a cheat toggled by a glass Poké Ball in the rival's house) was
removed outright rather than made an option: it stored its hidden factor in
the catch-rate byte, which decision 6 reserves for the held item.

**Costs.** Wild randomization no longer offers re-rolling the seed mid-game;
the seed is the one chosen at NEW GAME. The Safari event is no longer locked
until after the Elite Four.

## Plan

Steps in order. Each names its verification; a step is done when that passes
and the budget table above is updated.

| Step | Work | Verification | Budget effect |
|---|---|---|---|
| A (done) | `hBattleSide` (decision 1): relocate the two side bytes to `$FFE2`, update the entry-point shims. Extend `compare_builds.py` to compare RAM by name across layout changes, ignoring names that only the old build has, so the comparison stays on for this commit | `compare_builds.py` identical on results and all shared RAM; `make test`; all eight variants build | WRAM 6 → 8, HRAM 5 → 4 |
| B (done) | Damage pipeline, structural (decision 3): merge `{Player,Enemy}CanExecuteMove` and `{Player,Enemy}CalcMoveDamage`, read the level via the side table, remove `SwapPlayerAndEnemyLevels`, install empty hook tables and the S3 stage with n = 16. First add a `tests/suites/` suite that drives the whole `CalcMoveDamage` path (today only `damage_vars` and `apply_attack` are covered) | New suite identical across the two builds, including random consumption; `make test` | 0 |
| C (done) | Merge `Check{Player,Enemy}StatusConditions` with 16 explicit side checks. First add a status-conditions suite (sleep, freeze, paralysis, confusion, flinch, Disable, Hyper Beam recharge) using `skip_delays()` and `auto_buttons()` | Suite identical across builds; `make test` | 0 (battle bank gains ~300 lines of room) |
| D (done) | Current box to save RAM (decision 2): accessor, own checksum, ~90 call sites in 15 files, day-care mon included | New spec tests for deposit, withdraw, catch with a full party, box change and checksum repair; existing suites still identical (battle does not touch the box); a save-and-reload run in the emulator | WRAM 8 → ~1130 |
| E (parts 1-4 done) | First mechanics, on the `claude/mechanics` branch (decision 8), one commit each with a spec test, in this order because each later one depends on the stats the earlier ones define: (1) Special split: Special Attack and Special Defense with Gen 2's base stats, separate DVs (decision 6), shared Special stat experience, a Special Defense stat stage, Gen 2's move effects (Amnesia, Growth, Psychic's side effect) and Light Screen on Special Defense; (2) physical/special split: a category per move (a table by move id, `GetMoveCategory`), read in S0; (3) natures (`CalcStats`), the 25 Gen 9 natures over the five stats, neutral for trainers' Pokémon, shown on the status screen; (4) abilities (an ability slot bit; the logic in bank 9, reached by far-call hooks in the battle engine); (5) held items (item byte, wild item table, `Mon1BCDScore` fix); (6) weather (map-and-time at battle start, S3 hook, one battle-only byte) | `tests/test_*.py` per mechanic; `compare_builds.py --suite` on every suite a mechanic should not affect | Special split: 53 WRAM bytes (a third DV byte and a sixth stat in every party and battle struct); natures 1; abilities 15; weather 1 planned |
| F | Day/night (decision 5): `GetTimeOfDay`, palette handling per hardware, three encounter tables per outdoor map, time evolutions. Then map regions (decision 4) when the first non-Kanto map is designed | Spec tests poke the clock and check phase, palette value and encounter table; an emulator run across a phase change | 0, then 2 bytes for regions |
| G | Link checks (decision 7): version byte, per-turn checksum, mirror test | Two harness instances linked by their serial ports, or a scripted exchange, showing the draw path on an injected mismatch | 0 |

**Step B as done, and where it differs from the row above.**

- `SwapPlayerAndEnemyLevels` is gone from the main enemy flow (seven of nine
  calls) with no behaviour change. The pair in the enemy's multi-hit loop was
  a bug and was removed in a separate fix: see "Bugs found by the refactor".
- `{Player,Enemy}CalcMoveDamage` are one `CalcMoveDamage`; it returns carry
  where the old code jumped to the fly/charge check.
- `{Player,Enemy}CanExecuteMove` stay separate. Only the player's spends PP
  and only the enemy's clears the disobedience flag, and both end with a tail
  jump to `JumpMoveEffect` that returns out of the whole turn, which a called
  shared routine would break. What they share is about a dozen lines.
- The S3 stage is a call to `ApplyDamageModifiers` in all three places damage
  is finalized (`CalcMoveDamage` and both multi-hit loops). It is an empty
  stub; the hook tables come with the first real modifier rather than as empty
  structures now.
- `tests/suites/move_execution.py` runs whole turns. It compares only `b`
  (the turn's only register result) and RAM; `compare_builds.py` treats
  `hBattleSide` as scratch (see its `SCRATCH` list).

**Step C as done.** `Check{Player,Enemy}StatusConditions` are one
`CheckStatusConditions` that takes the side in `hBattleSide`. Side-specific
addresses and continuation points come from two-entry tables through
`GetSideAddr`; the real differences (sleep text before or after the
animation, animation numbers, the Disable predef, the self-hit routine, the
enemy not clearing `INVULNERABLE`) are explicit side checks. The enemy's inline
self-hit code became `EnemyHandleSelfConfusionDamage`, unchanged; merging it
with `HandleSelfConfusionDamage` (which also redraws the player's HUD) is a
possible follow-up. `tests/suites/status_checks.py` covers it.

**Step D as done, and where it differs from decision 2.**

- The day-care mon (name, OT name, box struct) and the current box live in
  save RAM bank 0 after the Hall of Fame (`sLiveDataStart`-`sLiveDataEnd`,
  `$b858`-`$bcf0`). Every access sits between `OpenBox` and `CloseBox` in
  the home bank. They enable SRAM, select bank 0, nest (`wBoxOpenDepth`),
  preserve every register and flag, and disable SRAM at the outermost
  close. `GetNumInBox` reads the count. The test harness fails any call that
  returns with the box still open.
- **The box is still written at save time.** Decision 2 said it would not be,
  and that its checksum would be updated on every write. That would make box
  changes permanent without saving while party changes are not. A deposit
  followed by a reset would leave the mon in the saved party and in the live
  box. So saving copies the live data to a snapshot in bank 1
  (`sLiveDataSnapshot`) with its own checksum (`sLiveDataSnapshotCheckSum`).
  Loading checks that checksum and the main one before copying anything,
  then copies the snapshot back. The main checksum no longer covers the box.
  The live copy needs no checksum because every load rebuilds it.
- **Save RAM is never left enabled across a frame**, with two changes needed
  to keep that. `SendNewMonToBox` asks for the nickname into `wcd6d` before
  opening the box, and the texts that name the mon print it from there. The
  PC's list menu reads its list every frame, so it gets a 22-byte WRAM copy
  of the count and species (`wBoxListCopy`). It reads nicknames through
  brackets in the list-menu code. Picture decompression still leaves SRAM
  enabled, as it always has.
- Two preparatory commits: the boot RNG seed, written to the literal address
  `$def0` inside `wBlackoutSavedMapData`, got its own variable (`wRNGSeed`);
  and the unused `FarCopyData3` was removed from bank 0 to make room.
- **Verified:** every test in `tests/test_pc_boxes.py` passes, with only the
  readers and writers in `tests/boxes.py` changed. `tests/test_pc_menu.py` is
  new: it withdraws, deposits and releases through the PC's own menus and
  checks the name the list menu read from save RAM. `make test` passes and
  all eight ROMs build. `compare_builds.py` against the previous commit
  matches on every result. The only RAM difference is `wPredefRegisters+3`
  in nested predef calls. It records the address of `Predef.done`, which
  moved 12 bytes in bank 0.
- **Not verified:** the save-and-reload check is the game's own save and load
  routines run in the emulator by `SaveTest`, not a played session through
  the start menu. The Game Boy Printer's box printout builds but has no
  test, because the harness has no printer.

**Step E, part 1 as done: the special split** (`claude/mechanics` only).

- **Data.** Base stats gain special defense right after special, with Gen 2's
  special attack and special defense for all 151 (MissingNo. keeps 128 for
  both). HP, attack, defense and speed already matched Gen 2. The Gen 2 split
  is the official one: 43 species' special attack differs from their Gen 1
  special (Chansey 105 to 35, Charizard 85 to 109).
- **Layout.** The DVs are 3 bytes (`NUM_DVS`); the third's high nybble is the
  special defense DV and its low nybble is spare and always 0. The HP DV is
  unchanged (the low bits of the other four), and so are Gen 2's shiny and
  gender rules, which only read the first two bytes. Box structs are 34 bytes,
  party structs 47, battle structs 32. `NUM_STATS` is 6; `NUM_STAT_EXPS` is 5,
  because special attack and special defense share the special stat exp,
  which gains the defeated mon's base special attack, as in Gen 2.
- **Stat stages.** Special defense's stage is the seventh slot (`MOD_*` in
  `constants/battle_constants.asm`), after accuracy and evasion, so the
  original six keep their indices; `StatModToStat` maps a stage to its stat.
  The old Special effects now mean special attack (Growth, X Special, also in
  hard mode). Two new effects use free ids: `SPECIAL_DEFENSE_UP2_EFFECT` ($4E,
  Amnesia) and `SPECIAL_DEFENSE_DOWN_SIDE_EFFECT` ($48, Psychic), the latter
  in the slot Gen 1 already routed to the stat-down code.
- **Battle.** Special moves use the attacker's special attack against the
  defender's special defense, critical hits included; Light Screen doubles
  special defense. The Volcano Badge boosts both specials. The AI uses X
  Special like X Attack (it raises special attack only now), counts Amnesia
  among stat-up moves, and treats it like Light Screen against physical
  attackers.
- **DVs everywhere they are made.** Wild mons roll the special defense DV
  with the others (rerolled once below 4 in hard mode); normal-mode trainers'
  is 8; hard-mode and boss rolls keep their biases; gifts get at least 8; the
  Cinnabar Lab passes one parent's on whole; the M.Gene and Mist Stone handle
  it.
- **Display.** The status screen lists five stats in rows 8-17 without a box,
  as Gen 2 does, with a divider before the types box; holding START shows
  five DVs, SELECT the stat exp (special twice). The level-up box, the trade
  center's stats view and the printer page show five stats. Stat-change
  text says SPCL.ATK and SPCL.DEF; TM29's and the Cinnabar Lab book's text
  changed to match.
- **Hidden layout assumptions fixed on the way:** struct offsets written as
  numbers in the AI (`func_ai.asm`), the poison/burn max HP offset, the
  party size in `WakeUpEntireParty`, `MoveMon`'s offset back to stat exp, the
  link cable's party data length, and the stat-exp zeroing and DV skipping
  in `AddPartyMon` and when sending a caught mon to the box. The gamma
  setting's save address and the trainer card's badge graphics bank, also
  hard-coded, were fixed on the base branch first.
- **Verified:** `tests/test_special_split.py` checks the stat formula for all
  151 species against a model, the Gen 2 values, Amnesia, Growth and Psychic
  as whole turns, the Volcano Badge, stat exp gains and wild DVs. The other
  suites now take struct sizes and offsets from the symbols. In the emulator: a
  trainer battle with a level-up (the five-stat box, recalculated stats
  checked by hand), the status screen's three views, and save and continue.
- **Not verified:** link battles and trades between two copies (both sides
  run the same code and sizes come from the labels), the printer page (no
  printer in the harness).

**Step E, part 2 as done: the physical/special split** (`claude/mechanics`).

- **Where the category lives.** The plan said two spare bits of each move's
  type byte, but 47 places read a move's type, and every one would have had
  to mask them off. Instead `data/move_categories.asm` holds one byte per
  move (`PHYSICAL`, `SPECIAL` or `STATUS`), next to the moves, and
  `GetMoveCategory` (home bank) looks it up by move id, returning `STATUS`
  for ids that aren't moves (the X items' animation ids). The move data and
  everything that reads a type are unchanged.
- **Data.** Gen 4's categories for all 165 moves, from PokeAPI's move list,
  whose ids 1-165 are Gen 1's in the same order. 75 physical, 35 special,
  55 status. Moves whose category differs from what their Gen 1 type gave
  them include Crabhammer, Waterfall, the elemental punches, Razor Leaf and
  Vine Whip (now physical) and Gust, Tri Attack, Swift and Hyper Beam (now
  special).
- **Readers.** `GetDamageVars` (stage S0) and the four AI checks that asked
  "is this move special?" by type now ask by category. Counter strikes back at
  physical moves whatever their type, as from Gen 2 (it was Normal and
  Fighting moves), and the AI's Counter check agrees; tested in
  `tests/test_move_categories.py`.
- **Home bank.** It was full; `RefreshPartyMenu` and the clause-check
  wrapper, each used from at most two banks, moved out to make room.
- **Move menu.** The line that said "TYPE/" now shows the selected move's
  category (PHYS, SPCL or STAT) on the left and its effectiveness against
  the enemy on the right: ▴▴ 4x, ▴ 2x, nothing 1x, ▼ 1/2x, ▼▼ 1/4x, × no
  effect, from the same calculation the AI uses. Status moves get no mark;
  fixed-damage moves only show ×. There is no mark against a ghost the
  Silph Scope hasn't identified, so the marks can't hint at what it is. ▴ is
  a new font tile at $E9, ▼ upside
  down, in a slot the font had left unused. `tests/test_move_menu_marks.py`
  checks every mark; in the emulator, a battle's move menu showed each case.
- **Verified:** `tests/test_move_categories.py` checks `GetMoveCategory`
  against the table for all 256 ids and that crossover moves use their
  category's stats; the damage-stat model in `tests/test_damage_vars.py`
  decides special by category, over random real moves.

**Step E, part 3 as done: natures** (`claude/mechanics`).

- **From the DVs.** A mon's nature is its three DV bytes read as one number
  (without the spare low nybble, which stays free for the ability slot), plus
  `NATURE_OFFSET`, mod 25, in Gen 3's order: nature = 5 x raised + lowered,
  counting attack, defense, speed, special attack, special defense, which is
  also the order of the stats here. The offset makes the fixed DVs of
  trainers' Pokemon outside hard mode (`TRAINER_DVS_*`) come out HARDY, so
  those are neutral with no special case; hard mode's random trainer DVs
  give varied natures. Changing a mon's DVs (M.Gene, the Cinnabar Lab)
  changes its nature with them.
- **Effect.** `_CalcStat` looks the nature up (`GetNatureFromDVs`, kept in
  wCalcStatNature) and scales the finished stat by 110/100 or 90/100 before
  the 999 cap, as from Gen 3, so every path that computes stats gets it. One
  WRAM byte.
- **Display.** The status screen shows the nature's name under the HP and
  marks the raised and lowered stats with ▴ and ▼ beside their values. Bank
  4 had 30 bytes, so the code and names live in bank 9 beside `_CalcStat`,
  and the status screen far-calls them.
- **Verified:** `tests/test_natures.py` checks the lookup against a model,
  trainer DVs giving HARDY, the spare nybble not counting, all 25 natures'
  stats for Mewtwo against the formula without a nature, and the status
  screen's name and marks for each; the all-species stat test includes
  natures. In the emulator: the status screen for an Adamant and a Quirky
  Chansey.

**Step E, part 4 as begun: abilities, the infrastructure** (`claude/mechanics`).

- **Which abilities.** Each species gets Gen 9's two non-hidden abilities
  (PokeAPI's data; a species with one has it twice), 68 distinct abilities
  in all. The ten that need something the game doesn't have yet are left
  empty (NO_ABILITY) in the species table, not cut from it, so they slot in
  later: Chlorophyll, Swift Swim, Sand Veil, Cloud Nine, Leaf Guard and
  Hydration (weather), Sticky Hold and Pickup (held items), Cute Charm
  (infatuation) and Magnet Pull (the Steel type). Oddish's, Bellsprout's,
  Exeggcute's, Tangela's, Sandshrew's and Magikarp's lines have no ability
  for now; Clefairy, Grimer and a dozen others have one of their two.
  `constants/ability_constants.asm`, `data/mon_abilities.asm` and
  `data/ability_names.asm` are generated from PokeAPI's CSVs; names are
  at most 12 characters, Gen 3 style (LIGHTNINGROD, COMPOUNDEYES,
  NEUTRAL. GAS).
- **The slot.** Bit 0 of the third DV byte, which natures and stats ignore.
  `Random_DV` and `Random_BiasDV` roll it with one more random number (so
  every wild, gift and hard-mode trainer mon takes one extra roll), the
  forced-shiny path keeps it, and trainers' fixed DVs ($80) give slot 0.
  The M.Gene rerolls it with the rest of the DVs.
- **In battle.** `wPlayerAbility` and `wEnemyAbility` are set when each mon
  is sent out (`LoadBattleMonFromParty`, `LoadEnemyMonData`, and the link
  path `LoadEnemyMonFromParty`). Hooks read them through `GetSideAbility`,
  `UserAbility`, `TargetAbility` and `TargetAbilityForMove` in bank $0F:
  Neutralizing Gas stops every ability but itself while it is out, and the
  "for move" variant also returns none when the user has Mold Breaker.
  Abilities that react after a hit lands (Static and the like) use
  `TargetAbility`, since Mold Breaker doesn't stop them; each hook picks
  its variant, so no breakable-ability table is needed. Transform copying
  the ability and Trace come with the entry abilities.
- **Display.** Page 2 of the status screen shows the ability under the pic,
  beside the dex number. Page 1 had no room for a 12-character name.
- **Space.** The table, names and lookups (1182 bytes) live in bank 9 beside
  natures; the first try left them floating and the linker put them in bank
  3, taking all its free space.
- **Verified:** `tests/test_abilities.py` checks the lookup for every species
  and slot, spot checks against Gen 9's abilities, the names, the slot bit
  from each generator, the send-out hooks for the player, a link enemy and
  a trainer, Neutralizing Gas and Mold Breaker, and the status screen. In the
  emulator: a trainer battle's Rattatas (the player's with slot 1 had Guts,
  the trainer's Run Away) and page 2 of a Chansey's status screen.

**Step E, part 4 continued: abilities that stop moves or change damage.**

- **Stopping a move.** `AbilityBlocksMove` runs once a move is announced
  (after "used ...!" and PP), before anything else the move does, which is
  Gen 5's place: after the check for a target in the air or underground,
  before accuracy. It returns carry and the move ends, as a miss would.
  Levitate takes Ground attacks; Volt Absorb, Water Absorb and Dry Skin heal
  1/4 of max HP from Electric, Water and Water moves; Lightning Rod raises
  Special Attack a stage from Electric moves; Flash Fire takes Fire moves and
  powers up its own; Soundproof takes Growl, Roar, Sing, Supersonic and
  Screech. Type-based ones take damaging moves and Thunder Wave, the only
  status move of those types that targets the foe (so Water Absorb leaves
  Withdraw alone). The messages are "<mon>'s <ABILITY>!" followed by the
  outcome ("It doesn't affect ...", "... regained health!", "...'s
  SPCL.ATK rose!", "...'s FIRE moves powered up!"). All of these are
  ignored by Mold Breaker.
- **Damage (S3).** `ApplyDamageModifiers`, the stage the refactor left
  empty, now far-calls `AbilityDamageModifiers`: each applicable ability
  scales the damage by a ratio (damage x n / d, at least 1, at most
  $ffff), the user's first, then the target's. User: Technician (power 60
  or less, x3/2), Iron Fist (punches, x6/5), Reckless (recoil and crash
  moves, not Struggle, x6/5), Adaptability (x4/3 on top of the same-type
  bonus, making it 2), Tinted Lens (not very effective, x2), Sniper
  (critical hits, x3/2), Guts (physical moves with a status condition,
  x3/2, and x2 more when burned, undoing burn's halving except on critical
  hits, which use stats from before the burn), Overgrow, Blaze, Torrent and
  Swarm (their type at 1/3 HP or less, x3/2) and an active Flash Fire
  (Fire, x3/2). Target: Thick Fat (Fire and Ice, x1/2), Filter (super
  effective, x3/4) and Dry Skin (Fire, x5/4). Fixed-damage moves are left
  alone. Gen 9 applies some of these to power or stats instead; the
  difference is rounding.
- **Scrappy (S2).** Before effectiveness, a Ghost type of the defender
  counts as its other type (or as Fire, neutral to both, for a pure Ghost)
  against a Scrappy user's Normal and Fighting moves.
- **Stat stages.** `ChangeStatStage` raises or lowers any stage and
  recalculates the stat the way stat moves do, with the player's badge
  boost reapplied to that stat; Lightning Rod is its first user, and the
  entry abilities (Intimidate, Download) will use it.
- **Move flags.** `data/move_flags.asm` gives each move Gen 9's contact,
  punch and sound flags (generated with the ability data).
- **Not yet.** The trainer AI doesn't know about abilities, and the move
  menu's effectiveness marks stay type-only (they shouldn't reveal the
  foe's ability anyway). Transform copying the ability comes with Trace.
- **Verified (part 2):** `tests/test_ability_damage.py` checks each damage ability
  and its conditions on both sides, Mold Breaker and Neutralizing Gas,
  rounding and the cap; each blocking ability on both sides (healing,
  capping at max HP, the +6 limit, Flash Fire's flag) and what gets
  through (an airborne target, Mold Breaker, other types); a whole turn of
  Earthquake into Levitate; and Scrappy against Ghost and Ghost/Poison. In
  the emulator: a trainer battle where Thunderbolt hit Volt Absorb and
  Earthquake hit Levitate, with the messages above.

**Step E, part 4 continued: abilities that protect, and accuracy and HP.**

- **Status moves.** The move gate also stops status moves whose effect the
  target's ability keeps off: Insomnia and Vital Spirit (sleep), Immunity
  (poison), Limber (paralysis), Own Tempo (confusion), Clear Body (any stat
  drop), Hyper Cutter (attack drops), Keen Eye and Illuminate (accuracy
  drops), with "<mon>'s <ABILITY>!" and "It doesn't affect ...". Gen 9
  checks these after accuracy, so a status move that would have missed shows
  the ability instead of "missed"; the difference is the message. Rest fails
  under Insomnia and Vital Spirit.
- **Side effects.** Every side-effect roll (burn, freeze, paralysis, poison,
  flinch, confusion, stat drops) now goes through `RollSideEffect`, which
  lets `AbilitySideEffectChance` change the chance before the one random
  number is drawn, so randomness is consumed as before: none past Shield
  Dust or an ability that keeps the effect off (the ones above, plus Water
  Veil for burns and Inner Focus for flinching), twice the chance with
  Serene Grace. `GetEffectKind` maps a move effect to what it does, for both
  the gate and the rolls.
- **Damp** on either mon stops Explosion and Self-Destruct before they go
  off ("<mon> can't use EXPLOSION!"); the user doesn't faint. **Sturdy**
  stops one-hit KO moves and, at full HP, survives a foe's hit that would
  knock it out with 1 HP ("... endured the hit!", printed after the move by
  `AbilityAfterMove`). Not its own recoil, crash or confusion damage.
- **Accuracy.** `CalcHitChance` moved to bank 9 as `CalcHitChance_` (bank
  $0F keeps an 8-byte stub, a net gain of 60 bytes there) and gained:
  Keen Eye and Illuminate ignore the target's raised evasion, Compound Eyes
  x13/10, Tangled Feet halves accuracy against its confused holder, and No
  Guard on either mon sets the hit chance to 255, which the fork's roll
  never misses; No Guard also hits a target in the air or underground.
- **Critical hits.** Battle Armor and Shell Armor stop them, in the
  critical-hit-rate predef. **Skill Link** makes two-to-five-hit moves hit
  five times (without the rolls).
- **HP.** Magic Guard: no damage from poison, burn, Leech Seed, recoil or
  Jump Kick's crash. Rock Head: no recoil, except Struggle's. Liquid Ooze:
  drain moves and Leech Seed hurt the drainer by what it would have healed
  ("... sucked up the ooze!"). `HealMon` and `HurtMon` change any mon's HP
  with the HP bar animation.
- **After the move.** `AbilityAfterMove` runs after each mon's move (a
  wrapper around `ExecutePlayerMove` and `ExecuteEnemyMove` in the turn
  loop), for what abilities do once a move is over; Sturdy's message is its
  first user.
- **A bug class found.** `cp X` / `ret nz` returns with carry set whenever
  the ability's id is below X, so routines whose carry is their answer must
  clear it (`and a`) on the "no" path; two did not, and the tests caught it.
- **Verified:** `tests/test_ability_protection.py` checks the gate for every
  protected status move and what still gets through (side effects aren't
  blocked whole, Mold Breaker, Neutralizing Gas), Damp both ways, Sturdy
  against one-hit KOs; each side-effect immunity, Shield Dust, Serene Grace
  and the cap, and that a roll still draws one random number and preserves
  registers; the moved accuracy calculation against Gen 1's formula over
  random stages, and each accuracy ability; No Guard through Fly; Sturdy's
  endurance (and not at 199/200, not against Mold Breaker, not for its own
  crash); Magic Guard, Liquid Ooze, Rock Head and Struggle; Skill Link;
  armor against a guaranteed critical hit; and Rest under Insomnia. In the
  emulator: a foe's Sturdy holding at 1 HP against a 999-Attack Tackle,
  with its messages.

**Step E, part 4 continued: abilities that react, and turn and switch
abilities.**

- **The snapshot.** When a move starts (the move gate), the target's HP,
  status and stat stages are saved; `AbilityAfterMove` compares them with
  what the move left, so one hook after the move serves every ability that
  reacts to "was hit", "was statused" or "had a stat lowered", whatever
  code path the move took. Nothing happens to a target that fainted.
- **Reactions.** Anger Point: a critical hit maxes its Attack. Cursed Body:
  a 30% chance to disable the move that hit it for 4 turns. Synchronize: a
  foe that burns, poisons (badly, for Toxic) or paralyzes it gets the same,
  unless its type (Gen 9's: Fire, Poison, Electric) or ability keeps it
  off, with the stat penalty. Competitive: any stat lowered by a foe's move
  (not Haze) raises its Special Attack two stages. Stench: a 10% chance of
  flinching for damaging moves without a flinch effect, past Inner Focus and
  Shield Dust.
- **Each turn**, with the residual damage: Shed Skin, a 1/3 chance to shed
  its status (before poison or burn hurts it), undoing burn's and
  paralysis's stat penalties; Early Bird takes a second turn off its sleep
  count, never the last.
- **Switching out**: Natural Cure cures its status, for the player's and a
  trainer's mon. (Not at the end of a battle: that code is in bank 4, which
  has 1 byte.)
- **Pressure**: a move aimed at its holder (`MoveTargetsFoe`: damaging
  moves, status moves that do something to the target, Leech Seed, Disable,
  Mimic, Transform, Roar, Whirlwind) costs one more PP, for both sides.
- **Randomness.** `AbilityRandom` is `BattleRandom` in bank 9 (a far call
  can't return a value in a), drawing from the shared list in link battles,
  so both games stay in step.
- **Stat stages.** `ChangeStatStage` now keeps burn's and paralysis's
  penalties on the recalculated stat, as the fork's stat moves do.
- **Two register bugs** caught by the tests: `PrintText` clobbers `de`, so
  values in `d` or `e` must be saved or reloaded across a message.
- **Verified:** `tests/test_ability_reactions.py` checks each reaction on
  both sides, including the random thresholds, the types and abilities that
  stop Synchronize, Toxic passed on as bad poison, Haze not counting for
  Competitive, and that nothing happens without a move; Shed Skin's chance
  and its timing before poison damage; Early Bird's count; Natural Cure;
  Pressure for damaging, status and self-targeting moves and at 0 PP; and
  the stat penalties. `harness.clear_random()` lets a test replace the
  queued random numbers mid-test. In the emulator: Thunder Wave into a
  Synchronize foe paralyzed the user back, with its messages.

**Step E, part 4 done: entry, contact and field abilities.**

- **Entry.** Sending a mon out sets a pending flag for its side;
  `EntryAbilities` runs the pending ones at the start of each turn and just
  before each move (so a mon switched in mid-turn acts before the foe's
  move), the faster first, once both mons are out. Intimidate: the foe's
  Attack falls a stage, unless it's behind a substitute or mist, or its
  ability stops it (Gen 9: Hyper Cutter, Clear Body, Oblivious, Inner
  Focus, Own Tempo, Scrappy); Competitive answers it. Download: Attack up
  if the foe's Defense is the lower, else Special Attack. Trace copies the
  foe's ability (not Trace or none), which then acts as if it had just come
  in. Forewarn names the foe's strongest move (one-hit KOs as 150, Counter
  120, other fixed damage 80). Pressure, Mold Breaker and Neutralizing Gas
  announce themselves. Neutralizing Gas keeps the foe's from acting.
- **Contact.** Static, Poison Point, Flame Body (30%) and Effect Spore (11%
  sleep, 9% poison, 10% paralysis; Grass types are immune) act through
  `AbilityAfterMove` when a move with Gen 9's contact flag hit for damage.
  `GiveUserStatus`, shared with Synchronize, applies Gen 9's type
  immunities, the attacker's own ability, and the stat penalties. Effect
  Spore's sleep ignores the sleep clause option.
- **Field.** Arena Trap keeps the foe from fleeing or switching (player:
  "Can't escape!" from RUN and the party menu; trainer AI: no switch,
  so it uses a move) unless it's a Flying or Ghost type or has Levitate; not
  in link battles, where each side's game decides for its own player. Run
  Away always gets away from wild battles.
- **Rivalry**: x5/4 against the same gender, x3/4 against the other, from
  the fork's `DetermineMonGender` (species and Attack DV). **Transform**
  copies the target's ability, as from Gen 3.
- **Still not done**: the trainer AI ignores abilities when choosing moves
  and switches, and the move menu's marks ignore them by design.
- **Verified:** `tests/test_ability_entry.py` checks Intimidate both ways
  and everything that stops it, Competitive's answer, both sides entering
  in speed order and only pending sides acting, Download's comparison
  (including ties and 255 against 256), Trace and what it can't copy,
  Forewarn's powers, the announcements changing nothing; each contact
  ability's chance, Effect Spore's bands, immunities by type and ability,
  and nothing without damage; Arena Trap's exceptions and Run Away; Rivalry
  for single-gender, genderless and DV-gendered species; Transform. In the
  emulator: a foe's Intimidate acting just before its move, with its
  messages.

**Link mirror test** (`tests/test_link_mirror.py`). Two emulator instances
run the same mon's move in a link battle: one as the player's move, the
other, with every player/enemy pair of battle state swapped, as the enemy's.
Both draw from the shared random list, and `Random` itself is trapped, since
a link battle must never call it. Afterwards the random list, its index and
the mirrored battle state must match (PP aside: the player spends it when
moving, the enemy when choosing; and the party copies aside: each game
copies only its own player's HP back to its party). 80 random turns with
random abilities, plus 96 targeted ones where Static, Effect Spore, Cursed
Body, Poison Point, Stench, Serene Grace, Shed Skin and Shield Dust get to
roll, all agree. Checked that it bites: with one game's `AbilityRandom`
drawing from `Random` instead, 39 of the 96 targeted turns fail.

**Step E, part 5 begun: held items, the items and holding them.**

- **The set** (your choice: Gen 2's plus later staples): 15 type boosters
  (Gen 2's names, no Dark or Steel), Gen 2's ten berries plus the Sitrus
  Berry, Leftovers, Quick Claw, King's Rock, Scope Lens, BrightPowder, Focus
  Band, Light Ball, Thick Club, Metal Powder, Lucky Egg, Amulet Coin,
  Everstone, Exp. Share, Smoke Ball, Cleanse Tag, Stick, Lucky Punch, and
  Choice Band, Specs and Scarf, Life Orb, Eviolite and Focus Sash: 49 new
  item ids, `$62`-`$92` (`FIRST_HELD_ITEM`), after the elevator floors.
  Names, prices and key-item bits are extended to match; the key-item
  lookup copied a fixed 15 bytes of its bitfield and now copies what the ids
  need.
- **Holding.** The catch-rate byte is the held item (decision 6). Using a
  held item from the bag gives it to a party mon (not in battle); one it was
  holding goes back in the bag, unless the bag is full. A mon holding an item
  gets TAKE on its party-menu list, as a field-move-like entry. Page 2 of the
  status screen names the item under the mon's name. New party mons hold
  nothing (it used to copy the species' catch rate); a caught wild mon keeps
  its battle struct's byte; a trainer's mon's battle struct takes its party
  data's item (`GetEnemyHeldItem`); Transform copies everything in that
  block but the item, as in Gen 9. Items do nothing in battle yet.
- **Conflicts resolved.** `Mon1BCDScore` mode 1 reads the species' catch
  rate from its base stats. Nuzlocke mode marked dead mons by writing a value
  into that byte; the mark is now bit 1 of the third DV byte (natures, stats
  and the ability slot ignore it), and the M.Gene's reroll keeps it.
- **Space.** Bank 1 couldn't take the longer name and price tables, so both
  moved to bank 9 (every reader uses `BANK(...)`); the DV generators
  (`engine/random.asm`, reached only by far calls) moved from bank 4 to bank
  9 to make room for TAKE and the status-screen line.
- **Harness.** `menu_choices` now patches `HandleMenuInput_`, which the party
  menu calls directly, so tests can pick a party mon.
- **Verified:** `tests/test_held_items.py` checks ids, names, prices and
  key-item bits; giving, swapping, giving in battle (refused), TAKE and TAKE
  with a full bag, TAKE on the menu only when holding; the enemy's item for
  trainer and wild battles, new mons holding nothing, Transform keeping the
  user's item, the status-screen line; and the Nuzlocke mark. In the
  emulator: TAKE on the party menu and LEFTOVERS on the status screen.

Every ability the 151 species have that works without weather, held items,
infatuation or the Steel type now does what it does in Gen 9 (with the
differences noted above); the ten that need those are empty slots in
`data/mon_abilities.asm` until they exist.

Steps A to D, the refactors, are done, and each compared identical apart
from the differences recorded above. Steps E to G are the new behaviour.
WRAM no longer gates them. Bank 3's 3 free bytes may.

## Bugs found by the refactor

Refactors must not change behaviour, so bugs they uncover are recorded here
and fixed in their own commit, with a spec test, once approved. Bugs that also
exist upstream are written up for Shin Pokémon in `docs/upstream_bug_reports.md`.

- **Fixed: enemy multi-hit moves used the player's level after the first
  hit.** A leftover `SwapPlayerAndEnemyLevels` pair in the enemy's multi-hit
  loop. Test: `tests/test_multi_hit.py`. Recommended upstream.
- **Fixed: an enemy fully paralyzed or hurt by confusion mid-Fly or
  mid-Dig stayed invulnerable.** The status check cleared `INVULNERABLE` for
  the player's mon only, so every move missed the enemy until it completed a
  Fly or Dig or switched out. Both sides now use the same mask. Test:
  `tests/test_invulnerability.py`. Recommended upstream.
- **Fixed: accuracy and evasion changes re-applied every badge boost.**
  After a stat stage changes, only that stat is recalculated, so Shin
  re-applies only its badge boost (`wUnusedD71B`); for accuracy and evasion,
  which have no stat, it re-applied all of them. Each Double Team or
  Minimize by the player, or Sand-Attack or Smokescreen against it, raised the
  player's other stats by another 12.5%. Now nothing is re-applied in that
  case. Test: `tests/test_badge_boosts.py`. Against the previous build it
  changed 9 of 600 random whole turns, all of them the player's evasion
  rising or its accuracy falling. Recommended upstream.

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
- The play-time clock does not stop at 255 hours in this fork: hours carry
  into `wPlayTimeMaxed` and only bit 7 of that byte stops the count.
- `$FF9E` is not free HRAM: `H_SAVEDNUMTOPRINT` at `$FF9C` is three bytes.
- The main save checksum covers `sPlayerName` through the byte before
  `sMainDataCheckSum`. Since step D that excludes the box and the day care.
  Their snapshot in bank 1 has its own checksum, and loading fails if either
  checksum is wrong.
- The current box and the day-care mon are in save RAM bank 0. Read them
  only between `OpenBox` and `CloseBox`. Never hold the box open across a
  save, a load, a box change or the naming screen, because those select
  other banks or disable SRAM, or run for many frames.
- The list menu tells a party list from a box list by the low byte of the
  list's address alone; `wram.asm` asserts that `wBoxListCopy` differs from
  `wPartyCount` there.
