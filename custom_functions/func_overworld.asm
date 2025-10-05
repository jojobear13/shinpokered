;This function is for teleporting you home from the start menu if you get stuck
SoftlockTeleport:
;make it not work for inside the cable club
;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [wCurMap]
	cp TRADE_CENTER
	ret z
	cp COLOSSEUM
	ret z
;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [hJoyInput]
	cp D_UP + B_BUTTON + SELECT
	jp z, ResetAllOptions
	cp D_DOWN + A_BUTTON + SELECT
	jp z, ShowDamageValues
	cp D_DOWN + B_BUTTON + SELECT
	ret nz
	CheckEvent EVENT_GOT_POKEDEX
	ld a, [wCurrentMenuItem]
	jr nz, .next
	;do this stuff if pokedex has not been obtained
	cp 5
	ret nz
	callba ItemUseNotTime
	ret
.next
	cp 6 
	ret nz
	ld a, PALLET_TOWN
	ld [wLastBlackoutMap], a
	ld a, [wd732]
	set 3, a 
	res 4, a 
	set 6, a 
	ld [wd732], a
	;reset safari zone
	ResetEvent EVENT_IN_SAFARI_ZONE
	xor a
	ld [wNumSafariBalls], a
	ld [wSafariZoneEntranceCurScript], a
	;make sure player has at least 1000 money
	ld a, [wPlayerMoney]
	and a
	ret nz
	ld a, [wPlayerMoney + 1]
	cp $10
	ret nc
	ld a, $10
	ld [wPlayerMoney + 1], a
	ret
	
	
ShowDamageValues:	;joenote - toggle damage values being shown in battle
	call WaitForSoundToFinish
	CheckAndResetEvent EVENT_910
	ld a, SFX_TURN_OFF_PC
	jr nz, .return
	SetEvent EVENT_910
	ld a, SFX_ENTER_PC
.return
	call PlaySound	
	ret
	
ResetAllOptions: ;joenote - reset all the special options (like for patching-up)
	ld a, SFX_LEVEL_UP
	call PlaySound
	
	ld a, [wOptions]
	and %11000000
	set 0, a
	ld [wOptions], a

	ld a, [wUnusedD721]
	and %01100111
	ld [wUnusedD721], a

	ResetEvent EVENT_910
	ret

	
	ResetEvent EVENT_9FE
	ResetEvent EVENT_9FF
	ret


	
;this function handles tracking of how fast to go on or off a bike
;biking ORs with $2
;running by holding B ORs with $1
TrackRunBikeSpeed:
	xor a
	ld[wUnusedD119], a
	ld a, [wWalkBikeSurfState]
	dec a ; riding a bike? (0 value = TRUE)
	call z, IsRidingBike
IF DEF(_RUNSHOES)
	ld a, [hJoyHeld]
	and B_BUTTON	;holding B to speed up? (non-zero value = TRUE)
	call nz, IsRunning	;joenote - make holding B do double-speeed while walking/surfing/biking
ENDC
	ld a, [wd736]
	bit 7, a
	call nz, IsSpinArrow	;player sprite spinning due to spin tiles (Rocket hideout / Viridian Gym)
	ld a, [wUnusedD119]
	cp 2	;is biking without speedup being done?
	jr z, .skip	;if not make the states a value from 1 to 4 (excluding biking without speedup, which needs to be 2)
	inc a	
.skip
	ld[wUnusedD119], a
	ret
IsRidingBike:
	ld a, [wUnusedD119]
	or $2
	ld[wUnusedD119], a
	ret
IsRunning:
IsSpinArrow:
	ld a, [wUnusedD119]
	or $1
	ld[wUnusedD119], a
	ret
	

	
;Overworld female trainer sprite functions
LoadRedSpriteToDE:
	ld a, [wUnusedD721]
IF DEF(_FPLAYER)
	ld de, RedFSprite
	bit 0, a	;check if girl
	jr nz, .next
ENDC
	ld de, RedSprite
.next
	res 2, a
	ld [wUnusedD721], a
	ret
	
LoadSeelSpriteToDE:
	ld de, SeelSprite
	ld a, [wUnusedD721]
	set 2, a	;regardless if boy or girl, need to set override bit to use the regular sprite bank
	ld [wUnusedD721], a
	ret

LoadRedCyclingSpriteToDE:
	ld a, [wUnusedD721]
IF DEF(_FPLAYER)
	ld de, RedFCyclingSprite
	bit 0, a	;check if girl
	jr nz, .donefemale
ENDC
	ld de, RedCyclingSprite
.donefemale
	res 2, a
	ld [wUnusedD721], a
	ret


	
;***************************************************************************************************
;these functions have been moved here from overworld.asm 
;and they have been modified to work with a bank call.
;This is to free up space in rom bank 0

