w2MapViewHLPointer			EQU $d0fa	;wram bank 2 backup. 2 bytes
w2CurMap					EQU $d0fc
w2CurMapTileset				EQU $d0fd
w2MapViewVRAMPointer		EQU $d0fe	;wram bank 2 backup. 2 bytes
w2BGMapAttributes 			EQU $d100 	;In wram bank 2 (GBC only). This is 1024 bytes (32 by 32).
w2GBCFullPalBuffer			EQU $d500	;secondary buffer that is 128 bytes
const_value = 0

	const PAL_ENH_OVW_RED     	; $00
	const PAL_ENH_OVW_PINK  	; $01
	const PAL_ENH_OVW_PURPLE 	; $02
	const PAL_ENH_OVW_GRAY   	; $03
	const PAL_ENH_OVW_GREEN    	; $04
	const PAL_ENH_OVW_YELLOW  	; $05
	const PAL_ENH_OVW_BROWN    	; $06
	const PAL_ENH_OVW_BLUE  	; $07

GBCEnhancedOverworldPalettes:	
	; PAL_ENH_OVW_RED     	; $00
	RGB 31, 31, 31
	RGB 31, 10,  0
	RGB 21,  0,  0
	RGB  3,  3,  3
	
	; PAL_ENH_OVW_PINK  	; $01
	RGB 31, 31, 31
	RGB 31, 15, 18
	RGB 31,  0,  6
	RGB  3,  3,  3

	; PAL_ENH_OVW_PURPLE 	; $02
	RGB 31, 31, 31
	RGB 25, 15, 31
	RGB 19,  0, 22
	RGB  3,  3,  3

	; PAL_ENH_OVW_GRAY   	; $03
	RGB 31, 31, 31
	RGB 20, 23, 10
	RGB 11, 11,  5
	RGB  3,  3,  3

	; PAL_ENH_OVW_GREEN    	; $04
	RGB 31, 31, 31
	RGB 17, 31, 11
	RGB  1, 22,  6
	RGB  3,  3,  3
	
	; PAL_ENH_OVW_YELLOW  	; $05
	RGB 31, 31, 31
	RGB 31, 31,  0
	RGB 28, 14,  0
	RGB  3,  3,  3

	; PAL_ENH_OVW_BROWN    	; $06
	RGB 31, 31, 31
	RGB 22, 16,  5
	RGB 15,  7,  3
	RGB  3,  3,  3

	; PAL_ENH_OVW_BLUE  	; $07
	RGB 31, 31, 31
	RGB 12, 14, 31
	RGB  0,  1, 25
	RGB  3,  3,  3


	
;This copies everything in wTileMap to w2BGMapAttributes in wram bank 2
;It also converts all the tile values to BG Map Attribute palettes
;Clobbers BC, HL, and DE
;This function is in the same spirit as LoadCurrentMapView, but for GBC color pals instead of tiles
MakeOverworldBGMapAttributes:	
;only for GBC and only if option is active
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	bit 7, a
	ret z

	ld a, [wMapViewVRAMPointer]
	ld b, a
	ld a, [wMapViewVRAMPointer+1]
	ld c, a
	ld a, [wCurMap]
	ld d, a
	ld a, [wCurMapTileset]
	ld e, a
	
	di	;disable the interrupts while messing around in the other wram bank since a bunch of stuff runs during vblank

	ld hl, rSVBK
	set 1, [hl]		;switch over to wram bank 2 (covers everything from address D700 to DFFF)
	
	ld a, b
	ld [w2MapViewVRAMPointer], a
	ld a, c
	ld [w2MapViewVRAMPointer+1], a
	ld a, d
	ld [w2CurMap], a
	ld a, e
	ld [w2CurMapTileset], a
	
	ld hl, hFlags_0xFFF6
	bit 3, [hl]
	jp nz, MakeOverworldBGMapAttributes_RolColUpdate	

;back up the stack pointer
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;copy wTileMap to w2BGMapAttributes
	ld hl, wTileMap
	ld sp, hl
	ld hl, w2BGMapAttributes - vBGMap0
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	ld b, a
	add hl, bc
	

	ld b, SCREEN_HEIGHT 	;tile map height
.w2ramCopyLoop_Y
	ld a, h
	ld [w2MapViewHLPointer], a
	ld a, l
	ld [w2MapViewHLPointer+1], a
	ld c, SCREEN_WIDTH	;tile map width
