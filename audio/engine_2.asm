Audio2_PlaySound::
	ld [wSoundID], a
	cp $ff
	jp z, Audio2_221f3
	cp MUSIC2_FIRST_ENTRY - 1
	jp z, Audio2_2210d
	jp c, Audio2_2210d
	cp $fe
	jr z, .asm_2204c
	jp nc, Audio2_2210d
.asm_2204c
	call InitMusicVariables
	jp Audio2_2224e

Audio2_2210d:
	ld l, a
	ld e, a
	ld h, $0
	ld d, h
	add hl, hl
	add hl, de
	ld de, SFX_Headers_2
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
.asm_22126
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
	jr z, .asm_22162
	ld a, e
	cp $7
	jr nz, .asm_22159
	ld a, [wSoundID]
	cp $14
	jr nc, .asm_22152
	ret
.asm_22152
	ld a, [hl]
	cp $14
	jr z, .asm_22162
	jr c, .asm_22162
.asm_22159
	ld a, [wSoundID]
	cp [hl]
	jr z, .asm_22162
	jr c, .asm_22162
	ret
.asm_22162
	call InitSFXVariables
.asm_221ea
	ld a, c
	and a
	jp z, Audio2_2224e
	dec c
	jp .asm_22126

Audio2_221f3:
	call StopAllAudio
	ret
	
Audio2_2224e:
	ld a, [wSoundID]
	ld l, a
	ld e, a
	ld h, $0
	ld d, h
	add hl, hl
	add hl, de
	ld de, SFX_Headers_2
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
.asm_22270
	cp c
	jr z, .asm_22278
	inc c
	inc hl
	inc hl
	jr .asm_22270
.asm_22278
	push af
	push hl
	push bc
	ld b, $0
	ld c, a
	cp $3
	jr c, .asm_22291
	ld hl, wChannelFlags1
	add hl, bc
	set 2, [hl]
.asm_22291
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
	jr nz, .asm_22270
	ld a, [wSoundID]
	cp $14
	jr nc, .asm_222aa
	jr .asm_222d4
.asm_222aa
	ld a, [wSoundID]
	cp $86
	jr z, .asm_222d4
	jr c, .asm_222b5
	jr .asm_222d4
.asm_222b5
	ld hl, wChannelSoundIDs + Ch4
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld hl, wChannelCommandPointers + Ch6 * 2 ; sfx noise channel pointer
	ld de, Noise2_endchannel
	ld [hl], e
	inc hl
	ld [hl], d ; overwrite pointer to point to endchannel
	ld a, [wSavedVolume]
	and a
	jr nz, .asm_222d4
	ld a, [rNR50]
	ld [wSavedVolume], a
	ld a, $77
	ld [rNR50], a
.asm_222d4
	ret

Noise2_endchannel:
	endchannel

Music_GetKeyItemInBattle::	;joenote - if SFX_GET_KEY_ITEM plays in battle, play a previously unused SFX
	; begin playing the "caught mon" sound effect
	ld a, SFX_CAUGHT_MON
	call PlaySoundWaitForCurrent
	; then immediately overwrite the channel pointers
	ld hl, wChannelCommandPointers + Ch4 * 2
	ld de, SFX_08_unused2_Ch4
	call Audio2_OverwriteChannelPointer
	ld de, SFX_08_unused2_Ch5
	call Audio2_OverwriteChannelPointer
	ld de, SFX_08_unused2_Ch6
	jp Audio2_OverwriteChannelPointer
	
Music_PokeFluteInBattle::
	; begin playing the "caught mon" sound effect
	ld a, SFX_CAUGHT_MON
	call PlaySoundWaitForCurrent
	; then immediately overwrite the channel pointers
	ld hl, wChannelCommandPointers + Ch4 * 2
	ld de, SFX_08_PokeFlute_Ch4
	call Audio2_OverwriteChannelPointer
	ld de, SFX_08_PokeFlute_Ch5
	call Audio2_OverwriteChannelPointer
	ld de, SFX_08_PokeFlute_Ch6

Audio2_OverwriteChannelPointer:
	ld a, e
	ld [hli], a
	ld a, d
	ld [hli], a
	ret

