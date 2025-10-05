const_value = -1
	const MOVE_NIDORINO_RIGHT
	const MOVE_GENGAR_RIGHT
	const MOVE_GENGAR_LEFT

ANIMATION_END EQU 80

const_value = 3
	const GENGAR_INTRO_TILES1
	const GENGAR_INTRO_TILES2
	const GENGAR_INTRO_TILES3

PlayIntro:
	xor a
	ld [hJoyHeld], a
	inc a
	ld [H_AUTOBGTRANSFERENABLED], a
	call PlayShootingStar
	call PlayIntroScene
	call GBFadeOutToWhite
	xor a
	ld [hSCX], a
	ld [H_AUTOBGTRANSFERENABLED], a
	call ClearSprites
	call DelayFrame
	ret

PlayIntroScene:
	ld b, SET_PAL_NIDORINO_INTRO
	call RunPaletteCommand
	ldPal a, BLACK, DARK_GRAY, LIGHT_GRAY, WHITE
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a
	call UpdateGBCPal_BGP
	call UpdateGBCPal_OBP0
	call UpdateGBCPal_OBP1
	
IF DEF(_BLUE)
	push de
	ld d, CONVERT_OBP0
	ld e, 0
	ld a, JIGGLYPUFF
	ld [wcf91], a
	callba TransferMonPal ;gbcnote - jigglypuff object needs its pal in blue version
	pop de
ENDC
	
	xor a
	ld [hSCX], a
	ld b, GENGAR_INTRO_TILES1
	call IntroCopyTiles
	
;credit Dracrius/pocketrgb-en/commit/04c4fc74344c35fcb5179a6509a73dd380a16d97
IF DEF(_REDGREENJP)
	ld a, 8	; Nidorino is 8px further over than Jigglypuff in the JP Red and Green
ELSE 
	ld a, 0
ENDC

	ld [wBaseCoordX], a
	ld a, 80
	ld [wBaseCoordY], a
	lb bc, 6, 6
	call InitIntroNidorinoOAM
	lb de, 80 / 2, MOVE_NIDORINO_RIGHT
	call IntroMoveMon
	ret c

; hip
	ld a, SFX_INTRO_HIP
	call PlaySound
	xor a
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation1
	call AnimateIntroNidorino
; hop
	ld a, SFX_INTRO_HOP
	call PlaySound
	ld de, IntroNidorinoAnimation2
	call AnimateIntroNidorino
	ld c, 10
	call CheckForUserInterruption
	ret c

; hip
	ld a, SFX_INTRO_HIP
	call PlaySound
	ld de, IntroNidorinoAnimation1
	call AnimateIntroNidorino
; hop
	ld a, SFX_INTRO_HOP
	call PlaySound
	ld de, IntroNidorinoAnimation2
	call AnimateIntroNidorino
	ld c, 30
	call CheckForUserInterruption
	ret c

; raise
	ld b, GENGAR_INTRO_TILES2
	call IntroCopyTiles
	ld a, SFX_INTRO_RAISE
	call PlaySound
	lb de, 8 / 2, MOVE_GENGAR_LEFT
	call IntroMoveMon
	ld c, 30
	call CheckForUserInterruption
	ret c

; slash
	ld b, GENGAR_INTRO_TILES3
	call IntroCopyTiles
	ld a, SFX_INTRO_CRASH
	call PlaySound
	lb de, 16 / 2, MOVE_GENGAR_RIGHT
	call IntroMoveMon
; hip
	ld a, SFX_INTRO_HIP
	call PlaySound
	ld a, (FightIntroFrontMon2 - FightIntroFrontMon) / BYTES_PER_TILE
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation3
	call AnimateIntroNidorino
	ld c, 30
	call CheckForUserInterruption
	ret c

	lb de, 8 / 2, MOVE_GENGAR_LEFT
	call IntroMoveMon
	ld b, GENGAR_INTRO_TILES1
	call IntroCopyTiles
	ld c, 60
	call CheckForUserInterruption
	ret c

; hip
	ld a, SFX_INTRO_HIP
	call PlaySound
	xor a
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation4
	call AnimateIntroNidorino
