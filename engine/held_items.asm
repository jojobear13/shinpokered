; held items: a mon's held item is in the catch-rate byte of its data (Gen 2
; did the same); 0 for none

; The enemy mon's held item, for its battle struct (written at de): a
; trainer's mon's from its party data, a wild mon's from the wild item table
; (none yet). Preserves de
GetEnemyHeldItem:
	ld a, [wIsInBattle]
	cp 2
	jr nz, .wild
	push de
	ld hl, wEnemyMon1CatchRate
	ld a, [wWhichPokemon]
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	pop de
	ld a, [hl]
	ld [de], a
	ret
.wild
	xor a
	ld [de], a
	ret

; A mon being added to a party: none, unless it's the wild mon being caught,
; which keeps its own. Written at de; preserves de
NewMonHeldItem:
	xor a
	ld [de], a
	ret

; on page 2 of the status screen: the held item, under the mon's name
PrintStatusScreenHeldItem:
	ld a, [wLoadedMonCatchRate]
	and a
	ret z
	ld [wd11e], a
	call GetItemName
	coord hl, 8, 2
	jp PlaceString
