; The randomizer's #MON (RANDOM #MON options): starters, trainers, wild
; #MON, the one-off #MON, trades, TMs and learnsets. Nothing is stored:
; everything is drawn, when the game needs it, from the seed and what it is
; for (RandoKey), so the same seed always gives the same answer.

; ---- random numbers for one thing

; b = what for (RKEY_*), c, d, e = which one -> sRandoRng, from the seed (save
; RAM open)
RandoKey:
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, 1
	ld [MBC1SRamBank], a
	ld hl, wRandoSeed
	ld a, [hli]
	xor b
	ld [sRandoRng], a
	ld a, [hli]
	xor c
	ld [sRandoRng + 1], a
	ld a, [hli]
	xor d
	ld [sRandoRng + 2], a
	ld a, [hl]
	xor e
	ld [sRandoRng + 3], a
	ld hl, sRandoRng
	or [hl]
	inc hl
	or [hl]
	inc hl
	or [hl]
	jr nz, .stir
	ld [hl], $25                 ; never 0
.stir
	callba RandoRngStir
	ret

; a = n (1-255) -> a = the next random number below n (bc and hl lost)
RandoRandA:
	ld e, a
	ld d, 0
	callba RandoRandDE
	ld a, e
	ret

; a = i (below c), b = a key, c = n -> a = where i goes in a shuffle of n
; things, a different one for each seed and key. Cheap enough to run for
; every species when the #DEX looks up where one lives: four rounds of
; odd-multiply-and-add then xorshift, each a shuffle of 0-255, repeated
; until the result is below n.
RandoPermute:
	push de
	push hl
	ld d, a
.walk
	ld hl, wRandoSeed
	ld e, 4
.round
	ld a, [hli]
	or 1                         ; odd: a shuffle
	push hl
	ld h, a
	ld a, d
	call .multiply
	pop hl
	ld d, a
	ld a, e
	cp 1
	ld a, [hl]
	jr nz, .add
	ld a, [wRandoSeed]
.add
	xor b
	add d
	ld d, a
	srl a
	srl a
	srl a
	xor d
	ld d, a
	dec e
	jr nz, .round
	ld a, d
	cp c
	jr nc, .walk
	pop hl
	pop de
	ret
; a * h (mod 256) -> a
.multiply
	ld l, a
	xor a
	push bc
	ld b, 8
.bit
	add a
	sla h
	jr nc, .next
	add l
.next
	dec b
	jr nz, .bit
	pop bc
	ret

; ---- species

; a = species -> hl = its RandoMonInfo (type, type, base stat total / 4,
; flags)
RandoMonInfoOf:
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	add hl, hl
	ld de, RandoMonInfo
	add hl, de
	ret

; a = species -> nz if it may be picked (sRandoWant; save RAM open)
RandoWanted:
	ld c, a
	ld a, [sRandoWant + RANDO_WANT_NOT]
	cp c
	jr z, .no
	ld a, c
	call RandoMonInfoOf
	inc hl
	inc hl
	inc hl
	ld a, [sRandoWant + RANDO_WANT_MASK]
	and [hl]
	ld b, a
	ld a, [sRandoWant + RANDO_WANT_FLAGS]
	cp b
	jr nz, .no
	dec hl
	ld a, [sRandoWant + RANDO_WANT_LOW]
	dec a
	cp [hl]
	jr nc, .no                   ; below LOW
	ld a, [sRandoWant + RANDO_WANT_HIGH]
	cp [hl]
	jr c, .no                    ; above HIGH
	ld a, [sRandoWant + RANDO_WANT_TYPE]
	cp $ff
	jr z, .yes
	dec hl
	cp [hl]
	jr z, .yes
	dec hl
	cp [hl]
	jr nz, .no
.yes
	or 1
	ret
.no
	xor a
	ret

; -> a = how many species sRandoWant wants
RandoCountWanted:
	ld b, 0
	ld a, 1
.loop
	push af
	push bc
	call RandoWanted
	pop bc
	jr z, .next
	inc b
.next
	pop af
	inc a
	cp 191
	jr c, .loop
	ld a, b
	ret

; a = n -> a = the n-th species sRandoWant wants
RandoNthWanted:
	ld b, a
	ld a, 1
.loop
	push af
	push bc
	call RandoWanted
	pop bc
	jr z, .next
	ld a, b
	and a
	jr z, .found
	dec b
.next
	pop af
	inc a
	jr .loop
.found
	pop af
	ret

; a random species of those sRandoWant wants, from sRandoRng -> a (0: none)
RandoPickWanted:
	call RandoCountWanted
	and a
	ret z
	call RandoRandA
	jp RandoNthWanted

; sRandoWant: any real species but the legendaries, of any type and strength
RandoWantAny:
	ld hl, sRandoWant
	ld a, MONINFO_REAL | MONINFO_LEGENDARY
	ld [hli], a
	ld a, MONINFO_REAL
	ld [hli], a
	ld a, $ff
	ld [hli], a                  ; type
	ld a, 1
	ld [hli], a                  ; low
	ld a, $ff
	ld [hli], a                  ; high
	xor a
	ld [hl], a                   ; not
	ret