.w2ramCopyLoop_X
	pop de
	ld a, e
	ld [hli], a
	ld a, d
	ld [hl], a
	ld a, l
	and $1f
	cp $1f
	jr c, .w2ramCopyLoop_X_nowrap
	ld a, l
	sub 32
	ld l, a
	ld a, h
	sbc 0
	ld h, a
.w2ramCopyLoop_X_nowrap	
	inc hl
	dec c
	dec c
	jr nz, .w2ramCopyLoop_X

	ld a, [w2MapViewHLPointer+1]
	add 32
	ld l, a
	ld a, [w2MapViewHLPointer]
	adc 0
	cp $d5
	jr c, .w2ramCopyLoop_Y_nowrap
	sub 4
.w2ramCopyLoop_Y_nowrap
	ld h, a
	dec b
	jr nz, .w2ramCopyLoop_Y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;restore the stack pointer
	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl

;get the current map tileset
;based on the tileset, point HL to the correct list of BG map attributes for its tiles
	ld a, [w2CurMapTileset]
	ld c, a
	ld b, 0
	ld hl, OverworldTilePalPointers	
	add hl, bc
	add hl, bc
	ld a, [hli]   
	ld b, a       
	ld a, [hl]    
	ld h, a
	ld a, b
	ld l, a

;backup this HL pointer
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP+1], a

;now point DE to w2BGMapAttributes
	ld hl, w2BGMapAttributes - vBGMap0
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	ld b, a
	add hl, bc
	ld d, h
	ld e, l
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;Convert the tile values in w2BGMapAttributes to color attribute settings
	ld b, SCREEN_HEIGHT 	;tile map height
.w2ramCopyLoop2_Y

	ld a, d
	ld [w2MapViewHLPointer], a
	ld a, e
	ld [w2MapViewHLPointer+1], a
	ld c, SCREEN_WIDTH	;tile map width
.w2ramCopyLoop2_X
	;get the tileset address pointer
	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP+1]
	ld l, a

	;point to the correct tile
	ld a, [de]
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	
	;get the correct color
	ld a, [hl]
	cp 8
	jr c, .copyColorAttribute
	call .townColor
.copyColorAttribute	
	ld [de], a
	ld a, e
	and $1f
	cp $1f
	jr c, .w2ramCopyLoop2_X_nowrap
	ld a, e
	sub 32
	ld e, a
	ld a, d
	sbc 0
	ld d, a
.w2ramCopyLoop2_X_nowrap	
	inc de
	dec c
	jr nz, .w2ramCopyLoop2_X

	ld a, [w2MapViewHLPointer+1]
	add 32
	ld e, a
	ld a, [w2MapViewHLPointer]
	adc 0
	cp $d5
	jr c, .w2ramCopyLoop2_Y_nowrap
	sub 4
.w2ramCopyLoop2_Y_nowrap	
	ld d, a
	dec b
	jr nz, .w2ramCopyLoop2_Y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.return
;restore the original wram bank and return
	ld hl, rSVBK
	res 1, [hl]

;re-enabling interrupts causes vblank to run which in turn creates a weird scanline glitch for a 1 frame
;skip OAM in order to prevent it
	ld a, [hFlagsFFFA]
	set 5, a
	ld [hFlagsFFFA], a
	ei	;re-enable interrupts
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.townColor
	push hl
	push bc
	ld a, [w2CurMap]
	ld c, a
	ld b, 0
	ld hl, PalSettings_TownSpecialPal	
	add hl, bc
	ld a, c
	cp SAFFRON_CITY+1	;set flags
	ld a, [hl]	;get pal value into A
	pop bc
	pop hl
	
	ret c
	ld a, PAL_ENH_OVW_BROWN	;for routes and other such maps
	ret
	
	
;same as above but just for updating the row/column when the player walks
MakeOverworldBGMapAttributes_RolColUpdate:	
	ld a, [wSpriteStateData1 + 3]
	cp $01
	jr z, .south
	cp $ff
	jr z, .north
	ld a, [wSpriteStateData1 + 5]
	cp $01
	jr z, .east
	cp $ff
	jr z, .west
	jp MakeOverworldBGMapAttributes.return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.south
	ld hl, wTileMap + (SCREEN_WIDTH*SCREEN_HEIGHT - 2*SCREEN_WIDTH)
	
	;vram should be the $9800 table right now
	;get the pointer offset into BC
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	sub $98
	ld b, a
	
	;point to w2BGMapAttributes + offset
	ld de, w2BGMapAttributes
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	ld d, a
	
	;point to w2BGMapAttributes + offset + offset to the last two rows of the map view
	ld bc, 32*(SCREEN_HEIGHT-2)
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	cp $d5
	jr c, .south_no_wrap
	sub 4
