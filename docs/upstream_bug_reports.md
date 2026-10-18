# Bug reports for Shin Pokémon

Bugs found while refactoring this fork that also exist in upstream Shin
Pokémon (jojobear13/shinpokered). Each one is written so it can be filed as an
issue or turned into a pull request there. Nothing here has been filed yet.

## Enemy multi-hit moves use the player's level after the first hit

**Status:** fixed in this fork (`claude/practical-mayer-gyxrm5`, commit
"Fix enemy multi-hit moves using the player's level"). Present in upstream as
of commit `a7a9b13` ("Merge pull request #424").

**Symptom.** When the enemy uses a move that hits more than once (Double
Kick, Fury Attack, Pin Missile, Twineedle, Comet Punch and the like, including
one called by Metronome), every hit after the first is calculated with the
**player's** level instead of the enemy's. The player's level also feeds the
enemy's critical-hit stat calculation on those hits. A low-level enemy facing
a high-level player hits much harder than it should, and the reverse. Example
from testing: an enemy at level 24 against a player at level 79 dealt its
follow-up hits as if it were level 79.

**Cause.** In `engine/battle/core.asm`, the enemy's damage calculation used to
run with the two mons' levels swapped (`SwapPlayerAndEnemyLevels` at the
start of `EnemyCalcMoveDamage` and back on every way out), with a second swap
pair around `GetDamageVarsForEnemyAttack` to un-swap them for that one call.
The per-hit recalculation for multi-hit moves (the block in
`EnemyCheckIfMirrorMoveEffect` marked "multi-hit attacks like twineedle,
double-kick, and fury attack should check damage each time") copied that
inner pair:

```
	call CriticalHitTest
	call SwapPlayerAndEnemyLevels
	call GetDamageVarsForEnemyAttack
	call SwapPlayerAndEnemyLevels
	call CalculateDamage
```

But by the time this loop runs, the levels have already been swapped back, so
here the pair swaps them *into* the wrong state for `GetDamageVarsForEnemyAttack`,
which reads the attacker's level from `wEnemyMonLevel` (and, on a critical
hit, recomputes the enemy's unmodified stats through `GetEnemyMonStat`, which
also reads it).

**Fix (upstream).** Delete the two `call SwapPlayerAndEnemyLevels` lines in
that block. Nothing else changes: the player's version of the loop has no swap
pair, and every other path through the enemy's turn is unaffected.

**How it was found and checked.** An emulator test runs randomized whole
enemy turns. Removing the swap pairs changed exactly the turns that go through
the enemy multi-hit loop (51 of 2000 random enemy turns: 40 multi-hit moves,
10 turns continuing a multi-hit attack, 1 via Metronome) and no player turns.
A spec test (`tests/test_multi_hit.py` in this fork) runs the same enemy
Double Kick turn with identical random numbers at three player levels; before
the fix the player's remaining HP differed by level (for example 952, 927 and
900 HP at player levels 5, 50 and 100), after it they are identical.

## Enemy stays invulnerable when it can't act mid-Fly or mid-Dig

**Status:** fixed in this fork (`claude/practical-mayer-gyxrm5`, commit
"Fix the enemy staying invulnerable when it can't act mid-Fly or mid-Dig").
Present in upstream as of commit `a7a9b13`.

**Symptom.** If the enemy is fully paralyzed, or hurts itself in confusion,
on the turn it would come down from Fly or up from Dig, it stays
invulnerable: every move the player uses misses it until it completes a Fly
or Dig or switches out. This is the Gen 1 invulnerability glitch, which Shin
already fixed for the player's side.

**Cause.** `CheckPlayerStatusConditions` and `CheckEnemyStatusConditions`
(`engine/battle/core.asm`, the `.MonHurtItselfOrFullyParalysed` /
`.monHurtItselfOrFullyParalysed` blocks) clear the mon's multi-turn flags when
it can't act. The player's mask includes `1 << INVULNERABLE` (comment: "also
clear invulnerablility (fly/dig) to prevent invincibility glitch"); the
enemy's mask doesn't. `MoveHitTest` then treats the enemy as untouchable.

**Fix (upstream).** Add `(1 << INVULNERABLE)` to the enemy's mask:

```
	and $ff ^ ((1 << STORING_ENERGY) | (1 << THRASHING_ABOUT) | (1 << CHARGING_UP) | (1 << INVULNERABLE) | (1 << USING_TRAPPING_MOVE))
```

**How it was found and checked.** While merging the two status-check
routines, the masks differed. A spec test (`tests/test_invulnerability.py` in
this fork) puts each side mid-Fly, paralyzed, with random rolls that force
full paralysis; before the fix the enemy's `INVULNERABLE` flag stayed set in
10 of 10 runs (the player's in 0 of 10), after it neither side keeps it.
Against the previous build, the fix changed only 4 of 8000 random states,
all of them with the enemy starting out invulnerable.

## Accuracy and evasion changes re-apply every badge boost

**Status:** fixed in this fork (`claude/practical-mayer-gyxrm5`, commit
"Fix accuracy and evasion changes re-applying badge boosts"). Present in
upstream as of commit `a7a9b13`.

**Symptom.** Every time the player's accuracy or evasion stage changes, the
player's active Pokémon gets all its badge boosts again: attack, defense,
speed and special each grow by another 12.5%. Using Double Team or Minimize
repeatedly, or being hit by Sand-Attack, Smokescreen, Kinesis or Flash,
keeps inflating the player's stats for the rest of the time that mon is out.
Example from testing: with all badges, one Double Team took attack 100,
defense 120 and speed 140 to 112, 135 and 157.

**Cause.** Shin already fixed Gen 1's version of this bug, where any stat-up
move re-applied every badge boost. `StatModifierUpEffect` and
`StatModifierDownEffect` record which stat changed (`wUnusedD71B`, the stage
index + 1), and `ApplyBadgeStatBoosts` (`engine/battle/core.asm`,
`.selectiveBadgeBoost`) re-applies only that stat's boost. But for accuracy
and evasion (index + 1 of 5 or 6) it falls back to re-applying every boost:

```
	ld c, $5
	cp c
	ret nc 	;kick out if carry flag not set so the function will apply all normal badge boosts
```

Accuracy and evasion have no stat that gets recalculated, so no boost should
be re-applied at all.

**Fix (upstream).** Clear the badge bits in that case:

```
	ld c, $5
	cp c
	jr c, .selectOne
	ld b, 0 ; accuracy or evasion: no stat was recalculated, so there is no boost to reapply
	ret
.selectOne
```

**How it was found and checked.** While extending the badge boosts for a split
special stat, the accuracy/evasion branch stood out. A spec test
(`tests/test_badge_boosts.py` in this fork) runs whole turns of Double Team
by the player and Sand-Attack against it with every badge; before the fix the
player's stats rose 12.5% each time, after it they are unchanged. Against
the previous build, the fix changed 9 of 600 random whole turns, all of
them the player's evasion rising or accuracy falling.
