w2BGMapAttributesPointer	EQU $d0fe 	;In wram bank 2 (GBC only). This is 2 bytes.
w2BGMapAttributes 		EQU $d100 	;In wram bank 2 (GBC only). This is 1024 bytes (32 by 32).
w2BGMapAttributes_End 	EQU $d500
const_value = 0

	const PAL_ENH_OVW_RED     	; $00
	const PAL_ENH_OVW_GREEN    	; $01
	const PAL_ENH_OVW_BLUE  	; $02
	const PAL_ENH_OVW_BROWN    	; $03
	const PAL_ENH_OVW_YELLOW  	; $04
	const PAL_ENH_OVW_PINK  	; $05
	const PAL_ENH_OVW_PURPLE 	; $06
	const PAL_ENH_OVW_GRAY   	; $07

GBCEnhancedOverworldPalettes:	
	; PAL_ENH_OVW_RED     	; $00
	RGB 31, 31, 31
	RGB 31, 10,  0
	RGB 21,  0,  0
	RGB  3,  3,  3
	
	; PAL_ENH_OVW_GREEN    	; $01
	RGB 31, 31, 31
	RGB 17, 31, 11
	RGB  1, 22,  6
	RGB  3,  3,  3
	
	; PAL_ENH_OVW_BLUE  	; $02
	RGB 31, 31, 31
	RGB 12, 14, 31
	RGB  0,  1, 25
	RGB  3,  3,  3

	; PAL_ENH_OVW_BROWN    	; $03
	RGB 31, 31, 31
	RGB 22, 16,  5
	RGB 15,  7,  3
	RGB  3,  3,  3

	; PAL_ENH_OVW_YELLOW  	; $04
	RGB 31, 31, 31
	RGB 31, 31,  0
	RGB 28, 14,  0
	RGB  3,  3,  3

	; PAL_ENH_OVW_PINK  	; $05
	RGB 31, 31, 31
	RGB 31, 15, 18
	RGB 31,  0,  6
	RGB  3,  3,  3

	; PAL_ENH_OVW_PURPLE 	; $06
	RGB 31, 31, 31
	RGB 25, 15, 31
	RGB 19,  0, 22
	RGB  3,  3,  3

	; PAL_ENH_OVW_GRAY   	; $07
	RGB 31, 31, 31
	RGB 20, 23, 10
	RGB 11, 11,  5
	RGB  3,  3,  3


	
;This copies everything in wTileMap to w2BGMapAttributes in wram bank 2
;It additionally takes into account where the viewable tile map area is positioned in the BG Map grid
;It then calls the procedure to convert all the tile values to BG Map Attribute palettes
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

;first find the offset of the visible 20x18 tile map within the BG Map and set that as the starting destination 
	ld a, [wMapViewVRAMPointer]
	ld e, a
	ld a, [wMapViewVRAMPointer+1]
	ld d, a
	ld hl, ($FFFF - vBGMap0 + 1)
	add hl, de
	ld de, w2BGMapAttributes
	add hl, de
	ld d, h
	ld e, l
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	di	;disable the interrupts while messing around in the other wram bank since a bunch of stuff runs during vblank
	ld hl, rSVBK
	set 1, [hl]		;switch over to wram bank 2 (covers everything from address D700 to DFFF)
	;back up the pointer
	ld a, d
	ld [w2BGMapAttributesPointer], a
	ld a, e
	ld [w2BGMapAttributesPointer+1], a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	ld hl, wTileMap
	ld b, 18 	;tile map height
	ld c, 20	;tile map width
.w2ramCopyLoop
	push bc
	call MakeOverworldBGMapAttributes_CopyRow
	pop bc
;reset to the correct starting column
	push bc
	ld c, 32 - 20
.rowIncrementLoop
	call .incrementRow
	dec c
	jr nz, .rowIncrementLoop
	pop bc
;now move down to the next row
	ld a, 32
	add e	
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
;wrap around to the top row of the BG Map Attributes if needed
	ld a, d
	push bc
	ld bc, w2BGMapAttributes_End
	sub b
	pop bc
	jr c, .carry	;if the value of D is less that $D5, then we haven't gone over
	;else wrap back to first row
	ld a, d
	sub 4
	ld d, a
