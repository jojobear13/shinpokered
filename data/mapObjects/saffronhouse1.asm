SaffronHouse1Object:
	db $a ; border block

	db 2 ; warps
	warp 2, 7, 3, -1
	warp 3, 7, 3, -1

	db 0 ; signs

	db 4 ; objects
	; wispnote - exchange object 1 and 4 to much their corresponding text
	object SPRITE_PAPER_SHEET, 3, 3, STAY, NONE, 1 ; person
	object SPRITE_BIRD, 0, 4, WALK, 1, 2 ; person
	object SPRITE_BUG_CATCHER, 4, 1, STAY, DOWN, 3 ; person
	object SPRITE_BRUNETTE_GIRL, 2, 3, STAY, RIGHT, 4 ; person 

	; warp-to
	warp_to 2, 7, SAFFRON_HOUSE_1_WIDTH
	warp_to 3, 7, SAFFRON_HOUSE_1_WIDTH