.south_no_wrap
	ld d, a
	
	call .copyrow
	call .copyrow
	jp MakeOverworldBGMapAttributes.return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.north
	ld hl, wTileMap
	
	;vram should be the $9800 table right now
	;get the pointer offset into BC
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	sub $98
	ld b, a
	
	;point to w2BGMapAttributes + offset
	ld de, w2BGMapAttributes
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	ld d, a
	
	call .copyrow
	call .copyrow
	jp MakeOverworldBGMapAttributes.return	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.east
	ld hl, wTileMap + (SCREEN_WIDTH - 2)
	
	;vram should be the $9800 table right now
	;get the pointer offset into BC
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	sub $98
	ld b, a
	
	;point to w2BGMapAttributes + offset
	ld de, w2BGMapAttributes
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	ld d, a
	
	;point to w2BGMapAttributes + offset + offset to the last two columns of the map view
	ld a, e
	and %11100000
	ld b, a
	ld a, (SCREEN_WIDTH-2)
	add e
	and %00011111
	or b
	ld e, a
	
	call .copycol
	call .copycol
	jp MakeOverworldBGMapAttributes.return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.west
	ld hl, wTileMap
	
	;vram should be the $9800 table right now
	;get the pointer offset into BC
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	sub $98
	ld b, a
	
	;point to w2BGMapAttributes + offset
	ld de, w2BGMapAttributes
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	ld d, a
	
	call .copycol
	call .copycol
	jp MakeOverworldBGMapAttributes.return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.copyrow	;copy a row from tile map address in HL to map attribute address in DE
	ld c, SCREEN_WIDTH
	push de
.copyrow_loop
	ld a, [hli]
	ld [de], a
	call .convert
	ld a, e
	and $1F
	cp $1F
	jr c, .notRowEnd
	ld a, e
	sub 32
	ld e, a
	ld a, d
	sbc 0
	ld d, a
.notRowEnd
	inc de
	dec c
	jr nz, .copyrow_loop
	;move to next row
	pop de
	ld a, 32
	add e
	ld e, a
	ld a, 0
	adc d
	ld d, a
	;account for rows looping back to the top
	cp $D5
	ret c
	sub 4
	ld d, a
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.copycol	;copy a column from tile map address in HL to map attribute address in DE
	ld c, SCREEN_HEIGHT
	push de
	push hl
.copycol_loop
	ld a, [hl]
	ld [de], a
	call .convert
;increment to the next map view row
	ld a, SCREEN_WIDTH
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
;increment to the next BG Map attribute row	
	ld a, 32
	add e
	ld e, a
	ld a, 0
	adc d
	cp $D5
	jr c, .notColEnd
	sub 4
.notColEnd
	ld d, a
;decrement counter
	dec c
	jr nz, .copycol_loop
;move to next column
	pop hl
	pop de
	inc hl
	ld a, e
	and %11100000
	ld b, a
	inc de
	ld a, e
	and %00011111
	or b
	ld e, a
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.convert
	push hl
	push bc
;get the current map tileset
;based on the tileset, point HL to the correct list of BG map attributes for its tiles
	ld a, [w2CurMapTileset]
	ld c, a
	ld b, 0
	ld hl, OverworldTilePalPointers	
	add hl, bc
	add hl, bc
	ld a, [hli]   
	ld b, a       
	ld a, [hl]    
	ld h, a
	ld a, b
	ld l, a
;point to the correct tile
	ld a, [de]
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a	
;get the correct color
	ld a, [hl]
	cp 8
	jr c, .copyColorAttribute
	call MakeOverworldBGMapAttributes.townColor
.copyColorAttribute	
	ld [de], a
	pop bc
	pop hl
	ret
	
	
	
;Just for being called during RedrawRowOrColumn	during VBLANK
TransferGBCEnhancedBGMapAttributes_RolColByte:
;only for GBC and only if option is active
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	bit 7, a
	ret z

	ld hl, rSVBK
	set 1, [hl]		;switch over to wram bank 2 (covers everything from address D700 to DFFF)

	ld a, 1
	ld [rVBK], a	;switch to vram bank 1

	dec de	
	ld bc, w2BGMapAttributes - vBGMap0
	ld h, d
	ld l, e
	add hl, bc

.waitVRAM
	ldh a, [rSTAT]		
	and %10				
	jr nz, .waitVRAM	
		
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hli]
	ld [de], a
	
	;restore the original vram bank
	xor a
	ld [rVBK], a

	;restore the original wram bank and return
	ld hl, rSVBK
	res 1, [hl]
	ret

	
	
