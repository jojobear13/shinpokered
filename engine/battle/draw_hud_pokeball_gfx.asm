DrawAllPokeballs:
	call LoadPartyPokeballGfx
	call SetupOwnPartyPokeballs
	ld a, [wIsInBattle]
	dec a
	ret z ; return if wild pokémon
	jp SetupEnemyPartyPokeballs

DrawEnemyPokeballs:
	call LoadPartyPokeballGfx
	jp SetupEnemyPartyPokeballs

LoadPartyPokeballGfx:
	ld de, PokeballTileGraphics
	ld hl, vSprites + $310
	lb bc, BANK(PokeballTileGraphics), (PokeballTileGraphicsEnd - PokeballTileGraphics) / $10
	jp CopyVideoData

SetupOwnPartyPokeballs:
	call PlacePlayerHUDTiles
	ld hl, wPartyMon1
	ld de, wPartyCount
	call SetupPokeballs
	ld a, $60
	ld hl, wBaseCoordX
	ld [hli], a
	ld [hl], a
	ld a, 8
	ld [wHUDPokeballGfxOffsetX], a
	xor a
	ld [wdeed], a
	ld hl, wOAMBuffer
	jp WritePokeballOAMData

SetupEnemyPartyPokeballs:
	call PlaceEnemyHUDTiles
	ld hl, wEnemyMons
	ld de, wEnemyPartyCount
	call SetupPokeballs
	ld hl, wBaseCoordX
	ld a, $48
	ld [hli], a
	ld [hl], $20
	ld a, -8
	ld [wHUDPokeballGfxOffsetX], a
	ld a, $1
	ld [wdeed], a
	ld hl, wOAMBuffer + PARTY_LENGTH * 4
	jp WritePokeballOAMData

SetupPokeballs:
	ld a, [de]
	push af
	ld de, wBuffer
	ld c, PARTY_LENGTH
	ld a, $34 ; empty pokeball
.emptyloop
	ld [de], a
	inc de
	dec c
	jr nz, .emptyloop
	pop af
	ld de, wBuffer
.monloop
	push af
	call PickPokeball
	inc de
	pop af
	dec a
	jr nz, .monloop
	ret

PickPokeball:
	inc hl
	ld a, [hli]
	and a
	jr nz, .alive
	ld a, [hl]
	and a
	ld b, $33 ; crossed ball (fainted)
	jr z, .done_fainted
.alive
	inc hl
	inc hl
	ld a, [hl] ; status
	and a
	ld b, $32 ; black ball (status)
	jr nz, .done
	dec b ; regular ball
	jr .done
.done_fainted
	inc hl
	inc hl
.done
	ld a, b
	ld [de], a
	ld bc, wPartyMon2 - wPartyMon1Status
	add hl, bc ; next mon struct
	ret

WritePokeballOAMData:
	ld de, wBuffer
	ld c, PARTY_LENGTH
.loop
	ld a, [wBaseCoordY]
	ld [hli], a
	ld a, [wBaseCoordX]
	ld [hli], a
	ld a, [de]
	ld [hli], a
	ld a, [wdeed]
	ld [hli], a
	ld a, [wBaseCoordX]
	ld b, a
	ld a, [wHUDPokeballGfxOffsetX]
	add b
	ld [wBaseCoordX], a
	inc de
	dec c
	jr nz, .loop
	ret

PlacePlayerHUDTiles:
	ld hl, PlayerBattleHUDGraphicsTiles
	ld de, wHUDGraphicsTiles
	ld bc, $3
	call CopyData

;joenote - let's draw a shiny symbol if applicable
	ld a, [wUnusedD366]
	bit 0, a
	jr z, .noshiny
	coord hl, 9, 7
	ld [hl], "<SHINY>"
.noshiny
	
	coord hl, 18, 10
	ld de, -1
	jp PlaceHUDTiles

PlayerBattleHUDGraphicsTiles:
; The tile numbers for specific parts of the battle display for the player's pokemon
	db $73 ; unused ($73 is hardcoded into the routine that uses these bytes)
	db $77 ; lower-right corner tile of the HUD
	db $6F ; lower-left triangle tile of the HUD

