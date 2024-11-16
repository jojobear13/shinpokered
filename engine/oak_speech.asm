SetDefaultNames:
	ld a, [wLetterPrintingDelayFlags]
	push af
	ld a, [wOptions]
	push af
;	ld a, [wd732]	;joenote - leftover from gamefreak's debug tools. need to clear this.
;	push af
	ld a, [wUnusedD721]	;joenote - preserve extra options
	push af
	ld hl, wPlayerName
	ld bc, wBoxDataEnd - wPlayerName
	xor a
	call FillMemory
	ld hl, wSpriteStateData1
	ld bc, $200
	xor a
	call FillMemory
	pop af
	ld [wUnusedD721], a	;joenote - restore extra options
;	pop af
;	ld [wd732], a
	pop af
	ld [wOptions], a
	pop af
	ld [wLetterPrintingDelayFlags], a
	ld a, [wOptionsInitialized]
	and a
	call z, InitOptions
	ld hl, NintenText
	ld de, wPlayerName
	ld bc, NAME_LENGTH
	call CopyData
	ld hl, SonyText
	ld de, wRivalName
	ld bc, NAME_LENGTH
	jp CopyData

OakSpeech:
	call ClearScreen
	call LoadTextBoxTilePatterns
	call SetDefaultNames
	predef InitPlayerData2
	call RunDefaultPaletteCommand	;gbcnote - reinitialize the default palette in case the pointers got cleared

;joenote - initialize hack version byte as well as...
	ld a, HACK_VERSION
	ld [wRomHackVersion], a
	predef SingleCPUSpeed	;...deactivate 2x speed das it may cause visual bugs during Oak's speech
	
;joenote - give option to play as a female trainer here
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IF DEF(_FPLAYER)
.askBoyGirl
	ld hl, AskIfGirlText
	call PrintText
	call BoyGirlChoice
	ld a, [hJoyHeld]
	bit BIT_B_BUTTON, A
	jr nz, .askBoyGirl
	ld a, [wCurrentMenuItem]
	ld b, a
	ld a, [wUnusedD721]
	res 0, a
	or b
	ld [wUnusedD721], a
	call ClearScreen
ENDC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, $FF
	call PlaySound ; stop music
	ld a, BANK(Music_Routes2)
	ld c, a
	ld a, MUSIC_ROUTES2
	call PlayMusic
	ld hl, wNumBoxItems
	ld a, POTION
	ld [wcf91], a
	ld a, 1
	ld [wItemQuantity], a
	call AddItemToInventory  ; give one potion
	ld a, [wDefaultMap]
	ld [wDestinationMap], a
	call SpecialWarpIn
	xor a
	ld [hTilesetType], a
	ld a, [wd732]
	bit 1, a ; possibly a debug mode bit
	jp nz, .skipChoosingNames
	ld de, ProfOakPic
	lb bc, Bank(ProfOakPic), $00
	call IntroDisplayPicCenteredOrUpperRight
	call FadeInIntroPic
	ld hl, OakSpeechText1
	call PrintText
	call GBFadeOutToWhite
	call ClearScreen
	ld a, NIDORINO
	ld [wd0b5], a
	ld [wcf91], a
	call GetMonHeader
	coord hl, 6, 4
	call LoadFlippedFrontSpriteByMonIndex
	;call MovePicLeft
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;gbcnote - Nidorino needs its pal
	ld a, %11100100
	ld [rBGP], a
	call UpdateGBCPal_BGP
	
	push af
	push bc
	push hl
	push de
	ld d, CONVERT_BGP
	ld e, 0
	callba TransferMonPal 
	pop de
	pop hl
	pop bc
	pop af
	
	call MovePicLeft_NoPalUpdate
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, OakSpeechText2
	call PrintText
	call GBFadeOutToWhite
	call ClearScreen
;joenote - support female sprite
IF DEF(_FPLAYER)
	ld de, RedPicFFront
	lb bc, BANK(RedPicFFront), $00
	ld a, [wUnusedD721]
	bit 0, a	;check if girl
	jr nz, .donefemale_front
ENDC
	ld de, RedPicFront
	lb bc, BANK(RedPicFront), $00
.donefemale_front	
	call IntroDisplayPicCenteredOrUpperRight
	call MovePicLeft
	ld hl, IntroducePlayerText
	call PrintText
	call ChoosePlayerName
	call GBFadeOutToWhite
	call ClearScreen
	ld de, Rival1Pic
	lb bc, Bank(Rival1Pic), $00
	call IntroDisplayPicCenteredOrUpperRight
	call FadeInIntroPic
	ld hl, IntroduceRivalText
	call PrintText
	call ChooseRivalName
