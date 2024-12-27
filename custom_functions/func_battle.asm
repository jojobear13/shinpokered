;joenote - custom functions to handle move priority. Sets zero flag if priority lowered/raised.
CheckLowerPlayerPriority:	
	ld a, [wPlayerSelectedMove]
	ld hl, wPlayerBattleStatus3
	jr LowPriorityMoves
CheckLowerEnemyPriority:
	ld a, [wEnemySelectedMove]
	ld hl, wEnemyBattleStatus3
;	jp LowPriorityMoves
;fall through
LowPriorityMoves:
;joenote - handle trapping spam counter and implement the trapping clause
	call CheckIfTrappingMove
	jr nz, .next1	;reset the number of consecutive trapping moves and continue if this is not a trapping move

	bit TRAPPING_NEGATIVE, [hl]
	jr nz, .CheckTrappingClause	;if the bit indicating two consecutive uses is set, ret immediately with z flag for negative priority
	jr .next2
	
.next1
	res TRAPPING_COUNT, [hl]
	res TRAPPING_NEGATIVE, [hl]
.next2
	cp COUNTER
	ret
.CheckTrappingClause
	res TRAPPING_COUNT, [hl]

;link battles now sync clause flag
;	ld a, [wLinkState]
;	cp LINK_STATE_BATTLING
;	jr z, .next3

	CheckEvent EVENT_8C5
.next3
	;invert the z flag bit at this point
	jr nz, .retz
.retnz
	ld a, 1
	and a
	ret
.retz
	xor a
	ret

CheckHigherPlayerPriority:	
	ld a, [wPlayerSelectedMove]
	jr HighPriorityMoves
CheckHigherEnemyPriority:
	ld a, [wEnemySelectedMove]
;	jr HighPriorityMoves
; fall through
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
	
CheckIfTrappingMove:
	cp BIND
	ret z
	cp WRAP
	ret z
	cp FIRE_SPIN
	ret z
	cp CLAMP
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

	
;custom function to determin the DVs of wild pokemon with an option for forcing shiny DVs
DetermineWildMonDVs:
	ld a, [wFontLoaded]
	bit 7, a
	jr z, .do_random
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;exclude tower ghosts and old man tutorial
	ld a, [wBattleType]
	dec a
	jr z, .do_random
	ld a, [wFlags_D733]
	bit 6, a
	jr nz, .do_random 
	CheckEvent EVENT_10E
	jr nz, .do_random	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld b, $AA
	call Random	;get random number into a
	or $20	;set only bit 5
	and $F0 ; clear the lower nybble
	or $0A	;set the lower nyble to $A
	jr .load
.do_random
	CheckEvent EVENT_90F	;special safari zone active?
	jr z, .notsafari	
	call IsInSafariZone
	jr nz, .do_random_safari
.notsafari
	call Random_DV
	jr .load
.do_random_safari	;special safari zone pokemon have better DVs
	call Random_BiasDV
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


ForfeitTrainerMatch:
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	ret z	;return if in a link battle
	ld a, [wIsInBattle]
	cp 0	
	ret z	;return if not in battle
	cp 1	
	ret z	;return if in wild battle
	ld a, [hJoyHeld]
	and SELECT
	ret z	;return if select is not being held
	ld hl, ForfeitTrainerMatchText
	call PrintText 
	call NoYesChoice
	ld a, [wCurrentMenuItem]
	and a
	push af
	call nz, ForfeitConfirmed
	pop af
	ret
ForfeitTrainerMatchText:
	TX_FAR _ForfeitTrainerMatchText
	db "@"
_ForfeitTrainerMatchText::
	text "Forfeit?"
	done

ForfeitConfirmed:
	;set the flag for forfeiting
	ld a, [wUnusedD721]
	set 1, a
	ld [wUnusedD721], a
	call ForfeitConfirmed_NuzlockeHandler	;joenote - mark already KO'ed pokemon as dead for nuzlocke mode
	;fall through