PlaceEnemyHUDTiles:
	ld hl, EnemyBattleHUDGraphicsTiles
	ld de, wHUDGraphicsTiles
	ld bc, $3
	call CopyData

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - don't draw any special symbols for ghost battles, including ghost marowak
	ld a, [wFlags_D733]
	bit 6, a
	jr nz, .noDraw 
	CheckEvent EVENT_10E
	jr nz, .noDraw

;joenote - let's draw a shiny symbol if applicable
	ld a, [wUnusedD366]
	bit 7, a
	jr z, .noshiny
	coord hl, 0, 0
	ld [hl], "<SHINY>"
.noshiny

;don't draw any further special sybols if in a non-wild battle
	ld a, [wIsInBattle]
	cp 1
	jr nz, .noDraw	;don't draw anything for non-wild battles
	
;while we're at it, let's also do some nuzelock mode stuff
	predef EncounterLoad_NuzlockeHandler

;let's draw a pokeball to indicate an owned mon
;also let's handle a gender symbol	
	CheckEvent EVENT_90E
	jr z, .noDraw
	
	push de
	push bc
	;get attack DV
	ld a, [wEnemyMonDVs]
	swap a
	and $0F
	ld e, a
	;get species
	ld a, [wEnemyMonSpecies]
	ld d, a
	callba DetermineMonGender
	ld a, d
	and a
	jr z, .nosymbol
	coord hl, 3, 1
	ld [hl], a
.nosymbol
	pop bc
	pop de

	push bc
	callba IsEnemyMonOwned
	pop bc
	jr z, .noDraw
	;load the indicator tiles to be drawn
	coord hl, 1, 1
	ld [hl], "<BALL>"
.noDraw
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	coord hl, 1, 2
	ld de, $1
	jp PlaceHUDTiles

EnemyBattleHUDGraphicsTiles:
; The tile numbers for specific parts of the battle display for the enemy
	db $73 ; unused ($73 is hardcoded in the routine that uses these bytes)
	db $74 ; lower-left corner tile of the HUD
	db $78 ; lower-right triangle tile of the HUD

PlaceHUDTiles:
	ld [hl], $73
	ld bc, SCREEN_WIDTH
	add hl, bc
	ld a, [wHUDGraphicsTiles + 1] ; leftmost tile
	ld [hl], a
	ld a, 8
.loop
	add hl, de
	ld [hl], $76
	dec a
	jr nz, .loop
	add hl, de
	ld a, [wHUDGraphicsTiles + 2] ; rightmost tile
	ld [hl], a
	
	;joenote - show or clear the damage values
	CheckEvent EVENT_910
	jr z, .end_printdamage
	coord hl, 6, 4
	ld de, wBattleMonHP ; current player HP
	call .isDEzero
	jr z, .printwhite
	ld de, wEnemyMonHP ; current enemy HP
	call .isDEzero
	jr z, .printwhite
	ld de, wDamage ; current damage
	call .isDEzero
	jr nz, .printdamage
.printwhite
	;load white tiles
	ld a, $7f
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	jr .end_printdamage
.printdamage	
	lb bc, LEADING_ZEROES | 2, 5 ; 2 bytes, 5 digits
	call PrintNumber
.end_printdamage	

	ret

.isDEzero
	ld a, [de]
	ld b, a
	inc de
	ld a, [de]
	dec de
	or b
	ret

	
SetupPlayerAndEnemyPokeballs:
	call LoadPartyPokeballGfx
	ld hl, wPartyMons
	ld de, wPartyCount
	call SetupPokeballs
	ld hl, wBaseCoordX
	ld a, $50
	ld [hli], a
	ld [hl], $40
	ld a, 8
	ld [wHUDPokeballGfxOffsetX], a
	xor a
	ld [wdeed], a
	ld hl, wOAMBuffer
	call WritePokeballOAMData
	ld hl, wEnemyMons
	ld de, wEnemyPartyCount
	call SetupPokeballs
	ld hl, wBaseCoordX
	ld a, $50
	ld [hli], a
	ld [hl], $68
;	ld a, $1
	xor a ;gbcnote - make the enemy pokeballs use the same color register as the player
	ld [wdeed], a
	ld hl, wOAMBuffer + $18
	jp WritePokeballOAMData

; four tiles: pokeball, black pokeball (status ailment), crossed out pokeball (fainted) and pokeball slot (no mon)
PokeballTileGraphics::
	INCBIN "gfx/pokeball.2bpp"
PokeballTileGraphicsEnd:
