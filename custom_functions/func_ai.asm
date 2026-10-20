;joenote - custom functions for determining which trainerAI pkmn have already been sent out before
;a=party position of pkmn (like wWhichPokemon). If checking, zero flag gives bit state (1 means sent out already)
CheckAISentOut:
	ld a, [wWhichPokemon]	
	cp $05
	jr z, .party5
	cp $04
	jr z, .party4
	cp $03
	jr z, .party3
	cp $02
	jr z, .party2
	cp $01
	jr z, .party1
	jr .party0
.party5
	ld a, [wFontLoaded]
	bit 6, a
	jr .partyret
.party4
	ld a, [wFontLoaded]
	bit 5, a
	jr .partyret
.party3
	ld a, [wFontLoaded]
	bit 4, a
	jr .partyret
.party2
	ld a, [wFontLoaded]
	bit 3, a
	jr .partyret
.party1
	ld a, [wFontLoaded]
	bit 2, a
	jr .partyret
.party0
	ld a, [wFontLoaded]
	bit 1, a
.partyret
	ret
	
SetAISentOut:
	ld a, [wWhichPokemon]	
	cp $05
	jr z, .party5
	cp $04
	jr z, .party4
	cp $03
	jr z, .party3
	cp $02
	jr z, .party2
	cp $01
	jr z, .party1
	jr .party0
.party5
	ld a, [wFontLoaded]
	set 6, a
	ld [wFontLoaded], a
	jr .partyret
.party4
	ld a, [wFontLoaded]
	set 5, a
	ld [wFontLoaded], a
	jr .partyret
.party3
	ld a, [wFontLoaded]
	set 4, a
	ld [wFontLoaded], a
	jr .partyret
.party2
	ld a, [wFontLoaded]
	set 3, a
	ld [wFontLoaded], a
	jr .partyret
.party1
	ld a, [wFontLoaded]
	set 2, a
	ld [wFontLoaded], a
	jr .partyret
.party0
	ld a, [wFontLoaded]
	set 1, a
	ld [wFontLoaded], a
.partyret
	ret
	
	

;joenote - custom functions for determining which trainerAI pkmn have already been switched out before
;a=party position of pkmn (like wEnemyMonPartyPos). If checking, zero flag gives bit state (1 means switched out already)	
CheckAISwitched:
	ld a, [de]	
	cp $05
	jr z, .party5
	cp $04
	jr z, .party4
	cp $03
	jr z, .party3
	cp $02
	jr z, .party2
	cp $01
	jr z, .party1
	jr .party0
.party5
	ld a, [wUnusedD366]
	bit 6, a
	jr .partyret
.party4
	ld a, [wUnusedD366]
	bit 5, a
	jr .partyret
.party3
	ld a, [wUnusedD366]
	bit 4, a
	jr .partyret
.party2
	ld a, [wUnusedD366]
	bit 3, a
	jr .partyret
.party1
	ld a, [wUnusedD366]
	bit 2, a
	jr .partyret
.party0
	ld a, [wUnusedD366]
	bit 1, a
.partyret
	ret

ClearAISwitched:
	ld a, [de]	
	cp $05
	jr z, .party5
	cp $04
	jr z, .party4
	cp $03
	jr z, .party3
	cp $02
	jr z, .party2
	cp $01
	jr z, .party1
	jr .party0
.party5
	ld a, [wUnusedD366]
	res 6, a
	jr .partyret
.party4
	ld a, [wUnusedD366]
	res 5, a
	jr .partyret
.party3
	ld a, [wUnusedD366]
	res 4, a
	jr .partyret
.party2
	ld a, [wUnusedD366]
	res 3, a
	jr .partyret
.party1
	ld a, [wUnusedD366]
	res 2, a
	jr .partyret
.party0
	ld a, [wUnusedD366]
	res 1, a
.partyret
	ret