Determine180degreeMove:	
	ld a, [wd730]
	bit 7, a ; are we simulating button presses?
	jr nz, .noDirectionChange ; ignore direction changes if we are
	ld a, [wCheckFor180DegreeTurn]
	and a
	jr z, .noDirectionChange
	ld a, [wPlayerDirection] ; new direction
	ld b, a
	ld a, [wPlayerLastStopDirection] ; old direction
	cp b
	jr z, .noDirectionChange
; Check whether the player did a 180-degree turn.
; It appears that this code was supposed to show the player rotate by having
; the player's sprite face an intermediate direction before facing the opposite
; direction (instead of doing an instantaneous about-face), but the intermediate
; direction is only set for a short period of time. It is unlikely for it to
; ever be visible because DelayFrame is called at the start of OverworldLoop and
; normally not enough cycles would be executed between then and the time the
; direction is set for V-blank to occur while the direction is still set.
	swap a ; put old direction in upper half
	or b ; put new direction in lower half
	cp (PLAYER_DIR_DOWN << 4) | PLAYER_DIR_UP ; change dir from down to up
	jr nz, .notDownToUp
	ld a, PLAYER_DIR_LEFT
	ld [wPlayerMovingDirection], a
	jr .holdIntermediateDirectionLoop
.notDownToUp
	cp (PLAYER_DIR_UP << 4) | PLAYER_DIR_DOWN ; change dir from up to down
	jr nz, .notUpToDown
	ld a, PLAYER_DIR_RIGHT
	ld [wPlayerMovingDirection], a
	jr .holdIntermediateDirectionLoop
.notUpToDown
	cp (PLAYER_DIR_RIGHT << 4) | PLAYER_DIR_LEFT ; change dir from right to left
	jr nz, .notRightToLeft
	ld a, PLAYER_DIR_DOWN
	ld [wPlayerMovingDirection], a
	jr .holdIntermediateDirectionLoop
.notRightToLeft
	cp (PLAYER_DIR_LEFT << 4) | PLAYER_DIR_RIGHT ; change dir from left to right
	jr nz, .holdIntermediateDirectionLoop
	ld a, PLAYER_DIR_UP
	ld [wPlayerMovingDirection], a
.holdIntermediateDirectionLoop
	call UpdateSprites	;joenote - make the transitional frames viewable
	call DelayFrame
	ld hl, wFlags_0xcd60
	set 2, [hl]
	ld hl, wCheckFor180DegreeTurn
	dec [hl]
	jr nz, .holdIntermediateDirectionLoop
	ld a, [wPlayerDirection]
	ld [wPlayerMovingDirection], a
	xor a
	ret
.noDirectionChange
	scf
	ret

CheckWestMap:
	ld a, [wXCoord]
	cp $ff
	jp nz, CheckEastMap	
	ld a, [wMapConn3Ptr]
	ld [wCurMap], a
	ld a, [wWestConnectedMapXAlignment] ; new X coordinate upon entering west map
	ld [wXCoord], a
	ld a, [wYCoord]
	ld c, a
	ld a, [wWestConnectedMapYAlignment] ; Y adjustment upon entering west map
	add c
	ld c, a
	ld [wYCoord], a
	ld a, [wWestConnectedMapViewPointer] ; pointer to upper left corner of map without adjustment for Y position
	ld l, a
	ld a, [wWestConnectedMapViewPointer + 1]
	ld h, a
	srl c
	jr z, .savePointer1
.pointerAdjustmentLoop1
	ld a, [wWestConnectedMapWidth] ; width of connected map
	add MAP_BORDER * 2
	ld e, a
	ld d, 0
	ld b, 0
	add hl, de
	dec c
	jr nz, .pointerAdjustmentLoop1
.savePointer1
	ld a, l
	ld [wCurrentTileBlockMapViewPointer], a ; pointer to upper left corner of current tile block map section
	ld a, h
	ld [wCurrentTileBlockMapViewPointer + 1], a	
	xor a ;zet zero flag
	ret
	
CheckEastMap:
	ld a, [wXCoord]
	ld b, a
	ld a, [wCurrentMapWidth2] ; map width
	cp b
	jp nz, CheckNorthMap
	ld a, [wMapConn4Ptr]
	ld [wCurMap], a
	ld a, [wEastConnectedMapXAlignment] ; new X coordinate upon entering east map
	ld [wXCoord], a
	ld a, [wYCoord]
	ld c, a
	ld a, [wEastConnectedMapYAlignment] ; Y adjustment upon entering east map
	add c
	ld c, a
	ld [wYCoord], a
	ld a, [wEastConnectedMapViewPointer] ; pointer to upper left corner of map without adjustment for Y position
	ld l, a
	ld a, [wEastConnectedMapViewPointer + 1]
	ld h, a
	srl c
	jr z, .savePointer2
.pointerAdjustmentLoop2
	ld a, [wEastConnectedMapWidth]
	add MAP_BORDER * 2
	ld e, a
	ld d, 0
	ld b, 0
	add hl, de
	dec c
	jr nz, .pointerAdjustmentLoop2
