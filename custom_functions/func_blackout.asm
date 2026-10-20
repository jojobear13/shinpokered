;functions for returning to where the player blacked out

;called from ResetStatusAndHalveMoneyOnBlackout before the player is warped to the last pokemon center
SaveBlackoutPosition:
	xor a
	ld [wBlackoutReturnFlag], a
	CheckEvent EVENT_NO_BLACKOUT_RETURN ; the BLACKOUT RTN rule
	ret nz
;don't offer a return for the elite 4 and champion rooms or the safari zone
	ld a, [wCurMap]
	cp LORELEIS_ROOM
	ret z
	cp BRUNOS_ROOM
	ret z
	cp AGATHAS_ROOM
	ret z
	cp LANCES_ROOM
	ret z
	cp CHAMPIONS_ROOM
	ret z
	CheckEvent EVENT_IN_SAFARI_ZONE
	ret nz
;save wCurMap through wLastMap along with the walking/biking/surfing state
	ld hl, wCurMap
	ld de, wBlackoutSavedMapData
	ld bc, wLastMap - wCurMap + 1
	call CopyData
	ld a, [wWalkBikeSurfState]
	ld [wBlackoutSavedWalkBikeSurfState], a
	ld a, 1
	ld [wBlackoutReturnFlag], a
	ret

;called from EnterMap
;sets carry if the player chose to return to where they blacked out
BlackoutReturnPrompt:
	ld a, [wBlackoutReturnFlag]
	and a
	ret z
	call GBFadeInFromBlack	;the screen is still black from blacking out
	call EnableAutoTextBoxDrawing
	call .displayText
	ld a, [wBlackoutReturnFlag]
	cp 2
	ld a, 0
	ld [wBlackoutReturnFlag], a
	ret nz	;carry is not set if 'no' was chosen
;restore the position from when the player blacked out
	ld hl, wBlackoutSavedMapData
	ld de, wCurMap
	ld bc, wLastMap - wCurMap + 1
	call CopyData
	ld a, [wBlackoutSavedWalkBikeSurfState]
	ld [wWalkBikeSurfState], a
;get ready to reload the map like SpecialEnterMap does
	call GBFadeOutToBlack
	call PlayDefaultMusicFadeOutCurrent
	xor a
	ld [hJoyPressed], a
	ld [hJoyHeld], a
	ld [hJoy5], a
	ld [wd72d], a
	call ResetPlayerSpriteData
	ld c, 20
	call DelayFrames
	scf
	ret
;display the prompt the same way DisplayTextID does
;CloseTextDisplay pops the rom bank pushed here and then returns
.displayText
	ld a, [H_LOADEDROMBANK]
	push af
	ld a, $ff	;any nonzero value makes a standard dialogue text box
	ld [hSpriteIndexOrTextID], a
	callba DisplayTextIDInit
	ld hl, wTextPredefFlag
	res 0, [hl]
	ld hl, BlackoutReturnText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .closeText	;'no' was chosen
	ld a, 2
	ld [wBlackoutReturnFlag], a
.closeText
	jp CloseTextDisplay

BlackoutReturnText:
	TX_FAR _BlackoutReturnText
	db "@"
