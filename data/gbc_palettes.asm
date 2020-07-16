; palettes for overworlds, title screen, monsters
;gbcnote - add pokemon yellow GBC palettes
GBCBasePalettes:
	; PAL_ROUTE
	RGB 31, 31, 31
	RGB 16, 31,  4
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_PALLET
	RGB 31, 31, 31
	RGB 23, 17, 31
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_VIRIDIAN
	RGB 31, 31, 31
	RGB 19, 31,  0
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_PEWTER
	RGB 31, 31, 31
	RGB 18, 18, 15
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_CERULEAN
	RGB 31, 31, 31
	RGB  5,  8, 31
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_LAVENDER
	RGB 31, 31, 31
	RGB 25,  4, 31
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_VERMILION
	RGB 31, 31, 31
	RGB 31, 19,  0
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_CELADON
	RGB 31, 31, 31
	RGB  5, 31,  5
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_FUCHSIA
	RGB 31, 31, 31
	RGB 31, 15, 15
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_CINNABAR
	RGB 31, 31, 31
	RGB 31,  8,  8
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_INDIGO
	RGB 31, 31, 31
	RGB 11,  8, 31
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_SAFFRON
	RGB 31, 31, 31
	RGB 31, 31,  0
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_TOWNMAP
	RGB 31, 31, 31
	RGB  0, 21, 31
	RGB 10, 28,  0
	RGB  1,  1,  1

	; PAL_LOGO1
	RGB 31, 31, 31	;white bg
	RGB 31, 31,  0	;unused yellow logo text
IF DEF(_RED)
	RGB 17, 23, 10	;unused on title screen
	RGB 15,  3,  3	;version subtitle text color
ENDC
IF DEF(_BLUE)
	RGB 21,  0,  4	;unused on title screen
	RGB  3,  3, 15	;version subtitle text color
ENDC

	; PAL_LOGO2
	RGB 31, 31, 31	;white bg
	RGB 31, 31,  0	;yellow logo text
	RGB  7,  7, 25	;blue logo text shadow
	RGB  0,  0, 17	;blue logo text outline

	; PAL_0F
	RGB 31, 31, 31
	RGB 13,  1, 31
	RGB  0,  9, 31
	RGB  1,  1,  1

	; PAL_MEWMON	;reworked to match red/blue tones 
	RGB 31, 31, 31
	RGB 30, 17,  11
	RGB 11,  5,  14
	RGB  3,  3,  3

	; PAL_BLUEMON
	RGB 31, 31, 31
	RGB 16, 18, 31
	RGB  0,  1, 25
	RGB  3,  3,  3

	; PAL_REDMON
	RGB 31, 31, 31
	RGB 31, 17,  0
	RGB 31,  0,  0
	RGB  3,  3,  3

	; PAL_CYANMON
	RGB 31, 31, 31
	RGB 16, 26, 31
	RGB  0, 17, 31
	RGB  3,  3,  3

	; PAL_PURPLEMON
	RGB 31, 31, 31
	RGB 25, 15, 31
	RGB 19,  0, 22
	RGB  3,  3,  3

	; PAL_BROWNMON
	RGB 31, 31, 31
	RGB 29, 18, 10
	RGB 17,  9,  5
	RGB  3,  3,  3

	; PAL_GREENMON
	RGB 31, 31, 31
	RGB 17, 31, 11
	RGB  1, 22,  6
	RGB  3,  3,  3

	; PAL_PINKMON
	RGB 31, 31, 31
	RGB 31, 15, 18
	RGB 31,  0,  6
	RGB  3,  3,  3

	; PAL_YELLOWMON
	RGB 31, 31, 31
	RGB 31, 31,  0
	RGB 28, 14,  0
	RGB  3,  3,  3

	; PAL_GREYMON
	RGB 31, 31, 31
	RGB 20, 23, 10
	RGB 11, 11,  5
	RGB  3,  3,  3

;gbcnote - retouched all the slot palettes to match the red/blue coloring
	; PAL_SLOTS1
	RGB 31, 31, 31	;reel background
	RGB 21, 12, 15	;reel accents
	RGB 21, 14,  0	;"7" fill color
	RGB  3,  3,  3	;reel outline

	; PAL_SLOTS2
	RGB 31, 31, 31	;"3" icon fill
	RGB 31, 31,  0	;"3" icon shape color
IF DEF(_RED)
	RGB 20,  8, 15	;"3" icon background color
ENDC
IF DEF(_BLUE)
	RGB 9,  5, 30	
ENDC
	RGB  3,  3,  3	;"3" icon outline

	; PAL_SLOTS3
	RGB 31, 31, 31	;"2" icon fill
	RGB  3, 31,  9	;"2" icon shape color
IF DEF(_RED)
	RGB 20,  8, 15	;"2" icon background color
ENDC
IF DEF(_BLUE)
	RGB 9,  5, 30	
ENDC
	RGB  3,  3,  3	;"2" icon outline

	; PAL_SLOTS4
	RGB 31, 31, 31	;"1" icon fill
IF DEF(_RED)
	RGB  9,  5, 30	;"1" icon shape color
	RGB 20,  8, 15	;"1" icon background color
ENDC
IF DEF(_BLUE)
	RGB 20,  8, 15
	RGB 9,  5, 30
ENDC
	RGB  3,  3,  3	;"1" icon outline

	; PAL_BLACK
	RGB 31, 31, 31
	RGB  3,  3,  3
	RGB  3,  3,  3
	RGB  3,  3,  3

	; PAL_GREENBAR
	RGB 31, 31, 31
	RGB 31, 31,  0
	RGB  0, 31,  0
	RGB  3,  3,  3

	; PAL_YELLOWBAR
	RGB 31, 31, 31
	RGB 31, 31,  0
	RGB 31, 18,  0
	RGB  3,  3,  3

	; PAL_REDBAR
	RGB 31, 31, 31
	RGB 31, 31,  0
	RGB 31,  0,  0
	RGB  3,  3,  3

	; PAL_BADGE	
	;re-toned to a nice teal for the cascade and earth badges
	RGB 31, 31, 31
	RGB  3, 11,  6
	RGB  3, 17, 11
	RGB  3,  3,  3

	; PAL_CAVE
	RGB 31, 31, 31
	RGB 23,  8,  0
	RGB 17, 14, 11
	RGB  3,  3,  3

	; PAL_GAMEFREAK
	RGB 31, 31, 31
	RGB 31, 19,  0
	RGB 19, 19,  0
	RGB  3,  3,  3

	; PAL_25
	RGB 31, 31, 31
	RGB 31, 31,  0
	RGB 11, 23, 31
	RGB  3,  3,  3

	; PAL_26
	RGB 31, 31, 31
	RGB 31, 18,  0
	RGB 19,  7,  1
	RGB  3,  3,  3

	; PAL_27
	RGB 31, 31, 31
	RGB  9,  9,  9
	RGB 31, 21,  0
	RGB  3,  3,  3