TransferGBCEnhancedBGMapAttributes:
;only for GBC and only if option is active
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	bit 7, a
	ret z

	ld de, $3F00
	ld hl, w2BGMapAttributes
	ld a, h
	ld [hDivideBCDBuffer], a
	ld a, l
	ld [hDivideBCDBuffer+1], a
	ld a, %11
	ld [hDivideBCDBuffer+2], a
	di
	ld hl, rSVBK
	set 1, [hl]
	callba LoadBGMapAttributes_Lite
	ld hl, rSVBK
	res 1, [hl]
	ei	
	ret

	

;This function builds the buffer and writes the palettes used for the overworld to the GBC palette registers
TransferGBCEnhancedOverworldPalettes:
;only for GBC and only if option is active
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	bit 7, a
	ret z
	
	call UpdateEnhancedGBCPal_BGP.skipHardwareUpdate
	ld d, CONVERT_OBP0
	call UpdateEnhancedGBCPal_OBP.skipHardwareUpdate
	ld d, CONVERT_OBP1
	call UpdateEnhancedGBCPal_OBP.skipHardwareUpdate

	ret 


	
;joenote - This is a function specifically for translating the default enhanced GBC pals into the GBC color buffer
;DE is passed-in containing the address of a pal pattern...like FadePal4 or something
BufferAllEnhancedColorsGBC:
	call .BGP0to3Loop
	call .BGP4to7Loop
	call .OBP0to3Loop
	call .OBP4to7Loop
	ret	
	
.BGP0to3Loop
	ld hl, wGBCFullPalBuffer
	xor a
.BGP0to3Loop_back
	call .readwriteinc
	cp 16
	jr c, .BGP0to3Loop_back
	ret

.BGP4to7Loop
	ld hl, wGBCFullPalBuffer+32
	ld a, 16
.BGP4to7Loop_back
	call .readwriteinc
	cp 32
	jr c, .BGP4to7Loop_back
	ret

.OBP0to3Loop
	ld hl, wGBCFullPalBuffer+64
	ld a, 32
	inc de	;increment to the rOBP0 portion of the pattern
.OBP0to3Loop_back
	call .readwriteinc
	cp 48
	jr c, .OBP0to3Loop_back
	ret

.OBP4to7Loop
	ld hl, wGBCFullPalBuffer+96
	ld a, 48
	inc de	;already incremented to the rOBP0 portion, so now increment to the rOBP1 portion of the pattern
.OBP4to7Loop_back
	call .readwriteinc
	cp 64
	jr c, .OBP4to7Loop_back
	ret

.readwriteinc
	ld [wGBCColorControl], a
	push de
	push hl
	call .ReadMasterPals	;get the color into DE
	push bc
	predef GBCGamma
	pop bc
	pop hl
	ld a, d
	ld [hli], a		;buffer high byte
	ld a, e
	ld [hli], a		;buffer low byte	
	pop de
	ld a, [wGBCColorControl]
	inc a
	ret

.ReadMasterPals
;first grab the correct base palette from GBCEnhancedOverworldPalettes
;the offset of the correct pointer corresponds to double the value of bits 2, 3, and 4 of the wGBCColorControl value
	push de ;need the value in DE for later because it holds the pal pattern like FadePal4 or something

	and %00011100
	rrca
	rrca
	ld de, $0000
	add a
	add a
	add a
	ld e, a
	ld hl, GBCEnhancedOverworldPalettes
	add hl, de
	
	pop de ;get the pal pattern back
	ld a, [de]
	;now put the pattern in E and make D zero
	ld d, 0
	ld e, a

;need to look at the last two bits of wGBCColorControl to determine which hardware pal color is desired
	ld a, [wGBCColorControl]
	and %00000011
	jr z, .zero
	cp 1
	jr z, .one
	cp 2
	jr z, .two
	cp 3
	jr z, .three
	
;roll the bits to get the correct base pal color number for the hardware pal color number
.zero
	sla e
	rl d
	sla e
	rl d
.one
	sla e
	rl d
	sla e
	rl d
.two
	sla e
	rl d
	sla e
	rl d
.three
	sla e
	rl d
	sla e
	rl d

;mask out all but the last two bits of D to get the base pal color number in A
	ld a, d
	and %00000011
	
;colors are 2 bytes, so double A to make it an offset and store back into DE
	add a
	ld d, 0
	ld e, a