;joenote - in jp-red and green this is a "hip", but that appears to be a small mistake corrected in jp-blue version
; hop
	ld a, SFX_INTRO_HOP
	call PlaySound
	ld de, IntroNidorinoAnimation5
	call AnimateIntroNidorino
	ld c, 20
	call CheckForUserInterruption
	ret c

	ld a, (FightIntroFrontMon2 - FightIntroFrontMon) / BYTES_PER_TILE
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation6
	call AnimateIntroNidorino
	ld c, 30
	call CheckForUserInterruption
	ret c

; lunge
	ld a, SFX_INTRO_LUNGE
	call PlaySound
	ld a, (FightIntroFrontMon3 - FightIntroFrontMon) / BYTES_PER_TILE
	ld [wIntroNidorinoBaseTile], a
	ld de, IntroNidorinoAnimation7
IF DEF(_REDGREENJP)	;redjp and green have a delay after the leap for some reason
	call AnimateIntroNidorino
	ld c, 80
	call DelayFrames
	ret
ELSE
	jp AnimateIntroNidorino
ENDC

AnimateIntroNidorino:
	ld a, [de]
	cp ANIMATION_END
	ret z
	ld [wBaseCoordY], a
	inc de
	ld a, [de]
	ld [wBaseCoordX], a
	push de
	ld c, 6 * 6
	call UpdateIntroNidorinoOAM
	ld c, 5
	call DelayFrames
	pop de
	inc de
	jr AnimateIntroNidorino

UpdateIntroNidorinoOAM:
	ld hl, wOAMBuffer
	ld a, [wIntroNidorinoBaseTile]
	ld d, a
.loop
	ld a, [wBaseCoordY]
	add [hl]
	ld [hli], a ; Y
	ld a, [wBaseCoordX]
	add [hl]
	ld [hli], a ; X
	ld a, d
	ld [hli], a ; tile
	inc hl
	inc d
	dec c
	jr nz, .loop
	ret

InitIntroNidorinoOAM:
	ld hl, wOAMBuffer
	ld d, 0
.loop
	push bc
	ld a, [wBaseCoordY]
	ld e, a
.innerLoop
	ld a, e
	add 8
	ld e, a
	ld [hli], a ; Y
	ld a, [wBaseCoordX]
	ld [hli], a ; X
	ld a, d
	ld [hli], a ; tile
	ld a, OAM_BEHIND_BG
	ld [hli], a ; attributes
	inc d
	dec c
	jr nz, .innerLoop
	ld a, [wBaseCoordX]
	add 8
	ld [wBaseCoordX], a
	pop bc
	dec b
	jr nz, .loop
	ret

IntroClearScreen:
	ld hl, vBGMap1
	ld bc, BG_MAP_WIDTH * SCREEN_HEIGHT
	jr IntroClearCommon

IntroClearMiddleOfScreen:
; clear the area of the tile map between the black bars on the top and bottom
	coord hl, 0, 4
	ld bc, SCREEN_WIDTH * 10

IntroClearCommon:
	ld [hl], 0
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, IntroClearCommon
	ret

IntroPlaceBlackTiles:
	ld a, 1
.loop
	ld [hli], a
	dec c
	jr nz, .loop
	ret

IntroMoveMon:
; d = number of times to move the mon (2 pixels each time)
	ld a, e
	cp MOVE_NIDORINO_RIGHT
	jr z, .moveNidorinoRight
	cp MOVE_GENGAR_LEFT
	jr z, .moveGengarLeft
; move Gengar right
	ld a, [hSCX]
	dec a
	dec a
	jr .next
.moveNidorinoRight
	push de
	ld a, 2
	ld [wBaseCoordX], a
	xor a
	ld [wBaseCoordY], a
	ld c, 6 * 6
	call UpdateIntroNidorinoOAM
	pop de
.moveGengarLeft
	ld a, [hSCX]
	inc a
	inc a
.next
	ld [hSCX], a
	push de
	ld c, 2
	call CheckForUserInterruption
	pop de
	ret c
	dec d
	jr nz, IntroMoveMon
	ret

