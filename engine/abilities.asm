; abilities: each species has two (data/mon_abilities.asm), and the ability
; slot bit, bit 0 of the third DV byte, picks one

; a = species, c = the third DV byte -> a = the ability
; preserves bc, de and hl
GetMonAbility:
	push hl
	push de
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld de, MonAbilities
	add hl, de
	bit 0, c
	jr z, .gotSlot
	inc hl
.gotSlot
	ld a, [hl]
	pop de
	pop hl
	ret

; set wPlayerAbility or wEnemyAbility from the mon just sent out, and clear
; what the side's last mon's ability had set up
LoadPlayerAbility:
	xor a
	ld [wPlayerChoiceLock], a
	ld hl, wAbilityFlags
	res FLASH_FIRE_PLAYER_F, [hl]
	set ENTRY_PENDING_PLAYER_F, [hl]
	ld de, wBattleMon
	ld hl, wPlayerAbility
	jr LoadBattleMonAbility
LoadEnemyAbility:
	xor a
	ld [wEnemyChoiceLock], a
	ld hl, wAbilityFlags
	res FLASH_FIRE_ENEMY_F, [hl]
	set ENTRY_PENDING_ENEMY_F, [hl]
	ld de, wEnemyMon
	ld hl, wEnemyAbility
LoadBattleMonAbility:
	ASSERT wEnemyMonDVs - wEnemyMon == wBattleMonDVs - wBattleMon
	push hl
	ld hl, wBattleMonDVs + 2 - wBattleMon
	add hl, de
	ld c, [hl]
	ld a, [de] ; species
	call GetMonAbility
	pop hl
	ld [hl], a
	ret

; a = 0 for the player's mon or 1 for the enemy's -> a = its ability, after
; Neutralizing Gas (which stops every ability but itself), and z if none
; preserves bc, de and hl
GetSideAbility:
	push hl
	push bc
	ld hl, wPlayerAbility
	ld b, [hl]
	inc hl
	ld c, [hl]
	and a
	jr z, .gotSide
	ld a, b
	ld b, c
	ld c, a
.gotSide ; b = this side's, c = the other side's
	ld a, c
	cp NEUTRALIZING_GAS
	ld a, b
	jr nz, .done
	cp NEUTRALIZING_GAS
	jr z, .done
	xor a ; NO_ABILITY
.done
	pop bc
	pop hl
	and a
	ret

; the ability of the mon whose turn it is
UserAbility:
	ld a, [H_WHOSETURN]
	jr GetSideAbility

; the ability of the other mon
TargetAbility:
	ld a, [H_WHOSETURN]
	xor 1
	jr GetSideAbility

; the target's ability where the user's move meets it: none if the user has
; Mold Breaker. Abilities that react to a hit after it lands (Static and the
; like) use TargetAbility, since Mold Breaker doesn't stop them
TargetAbilityForMove:
	call UserAbility
	cp MOLD_BREAKER
	jr nz, TargetAbility
	xor a
	ret

; a = move -> a = its flags (MOVE_*_F)
; preserves bc, de and hl
GetMoveFlags:
	push hl
	push de
	dec a
	ld e, a
	ld d, 0
	ld hl, MoveFlags
	add hl, de
	ld a, [hl]
	pop de
	pop hl
	ret

; hl = the user's move (wPlayerMoveNum or wEnemyMoveNum)
GetUserMove:
	ASSERT wEnemyMoveNum - wEnemyMoveEffect == wPlayerMoveNum - wPlayerMoveEffect
	ld hl, wPlayerMoveNum
	ld a, [H_WHOSETURN]
	and a
	ret z
	ld hl, wEnemyMoveNum
	ret

; a = offset into the user's move (wPlayerMoveNum ...) -> a = that field
; preserves bc and de
GetUserMoveField:
	push bc
	ld c, a
	ld b, 0
	call GetUserMove
	add hl, bc
	ld a, [hl]
	pop bc
	ret

; a = ability -> its name in wcd6d, and de = wcd6d
GetAbilityName:
	ld hl, AbilityNames
	and a
	jr z, .found
	ld b, a
.skip
	ld a, [hli]
	cp "@"
	jr nz, .skip
	dec b
	jr nz, .skip
.found
	ld de, wcd6d
	push de
.copy
	ld a, [hli]
	ld [de], a
	inc de
	cp "@"
	jr nz, .copy
	pop de
	ret

; on page 2 of the status screen: the mon's ability, under the pic beside its
; dex number
PrintStatusScreenAbility:
	ld a, [wLoadedMonDVs + 2]
	ld c, a
	ld a, [wLoadedMonSpecies]
	call GetMonAbility
	call GetAbilityName
	coord hl, 8, 7
	jp PlaceString

; Abilities that stop a move before it hits (Gen 5 on: after the check for a
; target in the air or underground, before accuracy). Called once the user's
; move is chosen and announced; returns carry if the target's ability took the
; move, having said so and done what the ability does.
AbilityBlocksMove:
	call TakeMoveSnapshot
	call PressureCostsPP
	call MoveBlockedByAbility
	ret nc
	jp hl ; what the battle does about it

; Whether an ability stops the move of the side whose turn it is, without
; messages or changes: carry if so, with hl = what the battle does about it
; (AbilityBlocksMove jumps there) and d = the ability. The trainer AI asks
; this too (AIMoveBlockedByAbility).
MoveBlockedByAbility:
; Damp, on either mon, stops Explosion and Self-Destruct
	ld a, wPlayerMoveEffect - wPlayerMoveNum
	call GetUserMoveField
	cp EXPLODE_EFFECT
	jr nz, .notExplosion
	call UserAbility
	ld hl, AbilityUserDamp
	cp DAMP
	jr z, .blocked
	call TargetAbilityForMove
	ld hl, AbilityTargetDamp
	cp DAMP
	jr z, .blocked
.notExplosion
	ld hl, wEnemyBattleStatus1
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotTargetStatus
	ld hl, wPlayerBattleStatus1
.gotTargetStatus
	bit INVULNERABLE, [hl]
	ret nz ; the move misses as usual (carry is clear after the and)
	call TargetAbilityForMove
	ret z
	ld d, a ; d = the target's ability
	call GetUserMove
	ld a, [hl] ; move
	ld e, a ; e = move
	cp STRUGGLE
	ret z ; and carry clear
	call GetMoveFlags
	ld hl, AbilityDoesntAffect
	bit MOVE_SOUND_F, a
	jr z, .notSound
	ld a, d
	cp SOUNDPROOF
	jr z, .blockedD
.notSound
	ld a, d
	cp STURDY
	jr nz, .notSturdy
	ld a, wPlayerMoveEffect - wPlayerMoveNum
	call GetUserMoveField
	cp OHKO_EFFECT
	ld hl, AbilityDoesntAffect
	jr z, .blockedD
.notSturdy
; the rest go by type, for moves that hit the target: damaging moves and
; Thunder Wave, the one status move of those types that targets the foe
	call GetUserMove
	ld a, e
	cp THUNDER_WAVE
	jr z, .targetsFoe
	ld bc, wPlayerMovePower - wPlayerMoveNum
	add hl, bc
	ld a, [hl]
	and a
	jr z, .statusMove
.targetsFoe
	call GetUserMove
	ld bc, wPlayerMoveType - wPlayerMoveNum
	add hl, bc
	ld e, [hl] ; e = the move's type
	ld hl, AbilityImmunities
.loop
	ld a, [hli]
	and a
	jr z, .statusMove
	cp d
	jr nz, .next
	ld a, [hl]
	cp e
	jr z, .found
.next
	inc hl
	inc hl
	inc hl
	jr .loop
.found
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
.blockedD
	ld a, d
.blocked
	ld d, a
	scf
	ret

