; IVs are four bytes, read as one 32-bit number, high byte first: six 5-bit
; IVs (HP, attack, defense, speed, special attack, special defense, from the
; top), then Nuzlocke's dead mark (bit 1) and the ability slot (bit 0).

; hl = IVs, c = a stat (1-6) -> a = its IV (0-31). Keeps bc, de and hl.
GetIV::
	push hl
	push de
	push bc
	ld a, [hli]
	ld d, a
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld l, [hl]
	ld h, a ; dehl = the IVs
	ld a, c
	dec a
	ld b, a
	add a
	add a
	add b ; 5 bits per stat before this one
	and a
	jr z, .gotIV
.shift
	sla l
	rl h
	rl e
	rl d
	dec a
	jr nz, .shift
.gotIV
	ld a, d
	rrca
	rrca
	rrca
	and %11111
	pop bc
	pop de
	pop hl
	ret

; de = IVs -> wIVScratch = the six IVs, for far callers (callab keeps de)
UnpackIVsAtDE::
	ld h, d
	ld l, e
; hl = IVs -> wIVScratch = the six IVs. Keeps bc, de and hl.
UnpackIVs::
	push bc
	push de
	ld de, wIVScratch
	ld c, 1
.loop
	call GetIV
	ld [de], a
	inc de
	inc c
	ld a, c
	cp NUM_STATS + 1
	jr nz, .loop
	pop de
	pop bc
	ret

; wIVScratch -> the four IV bytes at hl, with the flags in a (bits 0 and 1).
; Keeps de and hl.
PackIVs::
	push de
	push af
	push hl
	xor a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	pop hl
	ld de, wIVScratch
	ld c, NUM_STATS
.ivLoop
	ld a, [de]
	inc de
	rlca
	rlca
	rlca ; the 5 bits at the top
	ld b, 5
.bitLoop
	sla a
	push af
	call .shiftIn
	pop af
	dec b
	jr nz, .bitLoop
	dec c
	jr nz, .ivLoop
	and a
	call .shiftIn
	and a
	call .shiftIn ; room for the flags
	pop af
	and %11
	inc hl
	inc hl
	inc hl
	or [hl]
	ld [hld], a
	dec hl
	dec hl
	pop de
	ret

; shift the 32 bits at hl left, carry into bit 0. Keeps hl
.shiftIn
	inc hl
	inc hl
	inc hl
	rl [hl]
	dec hl
	rl [hl]
	dec hl
	rl [hl]
	dec hl
	rl [hl]
	ret

; wIVScratch -> the four IV bytes at de, keeping their flags (for far callers)
PackIVsKeepFlags::
	ld h, d
	ld l, e
	inc hl
	inc hl
	inc hl
	ld a, [hl]
	and %11
	ld h, d
	ld l, e
	jr PackIVs

; Roll new IVs into the four bytes at de: a random ability slot, no Nuzlocke
; mark. Each takes its way of rolling (IVGEN_*_F in wIVGenMode); far callers
; use the entry points below, which set it.
WildIVs::
	ld a, 1 << IVGEN_HARD_F
	jr GenerateIVs
BiasedIVs::
	ld a, 1 << IVGEN_BIAS_F
	jr GenerateIVs
GiftIVs::
	ld a, 1 << IVGEN_MIN16_F
	jr GenerateIVs
MGeneIVs::
	ld a, 1 << IVGEN_BIAS_F | 1 << IVGEN_MIN16_F
	jr GenerateIVs
ShinyIVs::
	ld a, 1 << IVGEN_SHINY_F
GenerateIVs::
	ld [wIVGenMode], a
	bit IVGEN_BIAS_F, a
	call nz, .boss
	ld hl, wIVScratch
	ld c, NUM_STATS
.loop
	call .roll
	ld b, a
	ld a, [wIVGenMode]
	bit IVGEN_BIAS_F, a
	jr z, .notBiased
	call .roll ; the better of two
	cp b
	jr c, .notBiased
	ld b, a
.notBiased
	ld a, [wIVGenMode]
	bit IVGEN_HARD_F, a
	jr z, .notHard
	ld a, [wOptions]
	bit BIT_BATTLE_HARD, a
	jr z, .notHard
	ld a, b
	cp 8
	jr nc, .notHard
	call .roll ; hard mode rerolls a wild mon's IVs under 8, once
	ld b, a
.notHard
	ld a, [wIVGenMode]
	bit IVGEN_MIN16_F, a
	jr z, .notMin16
	set 4, b ; 16 or more
.notMin16
	bit IVGEN_SHINY_F, a
	jr z, .notShiny
	ld a, b
	and %11100
	or SHINY_IV_BITS
	ld b, a
.notShiny
	ld a, b
	ld [hli], a
	dec c
	jr nz, .loop
	call Random ; the ability slot
	and 1
	ld h, d
	ld l, e
	jp PackIVs

.roll
	call Random
	and %11111
	ret

; bosses' mons (gym leaders, the Elite Four, Giovanni, the rival's final
; teams) have IVs of 16 or more
.boss
	ld a, [wChannelSoundIDs]
	cp MUSIC_GYM_LEADER_BATTLE
	jr z, .isBoss
	cp MUSIC_FINAL_BATTLE
	jr z, .isBoss
	ld a, [wCurOpponent]
	cp SONY2
	jr z, .isBoss
	cp GIOVANNI
	jr z, .isBoss
	cp LORELEI
	jr z, .isBoss
	cp BRUNO
	jr z, .isBoss
	cp AGATHA
	ret nz
.isBoss
	ld hl, wIVGenMode
	set IVGEN_MIN16_F, [hl]
	ret

; hl = IVs -> a = the byte a mon's gender is read from (the first and third
; IV bytes xored). Keeps bc, de and hl.
GetGenderByte::
	push hl
	ld a, [hli]
	inc hl
	xor [hl]
	pop hl
	ret

; Add up to [wItemScratch + 1] EVs to stat [wItemScratch] (0 = HP ... 5 =
; special defense) of the six EVs at de, within MAX_EV for the stat and
; MAX_TOTAL_EVS in all. Carry if none could be added.
AddEVs::
	ld h, d
	ld l, e
	ld b, NUM_STATS
	ld de, 0
.sum
	ld a, [hli]
	add e
	ld e, a
	jr nc, .noCarry
	inc d
.noCarry
	dec b
	jr nz, .sum
	ld a, LOW(MAX_TOTAL_EVS)
	sub e
	ld e, a
	ld a, HIGH(MAX_TOTAL_EVS)
	sbc d
	ld d, a ; de = the room left in all
	jr c, .none
	ld bc, -NUM_STATS
	add hl, bc
	ld a, [wItemScratch]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, MAX_EV
	sub [hl] ; the room left in the stat
	jr z, .none
	jr c, .none
	ld c, a
	ld a, [wItemScratch + 1]
	cp c
	jr nc, .gotAmount
	ld c, a ; the smaller
.gotAmount
	ld a, d
	and a
	jr nz, .add
	ld a, e
	and a
	jr z, .none
	cp c
	jr nc, .add
	ld c, a
.add
	ld a, c
	and a
	jr z, .none
	add [hl]
	ld [hl], a
	and a
	ret
.none
	scf
	ret
