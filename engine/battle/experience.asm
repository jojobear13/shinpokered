;Note from the shinpokered cabal:
;Hey dude. If you're looking at this file, 
;then you're probably trying to do stuff with the experience code in your own rom hack.
;You also probably have glazed-over eyes and a smashed keyboard from trying to make sense of things.
;Well, this one goes out to you.
;This file tries to rewrite, consolidate, fix, and comment all the exp gain code.
;The parts that are exclusive to shinpokered are marked so vanilla functionality can be achieved.
;Feel free to take this file and implement it for your own pokered-based project.
;This takes about the same time to run as the original code, but at least it is easier to manage and modify.

;joenote - This is the main function that gets called from engine\battle\core.asm
;core.asm has a few required changes at the spot where it calls GainExperience
;Note that this fixes several bugs involving EXP ALL including the division bug where chunks of exp can be lost.
;Here is how things now work with EXP ALL:
; 1 - Resolve battle participants.
;   A - Copy the base stats and base exp value of the enemy pokemon into buffer memory.
;   B - Halve each of these six values due to EXP ALL.
;   C - Divide these six values further by the number of non-fainted pokemon who fought.
;   D - Add the resulting five base stat values to the Stat EXP values of non-fainted pokemon who fought.
;	E - Get the enemy pokemon base exp value (which was previously halved) and multiply it by the enemy's level.
;	F - Take that result and divide by 7 to get the general EXP amount. Multiply again by 1.5 if a trainer battle.
;	G - Give that EXP value to every non-fainted pokemon who fought, multiplying it by 1.5 for any traded pokemon.
; 2 - Set flags so that the entire party is now treated as "having fought" for the purposes of EXP ALL.
; 3 - Repeat #1.
;Meaning that:
;  - Pokemon still do not recieve EXP for being fainted, but they no longer count towards division and dilute the EXP.
;  - The division done by having multiple battle participants is now cleared before doing whole-party EXP.
GainExperience:
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	ret z ; return if link battle

;shinpokered feature having to do with the GBC double speed CPU mode
;Running in double speed CPU mode shaves off about 1 second of computation delay
	predef SetCPUSpeed
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;shinpokered feature having to do with exp all
	ld a, [wBoostExpByExpAll]
	and a
	jr z, .skipexpallmsg
	ld a, [wd728]
	set 7, a
	ld [wd728], a	
.skipexpallmsg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	call BufferExpData
	call GetNumMonsGainingExp
	call DivideExpDataByNumMonsGainingExp
	call GiveStatExp
	call CalculateLevelExp
	
	xor a
	ld [wWhichPokemon], a
	ld a, [wPartyGainExpFlags]
	and %00111111
	ld c, a
	ld hl, wPartyMon1OTID
.loop
	push bc
	srl c
	jr nc, .next
	push hl		;preserve wPartyMon'X'OTID

	call AddExpToPokemon
	;HL  now equals wPartyMon'X'Exp
	;Now backup the general exp calculation since the quotient addresses are going to get clobbered
	ld a, [H_QUOTIENT+2]
	push af
	ld a, [H_QUOTIENT+3]
	push af
	call CapExpAtMaxLevel
	;HL  still equals wPartyMon'X'Exp
	call PrintExpGained
	;HL  still equals wPartyMon'X'Exp
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
;joenote - Now to check if the pointed pokemon gained any levels
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	push hl

IF DEF(_EXPBAR)
	callba AnimateEXPBar	;joenote - animate the exp bar
ENDC

	call LoadMonData
	pop hl	;HL equals wPartyMon'X'Exp
	ld bc, wPartyMon1Level - wPartyMon1Exp
	add hl, bc	;HL equals wPartyMon'X'Level
	push hl
	callba CalcLevelFromExperience
	pop hl	;HL equals wPartyMon'X'Level
	ld a, [hl] ; current level

	ld [wTempCoins1], a	;joenote - fixing skip move-learn glitch: need to store the current level in wram
	;wTempCoins1 was chosen because it's used only for slot machine and gets defaulted to 1 during the mini-game
	;This has to do with shinpokered fixes implemented in engine\evos_moves.asm

	cp d	;D holds the potential new level based on the added exp
	jr z, .nextMon ; if level didn't change, go to next mon