;add DE to HL to make HL point to the desired base pal color number
	add hl, de

;load the low byte of the color
	ld a, [hli]
	ld e, a
;load the high byte of the color
	ld a, [hli]
	ld d, a
	
	ret

	

UpdateEnhancedGBCPal_BGP:
	ld a, [rBGP]
	ld [wLastBGP], a
.skipHardwareUpdate

;;We're on a GBC and this stuff takes a while. Switch to double speed mode if not already.
;	ld a, [rKEY1]
;	bit 7, a
;	ld a, $ff
;	jr nz, .doublespeed	
;	predef SetCPUSpeed
;	xor a
;.doublespeed
;	push af

	ld de, rBGP	
	call BufferAllEnhancedColorsGBC.BGP0to3Loop
	call BufferAllEnhancedColorsGBC.BGP4to7Loop

	ld a, [rIE]		;manually disable interrupts
	push af
	xor a
	ld [rIE], a

	ld de, wGBCFullPalBuffer
	call GBCBufferFastTransfer_BGP

	pop af		;re-enable interrupts
	ld [rIE], a
	
;	pop af
;	inc a
;	ret z	;return now if 2x cpu mode was already active at the start of this function
;	;otherwise return to single cpu mode and return
;	predef SingleCPUSpeed
	ret
	


UpdateEnhancedGBCPal_OBP::
; d = CONVERT_OBP0 or CONVERT_OBP1

	ld a, d
	dec a
	jr nz, .OBP1_hardwareUpdate
.OBP0_hardwareUpdate
	ld a, [rOBP0]
	ld [wLastOBP0], a
	jr .skipHardwareUpdate
.OBP1_hardwareUpdate
	ld a, [rOBP1]
	ld [wLastOBP1], a
.skipHardwareUpdate

;;We're on a GBC and this stuff takes a while. Switch to double speed mode if not already.
;	ld a, [rKEY1]
;	bit 7, a
;	ld a, $ff
;	jr nz, .doublespeed	
;	predef SetCPUSpeed
;	xor a
;.doublespeed
;	push af

	ld a, d
	dec a
	push af	;save flag register
	jr nz, .OBP1_buffer
.OBP0_buffer
	ld de, rOBP0
	dec de	;this will get incremented in the next call
	call BufferAllEnhancedColorsGBC.OBP0to3Loop
	jr .transfer
.OBP1_buffer
	ld de, rOBP1
	dec de	;this will get incremented in the next call
	call BufferAllEnhancedColorsGBC.OBP4to7Loop

.transfer
	pop af	;get flag register back
	ld de, wGBCFullPalBuffer
	
	ld a, [rIE]		;manually disable interrupts
	push af
	ld a, 0
	ld [rIE], a

	jr nz, .OBP1_transfer
.OBP0_transfer
	call GBCBufferFastTransfer_OBP0
	jr .done
.OBP1_transfer
	call GBCBufferFastTransfer_OBP1
	
.done	
	pop af		;re-enable interrupts
	ld [rIE], a	

;	pop af
;	inc a
;	ret z	;return now if 2x cpu mode was already active at the start of this function
;	;otherwise return to single cpu mode and return
;	predef SingleCPUSpeed
	ret


	
OverworldTilePalPointers:
	dw PalSettings_OVERWORLD    ; 0
	dw PalSettings_REDS_HOUSE_1 ; 1
	dw PalSettings_MART         ; 2
	dw PalSettings_FOREST       ; 3
	dw PalSettings_REDS_HOUSE_2 ; 4
	dw PalSettings_DOJO         ; 5
	dw PalSettings_POKECENTER   ; 6
	dw PalSettings_GYM          ; 7
	dw PalSettings_HOUSE        ; 8
	dw PalSettings_FOREST_GATE  ; 9
	dw PalSettings_MUSEUM       ; 10
	dw PalSettings_UNDERGROUND  ; 11
	dw PalSettings_GATE         ; 12
	dw PalSettings_SHIP         ; 13
	dw PalSettings_SHIP_PORT    ; 14
	dw PalSettings_CEMETERY     ; 15
	dw PalSettings_INTERIOR     ; 16
	dw PalSettings_CAVERN       ; 17
	dw PalSettings_LOBBY        ; 18
	dw PalSettings_MANSION      ; 19
	dw PalSettings_LAB          ; 20
	dw PalSettings_CLUB         ; 21
	dw PalSettings_FACILITY     ; 22
	dw PalSettings_PLATEAU      ; 23

