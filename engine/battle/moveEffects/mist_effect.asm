; Gen 9: the user's side is protected for 5 turns, through switches
MistEffect_:
	ld hl, wPlayerMistTurns
	ld a, [H_WHOSETURN]
	and a
	jr z, .mistEffect
	ld hl, wEnemyMistTurns
.mistEffect
	ld a, [hl]
	and a ; is the side protected by mist?
	jr nz, .mistAlreadyInUse
	ld [hl], 5
	callab PlayCurrentMoveAnimation
	ld hl, ShroudedInMistText
	jp PrintText
.mistAlreadyInUse
	jpab PrintButItFailedText_

ShroudedInMistText:
	TX_FAR _ShroudedInMistText
	db "@"