;remember that HL equals wPartyMon'X'Level at this line
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;		
	call LevelUpPokemon
.nextMon
	;Need to restore the general exp calculation back into the quotient addresses
	pop af
	ld [H_QUOTIENT+3], a
	pop af
	ld [H_QUOTIENT+2], a
	xor a
	ld [H_QUOTIENT+1], a
	ld [H_QUOTIENT], a
	pop hl	;HL equals wPartyMon'X'OTID
.next
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc
	ld a, [wWhichPokemon]
	inc a
	ld [wWhichPokemon], a
	pop bc
	srl c
	jr nz, .loop
	
;all done with the main run, so do some finishing-up

	;shinpokered feature having to do with the GBC double speed CPU mode
	predef SingleCPUSpeed
	
	ld b, EXP_ALL
	call IsItemInBag
	jr z, .done_doPredefJump	;totally done if exp all is not in the bag
	
	ld a, [wBoostExpByExpAll]
	and a
	jr nz, .done_doPredefJump	;totally done if exp all is in the bag but ran through its effect already

;exp all is in the bag but its effect still needs to happen
.done_doPredefAndLoop
	ld hl, wPartyGainExpFlags
	xor a
	ld [hl], a ; clear gain exp flags
	ld a, [wPlayerMonNumber]
	ld c, a
	ld b, FLAG_SET
	push bc
	predef FlagActionPredef ; set the gain exp flag for the mon that is currently out
	ld hl, wPartyFoughtCurrentEnemyFlags
	xor a
	ld [hl], a
	pop bc
	predef FlagActionPredef ; set the fought current enemy flag for the mon that is currently out
	;initiate the exp all effect and run through this function again
	call SetExpAllFlags
	jp GainExperience
	
.done_doPredefJump
	ld hl, wPartyGainExpFlags
	xor a
	ld [hl], a ; clear gain exp flags
	ld a, [wPlayerMonNumber]
	ld c, a
	ld b, FLAG_SET
	push bc
	predef FlagActionPredef ; set the gain exp flag for the mon that is currently out
	ld hl, wPartyFoughtCurrentEnemyFlags
	xor a
	ld [hl], a
	pop bc
	predef_jump FlagActionPredef ; jump out to set the fought current enemy flag for the mon that is currently active















	
	
;joenote - This function backs up enemy base stats and base exp into wBuffer
;it also halves the values if EXP ALL is detected in the bag
BufferExpData:
	push de
	ld de, wBuffer
	ld hl, wEnemyMonBaseStats
	ld c, wEnemyMonBaseExp + 1 - wEnemyMonBaseStats
.loop
	ld a, c
	cp 2
	ld a, [hli]
	jr z, .next	;skip wEnemyMonActualCatchRate
	ld [de], a
	inc de
.next
	dec c
	jr nz, .loop
	
	ld b, EXP_ALL
	call IsItemInBag
	jr z, .done
	
	;if exp all is in the bag, halve everything in the buffer
	ld c, NUM_STATS+1
	ld hl, wBuffer
.loop2
	ld a, [hl]
	srl a
	ld [hli], a
	dec c
	jr nz, .loop2

.done	
	pop de
	ret

	
;joenote - This function counts the number of pokemon that get a share of exp
;stores this value in wUnusedD155
GetNumMonsGainingExp:
	ld a, [wPartyGainExpFlags]
	ld b, a
	xor a
	ld c, $6
.countSetBitsLoop ; loop to count set bits in wPartyGainExpFlags
	srl b
	adc 0
	dec c
	jr nz, .countSetBitsLoop
	ld [wUnusedD155], a
	ret

