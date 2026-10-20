; Gen 9's damage (design brief, Gen 9 rules pass, part 4), for the side in
; hBattleSide (the attacker; BaseDamage adds BATTLE_SIDE_SPECIAL for a special
; move):
;   base = (2 x level / 5 + 2) x power x A / D / 50 + 2, with A and D the
;     unmodified stats times their stages (a critical hit leaves out the
;     attacker's drops and the defender's raises), each at most 999
;   then x1.5 for a critical hit, x85-100% at random, STAB and type
;   (AdjustDamageForMoveType), x1/2 for a burned attacker's physical move
;   (not with Guts), x1/2 behind Reflect or Light Screen (not on a critical
;   hit), then the abilities' and items' modifiers; at least 1 unless the
;   target is immune.

; Gen 9's critical hit chance: stage 0 1/24, 1 1/8, 2 1/2, 3 or more always.
; +1 for the high-ratio moves, +2 for Focus Energy (and Dire Hit), items
; (CritStageModifiers); never against Battle Armor or Shell Armor, and never
; for the fixed-damage moves (power 0 or 1)
CriticalHitTest:
	xor a
	ld [wCriticalHitOrOHKO], a
	ld hl, wPlayerMovePower
	ld de, wPlayerBattleStatus2
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotSide
	ld hl, wEnemyMovePower
	ld de, wEnemyBattleStatus2
.gotSide
	ld a, [hld]
	cp 2
	ret c
	dec hl
	ld c, [hl] ; the move
	ld b, 0 ; the stage
	ld a, [de]
	bit GETTING_PUMPED, a
	jr z, .noFocusEnergy
	inc b
	inc b
.noFocusEnergy
	ld hl, HighCriticalMoves
.loop
	ld a, [hli]
	cp $ff
	jr z, .gotMove
	cp c
	jr nz, .loop
	inc b
.gotMove
	ld a, b
	ld [wSideEffectChance], a ; free while the stage is worked out
	callab CritStageModifiers
	ld a, [wSideEffectChance]
	cp $ff
	ret z ; armor
	cp 3
	jr nc, .crit
	ld hl, CritChances
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	call BattleRandom
	cp [hl]
	ret nc
.crit
	ld a, 1
	ld [wCriticalHitOrOHKO], a
	ret

CritChances: ; out of 256, by stage
	db 11  ; 1/24
	db 32  ; 1/8
	db 128 ; 1/2

; the moves with a high critical hit ratio (+1)
HighCriticalMoves:
	db KARATE_CHOP
	db RAZOR_LEAF
	db CRABHAMMER
	db SLASH
	db RAZOR_WIND
	db SKY_ATTACK
	db $FF

; hBattleSide = the attacking side -> wDamage = the base damage, and
; BATTLE_SIDE_SPECIAL set for a special move; z if the move has no power
BaseDamage:
	xor a
	ld [wDamage], a
	ld [wDamage + 1], a
	ld a, [hBattleSide]
	and BATTLE_SIDE_ENEMY
	ld [hBattleSide], a
	ld hl, wPlayerMovePower
	jr z, .gotMove
	ld hl, wEnemyMovePower
.gotMove
	ld a, [hld]
	and a
	ret z
	ld [wDamageScratch], a ; power
	dec hl
	ld a, [hl]
	call GetMoveCategory
	cp SPECIAL
	jr nz, .gotCategory
	ld hl, hBattleSide
	set BATTLE_SIDE_SPECIAL_F, [hl]
.gotCategory
	ld hl, .attackerStat
	call .lookup
	push hl
	ld hl, .attackerStage
	call .lookup
	ld a, [hl]
	ld b, a
	ld a, [wCriticalHitOrOHKO]
	dec a
	ld a, b
	jr nz, .gotAttackerStage
	cp 7
	jr nc, .gotAttackerStage
	ld a, 7 ; a critical hit leaves out the attacker's drops
.gotAttackerStage
	pop hl
	call ScaledStat
	ld a, d
	ld [wDamageScratch + 2], a
	ld a, e
	ld [wDamageScratch + 3], a
	ld hl, .defenderStat
	call .lookup
	push hl
	ld hl, .defenderStage
	call .lookup
	ld a, [hl]
	ld b, a
	ld a, [wCriticalHitOrOHKO]
	dec a
	ld a, b
	jr nz, .gotDefenderStage
	cp 7
	jr c, .gotDefenderStage
	ld a, 7 ; and the defender's raises
