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
	ld hl, wAbilityFlags
	res FLASH_FIRE_PLAYER_F, [hl]
	ld de, wBattleMon
	ld hl, wPlayerAbility
	jr LoadBattleMonAbility
LoadEnemyAbility:
	ld hl, wAbilityFlags
	res FLASH_FIRE_ENEMY_F, [hl]
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
	bit MOVE_SOUND_F, a
	jr z, .notSound
	ld a, d
	cp SOUNDPROOF
	jr z, AbilityDoesntAffect
.notSound
; the rest go by type, for moves that hit the target: damaging moves and
; Thunder Wave, the one status move of those types that targets the foe
	ld a, e
	cp THUNDER_WAVE
	jr z, .targetsFoe
	ld bc, wPlayerMovePower - wPlayerMoveNum
	add hl, bc
	ld a, [hl]
	and a
	ret z ; and carry clear
.targetsFoe
	call GetUserMove
	ld bc, wPlayerMoveType - wPlayerMoveNum
	add hl, bc
	ld e, [hl] ; e = the move's type
	ld hl, AbilityImmunities
.loop
	ld a, [hli]
	and a
	ret z ; and carry clear
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
	push hl
	call PrintAbilityActivated
	ret ; to the handler

AbilityImmunities: ; ability, the type it takes, what it does
	db LEVITATE, GROUND
	dw AbilityDoesntAffect.printed
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

AbilityDoesntAffect:
	call PrintAbilityActivated
.printed
	ld hl, AbilityDoesntAffectText
	call PrintText
	scf
	ret

; heals the target by 1/4 of its max HP
AbilityHealsTarget:
	ld hl, wEnemyMonHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotTarget
	ld hl, wBattleMonHP
.gotTarget
	ld a, [hli]
	ld d, a
	ld a, [hl]
	ld e, a ; de = HP
	ld [wHPBarOldHP], a
	ld a, d
	ld [wHPBarOldHP + 1], a
	push hl ; HP low byte
	ld bc, (wBattleMonMaxHP + 1) - (wBattleMonHP + 1)
	add hl, bc
	ld a, [hld]
	ld c, a
	ld [wHPBarMaxHP], a
	ld a, [hl]
	ld b, a ; bc = max HP
	ld [wHPBarMaxHP + 1], a
	pop hl
	ld a, e
	cp c
	jr nz, .notFull
	ld a, d
	cp b
	jr z, AbilityDoesntAffect.printed
.notFull
	push hl
	ld h, b
	ld l, c
	srl h
	rr l
	srl h
	rr l ; hl = max HP / 4
	ld a, h
	or l
	jr nz, .gotAmount
	inc l ; at least 1
.gotAmount
	add hl, de ; hl = HP + max HP / 4
	ld a, l
	sub c
	ld a, h
	sbc b
	jr c, .notOverMax
	ld h, b
	ld l, c
.notOverMax
	ld d, h
	ld e, l
	pop hl
	ld a, e
	ld [hld], a
	ld [wHPBarNewHP], a
	ld a, d
	ld [hl], a
	ld [wHPBarNewHP + 1], a
	ld a, [H_WHOSETURN]
	and a
	coord hl, 2, 2 ; the enemy's HP bar
	ld a, 0
	jr z, .updateHPBar
	coord hl, 10, 9 ; the player's
	ld a, 1
.updateHPBar
	ld [wHPBarType], a
	predef UpdateHPBar2
	callab DrawHUDsAndHPBars
	ld hl, AbilityRegainedHealthText
	call PrintText
	scf
	ret

; Lightning Rod: the target's special attack goes up a stage
AbilityRaisesSpecialAttack:
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
	jr nc, .noStat
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
