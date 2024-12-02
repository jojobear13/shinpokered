; [wd0b5] = pokemon ID
; hl = dest addr
PrintMonType:
	;joenote - if wd0b5 holds zero, then assume printing from the status screen
	ld a, [wd0b5]
	and a
	jp z, PrintMonType_StatusScreen

	call GetPredefRegisters
	push hl
	call GetMonHeader
	pop hl
	push hl
	ld a, [wMonHType1]
	call PrintType
	ld a, [wMonHType1]
	ld b, a
	ld a, [wMonHType2]
	cp b
	pop hl
	jr z, EraseType2Text
	ld bc, SCREEN_WIDTH * 2
	add hl, bc

; a = type
; hl = dest addr
PrintType:
	push hl
	jr PrintType_

; erase "TYPE2/" if the mon only has 1 type
EraseType2Text:
	ld a, " "
	ld bc, $13
	add hl, bc
	ld bc, $6
	jp FillMemory

PrintMoveType:
	call GetPredefRegisters
	push hl
	ld a, [wPlayerMoveType]
; fall through

PrintType_:
	add a
	ld hl, TypeNames
	ld e, a
	ld d, $0
	add hl, de
	ld a, [hli]
	ld e, a
	ld d, [hl]
	pop hl
	jp PlaceString

;joenote - if printing on the status screen, pull the types right from the party data structures
;This allows for pokemon to have "forms" where the species is the same but the type is different.
PrintMonType_StatusScreen:
	call GetPredefRegisters
	push de
	push hl
	
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Type1
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	
	ld d, h
	ld e, l
	pop hl


	ld a, [de]
	push de
	call PrintType
	pop de
	ld a, [de]
	ld b, a
	inc de
	ld a, [de]
	cp b

	pop de
	jr z, EraseType2Text
	ld bc, SCREEN_WIDTH * 2
	add hl, bc
	jp PrintType
	
INCLUDE "text/type_names.asm"
