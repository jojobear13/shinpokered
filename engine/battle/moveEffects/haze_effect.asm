; Gen 9: Haze resets every stat stage on both sides, and nothing else
HazeEffect_:
	ld a, $7
; store 7 on every stat mod
	ld hl, wPlayerMonAttackMod
	call ResetStatMods
	ld hl, wEnemyMonAttackMod
	call ResetStatMods
; copy unmodified stats to battle stats
	ld hl, wPlayerMonUnmodifiedAttack
	ld de, wBattleMonAttack
	call ResetStats
	ld hl, wEnemyMonUnmodifiedAttack
	ld de, wEnemyMonAttack
	call ResetStats
; paralysis still halves speed
	ld a, [H_WHOSETURN]
	push af
	callab ApplyBurnAndParalysisPenaltiesToPlayer
	callab ApplyBurnAndParalysisPenaltiesToEnemy
	pop af
	ld [H_WHOSETURN], a
	ld hl, PlayCurrentMoveAnimation
	call CallBankF
	ld hl, StatusChangesEliminatedText
	jp PrintText

ResetStatMods:
	ld b, NUM_STAT_MODS
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret

ResetStats:
	ld b, (NUM_STATS - 1) * 2
.loop
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .loop
	ret

StatusChangesEliminatedText:
	TX_FAR _StatusChangesEliminatedText
	db "@"
