SchoolObject:
	db $a ; border block

	db 2 ; warps
	warp 2, 7, 2, -1
	warp 3, 7, 2, -1

	db 0 ; signs

	db 3 ; objects
	object SPRITE_BRUNETTE_GIRL, 3, 5, STAY, UP, 1 ; person
	object SPRITE_LASS, 4, 1, STAY, DOWN, 2 ; person
	object SPRITE_YOUNG_BOY, 5, 4, STAY, LEFT, 3	;joenote - added extra student for more text

	; warp-to
	warp_to 2, 7, VIRIDIAN_SCHOOL_WIDTH
	warp_to 3, 7, VIRIDIAN_SCHOOL_WIDTH
