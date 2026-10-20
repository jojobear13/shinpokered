; function that displays the start menu
DrawStartMenu:
	call StartMenuItemCount
	ld [wMaxMenuItem], a ; number of menu items
	add a ; two rows each
	ld b, a
	ld c, $08
	coord hl, 10, 0
	call TextBoxBorder
	ld a, D_DOWN | D_UP | START | B_BUTTON | A_BUTTON
	ld [wMenuWatchedKeys], a
	ld a, $02
	ld [wTopMenuItemY], a ; Y position of first menu choice
	ld a, $0b
	ld [wTopMenuItemX], a ; X position of first menu choice
	ld a, [wBattleAndStartSavedMenuItem] ; remembered menu selection from last time
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	xor a
	ld [wMenuWatchMovingOutOfBounds], a
	ld hl, wd730
	set 6, [hl] ; no pauses between printing each letter
	coord hl, 12, 2
	CheckEvent EVENT_GOT_POKEDEX
	jr z, .noPokedex
	ld de, StartMenuPokedexText
	call PrintStartMenuItem
.noPokedex
	ld de, StartMenuPokemonText
	call PrintStartMenuItem
	ld de, StartMenuItemText
	call PrintStartMenuItem
	call StartMenuHasPC
	jr z, .noPC
	ld de, StartMenuPCText
	call PrintStartMenuItem
.noPC
	ld de, wPlayerName ; player's name
	call PrintStartMenuItem
	ld a, [wd72e]
	bit 6, a ; is the player using the link feature?
; case for not using link feature
	ld de, StartMenuSaveText
	jr z, .printSaveOrResetText
; case for using link feature
	ld de, StartMenuResetText
.printSaveOrResetText
	call PrintStartMenuItem
	ld de, StartMenuOptionText
	call PrintStartMenuItem
	ld de, StartMenuExitText
	call PlaceString
	ld hl, wd730
	res 6, [hl] ; turn pauses between printing letters back on
	ret

StartMenuPokedexText:
	db "POKéDEX@"

StartMenuPokemonText:
	db "POKéMON@"

StartMenuItemText:
	db "ITEM@"

StartMenuSaveText:
	db "SAVE@"

StartMenuResetText:
	db "RESET@"

StartMenuExitText:
	db "EXIT@"

StartMenuOptionText:
	db "OPTION@"

StartMenuPCText:
	db "PC@"

; nz if the start menu has the PC: the EXTRAS option PC IN MENU, except in
; the link rooms
StartMenuHasPC:
	ld a, [wd72e]
	bit 6, a ; is the player using the link feature?
	jr nz, .no
	CheckEvent EVENT_PC_IN_MENU
	ret
.no
	xor a
	ret

; a = the number of start menu items: six, the POKéDEX and the PC
StartMenuItemCount:
	ld c, 6
	CheckEvent EVENT_GOT_POKEDEX
	jr z, .noPokedex
	inc c
.noPokedex
	call StartMenuHasPC
	jr z, .noPC
	inc c
.noPC
	ld a, c
	ret

; e = the chosen item: 0 POKéDEX, 1 POKéMON, 2 ITEM, 3 the player, 4 SAVE,
; 5 OPTION, 6 EXIT, or 7 when it was the PC, which runs here
StartMenuChoice:
	ld a, [wCurrentMenuItem]
	ld e, a
	CheckEvent EVENT_GOT_POKEDEX
	jr nz, .gotPokedex
	inc e
.gotPokedex
	ld a, e
	cp 3 ; past ITEM?
	ret c
	call StartMenuHasPC
	ret z
	ld a, e
	cp 3
	jr z, .pc
	dec e
	ret
.pc
	callba ActivatePC
	call LoadScreenTilesFromBuffer2
	call LoadTextBoxTilePatterns
	call UpdateSprites
	ld e, 7
	ret

PrintStartMenuItem:
	push hl
	call PlaceString
	pop hl
	ld de, SCREEN_WIDTH * 2
	add hl, de
	ret