;Divide enemy base stats and base exp by the number of mons gaining exp
;joenote - given a rewrite
;assumes that pokemon with zero hp are already cleared in wPartyGainExpFlags
;assumes that wUnusedD155 already contains the number to divide by from GetNumMonsGainingExp
;assumes BufferExpData was already run
DivideExpDataByNumMonsGainingExp:
	ld hl, wBuffer
	ld c, wEnemyMonBaseExp + 1 - wEnemyMonBaseStats - 1
.loop
	ld a, [wUnusedD155]
	cp 2
	ret c	;do nothing if dividing by 1	
	jr z, .div2
	
	cp 3
	jr z, .div3
	
	cp 4
	jr z, .div4
	
	cp 5
	jr z, .div5

	;else divide by 6
.div6
	ld a, [hl]
	call ByteDivBy3
	ld [hl], a
	jr .div2
.div5
	ld a, [hl]
	call ByteDivBy5
	ld [hli], a
	jr .next
.div3
	ld a, [hl]
	call ByteDivBy3
	ld [hli], a
	jr .next
.div4
	ld a, [hl]
	srl a
	ld [hl], a
	;fall through
.div2
	ld a, [hl]
	srl a
	ld [hli], a
.next
	dec c
	jr nz, .loop
	ret

;joenote - this function divides the byte in A by 3	
;Does a little bit of error correction
ByteDivBy3:
	ld b, a
	srl b
	sub b
	
	ld b, a
	srl b
	srl b
	add b
	
	ld b, a
	srl b
	srl b
	srl b
	srl b
	add b
	
	push af
	and 1
	ld b, a
	pop af
	
	srl a
	add b
	ret	
	
;joenote - this function divides the byte in A by 5	
;Does a little bit of error correction
ByteDivBy5:
	ld b, a
	srl b
	srl b
	sub b
	
	ld b, a
	srl b
	srl b
	srl b
	srl b
	add b
	
	push af
	and 1
	ld b, a
	pop af
	
	srl a
	srl a
	add b
	ret
	
	
;joenote - adds the stat exp values in wBuffer to every flagged participant
GiveStatExp:	
	push de
	ld a, [wPartyGainExpFlags]
	and %00111111 
	ld c, a
	ld hl, wPartyMon1HPExp + 1
.loopPartyMonStatExp
	push bc
	push hl
	srl c
	jr nc, .nextPartyMonStatExp	;if not flagged, go to next mon

	ld c, NUM_STATS
	ld de, wBuffer	
.loopPartyMonStatExp_subloop
	ld a, [de]
	ld b, a
	ld a, [hl]
	add b
	ld [hld], a
	ld a, [hl]
	adc 0
	ld [hli], a
	call c, ExpWordOverflow
	inc hl
	inc hl
	inc de
	dec c
	jr nz, .loopPartyMonStatExp_subloop

.nextPartyMonStatExp	
	pop hl	;reset to wPartyMon'X'HPExp + 1
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc	;advance to next party mon
	pop bc	;get flag state back
	srl c	;advance the flags
	jr nz, .loopPartyMonStatExp

	pop de
	ret		;we're done if C is zero
	
	
;joenote - call after adding and getting a carry flag. sets HL and HL-1 each to FF
ExpWordOverflow:
	ld a, $ff
	ld [hld], a
	ld [hli], a
	ret
	
;joenote - do a general calculation for level experience to be doled out
;result can be up to two bytes large stored in H_QUOTIENT + 2 and H_QUOTIENT + 3
CalculateLevelExp:
	;multiply the adjusted base exp value in the buffer by the level of the enemy pokemon
	ld hl, wBuffer + NUM_STATS
	ld a, [hl]
	ld [H_MULTIPLICAND + 2], a
	xor a
	ld [H_MULTIPLICAND + 1], a
	ld [H_MULTIPLICAND], a
	ld a, [wEnemyMonLevel]
	ld [H_MULTIPLIER], a
	call Multiply
	
	;now divide it by 7
	ld a, 7
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	
	;if this is a trainer battle, multiply the exp by 1.5
	ld a, [wIsInBattle]
	dec a
	call nz, BoostExp
	
	ret

	
