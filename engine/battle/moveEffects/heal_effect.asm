HealEffect_:
	callab RestPrevented ; Insomnia, Vital Spirit
	jp c, .failed
	ld a, [H_WHOSETURN]
	and a
	ld de, wBattleMonHP
	ld hl, wBattleMonMaxHP
	ld a, [wPlayerMoveNum]
	jr z, .healEffect
	ld de, wEnemyMonHP
	ld hl, wEnemyMonMaxHP
	ld a, [wEnemyMoveNum]
.healEffect	;joenote - fixed the fail on 255 or 511 hp issue
	;h holds high byte of maxHP, l holds low byte of maxHP
	;d holds high byte of curHP, e holds low byte of curHP
	ld b, a
	ld a, [de]	;load d into a
	cp [hl] 	;compare a with h
			; most significant bytes comparison is ignored
	        ; causes the move to miss if max HP is 255 or 511 points higher than the current HP
	;assume h >= d. it does not matter what d or h are, c_flag = 1 if h != d so assume h > d
	inc de	;incrementing 16-bit registers does not change the flag register
	inc hl	; however, it does get us working with e & l
	jr nz, .passed	; if c_flag is set, then h is > d and therefore hl is assumed > de. we can stop checking here
	ld a, [de]	;if h = d, then load e into a. again, assume l >= e
	sbc [hl]	;c_flag is still 0. compare a with l. 
	;A a zero flag means both h and d as well as l and e are equal pairs. hl = de, so already at full hp!
	jp z, .failed ; no effect if user's HP is already at its maximum
.passed
	ld a, b
	cp REST
	jr nz, .healHP
	push hl
	push de
	push af
	ld c, 50
	call DelayFrames
	ld hl, wBattleMonStatus
	ld a, [H_WHOSETURN]
	and a
	jr z, .restEffect
	ld hl, wEnemyMonStatus
.restEffect
;;;;;;;;joenote - undo the stat-changing effects of burn and paralyze and clear toxic info
	callab UndoBurnParStats

;remove toxic and clear toxic counter
.checkToxic	;remove toxic and clear toxic counter
	ld hl, wPlayerBattleStatus3	;load in for toxic bit
	ld de, wPlayerToxicCounter	;load in for toxic counter
	ld a, [H_WHOSETURN]
	and a
	jr z, .undoToxic
	ld hl, wEnemyBattleStatus3	;load in for toxic bit
	ld de, wEnemyToxicCounter	;load in for toxic counter
.undoToxic
	res BADLY_POISONED, [hl] ; heal Toxic status
	xor a	;clear a
	ld [de], a	;write a to toxic counter
;reload the initial status info so the correct condtions can be cleared
	ld hl, wBattleMonStatus
	ld a, [H_WHOSETURN]
	and a
	jr z, .noCondition
	ld hl, wEnemyMonStatus
.noCondition
;;;;;;;;
	ld a, [hl]
	and a
	ld [hl], 3 ; clear status and set number of turns asleep to 2 / joenote - changed to 3 since attacking on wakeup is now possible
	ld hl, StartedSleepingEffect ; if mon didn't have an status
	jr z, .printRestText
	ld hl, FellAsleepBecameHealthyText ; if mon had an status
.printRestText
	call PrintText
	pop af
	pop de
	pop hl
.healHP
	ld a, [hld]
	ld [wHPBarMaxHP], a
	ld c, a
	ld a, [hl]
	ld [wHPBarMaxHP+1], a
	ld b, a
	jr z, .gotHPAmountToHeal
; Recover and Softboiled only heal for half the mon's max HP
	srl b
	rr c
.gotHPAmountToHeal
; update HP
	ld a, [de]
	ld [wHPBarOldHP], a
	add c
	ld [de], a
	ld [wHPBarNewHP], a
	dec de
	ld a, [de]
	ld [wHPBarOldHP+1], a
	adc b
	ld [de], a
	ld [wHPBarNewHP+1], a
	inc hl
	inc de
	ld a, [de]
	dec de
	sub [hl]
	dec hl
	ld a, [de]
	sbc [hl]
	jr c, .playAnim
; copy max HP to current HP if an overflow occurred
	ld a, [hli]
	ld [de], a
	ld [wHPBarNewHP+1], a
	inc de
	ld a, [hl]
	ld [de], a
	ld [wHPBarNewHP], a
.playAnim
	ld hl, PlayCurrentMoveAnimation
	call BankswitchEtoF
	ld a, [H_WHOSETURN]
	and a
	coord hl, 10, 9
	ld a, $1
	jr z, .updateHPBar
	coord hl, 2, 2
	xor a
.updateHPBar
	ld [wHPBarType], a
	predef UpdateHPBar2
	ld hl, DrawHUDsAndHPBars
	call BankswitchEtoF
	ld hl, RegainedHealthText
	jp PrintText
.failed
	ld c, 50
	call DelayFrames
	ld hl, PrintButItFailedText_
	jp BankswitchEtoF

StartedSleepingEffect:
	TX_FAR _StartedSleepingEffect
	db "@"

FellAsleepBecameHealthyText:
	TX_FAR _FellAsleepBecameHealthyText
	db "@"

RegainedHealthText:
	TX_FAR _RegainedHealthText
	db "@"

BankswitchEtoF:
	ld b, BANK(BattleCore)
	jp Bankswitch
