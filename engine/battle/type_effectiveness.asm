; STAB and type effectiveness, and the type chart (out of bank $0F, which is full)

AdjustDamageForMoveType:
	ld a, $a
	ld [wDamageMultipliers], a	;joenote - move this to AdjustDamageForMoveType to prevent multi-attack overflows
; values for player turn
	ld hl, wBattleMonType
	ld a, [hli]
	ld b, a    ; b = type 1 of attacker
	ld c, [hl] ; c = type 2 of attacker
	ld hl, wEnemyMonType
	ld a, [hli]
	ld d, a    ; d = type 1 of defender
	ld e, [hl] ; e = type 2 of defender
	ld a, [wPlayerMoveType]
	ld [wMoveType], a
	ld a, [H_WHOSETURN]
	and a
	jr z, .next
; values for enemy turn
	ld hl, wEnemyMonType
	ld a, [hli]
	ld b, a    ; b = type 1 of attacker
	ld c, [hl] ; c = type 2 of attacker
	ld hl, wBattleMonType
	ld a, [hli]
	ld d, a    ; d = type 1 of defender
	ld e, [hl] ; e = type 2 of defender
	ld a, [wEnemyMoveType]
	ld [wMoveType], a
.next
;here is where STAB is handled
	ld a, [wMoveType]
	cp b ; does the move type match type 1 of the attacker?
	jr z, .sameTypeAttackBonus
	cp c ; does the move type match type 2 of the attacker?
	jr z, .sameTypeAttackBonus
	jr .skipSameTypeAttackBonus
.sameTypeAttackBonus
; if the move type matches one of the attacker's types, multiply damage by 1.5
	ld hl, wDamage + 1
	ld a, [hld]
	ld h, [hl]
	ld l, a    ; hl = damage
	ld b, h
	ld c, l    ; bc = damage
	srl b
	rr c      ; bc = floor(0.5 * damage)
	add hl, bc ; hl = floor(1.5 * damage)
; store damage
	ld a, h
	ld [wDamage], a
	ld a, l
	ld [wDamage + 1], a
	call c, .overflow	;joenote - handle damage overflow
	ld hl, wDamageMultipliers
	set 7, [hl]
.skipSameTypeAttackBonus

;now to check move type effectiveness against defender's type 1 and 2
	callab ScrappyTypes ; keeps de
	ld c, d 	;start by checking against type 1
	call TypeXEffectiveness
	;make sure that there is a type 2 to even look at
	ld a, d
	cp e
	ld c, e 	
	call nz, TypeXEffectiveness	;now check against type 2

;wDamageMultipliers will now be either 0, 2, 5, 10, 20, or 40 (immune, quarter, half, neutral, double, quadruple)	
;Adjust the damage accordingly
	ld hl, wDamage
	ld a, [wDamageMultipliers]
	and $7F
	jr z, .negate
	
	;There is no type immunity at this line, so make any static moves return neutral
	push af
	ld a, [wUnusedC000]
	ld b, a
	pop af
	bit 4, b
	jr nz, .static_move
	
	cp 3
	push af
	call c, .halve
	pop af
	cp 10
	push af
	call c, .halve
	pop af
	cp 11
	push af
	call nc, .double
	pop af
	cp 21
	call nc, .double
	jr .done
.negate
	xor a
	ld [hli], a
	ld [hl], a
;damage is 0, make the move miss
	ld a, 2
	ld [wMoveMissed], a
.done
	ret
