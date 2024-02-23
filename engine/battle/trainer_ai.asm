; creates a set of moves that may be used and returns its address in hl
; unused slots are filled with 0, all used slots may be chosen with equal probability
AIEnemyTrainerChooseMoves:
;joenote - let's make wild pokemon have some AI in choosing moves
	ld a, [wIsInBattle]
	dec a
	jr nz, .notwildbattle
	;wild battle confirmed at this point
	ld hl, wEnemyMonMoves	;restore this address which was clobbered by callba
	;ret z ; wild encounter	;uncomment this line to restore default wildmon behavior
	;but let's do a little something else
	;only do wildmon AI move choice for Mewtwo while in SET mode
	;after all, it is still a cunning foe even as a wild pokemon
	ld a, [wOptions]
	bit BIT_BATTLE_HARD, a ;check for hard mode
	ret z ;wild AI as normal in outside of hard mode
	ld a, [wEnemyMon]	
	cp MEWTWO
	ret nz
	;load the Sailor class since it only uses AI routines 1 and 3
	ld a, SAILOR
	ld [wTrainerClass], a
	;should be fine to let AIEnemyTrainerChooseMoves run at this point
.notwildbattle
	
	ld a, $a
	ld hl, wBuffer ; init temporary move selection array. Only the moves with the lowest numbers are chosen in the end
	ld [hli], a   ; move 1
	ld [hli], a   ; move 2
	ld [hli], a   ; move 3
	ld [hl], a    ; move 4

;joenote - make a backup buffer
	push hl
	ld a, $ff
	inc hl
	ld [hli], a	;backup 1
	ld [hli], a	;backup 2
	ld [hli], a	;backup 3
	ld [hl], a	;backup 4
	pop hl
	
	;joenote - backup the power of the last moved used
	ld a, [wEnemyMovePower]
	ld [wAILastMovePower], a
	
	ld a, [wEnemyDisabledMove] ; forbid disabled move (if any)
	swap a
	and $f
	jr z, .noMoveDisabled
	ld hl, wBuffer
	dec a
	ld c, a
	ld b, $0
	add hl, bc    ; advance pointer to forbidden move
	ld [hl], $50  ; forbid (highly discourage) disabled move
.noMoveDisabled
	ld hl, TrainerClassMoveChoiceModifications
	ld a, [wTrainerClass]
	ld b, a
.loopTrainerClasses
	dec b
	jr z, .readTrainerClassData
.loopTrainerClassData
	ld a, [hli]
	and a
	jr nz, .loopTrainerClassData
	jr .loopTrainerClasses
.readTrainerClassData
	ld a, [hl]
	and a
	jp z, .useOriginalMoveSet
	push hl
.nextMoveChoiceModification
	pop hl
	ld a, [hli]
	and a
	jr z, .loopFindMinimumEntries_bakupfirst
	push hl
	ld hl, AIMoveChoiceModificationFunctionPointers
	dec a
	add a
	ld c, a
	ld b, 0
	add hl, bc    ; skip to pointer
	ld a, [hli]   ; read pointer into hl
	ld h, [hl]
	ld l, a
	ld de, .nextMoveChoiceModification  ; set return address
	push de
	jp hl         ; execute modification function
.loopFindMinimumEntries_bakupfirst	;joenote - make a backup of the scores
	ld hl, wBuffer  ; temp move selection array
	ld de, wBuffer + NUM_MOVES  ;backup buffer
	ld bc, NUM_MOVES
	call CopyData
.loopFindMinimumEntries ; all entries will be decremented sequentially until one of them is zero
	ld hl, wBuffer  ; temp move selection array
	ld de, wEnemyMonMoves  ; enemy moves
	ld c, NUM_MOVES
.loopDecrementEntries
	ld a, [de]
	inc de
	and a
	jr z, .loopFindMinimumEntries
	dec [hl]
	jr z, .minimumEntriesFound
	inc hl
	dec c
	jr z, .loopFindMinimumEntries
	jr .loopDecrementEntries
.minimumEntriesFound
	ld a, c
.loopUndoPartialIteration ; undo last (partial) loop iteration
	inc [hl]
	dec hl
	inc a
	cp NUM_MOVES + 1
	jr nz, .loopUndoPartialIteration
	ld hl, wBuffer  ; temp move selection array
	ld de, wEnemyMonMoves  ; enemy moves
	ld c, NUM_MOVES
.filterMinimalEntries ; all minimal entries now have value 1. All other slots will be disabled (move set to 0)
	ld a, [de]
	and a
	jr nz, .moveExisting
	ld [hl], a
.moveExisting
	ld a, [hl]
	dec a
	jr z, .slotWithMinimalValue
	xor a
	ld [hli], a     ; disable move slot
	jr .next
.slotWithMinimalValue
	ld a, [de]
	ld [hli], a     ; enable move slot
.next
	inc de
	dec c
	jr nz, .filterMinimalEntries
	ld hl, wBuffer    ; use created temporary array as move set
	ret
.useOriginalMoveSet
	ld hl, wEnemyMonMoves    ; use original move set
	ret

AIMoveChoiceModificationFunctionPointers:
	dw AIMoveChoiceModification1
	dw AIMoveChoiceModification2
	dw AIMoveChoiceModification3
	dw AIMoveChoiceModification4 ; ;joenote - repurposed unused routine for trainer switching

; discourages moves that cause no damage but only a status ailment if player's mon already has one
; joenote - reworked so that it now discourages doing things that are generally useless
AIMoveChoiceModification1:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - kick out if no-attack bit is set
	ld a, [wUnusedC000]
	bit 2, a
	ret nz
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [wBattleMonStatus]
	and a
	;joenote - don't return yet. going to check for dream eater. will do this later
	;ret z ; return if no status ailment on player's mon
	ld hl, wBuffer - 1 ; temp move selection array (-1 byte offset)
	ld de, wEnemyMonMoves ; enemy moves
	ld b, NUM_MOVES + 1
.nextMove
	dec b
	ret z ; processed all 4 moves
	inc hl
	ld a, [de]
	and a
	ret z ; no more moves in move set
	inc de
	call ReadMove
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use effects that end battle because this is a trainer battle and they do not work
	ld a, [wEnemyMoveEffect]	;load the move effect
	cp SWITCH_AND_TELEPORT_EFFECT	;see if it is a battle-ending effect
	jp z, .heavydiscourage	;heavily discourage if so
;and dont try to use splash either
	cp SPLASH_EFFECT	
	jp z, .heavydiscourage
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use dream eater if enemy not asleep, otherwise encourage it
	ld a, [wEnemyMoveEffect]	;load the move effect
	cp DREAM_EATER_EFFECT	;see if it is dream eater
	jr nz, .notdreameater	;skip out if move is not dream eater
	ld a, [wActionResultOrTookBattleTurn]
	and a
	jp nz, .nextMove	;if player switched or used an item, AI should be blind to the change
	ld a, [wBattleMonStatus]	;load the player pkmn non-volatile status
	and $7	;check bits 0 to 2 for sleeping turns
	jp z, .heavydiscourage	;heavily discourage using dream eater on non-sleeping pkmn
	dec [hl]	;else slightly encourage dream eater's use on a sleeping pkmn
	jp .nextMove
.notdreameater	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use counter against a non-applicable move
	ld a, [wEnemyMoveNum]	
	cp COUNTER
	jr nz, .countercheck_end	;if this move is not counter then jump out
	ld a, [wPlayerMovePower]
	and a
	jp z, .heavydiscourage	;heavily discourage counter if enemy is using zero-power move
	ld a, [wPlayerMoveType]
	cp NORMAL
	jr z, .countercheck_end	; continue on if countering a normal move
	cp FIGHTING
	jr z, .countercheck_end	; continue on if countering a fighting move
	cp BIRD
	jr z, .countercheck_end	; continue on if countering STRUGGLE or other typeless move
	jp .heavydiscourage	;else heavily discourage since the player move type is not applicable to counter
.countercheck_end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use moves that are ineffective against substitute if a substitute is up
	ld a, [wPlayerBattleStatus2]
	bit HAS_SUBSTITUTE_UP, a	;check for substitute bit
	jr z, .noSubImm	;if the substitute bit is not set, then skip out of this block
	ld a, [wEnemyMoveEffect]	;get the move effect into a
	push hl
	push de
	push bc
	ld hl, SubstituteImmuneEffects
	ld de, $0001
	call IsInArray	;see if a is found in the hl array (carry flag set if true)
	pop bc
	pop de
	pop hl
	jp c, .heavydiscourage	;carry flag means the move effect is blocked by substitute
	;else continue onward
