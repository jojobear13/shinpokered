; Gen 9's binding moves and side conditions. Wrap and co. bind the target for
; 4-5 turns: it takes 1/8 of its max HP after each of its turns and can't
; switch out (but can still move). Reflect, Light Screen and Mist protect
; their side for 5 turns, through switches.

; hl = a player's byte, a = 0 for the player or 1 for the enemy -> hl = that
; side's byte (the enemy's comes just after)
SideByte:
	add l
	ld l, a
	ret nc
	inc h
	ret

; the move whose turn it is binds the target, unless it already is or the
; move doesn't affect it
BindTarget:
	ld hl, wUnusedC000
	set 3, [hl] ; AIGetTypeEffectiveness: the player's move
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotSide
	res 3, [hl] ; the enemy's
.gotSide
	call AIGetTypeEffectiveness
	ld a, [wTypeEffectiveness]
	and a
	ret z
	ld a, [H_WHOSETURN]
	xor 1
	ld hl, wPlayerBoundTurns
	call SideByte
	ld a, [hl]
	and a
	ret nz
	call BattleRandom
	and 1
	add 5 ; 4-5 turns, as the count goes down before each
	ld [hli], a
	inc hl ; the bound move
	ld a, [H_WHOSETURN]
	and a
	ld a, [wPlayerMoveNum]
	jr z, .gotMove
	ld a, [wEnemyMoveNum]
.gotMove
	ld [hl], a
	ld hl, BoundText
	jp PrintText

BoundText:
	text "<TARGET>"
	line "can't escape!"
	prompt

; after the turn of the mon whose turn it is: carry if it's still bound, so
; hurt (wd11e = the binding move, its name in wcd6d); the last turn frees it
BoundTurnEnd:
	ld a, [H_WHOSETURN]
	ld hl, wPlayerBoundTurns
	call SideByte
	ld a, [hl]
	and a
	ret z ; carry clear
	dec [hl]
	inc hl
	inc hl
	ld a, [hl]
	ld [wd11e], a
	call GetMoveName ; (keeps hl)
	dec hl
	dec hl
	ld a, [hl]
	and a
	scf
	ret nz
	ld hl, FreedText
	call PrintText
	and a
	ret

FreedText:
	text "<USER>"
	line "was freed from"
	cont "@"
	TX_RAM wcd6d
	text "!"
	prompt

; as the battle loop comes round after a turn: each side's screens and Mist
; count down, and say so as they wear off
SideConditionsEndOfTurn:
	ld hl, wTurnPending
	ld a, [hl]
	and a
	ret z
	ld [hl], 0
	ld hl, wPlayerReflectTurns
	ld c, REFLECT
	call .condition
	ld hl, wPlayerLightScreenTurns
	ld c, LIGHT_SCREEN
	call .condition
	ld hl, wPlayerMistTurns
	ld c, MIST
.condition ; both sides of the condition at hl, move c
	ld de, PlayerSideWoreOffText
	call .side
	inc hl
	ld de, EnemySideWoreOffText
.side
	ld a, [hl]
	and a
	ret z
	dec [hl]
	ret nz
	push hl
	push bc
	push de
	ld a, c
	ld [wd11e], a
	call GetMoveName
	pop hl
	call PrintText
	pop bc
	pop hl
	ret

PlayerSideWoreOffText:
	text "Your team's"
	line "@"
	TX_RAM wcd6d
	text " wore off!"
	prompt

EnemySideWoreOffText:
	text "The foe's"
	line "@"
	TX_RAM wcd6d
	text " wore off!"
	prompt
