HealParty:
; Restore HP and PP.

	ld hl, wPartySpecies
	ld de, wPartyMon1HP
.healmon
	ld a, [hli]
	cp $ff
	jr z, .done
	cp EGG
	jr z, .nextMon ; an egg keeps its 0 HP

	push hl
	push de

	ld hl, wPartyMon1Status - wPartyMon1HP
	add hl, de
	xor a
	ld [hl], a

	push de
	ld b, NUM_MOVES ; A Pokémon has 4 moves
.pp
	ld hl, wPartyMon1Moves - wPartyMon1HP
	add hl, de

	ld a, [hl]
	and a
	jr z, .nextmove

	dec a
	ld hl, wPartyMon1PP - wPartyMon1HP
	add hl, de

	push hl
	push de
	push bc

	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	
	;joenotes...
	;HL now points to the address of the move in the master moves characteristics list
	;Check that the HL-pointed address itself does not fall outside of the starting or ending address of the list
	;If it does, HL is pointing to a glitch move. Default the base pp to 0 instead of trying to read it.
	ld de, Moves
	ld a, l
	sub e
	ld a, h
	sbc d
	ld a, 0
	jr c, .basePP_loaded	;if HL is < Moves, this is a glitch move and load 0 pp
	ld de, MovesEndOfList
	ld a, l
	sub e
	ld a, h
	sbc d
	ld a, 0
	jr nc, .basePP_loaded	;if HL is >= MovesEndOfList, this is a glitch move and load 0 pp
	
	ld de, wcd6d
	ld a, BANK(Moves)
	call FarCopyData
	ld a, [wcd6d + 5] ; PP is byte 5 of move data
.basePP_loaded
	pop bc
	pop de
	pop hl

	inc de
	push bc
	ld b, a	;the master PP characteristic is  loaded into B
	ld a, [hl]	;HL points to the PP of the current party mon move, so get its PP info into A
	and $c0	;mask out everything but the PP-up bits
	add b	;add to it the master PP value
	ld [hl], a	;store it back into the party mon struct
	pop bc

.nextmove
	dec b
	jr nz, .pp
	pop de

	ld hl, wPartyMon1MaxHP - wPartyMon1HP
	add hl, de
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a

	pop de
	pop hl

.nextMon
	push hl
	ld bc, wPartyMon2 - wPartyMon1
	ld h, d
	ld l, e
	add hl, bc
	ld d, h
	ld e, l
	pop hl
	jr .healmon

.done
	xor a
	ld [wWhichPokemon], a
	ld [wd11e], a

	ld a, [wPartyCount]
	ld b, a
.ppup
	push bc
	call RestoreBonusPP
	pop bc
	ld hl, wWhichPokemon
	inc [hl]
	dec b
	jr nz, .ppup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;joenote - handle dead pokemon for the nuzlocke mode
	predef HealParty_NuzlockeHandler
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ret
