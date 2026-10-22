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

; ---- wild #MON

; Shin's RANDOM WILD (TIER, FULL): d = the #MON's place in its list, e = the
; list's length -> e = the place of the one it becomes, from the whole seed
; (Shin's own shuffle has a one-byte seed); $ff for Shin's (no seed: RANDOM
; WILD turned on in an older game)
RandoWildPermute::
	ld hl, wRandoSeed
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	inc hl
	or [hl]
	jr nz, .seeded
	ld e, $ff
	ret
.seeded
	ld a, d
	ld c, e
	ld b, e                      ; each list its own shuffle
	call RandoPermute
	ld e, a
	ret

; sRandoWant: the basic #MON but the legendaries; with c = 1 only the water
; ones (save RAM open; c kept)
RandoWantBasics:
	push bc
	call RandoWantAny
	pop bc
	ld a, MONINFO_REAL | MONINFO_LEGENDARY | MONINFO_BASIC
	ld [sRandoWant + RANDO_WANT_MASK], a
	ld a, MONINFO_REAL | MONINFO_BASIC
	ld [sRandoWant + RANDO_WANT_FLAGS], a
	bit 0, c
	ret z
	ld a, MONINFO_REAL | MONINFO_LEGENDARY | MONINFO_BASIC | MONINFO_WATER
	ld [sRandoWant + RANDO_WANT_MASK], a
	ld a, MONINFO_REAL | MONINFO_BASIC | MONINFO_WATER
	ld [sRandoWant + RANDO_WANT_FLAGS], a
	ret

; c = 0 land, 1 water -> d = the size of that deck (save RAM open; c kept)
RandoDeckSize:
	call RandoWantBasics
	push bc
	call RandoCountWanted
	pop bc
	ld d, a
	ret

; WILD AREA: hl = an encounter's number among the land (c = 0) or water
; (c = 1) ones, d = the deck's size -> a = its place in the deck. Each run
; of the deck's size numbers is a shuffle of the whole deck, so every basic
; #MON is somewhere. (bc, de, hl kept.)
RandoAreaPlace:
	push bc
	push de
	push hl
	ld b, RKEY_WILD
	ld e, d
	ld d, 0
.cycle
	ld a, l
	sub e
	ld l, a
	ld a, h
	sbc d
	jr c, .got
	ld h, a
	inc b
	inc b
	jr .cycle
.got
	ld a, l
	add e                        ; the place in this run
	push af
	ld a, b
	add c                        ; land and water differ
	ld b, a
	pop af
	ld c, e
	call RandoPermute
	pop hl
	pop de
	pop bc
	ret

; a = a map, c = 0 land, 1 water -> a = its encounter group (0: none); bc,
; de kept
RandoWildGroup:
	push de
	ld l, a
	ld h, 0
	add hl, hl
	ld e, c
	ld d, 0
	add hl, de
	ld de, RandoWildGroups
	add hl, de
	ld a, [hl]
	pop de
	ret

; a = the group (1-), e = the slot -> hl = the encounter's number
RandoAreaNumber:
	dec a
	ld l, a
	ld h, 0
	ld a, e
	ld d, h
	ld e, l
	add hl, hl
	add hl, hl
	add hl, de
	add hl, hl                   ; * 10
	ld e, a
	ld d, 0
	add hl, de
	ret

; wild_encounters: e = the slot * 2 (wcf91, wCurEnemyLVL). With WILD AREA,
; the #MON there is the deck's, then evolved as far as its level allows.
RandoWildArea::
	ld a, [wRandoFlags2]
	bit RANDO2_WILD_AREA_F, a
	ret z
	srl e
	ld c, 0
	aCoord ENCOUNTER_TILE_COORD_X, ENCOUNTER_TILE_COORD_Y
	cp $14                       ; a water tile (as wild_encounters)
	jr nz, .gotKind
	inc c
.gotKind
	ld a, [wCurMap]
	call RandoWildGroup
	and a
	ret z
	call RandoAreaNumber
	call RandoAreaMon
	jp RandoAreaEvolve

; hl = the encounter's number, c = 0 land, 1 water -> wcf91 = the deck's
RandoAreaMon:
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, 1
	ld [MBC1SRamBank], a
	push hl
	call RandoDeckSize
	pop hl
	call RandoAreaPlace
	call RandoNthWanted          ; (sRandoWant still the deck)
	ld [wcf91], a
	jp RandoCloseSRAM

; wcf91 evolved as Shin's trainers' are for wCurEnemyLVL; into
; wEnemyMonSpecies2 too
RandoAreaEvolve:
	callba EnemyMonEvolve
	ld a, [wcf91]
	ld [wEnemyMonSpecies2], a
	ret

; fishing (wcf91, wCurEnemyLVL): with WILD AREA, from the water deck, by the
; map and what the rod would have caught
RandoFishArea::
	ld a, [wRandoFlags2]
	bit RANDO2_WILD_AREA_F, a
	ret z
	ld a, [wCurMap]
	ld l, a
	ld h, 0
	ld a, [wcf91]
	ld e, a
	ld d, h
	add hl, de
	ld c, 1
	call RandoAreaMon
	jp RandoAreaEvolve

; FindWildLocationsOfMon, with WILD AREA: wBuffer = the maps where wd11e's
; line can be met, $ff after; the flags for wCurMap as CheckMapForMon sets
; them (bit 1 land, bit 3 water). e = 1 if done (WILD AREA on), else 0.
; Scratch in save RAM: sRandoArea = the map, + 1 the line's basic, + 2-5
; its place in each deck ($ff: not in it) and the deck's size.
RandoAreaLocations::
	ld e, 0
	ld a, [wRandoFlags2]
	bit RANDO2_WILD_AREA_F, a
	ret z
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, 1
	ld [MBC1SRamBank], a
	ld a, [wd11e]
.basic
	ld [sRandoArea + 1], a
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld de, RandoDevolve
	add hl, de
	ld a, [hl]
	and a
	jr nz, .basic
	ld c, 0
	call .rank
	ld c, 1
	call .rank
	ld de, wBuffer
	xor a
.map
	ld [sRandoArea], a
	ld c, 0
	call .kind
	ld c, 1
	call .kind
	ld a, [sRandoArea]
	inc a
	cp RANDO_WILD_MAPS
	jr c, .map
	ld a, $ff
	ld [de], a
	call RandoCloseSRAM
	ld e, 1
	ret

; c = the deck -> its size and the basic's place in it, at sRandoArea + 2 + c * 2
.rank
	call RandoDeckSize
	push de
	ld a, [sRandoArea + 1]
	push bc
	call RandoWantedRank
	pop bc
	pop de
	ld b, a
	ld a, c
	add a
	ld l, a
	ld h, 0
	push de
	ld de, sRandoArea + 2
	add hl, de
	pop de
	ld a, b
	ld [hli], a
	ld [hl], d
	ret

; c = 0 land, 1 water: is the basic in this map's group? (de: where wBuffer
; is up to)
.kind
	ld a, [sRandoArea]
	call RandoWildGroup
	and a
	ret z
	push de
	ld e, 0
	call RandoAreaNumber         ; hl = the group's first number
	push hl
	ld a, c
	add a
	ld l, a
	ld h, 0
	ld de, sRandoArea + 2
	add hl, de
	ld d, h
	ld e, l
	pop hl
	ld a, [de]
	ld b, a                      ; the place
	inc de
	ld a, [de]
	ld d, a                      ; the deck's size
	ld a, b
	cp $ff
	jr z, .none
	ld e, 10
