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
| ROM bank 0 (always loaded) | 16 KB | 246 bytes | Shared helpers must live here to be callable from every bank cheaply. Step D's accessors took 55 bytes, after removing the unused `FarCopyData3` (30). Moving the marts' item lists to bank `$34` (held items, part 5) freed about 150 more. The fixed "Home" section at `$61` is full |
| ROM bank 3 | 16 KB | 1230 bytes | Holds the item, catching, `MoveMon`, status-screen and day-care code. Moving `DrawBadges` and its badge graphics out freed 1261; the special split took 34 |
| Battle engine bank ($0F) | 16 KB | 98 bytes | Was 21 before the merges started; the special split took 59, the physical/special split, move-menu marks and Counter most of the rest. Abilities live in bank 9 and cost bank $0F only their far-call hooks; moving `CalcHitChance` to bank 9 paid for most of part 3's |
| WRAM | 8 KB | **1086 bytes** (end of WRAM to `$deff`) | Step D moved the current box and the day-care mon to save RAM, freeing 1177 bytes; the special split took 53 (a third DV byte and a sixth stat in every party and battle struct), natures 1, abilities 15 (each side's ability in battle, a flags byte, a side effect's chance as abilities change it, and an 11-byte snapshot of the target before each move); held items 5 (each side's Choice lock, what a Focus item saved, 2 scratch bytes); the Gen 9 pass's IVs and EVs gave back 3 more than their scratch bytes took (now **1086** free). Still allocate new state through this table |
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

### 5. Day/night: a 24-minute play-time day, computed on demand, no clock hardware (dropped)

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
the caught icon, the battle clauses and the Safari event) is an option on
the OPTION screen (`engine/menu/options.asm`; see "The OPTION screen"
below). The NPCs that Shin added for them
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
| E (done; part 6 dropped) | First mechanics, on the `claude/mechanics` branch (decision 8), one commit each with a spec test, in this order because each later one depends on the stats the earlier ones define: (1) Special split: Special Attack and Special Defense with Gen 2's base stats, separate DVs (decision 6), shared Special stat experience, a Special Defense stat stage, Gen 2's move effects (Amnesia, Growth, Psychic's side effect) and Light Screen on Special Defense; (2) physical/special split: a category per move (a table by move id, `GetMoveCategory`), read in S0; (3) natures (`CalcStats`), the 25 Gen 9 natures over the five stats, neutral for trainers' Pokémon, shown on the status screen; (4) abilities (an ability slot bit; the logic in bank 9, reached by far-call hooks in the battle engine); (5) held items (item byte, wild item table, `Mon1BCDScore` fix); (6) weather (map-and-time at battle start, S3 hook, one battle-only byte): **dropped**, with step F, see below | `tests/test_*.py` per mechanic; `compare_builds.py --suite` on every suite a mechanic should not affect | Special split: 53 WRAM bytes (a third DV byte and a sixth stat in every party and battle struct); natures 1; abilities 15; held items 5; weather dropped |
| F (day/night dropped; regions remain) | Day/night (decision 5): `GetTimeOfDay`, palette handling per hardware, three encounter tables per outdoor map, time evolutions. Then map regions (decision 4) when the first non-Kanto map is designed | Spec tests poke the clock and check phase, palette value and encounter table; an emulator run across a phase change | 0, then 2 bytes for regions |
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
  Hydration (weather), Sticky Hold and Pickup (held items; both added since), Cute Charm
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
- **Not yet.** The trainer AI doesn't know about abilities (it does since
  held items), and the move menu's effectiveness marks stay type-only (they shouldn't reveal the
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
  and switches (done after held items), and the move menu's marks ignore
  them by design.
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

**Step E, part 5 continued: held items in battle.**

- **A bank of their own.** Bank 9 was down to 1.5 KB, so the ability and
  held-item code moved, with the item names and prices, to an empty bank,
  `$34` (the ROM was already padded to 1 MB). All callers reach it through
  far calls with `BANK(...)`, so nothing else changed; bank 9 has 10 KB again.
- **Damage (S3, with the abilities').** The 15 type boosters x6/5 (Gen 9's
  20%, not Gen 2's 10%: the mechanics are Gen 9's throughout, the item set
  Gen 2's), Choice Band (physical) and Choice Specs (special) x3/2, Life Orb
  x13/10, Light Ball (Pikachu) x2, Thick Club (Cubone, Marowak, physical) x2;
  the target's Eviolite x2/3 if it has an evolution (read from the evolution
  table), Metal Powder (an untransformed Ditto, physical) x1/2. Gen 9
  scales the stats for most of these; the difference is rounding.