;joenote - multiplies exp by 1.5
BoostExp:
	ld a, [H_QUOTIENT + 2]
	ld b, a
	ld a, [H_QUOTIENT + 3]
	ld c, a
	srl b
	rr c
	add c
	ld [H_QUOTIENT + 3], a
	ld a, [H_QUOTIENT + 2]
	adc b
	ld [H_QUOTIENT + 2], a
	jr c, .overflow
	ret
.overflow
	ld a, $FF
	ld [H_QUOTIENT + 2], a
	ld [H_QUOTIENT + 3], a
	ret

	
;joenote - adds the exp in H_QUOTIENT + 2 and H_QUOTIENT + 3 to the pokemon pointed to by HL
;Assumes HL = wPartyMon'X'OTID
;Returns with HL = wPartyMon'X'Exp
;Also applies any boosts unique to the pointed pokemon
AddExpToPokemon:
	push de
	
	xor a
	ld [wGainBoostedExp], a
	
	ld a, [H_QUOTIENT + 3]
	ld e, a
	ld a, [H_QUOTIENT + 2]
	ld d, a

	push hl
	ld a, [wPlayerID]
	cp [hl]
	jr nz, .traded
	inc hl
	ld a, [wPlayerID+1]
	cp [hl]
	jr z, .next
.traded
	call BoostExp
	ld a, 1
	ld [wGainBoostedExp], a
.next
	pop hl
	
	ld bc, (wPartyMon1Exp + 2) - wPartyMon1OTID
	add hl, bc
	;hl now points to wPartyMon'X'Exp + 2
	
	ld a, [hl]
	ld b, a
	ld a, [H_QUOTIENT + 3]
	ld [wExpAmountGained + 1], a
	add b
	ld [hld], a
	
	ld a, [hl]
	ld b, a
	ld a, [H_QUOTIENT + 2]
	ld [wExpAmountGained], a
	adc b
	ld [hld], a
	
	ld a, [hl]
	ld b, a
	ld a, 0
	adc b
	ld [hl], a


	ld a, e
	ld [H_QUOTIENT + 3], a
	ld a, d
	ld [H_QUOTIENT + 2], a
	pop de
	ret
	

;joenote - finds the exp for the pointed pokemon species at max level and enforces it as a cap
;Assumes HL = wPartyMon'X'Exp and preserves it
;Assumes wWhichPokemon = 'X'-1
CapExpAtMaxLevel:
	push de	
	push hl
	inc hl
	inc hl
	;HL = wPartyMon'X'Exp + 2
	push hl
	ld a, [wWhichPokemon]
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl] ; species
	ld [wd0b5], a
	call GetMonHeader
	ld d, MAX_LEVEL
	callab CalcExperience ; get max exp
; compare max exp with current exp
	ld a, [hExperience]
	ld b, a
	ld a, [hExperience + 1]
	ld c, a
	ld a, [hExperience + 2]
	ld d, a
	pop hl	;HL = wPartyMon'X'Exp + 2
	ld a, [hld]
	sub d
	ld a, [hld]
	sbc c
	ld a, [hl]
	sbc b
	jr c, .next
; the mon's exp is greater than or equal to the max exp, so overwrite it with the max exp
	ld a, b
	ld [hli], a
	ld a, c
	ld [hli], a
	ld a, d
	ld [hl], a
.next
	pop hl
	pop de
	ret


;joenote - prints the text for gaining experience
;preserves HL
PrintExpGained:
	push hl
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	ld hl, GainedText

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - changing exp.all text for shinpokered
	ld a, [wBoostExpByExpAll]
	and a
	jr z, .noexpall
	ld a, [wd728]
	bit 7, a
	jr z, .noexpprint	;print the exp.all amount only once (for the first party member)
	res 7, a
	ld [wd728], a
	ld hl, WithExpAllText
.noexpall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	call PrintText
.noexpprint
	pop hl
	ret
	

