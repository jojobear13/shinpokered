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
