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
