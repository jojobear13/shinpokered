; copy text of fixed length NAME_LENGTH (like player name, rival name, mon names, ...)
CopyFixedLengthText:
	ld bc, NAME_LENGTH
	jp CopyData

SetDefaultNamesBeforeTitlescreen:
	ld hl, NintenText
	ld de, wPlayerName
	call CopyFixedLengthText
	ld hl, SonyText
	ld de, wRivalName
	call CopyFixedLengthText
	xor a
	ld [hWY], a
	ld [wLetterPrintingDelayFlags], a
	ld hl, wd732
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld a, BANK(Music_TitleScreen)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a

DisplayTitleScreen:
	call GBPalWhiteOut
	ld a, $1
	ld [H_AUTOBGTRANSFERENABLED], a
	xor a
	ld [hTilesetType], a
IF DEF(_RGTITLE)
	ld [hSCY], a
	ld a, -112
	ld [hSCX], a
ELSE
	ld [hSCX], a
	ld a, $40
	ld [hSCY], a
ENDC
	ld a, $90
	ld [hWY], a
	call ClearScreen
	call DisableLCD
	call LoadFontTilePatterns
	ld hl, NintendoCopyrightLogoGraphics
	ld de, vTitleLogo2 + $100
	ld bc, $50
	ld a, BANK(NintendoCopyrightLogoGraphics)
	call FarCopyData2
	ld hl, GamefreakLogoGraphics
	ld de, vTitleLogo2 + $100 + $50
	ld bc, $90
	ld a, BANK(GamefreakLogoGraphics)
	call FarCopyData2
	ld hl, PokemonLogoGraphics
	ld de, vTitleLogo
	ld bc, $600
	ld a, BANK(PokemonLogoGraphics)
	call FarCopyData2          ; first chunk
	ld hl, PokemonLogoGraphics+$600
	ld de, vTitleLogo2
	ld bc, $100
	ld a, BANK(PokemonLogoGraphics)
	call FarCopyData2          ; second chunk
	ld hl, Version_GFX
	ld de, vChars2 + $600 - (Version_GFXEnd - Version_GFX - $50)
	ld bc, Version_GFXEnd - Version_GFX
	ld a, BANK(Version_GFX)
	call FarCopyDataDouble
	call ClearBothBGMaps

; place tiles for pokemon logo (except for the last row)
	coord hl, 2, 1
	ld a, $80
	ld de, SCREEN_WIDTH
	ld c, 6
.pokemonLogoTileLoop
	ld b, $10
	push hl
.pokemonLogoTileRowLoop ; place tiles for one row
	ld [hli], a
	inc a
	dec b
	jr nz, .pokemonLogoTileRowLoop
	pop hl
	add hl, de
	dec c
	jr nz, .pokemonLogoTileLoop

; place tiles for the last row of the pokemon logo
	coord hl, 2, 7
	ld a, $31
	ld b, $10
.pokemonLogoLastTileRowLoop
	ld [hli], a
	inc a
	dec b
	jr nz, .pokemonLogoLastTileRowLoop

	call DrawPlayerCharacter

; put a pokeball in the player's hand
	ld hl, wOAMBuffer + $28
IF DEF(_RGTITLE)
	ld a, $70
ELSE
	ld a, $74
ENDC
	ld [hl], a

; place tiles for title screen copyright
IF DEF(_REDGREENJP)
	coord hl, 3, 17
	ld de, .tileScreenCopyrightTiles
	ld b, $0D
ELSE
	coord hl, 2, 17
	ld de, .tileScreenCopyrightTiles
	ld b, $10
ENDC
.tileScreenCopyrightTilesLoop
	ld a, [de]
	ld [hli], a
	inc de
	dec b
	jr nz, .tileScreenCopyrightTilesLoop

	jr .next

.tileScreenCopyrightTiles
IF DEF(_REDGREENJP)
	db $41,$43,$44,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E ; ©1995 GAME FREAK inc.
ELIF DEF(_BLUEJP)
	db $41,$42,$43,$44,$42,$43,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E ; ©'95.'96.'98 GAME FREAK inc.
ELSE
	db $41,$42,$43,$42,$44,$42,$45,$46,$47,$48,$49,$4A,$4B,$4C,$4D,$4E ; ©'95.'96.'98 GAME FREAK inc.
ENDC

.next
	call SaveScreenTilesToBuffer2
	call LoadScreenTilesFromBuffer2
	call EnableLCD