; status moves: the conditions and stat drops abilities keep off (a damaging
; move's side effect is only kept off, in AbilitySideEffectChance)
.statusMove
	ld a, wPlayerMovePower - wPlayerMoveNum
	call GetUserMoveField
	and a
	ret nz ; carry clear
	ld a, wPlayerMoveEffect - wPlayerMoveNum
	call GetUserMoveField
	call GetEffectKind
	call AbilityPreventsEffect
	ld hl, AbilityDoesntAffect
	jr c, .blockedD
	and a
	ret

; The trainer AI's question, with MoveBlockedByAbility's answer: would the
; other mon's ability stop the enemy's move (as ReadMove read it), or the
; player's? Carry if so. Nothing is printed or changed.
AIEnemyMoveBlocked:
	ld a, 1
	jr AIMoveBlocked

AIPlayerMoveBlocked:
	xor a
AIMoveBlocked:
	ld hl, H_WHOSETURN
	ld b, [hl]
	ld [hl], a
	push bc
	call MoveBlockedByAbility
	pop bc
	ld a, b
	ld [H_WHOSETURN], a
	ret

AbilityUserDamp:
	call PrintUserAbilityActivated
	jr AbilityCantUse

AbilityTargetDamp:
	call PrintAbilityActivated
AbilityCantUse:
	ld hl, AbilityCantUseMoveText
	call PrintText
	scf
	ret

AbilityImmunities: ; ability, the type it takes, what it does
	db LEVITATE, GROUND
	dw AbilityDoesntAffect
	db VOLT_ABSORB, ELECTRIC
	dw AbilityHealsTarget
	db WATER_ABSORB, WATER
	dw AbilityHealsTarget
	db DRY_SKIN, WATER
	dw AbilityHealsTarget
	db LIGHTNING_ROD, ELECTRIC
	dw AbilityRaisesSpecialAttack
	db FLASH_FIRE, FIRE
	dw AbilityFlashFire
	db 0

; "<TARGET>'s <ability>!", for the target's ability (d)
PrintAbilityActivated:
	ld a, d
	call GetAbilityName
	ld hl, AbilityActivatedText
	jp PrintText

; "<USER>'s <ability>!", for the user's ability (d)
PrintUserAbilityActivated:
	ld a, d
	call GetAbilityName
	ld hl, AbilityActivatedUserText
	jp PrintText

; What a move effect does to the target, for the abilities that keep it off.
; a = move effect -> b = EFFECT_KIND_* bits (0 for none of them), and for stat
; drops c = the MOD_* index of the stat
GetEffectKind:
	ld b, a
	ld hl, EffectKinds
.find
	ld a, [hli]
	cp -1
	jr z, .notListed
	cp b
	jr z, .found
	inc hl
	jr .find
.found
	ld b, [hl]
	ret
.notListed
	ld a, b
	ld bc, 0
; stat drops, by range
	cp ATTACK_DOWN1_EFFECT
	jr c, .none
	cp EVASION_DOWN1_EFFECT + 1
	jr c, .downStage1
	cp ATTACK_DOWN2_EFFECT
	jr c, .none
	cp EVASION_DOWN2_EFFECT + 1
	jr c, .downStage2
	cp ATTACK_DOWN_SIDE_EFFECT
	jr c, .none
	cp SPECIAL_DOWN_SIDE_EFFECT + 1
	jr c, .downSide
	cp SPECIAL_DEFENSE_DOWN_SIDE_EFFECT
	jr nz, .none
	ld c, MOD_SPECIAL_DEFENSE
	jr .statDrop
.downStage1
	sub ATTACK_DOWN1_EFFECT
	jr .gotStat
.downStage2
	sub ATTACK_DOWN2_EFFECT
	jr .gotStat
.downSide
	sub ATTACK_DOWN_SIDE_EFFECT
.gotStat
	ld c, a
.statDrop
	ld b, EFFECT_KIND_STAT_DROP
.none
	ret

EffectKinds:
	db SLEEP_EFFECT, EFFECT_KIND_SLEEP
	db POISON_EFFECT, EFFECT_KIND_POISON
	db POISON_SIDE_EFFECT1, EFFECT_KIND_POISON
	db POISON_SIDE_EFFECT2, EFFECT_KIND_POISON
	db TWINEEDLE_EFFECT, EFFECT_KIND_POISON
	db BURN_SIDE_EFFECT1, EFFECT_KIND_BURN
	db BURN_SIDE_EFFECT2, EFFECT_KIND_BURN
	db PARALYZE_EFFECT, EFFECT_KIND_PARALYSIS
	db PARALYZE_SIDE_EFFECT1, EFFECT_KIND_PARALYSIS
	db PARALYZE_SIDE_EFFECT2, EFFECT_KIND_PARALYSIS
	db CONFUSION_EFFECT, EFFECT_KIND_CONFUSION
	db CONFUSION_SIDE_EFFECT, EFFECT_KIND_CONFUSION
	db FLINCH_SIDE_EFFECT1, EFFECT_KIND_FLINCH
	db FLINCH_SIDE_EFFECT2, EFFECT_KIND_FLINCH
	db -1

; d = the target's ability, b = EFFECT_KIND_* bits, c = MOD_* for a stat drop
; -> carry if the ability keeps the effect off; preserves bc and de
AbilityPreventsEffect:
	ld a, b
	and a
	ret z
	ld hl, EffectImmunities
.loop
	ld a, [hli]
	and a
	ret z ; carry clear
	cp d
	jr nz, .next
	ld a, [hl]
	and b
	jr z, .next
	inc hl
	ld a, [hl]
	dec hl
	cp $ff
	jr z, .prevented ; any stat
	cp c
	jr z, .prevented
.next
	inc hl
	inc hl
	jr .loop
.prevented
	scf
	ret

EffectImmunities: ; ability, EFFECT_KIND_* it keeps off, which stat ($ff any)
	db INSOMNIA, EFFECT_KIND_SLEEP, $ff
	db VITAL_SPIRIT, EFFECT_KIND_SLEEP, $ff
	db IMMUNITY, EFFECT_KIND_POISON, $ff
	db WATER_VEIL, EFFECT_KIND_BURN, $ff
	db LIMBER, EFFECT_KIND_PARALYSIS, $ff
	db OWN_TEMPO, EFFECT_KIND_CONFUSION, $ff
	db INNER_FOCUS, EFFECT_KIND_FLINCH, $ff
	db CLEAR_BODY, EFFECT_KIND_STAT_DROP, $ff
	db HYPER_CUTTER, EFFECT_KIND_STAT_DROP, MOD_ATTACK
	db KEEN_EYE, EFFECT_KIND_STAT_DROP, MOD_ACCURACY
	db ILLUMINATE, EFFECT_KIND_STAT_DROP, MOD_ACCURACY
	db 0

; A damaging move's side effect, about to be rolled (wSideEffectChance out of
; 256): none past Shield Dust or an ability that keeps it off, and twice the
; chance with Serene Grace
AbilitySideEffectChance:
	call TargetAbilityForMove
	ld d, a
	cp SHIELD_DUST
	jr z, .none
	ld a, wPlayerMoveEffect - wPlayerMoveNum
	call GetUserMoveField
	call GetEffectKind
	call AbilityPreventsEffect
	jr c, .none
	call UserAbility
	cp SERENE_GRACE
	ret nz
	ld hl, wSideEffectChance
	sla [hl]
	ret nc
	ld [hl], $ff
	ret
.none
	xor a
	ld [wSideEffectChance], a
	ret

AbilityDoesntAffect:
	call PrintAbilityActivated
.printed
	ld hl, AbilityDoesntAffectText
	call PrintText
	scf
	ret

; HealMon and HurtMon change a mon's HP by bc and animate its HP bar
; a = 0 for the player's mon or 1 for the enemy's; HealMon stops at max HP,
; HurtMon at 0
HealMon:
	call GetMonHPForBar
	add hl, bc
	ld a, l
	sub e
	ld a, h
	sbc d
	jr c, SetMonHPForBar
	ld h, d
	ld l, e ; max HP
	jr SetMonHPForBar
HurtMon:
	call GetMonHPForBar
	ld a, l
	sub c
	ld l, a
	ld a, h
	sbc b
	ld h, a
	jr nc, SetMonHPForBar
	ld hl, 0
	; fall through
; hl = the new HP, for the mon GetMonHPForBar chose
SetMonHPForBar:
	pop de ; the HP's address
	ld a, h
	ld [de], a
	ld [wHPBarNewHP + 1], a
	inc de
	ld a, l
	ld [de], a
	ld [wHPBarNewHP], a
	ld a, [wHPBarType]
	and a
	coord hl, 2, 2 ; the enemy's HP bar
	jr z, .gotBar
	coord hl, 10, 9 ; the player's
.gotBar
	predef UpdateHPBar2
	callab DrawHUDsAndHPBars
	ret

; a = side -> hl = its HP, de = its max HP, the HP bar set up for the side,
; and the HP's address under the return address on the stack
GetMonHPForBar:
	and a
	ld hl, wEnemyMonHP
	ld a, 0 ; the enemy's HP bar
	jr nz, .gotSide
	ld hl, wBattleMonHP
	inc a ; the player's
.gotSide
	ld [wHPBarType], a
	pop de ; return address
	push hl ; the HP's address, for SetMonHPForBar
	push de
	ld a, [hli]
	ld d, a
	ld a, [hl]
	ld e, a
	push de ; HP
	ld de, (wBattleMonMaxHP + 1) - (wBattleMonHP + 1)
	add hl, de
	ld a, [hld]
	ld e, a
	ld [wHPBarMaxHP], a
	ld a, [hl]
	ld d, a ; de = max HP
	ld [wHPBarMaxHP + 1], a
	pop hl ; HP
	ld a, l
	ld [wHPBarOldHP], a
	ld a, h
	ld [wHPBarOldHP + 1], a
	ret

; heals the target by 1/4 of its max HP
AbilityHealsTarget:
	call PrintAbilityActivated
	ld hl, wEnemyMonHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotTarget
	ld hl, wBattleMonHP
.gotTarget
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a ; bc = HP
	ld de, wBattleMonMaxHP - (wBattleMonHP + 2)
	add hl, de
	ld a, [hli]
	cp b
	jr nz, .notFull
	ld a, [hl]
	cp c
	jp z, AbilityDoesntAffect.printed
.notFull
	dec hl
	ld a, [hli]
	ld b, a
	ld c, [hl]
	srl b
	rr c
	srl b
	rr c ; bc = max HP / 4
	ld a, b
	or c
	jr nz, .gotAmount
	inc c ; at least 1
