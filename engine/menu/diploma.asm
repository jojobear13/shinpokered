DisplayDiploma:
	call SaveScreenTilesToBuffer2
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	xor a
	ld [wUpdateSpritesEnabled], a
	ld hl, wd730
	set 6, [hl]

	call _DisplayDiploma	;adding for GB_PRINTER
	
	call WaitForTextScrollButtonPress
	ld hl, wd730
	res 6, [hl]
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	call Delay3
	jp GBPalNormal

;all this got moved into its own function for GB_PRINTER
_DisplayDiploma:
	call DisableLCD
	call DelayFrame	;joenote - the overworld sprite wobble fix makes the player sprites hidden unless a delay is added
	ld hl, CircleTile
;	ld de, vChars2 + $700
	ld de, vChars2 + $100	;;changing for GB_PRINTER diploma
	ld bc, $0010
	ld a, BANK(CircleTile)
	call FarCopyData2
	coord hl, 0, 0
	lb bc, 16, 18
	predef Diploma_TextBoxBorder
	
	;joenote - adding master text if the seafoam missingno battle is beaten
	ld hl, DiplomaTextPointersAndCoords_master
	ld c, $6
	CheckEvent EVENT_8C6
	jr nz, .asm_56715
	
	ld hl, DiplomaTextPointersAndCoords
	ld c, $5
.asm_56715
	push bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	push hl
	ld h, [hl]
	ld l, a
	call PlaceString
	pop hl
	inc hl
	pop bc
	dec c
	jr nz, .asm_56715
	coord hl, 10, 4
	ld de, wPlayerName
	call PlaceString

	call DrawDiplomaPokedex

	call EnableLCD
	
	;adding GB_PRINTER
	ld a, [wPrinterSettings]
	bit 7, a
	jr nz, .doneTextBoxTiles
	callba LoadTrainerInfoTextBoxTiles
.doneTextBoxTiles

	ld b, SET_PAL_GENERIC
	call RunPaletteCommand
	call Delay3
	call GBPalNormal
	ld a, $90
	ld [rOBP0], a
	call UpdateGBCPal_OBP0
	ret

DrawDiplomaPokedex:
	ld hl, DiplomaPokedexTiles
	ld de, vSprites
	ld bc, DiplomaPokedexTilesEnd - DiplomaPokedexTiles
	ld a, BANK(DiplomaPokedexTiles)
	call FarCopyData2
	call ClearSprites

	ld hl, wOAMBuffer
	lb de, 104, 120 ; OAM coordinates for screen position (112, 88)
	ld b, 5
	xor a
.row
	push de
	ld c, 5
.tile
	push af
	ld a, d
	ld [hli], a
	ld a, e
	ld [hli], a
	add 8
	ld e, a
	pop af
	ld [hli], a
	ld [hl], $80 ; Behind background text, using Red's GBC sprite palette
	inc hl
	inc a
	dec c
	jr nz, .tile
	pop de
	push af
	ld a, d
	add 8
	ld d, a
	pop af
	dec b
	jr nz, .row
	ret

DiplomaPokedexTiles:
	db $00, $00, $00, $00, $00, $00, $00, $01, $00, $03, $00, $03, $00, $03, $00, $03
	db $00, $00, $00, $00, $90, $f0, $00, $fc, $e0, $1f, $f0, $0f, $f0, $0f, $40, $bf
	db $00, $00, $00, $00, $00, $00, $00, $00, $38, $f8, $00, $ff, $00, $ff, $18, $ff
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $80, $80, $80
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $04, $07, $01, $07, $00, $07, $01, $06, $01, $06, $09, $0e, $01, $0e, $00, $0f
	db $03, $ff, $f8, $ff, $00, $ff, $fc, $03, $03, $fc, $60, $9f, $7f, $80, $7f, $80
	db $c8, $ff, $08, $ff, $08, $ff, $08, $ff, $e0, $1f, $21, $df, $b1, $5f, $b0, $5f
	db $10, $f0, $80, $f8, $80, $fc, $00, $fe, $00, $ff, $00, $ff, $00, $ff, $7f, $ff
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $40, $c0, $02, $fe, $81, $ff
	db $00, $0f, $02, $0d, $02, $0d, $13, $1c, $02, $1d, $00, $1f, $00, $1f, $06, $1f
	db $7f, $80, $ff, $00, $3f, $c0, $00, $ff, $7c, $83, $7c, $83, $7c, $83, $00, $ff
	db $b0, $5f, $90, $7f, $10, $ff, $40, $bf, $61, $bf, $61, $bf, $61, $bf, $20, $ff
	db $7f, $ff, $ff, $ff, $7f, $ff, $00, $ff, $f1, $0f, $ff, $00, $f4, $0b, $ff, $00
	db $f1, $ff, $f0, $fe, $f0, $fe, $f0, $fe, $00, $fe, $e2, $1e, $b2, $4e, $e2, $1e
	db $26, $3f, $00, $3f, $03, $3f, $00, $3f, $00, $3f, $47, $7f, $00, $3f, $20, $3f
	db $18, $ff, $11, $ff, $07, $ff, $07, $ff, $c3, $3f, $23, $ff, $00, $ff, $00, $ff
	db $00, $ff, $00, $ff, $05, $fe, $c1, $fe, $c0, $ff, $41, $ff, $4b, $ff, $0b, $ff
	db $31, $fe, $00, $ff, $e2, $1f, $f0, $0f, $00, $ff, $80, $ff, $f7, $ff, $ff, $ff
	db $e0, $1c, $60, $fc, $40, $fc, $00, $fc, $44, $bc, $04, $fc, $c4, $fc, $e0, $f8
	db $0f, $0f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $e0, $ff, $0f, $0f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $00, $ff, $f0, $ff, $7e, $7f, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
	db $67, $ff, $00, $ff, $00, $ff, $fe, $ff, $00, $00, $00, $00, $00, $00, $00, $00
	db $e0, $f8, $00, $f8, $08, $f8, $10, $f0, $e0, $e0, $00, $00, $00, $00, $00, $00
DiplomaPokedexTilesEnd:

UnusedPlayerNameLengthFunc:
; Unused function that does a calculation involving the length of the player's
; name.
	ld hl, wPlayerName
	ld bc, $ff00
.loop
	ld a, [hli]
	cp "@"
	ret z
	dec c
	jr .loop

DiplomaTextPointersAndCoords_master:	;joenote - adding master text
	dw MasterText
	dwCoord 1, 1	
DiplomaTextPointersAndCoords:
	dw DiplomaText
	dwCoord 5, 2
	dw DiplomaPlayer
	dwCoord 3, 4
	dw DiplomaEmptyText
	dwCoord 15, 4
	dw DiplomaCongrats
	dwCoord 1, 6
	dw DiplomaGameFreak
	dwCoord 1, 16

MasterText:	;joenote - adding master text
	db "<Shiny> #Mon Master <Shiny>@"

DiplomaText:
;	db $70,"Diploma",$70,"@"
	db $10,"Diploma",$10,"@"	;changing for GB_PRINTER diploma

DiplomaPlayer:
	db "Player@"

DiplomaEmptyText:
	db "@"

DiplomaCongrats:
	db   "Congratulations<LF>"
	db   "This diploma"
	next "certifies that"
	next "you have"
	next "completed"
	next "your #dex.@"

DiplomaGameFreak:
	db "Game Freak@"