IF DEF(_RED)
	ld a, CHARMANDER ; which Pokemon to show first on the title screen
ENDC
IF DEF(_BLUE)
	ld a, SQUIRTLE ; which Pokemon to show first on the title screen
ENDC
IF DEF(_GREEN)
	ld a, BULBASAUR ; which Pokemon to show first on the title screen
ENDC
	ld [wTitleMonSpecies], a
	call LoadTitleMonSprite
	ld a, (vBGMap0 + $300) / $100
	call TitleScreenCopyTileMapToVRAM
	call SaveScreenTilesToBuffer1
	ld a, $40
	ld [hWY], a
	call LoadScreenTilesFromBuffer2
	ld a, vBGMap0 / $100
	call TitleScreenCopyTileMapToVRAM
	ld b, SET_PAL_TITLE_SCREEN
	call RunPaletteCommand
	
	ld a, %11100100
	ld [rBGP], a
	ld [rOBP0], a
	call UpdateGBCPal_BGP
	call UpdateGBCPal_OBP0
		
	push de
	ld d, CONVERT_BGP
	ld e, 2
	callba TransferMonPal ;gbcnote - update the bg pal for the new title mon
	pop de

IF DEF(_RGTITLE)
	ld a, SFX_INTRO_WHOOSH
	call PlaySound
	
; make pokemon logo slide in from the right
	ld bc, hSCX ; background scroll X
	ld hl, .TitleScreenPokemonLogoXScrolls
ELSE
; make pokemon logo bounce up and down
	ld bc, hSCY ; background scroll Y
	ld hl, .TitleScreenPokemonLogoYScrolls
ENDC
.bouncePokemonLogoLoop
	ld a, [hli]
	and a
	jr z, .finishedBouncingPokemonLogo
	ld d, a
	cp -3
	jr nz, .skipPlayingSound
	ld a, SFX_INTRO_CRASH
	call PlaySound
.skipPlayingSound
	ld a, [hli]
	ld e, a
	call .ScrollTitleScreenPokemonLogo
	jr .bouncePokemonLogoLoop

; Controls the bouncing/sliding effect of the Pokemon logo on the title screen
IF DEF(_RGTITLE)
.TitleScreenPokemonLogoXScrolls:
	db 4,28  ; y scroll amount, number of times to scroll
ELSE
.TitleScreenPokemonLogoYScrolls:
	db -4,16  ; y scroll amount, number of times to scroll
	db 3,4
	db -3,4
	db 2,2
	db -2,2
	db 1,2
	db -1,2
ENDC
	db 0      ; terminate list with 0

.ScrollTitleScreenPokemonLogo:
; Scrolls the Pokemon logo on the title screen to create the bouncing effect
; Scrolls d pixels e times
	call DelayFrame
	ld a, [bc] ; background scroll Y
	add d
	ld [bc], a
	dec e
	jr nz, .ScrollTitleScreenPokemonLogo
	ret

.finishedBouncingPokemonLogo
	call LoadScreenTilesFromBuffer1
	ld c, 36
	call DelayFrames
IF DEF(_RGTITLE)
	;do nothing
ELSE
	ld a, SFX_INTRO_WHOOSH
	call PlaySound
ENDC

; scroll game version in from the right
	call PrintGameVersionOnTitleScreen
	ld a, SCREEN_HEIGHT_PIXELS
	ld [hWY], a
IF DEF(_RGTITLE)
	call Delay3
ELSE
	ld d, 144
.scrollTitleScreenGameVersionLoop
	ld h, d
	ld l, 64
	call ScrollTitleScreenGameVersion
	ld h, 0
	ld l, 80
	call ScrollTitleScreenGameVersion
	ld a, d
	add 4
	ld d, a
	and a
	jr nz, .scrollTitleScreenGameVersionLoop
ENDC

	ld a, vBGMap1 / $100
	call TitleScreenCopyTileMapToVRAM
	call LoadScreenTilesFromBuffer2
	call PrintGameVersionOnTitleScreen
	call Delay3
	call WaitForSoundToFinish
	ld a, MUSIC_TITLE_SCREEN
	ld [wNewSoundID], a
	call PlaySound
	xor a
	ld [wUnusedCC5B], a

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;gbcnote - The tiles in the window need to be shifted so that the bottom
;half of the title screen is in the top half of the window area.
;This is accomplished by copying the tile map to vram at an offset.
;The goal is to get the tile map for the bottom half of the title screen
;resides in the BGMap1 address space (address $9c00).
	ld a, (vBGMap0 + $300) / $100
	call TitleScreenCopyTileMapToVRAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