;Assign a color register to be used for each tile in every tileset.
;A value of 8 is a "wild card" to set the color register based on the current town.
PalSettings_OVERWORLD:   	; 0
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	6,	6,	1,	6,	8,	8,	8,	8,	8,	3,	6,	6,	3,	6,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	6,	8,	6,	7,	8,	8,	8,	8,	8,	3,	6,	6,	3,	6,	3;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	3,	3,	3,	3,	6,	8,	8,	6,	8,	8,	3,	3,	4,	4,	4,	3;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	4,	6,	6,	6,	6,	6,	6,	6,	8,	4,	3,	3,	6,	4,	4,	3;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	4,	4,	0,	0,	7,	7,	6,	6,	6,	6,	3,	3,	8,	8,	3,	3;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	4,	4,	4,	8,	6,	6,	6,	6,	6,	6,	8,	0,	8,	8,	3,	3;
PalSettings_REDS_HOUSE_1:	; 1
PalSettings_MART:        	; 2
PalSettings_FOREST:      	; 3
PalSettings_REDS_HOUSE_2:	; 4
PalSettings_DOJO:        	; 5
PalSettings_POKECENTER:  	; 6
PalSettings_GYM:          	; 7
PalSettings_HOUSE:        	; 8
PalSettings_FOREST_GATE:  	; 9
PalSettings_MUSEUM:       	; 10
PalSettings_UNDERGROUND:  	; 11
PalSettings_GATE:         	; 12
PalSettings_SHIP:         	; 13
PalSettings_SHIP_PORT:    	; 14
PalSettings_CEMETERY:     	; 15
PalSettings_INTERIOR:     	; 16
PalSettings_CAVERN:       	; 17
PalSettings_LOBBY:        	; 18
PalSettings_MANSION:      	; 19
PalSettings_LAB:          	; 20
PalSettings_CLUB:         	; 21
PalSettings_FACILITY:     	; 22
PalSettings_PLATEAU:      	; 23
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;



PalSettings_TownSpecialPal:
	db	PAL_ENH_OVW_PURPLE	;	PALLET_TOWN,		; $00
	db	PAL_ENH_OVW_GREEN	;	VIRIDIAN_CITY,		; $01
	db	PAL_ENH_OVW_GRAY	;	PEWTER_CITY,		; $02
	db	PAL_ENH_OVW_BLUE	;	CERULEAN_CITY,		; $03
	db	PAL_ENH_OVW_PURPLE	;	LAVENDER_TOWN,		; $04
	db	PAL_ENH_OVW_RED		;	VERMILION_CITY,		; $05
	db	PAL_ENH_OVW_GREEN	;	CELADON_CITY,		; $06
	db	PAL_ENH_OVW_PINK	;	FUCHSIA_CITY,		; $07
	db	PAL_ENH_OVW_RED		;	CINNABAR_ISLAND,	; $08
	db	PAL_ENH_OVW_BLUE	;	INDIGO_PLATEAU,		; $09
	db	PAL_ENH_OVW_YELLOW	;	SAFFRON_CITY,		; $0A

	

;This is an extremely fast and lightweight function for transferring an entire 128 byte buffer of colors to the GBC
;Takes DE which points to the address of the buffer to use
;Unlike the reduced versions below for BGP/OBP, this has a built-in 1 frame delay as it waits for LY=$90
;--> Since you're writing every color, it's assumed you want it all to happen during the vblank period
GBCBufferFastTransfer:
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter
	
	ld h, d
	ld l, e
	ld sp, hl
	
	ld hl, rBGPI	
	ld a, %10000000	
	ld [hli], a		
	ld c, 32		

.wait
	ldh a, [rLY]		
	cp $90			;8 cycles
	jr nz, .wait	;8 cycles on pass-through
	
.loop
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop	;12 cycles on loop, 8 on pass-through

	;now sitting at 1676 cycles passed
	
	ld hl, rOBPI	;12 cycles
	ld a, %10000000	;8 cycles
	ld [hli], a		;8 cycles
	ld c, 32		;8 cycles

.loop2
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop2	;12 cycles on loop, 8 on pass-through
	
	;completed in 3372 cycles
	;at 456 cycles per scanline, this should fit within the vblank period

	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl
	ret
	
GBCBufferFastTransfer_BGP:
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter
	
	ld h, d
	ld l, e
	ld sp, hl
	
	ld hl, rBGPI	
	ld a, %10000000	
	ld [hli], a		
	ld c, 32		

