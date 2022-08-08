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

;get the RGB values out of color in de into a spots pointed to by hRGB
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
	ld [hRGB + 0]
	
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
