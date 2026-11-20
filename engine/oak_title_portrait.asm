DrawOakTitleCharacter:
	ld hl, OakTitleGraphics
	ld de, vSprites
	ld bc, OakTitleGraphicsEnd - OakTitleGraphics
	ld a, BANK(OakTitleGraphics)
	call DrawPlayerCharacter.copy
; Neutral coat, gray hair, dark tie and trousers; warm face and hand.
	ld hl, wOAMBuffer
	ld de, 1
	ld b, 35
.coatPalette
	ld a, [hl]
	add TITLE_PORTRAIT_Y_OFFSET
	ld [hli], a
	inc hl
	inc hl
	ld a, [hl]
	and $f8
	or 3
	ld [hl], a
	add hl, de
	dec b
	jr nz, .coatPalette
	ld a, 5 ; dedicated red/white ball palette
	ld [wOAMBuffer + 10 * 4 + 3], a
; Five skin overlays consume the five remaining hardware sprite slots.
; Base skin pixels are transparent; no coat pixels use the skin palette.
	ld hl, .skinOAM
	ld de, wOAMBuffer + 35 * 4
	ld bc, 5 * 4
	call CopyData
	ret
.skinOAM
	db $68 + TITLE_PORTRAIT_Y_OFFSET,$6a,35,2 ; face left (source tile 7)
	db $68 + TITLE_PORTRAIT_Y_OFFSET,$72,36,2 ; face right (source tile 8)
	db $70 + TITLE_PORTRAIT_Y_OFFSET,$6a,37,2 ; chin/neck left (source tile 12)
	db $70 + TITLE_PORTRAIT_Y_OFFSET,$72,38,2 ; chin/neck right (source tile 13)
	db $78 + TITLE_PORTRAIT_Y_OFFSET,$62,39,2 ; open palm (source tile 16)

; Sprite tiles are column-major. Shift each column in the decoded buffer,
; keeping the last two rows in a spare tile below the usual 7-by-7 picture.
TITLE_MON_OVERFLOW_TILE EQU $69
ASSERT TITLE_MON_OVERFLOW_TILE >= TITLE_SLOGAN_FIRST_TILE + TITLE_SLOGAN_TILE_COUNT
DEF TITLE_MON_COLUMN_BYTES EQU 7 * 16
DEF TITLE_MON_SHIFT_BYTES EQU TITLE_PORTRAIT_Y_OFFSET * 2
ShiftTitleMonDown:
	ld hl, sSpriteBuffer1
	ld de, sSpriteBuffer0
	ld b, 7
.column
	push bc
	push hl
	ld bc, TITLE_MON_COLUMN_BYTES - TITLE_MON_SHIFT_BYTES
	add hl, bc
	ld bc, TITLE_MON_SHIFT_BYTES
	call CopyData
	push hl
	ld h, d
	ld l, e
	xor a
	ld b, 16 - TITLE_MON_SHIFT_BYTES
.padOverflowTile
	ld [hli], a
	dec b
	jr nz, .padOverflowTile
	ld d, h
	ld e, l
	pop hl
	push de
	ld d, h
	ld e, l
	dec de
	ld bc, -TITLE_MON_SHIFT_BYTES - 1
	add hl, bc
	ld b, TITLE_MON_COLUMN_BYTES - TITLE_MON_SHIFT_BYTES
.shiftBytes
	ld a, [hld]
	ld [de], a
	dec de
	dec b
	jr nz, .shiftBytes
	xor a
	ld b, TITLE_MON_SHIFT_BYTES
.blankTop
	ld [de], a
	dec de
	dec b
	jr nz, .blankTop
	pop de
	pop hl
	ld bc, TITLE_MON_COLUMN_BYTES
	add hl, bc
	pop bc
	dec b
	jr nz, .column

	ld hl, vFrontPic
	ld de, sSpriteBuffer1
	ld c, 7 * 7
	ld a, [H_LOADEDROMBANK]
	ld b, a
	call CopyVideoData
	ld hl, vChars2 + TITLE_MON_OVERFLOW_TILE * 16
	ld de, sSpriteBuffer0
	ld c, 7
	ld a, [H_LOADEDROMBANK]
	ld b, a
	call CopyVideoData
	coord hl, 5, 17
	ld a, TITLE_MON_OVERFLOW_TILE
	ld b, 7
.placeBottomRow
	ld [hli], a
	inc a
	dec b
	jr nz, .placeBottomRow
	ret