; Keep scrolling in new mons indefinitely until the user performs input.
.awaitUserInterruptionLoop

;credit Dracrius/pocketrgb-en/commit/04c4fc74344c35fcb5179a6509a73dd380a16d97
IF DEF(_RGTITLE)	;Pokemon scroll fast in jp Red and Green
	ld c, 255
ELSE
	ld c, 200
ENDC

	call CheckForUserInterruption
	jr c, .finishedWaiting
	call TitleScreenScrollInMon
	ld c, 1
	call CheckForUserInterruption
	jr c, .finishedWaiting
	callba TitleScreenAnimateBallIfStarterOut
	call TitleScreenPickNewMon
	jr .awaitUserInterruptionLoop

.finishedWaiting
	ld a, [wTitleMonSpecies]
	call PlayCry
	call WaitForSoundToFinish
	call GBPalWhiteOutWithDelay3
	call ClearSprites
	xor a
	ld [hWY], a
	ld [wMapPalOffset], a	;joenote - undo darkened rock tunnel if the player saved there and exited to the title screen
	inc a
	ld [H_AUTOBGTRANSFERENABLED], a
	call ClearScreen
	ld a, vBGMap0 / $100
	call TitleScreenCopyTileMapToVRAM
	ld a, vBGMap1 / $100
	call TitleScreenCopyTileMapToVRAM
	call Delay3
	call LoadGBPal
	ld a, [hJoyHeld]
	ld b, a
	and D_UP | SELECT | B_BUTTON
	cp D_UP | SELECT | B_BUTTON
	jp z, .doClearSaveDialogue
	jp MainMenu

.doClearSaveDialogue
	jpba DoClearSaveDialogue

TitleScreenPickNewMon:
	ld a, vBGMap0 / $100
	call TitleScreenCopyTileMapToVRAM

.loop
; Keep looping until a mon different from the current one is picked.
	call Random
	and $f
	ld c, a
	ld b, 0
	ld hl, TitleMons
	add hl, bc
	ld a, [hl]
	ld hl, wTitleMonSpecies

; Can't be the same as before.
	cp [hl]
	jr z, .loop

	ld [hl], a
	call LoadTitleMonSprite
	
	push de
	ld d, CONVERT_BGP
	ld e, 2
	callba TransferMonPal ;gbcnote - update the bg pal for the new title mon
	pop de
	
	ld a, $90
	ld [hWY], a
	ld d, 1 ; scroll out
	callba TitleScroll
	ret

TitleScreenScrollInMon:
	ld d, 0 ; scroll in
	callba TitleScroll
	;xor a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;gbcnote - The window normally covers the whole screen when picking a new title screen mon.
;This is not desired since it applies BG pal 2 to the whole screen when on a gbc.
;Instead, shift the window downwards by 40 tiles to just cover the version text and below.
;This makes it so the map attributes for BGMap1 (address $9c00) are covering the bottom half 
;of the screen.
	ld a, $40
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld [hWY], a
	ret

ScrollTitleScreenGameVersion:
	predef BGLayerScrollingUpdate	;joenote - consolidated into a predef that also fixes some issues

.wait2
	ld a, [rLY]
	cp h
	jr z, .wait2
	ret

;joenote - add support for female player
IF DEF(_FPLAYER)
DrawPlayerCharacter_F:
	ld hl, FPlayerCharacterTitleGraphics
	ld de, vSprites
	ld bc, FPlayerCharacterTitleGraphicsEnd - FPlayerCharacterTitleGraphics
	ld a, BANK(FPlayerCharacterTitleGraphics)
	jr DrawPlayerCharacter.copy
ENDC

DrawPlayerCharacter:
	ld hl, PlayerCharacterTitleGraphics
	ld de, vSprites
	ld bc, PlayerCharacterTitleGraphicsEnd - PlayerCharacterTitleGraphics
	ld a, BANK(PlayerCharacterTitleGraphics)
.copy
	call FarCopyData2
	call ClearSprites
	xor a
	ld [wPlayerCharacterOAMTile], a
	ld hl, wOAMBuffer
IF DEF(_RGTITLE)
	ld de, $6030
ELSE
	ld de, $605a
ENDC
	ld b, 7
.loop
	push de
	ld c, 5
