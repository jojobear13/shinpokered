Audio3_PlaySound::
	ld [wSoundID], a
	cp $ff
	jp z, .stopAllAudio
	cp MUSIC3_FIRST_ENTRY
	jp c, .playSfx
	cp MUSIC3_END - 1
	jr z, .playMusic
	jp nc, .playSfx
.playMusic
	call InitMusicVariables
	jp Audio3_7db03

.playSfx
	ld l, a
	ld e, a
	ld h, $0
	ld d, h
	add hl, hl
	add hl, de
	ld de, SFX_Headers_3
	add hl, de
	ld a, h
	ld [wSfxHeaderPointer], a
	ld a, l
	ld [wSfxHeaderPointer + 1], a
	ld a, [hl]
	and $c0
	rlca
	rlca
	ld c, a
.asm_7d9db
	ld d, c
	ld a, c
	add a
	add c
	ld c, a
	ld b, $0
	ld a, [wSfxHeaderPointer]
	ld h, a
	ld a, [wSfxHeaderPointer + 1]
	ld l, a
	add hl, bc
	ld c, d
	ld a, [hl]
	and $f
	ld e, a
	ld d, $0
	ld hl, wChannelSoundIDs
	add hl, de
	ld a, [hl]
	and a
	jr z, .asm_7da17
	ld a, e
	cp $7
	jr nz, .asm_7da0e
	ld a, [wSoundID]
	cp $14
	jr nc, .asm_7da07
	ret
.asm_7da07
	ld a, [hl]
	cp $14
	jr z, .asm_7da17
	jr c, .asm_7da17
.asm_7da0e
	ld a, [wSoundID]
	cp [hl]
	jr z, .asm_7da17
	jr c, .asm_7da17
	ret
.asm_7da17
	call InitSFXVariables
.asm_7da9f
	ld a, c
	and a
	jp z, Audio3_7db03
	dec c
	jp .asm_7d9db

.stopAllAudio
	call StopAllAudio
	ret

Audio3_7db03:
	ld a, [wSoundID]
	ld l, a
	ld e, a
	ld h, $0
	ld d, h
	add hl, hl
	add hl, de
	ld de, SFX_Headers_3
	add hl, de
	ld e, l
	ld d, h
	ld hl, wChannelCommandPointers
	ld a, [de] ; get channel number
	ld b, a
	rlca
	rlca
	and $3
	ld c, a
	ld a, b
	and $f
	ld b, c
	inc b
	inc de
	ld c, $0
.asm_7db25
	cp c
	jr z, .asm_7db2d
	inc c
	inc hl
	inc hl
	jr .asm_7db25
.asm_7db2d
	push af
	push hl
	push bc
	ld b, $0
	ld c, a
	cp $3
	jr c, .asm_7db46
	ld hl, wChannelFlags1
	add hl, bc
	set 2, [hl]
.asm_7db46
	pop bc
	pop hl
	ld a, [de] ; get channel pointer
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	pop af
	push hl
	push bc
	ld b, $0
	ld c, a
	ld hl, wChannelSoundIDs
	add hl, bc
	ld a, [wSoundID]
	ld [hl], a
	pop bc
	pop hl
	inc c
	dec b
	ld a, b
	and a
	ld a, [de]
	inc de
	jr nz, .asm_7db25
	ld a, [wSoundID]
	cp $14
	jr nc, .asm_7db5f
	jr .asm_7db89
.asm_7db5f
	ld a, [wSoundID]
	cp $86
	jr z, .asm_7db89
	jr c, .asm_7db6a
	jr .asm_7db89
.asm_7db6a
	ld hl, wChannelSoundIDs + Ch4
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld hl, wChannelCommandPointers + Ch6 * 2 ; sfx noise channel pointer
	ld de, Noise3_endchannel
	ld [hl], e
	inc hl
	ld [hl], d ; overwrite pointer to point to endchannel
	ld a, [wSavedVolume]
	and a
	jr nz, .asm_7db89
	ld a, [rNR50]
	ld [wSavedVolume], a
	ld a, $77
	ld [rNR50], a
.asm_7db89
	ret

Noise3_endchannel:
	endchannel