.gotAmount
	ld a, [H_WHOSETURN]
	xor 1
	call HealMon
	ld hl, AbilityRegainedHealthText
	call PrintText
	scf
	ret

; Lightning Rod: the target's special attack goes up a stage
AbilityRaisesSpecialAttack:
	call PrintAbilityActivated
	ld a, [H_WHOSETURN]
	xor 1
	ld c, MOD_SPECIAL_ATTACK
	ld b, 1
	call ChangeStatStage
	jp c, AbilityDoesntAffect.printed ; already +6
	ld hl, AbilitySpecialAttackRoseText
	call PrintText
	scf
	ret

; Flash Fire: the target's fire moves get stronger until it leaves
AbilityFlashFire:
	call PrintAbilityActivated
	ld hl, wAbilityFlags
	ld a, [H_WHOSETURN]
	and a
	jr z, .enemy
	set FLASH_FIRE_PLAYER_F, [hl]
	jr .done
.enemy
	set FLASH_FIRE_ENEMY_F, [hl]
.done
	ld hl, AbilityFirePowerRoseText
	call PrintText
	scf
	ret

; changes a mon's stat stage and recalculates the stat, as a stat move would
; a = 0 for the player's mon or 1 for the enemy's, c = MOD_* index,
; b = the change (-6 to 6); returns carry if the stage can't move that way
ChangeStatStage:
	and a
	ld hl, wPlayerMonStatMods
	jr z, .gotMods
	ld hl, wEnemyMonStatMods
.gotMods
	push af ; z for the player's mon, and carry clear
	ld a, l
	add c
	ld l, a
	jr nc, .gotMod
	inc h
.gotMod
	ld a, [hl]
	add b
	bit 7, b
	jr nz, .lowering
	cp 13 + 1
	jr c, .gotStage
	ld a, 13
	jr .gotStage
.lowering ; below 1 is 0 or wrapped past it
	bit 7, a
	jr nz, .lowest
	and a
	jr nz, .gotStage
.lowest
	ld a, 1
.gotStage
	cp [hl]
	jp z, .unchanged
	ld [hl], a
	ld b, a ; b = the new stage
; attack, defense, speed and special attack line up with their stages;
; special defense's stage comes after accuracy and evasion
	ld a, c
	cp MOD_SPECIAL_DEFENSE
	jr z, .specialDefense
	cp MOD_ACCURACY
	jp nc, .noStat
	jr .gotStat
.specialDefense
	ld a, STAT_SPECIAL_DEFENSE - STAT_ATTACK
.gotStat
	ld c, a ; c = the stat, counted from attack
	pop af
	push af
	ld hl, wBattleMonAttack
	ld de, wPlayerMonUnmodifiedAttack
	jr z, .gotStats
	ld hl, wEnemyMonAttack
	ld de, wEnemyMonUnmodifiedAttack
.gotStats
	ld a, c
	add a
	add l
	ld l, a
	jr nc, .gotStatAddr
	inc h
.gotStatAddr ; hl = the stat
	ld a, c
	add a
	add e
	ld e, a
	jr nc, .gotUnmodifiedAddr
	inc d
.gotUnmodifiedAddr ; de = the stat before stages
	push hl
	ld hl, StatModifierRatios
	ld a, b
	dec a
	add a
	add l
	ld l, a
	jr nc, .gotRatio
	inc h
.gotRatio
	xor a
	ld [H_MULTIPLICAND], a
	ld a, [de]
	ld [H_MULTIPLICAND + 1], a
	inc de
	ld a, [de]
	ld [H_MULTIPLICAND + 2], a
	ld a, [hli]
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, [hl]
	ld [H_DIVISOR], a
	push bc
	ld b, 4
	call Divide
	pop bc
	pop hl
	ld a, [H_QUOTIENT + 3]
	sub 999 % $100
	ld a, [H_QUOTIENT + 2]
	sbc 999 / $100
	jr c, .notCapped
	ld a, 999 / $100
	ld [H_QUOTIENT + 2], a
	ld a, 999 % $100
	ld [H_QUOTIENT + 3], a
.notCapped
; burn halves attack and paralysis quarters speed, as when the stat was made
	pop af
	push af
	push hl
	ld hl, wBattleMonStatus
	jr z, .gotStatus
	ld hl, wEnemyMonStatus
.gotStatus
	ld b, [hl]
	pop hl
	ld a, c
	and a ; attack
	jr nz, .notAttack
	bit BRN, b
	jr z, .gotPenalty
	ld b, 1
	jr .penalty
.notAttack
	cp STAT_SPEED - STAT_ATTACK
	jr nz, .noPenalty
	bit PAR, b
	jr z, .noPenalty
	ld b, 2
.penalty
	ld a, [H_QUOTIENT + 2]
	srl a
	ld [H_QUOTIENT + 2], a
	ld a, [H_QUOTIENT + 3]
	rra
	ld [H_QUOTIENT + 3], a
	dec b
	jr nz, .penalty
	jr .gotPenalty
.noPenalty
.gotPenalty
	ld a, [H_QUOTIENT + 2]
	ld [hli], a
	ld b, a
	ld a, [H_QUOTIENT + 3]
	ld [hl], a
	or b
	jr nz, .notZero
	inc [hl] ; at least 1
.notZero
	pop af
	ret nz ; carry clear
; the player's mon gets its badge boost back on the recalculated stat
	ld a, c
	cp STAT_SPECIAL_DEFENSE - STAT_ATTACK
	jr nz, .gotBadgeMod
	ld a, MOD_SPECIAL_DEFENSE
.gotBadgeMod
	inc a
	ld [wUnusedD71B], a ; the one stat ApplyBadgeStatBoosts boosts
	callab ApplyBadgeStatBoosts
	and a
	ret
.noStat
	pop af
	and a
	ret
.unchanged
	pop af
	scf
	ret

; the damage modifiers abilities make (damage pipeline stage S3), applied once
; to the damage after type effectiveness and before the random factor
AbilityDamageModifiers:
	ld a, [wUnusedC000]
	bit 4, a
	ret nz ; fixed-damage moves
	ld hl, wDamage
	ld a, [hli]
	or [hl]
	ret z
	callab ItemDamageModifiers
	call UserAbility
	call nz, .userAbility
	call TargetAbilityForMove
	ret z
; the target's
	ld d, a
	ld a, wPlayerMoveType - wPlayerMoveNum
	call GetUserMoveField
	ld e, a
	ld a, d
	cp THICK_FAT
	jr nz, .notThickFat
	ld a, e
	cp FIRE
	jr z, .halve
	cp ICE
	ret nz
.halve
	lb bc, 1, 2
	jp ScaleDamage
.notThickFat
	cp FILTER
	jr nz, .notFilter
	ld a, [wDamageMultipliers]
	and $7f
	cp 10 + 1
	ret c
	lb bc, 3, 4
	jp ScaleDamage
.notFilter
	cp DRY_SKIN
	ret nz
	ld a, e
	cp FIRE
	ret nz
	lb bc, 5, 4
	jp ScaleDamage

.userAbility
	ld d, a
	ld hl, UserDamageAbilities
.findUserAbility
	ld a, [hli]
	and a
	ret z
	cp d
	jr z, .foundUserAbility
	inc hl
	inc hl
	jr .findUserAbility
.foundUserAbility
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld a, wPlayerMoveType - wPlayerMoveNum
	call GetUserMoveField
	ld e, a ; e = the move's type
	ret ; to the ability's check, which scales the damage if it applies

UserDamageAbilities:
	dbw TECHNICIAN, .technician
	dbw IRON_FIST, .ironFist
	dbw RECKLESS, .reckless
	dbw ADAPTABILITY, .adaptability
	dbw TINTED_LENS, .tintedLens
	dbw SNIPER, .sniper
	dbw GUTS, .guts
	dbw OVERGROW, .overgrow
	dbw BLAZE, .blaze
	dbw TORRENT, .torrent
	dbw SWARM, .swarm
	dbw FLASH_FIRE, .flashFire
	dbw RIVALRY, .rivalry
	db 0

.technician
	ld a, wPlayerMovePower - wPlayerMoveNum
	call GetUserMoveField
	cp 60 + 1
	ret nc
	jp .oneAndAHalf
.ironFist
	xor a ; the move
	call GetUserMoveField
	call GetMoveFlags
	bit MOVE_PUNCH_F, a
	ret z
	jr .oneAndAFifth
.reckless
	xor a ; the move
	call GetUserMoveField
	cp STRUGGLE
	ret z
	ld a, wPlayerMoveEffect - wPlayerMoveNum
	call GetUserMoveField
	cp RECOIL_EFFECT
	jr z, .oneAndAFifth
	cp JUMP_KICK_EFFECT
	ret nz
.oneAndAFifth
	lb bc, 6, 5
	jp ScaleDamage
.adaptability ; same-type bonus of 2 instead of 1.5
	ld a, [wDamageMultipliers]
	bit 7, a
	ret z
	lb bc, 4, 3
	jp ScaleDamage
.tintedLens
	ld a, [wDamageMultipliers]
	and $7f
	cp 10
	ret nc
	lb bc, 2, 1
	jp ScaleDamage
