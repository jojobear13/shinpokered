VermilionDockScript:
	call EnableAutoTextBoxDrawing
	CheckEventHL EVENT_STARTED_WALKING_OUT_OF_DOCK
	jr nz, .asm_1db8d
	CheckEventReuseHL EVENT_GOT_HM01
	ret z
	ld a, [wDestinationWarpID]
	cp $1
	ret nz
	CheckEventReuseHL EVENT_SS_ANNE_LEFT
	jp z, VermilionDock_1db9b
	SetEventReuseHL EVENT_STARTED_WALKING_OUT_OF_DOCK
	call Delay3
	ld hl, wd730
	set 7, [hl]
	ld hl, wSimulatedJoypadStatesEnd
	ld a, D_UP
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld a, $3
	ld [wSimulatedJoypadStatesIndex], a
	xor a
	ld [wSpriteStateData2 + $06], a
	ld [wOverrideSimulatedJoypadStatesMask], a
	dec a
	ld [wJoyIgnore], a
	ret
.asm_1db8d
	CheckEventAfterBranchReuseHL EVENT_WALKED_OUT_OF_DOCK, EVENT_STARTED_WALKING_OUT_OF_DOCK
	jp nz, VermilionDockPostActions
	ld a, [wSimulatedJoypadStatesIndex]
	and a
	ret nz
	ld [wJoyIgnore], a
	SetEventReuseHL EVENT_WALKED_OUT_OF_DOCK
	ret

VermilionDockPostActions:	;joenote - for handling things that happen after the SS Anne leaves and you come back later
	ld a, [wCurMapScript]
	cp $AA
	jp z, VermilionDockScriptAA
	ret
	
VermilionDockScriptAA:
	xor a
	ld [wJoyIgnore], a
	ld [wCurMapScript], a
	ld a, [wIsInBattle]
	cp $ff
	ret z
;set the special trainer flag
	ld a, [wBeatGymFlags]
	set 3, a
	ld [wBeatGymFlags], a
	ret
	
VermilionDock_1db9b:
	predef SingleCPUSpeed	;joenote - needed for 60fps mode on GBC
	SetEventForceReuseHL EVENT_SS_ANNE_LEFT
	ld a, $ff
	ld [wJoyIgnore], a
	ld [wNewSoundID], a
	call PlaySound
	ld c, BANK(Music_Surfing)
	ld a, MUSIC_SURFING
	call PlayMusic
	callba LoadSmokeTileFourTimes
	xor a
	ld [wSpriteStateData1 + 2], a
	ld c, 120
	call DelayFrames
	ld b, $9c							;select vBGMap1 ($9c00)
	call CopyScreenTileBufferToVRAM		;copy wTileMap to vBGMap1
	coord hl, 0, 10
	ld bc, SCREEN_WIDTH * 6
	ld a, $14 ; water tile
	call FillMemory						;overwrite wTileMap to erase the SS Anne tiles and replace with water tiles
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a		;H_AUTOBGTRANSFERDEST already has $9C00 loaded, so re-copy wTileMap to vBGMap1
	call Delay3

;gbcnote: for enhanced GBC colors, you have to update the palettes for the water tiles just written to vBGMap1
	callba MakeAndTransferOverworldBGMapAttributes_OpenText

	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld [wSSAnneSmokeDriftAmount], a
	ld [rOBP1], a
	call UpdateGBCPal_OBP1
	ld a, 88
	ld [wSSAnneSmokeX], a
	ld hl, wMapViewVRAMPointer
	ld c, [hl]
	inc hl
	ld b, [hl]
	push bc
	push hl
	ld a, SFX_SS_ANNE_HORN
	call PlaySoundWaitForCurrent
	ld a, $ff
	ld [wUpdateSpritesEnabled], a
	ld d, $0
	ld e, $8
.asm_1dbfa
	ld hl, $0002
	add hl, bc
	ld a, l
	ld [wMapViewVRAMPointer], a
	ld a, h
	ld [wMapViewVRAMPointer + 1], a
	push hl
	push de

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;gbcnote - initiate a bg map attribute column update to the east for the enhanced GBC palettes
	
	;set the flag that says you want to do a row/column update
	ld hl, hFlags_0xFFF6
	set 3, [hl]
	
	;preserve the player facing
	ld a, [wSpriteStateData1 + 3]
	push af
	ld a, [wSpriteStateData1 + 5]
	push af
	
	;pretend like the player is facing east for  the time being
	xor a
	ld [wSpriteStateData1 + 3], a
	inc a
	ld [wSpriteStateData1 + 5], a
	
	;do the update without caring about the state of H_AUTOBGTRANSFERENABLED
	callba MakeOverworldBGMapAttributes.endAutoBGTransferFlag
	
	;restore facing
	pop af
	ld [wSpriteStateData1 + 5], a
	pop af
	ld [wSpriteStateData1 + 3], a
	
	;clear flag
	ld hl, hFlags_0xFFF6
	res 3, [hl]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

	call ScheduleEastColumnRedraw		;this redraws columns on vBGMap0 so garbage does not scroll in from the right
	call VermilionDock_EmitSmokePuff
	pop de
	ld b, $10
.asm_1dc11
	call VermilionDock_AnimSmokePuffDriftRight
	ld c, $8