;joenote - It's been determined that the pokemon pointed to by wPartyMon'X'Level has gained enough EXP to level-up
;The new level is in the D register and HL = wPartyMon'X'Level
;So go through the whole rigamaroll of increasing the level
LevelUpPokemon:
IF DEF(_EXPBAR)
	push hl
	callba KeepEXPBarFull	;joenote - animate the exp bar
	pop hl
ENDC

	ld a, [wCurEnemyLVL]
	push af		;wCurEnemyLVL is going to be used for stuff, so back up its value
	push hl	;also back up wPartyMon'X'Level

	;update to the new level
	ld a, d
	ld [hl], a
	ld [wCurEnemyLVL], a	;wCurEnemyLVL is used as a reference address for various calculation functions

	;load the pokemon's species header data
	ld bc, wPartyMon1Species - wPartyMon1Level
	add hl, bc	;HL = wPartyMon'X'Species
	ld a, [hl]
	ld [wd0b5], a
	ld [wd11e], a
	
	push af		;backup the species value
	
	call GetMonHeader
	
	ld bc, (wPartyMon1MaxHP + 1) - wPartyMon1Species
	add hl, bc	
	push hl		;preserve HL = wPartyMon'X'MaxHP + 1
	ld a, [hld]
	ld c, a
	ld b, [hl]	;HL = wPartyMon'X'MaxHP
	push bc ; preserve max HP value (from before level-up)
	
	ld d, h
	ld e, l
	;DE = wPartyMon'X'MaxHP
	ld bc, (wPartyMon1HPExp - 1) - wPartyMon1MaxHP
	add hl, bc	;HL = wPartyMon1HPExp - 1
	ld b, $1 ; consider stat exp when calculating stats
	call CalcStats
	
	pop bc ; restore max HP (from before levelling up) into BC
	pop hl	;restore HL = wPartyMon'X'MaxHP + 1
	ld a, [hld]
	sub c
	ld c, a
	ld a, [hl]
	sbc b
	ld b, a
	;BC = difference between old max HP and new max HP after level-up
	;HL = wPartyMon'X'MaxHP at this line
	ld de, (wPartyMon1HP + 1) - wPartyMon1MaxHP
	add hl, de
	;HL = wPartyMon'X'HP + 1 at this line
	
; add the amount of max HP gained from level-up to the current HP (it keeps things proportional)
; remember that BC = difference between old max HP and new max HP after level-up
	ld a, [hl] ; wPartyMon1HP + 1
	add c
	ld [hld], a
	ld a, [hl] ; HL = wPartyMon'X'HP
	adc b
	ld [hl], a
	
	;check if the pokemon being pointed to right now is currently the active pokemon in battle
	ld a, [wPlayerMonNumber]
	ld b, a
	ld a, [wWhichPokemon]
	cp b ; is the current mon in battle?
	jr nz, .printGrewLevelText	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; the current pointed-to mon is the active battle pokemon
; so now we have to update all the active battle pokemon stats
	ld de, wBattleMonHP

; copy party mon HP to battle mon HP
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a
	;HL = wPartyMon'X'HP + 1
	;DE = wBattleMonHP + 1

; copy other stats from party mon to battle mon and redo all the stat calculations for the active battle pokemon
	ld bc, wPartyMon1Level - (wPartyMon1HP + 1)
	add hl, bc
	push hl 	;preserve HL = wPartyMon'X'Level
	ld de, wBattleMonLevel
	ld bc, 1 + NUM_STATS * 2 ; size of stats
	call CopyData
	pop hl	;restore HL = wPartyMon'X'Level
	ld a, [wPlayerBattleStatus3]
	bit 3, a ; is the mon transformed?
	jr nz, .recalcStatChanges
; the mon is not transformed, so update the unmodified stats
	ld de, wPlayerMonUnmodifiedLevel
	ld bc, 1 + NUM_STATS * 2
	call CopyData