SetAISwitched:
	ld a, [wUnusedC000]
	bit 5, a
	ret z	;no point to this function if AIMoveChoiceModification4 is not active
	ld a, [de]	
	cp $05
	jr z, .party5
	cp $04
	jr z, .party4
	cp $03
	jr z, .party3
	cp $02
	jr z, .party2
	cp $01
	jr z, .party1
	jr .party0
.party5
	ld a, [wUnusedD366]
	set 6, a
	ld [wUnusedD366], a
	jr .partyret
.party4
	ld a, [wUnusedD366]
	set 5, a
	ld [wUnusedD366], a
	jr .partyret
.party3
	ld a, [wUnusedD366]
	set 4, a
	ld [wUnusedD366], a
	jr .partyret
.party2
	ld a, [wUnusedD366]
	set 3, a
	ld [wUnusedD366], a
	jr .partyret
.party1
	ld a, [wUnusedD366]
	set 2, a
	ld [wUnusedD366], a
	jr .partyret
.party0
	ld a, [wUnusedD366]
	set 1, a
	ld [wUnusedD366], a
.partyret
	ret
	
	
;this function handles selecting which mon in an AI trainer should be sent out
AISelectWhichMonSendOut:
	ld b, $FF
	xor a
	ld [wAIPartyMonScores + 6], a
	
.partyloop	;the party loop, using b as a counter, grabs the position of the mon that is not currently out
	inc b
	ld a, [wEnemyMonPartyPos]	;wEnemyMonPartyPos is 0-indexed (1st mon is position 0). This address holds FF at the start of a battle.
	cp b
	jp z, .seeifdone	;next position if pointing to the same mon
	
	;check the HP of the mon
	ld a, b
	ld hl, wEnemyMon1
	push bc
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	pop bc
	inc hl	
	ld a, [hli]
	ld c, a
	ld a, [hl]
	or c
	jp z, .seeifdone	;go to next pkmn in roster if this one has zero HP
	
	ld a, b
	ld [wWhichPokemon], a	;else save the new mon's position
	
	ld a, [wUnusedC000]
	bit 5, a
	jp z, .sendOutNewMon	;skip all this if AI routine 4 has not run and done all the scoring
	ld a, [wAIPartyMonScores + 6]	;get the best score
	and a
	jr z, .updatebestscore	;skip if no best score assiged yet
	ld c, a		;load best score in c
	;get the position of the mon currently being looked at and point HL to its score
	ld a, [wWhichPokemon]
	ld hl, wAIPartyMonScores
	push bc
	ld bc, $00
	ld c, a
	add hl, bc
	pop bc
	;get the currently inspected mon's score and compare it to the best score
	ld a, [hl]
	cp c
	jr c, .keepcurrentbestscore
	jr z, .keepcurrentbestscore
.updatebestscore
	ld a, [wWhichPokemon]
	ld [wAIPartyMonScores + 7], a	;store the position with the best score so far
	ld hl, wAIPartyMonScores
	push bc
	ld bc, $00
	ld c, a
	add hl, bc
	pop bc
	ld a, [hl]	; get the best score so far
	ld [wAIPartyMonScores + 6], a	;store the best score so far
	jr .seeifdone
.keepcurrentbestscore
	ld a, [wAIPartyMonScores + 7]
	ld [wWhichPokemon], a
.seeifdone
	ld a, [wEnemyPartyCount]
	dec a	;make party counter zero-indexed
	cp b
	jp nz, .partyloop	;loop if the last party member hasn't been reached
	
.sendOutNewMon
	;we're done here, so the mon in the position held by wWhichPokemon will get sent out
	ret

	
	

ScoreAIParty:
	push de
	
	;copy hp, position, and status of the active pokemon to its roster position so it is properly scored
	ld a, [wEnemyMonPartyPos]
	ld hl, wEnemyMon1HP
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld d, h
	ld e, l
	ld hl, wEnemyMonHP
	ld bc, 4
	call CopyData	 
	
	ld a, [wEnemyPartyCount]	;value of 1 to 6
	ld b, a
	ld a, [wWhichPokemon]
	ld c, a
	ld hl, wEnemyMon1
	ld de, wAIPartyMonScores
