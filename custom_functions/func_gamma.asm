;This function tries to apply gamma correction to a GBC palette color
;de holds pointer to the color
;returns value in de
;bits 0 and 1 of b give the pointed color's number within its palette
GBCGamma:
	call GetPredefRegisters
	
	;do not apply the gamma shader if hGBC is !=2
	ld a, [hGBC]
	cp 2
	ret nz
	
	push hl
	push bc
	
	call GetRGB	;store the RGB values at hRGB
	
	call .isBlack
	jr c, .return	;don't do gamma correction on a black color
	
	call MixColorMatrix
		
	call GammaConv

	call WriteRGB
	
.return
	pop bc
	pop hl
	ret
.isBlack	;Check if the current color is a type of black. Return carry if black.
	;check red value
	ld a, [hRGB + 0]
	cp 4	
	ret nc ;not a black if value > 3
	
	;check blue value
	ld a, [hRGB + 2]
	cp 4	
	ret nc ;not a black if value > 3

	;check green value
	ld a, [hRGB + 1]
	cp 4	
	ret

;get the RGB values out of color in de into a spot pointed to by hRGB
GetRGB:
;GetRed:	
	;red bits in e are %00011111
	ld a, e
	and %00011111	;mask to get just the color value
	ld [hRGB + 0], a
;GetGreen:
	;green bits in de are %00000011 11100000
	ld a, e
	and %11100000
	;a is now xxx00000
	swap a
	rrca
	ld b, a
	;b is now 00000xxx
	ld a, d
	and %00000011
	add a
	add a
	add a
	;a is now 000xx000
	or b
	;a is now 000xxxxx
	ld [hRGB + 1], a
;GetBlue:
	;blue bits in d are %01111100
	ld a, d
	rra
	rra
	and %00011111	;mask to get just the color value
	ld [hRGB + 2], a
	ret

;write a colors at hRGB into their proper bit placement in de
WriteRGB:
;writeRed:
	ld a, [hRGB + 0]
	ld b, a
	ld a, e
	and %11100000
	or b
	ld e, a
;writeGreen:
	ld a, [hRGB + 1]
	;					d		e
	;green bits are 00000011 11100000
	;bits in a are 00011111
	rrca
	rrca
	rrca
	ld b, a
	;bits in b are 11100011	
	;now load into d
	and %00000011
	ld c, a
	;bits in c are 00000011
	ld a, d
	and %11111100
	or c
	ld d, a
	;bits in b are still 11100011	
	;now load into e
	ld a, b
	and %11100000
	ld c, a
	;bits in c are 11100000
	ld a, e
	and %00011111
	or c
	ld e, a
;writeBlue:
	ld a, [hRGB + 2]	;blue bits are 00011111
	add a			;blue bits are 00111110
	add a			;blue bits are 01111100
	ld b, a
	ld a, d
	and %10000011
	or b
	ld d, a
	ret

;This is does gamma conversions of hRGB color values via lookup list.
GammaConv:
	ld hl, hRGB
	ld c, 3
	ld b, 0
.loop
	ld a, [hl]
	push hl
	ld hl, GammaList
	push bc
	ld c, a
	add hl, bc
	pop bc
	ld a, [hl]
	pop hl
	ld [hli], a
	dec c
	jr nz, .loop
	ret	
GammaList:	;gamma=2 conversion
	db 0	; color value 0
	db 6	; color value 1
	db 8	; color value 2
	db 10	; color value 3
	db 11	; color value 4
	db 12	; color value 5
	db 14	; color value 6
	db 15	; color value 7
	db 16	; color value 8
	db 17	; color value 9
	db 18	; color value 10
	db 18	; color value 11
	db 19	; color value 12
	db 20	; color value 13
	db 21	; color value 14
	db 22	; color value 15
	db 22	; color value 16
	db 23	; color value 17
	db 24	; color value 18
	db 24	; color value 19
	db 25	; color value 20
	db 26	; color value 21
	db 26	; color value 22
	db 27	; color value 23
	db 27	; color value 24
	db 28	; color value 25
	db 28	; color value 26
	db 29	; color value 27
	db 29	; color value 28
	db 30	; color value 29
	db 30	; color value 30
	db 31	; color value 31
	
