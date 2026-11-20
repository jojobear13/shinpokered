BorderPalettes:
IF DEF(_REDJP)
	INCBIN "gfx/red/sgbborder_jp.tilemap"
ELIF DEF(_RED)
	INCBIN "gfx/posmonstro/sgbborder.tilemap"
ENDC
IF DEF(_BLUEJP)
	INCBIN "gfx/blue/sgbborder_jp.tilemap"
ELIF DEF(_BLUE)
	INCBIN "gfx/blue/sgbborder.tilemap"
ENDC
IF DEF(_GREEN)
	INCBIN "gfx/green/sgbborder.tilemap"
ENDC
	ds $100

IF DEF(_BLUE) || (DEF(_RED) && !DEF(_REDJP))
	RGB 30,29,29 ; PAL_SGB1 (the first color is not defined, but if used, turns up as 30,29,29... o_O) ;joenote - fixed
	RGB 10,17,26
	RGB 5,9,20
	RGB 16,20,27
ELIF DEF(_RED)
	RGB 30,29,29 ; PAL_SGB1
	RGB 25,22,25
	RGB 25,17,21
	RGB 24,14,12
ENDC
;credit Dracrius/pocketrgb-en/commit/b7750e2ded2b8acd0b507c7358057591d4c0351b for correct values
IF DEF(_GREEN)
	RGB 30,29,29 ; PAL_SGB1
	RGB 25,31,18
	RGB 18,25,12
	RGB 12,20,9
ENDC

	ds $18

IF DEF(_BLUE) || (DEF(_RED) && !DEF(_REDJP))
	RGB 30,29,29 ; PAL_SGB2
	RGB 27,11,6
	RGB 5,9,20
	RGB 28,25,15
ELIF DEF(_RED)
	RGB 30,29,29 ; PAL_SGB2
	RGB 22,31,16
	RGB 27,20,6
	RGB 15,15,15
ENDC
IF DEF(_GREEN)
	RGB 30,29,29 ; PAL_SGB2
	RGB 15,18,27
	RGB 24,19,7
	RGB 15,15,15
ENDC

	ds $18

IF DEF(_BLUE) || (DEF(_RED) && !DEF(_REDJP))
	RGB 30,29,29 ; PAL_SGB3
	RGB 12,15,11
	RGB 5,9,20
	RGB 14,22,17
ELIF DEF(_RED)
	RGB 30,29,29 ; PAL_SGB3
	RGB 31,31,17
	RGB 18,21,29
	RGB 15,15,15
ENDC
;credit Dracrius/pocketrgb-en/commit/b7750e2ded2b8acd0b507c7358057591d4c0351b for correct values
IF DEF(_GREEN)
	RGB 30,29,29 ; PAL_SGB3
	RGB 30,27,4
	RGB 29,18,20
	RGB 13,15,16
ENDC

	ds $18

SGBBorderGraphics:
IF DEF(_REDJP)
	INCBIN "gfx/red/sgbborder.2bpp"
ELIF DEF(_RED)
	INCBIN "gfx/posmonstro/sgbborder.2bpp"
ENDC
IF DEF(_BLUE)
	INCBIN "gfx/blue/sgbborder.2bpp"
ENDC
IF DEF(_GREEN)
	INCBIN "gfx/green/sgbborder.2bpp"
ENDC