.scoreloop
	ld a, $A0; set sefault score
	ld [de], a
	push bc
	
	;track which position mon we're on
	ld a, [wEnemyPartyCount]
	sub b
	ld [wWhichPokemon], a
	
	;check the HP of the mon
	push hl
	inc hl	
	ld a, [hli]
	ld c, a
	ld a, [hl]
	or c
	pop hl
	jr nz, .next0	;go to next check if hp > 0
	ld a, $0F
	ld [de], a
	jp .end_scoring_modules
.next0	
	
	;+2 score if faster than current player mon's speed
	ld bc, wPartyMon1Speed - wPartyMon1	
	call GetRosterStructData
	ld b, a	;store hi byte of speed in b
	ld a, [wBattleMonSpeed]	;store hi byte of player mon speed in a
	cp b
	jr nz, .next1	;if bytes are not equal, then rely on carry bit to see which is greater
	;else check the lo bytes
	ld bc, wPartyMon1Speed + 1 - wPartyMon1
	call GetRosterStructData
	ld b, a	;store lo byte of speed in b
	ld a, [wBattleMonSpeed + 1]	;store lo byte of player mon speed in a
	cp b
.next1
	ld b, 2
	call c, .plus	;if carry is set, then player mon has less speed
	
	
	;+2 score if at or above max base hp
	ld a, 1
	call AIRosterScoringCheckIfHPBelowFraction
	ld b, 2
	push af
	call nc, .plus
	pop af
	jr nc, .next2
	;-1 score if less than 3/4 base hp
	ld a, $34
	call AIRosterScoringCheckIfHPBelowFraction
	ld b, 1
	call c, .minus
	;-2 more (total of -3) score if less than 1/2 base hp
	ld a, 2
	call AIRosterScoringCheckIfHPBelowFraction
	ld b, 2
	call c, .minus
	;-2 more (total of -5) score if less than 1/4 base hp
	ld a, 4
	call AIRosterScoringCheckIfHPBelowFraction
	ld b, 2
	call c, .minus
.next2	


	;-5 for a mon with sleep counter > 1
	ld bc, wPartyMon1Status - wPartyMon1	;get status byte
	call GetRosterStructData
	ld c, a	;back up the status byte in c
	and SLP
	cp $02
	ld b, 5
	push af
	call nc, .minus
	pop af
	jr nz, .next3
	;-2 if burned, paralyzed, or poisoned
	ld a, c
	and (1 << BRN) | (1 << PSN) | (1 << PAR)
	ld b, 2
	push af
	call nz, .minus
	pop af
	jr nz, .next3
	;-10 if frozen
	ld a, c
	and (1 << FRZ)
	ld b, 10
	call nz, .minus
.next3


	;adjust score for the active player mon moves
	;first back up player move power and type
	ld a, [wPlayerMovePower]
	ld b, a
	ld a, [wPlayerMoveType]
	ld c, a
	push bc
	;back up wBuffer, then use wBuffer to store the current enemy mon score
	ld a, [wBuffer]
	push af
	ld a, [de]
	ld [wBuffer], a
	;set loop counter to 4
	ld c, $04
.playermoveloop
	;update the current score to be the lowest
	ld a, [de]
	ld b, a
	ld a, [wBuffer]
	cp b
	jr c, .playermoveloop_wBuffer	;if wBuffer < DE score, set DE score to wBuffer
	ld a, b	;else update wBuffer 
	ld [wBuffer], a
