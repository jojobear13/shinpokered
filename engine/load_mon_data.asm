LoadMonData_:
; Load monster [wWhichPokemon] from list [wMonDataLocation]:
;  0: partymon
;  1: enemymon
;  2: boxmon
;  3: daycaremon
; Return monster id at wcf91 and its data at wLoadedMon.
; Also load base stats at wMonHeader for convenience.

	call OpenBox ; the box and the day care are in save RAM
	call .body
	jp CloseBox

.body
	ld a, [sDayCareMonSpecies]
	ld [wcf91], a
	ld a, [wMonDataLocation]
	and $7f
	cp DAYCARE_DATA
	jr z, .GetMonHeader

	ld a, [wWhichPokemon]
	ld e, a
	callab GetMonSpecies

.GetMonHeader
	ld a, [wcf91]
	ld [wd0b5], a ; input for GetMonHeader
	call GetMonHeader

	ld hl, wPartyMons
	ld bc, wPartyMon2 - wPartyMon1
	ld a, [wMonDataLocation]
	and $7f
	cp ENEMY_PARTY_DATA
	jr c, .getMonEntry

	ld hl, wEnemyMons
	jr z, .getMonEntry

	cp 2
	ld hl, wBoxMons
	ld bc, wBoxMon2 - wBoxMon1
	jr z, .getMonEntry

	ld hl, sDayCareMon
	jr .copyMonData

.getMonEntry
	ld a, [wWhichPokemon]
	call AddNTimes

.copyMonData
	ld de, wLoadedMon
	ld bc, wPartyMon2 - wPartyMon1
	;jp CopyData
;joenote - allow active battle pokemon's realtime stats to be used in place of its unmodified stats
	call CopyData

	ld a, [wMonDataLocation]
	and $7f
	ret nz	;done if lot looking at player party data

	ld a, [wIsInBattle]
	and a
	ret z	;done if not in a battle

	ld a, [wWhichPokemon]
	ld b, a
	ld a, [wPlayerMonNumber]
	cp b
	ret nz	;done if loading data for a different 'mon than the active pokemon

	ld a, [wMonDataLocation]
	bit 7, a
	ret nz	;done if doing some kind of interesting stat display like level-up during battle
	
	ld hl, wBattleMonAttack
	ld de, wLoadedMonAttack
	ld bc, wBattleMonSpecial - wBattleMonMaxHP
	jp CopyData
	
	
	
	
	
	
	
	
	
	
	