;Applies the color-mixing matrix to colors at hRGB
;Doing as few calculations as possible to increase speed because a matrix multiply causes lag
MixColorMatrix:
;calculate red row and store it
	xor a
	ld b, a	; b remains 0 for the entirety of this function
	ld h, a
	; multiply red value by 13 and add to hl
	; uses shift and add
	ld a, [hRGB + 0]
	ld c, a		; bc = r * 1
	add a		;  a = r * 2
	add a		;  a = r * 4
	ld l, a		; hl = a * 4
	add c		;  a = r * 4 + r * 1 = r * 5
	ld c, a		; bc = r * 5
	add hl, hl	; hl = (r * 4) * 2 = r * 8
	add hl, bc	; hl = r * 8 + r * 5 = r * 13
	;multiply green value by 2, add to blue and hl
	ld a, [hRGB + 1]
	add a
	ld c, a
	;multiply blue value by 1 and add to hl
	ld a, [hRGB + 2]
	add c
	ld c, a
	add hl, bc
	;shift 4 bits to the right, discarding upper bits
	;actually does a nibble swap, mask, then bitwise or
	swap h
	swap l
	ld a, l
	and $0F
	ld l, a
	ld a, h
	and $F0
	or l
	;store now because red isn't used after this
	ld [hRGB + 0], a
	
;calculate green row and store it
;this only needs 8-bit math: 31 * 3 + 31 * 1 == 124 < 255
	;multiply red value by 0 and add to c
	;no actions for this
	;multiply green value by 3 and add to c
	ld a, [hRGB + 1]
	ld c, a
	add a
	add c
	ld c, a
	;multiply blue value by 1 and add to c
	ld a, [hRGB + 2]
	add c
	;shift 2 bits to the right
	srl a
	srl a
	;save for later
	push af
	
;calculate blue row and store it
;while the formula is (r * 0 + g * 2 + b * 14) / 16, this instead does (r * 0 + g * 1 + b * 7) / 8
;which will not require a 16-bit register and will have the same result
	;while the math is for 8 bit 
	;multiply blue value by 7 and add to c
	ld a, [hRGB + 2]
	ld c, a	; c = b * 1
	add a	; a = b * 2
	add a	; a = b * 4
	add a	; a = b * 8
	sub c	; a = (b * 8) - (b * 1) = b * 7
	ld c, a
	;multiply red value by 0 and add to c
	;no actions for this
	;multiply green value by 1 and add to c
	ld a, [hRGB + 1]
	add c
	;shift 3 bits to the right
	rrca
	rrca
	rrca
	and $1F
;now store the color-mixed values
	ld [hRGB + 2], a	; blue
	pop af
	ld [hRGB + 1], a	; green
	; red was stored earlier
	ret

;This sets the GBC palette index for read/writes directly from the hardware
;Uses A, HL, and B
;Accepts settings which determine the color to work with using the value in wGBCColorControl	
	;bits 0 & 1 --> a value from 0 to 3 to select color 0 through 3
	;bits 2, 3, & 4 --> a value from 0 to 7 to select BGP/OBP 0 through 7
	;bit 5 --> 0 = BGP | 1 = OBP
	;bits 6 & 7 are unused
;When it returns with the z flag cleared, HL points to the BGP or OBP data address and B holds the final color offset
;Returns with the z flag set if not successful
SetGBCPalIndex:	
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	ret z
	
	ld a, [wGBCColorControl]	;copy the settings into A

	ld hl, rBGPI	;point HL to the BGP index-setting address $ff68
	bit 5, a	;check to see if BGP or OBP is desired
	jr z, .next
	ld hl, rOBPI	;point HL to the BGP index-setting address $ff6a
.next

	and %00011100	;mask the bits to leave A with just the index value
	;rotate A two bits to the right so we can do math on it properly
	rrca	
	rrca
	;each index step has four colors of two bytes each, so we need to multiply A by 8 to get the correct index offset
	add a
	add a
	add a
	ld b, a	;store the index into B for now
	
	ld a, [wGBCColorControl]	;copy the settings into A
	and %00000011	;mask the bits to leave A with just the color number offset
	add a	;each color is two bytes, so double the value to get the correct offset
	
	add b	;add the index offset in B to the color number offset
	ld b, a		;save the final offset in B for later functions