.playermoveloop_wBuffer
	ld [de], a
	;decrement counter, then exit out of loop if 4 moves reached
	ld a, c
	sub $01	;use sub instead of dec in order to affect carry bit
	ld c, a
	jp c, .playermoveloop_done
	;grab a player mon move
	push hl
	ld b, $00
	ld hl, wBattleMonMoves
	add hl, bc
	ld a, [hl]
	pop hl
	;do nothing if this is a null move
	and a
	jr z, .playermoveloop
	;save the player move power and type
	push bc
	push de
	push hl
	ld d, a
	callba ReadMoveForAIscoring
	ld a, e
	ld [wPlayerMoveType], a
	ld a, d
	ld [wPlayerMovePower], a
	pop hl
	pop de
	pop bc
	
	ld a, [wPlayerMovePower]	;get the power of the player's move
	cp $02	;regular damaging moves have power > 1
	jr c, .playermoveloop	;skip out if the move is not a normal damaging move
	;get effectiveness of the most recent player move
	call .get_effectiveness_to_enemy
	;now get the move-to-type effectiveness
	ld a, [wTypeEffectiveness]
	;skip if effectiveness is neutral
	cp $0A
	jp z, .playermoveloop
	;+15 to score if move has no effect
	cp $01
	ld b, 15
	push af
	call c, .plus
	pop af
	jp c, .playermoveloop
	;+10 to score if move has little effect
	cp $03
	ld b, 10
	push af
	call c, .plus
	pop af
	jp c, .playermoveloop
	;+5 to score if move is less effective
	cp $0A
	ld b, 5
	push af
	call c, .plus
	pop af
	jp c, .playermoveloop
	;at this point the move must be super effective
	;minus based on the power of the move
	ld a, [wPlayerMovePower]
	srl a	;-1/2 power
	srl a	;-1/4 power
	ld b, a
	call .minus	
;-15 to score if:
;	-> the 'mon currently being scored is not the active 'mon
;	-> and the player is not using a trapping move against the AI
;this is to discourage switching a 'mon straight into a super-effective attack
;but its safe to switch out of a trapping move because the player loses a turn
	ld a, [wWhichPokemon]
	ld b, a
	ld a, [wEnemyMonPartyPos]
	cp b
	jp z, .playermoveloop
	ld a, [wPlayerBattleStatus1]
	bit USING_TRAPPING_MOVE, a
	jp nz, .playermoveloop	
	ld b, 15
	call .minus
	jp .playermoveloop
.playermoveloop_done
	;restore player move power and type as well as wBuffer
	pop af
	ld [wBuffer], a
	pop bc
	ld a, c
	ld [wPlayerMoveType], a
	ld a, b
	ld [wPlayerMovePower], a
.next4

	
	;adjust score based on having any regular damaging moves
	ld a, $00
	ld [wAIPartyMonScores + 6], a	;set a default score tracker: (bits 0 to 6--> 0-5=-5, 0A = 0, 14 or more=+2)(bit 7 set for 60+ power) 
	ld a, [wUnusedC000]
	res 3, a ;get effectiveness of enemy moves
	ld [wUnusedC000], a
	ld bc, $08	;set offest to point to first move of current mon
.enemymoveloop
	ld a, $0C
	cp c	
	jp z, .enemymoveloop_done	;exit loop if incremented beyond 4th move slot
	call GetRosterStructData ;get the move and put it into a
	and a
	jp z, .enemymoveloop_done	;exit loop if reached an empty move slot
	push bc
	push hl
	push de
	ld d, a
	callba ReadMoveForAIscoring	;takes move in d, returns its power in d and type in e
	ld a, d	;get the power of the move
	cp $02	;regular damaging moves have power > 1
	jr c, .next5
	push af	;save the power in a
	ld a, [wEnemyMoveType]
	ld [wAIPartyMonScores + 7], a
	ld a, e	;get the type of the move
	ld [wEnemyMoveType], a
	callba AIGetTypeEffectiveness
	ld a, [wAIPartyMonScores + 7]
	ld [wEnemyMoveType], a
	pop af	;get the power back in a
	ld c, a	;and put it in c
	ld a, [wAIPartyMonScores + 6]	;get the current score tracker
	and $7F	;mask out highest bit
	ld b, a	;and put it in b
	ld a, [wTypeEffectiveness]	;get the found type effectiveness
	cp b
	jr c, .next5	;if the type effectiveness is less than the current score tracker then loop to next move
	ld [wAIPartyMonScores + 6], a	;else update score tracker
	ld a, c
	cp $3C	;set score tracker bit if power of this move 60+
	jr c, .next5
	ld a, [wAIPartyMonScores + 6]
	set 7, a
	ld [wAIPartyMonScores + 6], a
