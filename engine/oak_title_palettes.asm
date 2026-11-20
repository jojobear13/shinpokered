SetOakTitlePalettes:
	ld a, [hGBC]
	and a
	ret z
	ld hl, OakTitleSkinPalette
	ld a, l
	ld [wGBCBasePalPointers + 4], a
	ld a, h
	ld [wGBCBasePalPointers + 5], a
	ld hl, OakTitleCoatPalette
	ld a, l
	ld [wGBCBasePalPointers + 6], a
	ld a, h
	ld [wGBCBasePalPointers + 7], a
	ret
OakTitleSkinPalette:
	RGB 31, 31, 31
	RGB 29, 23, 18
	RGB 12, 9, 7
	RGB 1, 1, 1
OakTitleCoatPalette:
	RGB 31, 31, 31
	RGB 21, 22, 23
	RGB 7, 8, 9
	RGB 1, 1, 1

SetOakTitleBallPalette:
	ld a, [hGBC]
	and a
	ret z
	ld de, OakTitleBallPalette
	ld a, CONVERT_OBP0
	call DMGPalToGBCPal
	ld a, 5
	jp TransferCurOBPData
OakTitleBallPalette:
	RGB 31, 31, 31
	RGB 31, 31, 31 ; original highlights
	RGB 29, 3, 3   ; original shaded shell
	RGB 3, 3, 3