.sniper
	ld a, [wCriticalHitOrOHKO]
	dec a
	ret nz
	jr .oneAndAHalf
.guts ; physical moves, when the user has a status condition; and burn doesn't
      ; halve its attack (undone here, except on critical hits, which use the
      ; stats from before burn)
	ld a, [hBattleSide]
	and BATTLE_SIDE_SPECIAL
	ret nz
	ld hl, wBattleMonStatus
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotStatus
	ld hl, wEnemyMonStatus
.gotStatus
	ld a, [hl]
	and a
	ret z
	bit BRN, a
	jr z, .oneAndAHalf
	ld a, [wCriticalHitOrOHKO]
	and a
	jr nz, .oneAndAHalf
	lb bc, 3, 1 ; 1.5, times 2 for the burn
	jp ScaleDamage
.overgrow
	ld a, GRASS
	jr .pinch
.blaze
	ld a, FIRE
	jr .pinch
.torrent
	ld a, WATER
	jr .pinch
.swarm
	ld a, BUG
.pinch ; moves of type a, at 1/3 of max HP or less
	cp e
	ret nz
	ld hl, wBattleMonHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotHP
	ld hl, wEnemyMonHP
.gotHP
	ld a, [hli]
	ld b, a
	ld c, [hl] ; bc = HP
	ld de, wBattleMonMaxHP - (wBattleMonHP + 1)
	add hl, de
	ld a, [hli]
	ld d, a
	ld e, [hl] ; de = max HP
	ld h, b
	ld l, c
	add hl, hl
	add hl, bc ; hl = 3 x HP
	ld a, e
	sub l
	ld a, d
	sbc h
	ret c ; 3 x HP > max HP
	jr .oneAndAHalf
.rivalry ; x5/4 against the same gender, x3/4 against the other, nothing if
         ; either has none
	xor a
	call GetBattleMonGender
	and a
	ret z
	push af
	ld a, 1
	call GetBattleMonGender
	pop bc ; b = the player's mon's gender
	and a
	ret z
	cp b
	lb bc, 5, 4
	jp z, ScaleDamage
	lb bc, 3, 4
	jp ScaleDamage
.flashFire
	ld a, e
	cp FIRE
	ret nz
	ld a, [H_WHOSETURN]
	and a
	ld a, [wAbilityFlags]
	jr z, .gotFlag
	rrca
.gotFlag
	bit FLASH_FIRE_PLAYER_F, a
	ret z
.oneAndAHalf
	lb bc, 3, 2
	; fall through

; damage = damage x b / c, at least 1 and at most $ffff
ScaleDamage:
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
	ld b, a
	ld a, [H_QUOTIENT + 3]
	ld [wDamage + 1], a
	or b
	ret nz
	ld a, 1
	ld [wDamage + 1], a
	ret
.max
	ld a, $ff
	ld [wDamage], a
	ld [wDamage + 1], a
	ret

; CalcHitChance from the battle engine, with abilities: Keen Eye and
; Illuminate ignore the target's raised evasion, Compound Eyes raises accuracy
; by 3/10, Tangled Feet halves it when its holder is confused, and No Guard on
; either mon makes every move hit
CalcHitChance_:
	ld hl, wPlayerMoveAccuracy
	ld a, [H_WHOSETURN]
	and a
	ld a, [wPlayerMonAccuracyMod]
	ld b, a
	ld a, [wEnemyMonEvasionMod]
	ld c, a
	jr z, .next
; values for enemy turn
	ld hl, wEnemyMoveAccuracy
	ld a, [wEnemyMonAccuracyMod]
	ld b, a
	ld a, [wPlayerMonEvasionMod]
	ld c, a
.next
	push hl
	call UserAbility
	pop hl
	cp KEEN_EYE
	jr z, .ignoreEvasion
	cp ILLUMINATE
	jr nz, .gotEvasion
.ignoreEvasion
	ld a, c
	cp 7 + 1
	jr c, .gotEvasion
	ld c, 7
.gotEvasion
	ld a, $0e
	sub c
	ld c, a ; c = 14 - EVASIONMOD (this "reflects" the value over 7, so that an increase in the target's evasion
	       ; decreases the hit chance instead of increasing the hit chance)
; zero the high bytes of the multiplicand
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND + 1], a
	ld a, [hl]
	ld [H_MULTIPLICAND + 2], a ; set multiplicand to move accuracy
	push hl
	ld d, $02 ; loop has two iterations
; loop to do the calculations, the first iteration multiplies by the accuracy ratio and
; the second iteration multiplies by the evasion ratio
.loop
	push bc
	ld hl, StatModifierRatios  ; stat modifier ratios
	dec b
	sla b
	ld c, b
	ld b, $00
	add hl, bc ; hl = address of stat modifier ratio
	pop bc
	ld a, [hli]
	ld [H_MULTIPLIER], a ; set multiplier to the numerator of the ratio
	call Multiply
	ld a, [hl]
	ld [H_DIVISOR], a ; set divisor to the the denominator of the ratio
	                 ; (the dividend is the product of the previous multiplication)
	ld b, $04 ; number of bytes in the dividend
	call Divide
	ld a, [H_QUOTIENT + 3]
	ld b, a
	ld a, [H_QUOTIENT + 2]
	or b
	jp nz, .nextCalculation
; make sure the result is always at least one
	ld [H_QUOTIENT + 2], a
	ld a, $01
	ld [H_QUOTIENT + 3], a
.nextCalculation
	ld b, c
	dec d
	jr nz, .loop
	ld a, [H_QUOTIENT + 2]
	and a ; is the calculated hit chance over 0xFF?
	ld a, [H_QUOTIENT + 3]
	jr z, .storeAccuracy
; if calculated hit chance over 0xFF
	ld a, $ff ; set the hit chance to 0xFF
.storeAccuracy
	pop hl
	ld [hl], a ; store the hit chance in the move accuracy variable
	call NoGuardActive
	jr c, .alwaysHits
	call UserAbility
	cp COMPOUND_EYES
	jr nz, .notCompoundEyes
	lb bc, 13, 10
	call .scale
.notCompoundEyes
	call TargetItem
	cp BRIGHTPOWDER
	jr nz, .notBrightPowder
	lb bc, 9, 10
	call .scale
.notBrightPowder
	call TargetAbilityForMove
	cp TANGLED_FEET
	ret nz
	ld a, [H_WHOSETURN]
	and a
	ld a, [wEnemyBattleStatus1]
	jr z, .gotTargetStatus
	ld a, [wPlayerBattleStatus1]
.gotTargetStatus
	bit CONFUSED, a
	ret z
	srl [hl]
	ret nz
	inc [hl] ; at least 1
	ret
.alwaysHits
	ld [hl], $ff ; a hit chance of 255 never misses
	ret
; [hl] = [hl] x b / c, at most 255
.scale
	push hl
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND + 1], a
	ld a, [hl]
	ld [H_MULTIPLICAND + 2], a
	ld a, b
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, c
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	pop hl
	ld a, [H_QUOTIENT + 2]
	and a
	ld a, [H_QUOTIENT + 3]
	jr z, .scaled
	ld a, $ff
.scaled
	ld [hl], a
	ret

; Before a move: the target's HP, status and stat stages, for the abilities
; that react to what the move did (AbilityAfterMove)
TakeMoveSnapshot:
	ld de, wAbilitySnapshot
	ld a, 1 << SNAPSHOT_TAKEN_F
	ld [de], a
	inc de
	ld hl, wEnemyMonHP
	ld bc, wEnemyMonStatMods
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotTarget
	ld hl, wBattleMonHP
	ld bc, wPlayerMonStatMods
.gotTarget
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	inc de
	inc hl ; party position
	ld a, [hl] ; status
	ld [de], a
	inc de
	ld h, b
	ld l, c
	ld bc, NUM_STAT_MODS
	jp CopyData

; Pressure: a move aimed at it costs one more PP
PressureCostsPP:
	call TargetAbility
	cp PRESSURE
	ret nz
	call MoveTargetsFoe
	ret nc
	xor a ; the move
	call GetUserMoveField
	cp STRUGGLE
	ret z
	ld a, [H_WHOSETURN]
	and a
	jr nz, .enemy
	ld a, [wPlayerMoveListIndex]
	ld c, a
	ld b, 0
	ld hl, wBattleMonPP
	add hl, bc
	ld a, [hl]
	and %00111111 ; without PP Ups
	ret z
	ld de, wPlayerSelectedMove
	callab DecrementPP
	ret
.enemy
	ld a, [wEnemyMoveListIndex]
	ld c, a
	ld b, 0
	ld hl, wEnemyMonPP
	add hl, bc
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret

; carry if the user's move is aimed at the foe: a damaging move, a status
; move that does something to it, or one of the few that act on it
MoveTargetsFoe:
	ld a, wPlayerMovePower - wPlayerMoveNum
	call GetUserMoveField
	and a
	jr nz, .yes
	ld a, wPlayerMoveEffect - wPlayerMoveNum
	call GetUserMoveField
	ld e, a
	call GetEffectKind
	ld a, b
	and a
	jr nz, .yes
	ld a, e
	ld hl, FoeTargetingEffects
	ld de, 1
	call IsInArray
	ret c
	xor a ; the move
	call GetUserMoveField
	cp ROAR
	jr z, .yes
	cp WHIRLWIND
	jr z, .yes
	and a
	ret