.next5
	pop de
	pop hl
	pop bc
	inc c
	jp .enemymoveloop
.enemymoveloop_done
	ld a, [wAIPartyMonScores + 6]
	and $7F
	;-5 score if no moves are decently effective
	cp $0A
	ld b, 5
	push af
	call c, .minus
	pop af
	;no score adjustment for a neutral move
	jr z, .next6
	;+2 score if there's a supereffective move
	cp $14
	ld b, 2
	call nc, .plus
	;+3 more score (+5 total) if the supereffective move is 60 power or more
	ld a, [wAIPartyMonScores + 6]
	bit 7, a
	ld b, 3
	call nz, .plus
.next6	
		
	
	;-5 score if AISwitch flag has been set for some reason
	push de
	ld de, wWhichPokemon
	call CheckAISwitched
	pop de
	jr z, .next7
	ld b, 5
	call nz, .minus
.next7	


	;score penalty if opponent could have STAB against the pointed-to enemy mon
	ld a, [wPlayerMoveType]
	push af
	;check player type 1 effectiveness
	ld a, [wBattleMonType]
	ld [wPlayerMoveType], a
	call .get_effectiveness_to_enemy
	ld b, 3	;-3 for 2x effective or -6 if 4x effective
	ld a, [wTypeEffectiveness]
	push af
	cp $10
	call nc, .minus
	pop af
	cp $15
	call nc, .minus
	;jump if there is no type 2
	push hl
	ld hl, wBattleMonType
	ld a, [wBattleMonType + 1]
	cp [hl]
	pop hl
	jr z, .next8
	;else do type 2 now
	ld [wPlayerMoveType], a
	call .get_effectiveness_to_enemy
	ld b, 3	;-3 for 2x effective or -6 if 4x effective
	ld a, [wTypeEffectiveness]
	push af
	cp $10
	call nc, .minus
	pop af
	cp $15
	call nc, .minus
.next8	
	pop af
	ld [wPlayerMoveType], a
	
.end_scoring_modules
	pop bc
	dec b
	jr z, .donescoring
	push bc
	ld bc, wEnemyMon2 - wEnemyMon1
	add hl, bc
	pop bc
	inc de
	jp .scoreloop
.donescoring
	pop de
	ld a, c
	ld [wWhichPokemon], a
	jp AIAbortMonSendOut
.plus
	ld a, [de]
	add b
	call c, .overflow
	ld [de], a
	ret
.minus
	ld a, [de]
	sub b
	call c, .underflow
	ld [de], a
	ret
.overflow
	ld a, $FF
	ret
.underflow
	ld a, $00
	ret
.get_effectiveness_to_enemy
	ld a, [wUnusedC000]
	set 3, a 
	ld [wUnusedC000], a
	;preserve the current enemy mon typing
	ld a, [wEnemyMonType]
	ld [wAIPartyMonScores + 6], a
	ld a, [wEnemyMonType + 1]
	ld [wAIPartyMonScores + 7], a
	;override the current enemy mon typing with that from the roster pointer
	push bc
	ld bc, wPartyMon1Type1 - wPartyMon1
	call GetRosterStructData
	ld [wEnemyMonType], a
	ld bc, wPartyMon1Type2 - wPartyMon1
	call GetRosterStructData
	ld [wEnemyMonType + 1], a
	pop bc
	;now get the typing effectiveness
	push bc
	push hl
	push de
	callab AIGetTypeEffectiveness
	pop de
	pop hl
	pop bc
	;now undo the current mon type override
	ld a, [wAIPartyMonScores + 6]
	ld [wEnemyMonType], a
	ld a, [wAIPartyMonScores + 7]
	ld [wEnemyMonType + 1], a
	ret
	
	