.gotDefenderStage
	pop hl
	call ScaledStat
	ld a, d
	ld [wDamageScratch + 4], a
	ld a, e
	ld [wDamageScratch + 5], a
	ld a, [hBattleSide]
	and BATTLE_SIDE_ENEMY
	ld a, [wBattleMonLevel]
	jr z, .gotLevel
	ld a, [wEnemyMonLevel]
.gotLevel
	ld [wDamageScratch + 1], a
	call DamageFormula
	ld a, 1
	and a
	ret

; hl = the address the table at hl gives for hBattleSide (0-3)
.lookup
	ld a, [hBattleSide]
	add a
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

; by hBattleSide: the player's physical move, the enemy's, the player's
; special, the enemy's
.attackerStat
	dw wPlayerMonUnmodifiedAttack, wEnemyMonUnmodifiedAttack
	dw wPlayerMonUnmodifiedSpecialAttack, wEnemyMonUnmodifiedSpecialAttack
.attackerStage
	dw wPlayerMonAttackMod, wEnemyMonAttackMod
	dw wPlayerMonSpecialAttackMod, wEnemyMonSpecialAttackMod
.defenderStat
	dw wEnemyMonUnmodifiedDefense, wPlayerMonUnmodifiedDefense
	dw wEnemyMonUnmodifiedSpecialDefense, wPlayerMonUnmodifiedSpecialDefense
.defenderStage
	dw wEnemyMonDefenseMod, wPlayerMonDefenseMod
	dw wEnemyMonSpecialDefenseMod, wPlayerMonSpecialDefenseMod

; wDamageScratch: power, level, A (2 bytes), D (2 bytes) -> wDamage =
; (2 x level / 5 + 2) x power x A / D / 50 + 2, at most 65535
DamageFormula:
	ld a, [wDamageScratch + 1]
	add a
	ld b, -1
.divideBy5
	inc b
	sub 5
	jr nc, .divideBy5
	inc b
	inc b ; 2 x level / 5 + 2
	ld c, b
	ld b, 0
	ld a, [wDamageScratch]
	ld e, a
	ld d, 0
	call Mul16 ; x power
	ld a, [wMulResult + 2]
	ld b, a
	ld a, [wMulResult + 3]
	ld c, a
	ld a, [wDamageScratch + 2]
	ld d, a
	ld a, [wDamageScratch + 3]
	ld e, a
	call Mul16 ; x A
	ld a, [wDamageScratch + 4]
	ld d, a
	ld a, [wDamageScratch + 5]
	ld e, a
	call Div32by16 ; / D
	ld de, 50
	call Div32by16 ; / 50
	ld a, [wMulResult]
	ld b, a
	ld a, [wMulResult + 1]
	or b
	jr nz, .max
	ld a, [wMulResult + 3]
	add 2
	ld [wDamage + 1], a
	ld a, [wMulResult + 2]
	adc 0
	ld [wDamage], a
	ret nc
.max
	ld a, $ff
	ld [wDamage], a
	ld [wDamage + 1], a
	ret

; hl = an unmodified stat, a = its stage (1-13, 7 neutral) -> de = the stat
; times Gen 9's stage ratio, 1-999
ScaledStat:
	push af
	ld a, [hli]
	ld b, a
	ld c, [hl]
	pop af
	dec a
	add a
	ld hl, StatModifierRatios
	add l
	ld l, a
	jr nc, .noCarry
	inc h
.noCarry
	ld a, [hli]
	ld e, a
	ld d, 0
	ld a, [hl]
	push af
	call Mul16 ; x the numerator
	pop af
	ld e, a
	ld d, 0
	call Div32by16 ; / the denominator
	ld a, [wMulResult + 2]
	ld d, a
	ld a, [wMulResult + 3]
	ld e, a
	ld a, d
	cp HIGH(999)
	jr c, .notCapped
	jr nz, .cap
	ld a, e
	cp LOW(999) + 1
	jr c, .notCapped
.cap
	ld de, 999
	ret
.notCapped
	ld a, d
	or e
	ret nz
	inc e ; at least 1
	ret

; wMulResult / de -> wMulResult (32 bits); hl = the remainder. de must be
; nonzero and under 2 ^ 15
Div32by16:
	ld hl, 0
	ld a, 32
	ld [wMulCount], a
.loop
	push hl
	ld hl, wMulResult + 3
	sla [hl]
	dec hl
	rl [hl]
	dec hl
	rl [hl]
	dec hl
	rl [hl]
	pop hl
	rl l
	rl h
	ld a, l
	sub e
	ld c, a
	ld a, h
	sbc d
	jr c, .next
	ld h, a
	ld l, c
	ld a, [wMulResult + 3]
	or 1
	ld [wMulResult + 3], a