.halve
	srl [hl]
	inc hl
	rr [hl]
	dec hl
	ret ; (Gen 9: a hit that doesn't miss does at least 1, in DamageModifiers)
.double
	inc hl
	sla [hl]
	dec hl
	rl [hl]
	call c, .overflow	;joenote - handle damage overflow
	ret
.static_move
	ld a, [wDamageMultipliers]
	and $80
	or $A
	ld [wDamageMultipliers], a
	jr .done
.overflow	;joenote - cap damage at 65535
	ld a, $ff
	ld [wDamage], a
	ld [wDamage+1], a	
	ret
	
;c = defender type 1 or 2
TypeXEffectiveness:
	ld a, [wMoveType]
	ld b, a
	ld hl, TypeEffects
.loop
	ld a, [hli] ; a = "attacking type" of the current type pair
	cp $ff
	jr z, .done
	cp b ; does move type match "attacking type"?
	jr nz, .nextTypePair
	ld a, [hl] ; a = "defending type" of the current type pair
	cp c ; does type 1 or 2 of defender match "defending type"?
	jr z, .matchingPairFound
.nextTypePair
	inc hl
	inc hl
	jr .loop
.matchingPairFound
	inc hl
	ld a, [wDamageMultipliers]
	and $80
	ld b, a		;b will hold the STAB bit
	ld a, [wDamageMultipliers]
	and $7F
	ld c, a		;c will hold the current multiplier
	ld a, [hl]	;a = effectiveness multiplier of the current type pair (05, 20, or 00)
	and a
	jr z, .negate
	cp 20
	jr z, .double
	cp 05
	jr z, .halve
	jr .done	;don't do anything for invalid multiplier
.halve
	srl c
	jr .update_multiplier
.double
	ld a, c
	sla a
	and $7F
	ld c, a
	jr .update_multiplier
.negate
	xor a
	ld c, a
.update_multiplier
	ld a, b
	or c
	ld [wDamageMultipliers], a
.done
	ret

; AdjustDamageForMoveType:
; ; values for player turn
	; ld hl, wBattleMonType
	; ld a, [hli]
	; ld b, a    ; b = type 1 of attacker
	; ld c, [hl] ; c = type 2 of attacker
	; ld hl, wEnemyMonType
	; ld a, [hli]
	; ld d, a    ; d = type 1 of defender
	; ld e, [hl] ; e = type 2 of defender
	; ld a, [wPlayerMoveType]
	; ld [wMoveType], a
	; ld a, [H_WHOSETURN]
	; and a
	; jr z, .next
; ; values for enemy turn
	; ld hl, wEnemyMonType
	; ld a, [hli]
	; ld b, a    ; b = type 1 of attacker
	; ld c, [hl] ; c = type 2 of attacker
	; ld hl, wBattleMonType
	; ld a, [hli]
	; ld d, a    ; d = type 1 of defender
	; ld e, [hl] ; e = type 2 of defender
	; ld a, [wEnemyMoveType]
	; ld [wMoveType], a
; .next
	; ld a, [wMoveType]
	; cp b ; does the move type match type 1 of the attacker?
	; jr z, .sameTypeAttackBonus
	; cp c ; does the move type match type 2 of the attacker?
	; jr z, .sameTypeAttackBonus
	; jr .skipSameTypeAttackBonus
; .sameTypeAttackBonus
; ; if the move type matches one of the attacker's types
	; ld hl, wDamage + 1
	; ld a, [hld]
	; ld h, [hl]
	; ld l, a    ; hl = damage
	; ld b, h
	; ld c, l    ; bc = damage
	; srl b
	; rr c      ; bc = floor(0.5 * damage)
	; add hl, bc ; hl = floor(1.5 * damage)
; ; store damage
	; ld a, h
	; ld [wDamage], a
	; ld a, l
	; ld [wDamage + 1], a
	; ld hl, wDamageMultipliers
	; set 7, [hl]
; .skipSameTypeAttackBonus
	; ld a, [wMoveType]
	; ld b, a
	; ld hl, TypeEffects
; .loop
	; ld a, [hli] ; a = "attacking type" of the current type pair
	; cp $ff
	; jr z, .done
	; cp b ; does move type match "attacking type"?
	; jr nz, .nextTypePair
	; ld a, [hl] ; a = "defending type" of the current type pair
	; cp d ; does type 1 of defender match "defending type"?
	; jr z, .matchingPairFound
	; cp e ; does type 2 of defender match "defending type"?
	; jr z, .matchingPairFound
	; jr .nextTypePair
; .matchingPairFound
; ; if the move type matches the "attacking type" and one of the defender's types matches the "defending type"
	; push hl
	; push bc
	; inc hl
	; ld a, [wDamageMultipliers]
	; and $80
	; ld b, a
	; ld a, [hl] ; a = damage multiplier
	; ld [H_MULTIPLIER], a
	; add b
	; ld [wDamageMultipliers], a
	; xor a
	; ld [H_MULTIPLICAND], a
	; ld hl, wDamage
	; ld a, [hli]
	; ld [H_MULTIPLICAND + 1], a
	; ld a, [hld]
	; ld [H_MULTIPLICAND + 2], a
	; call Multiply
	; ld a, 10
	; ld [H_DIVISOR], a
	; ld b, $04
	; call Divide
	; ld a, [H_QUOTIENT + 2]
	; ld [hli], a
	; ld b, a
	; ld a, [H_QUOTIENT + 3]
	; ld [hl], a
	; or b ; is damage 0?
	; jr nz, .skipTypeImmunity
; .typeImmunity
; ; if damage is 0, make the move miss
; ; this only occurs if a move that would do 2 or 3 damage is 0.25x effective against the target
	; inc a
	; ld [wMoveMissed], a
; .skipTypeImmunity
	; pop bc
	; pop hl
; .nextTypePair
	; inc hl
	; inc hl
	; jp .loop
; .done
	; ret

; function to tell how effective the type of an enemy attack is on the player's current pokemon
; now takes into account the effects that dual types can have
; (e.g. 4x weakness / resistance, weaknesses and resistances canceling)
; the result is stored in [wTypeEffectiveness]
; ($05 is not very effective, $0A is neutral, $14 is super effective)
; ($00 is immune, $02 is 4x uneffective, $28 is 4x super effective)
; as far is can tell, this is only used once in some AI code to help decide which move to use
AIGetTypeEffectiveness:
;joenote - if type-effectiveness bit is set, then do wPlayerMoveType and wEnemyMonType
;		-also changed neutral value from $10 to $0A since it makes more sense
;		-and modifying this to take into account both types
	ld a, [wUnusedC000]
	bit 3, a
	jr z, .enemyMove	
	ld a, [wPlayerMoveType]
	ld d, a                    ; d = type of player move
	ld hl, wEnemyMonType
	ld b, [hl]                 ; b = type 1 of enemy's pokemon
	inc hl
	ld c, [hl]                 ; c = type 2 of enemy's pokemon
	ld a, $0A
	ld [wTypeEffectiveness], a ; initialize to neutral effectiveness
	ld hl, TypeEffects
	jr .loop
.enemyMove
	ld a, [wEnemyMoveType]
	ld d, a                    ; d = type of enemy move
	ld hl, wBattleMonType
	ld b, [hl]                 ; b = type 1 of player's pokemon
	inc hl
	ld c, [hl]                 ; c = type 2 of player's pokemon
	ld a, $0A
	ld [wTypeEffectiveness], a ; initialize to neutral effectiveness
	ld hl, TypeEffects
.loop
	ld a, [hli]
	cp $ff
	ret z
	cp d                      ; match the type of the move
	jr nz, .nextTypePair1
	ld a, [hli]
	cp b                      ; match with type 1 of pokemon
	jr z, .AImatchingPairFound
	cp c                      ; or match with type 2 of pokemon
	jr z, .AImatchingPairFound
	jr .nextTypePair2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.AImatchingPairFound
	ld a, [hl]	;get damage multiplier
	cp $05	;is it halved?
	jr nz, .AInothalf	;jump down of not half
	ld a, [wTypeEffectiveness]	;else get the effectiveness multiplier
	srl a	;halve the multiplier
	ld [wTypeEffectiveness], a ; store damage multiplier
	jr .nextTypePair2	;get next pair in list
.AInothalf
	cp $14	;is it double?
	jr nz, .AImustbezero	;if not double either, it must be zero so skip ahead
	ld a, [wTypeEffectiveness]	;else get the effectiveness multiplier
	sla a	;double the multiplier
	ld [wTypeEffectiveness], a ; store damage multiplier
	jr .nextTypePair2	;get next pair in list
.AImustbezero
	ld a, [wTypeEffectiveness]	;else get the effectiveness multiplier
	xor a	;clear a to 00
	jr .done
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.nextTypePair1
	inc hl
.nextTypePair2
	inc hl
	jr .loop
.done
	;joenote - removed		ld a, [hl]
	ld [wTypeEffectiveness], a ; store damage multiplier
	ret

INCLUDE "data/type_effects.asm"