.recalcStatChanges
	xor a ; battle mon
	ld [wCalculateWhoseStats], a
	callab CalculateModifiedStats
	callab ApplyBurnAndParalysisPenaltiesToPlayer
	callab ApplyBadgeStatBoosts
	callab DrawPlayerHUDAndHPBar
	callab PrintEmptyString
	call SaveScreenTilesToBuffer1
;all done dealing with the active pokemon in battle
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.printGrewLevelText
	ld hl, GrewLevelText
	call PrintText
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a

IF DEF(_EXPBAR)
	callba AnimateEXPBarAgain	;joenote - animate exp bar
ENDC

	call LoadMonData	;this clobbers the species value in wd0b5, which is needed for level-up moves
	ld d, $1
	callab PrintStatsBox
	call WaitForTextScrollButtonPress
	call LoadScreenTilesFromBuffer1
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	
	pop af			;restore saved species value
	ld [wd0b5], a
	ld [wd11e], a
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;This has to do with shinpokered fixes implemented in engine\evos_moves.asm
	;joenote - fixing skip move-learn glitch: here is where moves are learned from level-up, but it needs some changes
	ld a, [wCurEnemyLVL]	; load the level to advance to into a. this starts out as the final level.
	ld c, a	; load the final level to grow to over to c
	ld a, [wTempCoins1]	; load the current level into a
	ld b, a	; load the current level over to b
.inc_level	; marker for looping back 
	inc b	;increment 	the current level
	ld a, b	;put the current level in a
	ld [wCurEnemyLVL], a	;and reset the level to advance to as merely 1 higher
	push bc	;save b & c on the stack as they hold the current a true final level
	predef LearnMoveFromLevelUp
	pop bc	;get the current and final level values back from the stack
	ld a, b	;load the current level into a
	cp c	;compare it with the final level
	jr nz, .inc_level	;loop back again if final level has not been reached
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	predef LearnMoveFromLevelUp		;to restore vanilla functionality, comment out the above and uncomment this line

	ld hl, wCanEvolveFlags
	ld a, [wWhichPokemon]
	ld c, a
	ld b, FLAG_SET
	predef FlagActionPredef

	pop hl	;restore wPartyMon'X'Level
	pop af
	ld [wCurEnemyLVL], a	;restore the enemy level
	ret


;joenote - This function sets all party members with non-zero HP as flagged for getting a share of EXP
;With regards to wPartyGainExpFlags
;--Bit 0 of the flags represents the first mon in the party
;--Bit 5 of the flags represents the sixth mon in the party
SetExpAllFlags:
	push de	
	ld a, $1
	ld [wBoostExpByExpAll], a
	ld a, [wPartyCount]
	ld d, a
	ld e, %00000001
	ld hl, wPartyMon1HP
	ld bc, wPartyMon2HP - wPartyMon1HP
.gainExpFlagsLoop	
	ld a, [hli]
	or [hl] ; is mon's HP 0?
	jp z, .nextmon
	ld a, [wPartyGainExpFlags]
	or e
	ld [wPartyGainExpFlags], a
.nextmon 
	dec hl
	sla e
	add hl, bc
	dec d
	jr nz, .gainExpFlagsLoop
	pop de
	ret

	
GainedText:
	TX_FAR _GainedText
	TX_ASM
;joenote - changing exp all text for shinpokered, so these lines from vanilla are commented out
;	ld a, [wBoostExpByExpAll]
;	ld hl, WithExpAllText
;	and a
;	ret nz
	ld hl, ExpPointsText
	ld a, [wGainBoostedExp]
	and a
	ret z
	ld hl, BoostedText
	ret

WithExpAllText:
	TX_FAR _WithExpAllText
	TX_ASM
	ld hl, ExpPointsText
	ret

BoostedText:
	TX_FAR _BoostedText

ExpPointsText:
	TX_FAR _ExpPointsText
	db "@"

GrewLevelText:
	TX_FAR _GrewLevelText
	TX_SFX_LEVEL_UP
	db "@"