.yes
	scf
	ret

FoeTargetingEffects:
	db LEECH_SEED_EFFECT, DISABLE_EFFECT, MIMIC_EFFECT, TRANSFORM_EFFECT
	db -1

; a random number, the way the battle draws them (BattleRandom: in a link
; battle, from the shared list)
AbilityRandom:
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jp nz, Random
	push hl
	push bc
	ld a, [wLinkBattleRandomNumberListIndex]
	ld c, a
	ld b, 0
	ld hl, wLinkBattleRandomNumberList
	add hl, bc
	inc a
	ld [wLinkBattleRandomNumberListIndex], a
	cp 9
	ld a, [hl]
	pop bc
	pop hl
	ret c
; the last of the nine: make the next nine
	push hl
	push bc
	push af
	xor a
	ld [wLinkBattleRandomNumberListIndex], a
	ld hl, wLinkBattleRandomNumberList
	ld b, 9
.loop
	ld a, [hl]
	ld c, a
	add a
	add a
	add c
	inc a
	ld [hli], a
	dec b
	jr nz, .loop
	pop af
	pop bc
	pop hl
	ret

; carry if either mon has No Guard
NoGuardActive:
	xor a
	call GetSideAbility
	cp NO_GUARD
	jr z, .yes
	ld a, 1
	call GetSideAbility
	cp NO_GUARD
	jr z, .yes
	and a
	ret
.yes
	scf
	ret

; Sturdy: at full HP, a hit from the foe that would knock it out leaves it 1 HP.
; Called as damage is applied to the mon on side hBattleSide
SturdyEndure:
	ld a, [hBattleSide]
	and BATTLE_SIDE_ENEMY
	ld e, a ; e = the side taking the damage
	ld a, [H_WHOSETURN]
	cp e
	ret z ; its own move: recoil, a crash, confusion
	ld hl, wBattleMonHP
	ld a, e
	and a
	jr z, .gotMon
	ld hl, wEnemyMonHP
.gotMon
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a ; bc = HP
	push hl
	ld hl, wDamage + 1
	ld a, [hld]
	sub c
	ld a, [hl]
	sbc b
	pop hl
	ret c ; the mon survives anyway
	ld d, 1 ; d = at full HP
	push de
	ld de, wBattleMonMaxHP - (wBattleMonHP + 2)
	add hl, de
	pop de
	ld a, [hli]
	cp b
	jr nz, .notFull
	ld a, [hl]
	cp c
	jr z, .gotFull
.notFull
	ld d, 0
.gotFull
; Sturdy, at full HP
	ld a, d
	and a
	jr z, .notSturdy
	ld a, e
	call GetSideAbility
	cp STURDY
	jr nz, .notSturdy
	ld a, e
	xor 1
	call GetSideAbility
	cp MOLD_BREAKER
	ld a, 0 ; Sturdy, not an item
	jr nz, .endure
.notSturdy
	ld a, e
	call GetSideItem
	cp FOCUS_SASH
	jr nz, .notSash
	ld a, d
	and a
	ret z
	push bc
	ld a, e
	call ConsumeSideItem
	pop bc
	ld a, FOCUS_SASH
	jr .endure
.notSash
	cp FOCUS_BAND
	ret nz
	call AbilityRandom
	cp 26 ; 10%
	ret nc
	ld a, FOCUS_BAND
.endure
	ld [wEnduredBy], a
	dec bc
	ld hl, wDamage
	ld a, b
	ld [hli], a
	ld [hl], c ; damage = HP - 1
	ld hl, wAbilityFlags
	set STURDY_ENDURED_F, [hl]
	ret

; Magic Guard: no damage from poison, burn or Leech Seed. Called before them
; for the mon whose turn it is; returns carry to skip them, with z if it has
; fainted anyway (so the battle sees it)
AbilityResidual:
	callab ItemResidual ; Leftovers, berries
	call UserAbility
	cp MAGIC_GUARD
	jr z, .magicGuard
	cp SHED_SKIN
	jr z, .shedSkin
	cp EARLY_BIRD
	jr z, .earlyBird
.done
	and a
	ret
; Shed Skin: a 1/3 chance each turn to shed its status
.shedSkin
	ld d, a
	call GetUserStatus
	and a
	ret z ; carry clear
	call AbilityRandom
	cp 85 + 1 ; 1/3
	jr nc, .done
	callab UndoBurnParStats ; while the status still says which
	call GetUserStatus
	ld [hl], 0
	ld hl, wPlayerBattleStatus3
	ld de, wPlayerToxicCounter
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotToxic
	ld hl, wEnemyBattleStatus3
	ld de, wEnemyToxicCounter
.gotToxic
	res BADLY_POISONED, [hl]
	xor a
	ld [de], a
	ld d, SHED_SKIN
	call PrintUserAbilityActivated
	ld hl, AbilityCuredUserText
	call PrintText
	and a
	ret
; Early Bird: wakes up twice as fast (one more turn off the count, never the
; last one, so it wakes up as usual)
.earlyBird
	call GetUserStatus
	and SLP
	cp 2
	jr c, .done
	dec [hl]
	and a
	ret
.magicGuard
	ld hl, wBattleMonHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotHP
	ld hl, wEnemyMonHP
.gotHP
	ld a, [hli]
	or [hl]
	scf
	ret

; a = the status of the mon whose turn it is, hl = its address
GetUserStatus:
	ld hl, wBattleMonStatus
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotStatus
	ld hl, wEnemyMonStatus
.gotStatus
	ld a, [hl]
	ret

; Natural Cure: leaving the battle cures its status. Called as the player's or
; the enemy's mon is withdrawn, before its status goes back to the party
NaturalCurePlayer:
	xor a
	call GetSideAbility
	cp NATURAL_CURE
	ret nz
	xor a
	ld [wBattleMonStatus], a
	ld a, [wPlayerMonNumber]
	ld hl, wPartyMon1Status
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld [hl], 0
	ret
NaturalCureEnemy:
	ld a, 1
	call GetSideAbility
	cp NATURAL_CURE
	ret nz
	xor a
	ld [wEnemyMonStatus], a
	ret

; Leech Seed on a mon with Liquid Ooze hurts the seeder by what it would have
; healed: 1/16 of the seeded mon's max HP, at least 1, as the seeded mon (whose
; turn it is) lost. Called as the seeder would heal; returns carry if it did
; this.
LiquidOozeLeechSeed:
	call UserAbility
	cp LIQUID_OOZE
	jr nz, .no
	ld d, a
	ld hl, wBattleMonMaxHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotMaxHP
	ld hl, wEnemyMonMaxHP
.gotMaxHP
	ld a, [hli]
	ld b, a
	ld c, [hl]
	ld a, 4
.divideBy16
	srl b
	rr c
	dec a
	jr nz, .divideBy16
	ld a, b
	or c
	jr nz, .gotAmount
	inc c
.gotAmount
	push bc
	call PrintUserAbilityActivated
	pop bc
	call TargetAbility
	cp MAGIC_GUARD
	jr z, .done
	ld a, [H_WHOSETURN]
	xor 1
	call HurtMon
	ld hl, SuckedUpOozeTargetText
	call PrintText
.done
	scf
	ret
.no
	and a
	ret

; A drain move into Liquid Ooze hurts the user by what it would have healed
; (half the damage, at least 1). Returns carry if it did this.
LiquidOozeDrain:
	call TargetAbility ; Mold Breaker doesn't stop it
	cp LIQUID_OOZE
	jr nz, LiquidOozeLeechSeed.no
	ld d, a
	call PrintAbilityActivated
	call UserAbility
	cp MAGIC_GUARD
	jr z, LiquidOozeLeechSeed.done
	ld hl, wDamage
	ld a, [hli]
	ld b, a
	ld c, [hl]
	srl b
	rr c
	ld a, b
	or c
	jr nz, .gotAmount
	inc c
.gotAmount
	ld a, [H_WHOSETURN]
	call HurtMon
	ld hl, SuckedUpOozeUserText
	call PrintText
	scf
	ret

; carry if the user takes no recoil: Rock Head (except from Struggle) and
; Magic Guard
RecoilPrevented:
	call UserAbility
	cp MAGIC_GUARD
	jr z, .prevented
	cp ROCK_HEAD
	jr nz, .no
	xor a ; the move
	call GetUserMoveField
	cp STRUGGLE
	jr z, .no
.prevented
	scf
	ret
.no
	and a
	ret

; carry if the user has Magic Guard (no crash damage)
MagicGuardUser:
	call UserAbility
	cp MAGIC_GUARD
	jr z, RecoilPrevented.prevented
	and a
	ret

; carry if the user has Skill Link (two-to-five-hit moves hit five times)
SkillLink:
	call UserAbility
	cp SKILL_LINK
	jr z, RecoilPrevented.prevented
	and a
	ret