; a = species -> a random one of similar strength (and, if c isn't $ff, of
; type c) from sRandoRng: within an eighth of its base stat total, else a
; quarter, else any. Legendaries only for legendaries.
RandoSimilar:
	push af
	ld a, c
	push af
	call RandoWantAny
	pop af
	ld [sRandoWant + RANDO_WANT_TYPE], a
	pop af
	ld [sRandoWant + RANDO_WANT_NOT], a
	push af
	call RandoMonInfoOf
	ld a, [hli]
	ld a, [hli]
	ld c, [hl]                   ; its base stat total / 4
	inc hl
	ld a, [hl]
	and MONINFO_LEGENDARY
	jr z, .notLegendary
	ld a, MONINFO_REAL | MONINFO_LEGENDARY
	ld [sRandoWant + RANDO_WANT_FLAGS], a
.notLegendary
	pop af
	ld d, 3                      ; an eighth, a quarter, any
.window
	ld a, c
	REPT 3
	srl a
	ENDR
	ld e, a                      ; an eighth
	ld a, d
	cp 2
	jr nz, .width
	sla e                        ; a quarter
.width
	cp 1
	jr nz, .bounds
	ld a, 1
	ld [sRandoWant + RANDO_WANT_LOW], a
	ld a, $ff
	ld [sRandoWant + RANDO_WANT_HIGH], a
	jr .count
.bounds
	ld a, c
	sub e
	jr nc, .low
	ld a, 1
.low
	ld [sRandoWant + RANDO_WANT_LOW], a
	ld a, c
	add e
	jr nc, .high
	ld a, $ff
.high
	ld [sRandoWant + RANDO_WANT_HIGH], a
.count
	push bc
	push de
	call RandoCountWanted
	pop de
	pop bc
	cp 3
	jr nc, .pick
	and a
	jr z, .wider
	ld a, d
	cp 1
	jr z, .pick                  ; any: whatever there is
.wider
	dec d
	jr nz, .window
	ld a, [sRandoWant + RANDO_WANT_NOT]
	ret                          ; nothing: itself
.pick
	jp RandoPickWanted

; ---- starters

; the vanilla starters' lines, in RandoStarterSlots' order
RandoVanillaStarters:
	db BULBASAUR, IVYSAUR, VENUSAUR
	db CHARMANDER, CHARMELEON, CHARIZARD
	db SQUIRTLE, WARTORTLE, BLASTOISE

; a = species -> a = what replaces it with STARTERS on: the same stage of
; the line in its slot (any other species: itself)
RandoStarterMon::
	ld b, a
	ld a, [wRandoFlags2]
	and RANDO2_STARTERS
	ld a, b
	ret z
	ld hl, RandoVanillaStarters
	ld c, 0
.find
	ld a, [hli]
	cp b
	jr z, .found
	inc c
	ld a, c
	cp 9
	jr c, .find
	ld a, b
	ret
.found
	; c = slot * 3 + stage
	ld a, c
	ld b, 0
.slot
	cp 3
	jr c, .gotSlot
	sub 3
	inc b
	jr .slot
.gotSlot
	push af                      ; stage
	push bc                      ; b = slot
	call RandoStarterLines       ; sRandoWant = the three lines' numbers
	pop bc
	ld c, b
	ld b, 0
	ld hl, sRandoWant
	add hl, bc
	ld a, [hl]                   ; the line
	ld c, a
	add a
	add c                        ; * 3
	ld c, a
	pop af
	add c
	ld c, a
	ld hl, RandoLines + 1
	add hl, bc
	ld a, [hl]
	push af
	call RandoCloseSRAM
	pop af
	ret

; sRandoWant + 0-2 = the lines in the slots of BULBASAUR, CHARMANDER and
; SQUIRTLE: three different ones, or with TYPES ones whose basics beat each
; other as the originals do (SQUIRTLE's beats CHARMANDER's, which beats
; BULBASAUR's, which beats SQUIRTLE's)
RandoStarterLines:
	ld b, RKEY_STARTERS
	ld c, 0
	ld de, 0
	call RandoKey
	ld a, [wRandoFlags2]
	and RANDO2_STARTERS
	cp 2
	jr z, .types
	ld a, RANDO_LINES
	call RandoRandA
	ld [sRandoWant], a
.second
	ld a, RANDO_LINES
	call RandoRandA
	ld hl, sRandoWant
	cp [hl]
	jr z, .second
	ld [sRandoWant + 1], a
.third
	ld a, RANDO_LINES
	call RandoRandA
	ld hl, sRandoWant
	cp [hl]
	jr z, .third
	inc hl
	cp [hl]
	jr z, .third
	ld [sRandoWant + 2], a
	ret
.types
	ld a, [RandoTriangles]
	call RandoRandA
	ld c, a
	add a
	add c
	ld c, a
	ld b, 0
	ld hl, RandoTriangles + 1
	add hl, bc
	; (x, y, z): x beats y beats z beats x; SQUIRTLE's slot x, CHARMANDER's y,
	; BULBASAUR's z
	ld a, [hli]
	ld [sRandoWant + 2], a
	ld a, [hli]
	ld [sRandoWant + 1], a
	ld a, [hl]
	ld [sRandoWant], a
	ret

