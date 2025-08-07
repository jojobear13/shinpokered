; replaces a tile block with the one specified in [wNewTileBlockID]
; and redraws the map view if necessary
; b = Y
; c = X
ReplaceTileBlock:
	call GetPredefRegisters
	ld hl, wOverworldMap
	ld a, [wCurMapWidth]
	add $6
	ld e, a
	ld d, $0
	add hl, de
	add hl, de
	add hl, de
	ld e, $3
	add hl, de
	ld e, a
	ld a, b
	and a
	jr z, .addX
; add width * Y
.addWidthYTimesLoop
	add hl, de
	dec b
	jr nz, .addWidthYTimesLoop
.addX
	add hl, bc ; add X
	ld a, [wNewTileBlockID]
	
	;joenote - No point in wasting time if the new tile block is the same as the old one. 
	cp [hl]
	ret z
	
	ld [hl], a

;	ld a, [wCurrentTileBlockMapViewPointer]
;	ld c, a
;	ld a, [wCurrentTileBlockMapViewPointer + 1]
;	ld b, a		;bc now points to the upper left tile block in the map view
;	call CompareHLWithBC
;	ret c ; return if the replaced tile block is below the map view in memory
;	push hl
;	ld l, e
;	ld h, $0
;;	ld e, $6	;BUG - The lower right tile block in the map view is 4 columns to the right, not 6
;	ld e, $4	;joenote - let's fix that bug real quick
;	ld d, h
;	add hl, hl
;	add hl, hl
;	add hl, de
;	add hl, bc	;hl now points to the lower right tile block in the map view
;	pop bc
;	call CompareHLWithBC
;	ret c ; return if the replaced tile block is above the map view in memory
	
;joenote - check each row of tile blocks to see if the replaced block is even on screen, and only then do RedrawMapView
	push hl
	pop bc
	ld a, [wCurrentTileBlockMapViewPointer]
	ld l, a
	ld a, [wCurrentTileBlockMapViewPointer + 1]
	ld h, a		
	;hl now points to the upper left tile block in the map view
	;bc points to the tile block that was replaced
	;e is the number of bytes to add to get to the next row of the tile block map view
	call IsBCInHLTileBlockMapView
	ret c

;gbcnote - it is useful to have a version of RedrawMapView that does not mess with H_AUTOBGTRANSFERENABLED
;used particularly for clean enhanced GBC colors during in-game trades
RedrawMapView_NoChangeAutoBGTransfer:
	ld a, [wIsInBattle]
	inc a
	ret z
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	ld a, [hTilesetType]
	push af
	xor a
	jp RedrawMapView.done_AutoBGTransfer

RedrawMapView:
	ld a, [wIsInBattle]
	inc a
	ret z
	ld a, [H_AUTOBGTRANSFERENABLED]
	push af
	ld a, [hTilesetType]
	push af
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
.done_AutoBGTransfer
	ld [hTilesetType], a ; no flower/water BG tile animations
	call LoadCurrentMapView
	call RunDefaultPaletteCommand
;GBCnote - 	for enhanced GBC colors, TransferGBCEnhancedBGMapAttributes already ran during RunDefaultPaletteCommand
	ld hl, wMapViewVRAMPointer
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, -2 * 32
	add hl, de
	ld a, h
	and $3
	or $98
	ld a, l
	ld [wBuffer], a
	ld a, h
	ld [wBuffer + 1], a ; this copy of the address is not used
	ld a, 2
	ld [$ffbe], a
	ld c, 9 ; number of rows of 2x2 tiles (this covers the whole screen)
.redrawRowLoop
	push bc
	push hl
	push hl
	ld hl, wTileMap - 2 * SCREEN_WIDTH
	ld de, SCREEN_WIDTH
	ld a, [$ffbe]
.calcWRAMAddrLoop
	add hl, de
	dec a
	jr nz, .calcWRAMAddrLoop
	call CopyToRedrawRowOrColumnSrcTiles
	pop hl
	ld de, $20
	ld a, [$ffbe]
	ld c, a
.calcVRAMAddrLoop
	add hl, de
	ld a, h
	and $3
	or $98
	dec c
	jr nz, .calcVRAMAddrLoop
	ld [hRedrawRowOrColumnDest + 1], a
	ld a, l
	ld [hRedrawRowOrColumnDest], a
	ld a, REDRAW_ROW
	ld [hRedrawRowOrColumnMode], a
	call DelayFrame
	ld hl, $ffbe
	inc [hl]
	inc [hl]
	pop hl
	pop bc
	dec c
	jr nz, .redrawRowLoop
	pop af
	ld [hTilesetType], a
	pop af
	ld [H_AUTOBGTRANSFERENABLED], a
	ret

;CompareHLWithBC:
;	ld a, h
;	sub b
;	ret nz
;	ld a, l
;	sub c
;	ret

;joenote - replace the previous function with one that checks blocks in the whole map view
IsBCInHLTileBlockMapView:
	ld d, 5
.loop
	call .CheckRow
	ret nc
	dec d
	ret z
	push de
	ld d, 0
	add hl, de
	pop de
	jr .loop

.CheckRow
	ld a, b
	sub h
	ret nz
	ld a, c
	sub l
	ret c
	
	push hl
	
	push bc
	ld bc, $0004
	add hl, bc
	pop bc
	
	ld a, h
	sub b
	jr nz, .next
	ld a, l
	sub c
.next
	pop hl
	ret