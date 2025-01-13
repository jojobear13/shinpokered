DisplaySoundTestMenu:
	call ClearScreen
	
;place the static strings for the screen
	coord hl, 5, 1
	ld de, TextInstructions3
	call PlaceString
	coord hl, 1, 14
	ld de, TextInstructions2
	call PlaceString
	coord hl, 1, 16
	ld de, TextInstructions1
	call PlaceString
	
.loop
;draw text box for the audio track
	coord hl, 0, 6
	ld b, 1
	ld c, 18
	call TextBoxBorder

	call Delay3

.getJoypadStateLoop
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	bit BIT_B_BUTTON, b ; B button pressed?
	jr nz, .exitMenu
	bit BIT_SELECT, b
	jr nz, .exitMenu
	bit BIT_A_BUTTON, b ; A button pressed?
	jr nz, .play_selection
.checkDirectionKeys
	bit BIT_D_LEFT, b ; Left pressed?
	jr nz, .dec_track
	bit BIT_D_RIGHT, b ; Right pressed?
	jr nz, .inc_track
	jr .getJoypadStateLoop
.exitMenu
	call ClearScreen
	ret
.inc_track
	jr .loop
.dec_track
	jr .loop
.play_selection
	jr .getJoypadStateLoop

TextInstructions1:
	db "A: Play   B: Exit@"
TextInstructions2:
	db "L/R: Change Track@"
TextInstructions3:
	db "SOUND TEST@"