; The critical hit rate (out of 256, in wSideEffectChance) after items and
; abilities: Scope Lens doubles it, the Stick (Farfetch'd) and Lucky Punch
; (Chansey) quadruple it, and the target's Battle Armor or Shell Armor stops
; critical hits
CritRateModifiers:
	call UserItem
	ld b, 1
	cp SCOPE_LENS
	jr z, .double
	ld c, FARFETCHD
	cp STICK
	jr z, .species
	ld c, CHANSEY
	cp LUCKY_PUNCH
	jr nz, .armor
.species
	ld hl, wBattleMonSpecies
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotSpecies
	ld hl, wEnemyMonSpecies
.gotSpecies
	ld a, [hl]
	cp c
	jr nz, .armor
	inc b
.double
	ld hl, wSideEffectChance
.doubleLoop
	sla [hl]
	jr nc, .doubled
	ld [hl], $ff
	jr .armor
.doubled
	dec b
	jr nz, .doubleLoop
.armor
	call TargetAbilityForMove
	cp BATTLE_ARMOR
	jr z, .none
	cp SHELL_ARMOR
	ret nz
.none
	xor a
	ld [wSideEffectChance], a
	ret

; carry if the user is using Rest and its Insomnia or Vital Spirit keeps it
; awake
RestPrevented:
	xor a ; the move
	call GetUserMoveField
	cp REST
	jr nz, RecoilPrevented.no
	call UserAbility
	cp INSOMNIA
	jr z, RecoilPrevented.prevented
	cp VITAL_SPIRIT
	jr z, RecoilPrevented.prevented
	and a
	ret

; after the move of the mon whose turn it is
AbilityAfterMove:
	ld hl, wAbilityFlags
	bit STURDY_ENDURED_F, [hl]
	jr z, .notEndured
	res STURDY_ENDURED_F, [hl]
	ld a, [wEnduredBy]
	and a
	jr nz, .item
	call TargetAbility
	ld d, a
	call PrintAbilityActivated
	ld hl, EnduredTheHitText
	call PrintText
	jr .notEndured
.item
	ld [wd11e], a
	call GetItemName
	ld hl, HungOnText
	call PrintText
.notEndured
	ld hl, wAbilitySnapshot
	bit SNAPSHOT_TAKEN_F, [hl]
	ret z ; the mon didn't get to use a move
	ld a, [wEscapedFromBattle]
	and a
	jr nz, .done
; did the move hit the target for damage (even if it fainted)?
	call GetTargetHP
	ld hl, wAbilitySnapshot + 2
	ld a, c
	sub [hl]
	dec hl
	ld a, b
	sbc [hl]
	jr nc, .gotDamaged
	dec hl
	set SNAPSHOT_DAMAGED_F, [hl]
.gotDamaged
	call .abilities
	callab ItemsAfterMove
.done
	xor a
	ld [wAbilitySnapshot], a
	ret
.abilities
	call GetTargetHP
	ld a, b
	or c
	ret z ; it fainted: nothing more happens to it
	call AngerPoint
	call CursedBody
	call Synchronize
	call Competitive
	call Stench
	jp ContactAbilities

; bc = the target's HP (the mon whose turn it isn't)
GetTargetHP:
	ld hl, wEnemyMonHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotHP
	ld hl, wBattleMonHP
.gotHP
	ld a, [hli]
	ld b, a
	ld c, [hl]
	ret

; z if the mon whose turn it is has fainted
UserFainted:
	ld hl, wBattleMonHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotHP
	ld hl, wEnemyMonHP
.gotHP
	ld a, [hli]
	or [hl]
	ret

; nz if the move hit the target for damage
TargetWasDamaged:
	ld a, [wAbilitySnapshot]
	and 1 << SNAPSHOT_DAMAGED_F
	ret

; Anger Point: a critical hit maxes its attack
AngerPoint:
	call TargetAbility
	cp ANGER_POINT
	ret nz
	ld d, a
	call TargetWasDamaged
	ret z
	ld a, [wCriticalHitOrOHKO]
	dec a
	ret nz
	ld a, [H_WHOSETURN]
	xor 1
	lb bc, 12, MOD_ATTACK
	call ChangeStatStage
	ret c ; already maxed
	ld d, ANGER_POINT
	call PrintAbilityActivated
	ld hl, MaxedAttackText
	jp PrintText

; Cursed Body: a 30% chance to disable the move that hit it, for 4 turns
CursedBody:
	call TargetAbility
	cp CURSED_BODY
	ret nz
	ld d, a
	call TargetWasDamaged
	ret z
	call UserFainted
	ret z
	xor a ; the move
	call GetUserMoveField
	cp STRUGGLE
	ret z
	ld e, a ; e = the move
	ld hl, wPlayerDisabledMove
	ld bc, wPlayerMoveListIndex
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotUser
	ld hl, wEnemyDisabledMove
	ld bc, wEnemyMoveListIndex
.gotUser
	ld a, [hl]
	and a
	ret nz ; it already has a move disabled
	call AbilityRandom
	cp 77 ; 30%
	ret nc
	ld a, [bc]
	inc a
	swap a
	or 4 + 8 ; 4 turns, in the disable count's encoding (turns + 8)
	ld [hl], a
	ld hl, wPlayerDisabledMoveNumber
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotNumber
	inc hl ; wEnemyDisabledMoveNumber
.gotNumber
	ld [hl], e
	call PrintAbilityActivated
	ld hl, UserMoveDisabledText
	jp PrintText

; Synchronize: a foe that burns, poisons or paralyzes it gets the same, if it
; can have it
Synchronize:
	call TargetAbility
	cp SYNCHRONIZE
	ret nz
	ld d, a
	ld a, [wAbilitySnapshot + 3] ; the status before the move
	and a
	ret nz
	ld hl, wEnemyMonStatus
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotTargetStatus
	ld hl, wBattleMonStatus
.gotTargetStatus
	ld a, [hl]
	and (1 << PSN) | (1 << BRN) | (1 << PAR)
	ret z
	ld e, [hl] ; e = the new status
; Toxic's bad poison is passed on as bad poison
	bit PSN, e
	jr z, GiveUserStatus
	ld hl, wEnemyBattleStatus3
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotHolder
	ld hl, wPlayerBattleStatus3
.gotHolder
	bit BADLY_POISONED, [hl]
	jr z, GiveUserStatus
	set GIVE_BAD_POISON_F, e
	; fall through

; The target's ability (d) gives the mon whose turn it is the status e (poison,
; burn, paralysis or sleep; with GIVE_BAD_POISON_F, bad poison), if it can have
; it: it isn't fainted or statused already, and neither its types nor its
; ability keep it off. With "<target>'s <ability>!" and the status's message.
GiveUserStatus:
	call UserFainted
	ret z
	call GetUserStatus
	and a
	ret nz ; the foe has a status already
	ld a, e
	ld b, EFFECT_KIND_SLEEP
	ld c, -1
	and SLP
	jr nz, .gotKind
	ld a, e
	ld b, EFFECT_KIND_POISON
	ld c, POISON
	bit PSN, a
	jr nz, .gotKind
	ld b, EFFECT_KIND_BURN
	ld c, FIRE
	bit BRN, a
	jr nz, .gotKind
	ld b, EFFECT_KIND_PARALYSIS
	ld c, ELECTRIC
	bit PAR, a
	ret z
.gotKind ; b = the kind, c = the type that can't have it (-1 for none)
	ld hl, wBattleMonType1
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotUserTypes
	ld hl, wEnemyMonType1
.gotUserTypes
	ld a, [hli]
	cp c
	ret z
	ld a, [hl]
	cp c
	ret z
	push de
	call UserAbility
	ld d, a
	ld c, -1
	call AbilityPreventsEffect
	pop de
	ret c
; the foe takes it, as the mon whose turn it isn't, for the texts and penalties
	call AbilitySwapTurn
	ld hl, wEnemyMonStatus
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotFoeStatus
	ld hl, wBattleMonStatus
.gotFoeStatus
	ld a, e
	res GIVE_BAD_POISON_F, a
	ld [hl], a
	push de
	call PrintUserAbilityActivated
	pop de
	ld a, e
	and SLP
	jr nz, .asleep
	ld a, e
	bit PSN, a
	jr nz, .poisoned
	bit BRN, a
	jr nz, .burned
	callab QuarterSpeedDueToParalysis
	ld hl, SynchronizeParalyzedText
	jr .print
.burned
	callab HalveAttackDueToBurn
	ld hl, SynchronizeBurnedText
	jr .print
.asleep
	ld hl, FellAsleepAbilityText
	jr .print
.poisoned
	bit GIVE_BAD_POISON_F, e
	ld hl, SynchronizePoisonedText
	jr z, .print
; the foe is the mon whose turn it isn't
	ld hl, wEnemyBattleStatus3
	ld de, wEnemyToxicCounter
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotToxic
	ld hl, wPlayerBattleStatus3
	ld de, wPlayerToxicCounter
.gotToxic
	set BADLY_POISONED, [hl]
	xor a
	ld [de], a
	ld hl, SynchronizeBadlyPoisonedText
.print
	call PrintText
	; fall through