.loop
.wait
; In case we're already in H-blank or V-blank, wait for it to end. This is a
; precaution so that the transfer doesn't extend past the blanking period.
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr z, .wait	;repeat if still in h-blank or v-blank
; Wait for H-blank or V-blank to begin.
.notInBlankingPeriod
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr nz, .notInBlankingPeriod
	
;.loop
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop	;12 cycles on loop, 8 on pass-through

	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl
	ret
	
GBCBufferFastTransfer_OBP0:
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter
	
	ld h, d
	ld l, e
	ld de, 64
	add hl, de
	ld sp, hl
	
	ld hl, rOBPI	
	ld a, %10000000	
	ld [hli], a		
	ld c, 16		

.loop
.wait
; In case we're already in H-blank or V-blank, wait for it to end. This is a
; precaution so that the transfer doesn't extend past the blanking period.
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr z, .wait	;repeat if still in h-blank or v-blank
; Wait for H-blank or V-blank to begin.
.notInBlankingPeriod
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr nz, .notInBlankingPeriod
	
;.loop
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop	;12 cycles on loop, 8 on pass-through

	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl
	ret
	
GBCBufferFastTransfer_OBP1:
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter
	
	ld h, d
	ld l, e
	ld de, 96
	add hl, de
	ld sp, hl
	
	ld hl, rOBPI	
	ld a, %10100000	
	ld [hli], a		
	ld c, 16		

.loop
.wait
; In case we're already in H-blank or V-blank, wait for it to end. This is a
; precaution so that the transfer doesn't extend past the blanking period.
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr z, .wait	;repeat if still in h-blank or v-blank
; Wait for H-blank or V-blank to begin.
.notInBlankingPeriod
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr nz, .notInBlankingPeriod
	
;.loop
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop	;12 cycles on loop, 8 on pass-through

	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl
	ret

	

;clobbers bc, hl and de
CopyGBCFullPalBuffer1to2:
	ld a, [rIE]		
	push af
	ld a, [rSVBK]
	push af
	
	ld de, w2GBCFullPalBuffer
	ld hl, wGBCFullPalBuffer
	ld c, 128
.loop
	ld a, [hli]
	ld b, a

	;interrupts off
	di
	;svbk1
	ld a, [rSVBK]
	set 1, a
	ld [rSVBK], a


	ld a, b
	ld [de], a

	;svbk0
	ld a, [rSVBK]
	res 1, a
	ld [rSVBK], a
	;interrupts on
	ei

	inc de
	dec c
	jr nz, .loop
	
	pop af
	ld [rSVBK], a
	pop af
	ld [rIE], a
	ret
	

	
DecrementAllColorsGBC_improved:	
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	ret z
	
	ld c, d
	
	push bc
	call CopyGBCFullPalBuffer1to2
	pop bc
	
	;manually disable interrupts
	ld a, [rIE]		
	push af
	xor a
	ld [rIE], a
	
	ld a, [rSVBK]
	set 1, a
	ld [rSVBK], a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, w2GBCFullPalBuffer
	ld b, 128
.mainLoop
	push bc	;save the value in C, which is the amount to darken this function call

;********************************************************************************************************************
;C = number to subract from each R, G, and B value
;HL = pointer for the color bytes to modify

;red
	ld a, [hl]
	ld b, a				
	and %00000011	
	ld d, a				;d = red negative
	ld a, %01111100
	and b				;a = positive
	ld b, c				
	rlc b
	rlc b				;b = amount to subtract from red
	sub b				;a = a - b
	
	jr c, .makeMinRed
	cp $C
	jr nc, .meetsMinRed
.makeMinRed
	ld a, $C	;minimum red value if underflow
.meetsMinRed
	
	or d
	ld [hli], a
	
;blue
	ld a, [hl]
	ld b, a
	and %11100000
	ld e, a				;e = blue negative
	ld a, %00011111
	and b				;a = positive
	sub c				;a = a - c

	jr c, .makeMinBlue
	cp $03
	jr nc, .meetsMinBlue
.makeMinBlue
	ld a, $03	;minimum blue value if underflow
.meetsMinBlue

	or e
	ld [hld], a

;green
	ld a, [hli]
	ld b, a
	ld a, [hld]

	;load and shift HL five bits to the left
	push hl		;save the pointer
	ld h, 0
	ld l, c
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl

	ld c, a
	;color is now in BC and number to subtract is in HL
	
	;e = green positive lo = blue negative from above
	;d = green positive hi = red negative from above
	
	;do DE = DE - HL - 3
	ld a, e
	sub l
	ld e, a
	ld a, d
	sbc h
	ld d, a
	jr c, .makeMinGreen
	ld a, e
	sub 3
	ld e, a
	ld a, d
	sbc 0
	ld d, a
	jr nc, .meetsMinGreen	