FaintAllMons:
	;now KO the whole party
	ld a, $00
	ld [wBattleMonHP], a
	ld [wBattleMonHP + 1], a
	ld [wPartyMon1HP], a
	ld [wPartyMon1HP + 1], a
	ld [wPartyMon2HP], a
	ld [wPartyMon2HP + 1], a
	ld [wPartyMon3HP], a
	ld [wPartyMon3HP + 1], a
	ld [wPartyMon4HP], a
	ld [wPartyMon4HP + 1], a
	ld [wPartyMon5HP], a
	ld [wPartyMon5HP + 1], a
	ld [wPartyMon6HP], a
	ld [wPartyMon6HP + 1], a
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


;check hyper beam clause
;when active, hyperbeam does not need to recharge when scoring a KO
;set z flag if not applicable 
;clear z flag if confirmed
_HandleHyperbeamClause:

;link battles now sync clause flag
;	ld a, [wLinkState]
;	cp LINK_STATE_BATTLING
;	ret z	;do not enforce for link battles

	CheckEvent EVENT_8C8	
	ret z
	ld hl, wEnemyMonHP	;check enemy hp if it's the player's turn
	ld a, [H_WHOSETURN]
	and a
	jr z, .next
	ld hl, wBattleMonHP	;check player hp if its the enemy's turn
.next
	ld a, [hli]
	or [hl]
	jr nz, .noKO
	inc a
	ret
.noKO
	xor a
	ret

;return z and nc if nothing detected
;return nz for sleep clause triggered
;return c for  freeze clause triggered
;link battles kinda supported
_HandleSlpFrzClause:		
;link battles now sync clause flag
;	ld a, [wLinkState]
;	cp LINK_STATE_BATTLING
;	jp z, .returnclear ;do not enforce for link battles
	
	ld a, [wIsInBattle]
	cp 2
	jp nz, .returnclear ;continue for trainer battles only

	CheckEitherEventSet EVENT_8DC, EVENT_8DD
	jp z, .returnclear	;return if neither sleep nor freeze clause bits are set
	
	ld a, [H_WHOSETURN]
	and a
	jr nz, .playerdata
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.enemydata
	;now set up to start looping through the party
	ld a, [wEnemyPartyCount]	;1 to 6
	ld d, a
	ld bc, wEnemyMon2 - wEnemyMon1
	ld hl, wEnemyMon1Status
	jr .initialize
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.playerdata
	;now set up to start looping through the party
	ld a, [wPartyCount]	;1 to 6
	ld d, a
	ld bc, wPartyMon2 - wPartyMon1
	ld hl, wPartyMon1Status
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.initialize
	xor a	;start with A having a value of 0
.loop
	call .CheckPartyZeroHP
	jr c, .skipOR	;do not do the OR if pointed-to 'mon has zero HP
	or [hl]
.skipOR
	dec d
	jr z, .doneloop
	add hl, bc
	jr .loop
.doneloop
	;Rotate A so that the bits look like 4,3,2,1,0,7,6,5
	rlca
	rlca
	rlca	
	;frz bit is now the carry bit and z flag is cleared by the rlca opcode
	;Sleep counter is 2,1,0
	;use res opcodes to effectively do "and %00111000" so as to not affect the carry flag
	res 7, a
	res 6, a
	res 2, a
	res 1, a
	res 0, a
	;assign z or nz based on value of the sleep counter using inc and dec to not affect carry flag
	inc a
	dec a	
	
	push af	;save flags and the OR'ed status bits
	CheckBothEventsSet EVENT_8DC, EVENT_8DD
	jr z, .returnboth
	
	CheckEvent EVENT_8DC
	jr nz, .returnSLPonly	
	;otherwise the FRZ clause must be the only one active

.returnFRZonly
	pop af
	;need to set the z state while leaving carry alone 
	ld b, 1
	dec b
	ret
.returnSLPonly
	pop af
	;need to clear carry while maintaining proper z state
	ld b, a
	res 7, b	;make bit 7 into a 0
	rlc b	;then roll that 0 into the carry flag. sleep counter bits will determine the z/nz flag state.
	ret
.returnboth
	pop af
	ret
.returnclear
	xor a
	ret
