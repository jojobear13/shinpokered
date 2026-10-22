; try to initiate a wild pokemon encounter
; returns success in Z
TryDoWildEncounter:
	ld a, [wNPCMovementScriptPointerTableNum]
	and a
	ret nz
	ld a, [wd736]
	and a
	ret nz
	callab IsPlayerStandingOnDoorTileOrWarpTile
	jr nc, .notStandingOnDoorOrWarpTile
.CantEncounter
	ld a, $1
	and a
	ret
.notStandingOnDoorOrWarpTile
	callab IsPlayerJustOutsideMap
	jr z, .CantEncounter
	ld a, [wRepelRemainingSteps]
	and a
	jr z, .next
	dec a
	jp z, .lastRepelStep
	ld [wRepelRemainingSteps], a
.next
; determine if wild pokemon can appear in the half-block we're standing in
; is the encounter tile of the half-block we're standing in a grass/water tile?
;joenote - modified to use constants to keep everything consistent and avoid missingno glitch
	coord hl, ENCOUNTER_TILE_COORD_X, ENCOUNTER_TILE_COORD_Y
	ld c, [hl]
	ld a, [wGrassTile]
	cp c
	ld a, [wGrassRate]
	jr z, .CanEncounter
	ld a, $14 ; in all tilesets with a water tile, this is its id
	cp c
	ld a, [wWaterRate]
	jr z, .CanEncounter
; even if not in grass/water, standing anywhere we can encounter pokemon
; so long as the map is "indoor" and has wild pokemon defined.
; ...as long as it's not Viridian Forest or Safari Zone.
	ld a, [wCurMap]
	cp REDS_HOUSE_1F ; is this an indoor map?
	jp c, .CantEncounter2
	ld a, [wCurMapTileset]
	cp FOREST ; Viridian Forest/Safari Zone
	jp z, .CantEncounter2
	ld a, [wGrassRate]
.CanEncounter
; compare encounter chance with a random number to determine if there will be an encounter
	ld b, a
; a Cleanse Tag on the first mon cuts the encounter rate by a third
	ld a, [wPartyMon1CatchRate]
	cp CLEANSE_TAG
	jr nz, .gotRate
	ld a, b
	ld c, -1
.divideBy3
	inc c
	sub 3
	jr nc, .divideBy3
	ld a, b
	sub c
	ld b, a
.gotRate
	ld a, [hRandomAdd]
	cp b
	jr nc, .CantEncounter2
	ld a, [hRandomSub]
	ld b, a
	ld hl, WildMonEncounterSlotChances
.determineEncounterSlot
	ld a, [hli]
	cp b
	jr nc, .gotEncounterSlot
	inc hl
	jr .determineEncounterSlot
.gotEncounterSlot
; determine which wild pokemon (grass or water) can appear in the half-block we're standing in
	ld c, [hl]
	ld hl, wGrassMons
;joenote - modified to use constants to keep everything consistent and avoid missingno glitch
	aCoord ENCOUNTER_TILE_COORD_X, ENCOUNTER_TILE_COORD_Y
	cp $14 ; is the encounter tile of the half-block we're standing in a water tile?
	jr nz, .gotWildEncounterType ; if not, it's treated as a grass tile by default
	ld hl, wWaterMons
; since the bottom right tile of a "left shore" half-block used to be $14 but the bottom left tile was not,
; "left shore" half-blocks (such as the one in the east coast of Cinnabar) loaded grass encounters & gave missingno.
.gotWildEncounterType
	ld b, 0
	add hl, bc
	ld a, [hli]
	ld [wCurEnemyLVL], a
	ld a, [hl]
	ld [wcf91], a
	ld [wEnemyMonSpecies2], a
	ld e, c
	callba RandoWildArea ; WILD AREA: the slot's own #MON
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - expand the safari zone random encounters
	callba GetRandMonSafari
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - check for shiny DV attract conditions
	callba ShinyAttractFunction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;joenote - generate a random wild pokemon based on a seed value
	predef ReplaceWildMon
	callba RandoScaleDownWild ; the randomizer: not above the party
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; a REPEL keeps away mons lower level than the first party mon, and the
; DEXREPEL mons already caught (engine/items/held_item_use.asm)
	callab WildRepelCheck
	jr c, .shinycheck_repel
	jr .willEncounter
.lastRepelStep
	ld [wRepelRemainingSteps], a
	ld a, TEXT_REPEL_WORE_OFF
	ld [hSpriteIndexOrTextID], a
	call EnableAutoTextBoxDrawing
	call DisplayTextID
.CantEncounter2
	ld a, $1
	and a
	ret
.willEncounter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - disallow mew if pokedex not complete
	callba DisallowWildMew
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	xor a
	ret
.shinycheck_repel
;joenote - initiate encounter if shiny (overrides repel)
	ld a, [wFontLoaded]
	bit 7, a
	jr nz, .willEncounter
	jr .CantEncounter2

;joenote - This is obsolete and no longer needed.
;fix a grass tile not generating encounters
;c = lower-left tile to check
;gives z if grass tile
;give nz if not grass tile
;TestGrassTile:
;	ld a, [wGrassTile]
;	cp c
;	jr z, .return
;	ld a, [wCurMapTileset]
;	cp FOREST
;	jr nz, .return
;	ld a, $34	;check for the extra grass tile in the forest tileset
;	cp c
;.return
;	ret
	
WildMonEncounterSlotChances:
; There are 10 slots for wild pokemon, and this is the table that defines how common each of
; those 10 slots is. A random number is generated and then the first byte of each pair in this
; table is compared against that random number. If the random number is less than or equal
; to the first byte, then that slot is chosen.  The second byte is double the slot number.
	db $32, $00 ; 51/256 = 19.9% chance of slot 0
	db $65, $02 ; 51/256 = 19.9% chance of slot 1
	db $8C, $04 ; 39/256 = 15.2% chance of slot 2
	db $A5, $06 ; 25/256 =  9.8% chance of slot 3
	db $BE, $08 ; 25/256 =  9.8% chance of slot 4
	db $D7, $0A ; 25/256 =  9.8% chance of slot 5
	db $E4, $0C ; 13/256 =  5.1% chance of slot 6
	db $F1, $0E ; 13/256 =  5.1% chance of slot 7
	db $FC, $10 ; 11/256 =  4.3% chance of slot 8
	db $FF, $12 ;  3/256 =  1.2% chance of slot 9