; Now load in order to point at the correct overall offset (for example, color 2 of BGP 3)
	ld [hli], a		;we do a ld [hli] so that HL increments to the proper data address afterwards
	;HL now points to either rBGPD or rOBPD
	
	;return with z flag cleared to signal success
	ld a, 1
	and a
	ret
	

	
;Based on the settings used for SetGBCPalIndex, this function will write the desired color from DE
;Like VRAM, the color data of the GBC can only be read/written during VBLANK, HBLANK, or OAM Scan
WriteColorGBC:
	call SetGBCPalIndex	;set the color index to read
	ret z	;return if there was a problem
	;HL should now point to either rBGPD or rOBPD
	;The final offset should be in B
	
	push de	;save the value in DE
	
	call .write		;write the color's low byte to the data address then decrement back to the indexing address
	
	inc b			;increment the offset so that we can write the color's high byte
	ld a, b
	ld [hli], a		;update the indexing address with the high byte's offset and increment to the data address
	
	ld e, d			
	call .write		;write the color's high byte to the data address then decrement back to the indexing address
	
	pop de	;get the saved DE value back for preservation's sake
	
	ret

.write
	ldh a, [rIE]
	rrca	;see if vblank interrupt is already disabled (bit 0 of rIE)
	jr c, .write_DI		;if enabled right now, jump to disable it while doing the read
.waitVRAM
	ldh a, [rSTAT]		
	and %10		; mask for non-V-blank/non-H-blank STAT mode
	jr nz, .waitVRAM
	;we are now in a viable mode
	ld a, e
	ld [hld], a		
	ret
	
.write_DI
	di	;disable interrupts so that the VBLANK functions don't mess up the timing
	;wait for mode 0 or 1 (HBLANK or VBLANK)
.waitVRAM2
	ldh a, [rSTAT]		
	and %10		; mask for non-V-blank/non-H-blank STAT mode
	jr nz, .waitVRAM2
	;we are now in a viable mode
	ld a, e
	ld [hld], a		
	ei	;re-enable interrupts
	ret
	
	
	
;Read a specific color from the buffer into DE, similar to ReadColorGBC
ReadBufferColorGBC:
	ld de, $0000
	ld a, [wGBCColorControl]
	add a	;double A since each color is 2 bytes
	ld e, a
	ld hl, wGBCFullPalBuffer
	add hl, de
	ld a, [hli]		;read high byte
	ld d, a
	ld a, [hl]		;read low byte
	ld e, a
	ret
	

	
;This function does a few decrements to all the colors of the GBC in BGP 0-3 and OBP 0-7.
;It's used for fading to black or other things that need darkening.
;Returns the z-flag state: set = invalid | cleared = successful
;Reads all the relevant colors from wGBCFullPalBuffer, then decrements them C times, and writes to hardware.
DecrementAllColorsGBC:	
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	ret z

	ld a, [rIE]		;manually disable interrupts and wait until the first scanline of vblank is reached
	push af
	xor a
	ld [rIE], a
.wait
	ldh a, [rLY]		
	cp $90
	jr nz, .wait
	
	xor a	;load zero to start with the very first color of BGP 0 so we can loop through everything
.mainLoop
	ld [wGBCColorControl], a
	and %00100011
	cp 32
	jr z, .skipTransparent	;color 0 of OBP 0 to 7 are always transparent, so skip these ones

	push bc	;save the value in C, which is the number of times to iterate

	call ReadBufferColorGBC	;get the color into DE
	
	ld a, [wGBCColorControl]
	and a
	jr z, .backup_color
	ldh a, [hSwapTemp]
	cp d
	jr nz, .backup_color
	ldh a, [hSwapTemp+1]
	cp e
	jr nz, .backup_color
	ldh a, [hSwapTemp+2]
	ld d, a
	ldh a, [hSwapTemp+3]
	ld e, a
	jr .write_color
	