AbilitySwapTurn:
	ld a, [H_WHOSETURN]
	xor 1
	ld [H_WHOSETURN], a
	ret

; Static, Poison Point, Flame Body, Effect Spore: a 30% chance that a move
; making contact gives its user a status
ContactAbilities:
	call TargetWasDamaged
	ret z
	xor a ; the move
	call GetUserMoveField
	call GetMoveFlags
	bit MOVE_CONTACT_F, a
	ret z
	call TargetAbility
	ld d, a
	ld e, 1 << PAR
	cp STATIC
	jr z, .roll
	ld e, 1 << PSN
	cp POISON_POINT
	jr z, .roll
	ld e, 1 << BRN
	cp FLAME_BODY
	jr z, .roll
	cp EFFECT_SPORE
	ret nz
; Effect Spore: 11% sleep, 9% poison, 10% paralysis (of 100: the 30%), and
; nothing for Grass types, which powders don't touch
	ld hl, wBattleMonType1
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotTypes
	ld hl, wEnemyMonType1
.gotTypes
	ld a, [hli]
	cp GRASS
	ret z
	ld a, [hl]
	cp GRASS
	ret z
	call AbilityRandom
	ld e, 3 ; asleep for 3 turns
	cp 28 ; 11%
	jp c, GiveUserStatus
	ld e, 1 << PSN
	cp 28 + 23 ; 9%
	jp c, GiveUserStatus
	ld e, 1 << PAR
	cp 28 + 23 + 26 ; 10%
	jp c, GiveUserStatus
	ret
.roll
	call AbilityRandom
	cp 77 ; 30%
	ret nc
	jp GiveUserStatus

; a = 0 for the player's mon or 1 for the enemy's -> a = 0 genderless,
; 1 male, 2 female (from its species and attack DV, as the status screen shows)
GetBattleMonGender:
	ld hl, wBattleMonSpecies
	and a
	jr z, .gotMon
	ld hl, wEnemyMonSpecies
.gotMon
	ld d, [hl]
	ld bc, wBattleMonDVs - wBattleMonSpecies
	add hl, bc
	ld a, [hl]
	swap a
	and $f
	ld e, a ; attack DV
	callba DetermineMonGender
	ld a, d
	and a
	ret z
	cp $ef ; the male symbol
	ld a, 1
	ret z
	inc a
	ret

; Competitive: a foe's move lowering any of its stats raises its special
; attack two stages
Competitive:
	call TargetAbility
	cp COMPETITIVE
	ret nz
	ld d, a
	ld a, wPlayerMoveEffect - wPlayerMoveNum
	call GetUserMoveField
	cp HAZE_EFFECT
	ret z ; Haze resets stages, it doesn't lower them
	ld hl, wEnemyMonStatMods
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotMods
	ld hl, wPlayerMonStatMods
.gotMods
	ld de, wAbilitySnapshot + 4
	ld b, NUM_STAT_MODS
.loop
	ld a, [de]
	cp [hl]
	jr z, .next
	jr nc, .lowered
.next
	inc de
	inc hl
	dec b
	jr nz, .loop
	ret
.lowered
	ld a, [H_WHOSETURN]
	xor 1
	lb bc, 2, MOD_SPECIAL_ATTACK
	call ChangeStatStage
	ret c
	ld d, COMPETITIVE
	call PrintAbilityActivated
	ld hl, SpecialAttackGreatlyRoseText
	jp PrintText

; Stench: a 10% chance to make the target flinch, for moves that can't already
Stench:
	call UserAbility
	cp STENCH
	ret nz
	call TargetWasDamaged
	ret z
	ld a, wPlayerMoveEffect - wPlayerMoveNum
	call GetUserMoveField
	cp FLINCH_SIDE_EFFECT1
	ret z
	cp FLINCH_SIDE_EFFECT2
	ret z
	; fall through
; a 10% chance that the target flinches, for a move that hit it for damage
; and can't already make it flinch
StenchFlinch:
	call TargetWasDamaged
	ret z
	ld a, wPlayerMoveEffect - wPlayerMoveNum
	call GetUserMoveField
	cp FLINCH_SIDE_EFFECT1
	ret z
	cp FLINCH_SIDE_EFFECT2
	ret z
	call GetTargetHP
	ld a, b
	or c
	ret z
	call TargetAbilityForMove
	cp INNER_FOCUS
	ret z
	cp SHIELD_DUST
	ret z
	call AbilityRandom
	cp 26 ; 10%
	ret nc
	ld hl, wEnemyBattleStatus1
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotTarget
	ld hl, wPlayerBattleStatus1
.gotTarget
	set FLINCHED, [hl]
	callab ClearHyperBeam
	ret

; What abilities do as their mon comes in (Intimidate, Download, Trace,
; Forewarn, and the announcements), once both mons are out: for each side
; whose mon has come in since, the faster first
EntryAbilities:
	ld a, [H_WHOSETURN]
	push af
.loop
	ld a, [wAbilityFlags]
	and ENTRY_PENDING_PLAYER | ENTRY_PENDING_ENEMY
	jr z, .done
	cp ENTRY_PENDING_PLAYER | ENTRY_PENDING_ENEMY
	jr nz, .oneSide
; both: the faster first (the player's on a tie)
	ld hl, wEnemyMonSpeed + 1
	ld a, [wBattleMonSpeed + 1]
	sub [hl]
	dec hl
	ld a, [wBattleMonSpeed]
	sbc [hl]
	ld a, ENTRY_PENDING_PLAYER
	jr nc, .oneSide
	ld a, ENTRY_PENDING_ENEMY
.oneSide
	ld hl, wAbilityFlags
	cp ENTRY_PENDING_PLAYER
	ld a, 0
	jr z, .gotSide
	inc a
.gotSide
	ld [H_WHOSETURN], a
	and a
	jr nz, .enemy
	res ENTRY_PENDING_PLAYER_F, [hl]
	jr .cleared
.enemy
	res ENTRY_PENDING_ENEMY_F, [hl]
.cleared
	call EntryAbility
	jr .loop
.done
	pop af
	ld [H_WHOSETURN], a
	ret

; the entry ability of the mon whose turn it is (H_WHOSETURN), against the other
EntryAbility:
	call UserFainted
	ret z
	call GetTargetHP
	ld a, b
	or c
	ret z ; no foe out
	call UserAbility
	ret z
	ld d, a
	ld hl, EntryAbilityHandlers
.find
	ld a, [hli]
	and a
	ret z
	cp d
	jr z, .found
	inc hl
	inc hl
	jr .find
.found
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

EntryAbilityHandlers:
	dbw INTIMIDATE, Intimidate
	dbw DOWNLOAD, Download
	dbw TRACE, Trace
	dbw FOREWARN, Forewarn
	dbw PRESSURE, .pressure
	dbw MOLD_BREAKER, .moldBreaker
	dbw NEUTRALIZING_GAS, .neutralizingGas
	db 0
.pressure
	ld hl, ExertingPressureText
	jp PrintText
.moldBreaker
	ld hl, BreaksTheMoldText
	jp PrintText
.neutralizingGas
	ld hl, NeutralizingGasText
	jp PrintText

; Intimidate: the foe's attack falls a stage, unless it's behind a substitute or
; mist, or its ability stops it (Gen 9: Hyper Cutter and Clear Body, which keep
; stats up, and Oblivious, Inner Focus, Own Tempo and Scrappy)
Intimidate:
	call PrintUserAbilityActivated
	call TargetAbility
	ld d, a
	ld hl, IntimidateImmunities
	ld de, 1
	call IsInArray
	jr c, .prevented
	ld a, [H_WHOSETURN]
	and a
	ld a, [wEnemyBattleStatus2]
	jr z, .gotTargetStatus
	ld a, [wPlayerBattleStatus2]
.gotTargetStatus
	and (1 << HAS_SUBSTITUTE_UP) | (1 << PROTECTED_BY_MIST)
	jr nz, .notLowered
	ld a, [H_WHOSETURN]
	xor 1
	lb bc, -1, MOD_ATTACK
	call ChangeStatStage
	jr c, .notLowered
	ld hl, TargetAttackFellText
	call PrintText
; Competitive answers it
	call TargetAbility
	cp COMPETITIVE
	ret nz
	ld a, [H_WHOSETURN]
	xor 1
	lb bc, 2, MOD_SPECIAL_ATTACK
	call ChangeStatStage
	ret c
	ld d, COMPETITIVE
	call PrintAbilityActivated
	ld hl, SpecialAttackGreatlyRoseText
	jp PrintText
.prevented
	call TargetAbility
	ld d, a
	call PrintAbilityActivated
.notLowered
	ld hl, TargetAttackNotLoweredText
	jp PrintText

IntimidateImmunities:
	db HYPER_CUTTER, CLEAR_BODY, OBLIVIOUS, INNER_FOCUS, OWN_TEMPO, SCRAPPY
	db -1

; Download: raises attack a stage if the foe's defense is lower than its
; special defense, else special attack
Download:
	call PrintUserAbilityActivated
	ld hl, wEnemyMonDefense
	ld de, wEnemyMonSpecialDefense
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotFoe
	ld hl, wBattleMonDefense
	ld de, wBattleMonSpecialDefense
.gotFoe
	ld a, [hli]
	ld b, a
	ld c, [hl] ; bc = defense
	ld a, [de]
	ld h, a
	inc de
	ld a, [de]
	ld l, a ; hl = special defense
	ld a, c
	sub l
	ld a, b
	sbc h
	ld c, MOD_ATTACK
	ld hl, UserAttackRoseText
	jr c, .gotStat ; defense is the lower
	ld c, MOD_SPECIAL_ATTACK
	ld hl, UserSpecialAttackRoseText
.gotStat
	push hl
	ld a, [H_WHOSETURN]
	ld b, 1
	call ChangeStatStage
	pop hl
	ret c
	jp PrintText

; Trace: copies the foe's ability, which then acts as it came in
Trace:
	ld hl, wEnemyAbility
	ld de, wPlayerAbility
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotAbilities
	ld hl, wPlayerAbility
	ld de, wEnemyAbility
.gotAbilities
	ld a, [hl]
	and a
	ret z
	cp TRACE
	ret z
	ld [de], a
	call GetAbilityName
	ld hl, TracedText
	call PrintText
	jp EntryAbility

; Forewarn: names the foe's strongest move (one-hit KOs count as 150,
; Counter as 120 and other fixed-damage moves as 80)
Forewarn:
	ld hl, wEnemyMonMoves
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotMoves
	ld hl, wBattleMonMoves
