; Gen 9: the user's side is protected for 5 turns, through switches
ReflectLightScreenEffect_:
	ld hl, wPlayerReflectTurns
	ld de, wPlayerMoveEffect
	ld a, [H_WHOSETURN]
	and a
	jr z, .reflectLightScreenEffect
	ld hl, wEnemyReflectTurns
	ld de, wEnemyMoveEffect
.reflectLightScreenEffect
	ld a, [de]
	cp LIGHT_SCREEN_EFFECT
	ld de, ReflectGainedArmorText
	jr nz, .gotScreen
	inc hl
	inc hl ; light screen
	ld de, LightScreenProtectedText
.gotScreen
	ld a, [hl]
	and a ; is the side already protected?
	jr nz, .moveFailed
	ld [hl], 5
	ld h, d
	ld l, e
.playAnim
	push hl
	callab PlayCurrentMoveAnimation
	pop hl
	jp PrintText
.moveFailed
	ld c, 50
	call DelayFrames
	jpab PrintButItFailedText_

LightScreenProtectedText:
	TX_FAR _LightScreenProtectedText
	db "@"

ReflectGainedArmorText:
	TX_FAR _ReflectGainedArmorText
	db "@"