.carry
	dec b
	jr nz, .w2ramCopyLoop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
	ld a, [w2BGMapAttributesPointer]
	ld d, a
	ld a, [w2BGMapAttributesPointer+1]
	ld e, a

	ld a, [de]
	push af
	call ConvertTile2PalSetting		;do one conversion at the start just to initialize HL to where it needs to be
	pop af
	ld [de], a

	ld b, 18 	;tile map height
	ld c, 20	;tile map width
.w2ramConvertLoop
	push bc
	call MakeOverworldBGMapAttributes_ConvertRow
	pop bc
;reset to the correct starting column
	push bc
	ld c, 32 - 20
.rowIncrementLoop2
	call .incrementRow
	dec c
	jr nz, .rowIncrementLoop2
	pop bc
;now move down to the next row
	ld a, 32
	add e	
	ld e, a
	jr nc, .noCarry2
	inc d
.noCarry2
;wrap around to the top row of the BG Map Attributes if needed
	ld a, d
	push bc
	ld bc, w2BGMapAttributes_End
	sub b
	pop bc
	jr c, .carry2	;if the value of D is less that $D5, then we haven't gone over
	;else wrap back to first row
	ld a, d
	sub 4
	ld d, a
.carry2
	dec b
	jr nz, .w2ramConvertLoop	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.return
	;restore the original wram bank and return
	ld hl, rSVBK
	res 1, [hl]
	ei	;re-enable interrupts
	ret
.incrementRow
	ld a, e
	and $1F
	cp $1F
	jr nz, .incrementE
	ld a, e
	sub $1F
	ld e, a
	ret
.incrementE
	inc e
	ret
	
MakeOverworldBGMapAttributes_CopyRow:
	ld a, [hli]
	ld [de], a
	ld a, e
	and $1F
	cp $1F
	jr nz, .incrementE
	ld a, e
	sub $1F
	ld e, a
	jr .decrementC
.incrementE
	inc e
.decrementC
	dec c
	jr nz, MakeOverworldBGMapAttributes_CopyRow
	ret

MakeOverworldBGMapAttributes_ConvertRow:
	push bc
	call ConvertTile2PalSetting.doWrite
	pop bc
	ld a, e
	and $1F
	cp $1F
	jr nz, .incrementE
	ld a, e
	sub $1F
	ld e, a
	jr .decrementC
.incrementE
	inc e
.decrementC
	dec c
	jr nz, MakeOverworldBGMapAttributes_ConvertRow
	ret


	
;Replace a tile value pointed to by DE with its desired BG Map Attribute palette
;Clobbers BC and HL
;Preserves HL pointing to the proper PalSettings_ tileset so it can be quickly called over and over
ConvertTile2PalSetting:	
	ld hl, rSVBK
	res 1, [hl]
	ld a, [wCurMapTileset]
	set 1, [hl]
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
	
.doWrite	
	ld a, [de]
	cp $60	;tilesets only go up to $5F
	jr nc, .errorTrap
	ld c, a
	ld b, 0
	push hl
	add hl, bc
	ld a, [hl]
	pop hl
	ld [de], a
	cp 8	;check for town-based color register
	ret nz
.townColor
	push hl
	ld hl, rSVBK
	res 1, [hl]
	ld a, [wCurMap]
	set 1, [hl]
	ld c, a
	ld b, 0
	ld hl, PalSettings_TownSpecialPal	
	add hl, bc
	ld a, [hl]	
	pop hl
	ld [de], a
	ld a, SAFFRON_CITY
	cp c
	ret nc
	ld a, PAL_ENH_OVW_GRAY	;for routes and other such maps
	ld [de], a
	ret
.errorTrap
	xor a
	ld [de], a
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

	
	
;This function writes the palettes used for the overworld to the GBC palette registers
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
;	xor a
;	ld [wGBCColorControl], a
;	ld hl, GBCEnhancedOverworldPalettes	
;.loopBG
;	ld a, [hli]
;	ld e, a
;	ld a, [hli]
;	ld d, a
;	push hl
;	callba WriteColorGBC
;	pop hl
;	ld a, [wGBCColorControl]
;	inc a
;	and $1F
;	ld [wGBCColorControl], a
;	jr nz, .loopBG
;	
;	ld a, $20
;	ld [wGBCColorControl], a
;	ld hl, GBCEnhancedOverworldPalettes	
;.loopOB
;	ld a, [hli]
;	ld e, a
;	ld a, [hli]
;	ld d, a
;	push hl
;	callba WriteColorGBC
;	pop hl
;	ld a, [wGBCColorControl]
;	inc a
;	and $3F
;	ld [wGBCColorControl], a
;	jr nz, .loopOB
;
;	ret


	
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

