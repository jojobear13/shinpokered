DisplayExtraOptionMenu:
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld a, 1 ;cursor Y coordinate
	ld [wTopMenuItemY], a
	ld a, 1 ;cursor X coordinate
	ld [wTopMenuItemX], a

	ld a, 1
	ld [wLetterPrintingDelayFlags], a	;no delay
	ld a, $01
	ld [H_AUTOBGTRANSFERENABLED], a ; enable auto background transfer

;draw text box border for lite options
	coord hl, 0, 0
	ld b, 7
	ld c, 18
	call TextBoxBorder
;draw text box border for master options
;	coord hl, 0, 9
;	ld b, 2
;	ld c, 18
;	call TextBoxBorder

	call PlaceExtraOptionStrings
	
	call PlaceSoundSetting	;joenote - display the sound setting
	call Show60FPSSetting	;60fps - display current setting
	call ShowLaglessTextSetting	;joenote - display marker for lagless text or not
	call ShowHardModeSetting	;joenote - display marker for hard mode or not
	call ShowNoSwitchSetting	;joenote - display marker for deactivated trainer switching or not
	call ShowGammaSetting
	call ShowEnhancedGBCSetting
	
;	call ShowBadgeCap	;joenote - show the level cap depending on badge
;	call ShowNuzlocke

	call Delay3
.loop
	call PlaceMenuCursor

.getJoypadStateLoop
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	bit BIT_B_BUTTON, b ; B button pressed?
	jp nz, .exitMenu
	bit BIT_START, b ; Start button pressed?
	jp nz, .exitMenu
	bit BIT_SELECT, b ; Select button pressed?
	jp nz, DisplaySoundTestMenu
	bit BIT_A_BUTTON, b ; A button pressed?
	jr nz, .cursor_section
	jr .checkDirectionKeys	;jump if d-pad pressed
.cursor_section
	ld a, [wTopMenuItemY]
	cp $1 ; cursor over audio?
	jr z, .cursorAudio
	cp $2 ; cursor over FPS?
	jr z, .cursorFPS
	cp $3 ; cursor over instant text?
	jr z, .cursorInstText
	cp $4 ; cursor over hard mode?
	jr z, .cursorHardMode
	cp $5 ; cursor over ai switching?
	jr z, .cursorAISwitch
	cp $6 ;cursor over gamma shader?
	jr z, .cursorGamma
	cp $7 ;cursor over enhanced gbc?
	jr z, .cursorEnhGBC
;	cp $A ; cursor over lvl cap?
;	jr z, .cursorLvlCap
;	cp $B ; cursor over nuzlocke?
;	jr z, .cursorNuzlocke
	cp $10 ; is the cursor on Back?
	jr z, .exitMenu
	jr .getJoypadStateLoop
	
.cursorAudio
	call CycleSoundSetting
	jr .getJoypadStateLoop
.cursorFPS
	call Toggle60FPSSetting
	jr .getJoypadStateLoop
.cursorInstText
	call ToggleLaglessText
	jr .getJoypadStateLoop
.cursorHardMode
	call ToggleHardMode
	jr .getJoypadStateLoop
.cursorAISwitch
	call ToggleNoSwitch
	jr .getJoypadStateLoop
.cursorGamma
	call ToggleGammaShader
	jr .getJoypadStateLoop
.cursorEnhGBC
	call ToggleEnhancedGBCColors
	jr .getJoypadStateLoop
;.cursorLvlCap
;	call ToggleBadgeCap
;	jr .getJoypadStateLoop
;.cursorNuzlocke
;	call ToggleNuzlocke
;	jr .getJoypadStateLoop

.checkDirectionKeys
	ld a, [wTopMenuItemY]
	bit BIT_D_DOWN, b ; Down pressed?
	jr nz, .downPressed
	bit BIT_D_UP, b ; Up pressed?
	jr nz, .upPressed
	bit BIT_D_LEFT, b ; Left pressed?
	jr nz, .cursor_section
	bit BIT_D_RIGHT, b ; Right pressed?
	jr nz, .cursor_section
	jp .getJoypadStateLoop
.downPressed
	cp 16
	ld b, -15
	jr z, .updateMenuVariables
	cp 7
	ld b, 9	;	ld b, 3
	jr z, .updateMenuVariables
;	cp 10
;	ld b, 6
;	jr z, .updateMenuVariables
	;else
	ld b, 1
	jr .updateMenuVariables
.upPressed
	cp 1
	ld b, 15
	jr z, .updateMenuVariables
;	cp 10
;	ld b, -3
;	jr z, .updateMenuVariables
	cp 16
	ld b, -9	;ld b, -5
	jr z, .updateMenuVariables
	;else
	ld b, -1
