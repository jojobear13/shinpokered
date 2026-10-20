; Gen 9's recoil: Double-Edge 1/3 of the damage dealt, Take Down and
; Submission 1/4 (rounded), Struggle 1/4 of the user's max HP; at least 1
RecoilEffect_:
	call UserMaxHP
	cp STRUGGLE
	jr z, .struggle ; of its max HP (hl)
	ld hl, wDamage
	cp DOUBLE_EDGE
	ld a, 3
	jr z, .gotFraction
	inc a
	jr .gotFraction
.struggle
	ld a, 4
.gotFraction
	call RoundedFraction
	call UserMaxHP
	ld de, HitWithRecoilText
	jr UserLosesHP

; Jump Kick and Hi Jump Kick missed: the user loses half its max HP, not
; through its substitute (the text has been printed)
CrashDamage_:
	call UserMaxHP
	ld a, [hli]
	ld b, a
	ld c, [hl]
	dec hl
	srl b
	rr c
	ld de, 0
	; fall through

; the mon whose turn it is loses bc HP (at least 1), hl = its max HP; then
; text de, if any
UserLosesHP:
	ld a, b
	or c
	jr nz, .updateHP
	inc c ; at least 1
.updateHP
	ld a, [hli]
	ld [wHPBarMaxHP+1], a
	ld a, [hl]
	ld [wHPBarMaxHP], a
	push bc
	ld bc, wBattleMonHP - wBattleMonMaxHP
	add hl, bc
	pop bc
	ld a, [hl]
	ld [wHPBarOldHP], a
	sub c
	ld [hld], a
	ld [wHPBarNewHP], a
	ld a, [hl]
	ld [wHPBarOldHP+1], a
	sbc b
	ld [hl], a
	ld [wHPBarNewHP+1], a
	jr nc, .getHPBarCoords
; if the damage is higher than the Pokemon's HP, set its HP to 0
	xor a
	ld [hli], a
	ld [hl], a
	ld hl, wHPBarNewHP
	ld [hli], a
	ld [hl], a
.getHPBarCoords
	push de
	coord hl, 10, 9
	ld a, [H_WHOSETURN]
	and a
	ld a, $1
	jr z, .updateHPBar
	coord hl, 2, 2
	xor a
.updateHPBar
	ld [wHPBarType], a
	predef UpdateHPBar2
	pop hl
	ld a, h
	or l
	ret z
	jp PrintText

; hl = the max HP of the mon whose turn it is, a = its move
UserMaxHP:
	ld a, [H_WHOSETURN]
	and a
	ld a, [wPlayerMoveNum]
	ld hl, wBattleMonMaxHP
	ret z
	ld a, [wEnemyMoveNum]
	ld hl, wEnemyMonMaxHP
	ret

; bc = the big-endian word at hl divided by a, rounded (half up)
RoundedFraction:
	ld [H_DIVISOR], a
	ld b, [hl]
	inc hl
	ld c, [hl]
	srl a
	add c
	ld c, a
	jr nc, .noCarry
	inc b
.noCarry
	xor a
	ld [H_DIVIDEND], a
	ld [H_DIVIDEND + 1], a
	ld a, b
	ld [H_DIVIDEND + 2], a
	ld a, c
	ld [H_DIVIDEND + 3], a
	ld b, 4
	call Divide
	ld a, [H_QUOTIENT + 2]
	ld b, a
	ld a, [H_QUOTIENT + 3]
	ld c, a
	ret

HitWithRecoilText:
	TX_FAR _HitWithRecoilText
	db "@"
