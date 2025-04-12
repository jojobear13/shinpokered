;re-wrote this to give more control
;now takes an offset number in D for CutOrBoulderDustAnimationTilesAndAttributes 
WriteCutOrBoulderDustAnimationOAMBlock:
	push de
	call GetCutOrBoulderDustAnimationOffsets
	pop de
	ld l, d
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl
	ld de, CutOrBoulderDustAnimationTilesAndAttributes
	add hl, de
	ld d, h
	ld e, l
	ld a, $9
	call WriteOAMBlock
	ret

CutOrBoulderDustAnimationTilesAndAttributes:
;OBP0
	db $FC,$10,$FD,$10
	db $FE,$10,$FF,$10
;OBP1
	db $FC,$11,$FD,$11
	db $FE,$11,$FF,$11
;OBP2
	db $FC,$12,$FD,$12
	db $FE,$12,$FF,$12
;OBP3
	db $FC,$13,$FD,$13
	db $FE,$13,$FF,$13
;OBP4
	db $FC,$14,$FD,$14
	db $FE,$14,$FF,$14
;OBP5
	db $FC,$15,$FD,$15
	db $FE,$15,$FF,$15
;OBP6
	db $FC,$16,$FD,$16
	db $FE,$16,$FF,$16
;OBP7
	db $FC,$17,$FD,$17
	db $FE,$17,$FF,$17

	
GetCutOrBoulderDustAnimationOffsets:
	ld hl, wSpriteStateData1 + 4
	ld a, [hli] ; player's sprite screen Y position
	ld b, a
	inc hl
	ld a, [hli] ; player's sprite screen X position
	ld c, a ; bc holds ypos/xpos of player's sprite
	inc hl
	inc hl
	ld a, [hl] ; a holds direction of player (00: down, 04: up, 08: left, 0C: right)
	srl a
	ld e, a
	ld d, $0 ; de holds direction (00: down, 02: up, 04: left, 06: right)
	ld a, [wWhichAnimationOffsets]
	and a
	ld hl, CutAnimationOffsets
	jr z, .next
	ld hl, BoulderDustAnimationOffsets
.next
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, b
	add d
	ld b, a
	ld a, c
	add e
	ld c, a
	ret

CutAnimationOffsets:
; Each pair represents the x and y pixels offsets from the player of where the cut tree animation should be drawn
	db  8, 36 ; player is facing down
	db  8,  4 ; player is facing up
	db -8, 20 ; player is facing left
	db 24, 20 ; player is facing right

BoulderDustAnimationOffsets:
; Each pair represents the x and y pixels offsets from the player of where the cut tree animation should be drawn
; These offsets represent 2 blocks away from the player
	db  8,  52 ; player is facing down
	db  8, -12 ; player is facing up
	db -24, 20 ; player is facing left
	db 40,  20 ; player is facing right