.updateMenuVariables
	add b
	ld [wTopMenuItemY], a
	ld a, 1
	ld [wTopMenuItemX], a
	call PlaceExtraOptionStrings
	jp .loop

.exitMenu
	ld a, SFX_PRESS_AB
	call PlaySound
	call ClearScreen
	ret


PlaceExtraOptionStrings:
;place audio text
	coord hl, 1, 1
	ld de, TextAudio
	call PlaceString
	
;place 60fps text
	coord hl, 1, 2
	ld de, TextFPS
	call PlaceString
	
;place instant text
	coord hl, 1, 3
	ld de, TextInstant
	call PlaceString

;place hard mode text
	coord hl, 1, 4
	ld de, TextHardMode
	call PlaceString

;place AI switching text
	coord hl, 1, 5
	ld de, TextAISwitch
	call PlaceString

;place gamma shader text
	coord hl, 1, 6
	ld de, TextGamma
	call PlaceString
	
;place enhanced GBC color text
	coord hl, 1, 7
	ld de, TextEnhancedGBC
	call PlaceString

;place back text
	coord hl, 1, 16
	ld de, TextBack
	call PlaceString

;place lvl cap text
;	coord hl, 1, 10
;	ld de, TextAILevelCap
;	call PlaceString

;place nuzlocke text
;	coord hl, 1, 11
;	ld de, TextNuzlocke
;	call PlaceString

	ret


;joenote - show the sound setting on the menu
CycleSoundSetting:	;joenote - cycle through mono, earphone 1, 2, and 3
	ld a, [wOptions]
	push bc
	ld b, a
	ld c, a
	
	ld a, (SOUND_STEREO_BITS ^ $FF)
	and b
	ld b, a
	
	ld a, c
	and SOUND_STEREO_BITS
	swap a
	inc a
	swap a
	and SOUND_STEREO_BITS
	or b
	pop bc
	ld [wOptions], a
	;fall through
PlaceSoundSetting:
	ld hl, OptionMenuSoundText
	ld a, [wOptions]
	and SOUND_STEREO_BITS
	swap a
.loop
	and a
	jr z, .done
	dec a
	inc hl
	inc hl
	jr .loop
.done
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, $A, $1
	call PlaceString
	ret
OptionMenuSoundText:
	dw OptionMenuMono
	dw OptionMenuEar1
	dw OptionMenuEar2
	dw OptionMenuEar3
OptionMenuMono:
	db "     MONO@"
OptionMenuEar1:
	db "EARPHONE1@"
OptionMenuEar2:
	db "EARPHONE2@"
OptionMenuEar3:
	db "EARPHONE3@"


;60fps - show the fps setting on the menu when activated
Toggle60FPSSetting:
	ld a, [wUnusedD721]
	xor %00010000
	ld [wUnusedD721], a
	;fall through
Show60FPSSetting:
	ld hl, OptionMenuFPSText
	ld a, [wUnusedD721]
	bit 4, a
	jr nz, .done
	inc hl
	inc hl
.done
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, $11, $2
	call PlaceString
	ret
OptionMenuFPSText:
	dw OptionMenu60FPS
	dw OptionMenu30FPS
OptionMenu60FPS:
	db "60@"
OptionMenu30FPS:
	db "30@"

	
;joenote - for lagless text option
ToggleLaglessText:
	ld a, [wOptions]
	and %11111001
	xor TEXT_DELAY_FAST
	ld [wOptions], a
	;fall through
ShowLaglessTextSetting:
	ld hl, OptionMenuOnOffText
	ld a, [wOptions]
	and TEXT_DELAY_BITS
	jr z, .print
	inc hl
	inc hl
.print
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, $10, $03
	call PlaceString
	ret


;joenote - for hard mode option
ToggleHardMode:
	ld a, [wOptions]
	xor BATTLE_HARD_MODE
	ld [wOptions], a
	;fall through
ShowHardModeSetting:
	ld hl, OptionMenuOnOffText
	ld a, [wOptions]
	bit BIT_BATTLE_HARD, a
	jr nz, .print
	inc hl
	inc hl
.print
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, $10, $4
	call PlaceString
	ret


;joenote - for enhanced GBC colors option
ToggleEnhancedGBCColors:
	ld a, [hGBC]
	and a
	ret z	;do nothing if on dmg or sgb
	ld a, [wUnusedD721]
	xor ENH_GBC_COLORS
	ld [wUnusedD721], a
	call RunDefaultPaletteCommand
	;fall through
ShowEnhancedGBCSetting:
	ld hl, OptionMenuOnOffText
	ld a, [hGBC]
	and a
	jr z, .off
	ld a, [wUnusedD721]
	bit BIT_ENH_GBC_COLORS, a
	jr nz, .print
.off
	inc hl
	inc hl