.skipChoosingNames
	call GBFadeOutToWhite
	call ClearScreen
;joenote - support female sprite
IF DEF(_FPLAYER)
	ld de, RedPicFFront
	lb bc, BANK(RedPicFFront), $00
	ld a, [wUnusedD721]
	bit 0, a	;check if girl
	jr nz, .donefemale_front2
ENDC
	ld de, RedPicFront
	lb bc, BANK(RedPicFront), $00
.donefemale_front2	
	call IntroDisplayPicCenteredOrUpperRight
	call GBFadeInFromWhite
	ld a, [wd72d]
	and a
	jr nz, .next
	ld hl, OakSpeechText3
	call PrintText
.next
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, SFX_SHRINK
	call PlaySound
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ld c, 4
	call DelayFrames
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;joenote - support female trainer
IF DEF(_FPLAYER)
	ld de, RedFSprite
	lb bc, BANK(RedFSprite), $0C
	ld a, [wUnusedD721]
	bit 0, a	;check if girl
	jr nz, .sprite_next
ENDC
	ld de, RedSprite
	lb bc, BANK(RedSprite), $0C
.sprite_next
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, vSprites
	call CopyVideoData
	ld de, ShrinkPic1
	lb bc, BANK(ShrinkPic1), $00
	call IntroDisplayPicCenteredOrUpperRight
	ld c, 4
	call DelayFrames
	ld de, ShrinkPic2
	lb bc, BANK(ShrinkPic2), $00
	call IntroDisplayPicCenteredOrUpperRight
	call ResetPlayerSpriteData
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, BANK(Music_PalletTown)
	ld [wAudioROMBank], a
	ld [wAudioSavedROMBank], a
	ld a, 10
	ld [wAudioFadeOutControl], a
	ld a, $FF
	ld [wNewSoundID], a
	call PlaySound ; stop music
	pop af
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
	ld c, 20
	call DelayFrames
	coord hl, 6, 5
	ld b, 7
	ld c, 7
	call ClearScreenArea
	call LoadTextBoxTilePatterns
	ld a, 1
	ld [wUpdateSpritesEnabled], a
	ld c, 50
	call DelayFrames
	call GBFadeOutToWhite
	jp ClearScreen
OakSpeechText1:
	TX_FAR _OakSpeechText1
	db "@"
OakSpeechText2:
	TX_FAR _OakSpeechText2A
	TX_CRY_NIDORINA
	TX_FAR _OakSpeechText2B
	db "@"
IntroducePlayerText:
	TX_FAR _IntroducePlayerText
	db "@"
IntroduceRivalText:
	TX_FAR _IntroduceRivalText
	db "@"
OakSpeechText3:
	TX_FAR _OakSpeechText3
	db "@"

FadeInIntroPic:
	ld hl, IntroFadePalettes
	ld b, 6
.next
	ld a, [hli]
	ld [rBGP], a
	call UpdateGBCPal_BGP
	ld c, 10
	call DelayFrames
	dec b
	jr nz, .next
	ret

IntroFadePalettes:
	db %01010100
	db %10101000
	db %11111100
	db %11111000
	db %11110100
	db %11100100

MovePicLeft:
	ld a, %11100100
	ld [rBGP], a
	call UpdateGBCPal_BGP
MovePicLeft_NoPalUpdate: ;gbcnote - need the option to skip updating if needed
	ld a, 119
	ld [rWX], a
	call DelayFrame
.next
	call DelayFrame
	ld a, [rWX]
	sub 8
	cp $FF
	ret z
	ld [rWX], a
	jr .next

DisplayPicCenteredOrUpperRight:
	call GetPredefRegisters
IntroDisplayPicCenteredOrUpperRight:
; b = bank
; de = address of compressed pic
; c: 0 = centred, non-zero = upper-right
	push bc
	ld a, b
	call UncompressSpriteFromDE
	ld hl, sSpriteBuffer1
	ld de, sSpriteBuffer0
	ld bc, $310
	call CopyData
	ld de, vFrontPic
	call InterlaceMergeSpriteBuffers
	pop bc
	ld a, c
	and a
	coord hl, 15, 1
	jr nz, .next
	coord hl, 6, 4
.next
	xor a
	ld [hStartTileID], a
	predef_jump CopyUncompressedPicToTilemap

IF DEF(_FPLAYER)
AskIfGirlText::	;joenote - text to ask if female trainer
	TX_FAR _AskIfGirlText
	db "@"
	
BoyGirlChoice::	;joenote - added this
	call SaveScreenTilesToBuffer1
	ld a, BOY_GIRL_MENU
	ld [wTwoOptionMenuID], a
	coord hl, 13, 7
	ld bc, $080E
	jp DisplayYesNoChoice
ENDC

