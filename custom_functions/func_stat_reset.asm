;This is a debug feature that will set a pokemon's stat exp all to zero 
;and set its DVs according to the quantity of the first five items slots in the bag

DebugStatReset:
;make it not work for inside the cable club
;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [wCurMap]
	cp TRADE_CENTER
	ret z
	cp COLOSSEUM
	ret z
;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [hJoyInput]
	cp D_LEFT + A_BUTTON + SELECT
	ret nz
	
	ld hl, _TXTStatReset
	call PrintText
	
	call NoYesChoice
	ld a, [wCurrentMenuItem]
	and a
	ret z
	
.init
	ld hl, wPartyMon1HPExp
	ld bc, (wPartyMon2 - wPartyMon1)
	ld a, [wWhichPokemon]
	call AddNTimes
	
	ld b, NUM_STAT_EXPS
	sla b
	xor a
.loop
	ld[hli], a
	dec b
	jr nz, .loop
	
	push de
	ld d, 2
	ld bc, wBagItems+1
.loop2
	ld a, [bc]
	and $0f
	swap a
	ld [hl], a
	inc bc 
	inc bc
	ld a, [bc]
	and $0f
	or [hl]
	ld [hli], a
	inc bc
	inc bc
	dec d
	jr nz, .loop2
	ld a, [bc] ; the fifth slot is the special defense DV
	and $0f
	swap a
	ld [hl], a
	pop de
	
	call WaitForSoundToFinish
	ld a, SFX_DENIED
	call PlaySound
	call WaitForSoundToFinish
	ret

_TXTStatReset:
	text "Reset STAT EXP to"
	line "0 and reset DVs"
	cont "to QTYs of 1st 4"
	cont "item slots on"
	cont "this #MON?"
	done
	db "@"