.savePointer2
	ld a, l
	ld [wCurrentTileBlockMapViewPointer], a ; pointer to upper left corner of current tile block map section
	ld a, h
	ld [wCurrentTileBlockMapViewPointer + 1], a
	xor a
	ret
	
CheckNorthMap:
	ld a, [wYCoord]
	cp $ff
	jp nz, CheckSouthMap
	ld a, [wMapConn1Ptr]
	ld [wCurMap], a
	ld a, [wNorthConnectedMapYAlignment] ; new Y coordinate upon entering north map
	ld [wYCoord], a
	ld a, [wXCoord]
	ld c, a
	ld a, [wNorthConnectedMapXAlignment] ; X adjustment upon entering north map
	add c
	ld c, a
	ld [wXCoord], a
	ld a, [wNorthConnectedMapViewPointer] ; pointer to upper left corner of map without adjustment for X position
	ld l, a
	ld a, [wNorthConnectedMapViewPointer + 1]
	ld h, a
	ld b, 0
	srl c
	add hl, bc
	ld a, l
	ld [wCurrentTileBlockMapViewPointer], a ; pointer to upper left corner of current tile block map section
	ld a, h
	ld [wCurrentTileBlockMapViewPointer + 1], a
	xor a
	ret

CheckSouthMap:
	ld a, [wYCoord]
	ld b, a
	ld a, [wCurrentMapHeight2]
	cp b
	ret nz
	ld a, [wMapConn2Ptr]
	ld [wCurMap], a
	ld a, [wSouthConnectedMapYAlignment] ; new Y coordinate upon entering south map
	ld [wYCoord], a
	ld a, [wXCoord]
	ld c, a
	ld a, [wSouthConnectedMapXAlignment] ; X adjustment upon entering south map
	add c
	ld c, a
	ld [wXCoord], a
	ld a, [wSouthConnectedMapViewPointer] ; pointer to upper left corner of map without adjustment for X position
	ld l, a
	ld a, [wSouthConnectedMapViewPointer + 1]
	ld h, a
	ld b, 0
	srl c
	add hl, bc
	ld a, l
	ld [wCurrentTileBlockMapViewPointer], a ; pointer to upper left corner of current tile block map section
	ld a, h
	ld [wCurrentTileBlockMapViewPointer + 1], a
	xor a
	ret
;***************************************************************************************************



;joenote - this function ONLY checks if a sprite is in front of the player
;			wherein the sprite is unseen due to a menu (not being hidden)
IsOffScreenSpriteInFrontOfPlayer:
	ld d, $10 ; talking range in pixels (normal range)
	lb bc, $3c, $40 ; Y and X position of player sprite
	ld a, [wSpriteStateData1 + 9] ; direction the player is facing
.checkIfPlayerFacingUp
	cp SPRITE_FACING_UP
	jr nz, .checkIfPlayerFacingDown
; facing up
	ld a, b
	sub d
	ld b, a
	ld a, PLAYER_DIR_UP
	jr .doneCheckingDirection

.checkIfPlayerFacingDown
	cp SPRITE_FACING_DOWN
	jr nz, .checkIfPlayerFacingRight
; facing down
	ld a, b
	add d
	ld b, a
	ld a, PLAYER_DIR_DOWN
	jr .doneCheckingDirection

.checkIfPlayerFacingRight
	cp SPRITE_FACING_RIGHT
	jr nz, .playerFacingLeft
; facing right
	ld a, c
	add d
	ld c, a
	ld a, PLAYER_DIR_RIGHT
	jr .doneCheckingDirection

.playerFacingLeft
; facing left
	ld a, c
	sub d
	ld c, a
	ld a, PLAYER_DIR_LEFT

.doneCheckingDirection
	ld [wPlayerDirection], a
	ld a, [wNumSprites] ; number of sprites
	and a
	ret z

; if there are sprites
	ld hl, wSpriteStateData1 + $10
	ld d, a
	ld e, $01
.spriteLoop
	push hl

	ld a, e
	ld [H_CURRENTSPRITEOFFSET], a	
	push de
	push bc
	predef IsObjectHidden
	pop bc
	pop de
	pop hl
	push hl
	ld a, [$ffe5]
	and a
	jp nz, .nextSprite
	
	inc hl
	inc hl
	inc hl
	inc hl
	ld a, [hli] ; Y location
	cp b
	jr nz, .nextSprite
	
	inc hl
	ld a, [hl] ; X location
	cp c
	jr z, .foundSpriteInFrontOfPlayer
	
.nextSprite
	pop hl
	ld a, l
	add $10
	ld l, a
	inc e
	dec d
	jr nz, .spriteLoop
	ret

.foundSpriteInFrontOfPlayer
	pop hl
	ld a, l
	and $f0
	inc a
	ld l, a ; hl = $c1x1
	ld a, e
	ld [hSpriteIndexOrTextID], a
	ret

