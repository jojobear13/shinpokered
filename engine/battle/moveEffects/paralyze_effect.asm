ParalyzeEffect_:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - there should be no effect if PARALYZE is used against a substitute
	push hl	;save hl register on the stack
	ld hl, wEnemyBattleStatus2	;get enemy pkmn battle status into hl (assuming player's turn)
	ld a, [H_WHOSETURN]	;get whose turn it is
	and a	;check whose turn it is
	jr z, .subskip	;skip forward if it's the player's turn
	ld hl, wPlayerBattleStatus2	;otherwise it's the enemy's turn, so load data for the player's pkmn into hl
.subskip
	bit HAS_SUBSTITUTE_UP, [hl]	;check hl for substitute bit
	pop hl	;restore original hl data from the stack
	jr nz, .didntAffect	;if the substitute bit is set, then the pkmn cannot be paralyzed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, wEnemyMonStatus
	ld de, wPlayerMoveType
	ld a, [H_WHOSETURN]
	and a
	jp z, .next
	ld hl, wBattleMonStatus
	ld de, wEnemyMoveType
.next
	ld a, [hl]
	and a ; does the target already have a status ailment?
	jr nz, .didntAffect
; Gen 9: Electric types can't be paralyzed
	push hl
	inc hl ; the target's types
	ld a, 1 << PAR
	call StatusTypeImmune
	pop hl
	jr c, .doesntAffect
; check if the target is immune due to types
	ld a, [de]
	cp ELECTRIC
	jr nz, .hitTest
	ld b, h
	ld c, l
	inc bc
	ld a, [bc]
	cp GROUND
	jr z, .doesntAffect
	inc bc
	ld a, [bc]
	cp GROUND
	jr z, .doesntAffect
.hitTest
	push hl
	callab MoveHitTest
	pop hl
	ld a, [wMoveMissed]
	and a
	jr nz, .didntAffect
	set PAR, [hl]
	callab HalveSpeedDueToParalysis
	ld c, 30
	call DelayFrames
	callab PlayCurrentMoveAnimation
	jpab PrintMayNotAttackText
.didntAffect
	ld c, 50
	call DelayFrames
	jpab PrintDidntAffectText
.doesntAffect
	ld c, 50
	call DelayFrames
	jpab PrintDoesntAffectText
