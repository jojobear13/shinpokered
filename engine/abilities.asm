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

; set wPlayerAbility or wEnemyAbility from the mon just sent out
LoadPlayerAbility:
	ld de, wBattleMon
	ld hl, wPlayerAbility
	jr LoadBattleMonAbility
LoadEnemyAbility:
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

INCLUDE "data/mon_abilities.asm"
	ASSERT MonAbilitiesEnd - MonAbilities == 2 * VICTREEBEL

INCLUDE "data/ability_names.asm"