; OAK's lab: the starter in wcf91 (a vanilla one) becomes the randomizer's,
; or Shin's random wild #MON's
RandoStarterChoice::
	ld a, [wRandoFlags2]
	and RANDO2_STARTERS
	jr z, .shin
	ld a, [wcf91]
	call RandoStarterMon
	ld [wcf91], a
	ret
.shin
	predef ReplaceWildMon
	ret

; e = the vanilla species -> e = RandoStarterMon's (from other banks)
RandoStarterMonFar::
	ld a, e
	call RandoStarterMon
	ld e, a
	ret

; e = 1 if the starters aren't the originals (their texts can't name a
; type), else 0
RandoStartersChanged::
	ld e, 1
	ld a, [wRandoFlags2]
	and RANDO2_STARTERS
	ret nz
	CheckEvent EVENT_8DE
	ret nz
	dec e
	ret

; ---- trainers

; ReadTrainer, before each #MON is added (wcf91, wCurEnemyLVL; the party so
; far in wEnemyPartyCount). With TRAINERS ALL every trainer's #MON is
; another of similar strength, of the trainer's type theme if it had one
; (the gym leaders and the ELITE FOUR always do), drawn from the seed, the
; trainer and the place in the party; the rival keeps the starter line
; (STARTERS' if those are shuffled). Then levels scale down.
RandoTrainerMon::
	call RandoRivalClass
	jr nz, .notRival
	ld a, [wcf91]
	call RandoIsStarterLine
	jr nc, .notRival
	ld a, [wcf91]
	call RandoStarterMon
	ld [wcf91], a
	jr .scale
.notRival
	ld a, [wRandoFlags2]
	bit RANDO2_TRAINERS_F, a
	jr z, .scale
	ld a, [wTrainerClass]
	ld c, a
	ld a, [wTrainerNo]
	ld d, a
	ld a, [wEnemyPartyCount]
	ld e, a
	ld b, RKEY_TRAINER
	call RandoKey
	call RandoTrainerTheme
	ld c, a
	ld a, [wcf91]
	call RandoSimilar
	and a
	jr z, .close
	ld [wcf91], a
.close
	call RandoCloseSRAM
.scale
	jp RandoScaleDown

; z if wTrainerClass is the rival's
RandoRivalClass:
	ld a, [wTrainerClass]
	cp SONY1
	ret z
	cp SONY2
	ret z
	cp SONY3
	ret

; a = species -> carry if it is in a vanilla starter's line
RandoIsStarterLine:
	ld hl, RandoVanillaStarters
	ld c, 9
.loop
	cp [hl]
	scf
	ret z
	inc hl
	dec c
	jr nz, .loop
	and a
	ret

; -> a = wTrainerClass/wTrainerNo's type theme ($ff: none)
RandoTrainerTheme:
	ld a, [wTrainerClass]
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld de, RandoThemeIndex
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, RandoThemes - 1
	add hl, de
	ld a, [wTrainerNo]
	ld e, a
	ld d, 0
	add hl, de
	ld a, [hl]
	ret

; ReadTrainer, after TrainerHeldItems: with TRAINERS ALL, the bosses' #MON
; that hold nothing get a random battle item
RandoTrainerHeld::
	ld a, [wRandoFlags2]
	bit RANDO2_TRAINERS_F, a
	ret z
	ld a, [wTrainerClass]
	ld hl, RandoBossClasses
.boss
	ld b, [hl]
	inc hl
	inc b
	ret z
	dec b
	cp b
	jr nz, .boss
	ld a, [wEnemyPartyCount]
	and a
	ret z
	ld b, a
	ld e, 0
	ld hl, wEnemyMon1CatchRate
.mon
	ld a, [hl]
	and a
	jr nz, .next
	push bc
	push de
	push hl
	ld a, [wTrainerClass]
	ld c, a
	ld a, [wTrainerNo]
	ld d, a
	ld b, RKEY_HELD
	call RandoKey
	ld a, RandoBossItemsEnd - RandoBossItems
	call RandoRandA
	ld e, a
	ld d, 0
	ld hl, RandoBossItems
	add hl, de
	ld a, [hl]
	pop hl
	ld [hl], a
	pop de
	pop bc
.next
	push de
	ld de, wEnemyMon2 - wEnemyMon1
	add hl, de
	pop de
	inc e
	dec b
	jr nz, .mon
	jp RandoCloseSRAM

RandoBossClasses:
	db BROCK, MISTY, LT_SURGE, ERIKA, KOGA, SABRINA, BLAINE, GIOVANNI
	db LORELEI, BRUNO, AGATHA, LANCE, SONY2, SONY3, $ff

RandoBossItems:
	db GOLD_BERRY, SITRUS_BERRY, MIRACLEBERRY, LEFTOVERS, QUICK_CLAW, KINGS_ROCK
	db SCOPE_LENS, BRIGHTPOWDER, FOCUS_BAND, CHOICE_BAND, CHOICE_SPECS, CHOICE_SCARF
	db LIFE_ORB
RandoBossItemsEnd:
