; The type matchups the player has seen, and the move menu's effectiveness
; marks (the DISPLAY option TYPE HINT: OFF, ON, or LEARNED, which marks only
; matchups the player has seen).
;
; A matchup is seen when an attacking move (not a status move; fixed-damage
; ones count) hits, or fails to affect, a mon: its type against each of
; the target's types, so a hit on a dual-type mon counts as both matchups.
; Either side's moves count, and each direction is its own matchup.
; wTypeChartSeen keeps them, a flag each.

; on the move menu, the line above the move's type: its category on the left
; and, with TYPE HINT on, how effective it would be against the enemy on the
; right: ▴▴ 4x, ▴ 2x, nothing 1x, ▼ 1/2x, ▼▼ 1/4x, × no effect, and with it
; LEARNED, ? for a matchup not yet seen. Status moves get no mark, and
; fixed-damage moves only show ×, since type only decides whether they hit.
; There is no mark against a ghost the Silph Scope hasn't identified.
PrintMoveCategoryAndEffectiveness:
	ld a, [wPlayerMoveNum]
	call GetMoveCategory
	push af
	ld de, PhysicalText
	and a
	jr z, .gotCategoryText
	ld de, SpecialText
	dec a
	jr z, .gotCategoryText
	ld de, StatusMoveText
.gotCategoryText
	coord hl, 1, 9
	call PlaceString
	pop af
	cp STATUS
	ret z
	ld a, [wDisplayOptions]
	and TYPE_HINT_MASK
	ret z
	callab IsGhostBattle
	ret z ; an unidentified ghost: no hint at what it really is
	ld a, [wDisplayOptions]
	and TYPE_HINT_LEARNED
	jr z, .known
	ld a, [wPlayerMoveType]
	ld d, a
	ld hl, wEnemyMonType
	ld a, [hli]
	ld e, a
	push hl
	call TypeMatchupSeen
	pop hl
	jr z, .unknown
	ld e, [hl]
	call TypeMatchupSeen
	jr nz, .known
.unknown
	coord hl, 9, 9
	ld [hl], "?"
	ret
.known
	ld a, [wPlayerMoveEffect] ; fixed damage?
	cp SUPER_FANG_EFFECT
	jr z, .fixedDamage
	cp SPECIAL_DAMAGE_EFFECT
	jr z, .fixedDamage
	and a ; nc
	jr .gotDamageKind
.fixedDamage
	scf
.gotDamageKind
	push af
	ld a, [wTypeEffectiveness]
	push af
	ld a, [wUnusedC000]
	push af
	set 3, a ; the player's move against the enemy's types
	ld [wUnusedC000], a
	callab AIGetTypeEffectiveness
	pop af
	ld [wUnusedC000], a
	ld a, [wTypeEffectiveness]
	ld b, a
	pop af
	ld [wTypeEffectiveness], a
	pop af
	ld a, b
	jr nc, .gotMultiplier
	and a
	ret nz ; fixed damage: only immunity matters
.gotMultiplier
	coord hl, 8, 9
	and a
	jr z, .noEffect
	cp $05
	jr c, .quarter
	jr z, .half
	cp $14
	ret c ; neutral
	jr z, .double
	ld a, "▴" ; 4x
	ld [hli], a
	ld [hl], a
	ret
.double
	inc hl
	ld [hl], "▴"
	ret
.half
	inc hl
	ld [hl], "▼"
	ret
.quarter
	ld a, "▼"
	ld [hli], a
	ld [hl], a
	ret
.noEffect
	inc hl
	ld [hl], "×"
	ret

PhysicalText:
	db "PHYS@"
SpecialText:
	db "SPCL@"
StatusMoveText:
	db "STAT@"

; after an attack hits: its matchups are seen, then the "super effective"
; text
RecordAndDisplayEffectiveness:
	call RecordTypeMatchup
	ld a, [H_WHOSETURN]
	and a
	ld a, [wPlayerMovePower]
	jr z, .gotPower
	ld a, [wEnemyMovePower]
.gotPower
	dec a
	ret z ; fixed damage: no "super effective" text
	jpab DisplayEffectiveness

; the matchups of the move being used against its target's types, if it's
; an attacking move (power 1, fixed damage, counts too: its type still
; decides whether it hits). Keeps de.
RecordTypeMatchup:
	push de
	ld a, [H_WHOSETURN]
	and a
	ld a, [wPlayerMovePower]
	ld b, a
	ld a, [wPlayerMoveType]
	ld hl, wEnemyMonType
	jr z, .gotMove
	ld a, [wEnemyMovePower]
	ld b, a
	ld a, [wEnemyMoveType]
	ld hl, wBattleMonType
.gotMove
	ld d, a
	ld a, b
	and a
	jr z, .done
	ld a, [hli]
	ld e, a
	push hl
	call TypeMatchupBit
	or [hl]
	ld [hl], a
	pop hl
	ld e, [hl]
	call TypeMatchupBit
	or [hl]
	ld [hl], a
.done
	pop de
	ret

; nz if the player has seen type d attack type e
TypeMatchupSeen:
	call TypeMatchupBit
	and [hl]
	ret

; hl = the byte of wTypeChartSeen for type d attacking type e, a = its bit.
; Keeps de.
TypeMatchupBit:
	push de
	ld a, d
	call TypeChartIndex
	ld l, a
	ld h, 0
	ld b, h
	ld c, l
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl ; 16x
	add hl, bc
	add hl, bc
	add hl, bc ; 19x (NUM_CHART_TYPES)
	ld a, e
	call TypeChartIndex
	ld c, a
	add hl, bc
	ld a, l
	and 7
	ld b, a
	srl h
	rr l
	srl h
	rr l
	srl h
	rr l
	ld de, wTypeChartSeen
	add hl, de
	pop de
	ld a, 1
	inc b
.shift
	dec b
	ret z
	add a
	jr .shift

; a = the type chart's row or column for type a
TypeChartIndex:
	cp FIRE
	ret c
	sub FIRE - (STEEL + 1)
	ret

ASSERT FAIRY - FIRE + STEEL + 2 == NUM_CHART_TYPES