.backup_color
	ld a, d
	ldh [hSwapTemp], a
	ld a, e
	ldh [hSwapTemp+1], a

	call GetRGB			;Split color in DE to RGB values in hRGB
	
	ld hl, hRGB
	pop bc	;get the number of times to iterate
	push bc	;then save it again
	call .decrement		;reduce red
	ld [hli], a
	pop bc	;get the number of times to iterate
	push bc	;then save it again
	call .decrement		;reduce green
	ld [hli], a
	pop bc	;get the number of times to iterate
	push bc	;then save it again
	call .decrement		;reduce blue
	ld [hl], a
	
	call WriteRGB		;combine RGB values back into DE
	
	ld a, d
	ldh [hSwapTemp+2], a
	ld a, e
	ldh [hSwapTemp+3], a

.write_color
	call WriteColorGBC	;write the color in DE back to the hardware address
	
	pop bc	;get the number of times to iterate

.skipTransparent
	ld a, [wGBCColorControl]
	inc a
	cp 64
	jr nc, .return	;return if finished with OBP 7
	cp 16
	jr z, .unusedBGP	;increment past unused color locations and loop if at BGP 4
	call GBCBackgroundBlock
	jr .next

.unusedBGP
	add a	;add 16 to the location so we skip to color 32 which is OBP 0
	inc a	; color 0 of OBP 0 to 7 are always transparent, so increment to color 33
.next
	ld [wGBCColorControl], a
	jr .mainLoop

.decrement
	ld a, [hl]	;get either R, G, or B value into A
;c = max number of times to decrement per function call
;b = [minimum number + 1] threshold to stop decrementing
;	ld c, 3
	ld b, 4
.loopC
	cp b
	ret c	;return if value is below threshold
	dec a	;if not, decrement the value
	dec c	;and also decrement the counter
	ret z	;return if the counter hit zero
	jr .loopC

.return
	pop af		;re-enable interrupts
	ld [rIE], a

;If not in 2x CPU mode, everything updates in less than 144 scanlines
;Therefore, normal mode needs an audio update but 60 fps mode does not
	ld a, [rKEY1]
	bit 7, a
	push af
	call nz, DelayFrame	;Delay a frame in 60 fps mode to get the timing down right for any fades
	pop af
	jr nz, .return_next
	callba Audio1_UpdateMusic
	
.return_next
	ld a, 1
	and a
	ret

;optimize updating the colors for the battle background layer
GBCBackgroundBlock:
	push bc
	ld b, a
	ld a, [wIsInBattle]
	and a
	ld a, b
	pop bc
	ret z

	cp 1
	jr z, .add3
	cp 5
	jr z, .add3
	cp 9
	jr z, .add3

	cp 13
	jr z, .sub12
	cp 4
	jr z, .add1
	cp 8
	jr z, .add1
	cp 12
	jr z, .add1
	
	jr .return	
.sub12
	sub 12
	jr .return
.add3
	add 2
.add1
	inc a
.return
	ret

	
	
;This function does a few increments to all the colors of the GBC in BGP 0-3 and OBP 0-7.
;It's used for fading to white or other things that need lightening.
;Returns the z-flag state: set = invalid | cleared = successful
;Uses the value in C to increment that number of times
IncrementAllColorsGBC:	
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	ret z

	ld a, [rIE]		;manually disable interrupts and wait until the first scanline of vblank is reached
	push af
	xor a
	ld [rIE], a

.wait
	ldh a, [rLY]		
	cp $90
	jr nz, .wait
	
	xor a	;load zero to start with the very first color of BGP 0 so we can loop through everything
.mainLoop
	ld [wGBCColorControl], a
	and %00100011
	cp 32
	jr z, .skipTransparent	;color 0 of OBP 0 to 7 are always transparent, so skip these ones

	push bc	;save the value in C, which is the number of times to iterate
	
	call ReadBufferColorGBC	;get the color into DE
	
	ld a, [wGBCColorControl]
	and a
	jr z, .backup_color
	ldh a, [hSwapTemp]
	cp d
	jr nz, .backup_color
	ldh a, [hSwapTemp+1]
	cp e
	jr nz, .backup_color
	ldh a, [hSwapTemp+2]
	ld d, a
	ldh a, [hSwapTemp+3]
	ld e, a
	jr .write_color
	