.next
	ld a, [wMulCount]
	dec a
	ld [wMulCount], a
	jr nz, .loop
	ret

; after BaseDamage: Gen 9's modifiers, in its order
DamageModifiers:
	ld a, [wCriticalHitOrOHKO]
	dec a
	jr nz, .noCrit
	lb bc, 3, 2
	call ScaleDamage16
.noCrit
	call BattleRandom
	and 15
	add 85
	ld b, a
	ld c, 100
	call ScaleDamage16 ; 85-100%
	call AdjustDamageForMoveType ; STAB and type
; a burned attacker's physical move (not with Guts)
	ld a, [hBattleSide]
	bit BATTLE_SIDE_SPECIAL_F, a
	jr nz, .noBurn
	and BATTLE_SIDE_ENEMY
	ld a, [wBattleMonStatus]
	jr z, .gotStatus
	ld a, [wEnemyMonStatus]
.gotStatus
	bit BRN, a
	jr z, .noBurn
	callab UserHasGuts
	jr z, .noBurn
	lb bc, 1, 2
	call ScaleDamage16
.noBurn
; Reflect and Light Screen, not on a critical hit
	ld a, [wCriticalHitOrOHKO]
	dec a
	jr z, .noScreen
	ld a, [hBattleSide]
	and BATTLE_SIDE_ENEMY
	ld a, [wEnemyBattleStatus3]
	jr z, .gotScreens
	ld a, [wPlayerBattleStatus3]
.gotScreens
	ld b, a
	ld a, [hBattleSide]
	bit BATTLE_SIDE_SPECIAL_F, a
	ld a, b
	jr nz, .lightScreen
	bit HAS_REFLECT_UP, a
	jr .gotScreen
.lightScreen
	bit HAS_LIGHT_SCREEN_UP, a
.gotScreen
	jr z, .noScreen
	lb bc, 1, 2
	call ScaleDamage16
.noScreen
	callab AbilityDamageModifiers
; at least 1, unless it doesn't affect the target
	ld hl, wDamage
	ld a, [hli]
	or [hl]
	ret nz
	ld a, [wMoveMissed]
	and a
	ret nz
	ld a, [wDamageMultipliers]
	and $7f
	ret z
	ld [hl], 1
	ret

; wDamage x b / c (rounded down), at most 65535
ScaleDamage16:
	xor a
	ld [H_MULTIPLICAND], a
	ld a, [wDamage]
	ld [H_MULTIPLICAND + 1], a
	ld a, [wDamage + 1]
	ld [H_MULTIPLICAND + 2], a
	ld a, b
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, c
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	ld a, [H_QUOTIENT + 1]
	and a
	jr nz, .max
	ld a, [H_QUOTIENT + 2]
	ld [wDamage], a
	ld a, [H_QUOTIENT + 3]
	ld [wDamage + 1], a
	ret
.max
	ld a, $ff
	ld [wDamage], a
	ld [wDamage + 1], a
	ret

; A confused mon hitting itself (the mon whose turn it is): a 40-power
; typeless physical hit, its own Attack against its own Defense (with their
; stages), at random 85-100%, never critical. -> wDamage
SelfHitDamage:
	xor a
	ld [wCriticalHitOrOHKO], a
	ld a, 40
	ld [wDamageScratch], a
	ld a, [H_WHOSETURN]
	and a
	ld hl, wPlayerMonUnmodifiedAttack
	ld a, [wPlayerMonAttackMod]
	jr z, .gotAttack
	ld hl, wEnemyMonUnmodifiedAttack
	ld a, [wEnemyMonAttackMod]
.gotAttack
	call ScaledStat
	ld a, d
	ld [wDamageScratch + 2], a
	ld a, e
	ld [wDamageScratch + 3], a
	ld a, [H_WHOSETURN]
	and a
	ld hl, wPlayerMonUnmodifiedDefense
	ld a, [wPlayerMonDefenseMod]
	jr z, .gotDefense
	ld hl, wEnemyMonUnmodifiedDefense
	ld a, [wEnemyMonDefenseMod]
.gotDefense
	call ScaledStat
	ld a, d
	ld [wDamageScratch + 4], a
	ld a, e
	ld [wDamageScratch + 5], a
	ld a, [H_WHOSETURN]
	and a
	ld a, [wBattleMonLevel]
	jr z, .gotLevel
	ld a, [wEnemyMonLevel]
.gotLevel
	ld [wDamageScratch + 1], a
	call DamageFormula
	call BattleRandom
	and 15
	add 85
	ld b, a
	ld c, 100
	jp ScaleDamage16