.noSubImm	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Heavily discourage healing or exploding moves if HP is full. Encourage if hp is low
;Exploding has a slight preference over healing because overall this hurts the player more than the AI
	ld a, [wEnemyMoveEffect]	;load the move effect
	cp HEAL_EFFECT	;see if it is a healing move
	jr z, .heal_explode	;skip out if move is not
	cp EXPLODE_EFFECT	;what about an explosion effect?
	jr nz, .not_heal_explode	;skip out if move is not
	dec [hl]	;otherwise give a slight edge to exploding
	
	;since this is an explosion effect, it would be good to heavily discourage if
	;the opponent is in fly/dig state and the exploder is for-sure faster than the opponent
	ld a, [wPlayerBattleStatus1]
	bit 6, a
	jr z, .heal_explode	;proceed as normal if player is not in fly/dig
	call StrCmpSpeed	;do a speed compare
	jp c, .heavydiscourage	;a set carry bit means the ai 'mon is faster, so heavily discourage
	
.heal_explode
	ld a, 1	;
	call AICheckIfHPBelowFraction
	jp nc, .heavydiscourage	;heavy discourage if hp at max (heal +5 & explode +4)
	inc [hl]	;1/2 hp to max hp - slight discourage (heal +1 & explode 0)
	ld a, 2	;
	call AICheckIfHPBelowFraction
	jp nc, .nextMove	;if hp is 1/2 or more, get next move
	dec [hl]	;else 1/3 to 1/2 hp - neutral (heal 0 & explode -1)
	ld a, 3	;
	call AICheckIfHPBelowFraction
	jp nc, .nextMove	;if hp is 1/3 or more, get next move
	dec [hl]	;else 0 to 1/3 hp - slight preference (heal -1 & explode -2)
	jp .nextMove	;get next move
.not_heal_explode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Randomly discourage 2-turn moves if confused or paralyzed
	;check for 2-turn move
	ld a, [wEnemyMoveEffect]
	cp FLY_EFFECT
	jr z, .twoturncheck_par
	cp CHARGE_EFFECT
	jr nz, .twoturndone
	
.twoturncheck_par
	;handle paralysis
	ld a, [wEnemyMonStatus]
	bit PAR, a
	jr z, .twoturncheck_confused
	call Random
	cp $70
	jr nc, .twoturncheck_confused
	inc [hl]	;random chance to discourage if paralyzed
	inc [hl]
	
.twoturncheck_confused
	;handle confusion
	ld a, [wEnemyBattleStatus1]
	bit 7, a ;check confusion bit
	jr z, .twoturndone
	call Random
	cp $C0
	jr nc, .twoturndone
	inc [hl]	;random chance to discourage if confused
	inc [hl]
	
.twoturndone
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - discourage the use of fly or dig if a slower player is doing the same
; this is because the faster 'mon always misses if both decide to use fly/dig
	ld a, [wEnemyMoveNum]
	call IsDigOrFly
	jr nz, .end_bothusedigorfly
	ld a, [wPlayerMoveNum]
	call IsDigOrFly
	jr nz, .end_bothusedigorfly
	ld a, [wPlayerBattleStatus1]
	bit 6, a
	jr nz, .end_bothusedigorfly	;player is already in dig/fly invulnerability if nz, so move on
	call StrCmpSpeed
	jr z, .end_bothusedigorfly	;speeds equal if z, so move on
	jr c, .end_bothusedigorfly	;speed is less than player if carry, so move on
	;else AI is faster than player
	;discourage because AI will miss and player will hit
	inc [hl]
	inc [hl]
.end_bothusedigorfly
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [wEnemyMovePower]
	and a
	jp nz, .nextMove	;go to next move if the current move is not zero-power
;At this line onward all moves are assumed to be zero power
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use haze if user has no status or neutral stat mods
	ld a, [wEnemyMoveEffect]	;load the move effect
	cp HAZE_EFFECT	;see if it is haze
	jp nz, .hazekickout	;move on if not haze
;using haze at this point
	ld a, [wEnemyMonStatus]	;get status
	and a
	jp z, .heavydiscourage	;discourage if status is clear
	push hl
	push bc
	xor a
	ld b, 6
	ld hl, wEnemyMonStatMods
.hazeloop
	add [hl]
	inc hl
	dec b
	jr nz, .hazeloop
	pop bc
	pop hl
	cp 42
	jp nc, .heavydiscourage	;discourage if summed stat mods are same or more than 42 (7 per mod is neutral)
.hazekickout
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use disable on a pkmn that is already disabled
	ld a, [wEnemyMoveEffect]	;load the move effect
	cp DISABLE_EFFECT
	jr nz, .notdisable
	ld a, [wPlayerDisabledMove]	
	and a
	jp nz, .heavydiscourage	
.notdisable
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use substitute if not enough hp
	ld a, [wEnemyMoveEffect]
	cp SUBSTITUTE_EFFECT
	jr nz, .notsubstitute
	ld a, 4	;
	call AICheckIfHPBelowFraction
	jp c, .heavydiscourage
.notsubstitute
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use moves that are blocked by mist
	ld a, [wPlayerBattleStatus2]
	bit PROTECTED_BY_MIST, a	;check for mist bit
	jr z, .noMistImm	;if the mist bit is not set, then skip out of this block
	ld a, [wEnemyMoveEffect]	;get the move effect into a
	push hl
	push de
	push bc
	ld hl, MistBlockEffects
	ld de, $0001
	call IsInArray	;see if a is found in the hl array (carry flag set if true)
	pop bc
	pop de
	pop hl
	jp c, .heavydiscourage	;carry flag means the move effect is blocked by mist
	;else continue onward
.noMistImm	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use defense-up moves if opponent is special attacking
	ld a, [wEnemyMoveEffect]	;get the move effect
	cp DEFENSE_UP1_EFFECT	
	jr z, .do_def_check
	cp DEFENSE_UP2_EFFECT
	jr nz, .nodefupmove
.do_def_check
	ld a, [wPlayerMoveEffect]
	cp SPECIAL_DAMAGE_EFFECT
	jp z, .heavydiscourage	;don't bother boosting def against static damage attacks
	cp OHKO_EFFECT
	jp z, .heavydiscourage	;don't bother boosting def against OHKO attacks
	ld a, [wPlayerMovePower]	;all regular damage moves have a power of at least 10
	cp 10
	jr c, .nodefupmove
	ld a, [wPlayerMoveType]	;physical move types are numbers $00 to $08 while special is $14 to $1A
	cp $14
	jp nc, .heavydiscourage	;at this point, heavy discourage defense-boosting because player is using a special move of 10+ power
.nodefupmove
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - heavily discourage stat modifying moves if it would hit the mod limit and be ineffective
	;check for stat down effects
	ld a, [wEnemyMoveEffect]	;get the move effect
	cp ATTACK_DOWN1_EFFECT	
	jr c, .nostatdownmod	;if value is < the ATTACK_DOWN1_EFFECT value, jump out
	cp EVASION_DOWN2_EFFECT	+ $1
	jr nc, .nostatdownmod	;if value >= EVASION_DOWN2_EFFECT value + $1, jump out
	cp EVASION_DOWN1_EFFECT	+ $1
	jr c, .statdownmod	;if value < EVASION_DOWN1_EFFECT value + $1, there is a stat down move
	cp ATTACK_DOWN2_EFFECT	
	jr nc, .statdownmod	;if value is >= the ATTACK_DOWN2_EFFECT value, there is a stat down move
	jr .nostatdownmod; else the effect is something else in-between the target values
.statdownmod
	sub ATTACK_DOWN1_EFFECT	;normalize the effects from 0 to 5 to get an offset
	cp EVASION_DOWN1_EFFECT + $1 - ATTACK_DOWN1_EFFECT ; covers all -1 effects
	jr c, .statdowncheck
	sub ATTACK_DOWN2_EFFECT - ATTACK_DOWN1_EFFECT ; map -2 effects to corresponding -1 effect
.statdowncheck	
	push hl
	push bc
	ld hl, wPlayerMonStatMods	;load the player's stat mods
	ld c, a
	ld b, $0
	add hl, bc	;use offset to shift to the correct stat mod
	ld b, [hl]
	dec b ; decrement corresponding stat mod
	pop bc
	pop hl
	jr nz, .endstatmod ; if stat mod was > 1 before decrementing, then it's fine to lower
	;else can't be lowered anymore
	jp .heavydiscourage
.nostatdownmod
	;check for stat up effects
	ld a, [wEnemyMoveEffect]	;get the move effect
	cp ATTACK_UP1_EFFECT
	jr c, .endstatmod	;if value is < the ATTACK_UP1_EFFECT value, jump out
	cp EVASION_UP2_EFFECT + $1
	jr nc, .endstatmod	;if value >= EVASION_UP2_EFFECT value + $1, jump out
	cp EVASION_UP1_EFFECT + $1
	jr c, .statupmod	;if value < EVASION_UP1_EFFECT value + $1, there is a stat up move
	cp ATTACK_UP2_EFFECT	
	jr nc, .statupmod	;if value is >= the ATTACK_UP2_EFFECT value, there is a stat up move
	jr .endstatmod; else the effect is something else in-between the target values
