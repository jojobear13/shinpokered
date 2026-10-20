; Gen 7+'s experience (Gen 9's too), for one party mon: b x Lf / 5 / s x
; ((2 Lf + 10) / (Lf + Lp + 10)) ^ 2.5 + 1. b is the enemy mon's base
; experience (BaseExpYields), Lf its level, Lp the party mon's ([wExpScratch]),
; s its share ([wExpScratch + 1]: 1 if it took part, 2 for the Exp. Share's
; half). The ratio, under 2, is worked in 2.13 fixed point, so the result can
; be a point or so below Gen 9's. -> H_QUOTIENT + 2 and + 3, at most 65535
EXP_FRACTION_BITS EQU 13

ScaledExp:
	ld a, [wEnemyMonSpecies]
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld de, BaseExpYields
	add hl, de
	ld a, [hli]
	ld c, a
	ld b, [hl] ; bc = b
	ld a, [wEnemyMonLevel]
	ld e, a
	ld d, 0
	call Mul16 ; b x Lf
	ld hl, wMulResult
	ld de, H_DIVIDEND
	ld bc, 4
	call CopyData
	ld a, [wExpScratch + 1]
	ld b, a
	ld a, 5
.share
	dec b
	jr z, .gotDivisor
	add 5
	jr .share
.gotDivisor
	ld [H_DIVISOR], a
	ld b, 4
	call Divide ; / 5 / s
	ld a, [H_QUOTIENT + 2]
	ld [wExpScratch + 2], a
	ld a, [H_QUOTIENT + 3]
	ld [wExpScratch + 3], a
; r = (2 Lf + 10) / (Lf + Lp + 10), in 2.13: (2 Lf + 10) x 8192 / (Lf + Lp + 10)
	ld a, [wEnemyMonLevel]
	add a
	add 10
	ld c, a
	ld b, 0
	ld de, 1 << EXP_FRACTION_BITS
	call Mul16
	ld hl, wMulResult
	ld de, H_DIVIDEND
	ld bc, 4
	call CopyData
	ld a, [wEnemyMonLevel]
	ld b, a
	ld a, [wExpScratch]
	add b
	add 10
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	ld a, [H_QUOTIENT + 2]
	ld b, a
	ld a, [H_QUOTIENT + 3]
	ld c, a ; bc = r
	push bc
	ld d, b
	ld e, c
	call Mul16
	call Fixed2_13 ; hl = r ^ 2
	pop bc
	push hl
	call ISqrt2_13 ; de = sqrt(r)
	pop bc
	call Mul16
	call Fixed2_13 ; hl = r ^ 2.5
	ld b, h
	ld c, l
	ld a, [wExpScratch + 2]
	ld d, a
	ld a, [wExpScratch + 3]
	ld e, a
	call Mul16 ; x b x Lf / 5 / s
	ld a, [wMulResult]
	and %11100000
	jr nz, .cap ; 2 ^ 16 or more after the shift
	call Fixed2_13
	inc hl ; + 1
	ld a, h
	or l
	jr z, .cap
	ld a, h
	ld [H_QUOTIENT + 2], a
	ld a, l
	ld [H_QUOTIENT + 3], a
	ret
.cap
	ld a, $FF
	ld [H_QUOTIENT + 2], a
	ld [H_QUOTIENT + 3], a
	ret

; hl = wMulResult >> 13: a product of two 2.13 numbers back in 2.13 (the
; caller makes sure it fits in 16 bits)
Fixed2_13:
	ld a, [wMulResult]
	ld b, a
	ld a, [wMulResult + 1]
	ld h, a
	ld a, [wMulResult + 2]
	ld l, a
	ld c, EXP_FRACTION_BITS - 8 ; the top three bytes are already >> 8
.shift
	srl b
	rr h
	rr l
	dec c
	jr nz, .shift
	ret

; bc x de -> wMulResult (32 bits, big-endian). Keeps bc
Mul16:
	xor a
	ld hl, wMulResult
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld a, 16
	ld [wMulCount], a
.loop
	ld hl, wMulResult + 3
	sla [hl]
	dec hl
	rl [hl]
	dec hl
	rl [hl]
	dec hl
	rl [hl]
	sla e
	rl d
	jr nc, .next
	ld hl, wMulResult + 3
	ld a, [hl]
	add c
	ld [hld], a
	ld a, [hl]
	adc b
	ld [hld], a
	ld a, [hl]
	adc 0
	ld [hld], a
	ld a, [hl]
	adc 0
	ld [hl], a
.next
	ld a, [wMulCount]
	dec a
	ld [wMulCount], a
	jr nz, .loop
	ret

; bc = a 2.13 number (under 2) -> de = its square root in 2.13: the largest s
; with s x s <= bc x 8192
ISqrt2_13:
; the target, bc << 13, in wExpScratch (its two working bytes are no longer
; needed: the caller saved them) and wSqrtTarget
	ld a, b
	srl a
	srl a
	srl a
	ld [wSqrtTarget], a
	ld a, b
	and %111
	swap a
	sla a ; the low 3 bits of b at the top
	ld d, a
	ld a, c
	srl a
	srl a
	srl a
	or d
	ld [wSqrtTarget + 1], a
	ld a, c
	and %111
	swap a
	sla a
	ld [wSqrtTarget + 2], a
	xor a
	ld [wSqrtTarget + 3], a
	ld de, 0
	ld hl, 1 << 13 ; the top bit to try: the root of 2.0 is 1.414, under 2 in 2.13
.loop
	push hl
	push de
	ld a, d
	or h
	ld d, a
	ld a, e
	or l
	ld e, a ; the candidate
	push de
	ld b, d
	ld c, e
	call Mul16 ; its square
	pop de
	pop hl ; the old s
	push hl
	ld b, 4
	ld hl, wMulResult
	push de
	ld de, wSqrtTarget
.compare
	ld a, [de]
	cp [hl]
	jr c, .tooBig ; the square is bigger
	jr nz, .fits
	inc hl
	inc de
	dec b
	jr nz, .compare
.fits
	pop de ; the candidate
	pop hl
	jr .gotBit
.tooBig
	pop de
	pop de ; the old s
.gotBit
	pop hl
	srl h
	rr l
	ld a, h
	or l
	jr nz, .loop
	ret

; de = a party mon's EVs: add the enemy mon's EV yield (EVYields), within
; the limits (AddEVs)
GiveEnemyEVs:
	push de
	ld a, [wEnemyMonSpecies]
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld bc, EVYields
	add hl, bc
	ld a, [hli]
	ld b, a
	ld c, [hl] ; two bits per stat from the top: HP, attack, defense, speed; then
	           ; special attack and special defense
	pop de
	xor a
.loop
	ld [wItemScratch], a ; the stat
	xor a
	sla c
	rl b
	rla
	sla c
	rl b
	rla ; its yield
	and a
	jr z, .next
	ld [wItemScratch + 1], a
	push bc
	push de
	callab AddEVs
	pop de
	pop bc
.next
	ld a, [wItemScratch]
	inc a
	cp NUM_STATS
	jr nz, .loop
	ret
