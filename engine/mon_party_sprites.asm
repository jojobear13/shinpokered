AnimatePartyMon_ForceSpeed1:
	xor a
	ld [wCurrentMenuItem], a
	ld b, a
	inc a
	jr GetAnimationSpeed

; wPartyMenuHPBarColors contains the party mon's health bar colors
; 0: green
; 1: yellow
; 2: red
AnimatePartyMon:
	ld hl, wPartyMenuHPBarColors
	ld a, [wCurrentMenuItem]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]

GetAnimationSpeed:
	ld c, a
	ld hl, PartyMonSpeeds
	add hl, bc
	ld a, [wOnSGB]
	xor $1
	add [hl]
	ld c, a
	add a
	ld b, a
	ld a, [wAnimCounter]
	and a
	jr z, .resetSprites
	cp c
	jr z, .animateSprite
.incTimer
	inc a
	cp b
	jr nz, .skipResetTimer
	xor a ; reset timer
.skipResetTimer
	ld [wAnimCounter], a
	jp DelayFrame
.resetSprites
	push bc
	ld hl, wMonPartySpritesSavedOAM
	ld de, wOAMBuffer
	ld bc, $60
	call CopyData
	pop bc
	xor a
	jr .incTimer
.animateSprite
	push bc
	ld hl, wOAMBuffer + $02 ; OAM tile id
	ld bc, $10
	ld a, [wCurrentMenuItem]
	call AddNTimes
	ld c, $40 ; the second frame's tiles are $40 on
	ld b, $4
	ld de, $4
.loop
	ld a, [hl]
	add c
	ld [hl], a
	add hl, de
	dec b
	jr nz, .loop
	pop bc
	ld a, c
	jr .incTimer

; Party mon animations cycle between 2 frames.
; The members of the PartyMonSpeeds array specify the number of V-blanks
; that each frame lasts for green HP, yellow HP, and red HP in order.
; On the naming screen, the yellow HP speed is always used.
PartyMonSpeeds:
	db 5, 16, 32

; Each party mon has its own icon (gfx/party_icons_*.png, by tools/
; gen_party_icons.py): two 16x16 frames, four tiles each. Party slot n's go to
; sprite tiles 4n (the first frame) and $40 + 4n (the second).

LoadMonPartySpriteGfx:
; Load the party's icons, and the trade's circle, during V-blank.
	ld hl, TradeCirclePointers
	ld a, 2
	call LoadAnimSpriteGfx
	jp LoadPartyIcons

LoadAnimSpriteGfx:
; Load animated sprite tile patterns into VRAM during V-blank. hl is the address
; of an array of structures that contain arguments for CopyVideoData and a is
; the number of structures in the array.
	ld bc, $0
.loop
	push af
	push bc
	push hl
	add hl, bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CopyVideoData
	pop hl
	pop bc
	ld a, $6
	add c
	ld c, a
	pop af
	dec a
	jr nz, .loop
	ret

LoadMonPartySpriteGfxWithLCDDisabled:
; Load the party's icons, and the trade's circle, at once with the LCD off.
	call DisableLCD
	ld hl, MonPartySprites + $100
	ld de, vSprites + $380
	ld bc, $40
	ld a, BANK(MonPartySprites)
	call FarCopyData2
	ld hl, MonPartySprites + $140
	ld de, vSprites + $780
	ld bc, $40
	ld a, BANK(MonPartySprites)
	call FarCopyData2
	call LoadPartyIcons
	jp EnableLCD

; the trade's circle around the mon in the cable (Trade_WriteCircleOAM):
; tiles $38 and $78 on, clear of the icons'
TradeCirclePointers:
	dw MonPartySprites + $100
	db $40 / $10 ; $40 bytes
	db BANK(MonPartySprites)
	dw vSprites + $380

	dw MonPartySprites + $140
	db $40 / $10 ; $40 bytes
	db BANK(MonPartySprites)
	dw vSprites + $780

; each party mon's icon -> its slot's tiles
LoadPartyIcons:
	ld hl, wPartySpecies
	ld e, 0
.loop
	ld a, [hli]
	cp $ff
	ret z
	push hl
	push de
	call LoadPartyIcon
	pop de
	pop hl
	inc e
	ld a, e
	cp PARTY_LENGTH
	jr c, .loop
	ret

; a = a species (or EGG), e = a party slot -> its icon's two frames into the
; slot's tiles: at once with the LCD off, else in V-blank
LoadPartyIcon:
	call PartyIconOffset
	push hl
	ld l, e
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl ; 4 tiles of 16 bytes a slot
	ld de, vSprites
	add hl, de
	ld d, h
	ld e, l ; the first frame's tiles
	pop hl
	push hl
	push de
	ld bc, PartyIcons1
	add hl, bc
	ld a, BANK(PartyIcons1)
	call .copy
	pop de
	pop hl
	ld bc, PartyIcons2
	add hl, bc
	push hl
	ld hl, $400 ; the second frame's tiles, $40 on
	add hl, de
	ld d, h
	ld e, l
	pop hl
	ld a, BANK(PartyIcons2)
; a = bank, hl = an icon, de = its tiles
.copy
	ld b, a
	ld a, [rLCDC]
	bit 7, a
	jr nz, .lcdOn
	ld a, b
	ld bc, 4 * $10
	jp FarCopyData2
.lcdOn
	push de
	ld d, h
	ld e, l
	pop hl
	ld c, 4
	jp CopyVideoData

; a = a species (or EGG) -> hl = its icon's offset in either frame's data;
; keeps de
PartyIconOffset:
	cp EGG
	ld b, NUM_POKEMON ; the egg's is after Mew's
	jr z, .gotIcon
	push de
	ld [wd11e], a
	predef IndexToPokedex
	pop de
	ld a, [wd11e]
	dec a
	ld b, a
.gotIcon
	ld l, b
	ld h, 0
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl ; 64 bytes an icon
	ret

WriteMonPartySpriteOAMByPartyIndex:
; Write OAM blocks for the party mon in [hPartyMonIndex] (its icon is in its
; slot's tiles).
	push hl
	push de
	push bc
	ld a, [hPartyMonIndex]
	add a
	add a
	call WriteMonPartySpriteOAM
	pop bc
	pop de
	pop hl
	ret

WriteMonPartySpriteOAMBySpecies:
; Load the icon of the species in [wMonPartySpriteSpecies] into slot 0's
; tiles and write its OAM blocks there.
	xor a
	ld [hPartyMonIndex], a
	ld a, [wMonPartySpriteSpecies]
	ld e, 0
	call LoadPartyIcon
	xor a
; fall through

WriteMonPartySpriteOAM:
; Write the OAM blocks for the first animation frame of the icon at tile a
; into the OAM buffer and make a copy at wMonPartySpritesSavedOAM.
	ld [wOAMBaseTile], a
	ld c, $10
	ld h, wOAMBuffer / $100
	ld a, [hPartyMonIndex]
	swap a
	ld l, a
	add $10
	ld b, a
	call WriteAsymmetricMonPartySpriteOAM
; Make a copy of the OAM buffer with the first animation frame written so that
; we can flip back to it from the second frame by copying it back.
	ld hl, wOAMBuffer
	ld de, wMonPartySpritesSavedOAM
	ld bc, $60
	jp CopyData

MonPartySprites: ; (only the trade's circle is used now)
	INCBIN "gfx/mon_ow_sprites.2bpp"
