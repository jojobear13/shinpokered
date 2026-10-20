; Gen 9's per-move data the Gen 1 move struct has no room for

; Who moves first by priority (Gen 9's brackets): carry if the priorities
; decide it, then nz for the player first, z for the enemy
ComparePriority:
	ld a, [wPlayerSelectedMove]
	call MovePriority
	ld b, a
	push bc
	ld a, [wEnemySelectedMove]
	call MovePriority
	pop bc
	ld c, a
	ld a, b
	xor $80 ; signed to unsigned
	ld b, a
	ld a, c
	xor $80
	cp b
	jr z, .tie
	jr c, .player
	xor a ; the enemy first: z
	scf
	ret
.player
	ld a, 1
	and a ; nz
	scf
	ret
.tie
	and a
	ret

; a = a move -> a = its priority (signed)
MovePriority:
	ld c, a
	ld hl, MovePriorities
.loop
	ld a, [hli]
	and a
	ret z ; 0
	cp c
	ld a, [hli]
	ret z
	jr .loop

INCLUDE "data/move_priorities.asm"

; wSideEffectChance = the Gen 9 chance (out of 256) of the side effect of the
; move of the side whose turn it is, if MoveChances has one
MoveSecondaryChance:
	ld a, [H_WHOSETURN]
	and a
	ld a, [wPlayerMoveNum]
	jr z, .gotMove
	ld a, [wEnemyMoveNum]
.gotMove
	and a
	ret z
	dec a
	ld c, a
	ld b, 0
	ld hl, MoveChances
	add hl, bc
	ld a, [hl]
	and a
	ret z
	ld [wSideEffectChance], a
	ret

INCLUDE "data/move_chances.asm"
