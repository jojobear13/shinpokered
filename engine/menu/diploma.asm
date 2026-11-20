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
	lb de, 120, 130 ; OAM coordinates for screen position (122, 104)
	ld b, 3
	xor a
.row
	push de
	ld c, 3
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
	db $00, $00, $00, $06, $04, $0b, $06, $09, $00, $1f, $00, $1f, $04, $1b, $06, $19
	db $00, $00, $00, $00, $00, $e0, $02, $fe, $00, $fe, $00, $ff, $00, $ff, $e0, $1f
	db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $80, $00, $c0, $00, $e0
	db $03, $1c, $0f, $30, $07, $38, $08, $37, $07, $38, $03, $3c, $10, $7f, $00, $7f
	db $20, $df, $e3, $1f, $c1, $3f, $00, $ff, $21, $de, $03, $fc, $02, $ff, $00, $ff
	db $00, $fe, $f8, $ff, $fc, $ff, $fc, $ff, $88, $7e, $f8, $06, $3c, $c6, $28, $fe
	db $00, $7f, $02, $7f, $40, $7f, $38, $3f, $00, $00, $00, $00, $00, $00, $00, $00
	db $e3, $fc, $c0, $ff, $07, $ff, $01, $ff, $38, $3f, $00, $00, $00, $00, $00, $00
	db $00, $fe, $00, $fe, $f8, $fc, $78, $fc, $00, $fc, $f4, $fc, $00, $00, $00, $00
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
	dwCoord 9, 16

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
	db   "Congratulations"
	next "This diploma"
	next "certifies that you"
	next "have completed"
	next "your #dex.@"

DiplomaGameFreak:
	db "Game Freak@"
