;joenote - Custom functions to handle shiny pokemon
	
ShinyAttractFunction:
;only if the party leader is lvl 100 or more
	ld a, [wPartyMon1Level]
	cp 100	;do wPartyMon1Level - 100. set carry if result < 0
	ret c	;return if wPartyMon1Level < 100
;and only if it's a chansey
	ld a, [wPartyMon1Species]
	cp CHANSEY
	ret nz
;make a 1 in 255 chance to force shiny IVs on a wild pokemon 
	call Random
	ret nz
	ld a, [wFontLoaded]
	set 7, a 
	ld [wFontLoaded], a
	ret

;joenote - check if enemy mon has gen2 shiny IVs
;zero flag is set if not shiny	
;as a mercy, makes the next encounter shiny via a flag bit if this is a trainer shiny
CheckEnemyShinyIVs:
	push hl
	ld hl, wEnemyMonIVs
	call ShinyIVsChecker
	jr z, .end
	ld a, $01
	and a 
.end
	pop hl
	push af
	call nz, .trainer_mercy
	pop af
	ret
.trainer_mercy
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	ret z ;return if this is a link battle
	ld a, [wBattleType]
	dec a
	jr z, .next_enc_shiny	;grant mercy if this is the old man battle
	ld a, [wFlags_D733]
	bit 6, a
	jr nz, .next_enc_shiny	;grant mercy if this is a tower ghost battle
	CheckEvent EVENT_10E
	jr nz, .next_enc_shiny	;grant mercy if this is the ghost marowak battle
	ld a, [wIsInBattle]
	cp 2
	ret nz	;return if not a trainer battle
.next_enc_shiny
	;at this point, player is facing an AI trainer's shiny pokemon or some kind of uncatchable wild pokemon
	;so make the next wild encounter shiny
	ld a, [wFontLoaded]
	set 7, a 
	ld [wFontLoaded], a
	ret

CheckPlayerShinyIVs:
	push hl
	ld hl, wBattleMonIVs
	call ShinyIVsChecker
	jr z, .end
	ld a, $01
	and a 
.end
	pop hl
	ret
	
CheckLoadedShinyIVs:
	push hl
	ld hl, wLoadedMonIVs
	call ShinyIVsChecker
	jr z, .end
	ld a, $01
	and a 
.end
	pop hl
	ret

ShinyIVsChecker2:	;uses DE instead of HL to better call across banks
	ld h, d
	ld l, e
; hl = IVs -> z if not shiny, nz if shiny: every IV's low two bits are
; SHINY_IV_BITS (1 in 4096; engine/ivs.asm makes them)
ShinyIVsChecker:
	push de
	push bc
	ld de, ShinyIVMask
	ld b, NUM_IVS
.loop
	ld a, [de]
	and [hl]
	ld c, a
	inc de
	ld a, [de]
	inc de
	cp c
	jr nz, .notShiny
	inc hl
	dec b
	jr nz, .loop
	pop bc
	pop de
	ld a, $01
	and a
	ret
.notShiny
	pop bc
	pop de
	xor a
	ret

ShinyIVMask: ; each IV byte's mask and what it must hold
	db $18, $10
	db $C6, $84
	db $31, $21
	db $8C, $08

ShinyPlayerAnimation:
	ld a, [wUnusedD366]
	bit 0, a
	jr nz, .noPlayerShiny
	call CheckPlayerShinyIVs
	jr z, .noPlayerShiny
	push de
	ld d, $00
	ld e, $B6	;select an unused power-up animation	
	callba PlaySelectedAnimation
	pop de
	call SkipPlayerShinybit
	push bc
	ld b, SET_PAL_BATTLE
	call RunPaletteCommand
	pop bc
.noPlayerShiny
	ret
	
ShinyEnemyAnimation:
	ld a, [wUnusedD366]
	bit 7, a
	jr nz, .noEnemyShiny
	call CheckEnemyShinyIVs
	jr z, .noEnemyShiny
	push de
	ld d, $01
	ld e, $B6	;select an unused power-up animation	
	callba PlaySelectedAnimation
	pop de
	call SkipEnemyShinybit
	push bc
	ld b, SET_PAL_BATTLE
	call RunPaletteCommand
	pop bc
.noEnemyShiny
	ret
	
DoPlayerShinybit:
	ld a, [wUnusedD366]
	res 0, a
	ld [wUnusedD366], a
	ret
SkipPlayerShinybit:
	ld a, [wUnusedD366]
	set 0, a
	ld [wUnusedD366], a
	ret
DoEnemyShinybit:
	ld a, [wUnusedD366]
	res 7, a
	ld [wUnusedD366], a
	ret
SkipEnemyShinybit:
	ld a, [wUnusedD366]
	set 7, a
	ld [wUnusedD366], a
	ret

ShinyStatusScreen:
	ld a, [wPalPacket + 3]
	call ShinyDVConvert
	ld [wPalPacket + 3], a
	call PrintShinySymbolStatus
	ret
ShinyPlayerMon:
	ld a, [wPalPacket + 5]
	call ShinyDVConvert
	ld [wPalPacket + 5], a
	ret
ShinyEnemyMon:
	ld a, [wPalPacket + 7]
	call ShinyDVConvert
	ld [wPalPacket + 7], a
	ret
	
ShinyDVConvert:	;'a' holds the default value	
	cp PAL_MEWMON
	jr nz, .next1
	ld a, PAL_YELLOWMON
	jr .endConvert
.next1
	cp PAL_BLUEMON
	jr nz, .next2
	ld a, PAL_PURPLEMON
	jr .endConvert
.next2
	cp PAL_REDMON
	jr nz, .next3
	ld a, PAL_PINKMON
	jr .endConvert
.next3
	cp PAL_CYANMON
	jr nz, .next4
	ld a, PAL_GREENMON
	jr .endConvert
.next4
	cp PAL_PURPLEMON
	jr nz, .next5
	ld a, PAL_GREYMON
	jr .endConvert
.next5
	cp PAL_BROWNMON
	jr nz, .next6
	ld a, PAL_REDMON
	jr .endConvert
.next6
	cp PAL_GREENMON
	jr nz, .next7
	ld a, PAL_BLUEMON
	jr .endConvert
.next7
	cp PAL_PINKMON
	jr nz, .next8
	ld a, PAL_CYANMON
	jr .endConvert
.next8
	cp PAL_YELLOWMON
	jr nz, .next9
	ld a, PAL_BROWNMON
	jr .endConvert
.next9
	cp PAL_GREYMON
	jr nz, .endConvert
	ld a, PAL_MEWMON
.endConvert
	ret
	
PrintShinySymbolStatus:
	coord hl, 8, 1
	ld [hl], "<SHINY>"
	ret	