- **Critical hits** (the rate predef): Scope Lens x2, the Stick (Farfetch'd)
  and Lucky Punch (Chansey) x4, capped at 255; armor still stops them.
  **BrightPowder**: x9/10 accuracy against its holder.
- **Focus Sash** (full HP, used up) and **Focus Band** (10%) survive a
  foe's knockout with 1 HP, after Sturdy, with "... hung on using its ...!".
- **Turn order.** Within the same priority, a Quick Claw that goes off (20%)
  for one side only moves it first; otherwise speeds decide, with a Choice
  Scarf's x3/2. In a link battle both games roll the claws in the same order
  (the internal-clock game rolls its enemy's first, as the game's own speed
  tie does).
- **Choice lock.** After moving, a Choice item's holder is locked into that
  move until it switches out: the move menu refuses the others ("Its CHOICE
  item allows only ...!") and the AI won't pick them, unless the locked move
  is out of PP (Gen 9 would Struggle; here the others become usable).
- **After a move**: Life Orb costs 1/10 of max HP after a hit (even a
  knockout; not with Magic Guard); King's Rock is Stench's 10% flinch (they
  don't add up); a MysteryBerry gives 5 PP back to a move that ran out; then
  both mons check their berries. **Each turn**, before residual damage:
  Leftovers (1/16 of max HP), then berries.
- **Berries**: Berry +10 HP, Gold Berry +30, Sitrus Berry +1/4 of max HP, at
  half HP or less; PrzCureBerry, Mint Berry, PsnCureBerry, Ice Berry, Burnt
  Berry for their status (undoing its stat penalty), Bitter Berry for
  confusion, MiracleBerry for any status, or else confusion. A used item is
  gone from the battle struct and the party data (the player's, or a
  trainer's roster). Smoke Ball always gets away from a wild battle.
- **Test suites** now zero the held item in the battle structs they
  randomize, as they do abilities.
- **Verified:** `tests/test_held_item_battle.py` checks each damage item on
  both sides and its conditions, the crit rates and armor, BrightPowder,
  Focus Sash (used up, also from a trainer's roster) and Focus Band at their
  thresholds, Quick Claw and its link roll order, Choice Scarf and ties, the
  Choice lock (set after the move, the menu, the AI, cleared on send-out),
  Life Orb, King's Rock, MysteryBerry (with the party's PP), every berry
  including thresholds and fainted holders, Leftovers, and Smoke Ball. The
  link mirror test gained Focus Band, King's Rock, Life Orb, Sitrus Berry,
  Berry and Choice Band cases. In the emulator: Leftovers restoring HP with
  its messages.
- **Outside the moves**: Lucky Egg gives x1.5 experience (on top of a
  traded mon's x1.5); Exp. Share makes its holder count as having fought,
  so it shares the experience and stat experience like a participant (Gen
  2 gave it half; this keeps the fork's experience code as it is); Amulet
  Coin doubles a trainer's prize money when any party mon holds one (Gen 2
  required the holder to have fought); Everstone stops level-up evolution
  (stones still work, as in Gen 2); Cleanse Tag on the first party mon cuts
  the wild encounter rate by a third. Verified in
  `tests/test_held_item_field.py`, except Cleanse Tag, whose roll needs a
  whole map; the Everstone test checks that the evolution starts without it
  (the harness can't run the evolution scene to the end).

**Step E, part 5 done: where held items come from** (your choice: all four
sources).

- **Wild mons** hold their species' common item 23% of the time and its rare
  one 2% (Gen 2's rates), from `data/wild_held_items.asm`: FireRed and
  LeafGreen's lists, with Gen 3 berries under their Gen 2 names, plus a few
  Gen 2 touches (Pikachu's Light Ball, Snorlax's Leftovers, Chansey's Lucky
  Punch and Lucky Egg). The roll is made when the wild mon is loaded, so a
  caught mon keeps what it held.
- **Trainers**: each gym leader's ace, the Elite Four's and the champion's
  (and a few of their other mons) hold items, from
  `data/trainer_held_items.asm`, applied after the party is read.
- **Marts.** Celadon's 4F sells the type boosters (with 5F's first clerk),
  2F's first clerk and Saffron sell berries, Pewter and Cerulean the Berry
  (and Cerulean the PrzCureBerry). The mart lists are texts read from the
  map's bank, so they had to live in bank 0, which had 98 bytes free; they
  now live in bank `$34` (`data/mart_lists.asm`), and each mart's text keeps
  only `$FE` and the list's index, which `DisplayPokemartDialogue` hands to
  `LoadMartInventory`. That freed bank 0 instead of costing it. The longest
  list (14 items) exactly fills `wItemList`.
- **Field items**: 18 Poké Balls lying around now hold a held item instead
  of a common one (for example a Quick Claw in Viridian Forest, Leftovers on
  Route 12 instead of an Iron, a Choice Band in Victory Road).
- **Verified:** `tests/test_held_item_sources.py` checks the wild rolls at
  their thresholds (and that species without items roll nothing), the
  table's species and items, trainers' items through `ReadTrainer` (leaders,
  the champion's three teams, an ordinary trainer holding nothing), every
  mart list loading through its index, the lists fitting the buffer, and
  that at least 15 field items are held items.

Held items (step E, part 5) are done.

**The trainer AI knows abilities.**

- **One answer.** The battle's gate, `AbilityBlocksMove`, is split: its
  decision is `MoveBlockedByAbility`, which prints and changes nothing and
  returns what the battle does about the move, and the gate takes the
  snapshot, applies Pressure and jumps there. The AI asks the same routine
  (`AIEnemyMoveBlocked`, `AIPlayerMoveBlocked`, in bank `$34`), so the AI
  and the battle can't disagree: Damp on either mon, Soundproof, Sturdy
  against one-hit KO moves, Levitate and the absorbing abilities, and the
  status and stat-drop protections, with Mold Breaker and Neutralizing Gas.
- **Choosing moves.** Layer 3, the one that already weighs typing, gives a
  move the player's mon's ability stops the same 5 points it gives a type
  immunity. Like the typing check, it is skipped on the turn the player
  switches in (the AI doesn't know the new mon yet).
- **Switching.** Layer 4 no longer switches out to flee a super-effective
  move this mon's ability stops (a Levitating mon facing Earthquake).
- **Verified:** `tests/test_ai_abilities.py` checks the AI's answer against
  the gate's in 300 random cases, either side's move, half of them moves
  the abilities stop; a STAB move picked without the ability and dropped
  with it, for each type-blocking ability; the 5 points for status moves;
  moves that still work scoring the same; the enemy's Mold Breaker seeing
  through. Layer 4's use is covered by the agreement test only (its switch
  rolls need a whole party).

**Two more abilities, now that held items exist.** **Pickup** (Meowth):
after a battle other than a link battle, each party mon with it that holds
nothing picks up an item 10% of the time, without a message, from Gen 3's
list and odds (Super Potion 30%; Full Heal, Ultra Ball, Rare Candy, Full
Restore, Revive and Nugget 10% each; Protein 5%, PP Up 3%, King's Rock 1%).
**Sticky Hold** (Grimer, Muk) is in their slot and does nothing: no move
here takes or swaps items. `tools/gen_abilities.py` no longer leaves them
out; the ability ids after them moved up. Verified in
`tests/test_held_item_field.py` (the 10% roll, each item's threshold, who
picks up) and `tests/test_abilities.py` (the species' slots).

Every ability the 151 species have that works without weather,
infatuation or the Steel type now does what it does in Gen 9 (with the
differences noted above); the eight that need those are empty slots in
`data/mon_abilities.asm` until they exist.

**Weather and day/night are dropped** (your decision). The Game Boy has no
elegant way to show either, and no Kanto Pokémon relies on them: they would
make six abilities matter and nothing else. So step E's part 6 and step F's
day/night won't be built (its map regions, decision 4, remain). Decision 5
and the weather rows above stay as a record of the design. Chlorophyll, Swift Swim, Sand Veil, Cloud Nine, Leaf Guard and
Hydration stay empty slots in `data/mon_abilities.asm`, with Cute Charm and
Magnet Pull (infatuation and the Steel type, also not planned).

Steps A to D, the refactors, are done, and each compared identical apart
from the differences recorded above. Step E, the new behaviour, is done; step G (link checks) remains.
WRAM no longer gates them. Bank 3's 3 free bytes may.

## Gen 9 rules pass

**Your decision:** modernize everything: the battle rules become Gen 9's,
with the Steel, Dark and Fairy types, and your learnset audit
(`Gen1_Remaster_Learnset_Audit.xlsx`, level-up learnsets, built on those
types and a Gen 9 engine) applied on top. Species take Gen 9's base stats;
growth is full Gen 9: real 0-31 IVs, EVs and the Gen 9 experience formula.
The 999 cap on stats and damage stays. Moves that don't exist yet reuse
existing animations; the ones that need a custom animation are listed.
Where Scarlet and Violet dropped a Gen 1 move, it takes the last generation
that had it.

**Source.** Gen 9 data comes from PokeAPI's CSVs (types, type chart, species
types and stats, moves), through generator scripts in `tools/`.

**Order, one commit or more each, every one with spec tests:**

1. Types: Steel, Dark and Fairy, the Gen 6+ chart, Gen 9 species types,
   retyped moves, Magnet Pull.
2. Species data: Gen 9 base stats, EV yields, base experience.
3. IVs, EVs, the Gen 3+ stat formula, Gen 9 experience. Four IV bytes (six
   5-bit IVs, the ability slot bit and Nuzlocke's mark) and six EV bytes
   replace the three DV bytes and ten stat-experience bytes, so each mon's
   data gets 3 bytes smaller.
4. The damage formula, critical hits (stages, x1.5, which stages and
   screens they ignore), stat and accuracy stages; badge boosts go.
5. Status conditions.
6. Move behaviours (priority, secondary-effect chances, trapping, screens,
   Haze, Substitute, Counter, recoil and crash, switching moves...).
7. Move data for the 165 moves.
8. The audit's 49 new moves.
9. The audit's learnsets.
10. AI and UI follow-up.

**Space.** The battle engine's bank (`$0F`) is full, so Gen 9 code goes in
a new bank, `$35` ("Battle 2"), replacing the old code as it goes.

### Part 1: types

- **Steel, Dark and Fairy** are type ids `$09`, `$1B` and `$1C` (Gen 2's
  places for the first two), with names. The physical and special type
  groups mean nothing now (moves have their own category).
- **The chart** is Gen 6+'s, generated by `tools/gen_types.py` into
  `data/type_effects.asm`: Gen 1's Bug-Poison and Ice-Fire matchups go,
  with Ghost no longer resisting Ghost and the new types' matchups.
  Typeless (Struggle) stays neutral to everything.
- **Species types** are Gen 9's: Clefairy and Clefable are Fairy,
  Jigglypuff and Wigglytuff Normal/Fairy, Mr. Mime Psychic/Fairy, Magnemite
  and Magneton Electric/Steel (the same script writes them).
- **Moves**: Bite is Dark, Gust Flying, Karate Chop Fighting, Sand-Attack
  Ground. The rest of the move data comes with part 7.
- **Steel types can't be poisoned**, in battle and in the AI's scoring.
- **Magnet Pull** (Magnemite, Magneton) now exists: a Steel type facing it
  can't flee or switch out, unless it is also Ghost (as from Gen 6). Cute
  Charm still waits for infatuation; the six weather abilities stay empty.
- **Space.** The type chart grew past bank `$0F`'s last bytes, so STAB, type
  effectiveness (the battle's and the AI's) and the chart moved to bank
  `$35`, reached by far calls; bank `$0F` has 675 bytes free again.
- **Verified:** `tests/test_types.py` checks all 324 pairs of the 18 types
  through the battle's own routine against the chart written out in the
  test, dual types (Magneton's 4x Ground weakness), Typeless, the species'
  and moves' types, the names, poison against Steel types and Magnet Pull.

### Part 2: species data

- **Base stats** are Gen 9's, written by `tools/gen_species.py`. Gen 9
  kept Gen 2's Special Attack and Special Defense for most species, so 20
  changed: the Gen 6 and 7 buffs (Pidgeot's Speed 101, Alakazam's Special
  Defense 95, Golem's Attack 120, Arbok, Dugtrio, Pikachu, Clefable and the
  rest).
- **Catch rates** are Gen 9's: Raticate 127, and Kadabra 100 and Pikachu
  190 (the fork had lowered both to Yellow's).
- **EV yields** (`data/ev_yields.asm`, two bits per stat) and **base
  experience** (`data/base_exp.asm`, two bytes, since Chansey's 395 and
  Mewtwo's 306 don't fit in one) are new tables by Pokédex number in bank
  `$35`, for part 3. The base stats' own one-byte experience field is still
  the one the game reads until then.
- **Verified:** `tests/test_species_data.py` checks Gen 9 values for the
  buffed species and a few others, the catch rates, and both tables as the
  ROM holds them.

### Part 3: IVs, EVs and Gen 9's formulas

- **Layout.** A mon's data has six one-byte EVs where the five two-byte stat
  experience fields were, then four IV bytes (`engine/ivs.asm`): one 32-bit
  number holding six 5-bit IVs (HP, Attack, Defense, Speed, Special Attack,
  Special Defense) and two flags, the ability slot (bit 0) and Nuzlocke's
  dead mark (bit 1), in the byte at `IV_FLAGS`. The box struct is 31 bytes
  (was 34), the party struct 44 (was 47), the battle struct 1 longer. WRAM
  comes out 3 bytes ahead after the new scratch bytes; the saved fossil-clone
  IVs take one more byte.
- **Stats** use Gen 3+'s formula: (2 x base + IV + EV / 4) x level / 100 +
  5 (HP: + level + 10), then the nature, capped at 999. `CalcStat` takes the
  mon's EVs, with the IVs after them (or, with no EVs, the IVs minus six).
- **Natures, gender, shininess** come from the IVs, since there is no
  personality value. The nature is the IVs (without the flags) mod 25, offset
  so trainers' fixed IVs are Hardy. The gender byte is the first and third
  IV bytes xored, against Gen 9-like thresholds out of 256. A mon is shiny
  when every IV's low two bits are `%10` (1 in 4096, Gen 9's odds); forced
  shinies (the Chansey attract, the trainer "mercy") roll those bits.
- **Rolling IVs** (`GenerateIVs`): wild mons uniform, with hard mode
  rerolling each IV under 8 once; Safari and hard-mode trainers the better of
  two rolls, and bosses' mons 16 or more; gifts 16 or more; trainers outside
  hard mode a fixed 19 Attack and 17 for the rest (Gen 1's DVs of 9 and 8,
  as 2 x DV + 1). Hard-mode trainers' mons get level x 85 / 100 EVs in each
  stat (510 in all at level 100).
- **EVs** are capped at 252 a stat and 510 in all (`AddEVs`). A defeated mon
  gives its Gen 9 EV yield to every party mon that gains experience.
  Vitamins give 10 (Gen 9), up to the caps, at any level; Calcium now raises
  Special Attack only and **Zinc** (a new item, `$62`, sold beside the other
  vitamins in Celadon) Special Defense. The held items moved up one id.
- **Experience** is Gen 7+'s (`ScaledExp`): base exp x foe level / 5, x
  ((2 Lf + 10) / (Lf + Lp + 10)) ^ 2.5, + 1, worked in 2.13 fixed point
  (within 0.5% or 1.5 points of the exact value), then x1.5 traded, x1.5 Lucky
  Egg, x1.2 at or past the level it could have evolved at. Every non-fainted
  party mon gains: those that took part (or hold an Exp. Share) in full, the
  rest half (Gen 9's always-on Exp. Share), with one line for the rest of the
  team. The Exp. All item does nothing now; the catch-up boost option stays.
  Gen 9 has no trainer-battle bonus, so that x1.5 is gone.
- **Items and features.** The M.Gene rolls new biased IVs of 16 or more
  (keeping the Nuzlocke mark); the Mist Stone sets every IV to 31 (Gen 7's
  Gold Bottle Cap) instead of maxing stat experience. The Cinnabar gene
  clone inherits each IV from one parent or the other and shows all six; it
  now recalculates the clone's stats (it didn't before). The status screen
  shows EVs with SELECT and IVs with START. The debug reset zeroes the EVs
  and takes the IVs from the first six bag quantities. The Celadon IV-scoring
  minigames average the six IVs.
- **Transform** copies the target's IVs but keeps the user's flags. It also
  reset only the player's move index, so a link battle's two games disagreed
  after the player transformed; it now resets the enemy's too (the link
  mirror test found it, once the new stats changed which turn reached it).
- **Space.** The enemy mon's IV and stat setup moved out of bank `$0F` to
  bank `$35` with the experience formula; the IV code is in bank 9.
- **Verified:** `tests/test_growth.py` checks `GetIV`, unpacking and packing,
  the shiny rule, gender thresholds, the EV caps and yields, `ScaledExp`
  against its fixed-point model and Gen 9's exact formula, the evolution
  bonus, the x1.2, hard-mode trainer EVs, and whole `GainExperience` runs
  (full share, half share, fainted, EVs, a level-up recalculating the stats
  from the IVs and EVs). `test_special_split` and `test_natures` check the
  stat formula for all 151 species and every nature; `test_abilities` the
  generators. In the emulator: the status screen's IVs and EVs.

### Part 4: the damage formula, critical hits and stages

- **Damage** (`engine/battle/damage.asm`, bank `$35`): `BaseDamage` is Gen
  5+'s (2 x level / 5 + 2) x power x A / D / 50 + 2 with 16-bit stats (Gen 1
  divided both by 4 past 255). A and D are the unmodified stats times Gen 9's
  stage ratios (2/8 to 8/2), each 1-999; a critical hit leaves out the
  attacker's drops and the defender's raises. `DamageModifiers` then applies
  Gen 9's order: x1.5 critical hit, x85-100% at random (one battle random
  number, 16 steps), STAB and type (`AdjustDamageForMoveType`), x1/2 for a
  burned attacker's physical move unless it has Guts, x1/2 behind Reflect or
  Light Screen except on a critical hit, then the abilities' and items'
  modifiers. A hit that doesn't miss does at least 1 (Gen 1 made a 0 after
  x1/4 miss). Explosion no longer halves Defense. Decision 3's stage order
  (S0-S5) is replaced by this one; rounding is floor at each step.
- **Critical hits** are Gen 9's stages: 1/24 (11 in 256), 1/8, 1/2, then
  always, for +1 (Karate Chop, Razor Leaf, Crabhammer, Slash, Razor Wind,
  Sky Attack; part 7 will take the list from Gen 9's data), +2 for Focus
  Energy and Dire Hit, +1 Scope Lens, +2 the Stick and Lucky Punch; Battle
  Armor and Shell Armor stop them. The Stadium-style and speed-based rates
  are gone, in every mode.
- **Stages** are Gen 9's ratios for the stored stats too, and accuracy is one
  net stage, accuracy minus evasion, from 3/9 to 9/3.
- **Burn** halves damage, not the Attack stat, so curing it changes no stat;
  **badge boosts** are gone (Gen 9 has none).
- **The confused self-hit** is Gen 9's: 40 power, the mon's own Attack
  against its own Defense with their stages, x85-100%, never critical, and
  no longer touched by the foe's Reflect.
- **Space.** The Gen 1 routines (`GetDamageVars`, `CalculateDamage`,
  `CriticalHitTest`, `RandomizeDamage` and the critical-hit stat predefs)
  are gone, and `BattleRandom` moved to bank 0 so every bank can draw from
  the link battle's shared list (the abilities' copy of it is gone too). Bank
  `$0F` has 1725 bytes free.
- **Verified:** `tests/test_damage.py` runs 600 random battle states
  (`tests/suites/damage.py`, which replaces the Gen 1 `damage_vars` suite)
  through `BaseDamage` and `DamageModifiers` against a Python model of the
  chain, plus worked examples (crit, burn, screens, stages on crits, the
  minimum of 1) and every critical hit stage's threshold. The accuracy test
  models the net stage; the badge test checks there are none.

### Part 5: status conditions

As in Gen 9 (Showdown's implementation, where Bulbapedia is vague):

- **Sleep** lasts 1-3 turns: the counter is 2-4 (one random number, a 3
  rerolled), the mon wakes when it reaches 0 and moves that turn, as the fork
  already did. Rest's 3 is Gen 9's two turns asleep.
- **Freeze**: a 20% chance (51 in 256) to thaw at the start of the frozen
  mon's turn, and move; Fire moves still thaw a frozen target.
- **Paralysis** halves speed (`HalveSpeedDueToParalysis`, Gen 1 quartered
  it; curing it doubles it back) and fully paralyzes 25% of the time (64 in
  256, was 63).
- **Confusion** makes a mon hurt itself 1/3 of the time (85 in 256), for the
  same 1-4 turns (Gen 9's counter of 2-5, decreased before the check).
- **Residual damage**: poison and Leech Seed 1/8 of max HP (Liquid Ooze's
  Leech Seed too), burn 1/16, bad poison 1/16 times its counter; each at
  least 1.
- **Bad poison stays bad poison** through a switch: the status byte's spare
  bit 7 (`TOX`, always with `PSN`) marks it, Toxic and Synchronize set it,
  and a mon sent out with it gets its toxic flag back with the counter from
  1. Every cure clears the whole status byte, so the bit never outlives the
  poison.
- **Type immunities** (`StatusTypeImmune`, bank 0): Fire types can't be
  burned, Ice types frozen, Electric types paralyzed, Poison and Steel types
  poisoned, from any move or ability. Gen 1's rule that a move's side effect
  can't hit its own type (Body Slam couldn't paralyze a Normal type) is gone.
  Thunder Wave still can't hit Ground types. (Powder moves against Grass
  types come with part 6's move flags.)
- **Not changed**: poison still hurts outside battle, a field mechanic Gen
  5 dropped.
- **Verified:** `tests/test_status.py` checks each turn-start roll at its
  threshold (thaw, full paralysis, confusion), the sleep counter rolls, every
  residual fraction and the toxic sequence, bad poison on send-out, the type
  immunities (Thunder Wave on Electric, Ground and Normal types) and the
  speed halving. The ability and item tests that had Gen 1's numbers (Leech
  Seed, Leftovers after poison, Shed Skin, Synchronize) have Gen 9's.

### Part 6: move behaviours

One commit per group:

- **Priority** is Gen 9's brackets, from a table generated from PokeAPI
  (`tools/gen_move_data.py` → `data/move_priorities.asm`): Quick Attack +1,
  Bide +1, Counter -5, Whirlwind, Roar and Teleport -6. `ComparePriority`
  (bank `$35`) compares them signed; Quick Claw and speed decide ties.
- **Secondary-effect chances** are each move's Gen 9 chance, from the same
  script (`data/move_chances.asm`, out of 256, 255 for always):
  `MoveSecondaryChance` overrides the effect's own chance before Serene
  Grace and Shield Dust. Gen 9's high critical-hit moves come from the
  same script (`data/move_crit_moves.asm`).
- **Binding moves** (Wrap, Bind, Fire Spin, Clamp): the user is no longer
  locked in and the target no longer loses its turns. A hit binds the
  target, not through a substitute or an immunity, for 4-5 turns
  (`wPlayerBoundTurns`/`wEnemyBoundTurns`, 5-6, counted down after each of
  the bound mon's turns; the last frees it, "was freed from WRAP!"). Each
  turn it takes 1/8 of its max HP (Magic Guard: none, but the turns still
  count). It can't flee or switch out unless it's a Ghost type (the
  `SideTrapped` check Arena Trap uses, so the switch menu, running and the
  AI all respect it). Either mon leaving the field frees it. Shin's
  trapping clause, the AI's "switch out of a trapping move" and the
  "attack continues" text go; the rules menu loses its TRAP CLAUSE row
  (its link nybble bit stays, unused).
- **Reflect, Light Screen and Mist** are side conditions for 5 turns
  (`wPlayerReflectTurns` ... `wEnemyMistTurns`), kept through switches.
  They count down as each turn ends: `wTurnPending` is set once both sides
  have chosen, and the battle loop's next pass (`SideConditionsEndOfTurn`)
  counts down and says "Your team's REFLECT wore off!" / "The foe's ...".
  Guard Spec. is Mist for 5 turns. The status bits they used are free.
- **Haze** resets every stat stage on both sides and nothing else: status,
  Leech Seed, confusion, Focus Energy, Disable and screens stay (Gen 1's
  Haze cured the target's status). Paralysis still halves speed after it.
- **Verified:** `tests/test_move_data.py` (priority brackets, chances) and
  `tests/test_side_conditions.py` (binding duration, damage, immunity,
  switching, freeing on send-out, screens and Mist for 5 turns, the
  end-of-turn countdown, Haze). In the emulator, a wild battle against a
  Snorlax showed "can't escape!", "hurt by WRAP", "was freed from WRAP!",
  Reflect failing while up, and Mist. The damage and link mirror suites
  read the screens' new counters.
- **Multi-hit moves** hit 2 or 3 times 35% of the time each, 4 or 5 times
  15% (90/90/38/38 in 256; Skill Link still 5).
- **Recoil**: Double-Edge 1/3 of the damage dealt, Take Down and Submission
  1/4, rounded half up as Showdown does; Struggle 1/4 of the user's max HP
  (Rock Head doesn't stop it, Magic Guard does). At least 1.
- **Crash damage** (Jump Kick, Hi Jump Kick missing or not affecting the
  target): half the user's max HP, taken from the mon itself, not its
  substitute (`CrashDamage_`). The fork's "threatened damage" store in the
  hit test goes.
- **Psywave**: the user's level times 50-150% (a 0-100 roll, rerolled above
  100), at least 1. The fork's `PsywaveEnhanced` goes.
- **Low Kick**'s power goes by the target's Gen 9 weight: 20 under 10 kg,
  40 under 25, 60 under 50, 80 under 100, 100 under 200, else 120
  (`data/low_kick_powers.asm`, by Pokédex number, from `tools/gen_species.py`;
  `LowKickPower` in `BaseDamage`).
- **Verified:** `tests/test_move_effects.py` checks each multi-hit threshold,
  the recoil fractions and rounding, crash damage around a substitute,
  Psywave's ends and reroll, and Low Kick against four species; the damage
  model reads Low Kick's table.
- **Move flags**: `data/move_flags.asm` (now from `tools/gen_move_data.py`,
  which also covers the new moves through their PokeAPI ids) gains Gen 9's
  mirror, defrost, powder and bypass-substitute flags, and a never-miss
  flag for moves with no accuracy. `UserMoveHasFlag` and `MoveHasFlag`
  (bank `$34`) take the mask in `e`: `callab` overwrites `bc` (it loads its
  return address there), so nothing can be passed in `c` across it.
- **The hit test**: powders (Sleep Powder, Stun Spore, Poison Powder,
  Spore) don't affect Grass types ("is unaffected", `wMoveMissed` 2).
  Never-miss moves (Swift, Struggle, Whirlwind, Roar, Mimic, Mirror Move,
  Transform, Haze...) skip the accuracy roll but still can't hit a mon in
  the air or underground (Gen 1's Swift could).
- **Substitute**: costs a quarter of max HP and needs more than that (the
  fork's check only looked at the low byte, so 256 HP left failed); it
  breaks at 0 HP (Gen 1's survived at 0), and a broken one counts only the
  HP it had (`wDamage`, which recoil, drain and Counter read). Moves with
  the bypass flag (Growl, Roar, Sing, Supersonic, Screech, Whirlwind,
  Disable, Mimic, Haze) go through it (`CheckTargetSubstitute`); drain
  moves hit it (Gen 5+), Leech Seed still doesn't.
- **Counter** was already Gen 9's (physical moves of any type, twice the
  damage this turn).
- **Bide** always stores for two turns.
- **Rage** follows Gen 7, its last generation: the mon isn't locked in, each
  hit it takes raises its Attack, and choosing another move ends it. The
  fork's 2-3 turn counter and accuracy reset go.
- **Disable** picks the target's last move (not a random one) and fails if
  there is none, it was Struggle, it has no PP or a move is already
  disabled; it lasts 4 of the target's turns (counting this one if it
  hasn't moved). The fork's `PlayerDisableHandler` and
  `EnemyDisableHandler` predefs go.
- **Mimic** copies the target's last move (not a chosen or random one) into
  Mimic's slot with that move's full PP, until the user leaves the field;
  it fails on Mimic, Transform, Struggle, no move, or a move the user
  knows. The mimicked move's PP aren't the party mon's: `DecrementPP` and
  `IncrementMovePP` skip the party copy for that slot
  (`wPlayerMimicSlot`), and an enemy trainer's withdrawn mon gets Mimic's
  own PP back (`wEnemyMimicPP`). `DecrementPP` moved to bank `$35` (bank
  `$1A` was full).
- **Mirror Move** copies only moves with the mirror flag (moves aimed at
  another mon), so Swords Dance or Mirror Move itself fail.
- **Verified:** `tests/test_move_rules.py` (15 tests: Disable and its
  failures, Mimic and its PP, Mirror Move, powders against Grass, never-miss
  without a roll, Growl through a substitute, Absorb hitting one, the
  Substitute thresholds, breaking at 0 and counting its HP, Bide, Rage).
  Writing them found `PowderBlocked` returning carry for every type below
  Grass, and the flag mask lost across `callab`.
- **Conversion** (Gen 6+): the user becomes the type of the move in its
  first slot ("CLEFAIRY's type became FIRE!"), and fails if it already has
  that type. It moved to bank 9, by the type names.
- **Whirlwind and Roar in trainer battles** drag out a random other mon of
  the target's that can battle (`PickRandomSwitchIn`, rerolling
  `BattleRandom & 7` until a slot fits, so a link partner's game picks the
  same one), through trapping, and fail if there's none. The enemy's mon
  comes in through `EnemySendOut` with `wForcedSwitchSlot` set (no
  "withdrew" text, no shift prompt); the player's through
  `SwitchPlayerMon`. The dragged-out side does nothing more that turn.
- **Teleport in trainer battles** (Gen 8+) switches the user out: the player
  picks from the party menu (no cancelling), the AI at random. It fails in
  link battles, where the choice would have to cross the link mid-move.
- **Wild battles** keep Gen 1's rule for all three (running away or blowing
  the wild mon away, by a level roll).
- **Defrost**: a frozen mon using a move with the defrost flag thaws without
  the 20% roll (no Gen 1 move has it; Flame Wheel and Flare Blitz will).
- **Verified:** `tests/test_switch_moves.py` (which slots can come in, the
  random pick's rerolls, Roar on the enemy, Whirlwind on the player, the
  enemy's Teleport, failing with no other mon, Conversion) and a defrost
  test in `tests/test_status.py` (Tackle given the flag). The link mirror
  test now mirrors the party species, nicknames, Mimic slots and the forced
  switch slot, and caught the enemy's move number surviving a dragged-out
  switch (the player's is cleared by `SendOutMon`; now both are).

### Part 7: move data for the 165 moves

- **Numbers**: `tools/gen_move_data.py` rewrites each move's power, type,
  accuracy and PP in `data/moves.asm` from PokeAPI, in place (effects stay
  hand-written). Kept: power where PokeAPI has none (fixed damage, OHKO and
  status moves, where 1 means "does damage"), Low Kick's nominal 50 (its
  power comes from the target's weight), and the typeless (`BIRD`) Struggle
  and Bide; moves with no accuracy get 100 (their never-miss flag decides).
  The fork had already modernised many; the rest change, e.g. Tackle 40/100,
  Wing Attack 60, Fly 90, Thrash and Petal Dance 120, Blizzard 110/70, the
  95s to 90, Leech Life 80/10, Self-Destruct 200, Explosion 250, Glare and
  Disable 100% accurate, Recover 5 PP. Metronome is Normal.
- **Effects remapped to Gen 9's**: Acid lowers Special Defense; Low Kick
  doesn't flinch; String Shot lowers Speed two stages; Minimize raises
  evasion two; Waterfall and Rock Slide flinch (20%, 30%); Dizzy Punch
  confuses (20%); the chances come from `MoveChances`.
- **New effects**: Tri Attack (`TRI_ATTACK_EFFECT`, the first unused
  effect slot) burns, paralyzes or freezes, picked at random, 20% of the
  time; Growth (`GROWTH_EFFECT`) raises Attack and Special Attack one stage
  each. Skull Bash raises Defense as it charges. A Poison type's Toxic never
  misses (Gen 6+).
- **Not done**: Sky Attack's 30% flinch (the charge effect owns the effect
  slot).
- **Verified:** `tests/test_move_data_gen9.py` checks every move's power,
  accuracy and PP against PokeAPI (when the CSVs are present) and the new
  effects; Forewarn's Tackle is 40 now.

### Part 8: the learnset audit's 49 new moves

- **Ids**: the 49 moves go after Substitute (`AERIAL_ACE` $A5 ...
  `X_SCISSOR` $D5), so Struggle is $D6 and the special animations follow
  it, up to $FC. Move and animation ids stay below the animation scripts'
  special-effect commands ($D8+ are only command bytes, not ids), and no
  script's sound byte reached Struggle's row, so none needed renumbering.
  `ROUND` is an rgbds function, so the constant is `ROUND_M`. Names fit 12
  letters: ANCIENTPOWER, DRAGONBREATH, DYNAMICPUNCH, EXTREMESPEED (Gen 2-4's
  spellings), DISARM VOICE, STOMPTANTRUM.
- **Data**: each constant has a `; pokeapi NAME id` line, so
  `tools/gen_move_data.py` fills in power, type, accuracy, PP, category
  (`data/move_categories.asm`, now generated), flags, chances, priorities
  and high critical-hit moves. Effects are hand-picked from the existing ones
  (flinch, burn, paralysis, poison, confusion, stat-down side effects, drain,
  recoil).
- **New rules**: Ancient Power (`ALL_STATS_UP_SIDE_EFFECT`, 10%: all five
  stats +1); Close Combat (`CLOSE_COMBAT_EFFECT`: the user's Defense and
  Special Defense -1, even when the target faints); Brine (double power at
  half HP or less, `BrinePower`); Psyshock (special, against Defense, in
  `BaseDamage`); Poison Fang's poison is bad poison; Flare Blitz's recoil
  is 1/3; Flame Wheel and Flare Blitz thaw their user (defrost flag); Aerial
  Ace, Disarming Voice never miss; sound moves (Hyper Voice, Bug Buzz,
  Round, Disarming Voice) hit the mon behind a substitute
  (`ApplyDamageToPokemon`); Aqua Jet, Mach Punch +1 and Extreme Speed +2.
- **Not done**: Bug Bite, Pluck and Incinerate don't take or burn berries;
  Stomping Tantrum doesn't double after a failed move; Fire Fang doesn't
  flinch and Flare Blitz doesn't burn (one effect per move); Twister
  doesn't hit a flying mon; Ancient Power's self-boost can be stopped by the
  target's Shield Dust.
- **Animations** reuse a donor move's animation and sound;
  `docs/new_move_animations.md` lists each donor and the 13 moves that want
  a custom animation (Shadow Ball, Moonblast, Air Slash, X-Scissor, Aqua
  Jet, Dragon Rush, Fire Fang, Poison Fang, Flame Wheel, Flare Blitz,
  Icicle Crash, Leaf Blade, Water Pulse).
- **Space**: the SS Anne smoke and evolution code moved from bank `$1E` to
  `$35` to make room for the longer sound and animation tables.
- **Verified:** `tests/test_new_moves.py` (names, Ancient Power, Close
  Combat, Poison Fang, Flare Blitz, Brine, Flame Wheel thawing, Aerial Ace,
  Hyper Voice through a substitute, priorities, and Close Combat through a
  whole move); the move-data test checks the new moves against PokeAPI; the
  random-turn and link mirror suites draw from all 214 moves; the damage
  model knows Brine and Psyshock. In the emulator, Shadow Ball, Close
  Combat, Ancient Power and Extreme Speed play with their names and
  animations, which showed Close Combat lowering the stats twice (it wasn't
  in `SpecialEffects`, so it ran again at the end of the move); fixed.

### Part 9: the audit's learnsets

- **All 249 rows** of the "Recommended Remaster Learnsets" sheet are
  applied, CONDITIONAL ones included, by `tools/apply_learnset_audit.py`
  (run again, it changes nothing; `tests/test_learnsets.py` checks that
  when the spreadsheet is present). A move goes to the proposed level and
  out of wherever the species had it; "Remove" takes Horn Drill and
  Guillotine away. `docs/learnset_changes.md` lists every change.
- **Starting moves**: a starting move the sheet moves later comes out of the
  base stats' four; Zubat's only one (Leech Life, now at 12) gives way to
  Absorb, its first damaging Gen 9 level 1 move.
- **Level 1 moves are evolution moves** (Gen 7+): evolving now also calls
  `LearnMoveFromLevelUp` for level 1, so Vaporeon, Jolteon and Flareon learn
  their STAB as they evolve, and Clefable Disarming Voice. Base forms'
  level 1 moves are in their learnsets as `db 1` too (`WriteMonMoves` skips
  a move already known).
- **Not taken up**: the sheet's suggested category changes (Vine Whip and
  Razor Leaf special). Trainers' parties pick up the new moves through
  `WriteMonMoves` as before.
- **Space**: Reflect and Light Screen's effect moved from bank `$E` to
  `$35` (the learnsets filled `$E`).
- **Verified:** `tests/test_learnsets.py` (every learnset in level order with
  real moves, the sheet fully applied, Vaporeon learning Water Gun at level
  1); the full suite.

### Part 10: AI and item follow-up

- **Held items for the new types**: Metal Coat (Steel), BlackGlasses (Dark)
  and Fairy Feather (Fairy) boost their type by 1/5 like the Gen 2 ones
  (`TypeBoostingItems`), at $94-$96. The Celadon store's TM counter sells
  them (the X item counter was full at 13), and a wild Magnemite holds a
  Metal Coat 2% of the time.
- **AI**: Growth is "useless" only with both Attack and Special Attack at +6;
  Whirlwind, Roar and Teleport are no longer always discouraged in trainer
  battles, only when no mon could come in (`HasSwitchIn`).
- **Space**: the move categories moved from bank `$E` to `$35`.
- **Verified:** `tests/test_ai_gen9.py` (Growth at 0, +5 and +6; the switch
  moves with and without a mon to come in); the held item tests count 52.
- **Left for later**: AI scoring of the other new effects (Close Combat's
  drops, Ancient Power, Tri Attack) beyond what the generic damage scoring
  gives them; the 13 custom animations (`docs/new_move_animations.md`).

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

- **Fixed: a confused mon's self-hit could use its special stats** (a bug
  of this branch's physical/special split, not upstream's). `GetDamageVars`
  picks the stats by the move number, which the self-hit didn't set, so it
  went by the mon's last move: after a special one, its Special Attack
  against the foe's Special Defense (386 damage instead of 27 in the test).
  The self-hit now has no move while its damage is worked out, which means
  the physical stats, and the number is put back. Test:
  `tests/test_confusion_self_hit.py`.

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

## Cleanup after the Gen 9 pass

- **Rules toggles**: the two features the project began with are options:
  HEAL ON WIN (heal the party after a trainer win) and WARP BACK (offer a
  return to where you blacked out), on the OPTION screen's EXTRAS page. They
  were on by default at first (inverted flags); since the OPTION screen
  rework they are off by default like every other extra, with the flags
  `EVENT_WIN_HEAL` and `EVENT_BLACKOUT_RETURN` (the unused $8CA and $8CB)
  meaning "on". `tests/test_rule_toggles.py`.
- **Starter HP**: gift mons (the starters, and every mon `AddPartyMon` makes
  outside battle) came 1-2 HP short: `PackIVs` clobbered `de`, so
  `AddPartyMon` worked out the current HP from the bytes after `wIVScratch`
  instead of the new IVs. `PackIVs` keeps `de` now. `tests/test_gift_mons.py`.
- **Branding and version**: the title logo loses "SHIN" and 真 (the Japanese
  logo never had them); the main menu shows v0.5.0, and the link handshake
  digits are 0.0.5.0, so it won't link with Shin's builds.

- **The bag screen**: Shin's SELECT-swapped second bag is gone (its WRAM
  backup is freed). The bag holds 36 kinds (`BAG_ITEM_CAPACITY`) and opens
  full screen (`engine/menu/bag_menu.asm`, `BagMenu`), from the START menu
  and in battle: a header with the pocket's name between ◀ and ▶, and six
  two-line entries (the name, then "×NN" except for key items), then CANCEL.
  LEFT/RIGHT change pocket (ITEMS, MEDICINE, BALLS, BATTLE ITEMS, BERRIES,
  KEY ITEMS; TMs and HMs aren't in the bag, see below); the pocket, cursor
  and scroll are remembered.
  `tools/gen_item_pockets.py` writes `data/item_pockets.asm`: each item's
  pocket and `ItemSortList`, every item in pocket order. The bag is put in
  that order (`SortBag`) when the bag screen, the PC's deposit list or the
  mart's sell list opens, never while an item is being added or removed
  (those go by the index the bag had). `BagMenu` returns as
  `DisplayListMenuID` did, so USE/TOSS and the battle item code are
  unchanged; overworld sprites are hidden while it is open. The old man's
  demo still uses the old list. START in the PC's item box still sorts it.
  `tests/test_bag.py`.
- **TMs and HMs are owned, not carried.** Getting one (a gift, an item
  ball, a hidden item, a mart, the prize corner) sets its flag in
  `wTMsOwned` (7 bytes after the bag, which went from 40 kinds to 36 to make
  room; `MachineIndex` numbers them in `TechnicalMachines`' order, TMs then
  HMs) instead of adding it to the bag: `AddItemToInventory_` handles it
  and always succeeds. Marts sell an owned TM no more and an unowned one one
  at a time; the prize corner won't trade for one already owned. NEW GAME
  clears the flags; NEW GAME+ keeps them (`DoNewGamePlus` and
  `InitPlayerData` skip `wTMsOwned`..`wTMsOwnedEnd`). Pewter's TM34 speech
  says TMs never run out.
- **The MOVES screen** (party menu → MOVES, `engine/menu/moves_screen.asm`):
  the mon's four moves with their PP and its field move slot (Shin's
  temporary field move: usable outside battle only), and below them the
  highlighted move's type, category, power, accuracy and PP. A slot opens
  the list of what can go there: REMOVE (not for a mon's only move; the
  moves after it move up), then its starting moves, its learnset up to its
  level (marked L and the level), then each owned TM and HM it can learn
  (marked TM05, HM01...); the field move slot lists field moves only.
  Choosing one puts it in the slot (or the first empty one) with its full
  PP, and PP Ups go with the old move, as in Gen 9. The party submenu is
  STATS, MOVES, SWITCH, CANCEL, so it shows at most four field moves
  (`NUM_FIELD_MOVES`): a mon with four field moves no longer lists its
  field-slot move or TAKE there.
  `tests/test_moves_screen.py` checks the lists against a model built from
  the data files, for six mons and every slot, and learning, replacing,
  removing and the field slot; it also found that the learnset parser in
  `tests/test_learnsets.py` skipped entries whose "; Learnset" line had a
  comment (Pikachu's, among others), which it no longer does.
- **`coord` and the other screen-position macros** now put their row and
  column in parentheses, so `coord hl, 0, TOP - 1` means row TOP - 1 (it
  meant row TOP, one column to the left). No existing call used an
  expression the change affects, so the ROM is otherwise unchanged; the bag screen had
  hit it.
- **Removed, now that the MOVES screen does their jobs**: Shin's move
  deleter and relearner NPCs in Saffron (the `_MOVENPCS` build flag, their
  scripts, texts and `PrepareRelearnableMoveList`; Fuchsia gym's move list
  keeps the `MOVESLISTMENU` handling it shares), and the code that taught a
  TM from the bag (`ItemUseTMHM` and its texts, `TMToMove`, the party
  menu's ABLE/NOT ABLE mode, `TMHM_PARTY_MENU`'s prompt, and the "can't
  toss, sell or deposit an HM" checks). `LearnToFieldSlot` stays: a
  level-up outside battle can still offer a field move for the field slot.
- **The day care takes two.** A second slot in save RAM
  (`sDayCareMon2Name`, `sDayCareMon2OT`, `sDayCareMon2`, the same layout as
  the first, right after it; the bank 1 snapshot doubles to match), and
  `wDayCareInUse` is now how many are in (0-2). The day-care code still
  works on the first slot: `SwapDayCareMons` swaps the two when it needs the
  other, so a lone mon is always in the first. Talking to the man: with
  none in, as before; with one, "Would you like me to raise another
  #MON too?" (NO goes on to taking that one back, as before); with two, a
  menu of their names and CANCEL picks which one comes back. Both gain
  experience on the same steps. `tests/test_pc_boxes.py`: the swap, both
  gaining exp, the menu, saving and loading both, and the whole
  conversation (two in, the first one back) through the man's own script.
  Breeding and eggs come next, on top of this.
- **Breeding and eggs, as from Gen 6** (`engine/breeding.asm`). Shin's
  cloning machine in the Cinnabar lab (the gene-splicing scientist and his
  three bookshelves, `DevolveMon`) is gone; this replaces it.
  - **Data**: `tools/gen_breeding.py` writes `data/breeding.asm` from
    PokeAPI's CSVs, by Pokédex number: each species' two egg groups
    (`EGG_*`, `constants/breeding_constants.asm`), its egg cycles, the first
    of its line (what its eggs are) and its egg moves. Egg moves are those of
    the first of the whole line, so Pikachu's eggs know Pichu's, Snorlax's
    Munchlax's; they're Scarlet and Violet's, or for a species not in them
    the latest game's (Sword and Shield first), keeping the moves this game
    has.
  - **Laying**: every 256 steps (`wEggStepCounter`, from the step hook in
    `ApplyOutOfBattlePoisonDamage`) the day care's two mons may make an egg
    if none is waiting. `DayCareCompatibility`: a Ditto with any mon that
    isn't a Ditto or of the no-eggs group, or a male and a female sharing an
    egg group; 70% for the same species with different original trainers
    (OT IDs), 50% for the same species and trainer or different species and
    trainers, 20% for different species with the same trainer. The man
    says which ("The two seem to get along very well." ...) when the player
    talks to him with two mons in.
  - **The egg** is made when it's laid, into its own day-care slot in save
    RAM (`sDayCareEgg`, snapshotted with the rest), so taking a parent back
    doesn't change it. Its species is the first of the mother's line (the
    non-Ditto parent's): Nidoran either one at random. Its moves: its level 1
    moves, then the learnset moves both parents know, then the egg moves
    either parent knows, each new one pushing out the oldest. Three IVs, at
    random, come from one parent or the other; the rest are random; its
    ability slot is the mother's 80% of the time, the other's otherwise. A
    parent holding an Everstone passes its nature down (one of the two at
    random if both do): natures come from the IVs, so the last IV not
    inherited is picked to give it (any nature is possible from one IV's 32
    values). Gender and shininess come from the IVs, as for any mon. Level
    1, 0 EVs, the player as its original trainer, "EGG" as its nickname.
  - **Taking it**: the man offers it before anything else. Yes, with room in
    the party, gives it; no room keeps it for later; no means he keeps it
    for good (it's gone, as from Gen 3).
  - **An egg** is `EGG` ($FD) in a party's or box's species list (as in Gen
    2); its data is a mon's, with its real species, 0 HP, level 1, and its
    egg cycles left where a held item goes. With 0 HP it never battles and
    gains no experience; the Pokémon Center and every other full heal leave
    it at 0; no item works on it (the item party menus refuse it); it has no
    field moves, TAKE, MOVES screen, cry, rename or Hall of Fame entry; it
    can't go in the day care, and the PC and the day care won't take a
    player's last mon that can battle. STATS shows "EGG" and how close it is
    to hatching (Gen 2's four lines). The party menu shows its name and a new
    egg icon that wiggles (`gfx/egg_icon.png`, icon `EGG_ICON`).
    `GetMonName` names it "EGG"; `LoadMonData` reads an egg's header from
    its real species, so moving it through the PC works.
  - **Hatching**: every 256 steps each egg in the party loses a cycle (two
    with a Flame Body mon in the party, as from Gen 3); at 0 it hatches at
    once (`TEXT_EGG_HATCHING`): "Oh?", the new mon's picture and cry,
    "... hatched from the EGG!", a nickname, its level 1 stats and full HP,
    and its species seen and owned in the Pokédex. Gen 4 on hatch at level 1.
  - **Bugs found by the tests**: two 8-bit `(dex - 1) * 2` table offsets
    that wrap past Pokédex number 128 (Ditto read Charmander's egg groups).
  - `tests/test_breeding.py`: the data, compatibility for 13 pairs, the
    egg's species, moves (against a model), IVs and ability (with the random
    numbers queued), Ditto and Nidoran, the Everstone, laying, cycles and
    Flame Body, giving, hatching, the PC, healing, names, the last-battler
    rule, and the man's offer.
- **A party icon for every species.** The party menu, the naming screen and
  the trade animation used ten shared icon types (`MonPartyData`); each
  Pokémon now has its own two-frame icon, from "MINIDEX 001-251" by Chamber,
  Solo993, Blue Emerald, Lake, Neslug and Pikachu25 (free to use with credit;
  credited in the README). `tools/gen_party_icons.py` turns the sheet
  (`gfx/sources/minidex_001-251.gif`) into `gfx/party_icons_1.png` and
  `_2.png`, one frame each, 16x16 by Pokédex number with the egg's last
  (two frames that rock it, from `gfx/sources/egg_icon_frames.png`, its
  white light grey), mapping the sheet's
  colours to the Game Boy's: the peach skin light grey, the body colour dark
  grey, the outline black. They're 9.5 KB a frame, in two banks of their
  own. When the party menu draws, each party slot's icon is copied to its
  own tiles (slot n: sprite tiles 4n, and $40 + 4n for the second frame),
  and `wPartyIconSpecies` remembers whose they are, so a redraw reloads a
  slot whose species changed (a swap, an evolution, a hatch; swapping at
  first left the icons where they were); the naming screen and the trade load their one species' icon into slot
  0's. The old icon types' graphics are gone except the two pieces the
  trade's cable circle uses. Every icon now animates by swapping frames
  (the Poké Ball and helix icons used to bob instead). On the Game Boy
  Color, the icons still take the party menu's one sprite palette.
- **SPRITES: GEN 1 / GEN 2** (OPTION screen, DISPLAY page). GEN 2 shows
  Pokémon Crystal's sprites, fronts and backs, everywhere a Pokémon's
  picture is: battle (the send-out animation included), the status screen,
  the Pokédex, evolution, trades, the Hall of Fame, the title screen.
  - **Source**: pret's pokecrystal disassembly, whose sprites are lossless
    PNGs (a sheet ripped and saved as a downscaled lossy WebP couldn't be
    used). `tools/gen_gen2_pics.py` fetches them and writes
    `pic/gen2mon/<name>.png` (each front's first frame, its still pose,
    40, 48 or 56 pixels square as Gen 1's are) and
    `pic/gen2monback/<name>b.png` (48x48), grey from pret's palette
    indices, and `data/gen2_pics.asm`. The build compresses them as it does
    every pic.
  - **Space**: each species' front and back are a section of their own, so
    the linker keeps the pair in one bank (`wMonHPicBank` is shared) and
    packs them into the ROM's free space: about 96 KB, all in banks already
    in use. The ROM stays 1 MB (banks $36-$3F are still empty), so no 2 MB
    expansion was needed.
  - **How**: `GetMonHeader` far-calls `Gen2PicHeader` after copying a
    species' base stats; with the option on, it overwrites `wMonHPicBank`,
    `wMonHSpriteDim`, `wMonHFrontSprite` and `wMonHBackSprite` from
    `Gen2PicHeaders` (by Pokédex number). Every picture goes through those
    fields, so nothing downstream changed. The fossils' and the ghost's
    special pictures are left alone. Gen 2's backs are 48x48, shown
    unscaled: `LoadMonBackPic` asks `BackPicsAreLarge` (the Spaceworld
    builds always; the others with the option on) instead of the build flag,
    and uses the Spaceworld backs' path (`LoadUncompressedBackPics`). The
    player's own back picture stays as each build has it.
  - **The option** is bit `BIT_GEN2_SPRITES` of `wSpriteOptions`, a new
    saved byte (the old fossil IVs' spare bytes), kept through NEW GAME (as
    the other options are) and NEW GAME+.
  - **Home bank**: to fit the far call, four routines nothing called were
    removed (`GroundRoseText`, `EmptyFunc2`, `SetSpriteMovementBytesToFE`,
    `Func_35f4`).
  - **Not done**: on the Game Boy Color, the pictures keep each species'
    Gen 1 palette.
  - `tests/test_gen2_sprites.py`: every species' header with the option on
    and off (pointers, bank, size against the pic file), the special
    pictures, and NEW GAME+.
- **The OPTION screen** (`engine/menu/options.asm`) replaces the original
  three-option screen, the extra options screen SELECT opened, and that
  screen's RULES page, where options were unexplained and rules hid behind a
  confusing submenu.
  - **Layout**: the page's name in a box at the top (rows 0-2), up to seven
    options in the middle box (rows 3-11, value right-aligned), and a text
    box at the bottom (rows 12-17) explaining the option under the cursor
    in two lines of at most 18 letters. UP/DOWN move, A or RIGHT gives the
    next value and LEFT the previous; on the page's name, LEFT/RIGHT turn
    the page, and SELECT turns it from anywhere. B or START closes it. The
    map's sprites are hidden while it is open.
  - **Pages**: GAME (TEXT SPEED with INST./FAST/MEDIUM/SLOW, BATTLE ANIM,
    BTL. STYLE, AUDIO, SOUND TEST), DISPLAY (FRAME RATE, SPRITES, MORE
    COLOR, COLOR FIX, SYMBOLS, TYPE HINT), CHALLENGE (HARD MODE, AI SWITCHING, LEVEL
    CAP showing the current cap, SCALING, ALT. MOVES, NUZLOCKE), CLAUSES
    (ITEM, SLEEP, FREEZE, HYPER BEAM), EXTRAS (HEAL ON WIN, WARP BACK,
    CATCH-UP EXP, RANDOM WILD with OFF/TIER/FULL, RANDOM TRNR, SAFARI
    EVENT, PC IN MENU).
  - **Data-driven**: each option is a 12-byte row (label, explanation,
    kind, mask or value count, address or getter, setter, value names). A
    bit option (`opt_bit`, `opt_event` for event flags) toggles a mask;
    custom ones call a getter and setter (text speed, audio, the two color
    options, which refresh the palettes, the level cap and RANDOM WILD's
    two flags); an action (SOUND TEST) runs on A. The storage of every
    option is unchanged, so the code that reads them didn't change.
  - **Defaults**: every option starts as the original game played
    (`InitOptions`): MEDIUM text, animations on, SHIFT, mono, 30 frames a
    second (60 was the default on the Game Boy Color), trainers that don't
    switch with thought (the old default was smart switching), and every
    extra off. COLOR FIX is off too: the Japanese builds used to start
    with it on; SELECT at the copyright screen still turns it on, and the
    save keeps the choice.
  - **NEW GAME** still carries the options that are event flags over the
    event-flag wipe (`SaveRuleFlags`/`RestoreRuleFlags`, now from a plain
    list of flags, `RuleFlags`).
  - `tests/test_options.py`: the defaults as each option shows them on
    every page, every explanation fits its box, text speed and RANDOM
    WILD's values, bit options, the level cap's value, and the rule flags
    surviving NEW GAME.
- **PC IN MENU** (EXTRAS, off by default; `EVENT_PC_IN_MENU`, the unused
  $8CC): the start menu gets a PC item after ITEM that opens the whole PC
  (Bill's or someone's, the player's, Oak's, the League's and the printer)
  as a Pokémon Center's does, and returns to the start menu after LOG OFF.
  It is hidden in the link rooms.
  - The start menu's items are no longer fixed: `DrawStartMenu` counts them
    (`StartMenuItemCount`: six, the Pokédex, the PC) into `wMaxMenuItem`
    and sizes the box to fit (eight items fill the screen's height). The
    home bank's wrap-around reads `wMaxMenuItem` instead of checking the
    Pokédex, and it asks the far routine `StartMenuChoice` which item was
    chosen; the PC runs inside it. The home bank came out smaller.
    `SoftlockTeleport`'s check for EXIT reads `wMaxMenuItem` too.
  - `draw_start_menu.asm` moved out of bank 1 to a floating section.
  - `tests/test_start_menu_pc.py`: what each item does with and without
    the Pokédex and the option, and no PC in the link rooms.
- **TYPE HINT: OFF / ON / LEARNED** (DISPLAY, off by default, as the
  original game had no marks): the move menu's effectiveness marks
  (`engine/battle/type_chart.asm`). LEARNED shows a mark only for matchups
  the player has seen, and "?" for the rest.
  - **The chart**: `wTypeChartSeen` (46 bytes at the end of the saved main
    data) has a flag per attacking type and defending type, one way:
    19 x 19 (NORMAL to STEEL with BIRD's unused slot, then FIRE to FAIRY).
    NEW GAME clears it; NEW GAME+ keeps it, as it keeps the Pokédex.
  - **Recording**: `RecordTypeMatchup` marks the move's type against each
    of its target's types (a dual-type target counts as both matchups),
    for either side's moves, when an attacking move with ordinary damage
    (power 2 or more: no status moves, no fixed-damage ones) hits (the core
    calls `RecordAndDisplayEffectiveness` where it called
    `DisplayEffectiveness`) or doesn't affect its target by type
    (`PrintMoveFailureText`'s immune branch). A miss records nothing.
  - **Showing**: with LEARNED, the mark needs the move's type against both
    of the enemy's types to be seen.
  - The move menu's mark routine moved out of the full battle bank ($0F)
    into the new file.
  - `wSpriteOptions` is now `wDisplayOptions`: SPRITES in bit 0, TYPE HINT
    in bits 1-2.
  - `tests/test_type_chart.py`: dual types count both, direction, either
    side, status and fixed-damage moves don't count, each matchup's own
    bit, and the marks with OFF, ON and LEARNED. `test_move_menu_marks.py`
    runs with ON.
- **DEXREPEL** (key item `$97`, after the held items): a new PROF.OAK's
  aide upstairs in the Route 12 gate (with the TM39 girl; the binoculars
  are now text 3 and 4) gives it for 80 kinds caught, through the same
  `OaksAideScript` as the other aides (`EVENT_GOT_DEXREPEL`, $8CE). Used
  from the bag it turns on or off (`EVENT_DEXREPEL_ON`, $8CD; "not the
  time" in battle). On, a wild mon whose species is owned doesn't appear.
  - `TryDoWildEncounter` asks the far routine `WildRepelCheck`, which also
    does the REPEL's level check that used to be inline (bank 4 had 6 free
    bytes). As with the REPEL, a shiny still gets through, and fishing and
    fixed encounters are unaffected.
  - Using a held item from the bag, and TAKE, moved out of the full bank 3
    to `engine/items/held_item_use.asm`; `UseItem_` still sends every item
    from `FIRST_HELD_ITEM` up there, and the DEXREPEL is caught first.
  - `tests/test_dexrepel.py`: owned species kept away only while on, the
    REPEL still works, using it toggles (not in battle), and it's a key item
    in the key pocket.
- **EXP on catch** (Gen 6+): after "<mon> was caught!", `CaughtMonExperience`
  runs `GainExperience` as a defeat would: experience (with the Exp. Share
  rules and level-ups, move learning included) and the caught mon's EV
  yield for the party. Not in the Safari Zone, where none of the party
  battles, nor for the old man's catch. It keeps `wcf91` and `wd11e`, which
  the rest of the catch (the Pokédex, adding the mon) reads.
- **"Use another?"** (Gen 6+): when a repel wears off, `RepelWoreOff` (the
  far routine `DisplayRepelWoreOffText` now calls) offers another of the
  kind last used (`wLastRepelUsed`, set by `ItemUseRepelCommon`; not saved,
  as the repel's steps aren't) if the bag has one. YES uses it (its steps,
  one fewer in the bag, the bag's sound); otherwise the old text alone.
- `tests/test_qol_catch_repel.py`.
- **Status screen EVs** (bug): holding SELECT printed the EVs two columns
  left of the stats (left over from Shin's five-digit stat experience), so
  the nature's raised/lowered marks covered their middle digit (252 showed
  as 2▴2). They now line up with the stats.
- **README**: rewritten as a compact list of every change (this fork's, then
  Shin's, with what this fork replaced), credits and screenshots
  (`screenshots/fork/`); Shin's README is kept as `docs/shin_readme.md`.
- **Fixes and options (after the README)**:
  - Level-up text: a mon that didn't take part never printed "gained", so
    "grew to level" used whatever name `wcd6d` held (another mon's, or a
    move's). `LevelUpPokemon` now loads the mon's own name.
  - EXP on catch: `GainExperience` left `wWhichPokemon` at the party's end,
    so the ball (removed by its bag index) wasn't used up; and the thrown
    ball's sprite stayed over the level-up boxes. `CaughtMonExperience`
    keeps `wWhichPokemon` and clears the sprites first.
  - Shin's Pikachu SURF / Dragonite FLY secret marked the mon with catch
    rate 168, which is now the held item byte (an invalid item). The feats
    set `EVENT_SURFING_PIKACHU` / `EVENT_FLYING_DRAGONITE`, which unlock
    the move for the species (`SpecialMachineMove`).
  - Abilities that do nothing are gone: Sticky Hold is dropped, and a slot
    whose ability can't work gives way to the species' other ability, or
    to its hidden one if that works (`tools/gen_abilities.py`).
  - EXP. SHARE (GAME, off): on, Gen 9's always-on Exp. Share; off, only the
    mons that took part gain, or with EXP ALL in the bag the rest gain half
    (`RestOfTeamGainsExp`; `EVENT_EXP_SHARE_ON`, $8D1).
  - HP PERCENT (DISPLAY, off): the enemy HUD's "HP:" becomes a percentage
    in a 3x5 font drawn into tiles $D0-$D1 (kana slots, blank in the
    English font); the second keeps the bar's left end
    (`engine/battle/hp_percent.asm`).
  - Tests: `test_move_secret.py`, `test_hp_percent.py`, and the share on and
    off in `test_growth.py`.

