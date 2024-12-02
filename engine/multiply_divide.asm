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

	
_CalcStat:
	call GetPredefRegisters
	push hl
	push de
	push bc
	ld a, b
	ld d, a
	push hl
	ld hl, wMonHeader
	ld b, $0
	add hl, bc
	ld a, [hl]          ; read base value of stat
	ld e, a
	pop hl
	push hl
	sla c
	ld a, d
	and a
	jr z, .statExpDone  ; consider stat exp?
	add hl, bc          ; skip to corresponding stat exp value
.statExpLoop            ; calculates ceil(Sqrt(stat exp)) in b
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND+1], a
	inc b               ; increment current stat exp bonus
	ld a, b
	cp $ff
	jr z, .statExpDone
	ld [H_MULTIPLICAND+2], a
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, [hld]
	ld d, a
	ld a, [$ff98]
	sub d
	ld a, [hli]
	ld d, a
	ld a, [$ff97]
	sbc d               ; test if (current stat exp bonus)^2 < stat exp
	jr c, .statExpLoop
.statExpDone
	srl c
	pop hl
	push bc
	ld bc, wPartyMon1DVs - (wPartyMon1HPExp - 1) ; also wEnemyMonDVs - wEnemyMonHP beause the structures are the same size
	add hl, bc
	pop bc
	ld a, c
	cp $2
	jr z, .getAttackIV
	cp $3
	jr z, .getDefenseIV
	cp $4
	jr z, .getSpeedIV
	cp $5
	jr z, .getSpecialIV
.getHpIV
	push bc
	ld a, [hl]  ; Atk IV
	swap a
	and $1
	sla a
	sla a
	sla a
	ld b, a
	ld a, [hli] ; Def IV
	and $1
	sla a
	sla a
	add b
	ld b, a
	ld a, [hl] ; Spd IV
	swap a
	and $1
	sla a
	add b
	ld b, a
	ld a, [hl] ; Spc IV
	and $1
	add b      ; HP IV: LSB of the other 4 IVs
	pop bc
	jr .calcStatFromIV
.getAttackIV
	ld a, [hl]
	swap a
	and $f
	jr .calcStatFromIV
.getDefenseIV
	ld a, [hl]
	and $f
	jr .calcStatFromIV
.getSpeedIV
	inc hl
	ld a, [hl]
	swap a
	and $f
	jr .calcStatFromIV
.getSpecialIV
	inc hl
	ld a, [hl]
	and $f
.calcStatFromIV
	ld d, $0
	add e
	ld e, a
	jr nc, .noCarry
	inc d                     ; de = Base + IV
.noCarry
	sla e
	rl d                      ; de = (Base + IV) * 2
	srl b
	srl b                     ; b = ceil(Sqrt(stat exp)) / 4
	ld a, b
	add e
	jr nc, .noCarry2
	inc d                     ; de = (Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4
.noCarry2
	ld [H_MULTIPLICAND+2], a
	ld a, d
	ld [H_MULTIPLICAND+1], a
	xor a
	ld [H_MULTIPLICAND], a
	ld a, [wCurEnemyLVL]
	ld [H_MULTIPLIER], a
	call Multiply            ; ((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level
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
	call Divide             ; (((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level) / 100
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
	ld [H_MULTIPLICAND+1], a ; HP: (((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level) / 100 + Level
.noCarry3
	ld a, 10 ; +10 for HP stat
.notHPStat
	ld b, a
	ld a, [H_MULTIPLICAND+2]
	add b
	ld [H_MULTIPLICAND+2], a
	jr nc, .noCarry4
	ld a, [H_MULTIPLICAND+1]
	inc a                    ; non-HP: (((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level) / 100 + 5
	ld [H_MULTIPLICAND+1], a ; HP: (((Base + IV) * 2 + ceil(Sqrt(stat exp)) / 4) * Level) / 100 + Level + 10
.noCarry4
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
