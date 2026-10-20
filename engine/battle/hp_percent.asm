; The DISPLAY option HP PERCENT: the enemy's HUD shows its HP as a percentage,
; as on Showdown, in place of the "HP:" label. The number is drawn in a small
; 3x5 font into two tiles ($D0 and $D1, blank in the English font: kana
; slots) that take the place of the label's two tiles; the second keeps the
; bar's left end.

HP_PERCENT_TILE EQU $D0

; after DrawEnemyHUDAndHPBar draws the bar at (2, 2)
DrawEnemyHPPercent:
	ld a, [wDisplayOptions]
	bit BIT_HP_PERCENT, a
	ret z
	push de ; the bar's pixels, for its color
	call EnemyHPPercent
	call DrawHPPercentTiles
	coord hl, 2, 2
	ld a, HP_PERCENT_TILE
	ld [hli], a
	inc a
	ld [hl], a
	pop de
	ret

; a = the enemy's HP as a percentage of its max HP: rounded down, but at least
; 1 while it has any
EnemyHPPercent:
	ld hl, wEnemyMonHP
	ld a, [hli]
	ld b, a
	ld c, [hl]
	or c
	ret z
	ld hl, wEnemyMonMaxHP
	ld a, [hli]
	ld d, a
	ld e, [hl]
.scale ; max HP to one byte for Divide, HP alike
	ld a, d
	and a
	jr z, .scaled
	srl d
	rr e
	srl b
	rr c
	jr .scale
.scaled
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND + 1], a
	ld a, c
	ld [H_MULTIPLICAND + 2], a
	ld a, 100
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, [H_PRODUCT + 2]
	ld [H_DIVIDEND], a
	ld a, [H_PRODUCT + 3]
	ld [H_DIVIDEND + 1], a
	ld a, e
	ld [H_DIVISOR], a
	ld b, 2
	call Divide
	ld a, [H_QUOTIENT + 3]
	cp 101
	jr c, .notOver
	ld a, 100
.notOver
	and a
	ret nz
	inc a ; it has HP left
	ret

; draws percentage a (0-100) into the two tiles at wHPPercentTiles, then VRAM
DrawHPPercentTiles:
; the digits: d = hundreds, e = tens, c = ones; 10 for a blank
	ld d, 10
	cp 100
	jr c, .tens
	ld d, 1
	sub 100
.tens
	ld e, -1
.divideBy10
	inc e
	sub 10
	jr nc, .divideBy10
	add 10
	ld c, a
	ld a, e
	and a
	jr nz, .gotDigits
	ld a, d
	cp 10
	jr nz, .gotDigits ; 100: keep the zero
	ld e, 10
.gotDigits
	ld hl, wHPPercentTiles
	ld b, 0 ; the row
.row
	push bc
	push de
; the first tile: the hundreds then the tens
	ld a, d
	call .glyphRow
	swap a
	add a ; to bits 5-7
	ld d, a
	ld a, e
	call .glyphRow
	add a ; to bits 1-3
	or d
	ld [hli], a
	ld [hli], a
; the second: the ones, the "%", and the bar's left end
	pop de
	pop bc
	push bc
	push de
	ld a, c
	call .glyphRow
	swap a
	add a
	ld d, a
	ld a, 11 ; "%"
	call .glyphRow
	add a
	or d
	ld d, a
	ld a, b
	cp 3
	jr z, .barEnd
	cp 4
	jr nz, .noBarEnd
.barEnd
	set 0, d
.noBarEnd
	ld a, d
	ld de, 2 * 8 - 2 ; to the same row of the second tile
	push hl
	add hl, de
	ld [hli], a
	ld [hl], a
	pop hl
	pop de
	pop bc
	inc b
	ld a, b
	cp 8
	jr nz, .row
; to VRAM: at once with the LCD off, else in V-blank
	ld a, [rLCDC]
	bit 7, a
	jr nz, .lcdOn
	ld hl, wHPPercentTiles
	ld de, vChars1 + (HP_PERCENT_TILE - $80) * $10
	ld bc, 2 * $10
	jp CopyData
.lcdOn
	ld de, wHPPercentTiles
	ld hl, vChars1 + (HP_PERCENT_TILE - $80) * $10
	lb bc, BANK(@), 2
	jp CopyVideoData

; a = row b (0-7) of glyph a's three columns (bits 0-2); rows 1-5 hold it
.glyphRow
	push hl
	push bc
	ld c, a
	ld a, b
	dec a
	cp 5
	jr nc, .emptyRow
	ld b, a
	ld a, c
	ld l, a
	add a
	add a
	add l ; glyph * 5
	add b
	ld c, a
	ld b, 0
	ld hl, PercentGlyphs
	add hl, bc
	ld a, [hl]
	pop bc
	pop hl
	ret
.emptyRow
	xor a
	pop bc
	pop hl
	ret

PercentGlyphs: ; 0-9, a blank, "%"; five rows of three columns each
	db %111, %101, %101, %101, %111
	db %010, %110, %010, %010, %111
	db %111, %001, %111, %100, %111
	db %111, %001, %111, %001, %111
	db %101, %101, %111, %001, %001
	db %111, %100, %111, %001, %111
	db %111, %100, %111, %101, %111
	db %111, %001, %001, %001, %001
	db %111, %101, %111, %101, %111
	db %111, %101, %111, %001, %111
	db %000, %000, %000, %000, %000
	db %101, %001, %010, %100, %101
