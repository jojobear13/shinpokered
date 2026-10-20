; LoadEnemyMonData's IVs and stats, with the species' header loaded:
; wEnemyMonIVs, wEnemyMonLevel and the stats from wEnemyMonMaxHP. A trainer's
; mon keeps its IVs and EVs in its party data (hard mode rolls them on its
; first send-out); wUnusedD153 keeps the address of its EVs for
; GetEnemyMonStat.
EnemyMonIVsAndStats:
	ld de, wEnemyMonIVs
	ld a, [wEnemyBattleStatus3]
	bit TRANSFORMED, a
	jr z, .notTransformed
	ld hl, wTransformedEnemyMonOriginalIVs ; its own IVs, from before it transformed
	jr .copyIVs
.notTransformed
	ld a, [wIsInBattle]
	cp 2
	jr nz, .wild
	ld a, [wOptions]
	bit BIT_BATTLE_HARD, a
	ld hl, TrainerIVs
	jr z, .copyIVs
; hard mode: biased IVs, rolled into the party data the first time out
	call .partyMon
	ld bc, wEnemyMon1IVs - wEnemyMon1
	add hl, bc
	push hl
	callab CheckAISentOut
	pop hl
	jr nz, .copyPartyIVs
	push hl
	ld d, h
	ld e, l
	callab BiasedIVs
	pop hl
.copyPartyIVs
	ld de, wEnemyMonIVs
.copyIVs
	ld bc, NUM_IVS
	call CopyData
	jr .gotIVs
.wild
	callab DetermineWildMonIVs
.gotIVs
	ld a, [wCurEnemyLVL]
	ld [wEnemyMonLevel], a
	ld b, 0
	ld hl, wEnemyMonIVs - NUM_STATS ; no EVs
	ld a, [wIsInBattle]
	cp 2
	jr nz, .calcStats
	call .partyMon
	ld bc, wEnemyMon1EVs - wEnemyMon1
	add hl, bc
	ld a, h
	ld [wUnusedD153], a
	ld a, l
	ld [wUnusedD153 + 1], a
	push hl
	callab CheckAISentOut
	pop hl
	jr nz, .gotEVs
	call TrainerMonEV
	ld c, NUM_STATS
	push hl
.writeEVs
	ld [hli], a
	dec c
	jr nz, .writeEVs
	pop hl
.gotEVs
	ld b, 1
.calcStats
	ld de, wEnemyMonMaxHP
	jp CalcStats

.partyMon
	ld hl, wEnemyMon1
	ld a, [wWhichPokemon]
	ld bc, wEnemyMon2 - wEnemyMon1
	jp AddNTimes

TrainerIVs:
	db TRAINER_IVS_0, TRAINER_IVS_1, TRAINER_IVS_2, TRAINER_IVS_3

; -> a = the EV in each stat of a trainer's mon at level wCurEnemyLVL: in
; hard mode, level x 85 / 100 (510 in all at level 100), else none. Keeps hl
TrainerMonEV:
	ld a, [wOptions]
	bit BIT_BATTLE_HARD, a
	ld a, 0
	ret z
	push hl
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND + 1], a
	ld a, [wCurEnemyLVL]
	ld [H_MULTIPLICAND + 2], a
	ld a, 85
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, 100
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	ld a, [H_QUOTIENT + 3]
	pop hl
	ret