;sets the carry bit if current mon score < highest score of remaining roster	
AIAbortMonSendOut:
	ld a, [wWhichPokemon]
	ld b, a
	push bc
	call AISelectWhichMonSendOut	;this will get the mon with the highest score that is neither KO'd nor the active mon
	pop bc
	ld a, b
	ld [wWhichPokemon], a
	
	ld a, [wAIPartyMonScores + 6]
	ld b, a
	push bc
	
	ld a, [wEnemyMonPartyPos]
	ld c, a
	ld b, $00
	ld hl, wAIPartyMonScores
	add hl, bc
	pop bc
	
	
	ld a, [wEnemyBattleStatus3]
	bit 0, a	;check a for the toxic bit on active mon
	ld a, [hl]
	call nz, .dec5	;-5 score if badly poisoned
	
	ld a, [wPlayerBattleStatus1]
	bit 5, a	;check a for trapping move bit 
	ld a, [hl]
	call nz, .dec5	;-5 score if stuck in a trapping move
	
	ld a, [wEnemyBattleStatus1]
	bit 7, a	;check a for the confusion bit 
	ld a, [hl]
	call nz, .dec2	;-2 score if confused
	
	ld a, [wEnemyBattleStatus2]
	bit 7, a	;check a for the leech seed bit 
	ld a, [hl]
	call nz, .dec2	;-2 score if seeded
	
	ld a, [wEnemyDisabledMove] ; get disabled move (if any)
	swap a
	and $f
	ld a, [hl]
	call nz, .dec2	;-2 score if a move is disabled
	
	push bc
	;use b for storage and a for loading
	ld a, [wEnemyMonAttackMod]	
	ld b, a 
	ld a, [wEnemyMonDefenseMod]
	cp b
	call c, .ldba	;if a < b, then load a into b
	ld a, [wEnemyMonSpeedMod]
	cp b
	call c, .ldba	;if a < b, then load a into b
	ld a, [wEnemyMonSpecialAttackMod]
	cp b
	call c, .ldba	;if a < b, then load a into b
	ld a, [wEnemyMonSpecialDefenseMod]
	cp b
	call c, .ldba	;if a < b, then load a into b
	ld a, [wEnemyMonAccuracyMod]
	cp b
	call c, .ldba	;if a < b, then load a into b
	ld a, [wEnemyMonEvasionMod]
	cp b
	call c, .ldba	;if a < b, then load a into b
	ld a, b	;put b back into a
	pop bc
	cp $07	;is the lowest stat mod the normal value of 7?
	jr nc, .compare		;lowest stat mod is not negative (value below 7)
	push bc
	ld b, a	;put the lowest mod into b
	ld a, $07	; put 7 into a
	sub b	;a = 7 - b, so a becomes 6 (-6 stages) to 1 (-1 stage)
	ld b, a	;put a back into b
	;add the lowest mod to the score
	ld a, [hl]
	sub b
	ld [hl], a
	pop bc
	
.compare
	ld a, [hl]
	cp b	;(current mon score - highest other mon score)
	ret
.dec5
	dec a
	dec a
	dec a
.dec2
	dec a
	dec a
	ld [hl], a
	ret
.ldba
	ld b, a
	ret

	
	
	
; return carry if enemy trainer's current HP is below 1 / a of the maximum
; adapted to work with the roster scoring functions
; preserves hl and de
; the max hp is the base max value since true max hp is calculated upon every sendout and not stored anywhere
AIRosterScoringCheckIfHPBelowFraction:
;first preserve stuff onto the stack
	push de
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - handle an 'a' value of 1
	cp 1
	jr nz, .not_one
	ld bc, wPartyMon1MaxHP - wPartyMon1
	call GetRosterStructData
	ld d, a
	ld bc, wPartyMon1HP - wPartyMon1
	call GetRosterStructData
	cp d	;a = HP MSB an d = MAXHP MSB so do a - d and set carry if negative
	jr c, .return
	ld bc, wPartyMon1MaxHP + 1 - wPartyMon1
	call GetRosterStructData
	ld d, a
	ld bc, wPartyMon1HP + 1 - wPartyMon1
	call GetRosterStructData
	cp d	;a = HP LSB an d = MAXHP LSB so do a - d and set carry if negative
	jp .return
