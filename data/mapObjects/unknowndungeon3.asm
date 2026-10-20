UnknownDungeon3Object:;joenote - mewtwo bumped to lvl 74
	db $7d ; border block

	db 1 ; warps
	warp 3, 6, 8, UNKNOWN_DUNGEON_1

	db 0 ; signs

	db 3 ; objects
IF DEF(_REDGREENJP)
	object SPRITE_SLOWBRO, 5, 10, STAY, DOWN, 1, MEWTWO, 70
	object SPRITE_BALL, 24,  7, STAY, NONE, 2, ULTRA_BALL
	object SPRITE_BALL, 24,  1, STAY, NONE, 3, MYSTERYBERRY
ELSE
	object SPRITE_SLOWBRO, 27, 13, STAY, DOWN, 1, MEWTWO, 70
	object SPRITE_BALL, 16, 9, STAY, NONE, 2, ULTRA_BALL
	object SPRITE_BALL, 18, 1, STAY, NONE, 3, MAX_REVIVE
ENDC

	; warp-to
	warp_to 3, 6, UNKNOWN_DUNGEON_3_WIDTH ; UNKNOWN_DUNGEON_1