.asm_1dc16
	call VermilionDock_1dc7c	;this function includes an update of the scrolling layer
	dec c
	jr nz, .asm_1dc16
	inc d
	dec b
	jr nz, .asm_1dc11
	pop bc
	dec e
	jr nz, .asm_1dbfa
	xor a
	ld [rWY], a
	ld [hWY], a
	call VermilionDock_EraseSSAnne
	ld a, $90
	ld [hWY], a
	ld a, $1
	ld [wUpdateSpritesEnabled], a
	pop hl
	pop bc
	ld [hl], b
	dec hl
	ld [hl], c
	call LoadPlayerSpriteGraphics
	predef SetCPUSpeed	;joenote - needed for 60fps mode on GBC
	ld hl, wNumberOfWarps
	dec [hl]
	ret

VermilionDock_AnimSmokePuffDriftRight:
	push bc
	push de
	ld hl, wOAMBuffer + $11
	ld a, [wSSAnneSmokeDriftAmount]
	swap a
	ld c, a
	ld de, 4
.loop
	inc [hl]
	inc [hl]
	add hl, de
	dec c
	jr nz, .loop
	pop de
	pop bc
	ret

VermilionDock_EmitSmokePuff:
; new smoke puff above the S.S. Anne's front smokestack
	ld a, [wSSAnneSmokeX]
	sub 16
	ld [wSSAnneSmokeX], a
	ld c, a
	ld b, 100 ; Y
	ld a, [wSSAnneSmokeDriftAmount]
	inc a
	ld [wSSAnneSmokeDriftAmount], a
	ld a, $1
	ld de, VermilionDockOAMBlock
	call WriteOAMBlock
	ret

VermilionDockOAMBlock:
	db $fc, $10
	db $fd, $10
	db $fe, $10
	db $ff, $10

VermilionDock_1dc7c:
	ld h, d
	ld l, $50
	call .asm_1dc86
	ld h, $0
	ld l, $80
.asm_1dc86
	predef BGLayerScrollingUpdate	;joenote - consolidated into a predef that also fixes some issues
.asm_1dc8e
	ld a, [rLY]
	cp h
	jr z, .asm_1dc8e
	ret

VermilionDock_EraseSSAnne:
; Fill the area the S.S. Anne occupies in BG map 0 with water tiles.
	ld hl, wVermilionDockTileMapBuffer
	ld bc, (5 * BG_MAP_WIDTH) + SCREEN_WIDTH
	ld a, $14 ; water tile
	call FillMemory
	ld hl, vBGMap0 + 10 * BG_MAP_WIDTH
	ld de, wVermilionDockTileMapBuffer
	ld bc, (6 * BG_MAP_WIDTH) / 16
	call CopyVideoData

; Replace the blocks of the lower half of the ship with water blocks. This
; leaves the upper half alone, but that doesn't matter because replacing any of
; the blocks is unnecessary because the blocks the ship occupies are south of
; the player and won't be redrawn when the player automatically walks north and
; exits the map. This code could be removed without affecting anything.
	overworldMapCoord hl, 5, 2, VERMILION_DOCK_WIDTH
	ld a, $d ; water block
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a

	ld a, SFX_SS_ANNE_HORN
	call PlaySound
	ld c, 120
	call DelayFrames
	ret

;joenote - adding dialogue
VermilionDockTextPointers:
	dw VermilionDockText1
	dw VermilionDockText2
	
VermilionDockText1:
	TX_FAR _VermilionDockText1
	db "@"

VermilionDockText2:
	TX_ASM
	ld hl, VermilionDockSeigaIntro
	call PrintText
	CheckEvent EVENT_908	;has elite 4 been beaten?
	jr z, .text2end	;jump if not beaten
	call ManualTextScroll
	ld hl, VermilionDockSeigaChallenge
	call PrintText
	call YesNoChoice	;prompt a yes/no choice
	ld a, [wCurrentMenuItem]	;load the player choice
	and a	;check the player choice
	jr nz, .seigagoodbye	;if no, jump
	;otherwise begin loading battle
	ld hl, VermilionDockSeigaPre
	call PrintText
	ld hl, wd72d;set the bits for triggering battle
	set 6, [hl]	;
	set 7, [hl]	;
	ld hl, VermilionDockSeigaVictory	;load text for when you win
	ld de, VermilionDockSeigaDefeat	;load text for when you lose
	call SaveEndBattleTextPointers	;save the win/lose text
	ld a, [H_SPRITEINDEX]
	ld [wSpriteIndex], a
	call EngageMapTrainer
	call InitBattleEnemyParameters
	ld a, $09	;load 9 into the gym leader value to play final battle music 
	ld [wGymLeaderNo], a
	xor a
	ld [hJoyHeld], a
	ld a, $AA
	ld [wCurMapScript], a
	jr .text2end
.seigagoodbye
	ld hl, VermilionDockSeigaBye
	call PrintText
.text2end
	jp TextScriptEnd

VermilionDockSeigaChallenge:
	TX_FAR _VermilionDockSeigaChallenge
	db "@"

VermilionDockSeigaIntro:
	TX_FAR _VermilionDockSeigaIntro
	db "@"

VermilionDockSeigaDefeat:
	TX_FAR _VermilionDockSeigaDefeat
	db "@"
	
VermilionDockSeigaVictory:
	TX_FAR _VermilionDockSeigaVictory
	db "@"

VermilionDockSeigaBye:
	TX_FAR _VermilionDockSeigaBye
	db "@"

VermilionDockSeigaPre:
	TX_FAR _VermilionDockSeigaPre
	db "@"