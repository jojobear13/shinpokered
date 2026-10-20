_Multiply:
	ld a, $8
	ld b, a
	xor a
	ld [H_PRODUCT], a
	ld [H_MULTIPLYBUFFER], a
	ld [H_MULTIPLYBUFFER+1], a
	ld [H_MULTIPLYBUFFER+2], a
	ld [H_MULTIPLYBUFFER+3], a
.loop
	ld a, [H_MULTIPLIER]
	srl a
	ld [H_MULTIPLIER], a ; (aliases: H_DIVISOR, H_MULTIPLIER, H_POWEROFTEN)
	jr nc, .smallMultiplier
	ld a, [H_MULTIPLYBUFFER+3]
	ld c, a
	ld a, [H_MULTIPLICAND+2]
	add c
	ld [H_MULTIPLYBUFFER+3], a
	ld a, [H_MULTIPLYBUFFER+2]
	ld c, a
	ld a, [H_MULTIPLICAND+1]
	adc c
	ld [H_MULTIPLYBUFFER+2], a
	ld a, [H_MULTIPLYBUFFER+1]
	ld c, a
	ld a, [H_MULTIPLICAND] ; (aliases: H_MULTIPLICAND)
	adc c
	ld [H_MULTIPLYBUFFER+1], a
	ld a, [H_MULTIPLYBUFFER]
	ld c, a
	ld a, [H_PRODUCT] ; (aliases: H_PRODUCT, H_PASTLEADINGZEROES, H_QUOTIENT)
	adc c
	ld [H_MULTIPLYBUFFER], a
.smallMultiplier
	dec b
	jr z, .done
	ld a, [H_MULTIPLICAND+2]
	sla a
	ld [H_MULTIPLICAND+2], a
	ld a, [H_MULTIPLICAND+1]
	rl a
	ld [H_MULTIPLICAND+1], a
	ld a, [H_MULTIPLICAND]
	rl a
	ld [H_MULTIPLICAND], a
	ld a, [H_PRODUCT]
	rl a
	ld [H_PRODUCT], a
	jr .loop
.done
	ld a, [H_MULTIPLYBUFFER+3]
	ld [H_PRODUCT+3], a
	ld a, [H_MULTIPLYBUFFER+2]
	ld [H_PRODUCT+2], a
	ld a, [H_MULTIPLYBUFFER+1]
	ld [H_PRODUCT+1], a
	ld a, [H_MULTIPLYBUFFER]
	ld [H_PRODUCT], a
	ret

_Divide:
	ld a, [H_DIVISOR] ; (aliases: H_DIVISOR, H_MULTIPLIER, H_POWEROFTEN)	
	and a
	ret z	;joenote - return if this is a devide by zero
	xor a
	ld [H_DIVIDEBUFFER], a
	ld [H_DIVIDEBUFFER+1], a
	ld [H_DIVIDEBUFFER+2], a
	ld [H_DIVIDEBUFFER+3], a
	ld [H_DIVIDEBUFFER+4], a
	ld a, $9
	ld e, a
.asm_37db3
	ld a, [H_DIVIDEBUFFER]
	ld c, a
	ld a, [H_DIVIDEND+1] ; (aliases: H_MULTIPLICAND)
	sub c
	ld d, a
	ld a, [H_DIVISOR] ; (aliases: H_DIVISOR, H_MULTIPLIER, H_POWEROFTEN)
	ld c, a
	ld a, [H_DIVIDEND] ; (aliases: H_PRODUCT, H_PASTLEADINGZEROES, H_QUOTIENT)
	sbc c
	jr c, .asm_37dce
	ld [H_DIVIDEND], a ; (aliases: H_PRODUCT, H_PASTLEADINGZEROES, H_QUOTIENT)
	ld a, d
	ld [H_DIVIDEND+1], a ; (aliases: H_MULTIPLICAND)
	ld a, [H_DIVIDEBUFFER+4]
	inc a
	ld [H_DIVIDEBUFFER+4], a
	jr .asm_37db3
