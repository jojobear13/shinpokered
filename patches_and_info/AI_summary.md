
#Shin Pokemon Summary of AI Trainer Logic


Every trainer class has a number of interchangeable AI layers assigned in order to determine how moves are chosen.
These are also called AIMoveChoiceModification functions.
Here we can see how some of these layers are assigned.

0 - This is a terminator value.
1 - Makes the trainer avoid dumb things like using sleep moves on a sleeping target.
2 - The trainer will attempt to use a buffing move on the first turn after it sends out a new pokemon.
3 - Applies more advanced strategy that includes type-matchups and STAB.
4 - Not directly involved with moves. The trainer will evaluate if it should switch its active pokemon.

		TrainerClassMoveChoiceModifications:
			db 0      ; YOUNGSTER
			db 1,0    ; BUG CATCHER
			db 1,0    ; LASS
			db 1,3,0  ; SAILOR
			db 1,3,4,0    ; JR_TRAINER_M
			db 1,3,4,0    ; JR_TRAINER_F
			db 1,2,3,4,0; POKEMANIAC
			db 1,2,0  ; SUPER_NERD
			db 1,4,0    ; HIKER

The Youngster trainer class has no AI. 
Lass trainers are more experienced and will try not to spam or do stupid things.
Super Nerds are like the Lassies, but they prefer buffing when sending out a pokemon.
Hikers will try to avoid silly mistakes, but they also will think about switching if caught in a pinch.
Sailors are somewhat seasoned as they will try to utilize super-effective moves.
The Jr. Trainers don't mess around as they try to use decent strategy and consider switches.

All moves of the active enemy pokemon start with a preference score of 10.
For each move, all assigned AI layers get run on it (except Layer 4). Each AI layer adjusts the preference score.
Decreasing the score encourages the move.
Increasing the score discourages the move.
Once all moves have finished running through the AI layers, the move with the lowest score is chosen.
In case of ties, a move is randomly chosen from among the tied moves.

AIMoveChoiceModification1
- Discourages Spash.
- Discourages moves like Roar and Teleport that don't do anything in trainer battles.
- Discourages Rage.
- Encourages Dream Eater if opponent is asleep, otherwise discourages it.
- Encourages or discourages Counter depending on if it is applicable.
- Discourages moves that would do nothing if the player has a Substitute out.
- Discourages healing or exploding at high HP, and encourages it at low HP.
- Random chance to discourage 2-turn moves like Skull Bash and Dig if confused or paralyzed.
- Discourage the use of fly or dig if a slower opponent is also using a fly/dig effect to avoid missing.
- Do not use Haze if the user has no status conditions or has neutral stat mods.
- Do not use Disable on an opponent already Disabled.
- Do not use Substitute if there is not enough HP remaining.
- Do not use moves that would end up getting blocked by an active Mist.
- Do not use Defense-boosting moves if the player is attacking with something that ignores Defense.
- Do not use Light Screen if the player is attacking with something that ignores Special.
- Heavily discourage stat-modifying moves if it would hit the mod limit and be ineffective.
- Heavily discourage moves that do not stack with themselves, such as Focus Energy and Leech Seed.
- Discourage Confusion-only moves (such as Supersonic)on an already-confused opponent.
- Do not use a status-only move against a target that already has a non-volatile status condition.
- Dissuade from using non-damaging moves multiple turns in a row to prevent useless spamming.
- Blind the AI to the player using a restorative item or switching so the AI doesn't reapply a status condition every time.

AIMoveChoiceModification2
- On the first turn after sending a pokemon out, encourage any buffing moves.

AIMoveChoiceModification3
- This AI layer is skipped if the player switched pokemon to prevent the AI from perfectly predicting switch-ins.
- Don't use poison-effect moves on poison-tpe pokemon.
- If faster than a player pokemon that is in the fly/dig state, discourage using moves that will just miss.
- Do not use moves that are ineffective against the target's type.
- Do not use OHKO moves if the target is faster since it will always miss (exception made for X-Accuracy condition).
- Discourage moves that are not very effective.
- If target is not immune, static damage moves (like Super Fang) ignore typing and have a slight chance to be preferenced.
- Neutral-hitting moves have a random chance to be preferenced if they get STAB.
- Random chance to discourage using physical moves if user's Special is higher than Attack.
- Random chance to discourage using special moves if user's Attack is higher than Special.
- Encourages moves that are super effective.
- Discourage moves that are not very effective.

AIMoveChoiceModification4
This has less to do with moves and determines if the AI trainer has a chance of switching pokemon.
- The function ScoreAIParty is run first. If the active pokemon is scored the best option, then no switch can occur.
- An active pokemon with less than 25% HP remaining will not be switched out as it tends to be a useless gesture.
- 34% chance to switch if afflicted with Toxic poison.
- 25% chance to switch if stuck in a trapping move like Wrap.
- 25% chance to switch if confused.
- 12.5% chance to switch if afflicted with a sleep counter > 3.
- 12.5% chance to switch out of Leech Seed.
- 12.5% chance to switch out of Disable.
- A scaling chance to switch out of reduced stat mods.
- A scaling chance to switch out when faced with an incoming super-effective move.
- Except for all of the above, do not switch if the AI trainer's active pokemon was flagged (explained later).
- 25% chance to switch if afflicted with paralysis, regular poison, burn, or freeze.

When an AI trainer sends out a pokemon, that pokemon gets 'flagged' as being the best choice (except at the start of a battle).
Flagged pokemon will generally not be switched out unless there is some game state that otherwise prompts it.
This prevents the AI trainer from pointlessly switching back and forth.
Unless it's the Juggler class. Jugglers will randomly switch 25% of the time because they 'juggle' pokemon.
The flag will be cleared anytime the player sends out a new pokemon since now the situation has changed.

ScoreAIParty performs the vital function of assigning a score to all of the AI trainer's pokemon.
When switching, the trainer will send out the pokemon with the highest score (randomly picking among tied pokemon).
This score is also used for determining which new pokemon to send out after suffering a K.O.
Opposite for how moves are treated, a higher score is considered 'better'.
All pokemon start with a score of 160. The score can go up to 255. The lowest score typically used is 15.
Scoring is as follows:
- If a pokemon has fainted, set its score to 15.
- +2 score if faster than current opponent.
- +2 score if at full hp.
- A -1 score if less than 3/4 hp.
- Additional -2 score if less than 1/2 hp.
- Another additional -2 score if less than 1/4 hp.
- -5 for a having a sleep counter > 1.
- -2 if burned, paralyzed, or poisoned.
- -10 if frozen.
- Adjust score based on the effectiveness of the active player pokemon's moves.
  - +15 for a move to which there is an immunity.
  - +10 for a 1/4 not very effective move.
  - +5 for a 1/2 not very effective move.
  - For a move that is 2x super effective, subtract 25% of its base power from the score.
  - For a move that is 4x super effective, subtract 50% of its base power from the score.
- Score gets -15 if not currently the active pokemon and the player is not using a trapping move right now.
- Adjust score based on the effectiveness of the AI pokemon's moves.
  - -5 score if no moves are decently effective.
  - No score adjustment for a neutral move.
  - +2 score if there's a supereffective move that exists.
  - An additional +3 score (+5 total) if said supereffective move is 60 power or more.
- Apply a scaling penalty to score if the active opponent has a STAB move that would be super-effective.