.not_one
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	cp $34
	jr nz, .not3fourths
	ld bc, wPartyMon1MaxHP - wPartyMon1
	call GetRosterStructData
	ld d, a
	ld bc, wPartyMon1MaxHP + 1 - wPartyMon1
	call GetRosterStructData
	ld e, a
	;de now holds the max hp value
	ld a, d
	srl a
	ld d, a
	ld a, e
	rra
	ld e, a
	;de now holds half max hp
	ld a, d
	srl a
	ld d, a
	ld a, e
	rra
	ld e, a
	;de now holds 1/4 max hp
	push hl
	ld hl, $0000
	add hl, de
	add hl, de
	add hl, de
	ld d, h
	ld e, l
	pop hl
	;de now holds 3/4ths max hp
	push de
	ld bc, wPartyMon1HP - wPartyMon1
	call GetRosterStructData
	ld d, a
	ld bc, wPartyMon1HP + 1 - wPartyMon1
	call GetRosterStructData
	ld c, a
	ld a, d
	ld b, a
	pop de
	;now bc holds current hp and de holds 3/4ths max hp
	ld a, b
	sub d
	jr nz, .return
	ld a, c
	sub e
	jr .return
.not3fourths
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	push hl
	ld [H_DIVISOR], a
	ld bc, wPartyMon1MaxHP - wPartyMon1
	add hl, bc
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
	pop hl
	push hl
	ld de, $02
	add hl, de
	ld a, [hld]
	ld e, a
	ld a, [hl]
	pop hl
	ld d, a
	ld a, d
	sub b
	jr nz, .return
	ld a, e
	sub c
.return	;joenote - consolidating returns with the stack
	pop de
	ret
	
	
	
	
;hl should point at a party struct such as wEnemyMon1
;bc holds an offset
;returns the value of the offsetted in a
GetRosterStructData:
	push hl
	add hl, bc
	ld a, [hl]
	pop hl
	ret



;let's get some PP tracking for enemies both trainer and wild
ChooseMovePPTrack:
	;retrieve hl pointer
	ld a, [wUnusedCF8D]
	ld h, a
	ld a, [wUnusedCF8D + 1]
	ld l, a	
	ld b, e	;retrieve move number
;b holds the move slot (1 to 4)

	call IsTrainerBattlePPCheck

	ld a, b
	dec a
	ld [wEnemyMoveListIndex], a
;is move disabled?
	ld a, [wEnemyDisabledMove]
	swap a
	and $f
	cp b
	jp z, .flagset
;a Choice item allows only the move it locked in, while that has PP
	ld a, [wEnemyChoiceLock]
	and a
	jr z, .notChoiceLocked
	cp b
	jr z, .notChoiceLocked
	push hl
	push bc
	ld c, a
	ld b, 0
	ld hl, wEnemyMonPP - 1
	add hl, bc
	ld a, [hl]
	and $3f
	pop bc
	pop hl
	jp nz, .flagset
.notChoiceLocked
;is the move non-existant?
	ld a, [hl]
	and a
	jp z, .flagset
;now check the PP for the slot specified by "b"
	push hl
	ld hl, wEnemyMonPP
	push bc
	ld c, b
	ld b, 0
	dec bc
	add hl, bc
	pop bc
	ld a, [hl]
	and a
	jr z, .PPexhausted
.PPremaining
	;else decrement PP
	dec a
	ld [hl], a
	ld a, 1
	ld e, a	;return nz flag if there was PP left
	push bc
	call transformPPtasks
	pop bc
	pop hl
	jp .back
.PPexhausted	;return zero flag if no PP left
	pop hl
.flagset	;d is holding flags for unusable moves
	ld e, 0
	ld a,  b
	cp 4
	jr z, .move4
	cp 3
	jr z, .move3
	cp 2
	jr z, .move2