.asm_37dce
	ld a, b
	cp $1
	jr z, .asm_37e18
	ld a, [H_DIVIDEBUFFER+4]
	sla a
	ld [H_DIVIDEBUFFER+4], a
	ld a, [H_DIVIDEBUFFER+3]
	rl a
	ld [H_DIVIDEBUFFER+3], a
	ld a, [H_DIVIDEBUFFER+2]
	rl a
	ld [H_DIVIDEBUFFER+2], a
	ld a, [H_DIVIDEBUFFER+1]
	rl a
	ld [H_DIVIDEBUFFER+1], a
	dec e
	jr nz, .asm_37e04
	ld a, $8
	ld e, a
	ld a, [H_DIVIDEBUFFER]
	ld [H_DIVISOR], a ; (aliases: H_DIVISOR, H_MULTIPLIER, H_POWEROFTEN)
	xor a
	ld [H_DIVIDEBUFFER], a
	ld a, [H_DIVIDEND+1] ; (aliases: H_MULTIPLICAND)
	ld [H_DIVIDEND], a ; (aliases: H_PRODUCT, H_PASTLEADINGZEROES, H_QUOTIENT)
	ld a, [H_DIVIDEND+2]
	ld [H_DIVIDEND+1], a ; (aliases: H_MULTIPLICAND)
	ld a, [H_DIVIDEND+3]
	ld [H_DIVIDEND+2], a
.asm_37e04
	ld a, e
	cp $1
	jr nz, .asm_37e0a
	dec b
.asm_37e0a
	ld a, [H_DIVISOR] ; (aliases: H_DIVISOR, H_MULTIPLIER, H_POWEROFTEN)
	srl a
	ld [H_DIVISOR], a ; (aliases: H_DIVISOR, H_MULTIPLIER, H_POWEROFTEN)
	ld a, [H_DIVIDEBUFFER]
	rr a
	ld [H_DIVIDEBUFFER], a
	jr .asm_37db3
.asm_37e18
	ld a, [H_DIVIDEND+1] ; (aliases: H_MULTIPLICAND)
	ld [H_REMAINDER], a ; (aliases: H_DIVISOR, H_MULTIPLIER, H_POWEROFTEN)
	ld a, [H_DIVIDEBUFFER+4]
	ld [H_QUOTIENT+3], a
	ld a, [H_DIVIDEBUFFER+3]
	ld [H_QUOTIENT+2], a
	ld a, [H_DIVIDEBUFFER+2]
	ld [H_QUOTIENT+1], a ; (aliases: H_MULTIPLICAND)
	ld a, [H_DIVIDEBUFFER+1]
	ld [H_DIVIDEND], a ; (aliases: H_PRODUCT, H_PASTLEADINGZEROES, H_QUOTIENT)
	ret

	
; hl = a mon's IVs -> a and wCalcStatNature = its nature (HARDY ... QUIRKY): the
; four IV bytes as one number (without the flag bits), plus NATURE_OFFSET, mod
; 25. Preserves bc, de and hl. Other banks can callab it and read
; wCalcStatNature.
GetNatureFromIVs:
	push hl
	push bc
	ld bc, NUM_IVS << 8 ; b = bytes left, c = remainder so far
.loop
	ld a, c ; remainder * 256 = remainder * 6 (mod 25)
	add a
	add c
	add a
	ld c, a
	ld a, b
	cp 1
	ld a, [hli]
	jr nz, .gotByte
	and $FC ; not the flags
.gotByte
	call .mod25
	add c ; at most 6 * 24 + 24
	call .mod25
	ld c, a
	dec b
	jr nz, .loop
	add NATURE_OFFSET
	call .mod25
	ld [wCalcStatNature], a
	pop bc
	pop hl
	ret
.mod25
	cp NUM_NATURES
	ret c
	sub NUM_NATURES
	jr .mod25

; scale stat c, in H_MULTIPLICAND+1 and +2, by the nature in wCalcStatNature:
; x 1.1 if the nature raises it, x 0.9 if it lowers it (rounded down, as from
; Gen 3). HP and neutral natures are left alone.
ApplyNature:
	ld a, c
	cp STAT_ATTACK
	ret c ; HP
	ld a, [wCalcStatNature]
	ld b, STAT_ATTACK
