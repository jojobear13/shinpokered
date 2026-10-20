SoftReset::
	call StopAllSounds
	call GBPalWhiteOut
	ld c, 32
	call DelayFrames
	; fallthrough

Init::
;  Program init.

rLCDC_DEFAULT EQU %11100011
; * LCD enabled
; * Window tile map at $9C00
; * Window display enabled
; * BG and window tile data at $8800
; * BG tile map at $9800
; * 8x8 OBJ size
; * OBJ display enabled
; * BG display enabled

	di

	xor a
	ld [rIF], a
	ld [rIE], a
	ld [rSCX], a
	ld [rSCY], a
	ld [rSB], a
	ld [rSC], a
	ld [rWX], a
	ld [rWY], a
	ld [rTMA], a
	ld [rTAC], a
	ld [rBGP], a
	ld [rOBP0], a
	ld [rOBP1], a

	ld a, rLCDC_ENABLE_MASK
	ld [rLCDC], a
	call DisableLCD

	ld sp, wStack

	ld hl, $c000 ; start of WRAM
	ld bc, $2000 ; size of WRAM
.loop
	ld [hl], 0
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .loop

;joenote - implement xor shift RNG
;Initialize the RNG state. It can be initialized to anything but zero; this is just a simple way of doing it.
;Initialize with whatever random garbage is in hram to get an initial seed.
	ld a, [hJoyLast]	;ffb1
	and a
	push af
	ld a, [H_FRAMECOUNTER]	;ffd5
	and a
	push af
	ld a, [hDividend2]	;ffe5
	and a
	push af
	ld a, [hSpriteAnimFrameCounter]	;ffea
	and a
	push af
	
	call ClearVram

	ld hl, $ff80
	ld bc, $fffe - $ff80	;gbcnote - don't clear hGBC
	call FillMemory

	call ClearSprites

;finish initializing RNG
;joenote - added lines to save the RNG seed
	ld hl, wRNGSeed
	pop af
	call z, .inc_a
	ld [hRandomAdd], a
	ld [hli], a
	pop af
	call z, .inc_a
	ld [hRandomSub], a
	ld [hli], a
	pop af
	call z, .inc_a
	ld [hRandomLast], a
	ld [hli], a
	pop af
	call z, .inc_a
	ld [hRandomLast + 1], a
	ld [hli], a
	
	ld a, Bank(WriteDMACodeToHRAM)
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	call WriteDMACodeToHRAM

	xor a
	ld [hTilesetType], a
	ld [rSTAT], a
	ld [hSCX], a
	ld [hSCY], a
	ld [rIF], a
	ld a, 1 << VBLANK + 1 << TIMER + 1 << SERIAL
	ld [rIE], a

	ld a, 144 ; move the window off-screen
	ld [hWY], a
	ld [rWY], a
	ld a, 7
	ld [rWX], a

	ld a, CONNECTION_NOT_ESTABLISHED
	ld [hSerialConnectionStatus], a

	ld h, vBGMap0 / $100
	call ClearBgMap
	ld h, vBGMap1 / $100
	call ClearBgMap

	ld a, rLCDC_DEFAULT
	ld [rLCDC], a
	ld a, 16
	ld [hSoftReset], a
	call StopAllSounds

	ei

	predef LoadSGB

	ld a, BANK(SFX_Shooting_Star)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, $9c
	ld [H_AUTOBGTRANSFERDEST + 1], a
	xor a
	ld [H_AUTOBGTRANSFERDEST], a
	dec a
	ld [wUpdateSpritesEnabled], a

	predef PlayIntro

	call DisableLCD
	call ClearVram
	call GBPalNormal
	call ClearSprites
	ld a, rLCDC_DEFAULT
	ld [rLCDC], a

	jp SetDefaultNamesBeforeTitlescreen
.inc_a
	inc a
	ret
	
ClearVram:
	ld hl, $8000
	ld bc, $2000
	xor a
	jp FillMemory


StopAllSounds::
	ld a, BANK(Audio1_UpdateMusic)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	xor a
	ld [wAudioFadeOutControl], a
	ld [wNewSoundID], a
	ld [wLastMusicSoundID], a
	jp StopAllMusic

