DisplayStartMenu::
	ld a, BANK(StartMenu_Pokedex)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ld a, [wWalkBikeSurfState] ; walking/biking/surfing
	ld [wWalkBikeSurfStateCopy], a
	ld a, SFX_START_MENU
	call PlaySound

RedisplayStartMenu::
	callba DrawStartMenu
	callba PrintSafariZoneSteps ; print Safari Zone info, if in Safari Zone

	;GBCNote - if using enhanced GBC color, add some extra delay
	ld a, [wUnusedD721]
	bit 7, a
	call nz, Delay3

	call LoadGBPal	;joenote - moved this here for smoother whiteout transition
	call UpdateSprites
.loop
	call HandleMenuInput
	ld b, a
.checkIfUpPressed
	bit 6, a ; was Up pressed?
	jr z, .checkIfDownPressed
	ld a, [wCurrentMenuItem] ; menu selection
	and a
	jr nz, .loop
	ld a, [wLastMenuItem]
	and a
	jr nz, .loop
; if the player pressed tried to go past the top item, wrap around to the bottom
	ld a, [wMaxMenuItem] ; the number of items (DrawStartMenu)
	dec a
	ld [wCurrentMenuItem], a
	call EraseMenuCursor
	jr .loop
.checkIfDownPressed
	bit 7, a
	jr z, .buttonPressed
; if the player pressed tried to go past the bottom item, wrap around to the top
	ld a, [wMaxMenuItem]
	ld c, a
	ld a, [wCurrentMenuItem]
	cp c
	jr nz, .loop
; the player went past the bottom, so wrap to the top
	xor a
	ld [wCurrentMenuItem], a
	call EraseMenuCursor
	jr .loop
.buttonPressed ; A, B, or Start button pressed
	call PlaceUnfilledArrowMenuCursor
	ld a, [wCurrentMenuItem]
	ld [wBattleAndStartSavedMenuItem], a ; save current menu selection
	ld a, b
	and %00001010 ; was the Start button or B button pressed?
	jp nz, CloseStartMenu
	call SaveScreenTilesToBuffer2 ; copy background from wTileMap to wTileMapBackup2
	callba StartMenuChoice ; which item it is, in e (the PC runs there)
	ld a, e
	and a
	jp z, StartMenu_Pokedex
	dec a
	jp z, StartMenu_Pokemon
	dec a
	jp z, StartMenu_Item
	dec a
	jp z, StartMenu_TrainerInfo
	dec a
	jp z, StartMenu_SaveReset
	dec a
	jp z, StartMenu_Option
	dec a
	jp nz, RedisplayStartMenu ; after the PC

; EXIT falls through to here
CloseStartMenu::
	callba SoftlockTeleport	;joenote - do a check for a softlock warp
	call Joypad
	ld a, [hJoyPressed]
	bit 0, a ; was A button newly pressed?
	jr nz, CloseStartMenu
	call LoadTextBoxTilePatterns
	jp CloseTextDisplay