.divideBy5
	cp 5
	jr c, .gotStats
	sub 5
	inc b
	jr .divideBy5
.gotStats
	add STAT_ATTACK ; a = the lowered stat, b = the raised one
	cp b
	ret z ; neutral
	ld d, 90
	cp c
	jr z, .scale
	ld a, b
	cp c
	ret nz
	ld d, 110
.scale
	xor a
	ld [H_MULTIPLICAND], a
	ld a, d
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, 100
	ld [H_DIVISOR], a
	ld b, 4
	jp Divide ; the result is back in H_MULTIPLICAND+1 and +2

; Gen 3+'s formula: (2 x base + IV + EV / 4) x level / 100 + 5 (HP: + level +
; 10), then the nature. hl = the mon's EVs, with its IVs after them, or (b = 0,
; no EVs) its IVs - NUM_STATS
_CalcStat:
	call GetPredefRegisters
	push hl
	push de
	push bc
	push hl
	ld hl, wMonHeader
	ld a, b
	ld b, 0
	add hl, bc
	ld e, [hl] ; base stat
	pop hl
	ld b, 0
	and a
	jr z, .gotEV
	push hl
	ld a, c
	dec a
	add l
	ld l, a
	jr nc, .noCarryEV
	inc h
.noCarryEV
	ld a, [hl]
	pop hl
	srl a
	srl a
	ld b, a ; b = EV / 4
.gotEV
	push bc
	ld bc, NUM_STATS
	add hl, bc ; the IVs
	pop bc
	call GetNatureFromIVs
	call GetIV
	ld d, 0
	sla e
	rl d ; de = base x 2
	add e
	ld e, a
	jr nc, .noCarryIV
	inc d ; + IV
.noCarryIV
	ld a, b
	add e
	ld e, a
	jr nc, .noCarry2
	inc d ; + EV / 4
.noCarry2
	ld a, e
	ld [H_MULTIPLICAND+2], a
	ld a, d
	ld [H_MULTIPLICAND+1], a
	xor a
	ld [H_MULTIPLICAND], a
	ld a, [wCurEnemyLVL]
	ld [H_MULTIPLIER], a
	call Multiply            ; (2 x Base + IV + EV / 4) x Level
	ld a, [H_MULTIPLICAND]
	ld [H_DIVIDEND], a
	ld a, [H_MULTIPLICAND+1]
	ld [H_DIVIDEND+1], a
	ld a, [H_MULTIPLICAND+2]
	ld [H_DIVIDEND+2], a
	ld a, $64
	ld [H_DIVISOR], a
	ld a, $3
	ld b, a
	call Divide             ; (2 x Base + IV + EV / 4) x Level / 100
	ld a, c
	cp $1
	ld a, 5 ; + 5 for non-HP stat
	jr nz, .notHPStat
	ld a, [wCurEnemyLVL]
	ld b, a
	ld a, [H_MULTIPLICAND+2]
	add b
	ld [H_MULTIPLICAND+2], a
	jr nc, .noCarry3
	ld a, [H_MULTIPLICAND+1]
	inc a
	ld [H_MULTIPLICAND+1], a ; HP: ... + Level
.noCarry3
	ld a, 10 ; +10 for HP stat
.notHPStat
	ld b, a
	ld a, [H_MULTIPLICAND+2]
	add b
	ld [H_MULTIPLICAND+2], a
	jr nc, .noCarry4
	ld a, [H_MULTIPLICAND+1]
	inc a                    ; non-HP: ... + 5
	ld [H_MULTIPLICAND+1], a ; HP: ... + Level + 10
.noCarry4
	call ApplyNature
	ld a, [H_MULTIPLICAND+1] ; check for overflow (>999)
	cp 999 / $100 + 1
	jr nc, .overflow
	cp 999 / $100
	jr c, .noOverflow
	ld a, [H_MULTIPLICAND+2]
	cp 999 % $100 + 1
	jr c, .noOverflow
.overflow
	ld a, 999 / $100               ; overflow: cap at 999
	ld [H_MULTIPLICAND+1], a
	ld a, 999 % $100
	ld [H_MULTIPLICAND+2], a
.noOverflow
	pop bc
	pop de
	pop hl
	ret