.gotMoves
	lb bc, 0, NUM_MOVES ; b = the best power so far
	ld e, 0 ; e = its move
.loop
	ld a, [hli]
	and a
	jr z, .next
	push hl
	push bc
	push de
	ld d, a
	push de
	call ForewarnPower
	pop de
	ld l, d ; the move
	pop de
	pop bc
	cp b
	jr c, .notBetter
	jr z, .notBetter
	ld b, a
	ld e, l
.notBetter
	pop hl
.next
	dec c
	jr nz, .loop
	ld a, e
	and a
	ret z ; only status moves, or none
	ld [wd11e], a
	call GetMoveName
	ld d, FOREWARN
	call PrintUserAbilityActivated
	ld hl, ForewarnText
	jp PrintText

; a = move -> a = its power for Forewarn
ForewarnPower:
	ld hl, Moves
	ld bc, MoveEnd - Moves
	dec a
	call AddNTimes
	ld de, wAbilitySnapshot + 4 ; free between moves
	ld bc, 3 ; number, effect, power
	ld a, BANK(Moves)
	call FarCopyData
	ld hl, wAbilitySnapshot + 4
	ld a, [hli]
	cp COUNTER
	jr z, .counter
	ld a, [hli]
	cp OHKO_EFFECT
	jr z, .ohko
	ld a, [hl]
	cp 1
	ret nz
	ld a, 80 ; other fixed damage
	ret
.counter
	ld a, 120
	ret
.ohko
	ld a, 150
	ret

; Arena Trap: the mon whose turn it isn't (a = which) can't flee or switch out
; unless it's a Flying or Ghost type, or has Levitate. a = 0 for the player's
; mon, 1 for the enemy's; carry if trapped. Not in link battles, where each
; side's own game decides
SideTrapped:
	ld e, a
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jr z, .free
	ld a, e
	xor 1
	call GetSideAbility
	cp ARENA_TRAP
	jr nz, .free
	ld a, e
	call GetSideAbility
	cp LEVITATE
	jr z, .free
	ld hl, wBattleMonType1
	ld a, e
	and a
	jr z, .gotTypes
	ld hl, wEnemyMonType1
.gotTypes
	ld a, [hli]
	call .canLeave
	jr z, .free
	ld a, [hl]
	call .canLeave
	jr z, .free
	scf
	ret
.free
	and a
	ret
.canLeave
	cp FLYING
	ret z
	cp GHOST
	ret

PlayerTrapped:
	xor a
	jr SideTrapped
EnemyTrapped:
	ld a, 1
	jr SideTrapped

; Running from a wild battle: carry if Run Away lets the player go, else nz if
; Arena Trap keeps it (z to try as usual)
RunAwayOrTrapped:
	xor a
	call GetSideItem
	cp SMOKE_BALL
	jr z, .runAway
	xor a
	call GetSideAbility
	cp RUN_AWAY
	jr z, .runAway
	call PlayerTrapped
	jr c, .trapped
	xor a
	ret
.trapped
	or 1 ; nz, carry clear
	ret
.runAway
	scf
	ret

; Transform copies the target's ability too (the mon whose turn it is
; transformed)
TransformAbility:
	ld hl, wEnemyAbility
	ld de, wPlayerAbility
	ld a, [H_WHOSETURN]
	and a
	jr z, .copy
	ld hl, wPlayerAbility
	ld de, wEnemyAbility
.copy
	ld a, [hl]
	ld [de], a
	ret

; Scrappy: the user's Normal and Fighting moves hit Ghost types as if they
; weren't Ghost. d and e = the defender's types, changed in place
ScrappyTypes:
	call UserAbility
	cp SCRAPPY
	ret nz
	ld a, [wMoveType]
	cp NORMAL
	jr z, .hitsGhosts
	cp FIGHTING
	ret nz
.hitsGhosts
	ld a, d
	cp GHOST
	jr nz, .type1Done
	ld d, e
.type1Done
	ld a, e
	cp GHOST
	jr nz, .type2Done
	ld e, d
.type2Done
	ld a, d
	cp GHOST
	ret nz
	ld d, FIRE ; pure Ghost: neutral to both Normal and Fighting
	ld e, d
	ret

AbilityActivatedUserText:
	text "<USER>'s"
	line "@"
	TX_RAM wcd6d
	text "!"
	prompt

AbilityCantUseMoveText:
	text "<USER> can't use"
	line "@"
	TX_RAM wcf4b
	text "!"
	prompt

SuckedUpOozeTargetText:
	text "<TARGET> sucked"
	line "up the ooze!"
	prompt

SuckedUpOozeUserText:
	text "<USER> sucked"
	line "up the ooze!"
	prompt

FellAsleepAbilityText:
	TX_FAR _FellAsleepText
	db "@"

ExertingPressureText:
	text "<USER> is"
	line "exerting its"
	cont "PRESSURE!"
	prompt

BreaksTheMoldText:
	text "<USER> breaks"
	line "the mold!"
	prompt

NeutralizingGasText:
	text "Neutralizing gas"
	line "filled the area!"
	prompt

TargetAttackFellText:
	text "<TARGET>'s"
	line "ATTACK fell!"
	prompt

TargetAttackNotLoweredText:
	text "<TARGET>'s ATTACK"
	line "wasn't lowered!"
	prompt

UserAttackRoseText:
	text "<USER>'s"
	line "ATTACK rose!"
	prompt

UserSpecialAttackRoseText:
	text "<USER>'s"
	line "SPCL.ATK rose!"
	prompt

TracedText:
	text "<USER> traced"
	line "<TARGET>'s"
	cont "@"
	TX_RAM wcd6d
	text "!"
	prompt

ForewarnText:
	text "It was alerted to"
	line "@"
	TX_RAM wcd6d
	text "!"
	prompt

AbilityCuredUserText:
	text "<USER>"
	line "was cured!"
	prompt

MaxedAttackText:
	text "<TARGET> maxed"
	line "its ATTACK!"
	prompt

UserMoveDisabledText:
	text "<USER>'s"
	line "@"
	TX_RAM wcf4b
	text " was"
	cont "disabled!"
	prompt

SpecialAttackGreatlyRoseText:
	text "<TARGET>'s"
	line "SPCL.ATK greatly"
	cont "rose!"
	prompt

SynchronizePoisonedText:
	TX_FAR _PoisonedText
	db "@"

SynchronizeBadlyPoisonedText:
	TX_FAR _BadlyPoisonedText
	db "@"

SynchronizeBurnedText:
	TX_FAR _BurnedText
	db "@"

SynchronizeParalyzedText:
	TX_FAR _ParalyzedMayNotAttackText
	db "@"

HungOnText:
	text "<TARGET> hung on"
	line "using its"
	cont "@"
	TX_RAM wcd6d
	text "!"
	prompt

EnduredTheHitText:
	text "<TARGET>"
	line "endured the hit!"
	prompt

AbilityActivatedText:
	text "<TARGET>'s"
	line "@"
	TX_RAM wcd6d
	text "!"
	prompt

AbilityDoesntAffectText:
	TX_FAR _DoesntAffectMonText
	db "@"

AbilityRegainedHealthText:
	text "<TARGET>"
	line "regained health!"
	prompt

AbilitySpecialAttackRoseText:
	text "<TARGET>'s"
	line "SPCL.ATK rose!"
	prompt

AbilityFirePowerRoseText:
	text "<TARGET>'s FIRE"
	line "moves powered up!"
	prompt

INCLUDE "data/mon_abilities.asm"
	ASSERT MonAbilitiesEnd - MonAbilities == 2 * VICTREEBEL

INCLUDE "data/ability_names.asm"

INCLUDE "data/move_flags.asm"
	ASSERT MoveFlagsEnd - MoveFlags == STRUGGLE
