Random_::
; Generate a random 16-bit value.
;	ld a, [rDIV]
;	ld b, a
;	ld a, [hRandomAdd]
;	adc b
;	ld [hRandomAdd], a
;	ld a, [rDIV]
;	ld b, a
;	ld a, [hRandomSub]
;	sbc b
;	ld [hRandomSub], a
;	ret

;joenote - implementing Patrik Rak's Xor-Shift random number generator
;Found at https://gist.github.com/raxoft/2275716fea577b48f7f0
;Patrik Rak released this code into public domain.

; 8-bit Xor-Shift random number generator.
; Created by Patrik Rak in 2008 and revised in 2011/2012.
; See http://www.worldofspectrum.org/forums/showthread.php?t=23070

;Note about the hram locations and how they hold random values:
;hRandomAdd = x[n]
;hRandomLast = x[n-1]
;hRandomSub = x[n-2]
;hRandomLast+1 = x[n-3]
;This gives up to 4 random values to pick from so long as this function as been called at least 4 times.

	;load Seed[n] into bc
	ld hl, hRandomAdd + 1
	ld a, [hld]
	ld b, a
	ld a, [hl]
	ld c, a
	;load Seed[n-1] into de
	ld hl, hRandomLast + 1
	ld a, [hld]
	ld d, a
	ld a, [hli]
	ld e, a
	;Seed[n-1] = Seed[n] 
	ld a, b
	ld [hld], a
	ld a, c
	ld [hl], a
	
	ld  a,c         
    add a,a
    add a,a
    add a,a
    xor c
    ld  c,a
    ld  a,d         
    add a,a
    xor d
    ld  b,a
    rra             
    xor b
    xor c
    ld  b,e         
    ld  c,a    
	
	ld hl, hRandomAdd + 1
	ld a, b
	ld [hld], a
	ld a, c
	ld [hl], a
 	ret


RNG_Correction::
	ld hl, wRNGSeed
	ld d, 4
.seedloop
	ld a, [hli]
	ld b, a
	push bc
	dec d
	jr nz, .seedloop
	ld d, 4
	xor a
.seedloop2
	pop bc
	or b
	dec d
	jr nz, .seedloop2
	cp $01
	ret nz
	
	ld hl, wRNGSeed
	
	ld a, [rDIV]
	ld b, a
	ld a, [hl]
	adc b
	call z, .inc_a
	ld [hRandomAdd], a
	ld [hli], a
	
	ld a, [rDIV]
	ld b, a
	ld a, [hl]
	sbc b
	call z, .inc_a
	ld [hRandomSub], a
	ld [hli], a

	ld a, [rDIV]
	ld b, a
	ld a, [hRandomAdd]
	adc b
	call z, .inc_a
	ld [hRandomLast], a
	ld [hli], a

	ld a, [rDIV]
	ld b, a
	ld a, [hRandomSub]
	sbc b
	call z, .inc_a
	ld [hRandomLast+1], a
	ld [hli], a
	ret	
.inc_a
	inc a
	ret
	
	
	
	
	
	