
;joenote - custom functions to handle move priority. Sets zero flag if priority lowered/raised.
CheckLowerPlayerPriority:	
	ld a, [wPlayerSelectedMove]
	call LowPriorityMoves
	ret
CheckLowerEnemyPriority:
	ld a, [wEnemySelectedMove]
	call LowPriorityMoves
	ret
LowPriorityMoves:
	cp COUNTER
;	ret z
;	cp DUMMY_MOVE1
;	ret z
;	cp DUMMY_MOVE2
;	ret z
;	cp DUMMY_MOVE3
;	ret z
;	cp DUMMY_MOVE4
	ret

CheckHigherPlayerPriority:	
	ld a, [wPlayerSelectedMove]
	call HighPriorityMoves
	ret
CheckHigherEnemyPriority:
	ld a, [wEnemySelectedMove]
	call HighPriorityMoves
	ret
HighPriorityMoves:
	cp QUICK_ATTACK
;	ret z
;	cp DUMMY_MOVE1
;	ret z
;	cp DUMMY_MOVE2
;	ret z
;	cp DUMMY_MOVE3
;	ret z
;	cp DUMMY_MOVE4
	ret



;custom function to determin the DVs of wild pokemon with an option for forcing shiny DVs
DetermineWildMonDVs:
	ld a, [wFontLoaded]	;force a wild pokemon with shiny DVs for Gen 2 if bin 7 is set
	bit 7, a
	jr z, .do_random
	ld b, $AA
	call Random	;get random number into a
	or $20	;set only bit 5
	and $F0 ; clear the lower nybble
	or $0A	;set the lower nyble to $A
	jr .load
.do_random
	call IsInSafariZone
	jr nz, .do_random_safari	
.notsafari
	call Random_DV
	jr .load
.do_random_safari
;	call Random_BiasDV		;option to make safari zone pokemon have better DVs
	call Random_DV
.load
	push hl
	ld hl, wEnemyMonDVs
	ld [hli], a
	ld [hl], b
	pop hl
	ld a, [wFontLoaded]
	res 7, a 
	ld [wFontLoaded], a
	ret
	
	

SwapTurn:	;a simple custom function for swapping whose turn it is in the battle engine
	ld a, [H_WHOSETURN]
	and a
	jr z, .make_one
	xor a
	jr .leave
.make_one
	inc a
.leave
	ld [H_WHOSETURN], a
	ret



;returns z flag if on the first attack
;returns z flag cleared if not on the first or not applicable
TestMultiAttackMoveUse_firstAttack:
	call TestMultiAttackMoveUse
	ret nz
	ld a, l
	and a
	ret
;returns z flag set if on the last attack
;returns z flag cleared if not on the last attack or not applicable
TestMultiAttackMoveUse_lastAttack:
	call TestMultiAttackMoveUse
	ret nz
	ld a, l
	cp 1
	ret
;returns with z flag set if using a multi-attack move 
;returns with L = attacks left
TestMultiAttackMoveUse:
	ld a, [H_WHOSETURN]
	and a
	push bc
	ld a, [wPlayerMoveNum]
	ld b, a
	ld a, [wPlayerMoveEffect]
	ld h, a
	ld a, [wPlayerNumAttacksLeft]
	ld l, a
	jr z, .next1
	ld a, [wEnemyMoveNum]
	ld b, a
	ld a, [wEnemyMoveEffect]
	ld h, a
	ld a, [wEnemyNumAttacksLeft]
	ld l, a
.next1
	ld a, b
	pop bc
	cp TWINEEDLE
	jr z, .multi_attack
	ld a, h
	cp ATTACK_TWICE_EFFECT
	jr z, .multi_attack
	cp TWO_TO_FIVE_ATTACKS_EFFECT
	jr nz, .done_multi
.multi_attack
	;at this line, we are dealing with a multi-attack or two-attack move
	xor a
	ret
.done_multi
	ld a, 1
	and a
	ret



EnemyBideAccum:
	ld hl, wEnemyBattleStatus1
	bit STORING_ENERGY, [hl] ; is mon using bide?
	ret z
	xor a
	ld [wEnemyMoveNum], a
	ld hl, wDamage
	ld a, [hli]
	ld b, a
	ld c, [hl]
	ld hl, wEnemyBideAccumulatedDamage + 1
	ld a, [hl]
	add c ; accumulate damage taken
	ld [hld], a
	ld a, [hl]
	adc b
	ld [hl], a
	ret

PlayerBideAccum:
	ld hl, wPlayerBattleStatus1
	bit STORING_ENERGY, [hl] ; is mon using bide?
	ret z
	xor a
	ld [wPlayerMoveNum], a
	ld hl, wDamage
	ld a, [hli]
	ld b, a
	ld c, [hl]
	ld hl, wPlayerBideAccumulatedDamage + 1
	ld a, [hl]
	add c ; accumulate damage taken
	ld [hld], a
	ld a, [hl]
	adc b
	ld [hl], a
	ret


	
;These functions try to handle and correct situations where 
;the disable effect, with a counter of 1, applied to a slower 'mon
;will cause the effect to immediately wear off.
PlayerDisableHandler:
	call GetPredefRegisters
	;hl points to wPlayerDisabledMove at this line
	
	;continue if the counter nybble is not valid: either it is 0 or between 9 and F
	;else return because a valid counter of 1-8 exists
	ld a, [hl]
	and $0F
	cp 9
	jr nc, .continue
	and a
	ret nz
	
.continue
	;now restore the counter values to a valid 1-8 distribution
	sub 8 
	jr nc, .valid_count
	;if there was an underflow because of subtracting from 0, then make the value 8
	ld a, 8
.valid_count
	push bc
	ld b, a
	ld a, [hl]
	and $F0
	or b
	pop bc
	ld [hl], a
	;counter is now 1 to 8
	
	;now test to see if going second in the round
	ld a, [H_WHOFIRST]
	and a
	ret z	;return if player going first
	
	;The player is going second at this line.
	;So the counter will have one of the following outcomes at the start of the next round: [0,1,2,3,4,5,6,7].
	;This is because it's assumed the counter will decrement after returning from this function.
	;But said distribution is really supposed to be [1,2,3,4,5,6,7,8] like it is if going first.
	;If the counter is 1 right now, it will decrement to zero. A value of 8 is also unattainable. Both are undesireable. 

	;See if the counter is = 1 and return if not
	ld a, [hl]
	and $0F
	cp $01
	ret nz
	
	;now confirmed that: 
	;--> the counter is initialized to 1 this round. 
	;--> going second this round.
	;so covert the 1 into an 9 so it can be decremented to 8 after returning
	ld a, [hl]
	add 8
	ld [hl], a
.return
	ret

EnemyDisableHandler:
	call GetPredefRegisters
	;hl points to wEnemyDisabledMove at this line
	
	;continue if the counter nybble is not valid: either it is 0 or between 9 and F
	;else return because a valid counter of 1-8 exists
	ld a, [hl]
	and $0F
	cp 9
	jr nc, .continue
	and a
	ret nz
	
.continue
	;now restore the counter values to a valid 1-8 distribution
	sub 8 
	jr nc, .valid_count
	;if there was an underflow because of subtracting from 0, then make the value 8
	ld a, 8
.valid_count
	push bc
	ld b, a
	ld a, [hl]
	and $F0
	or b
	pop bc
	ld [hl], a
	;counter is now 1 to 8
	
	;now test to see if going second in the round
	ld a, [H_WHOFIRST]
	and a
	ret nz	;return if enemy going first
	
	;The enemy is going second at this line.
	;So the counter will have one of the following outcomes at the start of the next round: [0,1,2,3,4,5,6,7].
	;This is because it's assumed the counter will decrement after returning from this function.
	;But said distribution is really supposed to be [1,2,3,4,5,6,7,8] like it is if going first.
	;If the counter is 1 right now, it will decrement to zero. A value of 8 is also unattainable. Both are undesireable. 

	;See if the counter is = 1 and return if not
	ld a, [hl]
	and $0F
	cp $01
	ret nz
	
	;now confirmed that: 
	;--> the counter is initialized to 1 this round. 
	;--> going second this round.
	;so covert the 1 into an 9 so it can be decremented to 8 after returning
	ld a, [hl]
	add 8
	ld [hl], a
.return
	ret

	
	
SetAttackAnimPal:
	call GetPredefRegisters

	;set wAnimPalette based on if in grayscale or color
	ld a, $e4
	ld [wAnimPalette], a
	ld a, [wOnSGB]
	and a
	ret z
	ld a, $f0
	ld [wAnimPalette], a
	
	;return if not on a GBC
	ld a, [hGBC]
	and a
	ret z 
	
	ld a, [wIsInBattle]
	and a
	ret z

	;only continue for valid move animations
	ld a, [wAnimationID]
	and a
	ret z
	cp STRUGGLE		;check for non-move battle animations
	call nc, CheckIfBall
	jp z, SetAttackAnimPal_otheranim	;reset battle pals for any other battle animations
	
	ld a, $e4
	ld [wAnimPalette], a
	
	push hl
	push bc
	push de
	ld a, [wcf91]
	push af
	
	call CheckIfBall
	jr nz, .do_ball_color
	
;doing a move animation, so find its type and apply color
	ld a, [H_WHOSETURN]
	and a
	ld hl, wPlayerMoveType
	jr z, .playermove
	ld hl, wEnemyMoveType
.playermove
	ld a, [hl]
	ld bc, $0000
	ld c, a
	ld hl, TypePalColorList
	add hl, bc
	ld a, [hl]
	ld b, a

	;check if this animation is being played when hurting self from confusion
	ld a, [wUnusedD119]
	inc a
	ld a, [wUnusedC000]
	jr nz, .noselfdamage
	;if hurting self, load default palette
	ld b, PAL_BW
	jr .starttransfer
.noselfdamage

	bit 6, a	;check the bit that is set when absorbing HP due to leech seed
	jr z, .noleechseed
	;if absorbing, load default palette
	ld b, PAL_GREENMON
	jr .starttransfer
.noleechseed

	nop		;debugging placeholder
.starttransfer
	;make sure to reset palette/shade data into OBP0
	;have to do this so colors transfer to the proper positions
;	ld a, %11100100
;	ld [rOBP0], a
;NOTE: rOBP0 value is now set before entering this function, and colors will transfer based on its value
;		;Typically this will be $E4 or a complemented version of it
	
	ld c, 4
.transfer
	ld d, CONVERT_OBP0
	ld e, c
	dec e
	ld a, b	
	add VICTREEBEL+1
	ld [wcf91], a
	push bc
	callba TransferMonPal
	pop bc
	dec c
	jr nz, .transfer
	
	pop af
	ld [wcf91], a
	pop de
	pop bc
	pop hl
	ret	
.do_ball_color
	ld a, [wcf91]
	ld hl, ItemPalList
	ld b, 0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld b, a
	jr .starttransfer
;this functions sets z flag if not using a ball item, otherwise clears z flag if using a ball item
CheckIfBall:
	ld a, [wAnimationID]
	cp TOSS_ANIM
	jr z, .is_ball
	cp ULTRATOSS_ANIM
	jr nz, .not_ball
.is_ball
	ld a, 1
	and a
	ret
.not_ball
	xor a
	ret
;This function copies BGP colors 0-3 into OBP colors 0-3
;It is meant to reset the object palettes on the fly
SetAttackAnimPal_otheranim:
	push hl
	push bc
	push de
	
	ld c, 4
.loop
	ld a, 4
	sub c
	;multiply index by 8 since each index represents 8 bytes worth of data
	add a
	add a
	add a
	ld [rBGPI], a
	or $80 ; set auto-increment bit for writing
	ld [rOBPI], a
	ld hl, rBGPD
	ld de, rOBPD
	
	ld b, 4
.loop2
	ld a, [rLCDC]
	and rLCDC_ENABLE_MASK
	jr z, .lcd_dis
	;lcd in enabled otherwise
.wait1
	;wait for current blank period to end
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr z, .wait1
	;out of blank period now
.wait2
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr nz, .wait2
	;back in blank period now
.lcd_dis	
	;LCD is disabled, so safe to read/write colors directly
	ld a, [hl]
	ld [de], a
	ld a, [rBGPI]
	inc a
	ld [rBGPI], a
	ld a, [hl]
	ld [de], a
	ld a, [rBGPI]
	inc a
	ld [rBGPI], a
	dec b
	jr nz, .loop2
	
	dec c
	jr nz, .loop
	
	pop de
	pop bc
	pop hl
	ret
TypePalColorList:
	db PAL_YELLOWMON;normal
	db PAL_GREYMON;fighting
	db PAL_MEWMON;flying
	db PAL_PURPLEMON;poison
	db PAL_BROWNMON;ground
	db PAL_GREYMON;rock
	db PAL_BW;untyped/bird
	db PAL_GREENMON;bug
	db PAL_PURPLEMON;ghost
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_BW;unused
	db PAL_REDMON;fire
	db PAL_BLUEMON;water
	db PAL_GREENMON;grass
	db PAL_YELLOWMON;electric
	db PAL_PINKMON;psychic
	db PAL_CYANMON;ice
	db PAL_REDMON;dragon
ItemPalList:
	db PAL_BW	;null item
	db PAL_PURPLEMON	;master ball
	db PAL_UBALL	;ultra ball
	db PAL_BLUEMON	;great ball
	db PAL_REDMON	;pokeball
	db PAL_BW	;town map
	db PAL_BW	;bike
	db PAL_BW	;surfboard
	db PAL_GREENMON	;safari ball