.print
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, $10, $7
	call PlaceString
	ret


;joenote - for deactivating intelligent trainer switching
ToggleNoSwitch:
	ld a, [wUnusedD721]
	xor BATTLE_NOSWITCH
	ld [wUnusedD721], a
	;fall through
ShowNoSwitchSetting:
	ld hl, OptionMenuNoSwitch
	ld a, [wUnusedD721]
	bit BIT_BATTLE_NOSWITCH, a
	jr nz, .print
	inc hl
	inc hl
.print
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, $E, $5
	call PlaceString
	ret
OptionMenuNoSwitch:
	dw OptionMenuNoSwitchON
	dw OptionMenuNoSwitchOFF
OptionMenuNoSwitchON:
	db "ORIG.@"
OptionMenuNoSwitchOFF:
	db "SMART@"

	
;joenote - for deactivating intelligent trainer switching
ToggleGammaShader:
	ld a, [hGBC]
	and a
	ret z	;do nothing if on dmg or sgb
	xor %00000011
	ld [hGBC], a
;GBCNote - RunDefaultPaletteCommand which messes up enhanced GBC colors
;set a flag for prevent this from happening
	ld hl, hFlagsFFFA
	set 5, [hl]
	call RunDefaultPaletteCommand
	ld hl, hFlagsFFFA
	res 5, [hl]
	;fall through
ShowGammaSetting:
	ld hl, OptionMenuOnOffText
	ld a, [hGBC]
	cp 2
	jr z, .print
	inc hl
	inc hl
.print
	ld e, [hl]
	inc hl
	ld d, [hl]
	coord hl, $10, $6
	call PlaceString
	ret

	
;joenote - show /toggle badge cap for level
; ToggleBadgeCap:
	; ld a, [wUnusedD721]
	; xor %00100000
	; ld [wUnusedD721], a
	; ;fall through
; ShowBadgeCap:
	; ld de, OptionMenu5Spaces
	; coord hl, $0E, $A
	; call PlaceString
	; ld de, OptionMenu5SpacesOFF
	; ld a, [wUnusedD721]	;check if obedience level cap is active
	; bit 5, a
	; jr z, .print
	; ld de, OptionMenuCapLevelText
; .print
	; push af
	; coord hl, $0E, $A
	; call PlaceString
	; pop af
	; ret z
	
; .printnum	
	; callba GetBadgeCap
	; ld a, d
	; ld [wNumSetBits], a
	; coord hl, $10, $A
	; ld de, wNumSetBits
	; lb bc, 1, 3
	; call PrintNumber
	; ret
; OptionMenuCapLevelText:
	; db "L:@"
; OptionMenu5SpacesOFF:
	; db "  OFF@"
; OptionMenu5Spaces:
	; db "     @"


; ;joenote - show /toggle badge cap for level
; ToggleNuzlocke:
	; ld a, [wUnusedD721]
	; xor %01000000
	; ld [wUnusedD721], a
	; bit 6, a
	; call nz, NuzlockeSettings
	; ;fall through
; ShowNuzlocke:
	; ld de, OptionMenuTextOFF
	; ld a, [wUnusedD721]	;check if nuzlocke is active
	; bit 6, a
	; jr z, .print
	; ld de, OptionMenuTextON
; .print
	; coord hl, $10, $B
	; call PlaceString
	; ret
; ;default to recommended settings when turned on
; NuzlockeSettings:
	; push hl
	; ld hl, wUnusedD721
	; res 3, [hl]	;make sure trainers use smart switching
; ;activate or deactivate level cap depending on state of trainer scaling
	; set 5, [hl]
	; CheckEvent EVENT_90C
	; jr z, .next
	; res 5, [hl]
; .next
	; call ShowBadgeCap
	; call ShowNoSwitchSetting
	; ;battle mode SET and HARD
	; ld hl, wOptions
	; set BIT_BATTLE_HARD, [hl]
	; set BIT_BATTLE_SHIFT, [hl]
	; call ShowHardModeSetting
	; pop hl
	; ret


TextAudio:
	db " AUDIO@"
TextFPS:
	db " FPS@"
TextInstant:
	db " INST. TXT@"
TextHardMode:
	db " HARD MODE@"
TextAISwitch:
	db " AI SWAPS@"
TextGamma:
	db " Y SHADER@"
TextEnhancedGBC:
	db " ENH. COLOR@"
TextBack:
	db " BACK     SEL: OST@"

;TextAILevelCap:
;	db " LVL CAP@"
;TextNuzlocke:
;	db " NUZLOCKE@"
	
OptionMenuOnOffText:
	dw OptionMenuTextON
	dw OptionMenuTextOFF
OptionMenuTextON:
	db "ON @"
OptionMenuTextOFF:
	db "OFF@"