.innerLoop
	ld a, d
	ld [hli], a ; Y
	ld a, e
	ld [hli], a ; X
	add 8
	ld e, a
	ld a, [wPlayerCharacterOAMTile]
	ld [hli], a ; tile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;gbcnote - set the palette for the player tiles
;These bits only work on the GBC
	push af
	ld a, [hl]	;Attributes/Flags
	and %11111000
	or  %00000010
	ld [hl], a
	pop af
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	inc a
	ld [wPlayerCharacterOAMTile], a
	inc hl
	dec c
	jr nz, .innerLoop
	pop de
	ld a, 8
	add d
	ld d, a
	dec b
	jr nz, .loop
	ret

ClearBothBGMaps:
	ld hl, vBGMap0
	ld bc, $400 * 2
	ld a, " "
	jp FillMemory

LoadTitleMonSprite:
	ld [wcf91], a
	ld [wd0b5], a
IF DEF(_RGTITLE)
	coord hl, 9, 10
ELSE
	coord hl, 5, 10
ENDC
	call GetMonHeader
	jp LoadFrontSpriteByMonIndex

TitleScreenCopyTileMapToVRAM:
	ld [H_AUTOBGTRANSFERDEST + 1], a
	jp Delay3

LoadCopyrightAndTextBoxTiles:
	xor a
	ld [hWY], a
	call ClearScreen
	call LoadTextBoxTilePatterns

LoadCopyrightTiles:
	ld de, NintendoCopyrightLogoGraphics
	ld hl, vChars2 + $600
	lb bc, BANK(NintendoCopyrightLogoGraphics), (GamefreakLogoGraphicsEnd - NintendoCopyrightLogoGraphics) / $10
	call CopyVideoData
IF DEF(_REDGREENJP)
	coord hl, 4, 7
ELSE
	coord hl, 2, 7
ENDC
	ld de, CopyrightTextString
	jp PlaceString

CopyrightTextString:
IF DEF(_REDGREENJP)
	db   $60,$62,$63,$64,$65,$66,$67,$68,$69,$6A             ; ©1995 Nintendo
	next $60,$62,$63,$64,$6B,$6C,$6D,$6E,$6F,$70,$71,$72     ; ©1995 Creatures inc.
	next $60,$62,$63,$64,$73,$74,$75,$76,$77,$78,$79,$7A,$7B ; ©1995 GAME FREAK inc.
ELIF DEF(_BLUEJP)
	db   $60,$61,$62,$63,$61,$62,$64,$65,$66,$67,$68,$69,$6A             ; ©1995.1996 Nintendo
	next $60,$61,$62,$63,$61,$62,$64,$6B,$6C,$6D,$6E,$6F,$70,$71,$72     ; ©1995.1996 Creatures inc.
	next $60,$61,$62,$63,$61,$62,$64,$73,$74,$75,$76,$77,$78,$79,$7A,$7B ; ©1995.1996 GAME FREAK inc.
ELSE
	db   $60,$61,$62,$61,$63,$61,$64,$7F,$65,$66,$67,$68,$69,$6A             ; ©'95.'96.'98 Nintendo
	next $60,$61,$62,$61,$63,$61,$64,$7F,$6B,$6C,$6D,$6E,$6F,$70,$71,$72     ; ©'95.'96.'98 Creatures inc.
	next $60,$61,$62,$61,$63,$61,$64,$7F,$73,$74,$75,$76,$77,$78,$79,$7A,$7B ; ©'95.'96.'98 GAME FREAK inc.
ENDC
	db   "@"

INCLUDE "data/title_mons.asm"

; prints version text (red, blue)
PrintGameVersionOnTitleScreen:
IF DEF(_GREEN)
	coord hl, 6, 8
ELSE
	coord hl, 7, 8
ENDC
	ld de, VersionOnTitleScreenText
	jp PlaceString

; these point to special tiles specifically loaded for that purpose and are not usual text
VersionOnTitleScreenText:
IF DEF(_RED)
	db $60,$61,$7F,$65,$66,$67,$68,$69,"@" ; "Red Version"
ENDC
IF DEF(_BLUE)
	db $61,$62,$63,$64,$65,$66,$67,$68,"@" ; "Blue Version"
ENDC
IF DEF(_GREEN)
	db $62,$63,$64,$7F,$65,$66,$67,$68,$69,"@" ; "Green Version"
ENDC
NintenText: db "NINTEN@"
SonyText:   db "SONY@"
