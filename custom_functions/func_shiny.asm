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
;make a 1 in 255 chance to force shiny DVs on a wild pokemon 
	call Random
	ret nz
	ld a, [wFontLoaded]
	set 7, a 
	ld [wFontLoaded], a
	ret

;joenote - check if enemy mon has gen2 shiny DVs
;zero flag is set if not shiny	
;as a mercy, makes the next encounter shiny via a flag bit if this is a trainer shiny
CheckEnemyShinyDVs:
	push hl
	ld hl, wEnemyMonDVs
	ld a, [wEnemyBattleStatus3]
	bit TRANSFORMED, a
	jr z, .next
	ld hl, wTransformedEnemyMonOriginalDVs
.next
	call ShinyDVsChecker
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

CheckPlayerShinyDVs:
	push hl
	ld hl, wBattleMonDVs
	ld a, [wPlayerBattleStatus3]
	bit TRANSFORMED, a
	jr z, .next
	push bc
	ld hl, wPartyMon1DVs
	ld a, [wPlayerMonNumber]
	ld bc, (wPartyMon2 - wPartyMon1)
	call AddNTimes
	pop bc
.next
	call ShinyDVsChecker
	jr z, .end
	ld a, $01
	and a 
.end
	pop hl
	ret
	
CheckLoadedShinyDVs:
	push hl
	ld hl, wLoadedMonDVs
	call ShinyDVsChecker
	jr z, .end
	ld a, $01
	and a 
.end
	pop hl
	ret

ShinyDVsChecker2:	;uses DE instead of HL to better call across banks
	ld h, d
	ld l, e
ShinyDVsChecker:	;return z flag set if not shiny or cleared z flag if shiny
	ld a, [hl]	;load MSB
	bit 5, a	;bit 5 of the MSB need to be a 1 for shininess
	jr z, .end_zero
	and $0F	;now mask out the lesser nybble of the MSB
	cp $0A	;need to be a DV of 10 for shininess
	jr nz, .end_zero
	inc hl
	ld a, [hl]	;load LSB
	cp a, $AA	;need to be DVs of 10 for shininess
	jr nz, .end_zero
	ld a, $01
	and a 
	ret
.end_zero
	xor a
	ret

ShinyPlayerAnimation:
	ld a, [wUnusedD366]
	bit 0, a
	jr nz, .noPlayerShiny
	call CheckPlayerShinyDVs
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
	call CheckEnemyShinyDVs
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