.backup_color
	ld a, d
	ldh [hSwapTemp], a
	ld a, e
	ldh [hSwapTemp+1], a

	call GetRGB			;Split color in DE to RGB values in hRGB
	
	ld hl, hRGB
	pop bc	;get the number of times to iterate
	push bc	;then save it again
	call .increment		;increase red
	ld [hli], a
	pop bc	;get the number of times to iterate
	push bc	;then save it again
	call .increment		;increase green
	ld [hli], a
	pop bc	;get the number of times to iterate
	push bc	;then save it again
	call .increment		;increase blue
	ld [hl], a
	
	call WriteRGB		;combine RGB values back into DE
	
	ld a, d
	ldh [hSwapTemp+2], a
	ld a, e
	ldh [hSwapTemp+3], a

.write_color
	call WriteColorGBC	;write the color in DE back to the hardware address
	
	pop bc	;get the number of times to iterate
	
.skipTransparent
	ld a, [wGBCColorControl]
	inc a
	cp 64
	jr nc, .return	;return if finished with OBP 7
	cp 16
	jr z, .unusedBGP	;increment past unused color locations and loop if at BGP 4
	call GBCBackgroundBlock
	jr .next

.unusedBGP
	add a	;add 16 to the location so we skip to color 32 which is OBP 0
	inc a	; color 0 of OBP 0 to 7 are always transparent, so increment to color 33
.next
	ld [wGBCColorControl], a
	jr .mainLoop

.increment
	ld a, [hl]	;get either R, G, or B value into A
;c = max number of times to increment per function call
;b = [maximum number] threshold to stop decrementing
;	ld c, 3
	ld b, 31
.loopC
	cp b
	ret nc	;return if value is at or above threshold
	inc a	;if not, increment the value
	dec c	;and also decrement the counter
	ret z	;return if the counter hit zero
	jr .loopC

.return
	pop af		;re-enable interrupts
	ld [rIE], a

;If not in 2x CPU mode, everything updates in less than 144 scanlines
;Therefore, normal mode needs an audio update but 60 fps mode does not
	ld a, [rKEY1]
	bit 7, a
	push af
	call nz, DelayFrame	;Delay a frame in 60 fps mode to get the timing down right for any fades
	pop af
	jr nz, .return_next
	callba Audio1_UpdateMusic
	
.return_next
	ld a, 1
	and a
	ret
	
	

;Functions for smooth fades utilizing the GBC's palette hardware
;Returns the z-flag state: set = success | cleared = invalid
GBCFadeOutToBlack:
	call DelayFrame	;delay 1 frame to allow the player sprite to finish turning around when exiting a building
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	jr z, .notGBC
	
	;personal preference - only do smooth fade in 60fps mode
	ld a, [wUnusedD721]
	bit 4, a
	jr z, .notGBC

;	if 60fps option enabled but in 1x cpu mode, then enable 2x cpu mode just for this fade
	ld a, [rKEY1]
	bit 7, a
	ld a, $ff
	jr nz, .doublespeed	
	predef SetCPUSpeed
	xor a
.doublespeed
	push af
	
	push de
	ld de, FadePal4
	call BufferAllPokeyellowColorsGBC_helper		;back up all colors to a buffer space in wram
	
	ld a, [hFlagsFFFA]	;need to set a flag that skips the $FF80 OAM call in VBLANK
	push af
	set 0, a
	ld [hFlagsFFFA], a

	ld c, 3
.loop
	push bc
	call DecrementAllColorsGBC	;read buffered colors, decrement them C times, and write them to hardware
	pop bc
;	ld d, c
;	callba DecrementAllColorsGBC_improved
;	ld c, d

	ld a, c
	add 3	;step size of C
	ld c, a
	cp 32
	jr c, .loop

	pop af
	ld [hFlagsFFFA], a
	
	pop de

	pop af
	inc a
	ret z	;return now if 2x cpu mode was already active at the start of this function
	;otherwise return to single cpu mode and return
	predef SingleCPUSpeed
	xor a
	ret
	
.notGBC
	ld a, 1
	and a
	ret


	
;Functions for smooth fades utilizing the GBC's palette hardware
;Returns the z-flag state: set = success | cleared = invalid
GBCFadeOutToWhite:
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	jr z, .notGBC
	
	;personal preference - only do smooth fade in 60fps mode
	ld a, [wUnusedD721]
	bit 4, a
	jr z, .notGBC