IntroCopyTiles:
	coord hl, 13, 7

CopyTileIDsFromList_ZeroBaseTileID:
	ld c, 0
	predef_jump CopyTileIDsFromList

PlayMoveSoundB:
; unused
	predef GetMoveSoundB
	ld a, b
	jp PlaySound

LoadIntroGraphics:
	ld hl, FightIntroBackMon
	ld de, vChars2
	ld bc, FightIntroBackMonEnd - FightIntroBackMon
	ld a, BANK(FightIntroBackMon)
	call FarCopyData2
	ld hl, GameFreakIntro
	ld de, vChars2 + (FightIntroBackMonEnd - FightIntroBackMon)
	ld bc, GameFreakIntroEnd - GameFreakIntro
	ld a, BANK(GameFreakIntro)
	call FarCopyData2
	ld hl, GameFreakIntro
	ld de, vChars1
	ld bc, GameFreakIntroEnd - GameFreakIntro
	ld a, BANK(GameFreakIntro)
	call FarCopyData2
	ld hl, FightIntroFrontMon
	ld de, vChars0
	ld bc, FightIntroFrontMonEnd - FightIntroFrontMon
	ld a, BANK(FightIntroFrontMon)
	jp FarCopyData2

PlayShootingStar:
	ld b, SET_PAL_GAME_FREAK_INTRO
	call RunPaletteCommand
	callba LoadCopyrightAndTextBoxTiles
	ldPal a, BLACK, DARK_GRAY, LIGHT_GRAY, WHITE
	ld [rBGP], a
	call UpdateGBCPal_BGP
	ld c, 180
	;call DelayFrames
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;joenote - activate/deactivate gamma shader if select is pressed at copyright screen
;		- Behavior is determined by the destination code in the rom header
	ld a, [hGBC]
	and a
	jr z, .endgammaloop	;do not bother if not in GBC mode
	
	;set the default based on the header destination code
	ld b, a	;B is now 01
	ld a, [$014A] ;read destination code from rom header (00 for JP or 01 for !JP)
	xor $01	;invert the code (01 for JP or 00 for !JP)
	add b ;(A = 02 for JP or 01 for !JP)
	ld [hGBC], a	;set default shader state (02 for ON or 01 for OFF)
	
;check if there is a save on file, and instead load the last known gamma setting if a save is found
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, $1
	ld [MBC1SRamBankingMode], a
	ld [MBC1SRamBank], a
	ld hl, sMainData + ($D886 - wMainDataStart)
	bit 7, [hl]
	jr z, .sramOff
	ld a, 2
	bit 6, [hl]
	jr nz, .load2
.load1
	dec a
.load2
	ld [hGBC], a
.sramOff
	xor a
	ld [MBC1SRamEnable], a
	ld [MBC1SRamBankingMode], a
	
.gammaloop
	call DelayFrame
	push bc
	call ReadJoypad
	pop bc
	ld a, [hJoyInput]
	and SELECT
	jr z, .skipgamma
	
	;toggle the shader from its default due to pressing SELECT
	ld a, [$014A] ;read destination code from rom header (00 for JP or 01 for !JP)
	xor $01	;invert the code (01 for JP or 00 for !JP)
	ld b, a
	ld a, $02
	sub b 	;A is now 01 for JP or 02 for !JP
	ld [hGBC], a	;Toggle the shader state from the default
	
;	Play a SFX and print some tiles to confirm that it worked
	coord hl, $12, $11
	ld a, $7D
	ld [hl], a
	coord hl, $13, $11
	ld a, $7E
	ld [hl], a
	ld a, SFX_SNARE_1
	call PlaySound
	
	jr .endgammaloop

.skipgamma	
	dec c
	jr nz, .gammaloop
.endgammaloop
	inc c
	call DelayFrames
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	call ClearScreen
	call DisableLCD
	xor a
	ld [wCurOpponent], a
	call IntroDrawBlackBars
	call LoadIntroGraphics
	call EnableLCD
	ld hl, rLCDC
	res 5, [hl]
	set 3, [hl]
	ld c, 64
	call DelayFrames
	callba AnimateShootingStar
	push af