.makeMinGreen
	ld de, $0060	;minimum green value if underflow
.meetsMinGreen
	
	inc de
	inc de
	inc de
	pop hl	

	;now make BC the green negatives, OR with DE, and load back into HL
	ld a, %01111100
	and b
	or d
	ld [hli], a
	ld a, %00011111
	and c
	or e
	ld [hli], a
;********************************************************************************************************************

	pop bc	;get the number of times to iterate
	dec b
	jr nz, .mainLoop
	ld de, w2GBCFullPalBuffer
	call GBCBufferFastTransfer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ld a, [rSVBK]
	res 1, a
	ld [rSVBK], a

	;re-enable interrupts
	pop af		
	ld [rIE], a

;If not in 2x CPU mode, everything updates in less than 144 scanlines
;Therefore, normal mode needs an audio update but 60 fps mode does not
	ld a, [rKEY1]
	bit 7, a
	push af
	call nz, DelayFrame	;Delay a frame in 60 fps mode to get the timing down right for any fades
	pop af
	jr nz, .return
	callba Audio1_UpdateMusic	
.return
	ld a, 1
	and a
	ret
	
	
	
IncrementAllColorsGBC_improved:	
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	ret z
	
	ld c, d
	
	push bc
	call CopyGBCFullPalBuffer1to2
	pop bc
	
	;manually disable interrupts
	ld a, [rIE]		
	push af
	xor a
	ld [rIE], a
	
	ld a, [rSVBK]
	set 1, a
	ld [rSVBK], a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, w2GBCFullPalBuffer
	ld b, 128
.mainLoop
	push bc	;save the value in C, which is the amount to lighten this function call

;********************************************************************************************************************
;C = number to add to each R, G, and B value
;HL = pointer for the color bytes to modify

;red
	ld a, [hl]
	ld b, a				
	and %00000011	
	ld d, a				;d = red negative
	ld a, %01111100
	and b				;a = positive
	ld b, c				
	rlc b
	rlc b				;b = amount to add to red
	add b				;a = a + b
	
	cp $7C+1
	jr c, .meetsMaxRed
.makeMaxRed
	ld a, $7C	;Maximum red value if overflow
.meetsMaxRed
	
	or d
	ld [hli], a
	
;blue
	ld a, [hl]
	ld b, a
	and %11100000
	ld e, a				;e = blue negative
	ld a, %00011111
	and b				;a = positive
	add c				;a = a + c

	cp $1F+1
	jr c, .meetsMaxBlue
.makeMaxBlue
	ld a, $1F	;Maximum blue value if underflow
.meetsMaxBlue

	or e
	ld [hld], a

;green
	ld a, [hli]
	ld b, a
	ld a, [hld]

	;load and shift HL five bits to the left
	push hl		;save the pointer
	ld h, 0
	ld l, c
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl

	ld c, a
	;color is now in BC and number to add is in HL
	
	;e = green positive lo = blue negative from above
	;d = green positive hi = red negative from above
	
	;do HL = HL + DE then make sure it's < $03E0+1
	add hl, de
	ld a, l
	sub $E1
	ld a, h
	sbc $03
	ld d, h
	ld e, l
	jr c, .meetsMaxGreen
.makeMaxGreen
	ld de, $03E0	;Maximum green value if overflow
.meetsMaxGreen
	
	
	pop hl	

	;now make BC the green negatives, OR with DE, and load back into HL
	ld a, %01111100
	and b
	or d
	ld [hli], a
	ld a, %00011111
	and c
	or e
	ld [hli], a
;********************************************************************************************************************

	pop bc	;get the number of times to iterate
	dec b
	jr nz, .mainLoop
	ld de, w2GBCFullPalBuffer
	call GBCBufferFastTransfer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ld a, [rSVBK]
	res 1, a
	ld [rSVBK], a

	;re-enable interrupts
	pop af		
	ld [rIE], a

;If not in 2x CPU mode, everything updates in less than 144 scanlines
;Therefore, normal mode needs an audio update but 60 fps mode does not
	ld a, [rKEY1]
	bit 7, a
	push af
	call nz, DelayFrame	;Delay a frame in 60 fps mode to get the timing down right for any fades
	pop af
	jr nz, .return
	callba Audio1_UpdateMusic	
.return
	ld a, 1
	and a
	ret
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
