;This is a debug feature that will set a pokemon's EVs all to zero
;and set its IVs according to the quantity of the first six items slots in the bag

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
	ld hl, wPartyMon1EVs
	ld bc, (wPartyMon2 - wPartyMon1)
	ld a, [wWhichPokemon]
	call AddNTimes
	
	ld b, NUM_STATS
	xor a
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	
	push de
	push hl ; the IVs follow the EVs
	ld de, wIVScratch
	ld hl, wBagItems + 1
	ld b, NUM_STATS
.loop2 ; each IV is a bag slot's quantity (mod 32)
	ld a, [hli]
	inc hl
	and %11111
	ld [de], a
	inc de
	dec b
	jr nz, .loop2
	pop de
	callab PackIVsKeepFlags
	pop de
	
	call WaitForSoundToFinish
	ld a, SFX_DENIED
	call PlaySound
	call WaitForSoundToFinish
	ret

_TXTStatReset:
	text "Reset EVs to 0"
	line "and reset IVs"
	cont "to QTYs of 1st 6"
	cont "item slots on"
	cont "this #MON?"
	done
	db "@"