.move1
	set 0, d
	jr .back
.move2
	set 1, d
	jr .back
.move3
	set 2, d
	jr .back
.move4
	set 3, d
.back
	ld a, h
	ld [wUnusedCF8D], a
	ld a, l
	ld [wUnusedCF8D + 1], a
	ret


;this function will try to pick a trainer's preferred choice of move
;while also taking into account unusable moves
IsTrainerBattlePPCheck:
	ld a, [wIsInBattle]
	cp 2
	ret nz

;first, adjust the scores in the backup buffer so that unusable moves are maxed out (based on flags in d)
	push hl
	push de
	ld hl, wBuffer + NUM_MOVES
	ld e, NUM_MOVES
.loop
	rr d
	call c, .disabled_move
	inc hl
	dec e
	jr nz, .loop
	pop de
	pop hl
	
;now determine if the randomly chosen move is a preferred move that is usuable
	ld a, [hl]
	and a
	jr z, .next	;not preferred if zero; else check against backup score
	push hl
	push bc
	ld bc, NUM_MOVES
	add hl, bc
	pop bc
	ld a, [hl]
	pop hl
	cp $ff
	jr nz, .done	;the preferred move is not unuseable so we're good to go
.next	

;so the randomly picked move is either not preferred or is preferred but unusable
;in that case, pick the move with the lowest score moving towards the left and circling back if needed
	push hl
	push de
	push bc
	;move HL to the backup score buffer and set the loop counter
	push bc
	ld bc, NUM_MOVES
	add hl, bc
	pop bc
	ld c, NUM_MOVES	
	;initialize current score as best score
	ld a, [hl]
	ld e, a
	;initialize current move position as best move
	ld d, b
.loop2
	ld a, [hl]
	cp e
	call c, .updateBestScore
	dec hl
	dec b
	call z, .circleB
	dec c
	jr nz, .loop2
	pop bc
	ld b, d
	pop de
	pop hl

.done
	ld hl, wEnemyMonMoves
	push bc
	ld c, b
	ld b, 0
	dec bc
	add hl, bc
	pop bc
	ret
.disabled_move
	ld a, $ff
	ld [hl], a
	ret
.updateBestScore
	ld e, a
	ld d, b
	ret
.circleB
	ld b, NUM_MOVES
	push bc
	ld bc, NUM_MOVES
	add hl, bc
	pop bc
	ret

;if trainer uses Transform, then write its PP to party struct
transformPPtasks:
;	return if not a trainer battle since there is no need to update the party struct PP
	ld a, [wIsInBattle]
	cp 2
	ret nz

	ld c, b
	ld b, 0
	dec bc
	
;	return if the move being used is not Transform
	ld hl, wEnemyMonMoves
	add hl, bc
	ld a, [hl]
	cp TRANSFORM
	ret nz
	
;	return if using the Transform move while already transformed into something
	ld a, [wEnemyBattleStatus3]
	bit 3, a
	ret nz
	
	ld hl, wEnemyMonPP
	add hl, bc
	ld a, [hl]
	push af
	
	ld hl, wEnemyMon1PP
	add hl, bc
	ld a, [wEnemyMonPartyPos]
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	
	pop af
	ld [hl], a
	ret

advancedLoadPP:
	ld a, [wIsInBattle]
	cp 1
	jr z, .doRegular	;don't do anything special for wild battles
	;else see if the mon has been sent out before
	call CheckAISentOut
	jr z, .doRegular	;don't do anything special if the mon has not been out before

	;else load its PPs from the wEnemyMonxPP
	ld a, [wWhichPokemon]
	ld hl, wEnemyMon1PP
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	;HL now points to wEnemyMonxPP
	ld de, wEnemyMonPP
	ld bc, $0004
	call CopyData	;copy the pp data from wEnemyMonxPP to wEnemyMonPP
	ret
.doRegular
	ld hl, wEnemyMonMoves
	ld de, wEnemyMonPP - 1
	predef LoadMovePPs
	ret