;We're on a GBC and this stuff takes a while. Switch to double speed mode if not already.
	ld a, [rKEY1]
	bit 7, a
	ld a, $ff
	jr nz, .doublespeed	
	predef SetCPUSpeed
	xor a
.doublespeed
	push af

	;prevent the BGmap from updating during vblank 
	;because this is going to take a frame or two in order to fully run
	;otherwise a partial update (like during a screen whiteout) can be distracting
	ld hl, hFlagsFFFA
	set 1, [hl]

	ld de, rBGP
	
	call BufferAllEnhancedColorsGBC.BGP0to3Loop
	call BufferAllEnhancedColorsGBC.BGP4to7Loop
	call .TransferPals
	
	ld hl, hFlagsFFFA	;re-allow BGmap updates
	res 1, [hl]
	
	pop af
	inc a
	ret z	;return now if 2x cpu mode was already active at the start of this function
	;otherwise return to single cpu mode and return
	predef SingleCPUSpeed
	ret

.TransferPals
	xor a
	ld [wGBCColorControl], a
	ld hl, wGBCFullPalBuffer	
.loopBG
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
	push hl
	callba WriteColorGBC
	pop hl
	ld a, [wGBCColorControl]
	inc a
	ld [wGBCColorControl], a
	cp 32
	jr c, .loopBG
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

;We're on a GBC and this stuff takes a while. Switch to double speed mode if not already.
	ld a, [rKEY1]
	bit 7, a
	ld a, $ff
	jr nz, .doublespeed	
	predef SetCPUSpeed
	xor a
.doublespeed
	push af

	ld a, d
	dec a
	jr nz, .OBP1
.OBP0
	ld de, rOBP0
	dec de	;this will get incremented in the next call
	call BufferAllEnhancedColorsGBC.OBP0to3Loop
	ld a, 32
	ld [wGBCColorControl], a
	ld hl, wGBCFullPalBuffer + 64	
	jr .transfer
.OBP1
	ld de, rOBP1
	dec de	;this will get incremented in the next call
	call BufferAllEnhancedColorsGBC.OBP4to7Loop
	ld a, 48
	ld [wGBCColorControl], a
	ld hl, wGBCFullPalBuffer + 96	
.transfer
	call .TransferPals

	pop af
	inc a
	ret z	;return now if 2x cpu mode was already active at the start of this function
	;otherwise return to single cpu mode and return
	predef SingleCPUSpeed
	ret

.TransferPals
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
	push hl
	callba WriteColorGBC
	pop hl
	ld a, [wGBCColorControl]
	inc a
	ld [wGBCColorControl], a
	and $0F
	jr nz, .TransferPals
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
db	7,	3,	3,	5,	3,	8,	8,	8,	8,	8,	7,	3,	3,	7,	3,	7;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	7,	3,	8,	3,	2,	8,	8,	8,	8,	8,	7,	3,	3,	7,	3,	7;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	7,	7,	7,	7,	3,	8,	8,	3,	8,	8,	7,	7,	1,	1,	1,	7;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	1,	3,	3,	3,	3,	3,	3,	3,	8,	1,	7,	7,	3,	1,	1,	7;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	1,	1,	0,	0,	2,	2,	3,	3,	3,	3,	7,	7,	8,	8,	7,	7;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	1,	1,	1,	8,	3,	3,	3,	3,	3,	3,	8,	0,	8,	8,	7,	7;
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
	db	PAL_ENH_OVW_BROWN	;	PEWTER_CITY,		; $02
	db	PAL_ENH_OVW_BLUE	;	CERULEAN_CITY,		; $03
	db	PAL_ENH_OVW_PURPLE	;	LAVENDER_TOWN,		; $04
	db	PAL_ENH_OVW_RED		;	VERMILION_CITY,		; $05
	db	PAL_ENH_OVW_GREEN	;	CELADON_CITY,		; $06
	db	PAL_ENH_OVW_PINK	;	FUCHSIA_CITY,		; $07
	db	PAL_ENH_OVW_RED		;	CINNABAR_ISLAND,	; $08
	db	PAL_ENH_OVW_BLUE	;	INDIGO_PLATEAU,		; $09
	db	PAL_ENH_OVW_YELLOW	;	SAFFRON_CITY,		; $0A