;	if 60fps option enabled but in 1x cpu mode, then enable 2x cpu mode just for this fade
	ld a, [rKEY1]
	bit 7, a
	ld a, $ff
	jr nz, .doublespeed	
	predef SetCPUSpeed
	xor a
.doublespeed
	push af
	
	push de
	ld de, FadePal4
	call BufferAllPokeyellowColorsGBC_helper		;back up all colors to a buffer space in wram
	
	ld a, [hFlagsFFFA]	;need to set a flag that skips the $FF80 OAM call in VBLANK
	push af
	set 0, a
	ld [hFlagsFFFA], a

	ld c, 3
.loop
	push bc
	call IncrementAllColorsGBC	;read buffered colors, increment them C times, and write them to hardware
	pop bc
	ld a, c
	add 3	;step size of C
	ld c, a
	cp 32
	jr c, .loop

	pop af
	ld [hFlagsFFFA], a

	pop de

	pop af
	inc a
	ret z	;return now if 2x cpu mode was already active at the start of this function
	;otherwise return to single cpu mode and return
	predef SingleCPUSpeed
	xor a
	ret
	
.notGBC
	ld a, 1
	and a
	ret
	
	
	
GBCFadeInFromWhite:
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	jr z, .notGBC
	
	;personal preference - only do smooth fade in 60fps mode
	ld a, [wUnusedD721]
	bit 4, a
	jr z, .notGBC

;	if 60fps option enabled but in 1x cpu mode, then enable 2x cpu mode just for this fade
	ld a, [rKEY1]
	bit 7, a
	ld a, $ff
	jr nz, .doublespeed	
	predef SetCPUSpeed
	xor a
.doublespeed
	push af
	
	push de
	ld de, FadePal4
	call BufferAllPokeyellowColorsGBC_helper		;back up all colors to a buffer space in wram
	
	ld a, [hFlagsFFFA]	;need to set a flag that skips the $FF80 OAM call in VBLANK
	push af
	set 0, a
	ld [hFlagsFFFA], a

	ld c, 28
.loop
	push bc
	call IncrementAllColorsGBC	;read buffered colors, increment them C times, and write them to hardware
	pop bc
	ld a, c
	sub 3	;step size of C
	ld c, a
	jr nc, .loop

	pop af
	ld [hFlagsFFFA], a

	pop de

	pop af
	inc a
	ret z	;return now if 2x cpu mode was already active at the start of this function
	;otherwise return to single cpu mode and return
	predef SingleCPUSpeed
	xor a
	ret
	
.notGBC
	ld a, 1
	and a
	ret
	
	
	
GBCFadeInFromBlack:
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	jr z, .notGBC
	
	;personal preference - only do smooth fade in 60fps mode
	ld a, [wUnusedD721]
	bit 4, a
	jr z, .notGBC

;	if 60fps option enabled but in 1x cpu mode, then enable 2x cpu mode just for this fade
	ld a, [rKEY1]
	bit 7, a
	ld a, $ff
	jr nz, .doublespeed	
	predef SetCPUSpeed
	xor a
.doublespeed
	push af
	
	push de
	ld de, FadePal4
	call BufferAllPokeyellowColorsGBC_helper		;back up all colors to a buffer space in wram
	
	ld a, [hFlagsFFFA]	;need to set a flag that skips the $FF80 OAM call in VBLANK
	push af
	set 0, a
	ld [hFlagsFFFA], a

	ld c, 28
.loop
	push bc
	call DecrementAllColorsGBC	;read buffered colors, increment them C times, and write them to hardware
	pop bc
	ld a, c
	sub 3	;step size of C
	ld c, a
	jr nc, .loop

	pop af
	ld [hFlagsFFFA], a

	pop de

	pop af
	inc a
	ret z	;return now if 2x cpu mode was already active at the start of this function
	;otherwise return to single cpu mode and return
	predef SingleCPUSpeed
	xor a
	ret
	
.notGBC
	ld a, 1
	and a
	ret
	

	
BufferAllPokeyellowColorsGBC_helper:
	ld a, [wUnusedD721]
	bit 7, a
	jr z, .doNormal
	ld a, [hFlagsFFFA]
	bit 4, a
	jr z, .doNormal
	callba BufferAllEnhancedColorsGBC
	ret
.doNormal
	callba BufferAllPokeyellowColorsGBC
	ret
	
	
