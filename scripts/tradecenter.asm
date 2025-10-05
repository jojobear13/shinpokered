TradeCenterScript:
	call EnableAutoTextBoxDrawing
	ld a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	ld a, SPRITE_FACING_LEFT
	jr z, .next
	ld a, SPRITE_FACING_RIGHT
.next
	ld [hSpriteFacingDirection], a
	ld a, $1
	ld [H_SPRITEINDEX], a
	call SetSpriteFacingDirection
	ld hl, wd72d
	bit 0, [hl]
	set 0, [hl]
	ret nz
	
IF DEF(_FPLAYER)
;If there is a female trainer on the other side , load her graphics
	CheckEvent EVENT_LINKED_FPLAYER
	jr z, .next_afterFTrainer
	ld de, RedFSprite
	ld hl, vNPCSprites + $C0	;player is a $8000 while other person NPC is at $80C0
	lb bc, BANK(RedFSprite), $C	;NPC sprites are $C tiles worth of data
	call CopyVideoData
.next_afterFTrainer
ENDC	
		
	ld hl, wSpriteStateData2 + $14
	ld a, $8
	ld [hli], a
	ld a, $a
	ld [hl], a
	ld a, SPRITE_FACING_LEFT
	ld [wSpriteStateData1 + $19], a
	ld a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	ret z
	ld a, $7
	ld [wSpriteStateData2 + $15], a
	ld a, SPRITE_FACING_RIGHT
	ld [wSpriteStateData1 + $19], a
	ret

TradeCenterTextPointers:
	dw TradeCenterText1

TradeCenterText1:
	TX_FAR _TradeCenterText1
	db "@"