.statupmod
	sub ATTACK_UP1_EFFECT	;normalize the effects from 0 to 5 to get an offset
	cp EVASION_UP1_EFFECT + $1 - ATTACK_UP1_EFFECT ; covers all +1 effects
	jr c, .statupcheck
	sub ATTACK_UP2_EFFECT - ATTACK_UP1_EFFECT ; map +2 effects to corresponding +1 effect
.statupcheck	
	push hl
	push bc
	ld hl, wEnemyMonStatMods	;load the enemy's stat mods
	ld c, a
	ld b, $0
	add hl, bc	;use offset to shift to the correct stat mod
	ld b, [hl]
	inc b ; increment corresponding stat mod
	ld a, $0d
	cp b ; can't raise stat past +6 ($0d or 13)
	pop bc
	pop hl
	jr nc, .endstatmod ; if stat mod was < $0d before incrementing, then it's fine to raise
	;else can't be raised anymore
	jp .heavydiscourage
.endstatmod
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - heavily discourage moves that do not stack
	;check each of the stackabe effects one by one and jump to the corresponding section
	ld a, [wEnemyMoveEffect]
	cp FOCUS_ENERGY_EFFECT
	jr z, .checkfocus
	cp LIGHT_SCREEN_EFFECT
	jr z, .checkscreen
	cp REFLECT_EFFECT
	jr z, .checkreflect
	cp SUBSTITUTE_EFFECT
	jr z, .checksub
	cp MIST_EFFECT
	jr z, .checkmist
	cp LEECH_SEED_EFFECT
	jr z, .checkseed
	jr .endstacking
.checkfocus	;check status, and heavily discourage if bit is set
	ld a, [wEnemyBattleStatus2]
	bit GETTING_PUMPED, a
	jp nz, .heavydiscourage
	jr .endstacking
.checkscreen ;check status, and heavily discourage if bit is set
	ld a, [wEnemyBattleStatus3]
	bit HAS_LIGHT_SCREEN_UP, a
	jp nz, .heavydiscourage
	jr .endstacking
.checkreflect	;check status, and heavily discourage if bit is set
	ld a, [wEnemyBattleStatus3]
	bit HAS_REFLECT_UP, a
	jp nz, .heavydiscourage
	jr .endstacking
.checkmist	;check status, and heavily discourage if bit is set
	ld a, [wEnemyBattleStatus2]
	bit PROTECTED_BY_MIST, a
	jp nz, .heavydiscourage
	jr .endstacking
.checksub	;check status, and heavily discourage if bit is set
	ld a, [wEnemyBattleStatus2]
	bit HAS_SUBSTITUTE_UP, a
	jp nz, .heavydiscourage
	jr .endstacking
.checkseed
	;first check to make sure leech seed isn't used on a grass pokemon
	push bc
	push hl
	ld hl, wBattleMonType
	ld b, [hl]                 ; b = type 1 of player's pokemon
	inc hl
	ld c, [hl]                 ; c = type 2 of player's pokemon
	ld a, b		;load type 1 into a
	cp GRASS	;is type 1 grass?
	jr z, .seedgrasstest	;skip ahead if type1 is grass
	ld a, c		;load type 2 into a
.seedgrasstest
	pop hl
	pop bc
	cp GRASS	;a is either type 1 grass or it is type 2 yet to be confirmed
	jp z, .heavydiscourage	;heavily discourage if either of the types are grass
	;else, not to make sure it isn't already used
	;check status, and heavily discourage if bit is set
	ld a, [wPlayerBattleStatus2]
	bit SEEDED, a
	jp nz, .heavydiscourage
.endstacking
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - discourage using confuse-only moves on confused pkmn
	ld a, [wEnemyMoveEffect]
	cp CONFUSION_EFFECT	;see if the move has a confusion effect
	jr nz, .notconfuse	;skip out if move is not a zero-power confusion move
	ld a, [wPlayerBattleStatus1]	;load the player pkmn volatile status
	and $80	;check bit 7 for confusion bit
	jp nz, .heavydiscourage	;heavily discourage using zero-power confusion moves on confused pkmn
.notconfuse
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;don't use a status move against a status'd target
	ld a, [wEnemyMoveEffect]
	push hl
	push de
	push bc
	ld hl, StatusAilmentMoveEffects
	ld de, $0001
	call IsInArray
	pop bc
	pop de
	pop hl
	jr nc, .nostatusconflict
	ld a, [wBattleMonStatus]
	and a
	jr nz, .heavydiscourage
.nostatusconflict
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote: fix spamming of buff/debuff moves
	;See if the move has an effect that should not be dissuaded
	ld a, [wEnemyMoveEffect]
	push hl
	push de
	push bc
	ld hl, EffectsToNotDissuade
	ld de, $0001
	call IsInArray
	pop bc
	pop de
	pop hl
	jr nc, .spamprotection	;If not found on list, run anti-spam on it
	;if it is in the list, has only a chance of anti-spam being run on it