Audio2_InitMusicVariables::
	xor a
	;ld [wUnusedC000], a
	ld [wDisableChannelOutputWhenSfxEnds], a
	ld [wMusicTempo + 1], a
	ld [wMusicWaveInstrument], a
	ld [wSfxWaveInstrument], a
	ld d, $8
	ld hl, wChannelReturnAddresses
	call FillAudioRAM2
	ld hl, wChannelCommandPointers
	call FillAudioRAM2
	ld d, $4
	ld hl, wChannelSoundIDs
	call FillAudioRAM2
	ld hl, wChannelFlags1
	call FillAudioRAM2
	ld hl, wChannelDuties
	call FillAudioRAM2
	ld hl, wChannelDutyCycles
	call FillAudioRAM2
	ld hl, wChannelVibratoDelayCounters
	call FillAudioRAM2
	ld hl, wChannelVibratoExtents
	call FillAudioRAM2
	ld hl, wChannelVibratoRates
	call FillAudioRAM2
	ld hl, wChannelFrequencyLowBytes
	call FillAudioRAM2
	ld hl, wChannelVibratoDelayCounterReloadValues
	call FillAudioRAM2
	ld hl, wChannelFlags2
	call FillAudioRAM2
	ld hl, wChannelPitchBendLengthModifiers
	call FillAudioRAM2
	ld hl, wChannelPitchBendFrequencySteps
	call FillAudioRAM2
	ld hl, wChannelPitchBendFrequencyStepsFractionalPart
	call FillAudioRAM2
	ld hl, wChannelPitchBendCurrentFrequencyFractionalPart
	call FillAudioRAM2
	ld hl, wChannelPitchBendCurrentFrequencyHighBytes
	call FillAudioRAM2
	ld hl, wChannelPitchBendCurrentFrequencyLowBytes
	call FillAudioRAM2
	ld hl, wChannelPitchBendTargetFrequencyHighBytes
	call FillAudioRAM2
	ld hl, wChannelPitchBendTargetFrequencyLowBytes
	call FillAudioRAM2
	ld a, $1
	ld hl, wChannelLoopCounters
	call FillAudioRAM2
	ld hl, wChannelNoteDelayCounters
	call FillAudioRAM2
	ld hl, wChannelNoteSpeeds
	call FillAudioRAM2
	ld [wMusicTempo], a
	ld a, $ff
	ld [wStereoPanning], a
	xor a
	ld [rNR50], a
	ld a, $8
	ld [rNR10], a
	ld a, $0
	ld [rNR51], a
	xor a
	ld [rNR30], a
	ld a, $80
	ld [rNR30], a
	ld a, $77
	ld [rNR50], a
	ret

Audio2_InitSFXVariables::
	xor a
	push de
	ld h, d
	ld l, e
	add hl, hl
	ld d, h
	ld e, l
	ld hl, wChannelReturnAddresses
	add hl, de
	ld [hli], a
	ld [hl], a
	ld hl, wChannelCommandPointers
	add hl, de
	ld [hli], a
	ld [hl], a
	pop de
	ld hl, wChannelSoundIDs
	add hl, de
	ld [hl], a
	ld hl, wChannelFlags1
	add hl, de
	ld [hl], a
	ld hl, wChannelDuties
	add hl, de
	ld [hl], a
	ld hl, wChannelDutyCycles
	add hl, de
	ld [hl], a
	ld hl, wChannelVibratoDelayCounters
	add hl, de
	ld [hl], a
	ld hl, wChannelVibratoExtents
	add hl, de
	ld [hl], a
	ld hl, wChannelVibratoRates
	add hl, de
	ld [hl], a
	ld hl, wChannelFrequencyLowBytes
	add hl, de
	ld [hl], a
	ld hl, wChannelVibratoDelayCounterReloadValues
	add hl, de
	ld [hl], a
	ld hl, wChannelPitchBendLengthModifiers
	add hl, de
	ld [hl], a
	ld hl, wChannelPitchBendFrequencySteps
	add hl, de
	ld [hl], a
	ld hl, wChannelPitchBendFrequencyStepsFractionalPart
	add hl, de
	ld [hl], a
	ld hl, wChannelPitchBendCurrentFrequencyFractionalPart
	add hl, de
	ld [hl], a
	ld hl, wChannelPitchBendCurrentFrequencyHighBytes
	add hl, de
	ld [hl], a
	ld hl, wChannelPitchBendCurrentFrequencyLowBytes
	add hl, de
	ld [hl], a
	ld hl, wChannelPitchBendTargetFrequencyHighBytes
	add hl, de
	ld [hl], a
	ld hl, wChannelPitchBendTargetFrequencyLowBytes
	add hl, de
	ld [hl], a
	ld hl, wChannelFlags2
	add hl, de
	ld [hl], a
	ld a, $1
	ld hl, wChannelLoopCounters
	add hl, de
	ld [hl], a
	ld hl, wChannelNoteDelayCounters
	add hl, de
	ld [hl], a
	ld hl, wChannelNoteSpeeds
	add hl, de
	ld [hl], a
	ld a, e
	cp $4
	ret nz
	ld a, $8
	ld [rNR10], a
	ret

Audio2_StopAllAudio::
	ld a, $80
	ld [rNR52], a
	ld [rNR30], a
	xor a
	ld [rNR51], a
	ld [rNR32], a
	ld a, $8
	ld [rNR10], a
	ld [rNR12], a
	ld [rNR22], a
	ld [rNR42], a
	ld a, $40
	ld [rNR14], a
	ld [rNR24], a
	ld [rNR44], a
	ld a, $77
	ld [rNR50], a
	xor a
	;ld [wUnusedC000], a
	ld [wDisableChannelOutputWhenSfxEnds], a
	ld [wMuteAudioAndPauseMusic], a
	ld [wMusicTempo + 1], a
	ld [wSfxTempo + 1], a
	ld [wMusicWaveInstrument], a
	ld [wSfxWaveInstrument], a
	ld d, $b0 ;$a0
	ld hl, wChannelCommandPointers
	call FillAudioRAM2
	ld a, $1
	ld d, $18
	ld hl, wChannelNoteDelayCounters
	call FillAudioRAM2
	ld [wMusicTempo], a
	ld [wSfxTempo], a
	ld a, $ff
	ld [wStereoPanning], a
	ret

; fills d bytes at hl with a
FillAudioRAM2:
	ld b, d
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ret
