;Note from the shinpokered cabal:
;Hey dude. If you're looking at this file, 
;then you're probably trying to do stuff with the experience code in your own rom hack.
;You also probably have glazed-over eyes and a smashed keyboard from trying to make sense of things.
;Well, this one goes out to you.
;This file tries to rewrite, consolidate, fix, and comment all the exp gain code.
;The parts that are exclusive to shinpokered are marked so vanilla functionality can be achieved.
;Feel free to take this file and implement it for your own pokered-based project.
;This takes about the same time to run as the original code, but at least it is easier to manage and modify.

;Gen 9's experience: the party mons that took part (or hold an Exp. Share) gain
;it in full; with the EXP. SHARE option on (Gen 9's always-on Exp. Share), or
;else with the EXP ALL in the bag, the rest of the team gains half, by Gen 7+'s level-scaled formula (ScaledExp), then x1.5 if traded, x1.5
;with a Lucky Egg, x1.2 past the level it could have evolved at. Each of them
;gains the enemy's EV yield too.
GainExperience:
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	ret z ; return if link battle

;shinpokered feature having to do with the GBC double speed CPU mode
;Running in double speed CPU mode shaves off about 1 second of computation delay
	predef SetCPUSpeed

	callab ExpShareHolders ; they count as having taken part
	ld a, [wPartyGainExpFlags]
	ld [wUnusedD155], a ; who took part
	xor a
	ld [wWhichPokemon], a
	ld [wBoostExpByExpAll], a ; set if any mon gains the Exp. Share's half
.loop
	ld a, [wWhichPokemon]
	ld hl, wPartyCount
	cp [hl]
	jp nc, .done
	ld hl, wPartyMon1HP
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hli]
	or [hl]
	jp z, .nextMon ; fainted: nothing
; its share: 1 if it took part, else 2 if the rest of the team gains half
	ld a, [wWhichPokemon]
	inc a
	ld b, a
	ld a, [wUnusedD155]
.findBit
	rrca
	dec b
	jr nz, .findBit
	ld a, 1
	jr c, .gotShare
	push hl
	call RestOfTeamGainsExp
	pop hl
	jp z, .nextMon ; no share: no EXP and no EVs, as in the original game
	ld a, 2
	ld [wBoostExpByExpAll], a
.gotShare
	ld [wExpScratch + 1], a
	ld bc, wPartyMon1Level - (wPartyMon1HP + 1)
	add hl, bc
	ld a, [hl]
	ld [wExpScratch], a
; the EVs
	ld bc, wPartyMon1EVs - wPartyMon1Level
	add hl, bc
	ld d, h
	ld e, l
	callab GiveEnemyEVs
; the experience
	callab ScaledExp
	call CatchUpBoost ;shinpokered-master feature
	ld hl, wPartyMon1OTID
	ld a, [wWhichPokemon]
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	push hl		;preserve wPartyMon'X'OTID

	call AddExpToPokemon
	;HL  now equals wPartyMon'X'Exp
	call CapExpAtMaxLevel
	;HL  still equals wPartyMon'X'Exp
	ld a, [wExpScratch + 1]
	dec a
	call z, PrintExpGained ; those that took part; the rest get one line at the end
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
	call nz, LevelUpPokemon
	pop hl	;HL equals wPartyMon'X'OTID
.nextMon
	ld hl, wWhichPokemon
	inc [hl]
	jp .loop

.done
	ld a, [wBoostExpByExpAll]
	and a
	jr z, .noShare
	ld hl, TeamGainedExpText
	call PrintText
.noShare
	xor a
	ld [wBoostExpByExpAll], a

	;shinpokered feature having to do with the GBC double speed CPU mode
	predef SingleCPUSpeed

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

; nz if the party mons that didn't take part gain half: the EXP. SHARE option
; (Gen 9) or, without it, the EXP ALL in the bag
RestOfTeamGainsExp:
	CheckEvent EVENT_EXP_SHARE_ON
	ret nz
	ld b, EXP_ALL
	jp IsItemInBag

TeamGainedExpText:
	TX_FAR _TeamGainedExpText
	db "@"

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

	
;multiplies exp by 1.2
BoostExpByFifth:
	ld a, [H_QUOTIENT + 2]
	ld b, a
	ld a, [H_QUOTIENT + 3]
	ld c, a
	push bc
	xor a
	ld [H_QUOTIENT], a
	ld [H_QUOTIENT + 1], a
	ld a, 5
	ld [H_DIVISOR], a
	ld b, 4
	call Divide ; a fifth
	pop bc
	ld a, [H_QUOTIENT + 3]
	add c
	ld [H_QUOTIENT + 3], a
	ld a, [H_QUOTIENT + 2]
	adc b
	ld [H_QUOTIENT + 2], a
	ret nc
	ld a, $FF
	ld [H_QUOTIENT + 2], a
	ld [H_QUOTIENT + 3], a
	ret

;joenote - apply a big exp boost if an underleveled active pokemon scored the K.O.
;shinpokered-master feature
CatchUpBoost:	
	CheckEvent EVENT_8D9
	ret z
	ld a, [wBattleMonLevel]
	ld b, a
	ld a, [wEnemyMonLevel]	
	sub b
	ret z	;return if enemy lvl = player level
	ret c	;return if enemy lvl < player level
.loop
	;A is currently wEnemyMonLevel - wBattleMonLevel > 0
	push af
	call BoostExp
	pop af
	sub 3	;additional boost every 3 levels of difference
	jr nc, .loop	;keep boosting until A underflows
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
; a Lucky Egg: x1.5 more
	push hl
	ld bc, wPartyMon1CatchRate - wPartyMon1OTID
	add hl, bc
	ld a, [hl]
	pop hl
	cp LUCKY_EGG
	jr nz, .noLuckyEgg
	call BoostExp
	ld a, 1
	ld [wGainBoostedExp], a
.noLuckyEgg
; past the level it could have evolved at: x1.2
	push hl
	push de
	ld bc, wPartyMon1Species - wPartyMon1OTID
	add hl, bc
	ld a, [hl]
	ld [wd0b5], a
	ld bc, wPartyMon1Level - wPartyMon1Species
	add hl, bc
	ld a, [hl]
	ld [wExpScratch], a
	callab PastEvolutionLevel
	pop de
	pop hl
	call c, BoostExpByFifth

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

	call PrintText
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
	ld bc, wPartyMon1EVs - wPartyMon1MaxHP
	add hl, bc	;HL = wPartyMon'X'EVs
	ld b, $1 ; consider the EVs when calculating stats
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
; its own name: a mon that didn't take part never printed "gained", so
; wcd6d still held another mon's name or a move's
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	ld hl, GrewLevelText
	call PrintText
	xor a ; PLAYER_PARTY_DATA
	set 7, a	;for shinpokered-related stuff, indicate that stat display is for level-up in case we're in the middle of battle
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