.slot
	call RandoAreaPlace
	cp b
	jr z, .found
	inc hl
	dec e
	jr nz, .slot
.none
	pop de
	ret
.found
	pop de
	ld a, [sRandoArea]
	ld [de], a
	inc de
	ld b, a
	ld a, [wCurMap]
	cp b
	ret nz
	ld a, [wActionResultOrTookBattleTurn]
	set 1, a
	bit 0, c
	jr z, .flag
	res 1, a
	set 3, a
.flag
	ld [wActionResultOrTookBattleTurn], a
	ret

; a = species -> a = its place among those sRandoWant wants ($ff: not one)
RandoWantedRank:
	push af
	call RandoWanted
	pop bc
	jr z, .no
	ld c, 0
	ld a, 1
.loop
	cp b
	jr z, .done
	push af
	push bc
	call RandoWanted
	pop bc
	jr z, .next
	inc c
.next
	pop af
	inc a
	jr .loop
.done
	ld a, c
	ret
.no
	ld a, $ff
	ret

; GetEnemyHeldItem: e = the wild #MON -> e = a random number for which of
; WildHeldItems' pairs it holds from (ITEMS: one pair per species per
; seed), or $ff for its own
RandoWildHeldPick::
	ld a, [wRandoFlags]
	bit RANDO_ITEMS_F, a
	jr nz, .items
	ld e, $ff
	ret
.items
	ld c, e
	ld b, RKEY_HELD
	ld de, $100
	call RandoKey
	ld a, $ff
	call RandoRandA
	push af
	call RandoCloseSRAM
	pop af
	ld e, a
	ret

; ---- the one-off #MON (SPECIAL MON): gifts, legendaries, SNORLAX, the
; POWER PLANT's, the fossils, the prizes and the old man's WEEDLE

; e = the vanilla #MON -> e = the one there with SPECIAL MON: of similar
; strength (legendaries for legendaries), one per #MON per map per seed
RandoSpecialMon::
	ld a, [wRandoFlags2]
	bit RANDO2_SPECIAL_F, a
	ret z
	push de
	ld c, e
	ld a, [wCurMap]
	ld d, a
	ld e, 0
	ld b, RKEY_SPECIAL
	call RandoKey
	pop de
	ld a, e
	ld c, $ff                    ; any type
	call RandoSimilar
	push af
	call RandoCloseSRAM
	pop af
	ld e, a
	ret

; InitBattleEnemyParameters, a #MON standing on the map (wCurOpponent)
RandoSpecialBattle::
	ld a, [wCurOpponent]
	ld e, a
	call RandoSpecialMon
	ld a, e
	ld [wCurOpponent], a
	ld [wEnemyMonOrTrainerClass], a
	ret

; the GAME CORNER's #MON prizes (wPrize1-3)
RandoPrizes::
	ld hl, wPrize1
	ld b, 3
.loop
	push bc
	push hl
	ld e, [hl]
	call RandoSpecialMon
	pop hl
	ld [hl], e
	inc hl
	pop bc
	dec b
	jr nz, .loop
	ret
