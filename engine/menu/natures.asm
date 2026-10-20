; on the status screen: the mon's nature under its HP, and ▴ and ▼ next to the
; stats it raises and lowers
PrintStatusScreenNature:
	ld hl, wLoadedMonIVs
	call GetNatureFromIVs
	push af
	add a
	add a
	add a ; names are 8 bytes each
	ld e, a
	ld d, 0
	ld hl, NatureNames
	add hl, de
	ld d, h
	ld e, l
	coord hl, 9, 5
	call PlaceString
	pop af
	ld b, 0
.divideBy5
	cp 5
	jr c, .gotStats
	sub 5
	inc b
	jr .divideBy5
.gotStats ; b = the raised stat, a = the lowered one, both counted from attack
	cp b
	ret z ; neutral
	push af
	ld a, b
	call .valueRow
	ld [hl], "▴"
	pop af
	call .valueRow
	ld [hl], "▼"
	ret
; a = stat counted from attack -> hl = the column before its value
.valueRow
	coord hl, 5, 9
	ld bc, 2 * SCREEN_WIDTH
	jp AddNTimes

NatureNames: ; 8 bytes each, in the order of the nature constants
	db "HARDY@@@"
	db "LONELY@@"
	db "BRAVE@@@"
	db "ADAMANT@"
	db "NAUGHTY@"
	db "BOLD@@@@"
	db "DOCILE@@"
	db "RELAXED@"
	db "IMPISH@@"
	db "LAX@@@@@"
	db "TIMID@@@"
	db "HASTY@@@"
	db "SERIOUS@"
	db "JOLLY@@@"
	db "NAIVE@@@"
	db "MODEST@@"
	db "MILD@@@@"
	db "QUIET@@@"
	db "BASHFUL@"
	db "RASH@@@@"
	db "CALM@@@@"
	db "GENTLE@@"
	db "SASSY@@@"
	db "CAREFUL@"
	db "QUIRKY@@"
NatureNamesEnd:
	ASSERT NatureNamesEnd - NatureNames == NUM_NATURES * 8
