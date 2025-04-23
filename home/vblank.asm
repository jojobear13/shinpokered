VBlank::

	push af
	push bc
	push de
	push hl

	ld a, [H_LOADEDROMBANK]
	ld [wVBlankSavedROMBank], a
	
	;joenote - set the correct backed-up bank if vblank happened during a DelayFrame function
	ld a, [wDelayFrameBank]
	and a
	jr z, .no_delay_bank
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a
.no_delay_bank

	ld a, [hSCX]
	ld [rSCX], a
	ld a, [hSCY]
	ld [rSCY], a

	ld a, [wDisableVBlankWYUpdate]
	and a
	jr nz, .ok
	ld a, [hWY]
	ld [rWY], a
.ok

	ld a, [hFlagsFFFA]	;see if BGMap skip has been enabled (such as when updating color )
	bit 1, a
	jr nz, .skipBGMap
	call AutoBgMapTransfer
	call VBlankCopyBgMap
	call RedrawRowOrColumn
	call VBlankCopy
	call VBlankCopyDouble
	call UpdateMovingBgTiles
.skipBGMap

	ld a, [hFlagsFFFA]	;see if OAM skip has been enabled (such as while overworld sprites are updating)
	bit 0, a
	jr nz, .skipOAM
	call $ff80 ; hOAMDMA where DMARoutine: is copied
;joenote - doing this in DelayFrame instead
;	ld a, BANK(PrepareOAMData)
;	ld [H_LOADEDROMBANK], a
;	ld [MBC1RomBank], a
;	call PrepareOAMData
.skipOAM
	; VBlank-sensitive operations end.

	call Random

	ld a, [H_VBLANKOCCURRED]
	and a
	jr z, .skipZeroing
	xor a
	ld [H_VBLANKOCCURRED], a

.skipZeroing
	ld a, [H_FRAMECOUNTER]
	and a
	jr z, .skipDec
	dec a
	ld [H_FRAMECOUNTER], a

.skipDec
	call FadeOutAudio

	callbs Music_DoLowHealthAlarm
	callbs Audio1_UpdateMusic

	callba TrackPlayTime ; keep track of time played

	ld a, [hDisableJoypadPolling]
	and a
	call z, ReadJoypad

;GBCnote - for enhanced GBC colors, do the bg map attributes for new rows/columns if required
	ld a, [hVblankBackup]
	and %11
	jr z, .skip_GBCEnhancedRedrawRowOrColumn
	callba GBCEnhancedRedrawRowOrColumn
.skip_GBCEnhancedRedrawRowOrColumn

	ld a, [wVBlankSavedROMBank]
	ld [H_LOADEDROMBANK], a
	ld [MBC1RomBank], a

	pop hl
	pop de
	pop bc
	pop af
	reti


DelayFrame::
; Wait for the next vblank interrupt.
; As a bonus, this saves battery.

NOT_VBLANKED EQU 1

	ld a, NOT_VBLANKED
	ld [H_VBLANKOCCURRED], a

;joenote - If you want to run functions in DelayFrame, then there is a need to back up the loaded bank.
; This is because it's originally assumed that you don't switch banks in DelayFrame.
	ld a, [H_LOADEDROMBANK]
	ld [wDelayFrameBank], a
	
	call home_PrepareOAMData
	
	xor a
	ld [wDelayFrameBank], a
	
	ld a, [rLCDC]
	bit 7, a
	jr z, .lcd_off
.halt
	halt
	nop	;joenote - due to a processor bug, nop after halt is best practice
	ld a, [H_VBLANKOCCURRED]
	and a
	jr nz, .halt
	ret
.lcd_off	;You will never enter the vblank interrupt if the LCD is disabled, so call it manually
	call VBlank
	ret

home_PrepareOAMData::
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - Try to optimize PrepareOAMData so that overworld sprites don't wobble.
;Inspired by Drenn's work on the pokered-gbc project.

;First preserve the registers.
	push bc
	push de
	push hl
;I've labeled a free byte and utilized one of its bits as a flag for skipping OAM stuff.
	ld hl, hFlagsFFFA
;See if OAM skip has been enabled.
	bit 0, [hl]
	jr nz, .skipOAM
;If disabled, then enable it for now.
;This is so DMA transfer is skipped in case vblank triggers while PrepareOAMData is running.
	set 0, [hl]
;Now prepare the OAM data. 
	farcall PrepareOAMData
;Re-disable the OAM skip flag.
	ld hl, hFlagsFFFA
	res 0, [hl]
;Finally, pop the registers.
.skipOAM
	pop hl
	pop de
	pop bc
;Notes: 
; - A good place to test this is the row of four trainers on route 8.
; - There may be a rare 1-frame flicker due to instances where DMA transfer gets skipped for 1 frame.
; --> But trying to do DMA transfer here is worse because audio noise gets injected when drawing the screen.
; --> A real gameboy's TFT screen might be able to hide this.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ret