;joenote - restore "Presents" for the japanese builds
	coord hl, 7, 11
	ld de, .presentsTiles
	ld b, 6
.presentsTilesLoop
	ld a, [de]
	ld [hli], a
	inc de
	dec b
	jr nz, .presentsTilesLoop
	jr .presentEnd
.presentsTiles
	db $67,$68,$69,$6A,$6B,$6C ; "Presents"
.presentEnd

	pop af
	jr c, .next ; skip the delay if the user interrupted the animation
	ld c, 40
	call DelayFrames
.next
	ld a, BANK(Music_IntroBattle)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, MUSIC_INTRO_BATTLE
	ld [wNewSoundID], a
	call PlaySound
	call IntroClearMiddleOfScreen
	call ClearSprites
	jp Delay3

IntroDrawBlackBars:
; clear the screen and draw black bars on the top and bottom
	call IntroClearScreen
	coord hl, 0, 0
	ld c, SCREEN_WIDTH * 4
	call IntroPlaceBlackTiles
	coord hl, 0, 14
	ld c, SCREEN_WIDTH * 4
	call IntroPlaceBlackTiles
	ld hl, vBGMap1
	ld c,  BG_MAP_WIDTH * 4
	call IntroPlaceBlackTiles
	ld hl, vBGMap1 + BG_MAP_WIDTH * 14
	ld c,  BG_MAP_WIDTH * 4
	jp IntroPlaceBlackTiles

EmptyFunc4:
	ret

IntroNidorinoAnimation0:
	db 0, 0
	db ANIMATION_END

IntroNidorinoAnimation1:
; This is a sequence of pixel movements for part of the Nidorino animation. This
; list describes how Nidorino should hop.
; First byte is y movement, second byte is x movement
	db  0, 0
	db -2, 2
	db -1, 2
	db  1, 2
	db  2, 2
	db ANIMATION_END

IntroNidorinoAnimation2:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db  0,  0
	db -2, -2
	db -1, -2
	db  1, -2
	db  2, -2
	db ANIMATION_END

IntroNidorinoAnimation3:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db   0, 0
	db -12, 6
	db  -8, 6
	db   8, 6
	db  12, 6
	db ANIMATION_END

IntroNidorinoAnimation4:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db  0,  0
	db -8, -4
	db -4, -4
	db  4, -4
	db  8, -4
	db ANIMATION_END

IntroNidorinoAnimation5:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db  0, 0
	db -8, 4
	db -4, 4
	db  4, 4
	db  8, 4
	db ANIMATION_END

IntroNidorinoAnimation6:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db 0, 0
	db 2, 0
	db 2, 0
	db 0, 0
	db ANIMATION_END

IntroNidorinoAnimation7:
; This is a sequence of pixel movements for part of the Nidorino animation.
; First byte is y movement, second byte is x movement
	db -8, -16
	db -7, -14
	db -6, -12
	db -4, -10
	db ANIMATION_END

GameFreakIntro:
	INCBIN "gfx/gamefreak_intro.2bpp"
	INCBIN "gfx/gamefreak_logo.2bpp"
	ds $10 ; blank tile
GameFreakIntroEnd:

FightIntroBackMon:
	INCBIN "gfx/intro_fight.2bpp"
FightIntroBackMonEnd:

FightIntroFrontMon:

IF (DEF(_RED) || DEF(_GREEN))
	INCBIN "gfx/red/intro_nido_1.2bpp"
FightIntroFrontMon2:
	INCBIN "gfx/red/intro_nido_2.2bpp"
FightIntroFrontMon3:
	INCBIN "gfx/red/intro_nido_3.2bpp"
ENDC

IF DEF(_BLUE)
	INCBIN "gfx/blue/intro_purin_1.2bpp"
FightIntroFrontMon2:
	INCBIN "gfx/blue/intro_purin_2.2bpp"
FightIntroFrontMon3:
	INCBIN "gfx/blue/intro_purin_3.2bpp"
ENDC

FightIntroFrontMonEnd:

	ds $10 ; blank tile