;let's try to blind the AI a bit so that it won't just status the player immediately after using
;a restorative item or switching
	;effect found on list of spam-exempt moves, is this a status move (includes status-like effects)?
	ld a, [wEnemyMoveEffect]
	push hl
	push de
	push bc
	ld hl, StatusAilmentMoveEffectsExtended
	ld de, $0001
	call IsInArray
	pop bc
	pop de
	pop hl
	jr nc, .skipoutspam	;skip if not in the list of status effects (it's healing or a substitute or something)
	
	;effect is a status move, did the player use an item or switch?
	ld a, [wActionResultOrTookBattleTurn]
	and a
	jr z, .skipoutspam	;skip if player did not use an item or switch
	
	;79.68% chance per move that the AI is blind to the fact that the player switched or used an item
	;with three status moves on an AI mon, this works out to ~50% chance overall
	call Random
	cp 204
	jr nc, .skipoutspam	; if >= 204, proceed as normal
	;else run spam protection on the status move to simulate not predicting the player
	
.spamprotection
;heavily discourage 0 BP moves if health is below 1/3 max
	ld a, 3
	call AICheckIfHPBelowFraction
	jp c, .heavydiscourage
;heavily discourage 0 BP moves if one was used just previously
	ld a, [wAILastMovePower]
	and a
	jp z, .heavydiscourage
;else apply a random bias to the 0 bp move we are on
	call Random	
;outcome desired: 	50% chance to heavily discourage and would rather do damage
;					12.5% chance to slightly encourage
;					else neither encourage nor discourage
	cp 128	;don't set carry flag if number is >= this value
	jp nc, .heavydiscourage	
	cp 32
	jp c, .givepref	;if not discouraged, then there is a chance to slightly encourage to spice things up
	;else neither encourage nor discourage
.skipoutspam
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - end of this AI layer
	jp .nextMove
.heavydiscourage
	ld a, [hl]
	add $5 ; heavily discourage move
	ld [hl], a
	jp .nextMove
.givepref	;joenote - added marker
	dec [hl] ; slightly encourage this move
	jp .nextMove

EffectsToNotDissuade:
	db HEAL_EFFECT
	db SUBSTITUTE_EFFECT
	;fall through
StatusAilmentMoveEffectsExtended:
	db CONFUSION_EFFECT
	db LEECH_SEED_EFFECT
	db DISABLE_EFFECT
	;fall through
StatusAilmentMoveEffects:
	db $01 ; unused sleep effect
	db SLEEP_EFFECT
	db POISON_EFFECT
	db PARALYZE_EFFECT
	db $FF

SubstituteImmuneEffects:	;joenote - added this table to track for substitute immunities
	db $01 ; unused sleep effect
	db SLEEP_EFFECT
	db POISON_EFFECT
	db PARALYZE_EFFECT
	db CONFUSION_EFFECT
	db DRAIN_HP_EFFECT
	db LEECH_SEED_EFFECT
	db DREAM_EATER_EFFECT
	;fall through
MistBlockEffects:	;joenote - added this table to track for things blocked by mist
	db ATTACK_DOWN1_EFFECT
	db DEFENSE_DOWN1_EFFECT
	db SPEED_DOWN1_EFFECT
	db SPECIAL_DOWN1_EFFECT
	db ACCURACY_DOWN1_EFFECT
	db EVASION_DOWN1_EFFECT
	db ATTACK_DOWN2_EFFECT
	db DEFENSE_DOWN2_EFFECT
	db SPEED_DOWN2_EFFECT
	db SPECIAL_DOWN2_EFFECT
	db ACCURACY_DOWN2_EFFECT
	db EVASION_DOWN2_EFFECT
	db $FF

SpecialZeroBPMoves:	;joenote - added this table to tracks 0 bp moves that should not be treated as buffs
	db BIDE
	db METRONOME
	db THUNDER_WAVE
	db $FF
	
OtherZeroBPEffects:	;joenote - added to keep track of some outliers
	db LEECH_SEED_EFFECT
	db DISABLE_EFFECT
	db CONFUSION_EFFECT
	db $FF

; slightly encourage moves with specific effects.
; in particular, stat-modifying moves and other move effects
; that fall in-between
AIMoveChoiceModification2:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - kick out if no-attack bit is set
	ld a, [wUnusedC000]
	bit 2, a
	ret nz
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [wAILayer2Encouragement]
	and a ;cp $1	;joenote - AI layer 2 should activate on 1st turn instead of 2nd turn after sendout
	ret nz
	ld hl, wBuffer - 1 ; temp move selection array (-1 byte offset)
	ld de, wEnemyMonMoves ; enemy moves
	ld b, NUM_MOVES + 1
.nextMove
	dec b
	ret z ; processed all 4 moves
	inc hl
	ld a, [de]
	and a
	ret z ; no more moves in move set
	inc de
	call ReadMove
	ld a, [wEnemyMoveEffect]
	cp ATTACK_UP1_EFFECT
	jr c, .nextMove
	cp BIDE_EFFECT
	jr c, .preferMove
	cp ATTACK_UP2_EFFECT
	jr c, .nextMove
	cp POISON_EFFECT
	jr c, .preferMove
	jr .nextMove
.preferMove
	dec [hl] ; slightly encourage this move
	jr .nextMove

; encourages moves that are effective against the player's mon (even if non-damaging).
; discourage damaging moves that are ineffective or not very effective against the player's mon,
; unless there's no damaging move that deals at least neutral damage
; joenote - updated to also do some more advanced battle strategies
AIMoveChoiceModification3:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - kick out if no-attack bit is set
	ld a, [wUnusedC000]
	bit 2, a
	ret nz
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, wBuffer - 1 ; temp move selection array (-1 byte offset)
	ld de, wEnemyMonMoves ; enemy moves
	ld b, NUM_MOVES + 1
.nextMove
	dec b
	ret z ; processed all 4 moves
	inc hl
	ld a, [de]
	and a
	ret z ; no more moves in move set
	inc de
	call ReadMove
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;don't use poison-effect moves on poison-tpe pokemon
	ld a, [wEnemyMoveEffect]
	cp POISON_EFFECT
	jr nz, .notpoisoneffect
	ld a, [wActionResultOrTookBattleTurn]
	cp $A
	jp z, .notpoisoneffect	;if player switched, the AI does not get to know the typing of the 'mon switched-in
	ld a, [wBattleMonType]
	cp POISON
	jp z, .heavydiscourage2
	ld a, [wBattleMonType + 1]
	cp POISON
	jp z, .heavydiscourage2
.notpoisoneffect
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;slightly discourage using most offensive moves against fly/dig opponent if faster than opponent
	ld a, [wPlayerBattleStatus1]
	bit 6, a
	jr z, .endflydigcheck	;proceed as normal if player is not in fly/dig
	
	call StrCmpSpeed	;do a speed compare
	jr c, .flydigcheck_faster	;a set carry bit means the ai 'mon is faster
	ld a, [wEnemyMoveNum]
	cp QUICK_ATTACK
	jr z, .flydigcheck_faster

.flydigcheck_notfaster
	jr .endflydigcheck

.flydigcheck_faster
	;slightly discourage stuff that will just miss
	ld a, [wEnemyMoveEffect]
	push hl
	push de
	push bc
	ld hl, MistBlockEffects
	ld de, $0001
	call IsInArray
	pop bc
	pop de
	pop hl
	jr c, .flydigcheck_discourage

	ld a, [wEnemyMoveEffect]
	push hl
	push de
	push bc
	ld hl, StatusAilmentMoveEffects
	ld de, $0001
	call IsInArray
	pop bc
	pop de
	pop hl
	jr c, .flydigcheck_discourage

	ld a, [wEnemyMoveEffect]
	push hl
	push de
	push bc
	ld hl, OtherZeroBPEffects
	ld de, $0001
	call IsInArray
	pop bc
	pop de
	pop hl
	jr c, .flydigcheck_discourage

	ld a, [wEnemyMovePower]
	and a
	jr z, .endflydigcheck

	ld a, [wEnemyMoveEffect]
	cp FLY_EFFECT
	jr z, .endflydigcheck
	cp CHARGE_EFFECT
	jr z, .endflydigcheck
	
.flydigcheck_discourage
	inc [hl]
.endflydigcheck
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;check on certain moves with zero bp but are handled differently
	ld a, [wEnemyMoveNum]
	push hl
	push de
	push bc
	ld hl, SpecialZeroBPMoves
	ld de, $0001
	call IsInArray	;see if a is found in the hl array (carry flag set if true)
	pop bc
	pop de
	pop hl
	jp c, .specialBPend	;If found on list, treat it as if it were a damaging move

	;otherise only handle moves that deal damage from here on out
	ld a, [wEnemyMovePower]
	and a
	jp z, .nextMove	;go to next move if the current move is zero-power
.specialBPend
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;90.625% chance per move that AI is blind to the player switching, so treat the move as neutrally effective
	ld a, [wActionResultOrTookBattleTurn]
	cp $A
	jr nz, .blind_end
	call Random
	cp 232
	jr c, .neutral_effective	; if <, treat move as neutral damage
	;else proceed as normal
.blind_end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - heavily discourage attack moves that have no effect due to typing
	push hl
	push bc
	push de
	;reset type-effectiveness bit before calling function
	ld a, [wUnusedC000]
	res 3, a 
	ld [wUnusedC000], a
	callab AIGetTypeEffectiveness
	pop de
	pop bc
	pop hl

	ld a, [wTypeEffectiveness]	;get the effectiveness
	and a 	;check if it's zero
	jr nz, .skipout2	;skip if it's not immune
.heavydiscourage2	;at this line the move has no effect due to immunity or other circumstance
;heavily discourage move
	inc [hl]
	inc [hl]
	inc [hl]
	inc [hl]
.lightlydiscourage
	inc [hl]
	jp .nextMove
.skipout2
	;if thunder wave is being used against a non-immune target, neither encourage nor discourage it
	ld a, [wEnemyMoveNum]
	cp THUNDER_WAVE
	jp z, .nextMove
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not use ohko moves on faster opponents, since they will auto-miss
	ld a, [wEnemyMoveEffect]	;load the move effect
	cp OHKO_EFFECT	;see if it is ohko move
	jr nz, .skipout3	;skip ahead if not ohko move
	ld a, [wEnemyBattleStatus2]
	bit USING_X_ACCURACY, a
	jp nz, .nextMove	;X-accuracy is being used so ohko move viable
	call StrCmpSpeed	;do a speed compare
	jp c, .nextMove	;ai is fast enough so ohko move viable
	;else ai is slower so don't bother
	jp .heavydiscourage2
.skipout3	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote: static damage value moves should not be accounted for typing
;at the same time, randomly bump their preference to spice things up
	ld a, [wEnemyMovePower]	;get the base power of the enemy's attack
	cp $1	;check if it is 1. special damage moves assumed to have 1 base power
	jr nz, .skipout4	;skip down if it's not a special damage move
	call Random	;else get a random number between 0 and 255
	cp $40	
	jp c, .givepref	;(25% chance) slightly encourage
	jp .nextMove	;else neither encourage nor discourage
.skipout4
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;jump if the move is not very effective or is super effective
	ld a, [wTypeEffectiveness]
	cp $0A
	jr c, .notEffectiveMove
	jr nz, .isSuperEffectiveMove
;move has neutral effectiveness at this line
.neutral_effective
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;since the type effectiveness is neutral, randomly apply slight preference if there is STAB	
	;25% chance to check for and prefer a stab move
	call Random
	cp 192
	jr c, .skipout5
	push bc
	ld a, [wEnemyMoveType]
	ld b, a
	ld a, [wEnemyMonType1]
	cp b
	pop bc
	jp z, .givepref
	push bc
	ld a, [wEnemyMoveType]
	ld b, a
	ld a, [wEnemyMonType2]
	cp b
	pop bc
	jp z, .givepref
.skipout5
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;if attack is < special and move is physical, slightly discourage
;if attack is > special and move is special, slightly discourage
;25% chance to enact this
	call Random
	cp 192
	jr c, .skipout6
	call StrCmpAtkSPA
	jr z, .skipout6	;jump if stats equal
	push af
	ld a, [wEnemyMoveType]
	cp FIRE
	jr nc, .special_move
.physical_move
	pop af
	jp c, .lightlydiscourage	;jump if attack < special
	jr .skipout6
.special_move
	pop af
	jp nc, .lightlydiscourage		;jump if special < attack
.skipout6
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jp .nextMove
.isSuperEffectiveMove
	;at this line, move is super effective
.givepref	;joenote - added marker
	dec [hl] ; slightly encourage this move
	jp .nextMove
.notEffectiveMove ; discourages non-effective moves if better moves are available 
	push hl
	push de
	push bc
	ld a, [wEnemyMoveType]
	ld d, a
	ld hl, wEnemyMonMoves  ; enemy moves
	ld b, NUM_MOVES + 1
	ld c, $0
.loopMoves
	dec b
	jr z, .done
	ld a, [hli]
	and a
	jr z, .done
	call ReadMove
	ld a, [wEnemyMoveEffect]
	cp SUPER_FANG_EFFECT
	jr z, .betterMoveFound ; Super Fang is considered to be a better move
	cp SPECIAL_DAMAGE_EFFECT
	jr z, .betterMoveFound ; any special damage moves are considered to be better moves
	cp FLY_EFFECT
	jr z, .betterMoveFound ; Fly is considered to be a better move
	ld a, [wEnemyMoveType]
	cp d
	jr z, .loopMoves
	ld a, [wEnemyMovePower]
	and a
	jr nz, .betterMoveFound ; damaging moves of a different type are considered to be better moves
	jr .loopMoves
.betterMoveFound
	ld c, a
.done
	ld a, c
	pop bc
	pop de
	pop hl
	and a
	jp z, .nextMove
	inc [hl] ; slightly discourage this move
	jp .nextMove
	
AIMoveChoiceModification4:	;this unused routine now handles intelligent trainer switching
	ld a, [wUnusedD721]
	bit BIT_BATTLE_NOSWITCH, a
	jp nz, .skipSwitchEnd	;don't do anything if intelligent switching is deactivated
	
	ld a, [wUnusedC000]
	set 5, a ; sets the bit that signifies trainer has intelligent switching
	ld [wUnusedC000], a
	push hl
	push bc
	callab ScoreAIParty	;carry is cleared if current mon score >= highest score of remaining roster; don't switch
	pop bc
	pop hl
	jp nc, .skipSwitchEnd	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;it is typically better to not switch if HP is low rather than give the player a free hit
	ld a, 4
	call AICheckIfHPBelowFraction
	jp c, .skipSwitchEnd	;if hp below 1/a then do not switch
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;better chance to switch if afflicted with toxic-style poison
	ld a, [wEnemyBattleStatus3]
	bit 0, a	;check a for the toxic bit (sets or clears zero flag)
	jr z, .skipSwitchToxicEnd	;not badly poisoned if zero flag set
	call Random	;put a random number in 'a' between 0 and 255
	cp $55	;set carry if rand num < $55
	jp c, .setSwitch	;34% chance to switch
.skipSwitchToxicEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;chance to switch if stuck in a trapping move
	ld a, [wPlayerBattleStatus1]
	bit 5, a	;check a for trapping move bit (sets or clears zero flag)
	jr z, .skipSwitchTrapEnd	;not trapped if zero flag set
	call Random	;put a random number in 'a' between 0 and 255
	cp $40	;set carry if rand num < $40
	jp c, .setSwitch	;25% chance to switch
.skipSwitchTrapEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;chance to switch if afflicted with confusion
	ld a, [wEnemyBattleStatus1]
	bit 7, a	;check a for the confusion bit (sets or clears zero flag)
	jr z, .skipSwitchConfuseEnd	;not confused if zero flag set
	call Random	;put a random number in 'a' between 0 and 255
	cp $40	;set carry if rand num < $40
	jp c, .setSwitch	;25% chance to switch
.skipSwitchConfuseEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;12.5% chance to switch if afflicted with sleep counter > 3
	ld a, [wEnemyMonStatus]
	and %00000111	;check for sleep counter
	jr z, .skipSwitchNVSLEEPstatEnd	;no NV status if zero flag set
	push bc
	srl a
	srl a
	ld b, a
	call Random
	and %00000111
	cp b
	pop bc
	jp c, .setSwitch
.skipSwitchNVSLEEPstatEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;slight chance to switch if afflicted with leech seed
	ld a, [wEnemyBattleStatus2]
	bit 7, a	;check a for the leech seed bit (sets or clears zero flag)
	jr z, .skipSwitchSeedEnd	;not seeded if zero flag set
	call Random	;put a random number in 'a' between 0 and 255
	cp $20	;set carry if rand num < $20
	jp c, .setSwitch	;12.5% chance to switch
.skipSwitchSeedEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;slight chance to switch if move disabled
	ld a, [wEnemyDisabledMove] ; get disabled move (if any)
	swap a
	and $f
	jr z, .skipSwitchDisableEnd	;no disabled moves if zero flag set
	call Random	;put a random number in 'a' between 0 and 255
	cp $20	;set carry if rand num < $20
	jp c, .setSwitch	;12.5% chance to switch
.skipSwitchDisableEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;chance to switch if stat mods are too low
	push bc
	;use b for storage and a for loading
	ld a, [wEnemyMonAttackMod]	
	ld b, a 
	ld a, [wEnemyMonDefenseMod]
	cp b
	call c, CondLDBA	;if a < b, then load a into b
	ld a, [wEnemyMonSpeedMod]
	cp b
	call c, CondLDBA	;if a < b, then load a into b
	ld a, [wEnemyMonSpecialMod]
	cp b
	call c, CondLDBA	;if a < b, then load a into b
	ld a, [wEnemyMonAccuracyMod]
	cp b
	call c, CondLDBA	;if a < b, then load a into b
	ld a, [wEnemyMonEvasionMod]
	cp b
	call c, CondLDBA	;if a < b, then load a into b
	ld a, b	;but b back into a
	pop bc
	cp $07	;is the lowest stat mod the normal vale of 7?
	jr nc, .skipSwitchModEnd	;lowest stat mod is not negative (value below 7)
	push bc
	ld b, a	;put the lowest mod into b
	ld a, $07	; put 7 into a
	sub b	;a = 7 - b, so a becomes 6 (-6 stages) to 1 (-1 stage)
	ld b, a	;put a back into b
	call Random	;put a random number in 'a' between 0 and 255
	and $07	;use only bits 0 to 2 for a random number of 0 to 7
	cp b
	pop bc
	jp c, .setSwitch	;switch if random number < mod 1 (-1 stage) to 6 (-6 stages)
.skipSwitchModEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;switch if supereffective move is being used against enemy
	ld a, [wPlayerMovePower]	;get the power of the player's move
	cp $2	;regular damaging moves have power > 1
	jr c, .skipSwitchEffectiveEnd	;skip out if the move is not a normal damaging move
	push hl
	push bc
	push de
	;set type-effectiveness bit before calling function
	ld a, [wUnusedC000]
	set 3, a 
	ld [wUnusedC000], a
	callab AIGetTypeEffectiveness
	pop de
	pop bc
	pop hl
	ld a, [wTypeEffectiveness]	;get the multiplier effectiveness for the player's move
	cp $14	;is it < 20?
	jr c, .skipSwitchEffectiveEnd	;if so, skip to end of this block
	push bc
	ld a, [wPlayerMovePower]	;get the power of the player's move into a
	srl a	;halve the power
	srl a	;quarter the power
	ld b, a	;put quarter power into b
	ld a, [wPlayerMovePower]	;get the power of the player's move into a
	srl a	;halve the power
	add b	;add b to get 3/4ths power into a
	ld b, a
	call Random	;put a random number in 'a' 
	cp b; see if a < b and set carry if true
	pop bc
	jr nc, .skipSwitchEffectiveEnd	;if carry flag is set, switch pkmn
	;Before switching, flag the mon being switched out.
	;It will be used as a penalty in scoring since there
	;is clearly something disfavorable about it.
	push bc
	push hl
	push de
	ld de, wEnemyMonPartyPos
	callba SetAISwitched
	pop de
	pop bc
	pop hl
	jp .setSwitchKeepFlagged	
.skipSwitchEffectiveEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;do not switch if this pkmn was flagged
	push hl
	push bc
	push de
	ld de, wEnemyMonPartyPos
	callba CheckAISwitched
	pop de
	pop bc
	pop hl
	jp nz, .skipSwitchEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;commented this out because it is better to not switch if HP is low rather than give the player a free hit
;switch if HP is low. 
;but don't switch based on low HP if enemy outspeeds player mon
;	ld a, 3	;
;	call AICheckIfHPBelowFraction
;	jr nc, .skipSwitchHPend	;if hp not below 1/3 then skip to the end of this block
;	call Random	;put a random number in 'a' between 0 and 255
;	cp $40	;set carry if rand num < $40	/	;25% chance to switch
;	jr nc, .skipSwitchHPend
;	ld a, [wBattleMonSpeed]
;	push bc
;	ld b, a	;store hi byte of player speed in b
;	ld a, [wEnemyMonSpeed]	;store hi byte of enemy speed in a
;	cp b
;	pop bc
;	jr nz, .next1	;if bytes are not equal, then rely on carry bit to see which is greater
;	;else check the lo bytes
;	ld a, [wBattleMonSpeed + 1]
;	push bc
;	ld b, a	;store lo byte of player speed in b
;	ld a, [wEnemyMonSpeed + 1]	;store lo byte of enemy speed in a
;	cp b
;	pop bc
;.next1
;	jp c, .setSwitch	;if carry is set, then enemy mon has less speed --> switch out
;.skipSwitchHPend
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;chance to switch if afflicted with non-volatile status (except sleep)
	ld a, [wEnemyMonStatus]
	and %11111000	;check for any non-volatile status except sleep
	jr z, .skipSwitchNVstatEnd	;no NV status if zero flag set
	call Random	;put a random number in 'a' between 0 and 255
	cp $40	;set carry if rand num < $40
	jp c, .setSwitch	;25% chance to switch
.skipSwitchNVstatEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	jr .skipSwitchEnd	;jump to the end and get out of this line is reached.
.setSwitch	;this line will only be reached if a switch is confirmed.
	push bc
	push hl
	push de
	ld de, wEnemyMonPartyPos
	callba ClearAISwitched	;clear any switch flags on the mon being switched out
	pop de
	pop bc
	pop hl
.setSwitchKeepFlagged
	call SetSwitchBit
.skipSwitchEnd
	ret

;joenote - function for loading A into B so it can be called conditionally
CondLDBA:
	ld b, a
	ret
	
ReadMove:
	push hl
	push de
	push bc
	dec a
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld de, wEnemyMoveNum
	call CopyData
	pop bc
	pop de
	pop hl
	ret

;joenote - takes move in d, returns its power in d and type in e
ReadMoveForAIscoring:
	dec d
	ld a, d
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	inc hl	
	inc hl ;point to move power
	ld a, [hli]
	ld d, a	;store power in d
	ld a, [hl]
	ld e, a ;store type in e
	ret

; move choice modification methods that are applied for each trainer class
; 0 is sentinel value
;1 - Do not use a move that only statuses (e.g., Thunder Wave) if the player's Pokémon already has a status.
;2 - On the second turn only the Pokémon is out, prefer a move that heals/buffs/debuffs
;3 - Try to do type-matching when selecting attacks
;4 - switch if active pkmn is in trouble
TrainerClassMoveChoiceModifications:
	db 0      ; YOUNGSTER
	db 1,0    ; BUG CATCHER
	db 1,0    ; LASS
	db 1,3,0  ; SAILOR
	db 1,4,0    ; JR_TRAINER_M
	db 1,4,0    ; JR_TRAINER_F
	db 1,2,3,4,0; POKEMANIAC
	db 1,2,0  ; SUPER_NERD
	db 1,4,0    ; HIKER
	db 1,0    ; BIKER
	db 1,3,0  ; BURGLAR
	db 1,0    ; ENGINEER
	db 1,2,0  ; JUGGLER_X
	db 1,3,0  ; FISHER
	db 1,3,0  ; SWIMMER
	db 4,0      ; CUE_BALL
	db 1,0    ; GAMBLER
	db 1,3,0  ; BEAUTY
	db 1,2,4,0  ; PSYCHIC_TR
	db 1,0  ; ROCKER
	db 1,0    ; JUGGLER
	db 1,4,0    ; TAMER
	db 1,0    ; BIRD_KEEPER
	db 1,4,0    ; BLACKBELT
	db 1,4,0    ; SONY1
	db 1,3,4,0  ; PROF_OAK
	db 1,2,4,0  ; CHIEF
	db 1,2,0  ; SCIENTIST
	db 1,3,4,0  ; GIOVANNI
	db 1,4,0    ; ROCKET
	db 1,3,4,0  ; COOLTRAINER_M
	db 1,3,4,0  ; COOLTRAINER_F
	db 1,3,4,0    ; BRUNO
	db 1,3,4,0    ; BROCK
	db 1,3,4,0  ; MISTY
	db 1,3,4,0  ; LT_SURGE
	db 1,3,4,0  ; ERIKA
	db 1,3,4,0  ; KOGA
	db 1,3,4,0  ; BLAINE
	db 1,3,4,0  ; SABRINA
	db 1,2,4,0  ; GENTLEMAN
	db 1,3,4,0  ; SONY2
	db 1,3,4,0  ; SONY3
	db 1,2,3,4,0; LORELEI
	db 1,4,0    ; CHANNELER
	db 1,3,4,0    ; AGATHA
	db 1,3,4,0  ; LANCE

INCLUDE "engine/battle/trainer_pic_money_pointers.asm"

INCLUDE "text/trainer_names.asm"

INCLUDE "engine/battle/bank_e_misc.asm"

;joenote - moving all this to bank $2D to free up space for trainer AI in bank $E
;		- This only gets called from a bank switch in core.asm anyway
;INCLUDE "engine/battle/read_trainer_party.asm"

;INCLUDE "data/trainer_moves.asm"

;INCLUDE "data/trainer_parties.asm"

TrainerAI:
	and a
	ld a, [wIsInBattle]
	dec a
	ret z ; if not a trainer, we're done here
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	ret z

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [wPlayerBattleStatus1]
	bit USING_TRAPPING_MOVE, a ; caught in player's trapping move (e.g. wrap)
	jr z, .notbeingtrapped
	call CheckandResetSwitchBit	
	jp nz, AISwitchIfEnoughMons	;switch if switch bit is set and stuck in the player's trapping move
.notbeingtrapped
;	...otherwise
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - AI should not use actions if the null move has been selected
	ld a, [wEnemySelectedMove]
	cp $FF
	ret z
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - AI should not use actions if in a move that prevents such a thing
	ld a, [wEnemyBattleStatus2]
	and %01100000 
	ret nz
	ld a, [wEnemyBattleStatus1]
	and %01110011 
	ret nz
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - switch if the switch bit is set	
	call CheckandResetSwitchBit
	jp nz, AISwitchIfEnoughMons	;switch if bit was initially set
	;jp AISwitchIfEnoughMons	;joedebug - use this to make trainer ai constantly switch
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	ld a, [wTrainerClass] ; what trainer class is this?
	dec a
	ld c, a
	ld b, 0
	ld hl, TrainerAIPointers
	add hl, bc
	add hl, bc
	add hl, bc
	ld a, [wAICount]
	and a
	ret z ; if no AI uses left, we're done here
	inc hl
	inc a
	jr nz, .getpointer
	dec hl
	ld a, [hli]
	ld [wAICount], a
.getpointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call Random
	jp hl
.NoItem
	xor a	;make sure to clear the A register and flags before returning
	ret

TrainerAIPointers:
; one entry per trainer class
; first byte, number of times (per Pokémon) it can occur
; next two bytes, pointer to AI subroutine for trainer class
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,JugglerAI ; juggler_x
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 3,JugglerAI ; juggler
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 2,BlackbeltAI ; blackbelt
	dbw 3,GenericAI
	dbw 3,GenericAI
	dbw 1,GenericAI ; chief
	dbw 3,GenericAI
	dbw 1,GiovanniAI ; giovanni
	dbw 3,GenericAI
	dbw 2,CooltrainerMAI ; cooltrainerm
	dbw 1,CooltrainerFAI ; cooltrainerf
	dbw 2,BrunoAI ; bruno
	dbw 5,BrockAI ; brock
	dbw 1,MistyAI ; misty
	dbw 1,LtSurgeAI ; surge
	dbw 1,ErikaAI ; erika
	dbw 2,KogaAI ; koga
	dbw 2,BlaineAI ; blaine
	dbw 1,SabrinaAI ; sabrina
	dbw 3,GenericAI
	dbw 1,Sony2AI ; sony2
	dbw 1,Sony3AI ; sony3
	dbw 2,LoreleiAI ; lorelei
	dbw 3,GenericAI
	dbw 2,AgathaAI ; agatha
	dbw 1,LanceAI ; lance

;joenote - reorganizing these AI routines to jump on carry instead of returning on not-carry
;also adding recognition of a switch-pkmn bit

JugglerAI:
	cp $40
	jp c, AISwitchIfEnoughMons
	ret
	
BlackbeltAI:
	call AIItemsLowHPCheck
	jp c, TrainerAI.NoItem
	cp $20
	jp c, AIUseXAttack	
	ret
	
GiovanniAI:
	call AIItemsLowHPCheck
	jp c, TrainerAI.NoItem
	cp $40
	jp c, AIUseGuardSpec
	ret

CooltrainerMAI:	
	call AIItemsLowHPCheck
	jp c, TrainerAI.NoItem
	cp $40
	jp c, AIUseXAttack
	ret
	
CooltrainerFAI:
	call AIItemsLowHPCheck
	jp c, TrainerAI.NoItem
	cp $40
	jr nc, .coolFreturn
	ld a, $5
	call AICheckIfHPBelowFraction
	jp c, AIUseHyperPotion
.coolFreturn
	ret
	
BrockAI:
; if his active monster has a status condition, use a full heal
	ld a, [wEnemyMonStatus]
	and a
	jp nz, AIUseFullHeal
	ret 

MistyAI:
	call AIItemsLowHPCheck
	jp c, TrainerAI.NoItem
	cp $40
	jp c, AIUseXDefend
	ret
	
LtSurgeAI:
	call AIItemsLowHPCheck
	jp c, TrainerAI.NoItem
	cp $40
	jp c, AIUseXSpeed
	ret
	
ErikaAI:
	cp $80
	jr nc, .erikareturn
	ld a, $A
	call AICheckIfHPBelowFraction
	jp c, AIUseSuperPotion
.erikareturn
	ret

KogaAI:
	call AIItemsLowHPCheck
	jp c, TrainerAI.NoItem
	cp $40
	jp c, AIUseXAttack
	ret
	
BlaineAI:	;blaine needs to check HP. this was an oversight	
	cp $40
	jr nc, .blainereturn
	ld a, $2
	call AICheckIfHPBelowFraction	
	jp c, AIUseSuperPotion
.blainereturn
	ret

SabrinaAI:
	cp $40
	jr nc, .sabrinareturn
	ld a, $A
	call AICheckIfHPBelowFraction
	jp c, AIUseHyperPotion
.sabrinareturn
	ret

Sony2AI:
	cp $20
	jr nc, .rival2return
	ld a, 5
	call AICheckIfHPBelowFraction
	jp c, AIUsePotion
.rival2return
	ret

Sony3AI:
	cp $20
	jr nc, .rival3return
	ld a, 5
	call AICheckIfHPBelowFraction
	jp c, AIUseFullRestore
.rival3return
	ret

LoreleiAI:
	cp $80
	jr nc, .loreleireturn
	ld a, 5
	call AICheckIfHPBelowFraction
	jp c, AIUseSuperPotion	
.loreleireturn
	ret


BrunoAI:
	cp $40
	jp c, AIUseXDefend
	ret

AgathaAI:
;	cp $14
;	jp c, AISwitchIfEnoughMons
	cp $80
	jr nc, .agathareturn
	ld a, $4
	call AICheckIfHPBelowFraction
	jp c, AIUseSuperPotion
.agathareturn
	ret

LanceAI:
	cp $80
	jr nc, .lancereturn
	ld a, 5
	call AICheckIfHPBelowFraction
	jp c, AIUseHyperPotion
.lancereturn
	ret

GenericAI:
	and a ; clear carry
	ret

; end of individual trainer AI routines

;joenote - added these functions to check if the ai switching bit is set
;need to have 'a' accumulator and flag register freed up to use this function
CheckandResetSwitchBit:	
	ld a, [wUnusedC000]
	bit 0, a	;check a for switch pkmn bit (sets or clears zero flag)
	res 0, a ; resets the switch pkmn bit (does not affect flags)
	ld [wUnusedC000], a
	ret
SetSwitchBit:	
	ld a, [wUnusedC000]
	set 0, a ; sets the switch pkmn bit
	ld [wUnusedC000], a
	ret

DecrementAICount:
	call UndoEnemySelectionPPDecrement	;joenote - undo the pp decrement of already-selected move if applicable
	ld hl, wAICount
	dec [hl]
	scf
	ret

AIPlayRestoringSFX:
	ld a, SFX_HEAL_AILMENT
	jp PlaySoundWaitForCurrent

AIUseFullRestore:
	call AIPlayRestoringSFX
	call AICureStatus
	ld a, FULL_RESTORE
	ld [wAIItem], a
	ld de, wHPBarOldHP
	ld hl, wEnemyMonHP + 1
	ld a, [hld]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	inc de
	ld hl, wEnemyMonMaxHP + 1
	ld a, [hld]
	ld [de], a
	inc de
	ld [wHPBarMaxHP], a
	ld [wEnemyMonHP + 1], a
	ld a, [hl]
	ld [de], a
	ld [wHPBarMaxHP+1], a
	ld [wEnemyMonHP], a
	jr AIPrintItemUseAndUpdateHPBar

AIUsePotion:
; enemy trainer heals his monster with a potion
	call AIPlayRestoringSFX
	ld a, POTION
	ld b, 20
	jr AIRecoverHP

AIUseSuperPotion:
; enemy trainer heals his monster with a super potion
	call AIPlayRestoringSFX
	ld a, SUPER_POTION
	ld b, 50
	jr AIRecoverHP

AIUseHyperPotion:
; enemy trainer heals his monster with a hyper potion
	call AIPlayRestoringSFX
	ld a, HYPER_POTION
	ld b, 200
	; fallthrough

AIRecoverHP:
; heal b HP and print "trainer used $(a) on pokemon!"
	ld [wAIItem], a
	ld hl, wEnemyMonHP + 1
	ld a, [hl]
	ld [wHPBarOldHP], a
	add b
	ld [hld], a
	ld [wHPBarNewHP], a
	ld a, [hl]
	ld [wHPBarOldHP+1], a
	ld [wHPBarNewHP+1], a
	jr nc, .next
	inc a
	ld [hl], a
	ld [wHPBarNewHP+1], a
.next
	inc hl
	ld a, [hld]
	ld b, a
	ld de, wEnemyMonMaxHP + 1
	ld a, [de]
	dec de
	ld [wHPBarMaxHP], a
	sub b
	ld a, [hli]
	ld b, a
	ld a, [de]
	ld [wHPBarMaxHP+1], a
	sbc b
	jr nc, AIPrintItemUseAndUpdateHPBar
	inc de
	ld a, [de]
	dec de
	ld [hld], a
	ld [wHPBarNewHP], a
	ld a, [de]
	ld [hl], a
	ld [wHPBarNewHP+1], a
	; fallthrough

AIPrintItemUseAndUpdateHPBar:
	call AIPrintItemUse_
	coord hl, 2, 2
	xor a
	ld [wHPBarType], a
	predef UpdateHPBar2
	
	push af
	callba DrawEnemyHUDAndHPBar		;joenote - need to redraw the enemy trainer hud 
	pop af

	jp DecrementAICount

AISwitchIfEnoughMons:
; enemy trainer switches if there are 2 or more unfainted mons in party
	ld a, [wEnemyPartyCount]
	ld c, a
	ld hl, wEnemyMon1HP

	ld d, 0 ; keep count of unfainted monsters

	; count how many monsters haven't fainted yet
.loop
	ld a, [hli]
	ld b, a
	ld a, [hld]
	or b
	jr z, .Fainted ; has monster fainted?
	inc d
.Fainted
	push bc
	ld bc, wEnemyMon2 - wEnemyMon1
	add hl, bc
	pop bc
	dec c
	jr nz, .loop

	ld a, d ; how many available monsters are there?
	cp 2 ; don't bother if only 1
	
	push af
	call nc, UndoEnemySelectionPPDecrement	;joenote - undo the pp decrement of already-selected move if applicable
	pop af
	
	jp nc, SwitchEnemyMon
	and a
	ret

SwitchEnemyMon:
;joenote - if player using trapping move, then end their move
	ld a, [wPlayerBattleStatus1]
	bit USING_TRAPPING_MOVE, a
	jr z, .preparewithdraw
	ld hl, wPlayerBattleStatus1
	res USING_TRAPPING_MOVE, [hl] 
	xor a
	ld [wPlayerNumAttacksLeft], a
	ld a, $FF
	ld [wPlayerSelectedMove], a
.preparewithdraw
; prepare to withdraw the active monster:

	ld a, [wEnemyMonPartyPos]
	ld hl, wEnemyMon1HP
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, wEnemyMonHP
	ld bc, 4
	call CopyData	 ;copy hp, number, and status of the active pokemon to its roster position
	
	;joenote - don't copy PP information if transformed
	ld a, [wEnemyBattleStatus3]
	bit 3, a 	;check the state of the enemy transformed bit
	jr nz, .skiptransformed	;skip ahead if bit is set
	
	;joenote - copy PP information
	ld a, [wEnemyMonPartyPos]
	ld hl, wEnemyMon1PP
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, wEnemyMonPP
	ld bc, 4
	call CopyData
	
.skiptransformed
	ld hl, AIBattleWithdrawText
	call PrintText

	; This wFirstMonsNotOutYet variable is abused to prevent the player from
	; switching in a new mon in response to this switch.
	ld a, 1
	ld [wFirstMonsNotOutYet], a
	callab EnemySendOut
	xor a
	ld [wFirstMonsNotOutYet], a
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	ret z
	;joenote - the act of switching clears H_WHOSETURN, so it needs to be set back to 1
	ld a, $1
	ld [H_WHOSETURN], a
	scf
	ret

AIBattleWithdrawText:
	TX_FAR _AIBattleWithdrawText
	db "@"

AIUseFullHeal:
	call AIPlayRestoringSFX
	call AICureStatus
	ld a, FULL_HEAL
	jp AIPrintItemUse

AICureStatus:	;joenote - modified to be more robust and also undo stat changes of brn/par
; cures the status of enemy's active pokemon
	ld a, [wEnemyMonPartyPos]
	ld hl, wEnemyMon1Status
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	xor a
	ld [hl], a ; clear status in enemy team roster
	ld a, [H_WHOSETURN]
	push af
	ld a, $01 	;forcibly set it to the AI's turn
	ld [H_WHOSETURN], a
	callab UndoBurnParStats	;undo brn/par stat changes
	pop af
	ld [H_WHOSETURN], a
	xor a
	ld [wEnemyMonStatus], a ; clear status in active enemy data
	ld [wEnemyToxicCounter], a	;clear toxic counter
	ld hl, wEnemyBattleStatus3
	res BADLY_POISONED, [hl]	;clear toxic bit

	push af
	callba DrawEnemyHUDAndHPBar		;joenote - need to redraw the enemy trainer hud 
	pop af

	ret

AIUseXAccuracy: 
	call AIPlayRestoringSFX
	ld hl, wEnemyBattleStatus2
	set 0, [hl]
	ld a, X_ACCURACY
	jp AIPrintItemUse

AIUseGuardSpec:
	call AIPlayRestoringSFX
	ld hl, wEnemyBattleStatus2
	set 1, [hl]
	ld a, GUARD_SPEC
	jp AIPrintItemUse

AIUseDireHit: 
	call AIPlayRestoringSFX
	ld hl, wEnemyBattleStatus2
	set 2, [hl]
	ld a, DIRE_HIT
	jp AIPrintItemUse

AICheckIfHPBelowFraction:
; return carry if enemy trainer's current HP is below 1 / a of the maximum
;joenote - first preserve stuff onto the stack
	push hl
	push bc
	push de
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - handle an 'a' value of 1
	cp 1
	jr nz, .not_one
	ld a, [wEnemyMonMaxHP]
	ld b, a
	ld a, [wEnemyMonHP]
	cp b	;a = HP MSB an b = MAXHP MSB so do a - b and set carry if negative
	jr c, .return
	ld a, [wEnemyMonMaxHP + 1]
	ld b, a
	ld a, [wEnemyMonHP + 1]
	cp b	;a = HP LSB an b = MAXHP LSB so do a - b and set carry if negative
	jr .return
.not_one
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld [H_DIVISOR], a
	ld hl, wEnemyMonMaxHP
	ld a, [hli]
	ld [H_DIVIDEND], a
	ld a, [hl]
	ld [H_DIVIDEND + 1], a
	ld b, 2
	call Divide
	ld a, [H_QUOTIENT + 3]
	ld c, a
	ld a, [H_QUOTIENT + 2]
	ld b, a
	ld hl, wEnemyMonHP + 1
	ld a, [hld]
	ld e, a
	ld a, [hl]
	ld d, a
	ld a, d
	sub b
	jr nz, .return
	ld a, e
	sub c
.return	;joenote - consolidating returns with the stack
	pop de
	pop bc
	pop hl
	ret

AICheckIfPlayerHPBelowFraction:
; return carry if player's current HP is below 1 / a of the maximum
;joenote - first preserve stuff onto the stack
	push hl
	push bc
	push de
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - handle an 'a' value of 1
	cp 1
	jr nz, .not_one
	ld a, [wBattleMonMaxHP]
	ld b, a
	ld a, [wBattleMonHP]
	cp b	;a = HP MSB an b = MAXHP MSB so do a - b and set carry if negative
	jr c, .return
	ld a, [wBattleMonMaxHP + 1]
	ld b, a
	ld a, [wBattleMonHP + 1]
	cp b	;a = HP LSB an b = MAXHP LSB so do a - b and set carry if negative
	jr .return
.not_one
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld [H_DIVISOR], a
	ld hl, wBattleMonMaxHP
	ld a, [hli]
	ld [H_DIVIDEND], a
	ld a, [hl]
	ld [H_DIVIDEND + 1], a
	ld b, 2
	call Divide
	ld a, [H_QUOTIENT + 3]
	ld c, a
	ld a, [H_QUOTIENT + 2]
	ld b, a
	ld hl, wBattleMonHP + 1
	ld a, [hld]
	ld e, a
	ld a, [hl]
	ld d, a
	ld a, d
	sub b
	jr nz, .return
	ld a, e
	sub c
.return	;joenote - consolidating returns with the stack
	pop de
	pop bc
	pop hl
	ret

AIUseXAttack:
	ld b, $A
	ld a, X_ATTACK
	jr AIIncreaseStat

AIUseXDefend:
	ld b, $B
	ld a, X_DEFEND
	jr AIIncreaseStat

AIUseXSpeed:
	ld b, $C
	ld a, X_SPEED
	jr AIIncreaseStat

AIUseXSpecial:
	ld b, $D
	ld a, X_SPECIAL
	; fallthrough

AIIncreaseStat:
	ld [wAIItem], a
	push bc
	call AIPrintItemUse_
	pop bc
	ld hl, wEnemyMoveEffect
	ld a, [hld]
	push af
	ld a, [hl]
	push af
	push hl
	ld a, ANIM_AF
	ld [hli], a
	ld [hl], b
	callab StatModifierUpEffect
	pop hl
	pop af
	ld [hli], a
	pop af
	ld [hl], a
	jp DecrementAICount

AIPrintItemUse:
	ld [wAIItem], a
	call AIPrintItemUse_
	jp DecrementAICount

AIPrintItemUse_:
; print "x used [wAIItem] on z!"
	ld a, [wAIItem]
	ld [wd11e], a
	call GetItemName
	ld hl, AIBattleUseItemText
	jp PrintText

AIBattleUseItemText:
	TX_FAR _AIBattleUseItemText
	db "@"

StrCmpSpeed:	;joenote - function for AI to compare pkmn speeds
	push bc
	push de
	push hl
	ld de, wBattleMonSpeed ; player speed value
	ld hl, wEnemyMonSpeed ; enemy speed value
	ld c, $2	;bytes to copy
.spdcmploop	
	ld a, [de]	
	cp [hl]
	jr nz, .return
	inc de
	inc hl
	dec c
	jr nz, .spdcmploop
	;At this point:
	;zero flag set means speeds equal
	;carry flag not set means player pkmn faster
	;carry flag set means ai pkmn faster
.return
	pop hl
	pop de
	pop bc
	ret

StrCmpAtkSPA:	;joenote - function for AI to its attack and special stats
	push bc
	push de
	push hl
	ld de, wEnemyMonAttack 
	ld hl, wEnemyMonSpecial
	ld c, $2	;bytes to copy
.spdcmploop	
	ld a, [de]	
	cp [hl]
	jr nz, .return
	inc de
	inc hl
	dec c
	jr nz, .spdcmploop
	;At this point:
	;zero flag set means stats equal
	;carry flag not set means attack is greater
	;carry flag set means special is greater
.return
	pop hl
	pop de
	pop bc
	ret

;joenote - get the enemy move that has already been selected
;if it is found in the move list, increment the pp that was deducted when selecting the move
UndoEnemySelectionPPDecrement:
	push hl
	push bc
	push de
	ld a, [wEnemySelectedMove]
	and a
	jr z, .return	;return if the selected move is 00
	cp NUM_ATTACKS + 1
	jr nc, .return	;return if the selected move is invalid (> max number of moves)
	ld d, a
	ld e, NUM_MOVES
	ld bc, wEnemyMonPP - wEnemyMonMoves
	ld hl, wEnemyMonMoves
.loop
	ld a, [hl]
	and a
	jr z, .return
	cp d
	jr z, .found
	inc hl
	dec e
	jr z, .return
	jr .loop
.found
	add hl, bc
	inc [hl]
.return
	pop de
	pop bc
	pop hl
	ret

;joenote - ret z if move in A is either Dig or Fly
IsDigOrFly:
	cp DIG
	ret z
	cp FLY
	ret 
	
;joenote - see if either the player or AI trainer has low HP since it might be better to not use an item
AIItemsLowHPCheck:
	push bc
	ld b, a
	
	ld a, 2
	call AICheckIfPlayerHPBelowFraction
	jr c, .return

	ld a, 2
	call AICheckIfHPBelowFraction

.return
	ld a, b
	pop bc
	ret