;Used by _HandleSlpFrzClause to check if a party mon has zero HP
;set the carry bit if true
.CheckPartyZeroHP
	scf		;set the carry flag
	push af
	push hl
	;assume hl points to wEnemy/PartyMonXStatus
	dec hl	;point to level
	dec hl	;point to lo byte of hp
	ld a, [hld]	;lo HP byte into A then point to hi HP byte
	or [hl]; OR the lo and hi HP bytes together
	pop hl
	jr z, .ZeroHP
.SomeHP
	pop af
	ccf		;complement the carry flag (change from 1 to 0)
	ret
.ZeroHP
	pop af
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

;Note: calls GetBadgeCap and preserves D so that this too returns the level cap based on badges back into D
DoDisobeyLevelCheck:
	xor a
	ld [wMonIsDisobedient], a
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jr z, .return_usemove	;never apply obedience in link battles

;	CheckEvent EVENT_908	;joenote Check if Elite 4 beaten, and if so then don't even bother going further
;	jr nz, .return_usemove

	ld a, [wUnusedD721]	;joenote - check if obedience level cap is active and always treat as traded if so
	bit 5, a
	jr nz, .monIsTraded

	CheckEvent EVENT_90C
	jr nz, .return_usemove	;do not apply obedience if level scaling is active
	
; compare the mon's original trainer ID with the player's ID to see if it was traded
	ld hl, wPartyMon1OTID
	ld bc, wPartyMon2 - wPartyMon1
	ld a, [wPlayerMonNumber]
	call AddNTimes
	ld a, [wPlayerID]
	cp [hl]
	jr nz, .monIsTraded
	inc hl
	ld a, [wPlayerID + 1]
	cp [hl]
	jr z, .return_usemove
; it was traded

.monIsTraded
; what level might disobey?
	call GetBadgeCap

	ld a, [wBattleMonLevel]
	ld e, a
		
.return_back
	ld a, 1
	and a
	ret
	
.return_usemove
	xor a
	ret

;a 0 value means badge has no effect on obedience
; the value for no badges must be non-zero
ObedienceLevelsTraded:
	db 10	;no badges
	db 0	;boulder badge
	db 30	;cascade badge
	db 0	;thunder badge
	db 50	;rainbow badge
	db 0	;soul badge
	db 70	;marsh badge
	db 0	;volcano badge
	db 255	;earth badge
ObedienceLevelCappedOption:
	db 15	;no badges
	db 25	;boulder badge
	db 30	;cascade badge
	db 35	;thunder badge
	db 45	;rainbow badge
	db 50	;soul badge
	db 50	;marsh badge
	db 55	;volcano badge
	db 70	;earth badge

;returns the level cap based on badges back into D
GetBadgeCap:
	ld hl, ObedienceLevelsTraded
	ld a, [wUnusedD721]	;joenote - check if obedience level cap is active
	bit 5, a
	jr z, .next
	ld hl, ObedienceLevelCappedOption	
.next

	ld e, 8	;number of badges that exist
	ld a, [wObtainedBadges]
	ld d, a
	
	push bc
	ld a, [hl]
	ld b, a

.loop_level
	inc hl
	rrc d
	jr nc, .donthavebadge
	ld a, [hl]
	and a
	jr z, .donthavebadge
	ld b, a
.donthavebadge
	dec e
	jr nz, .loop_level
	
	ld d, b
	pop bc
	ret
	
	
PsywaveEnhanced:
	;E = user's level
	;D = [0, user's level]
	push de
	ld e, d
	
	ld hl, $0000
	ld d, 0
	add hl, de
	srl e
	add hl, de
	ld a, h
	or l
	jr nz, .next
	inc l
.next
	ld d, h
	ld e, l
	;DE = [1, 1.5*user's level]
	
	ld hl, wDamage
	ld a, [hl]
	cp d
	jr c, .update
	inc hl
	ld a, [hld]
	cp e
	jr nc, .cycle
.update
	ld a, d
	ld [hli], a
	ld a, e
	ld [hl], a
	
.cycle
	ld hl, wcf4b
	ld a, [hli]
	ld d, a
	ld a, [hld]
	ld e, a
	srl d
	rr e
	srl d
	rr e
	ld a, d
	ld [hli], a
	ld a, e
	ld [hld], a
	or d
	jr nz, .return_reroll
	
.return_good
	xor a
	jr .return
.return_reroll
	scf
.return
	pop de
	ret



