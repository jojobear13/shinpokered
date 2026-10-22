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
; trainer and the place in the party, then evolved as far as its level
; allows; the rival keeps the starter line (STARTERS' if those are
; shuffled). Then levels scale down.
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
	; evolved as far as its level allows, as Shin's random trainers' are
	callba EnemyMonEvolve
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

; ---- in-game trades (TRADES): what is asked for and what is given become
; others of similar strength, per trade per seed
RandoTrade::
	ld a, [wRandoFlags2]
	bit RANDO2_TRADES_F, a
	ret z
	ld hl, wInGameTradeGiveMonSpecies
	ld e, 0
	call .mon
	ld hl, wInGameTradeReceiveMonSpecies
	ld e, 1
.mon
	push hl
	ld a, [wWhichTrade]
	ld c, a
	ld d, 0
	ld b, RKEY_TRADE
	call RandoKey
	pop hl
	push hl
	ld a, [hl]
	ld c, $ff
	call RandoSimilar
	pop hl
	ld [hl], a
	jp RandoCloseSRAM

; ---- moves: TM MOVES, TM COMPAT. and LEARNSETS

; a = move -> a = its RandoMoveInfo (bit 7: does damage; the type below)
RandoMoveInfoOf:
	dec a
	ld e, a
	ld d, 0
	ld hl, RandoMoveInfo
	add hl, de
	ld a, [hl]
	ret

; a = move -> carry if it is one the HMs teach (never a TM's, by TM MOVES)
RandoHMMove:
	ld hl, RandoVanillaTMs + NUM_TMS
	ld c, NUM_HMS
.loop
	cp [hl]
	scf
	ret z
	inc hl
	dec c
	jr nz, .loop
	and a
	ret

; a = a machine (0-, the TMs then the HMs) -> a = the move it teaches. With
; TM MOVES the TMs teach a shuffle of every move but the HMs': the p-th of
; those is p + 1, plus one for each HM move at or below it (the HMs' moves
; are in order).
RandoTMMove:
	cp NUM_TMS
	jr nc, .vanilla
	ld b, a
	ld a, [wRandoFlags3]
	bit RANDO3_TM_MOVES_F, a
	ld a, b
	jr z, .vanilla
	ld c, NUM_ATTACKS - NUM_HMS
	ld b, RKEY_TM
	call RandoPermute
	inc a
	ld hl, RandoVanillaTMs + NUM_TMS
	ld c, NUM_HMS
.skipHMs
	cp [hl]
	jr c, .done
	inc a
	inc hl
	dec c
	jr nz, .skipHMs
.done
	ret
.vanilla
	ld e, a
	ld d, 0
	ld hl, RandoVanillaTMs
	add hl, de
	ld a, [hl]
	ret

; a = move -> a = the machine that teaches it ($ff: none)
RandoMoveMachine:
	ld b, a
	ld a, [wRandoFlags3]
	bit RANDO3_TM_MOVES_F, a
	jr z, .vanilla
	ld a, b
	call RandoHMMove
	jr c, .vanilla               ; the HMs stay
	; its place among the moves that aren't the HMs'
	ld a, b
	dec a
	ld hl, RandoVanillaTMs + NUM_TMS
	ld c, NUM_HMS
.below
	ld d, a
	ld a, [hli]
	cp b
	ld a, d
	jr nc, .placed
	dec a
	dec c
	jr nz, .below
.placed
	ld d, a                      ; the place
	ld e, 0
.machine
	ld a, e
	push de
	ld c, NUM_ATTACKS - NUM_HMS
	ld b, RKEY_TM
	call RandoPermute
	pop de
	cp d
	ld a, e
	ret z
	inc e
	ld a, e
	cp NUM_TMS
	jr c, .machine
	ld a, $ff
	ret
.vanilla
	ld hl, RandoVanillaTMs
	ld e, 0
.find
	ld a, [hli]
	cp b
	ld a, e
	ret z
	inc e
	ld a, e
	cp NUM_TMS + NUM_HMS
	jr c, .find
	ld a, $ff
	ret

; e = a machine -> e = its move (from other banks)
RandoTMMoveFar::
	ld a, e
	call RandoTMMove
	ld e, a
	ret

; CanLearnTM: e = the move, wcf91 the #MON, wMonHLearnset its machine bits
; -> e = 1 if it can learn it, 0 if not; $ff if neither TM MOVES nor TM
; COMPAT. changes anything (the game's own check)
RandoCanLearnTM::
	ld a, [wRandoFlags3]
	and (1 << RANDO3_TM_MOVES_F) | RANDO3_TM_COMPAT
	jr nz, .changed
	ld e, $ff
	ret
.changed
	ld a, e
	push de
	call RandoMoveMachine
	pop de
	ld d, a                      ; the machine
	cp $ff
	jr nz, .gotMachine
	ld e, 0
	ret
.gotMachine
	ld a, [wRandoFlags3]
	and RANDO3_TM_COMPAT
	jr z, .ownBits
	cp 3 << RANDO3_TM_COMPAT_F
	jr z, .yes                   ; FULL: every #MON, every machine
	ld a, d
	cp NUM_TMS
	jr nc, .ownBits              ; the HMs as they were: the logic needs them
	; TYPE: its own types always, NORMAL moves half the time, others a
	; fifth; RANDOM: half the time. One answer per #MON per machine per seed.
	push de
	ld a, [wcf91]
	ld c, a
	ld b, RKEY_TM
	ld e, 0
	call RandoKey
	ld a, 100
	call RandoRandA
	push af
	call RandoCloseSRAM
	pop af
	pop de
	ld b, a                      ; 0-99
	ld a, [wRandoFlags3]
	and RANDO3_TM_COMPAT
	cp 2 << RANDO3_TM_COMPAT_F
	ld c, 50
	jr z, .chance
	push bc
	ld a, e
	call RandoMoveInfoOf
	pop bc
	and $7f
	ld c, a                      ; the move's type
	ld a, [wcf91]
	push bc
	call RandoMonInfoOf
	pop bc
	ld a, [hli]
	cp c
	jr z, .yes
	ld a, [hl]
	cp c
	jr z, .yes
	ld a, c
	and a                        ; NORMAL
	ld c, 50
	jr z, .chance
	ld c, 20
.chance
	ld a, b
	cp c
	jr c, .yes
	ld e, 0
	ret
.yes
	ld e, 1
	ret
.ownBits
	ld a, d
	ld e, a
	srl e
	srl e
	srl e
	ld d, 0
	ld hl, wMonHLearnset
	add hl, de
	and 7
	ld b, a
	ld a, [hl]
	inc b
.shift
	dec b
	jr z, .bit
	rrca
	jr .shift
.bit
	and 1
	ld e, a
	ret

; LEARNSETS: e = the #MON, d = a move it learns -> d = the one it learns
; instead: one that does damage for one that does, else one that doesn't;
; with TYPE, of one of its types half the time; with METRONOME, METRONOME.
; One answer per #MON per move per seed, drawn by trying random moves
; (cheap: each try is a byte). Save RAM is closed after.
RandoLearnMove:
	ld a, d
	and a
	ret z
	ld a, [wRandoFlags3]
	and RANDO3_LEARN
	ret z
	cp 3 << RANDO3_LEARN_F
	jr nz, .random
	ld d, METRONOME
	ret
.random
	push de
	ld c, e
	ld b, RKEY_LEARN
	call RandoKey                ; d, e: the move and the #MON
	pop de
	; sRandoWant, for moves: + 0 damage or not (bit 7), + 1 a type ($ff any),
	; + 2 the one replaced, + 3 the one being tried
	ld a, d
	ld [sRandoWant + 2], a
	push de
	call RandoMoveInfoOf
	pop de
	and $80
	ld [sRandoWant], a
	ld a, $ff
	ld [sRandoWant + 1], a
	ld a, [wRandoFlags3]
	and RANDO3_LEARN
	cp 1 << RANDO3_LEARN_F
	jr nz, .try
	call RandoRngByte
	rrca
	jr nc, .try                  ; half the time any type
	rrca
	push af
	ld a, e
	call RandoMonInfoOf          ; its first type, or its second
	pop af
	jr nc, .gotType
	inc hl
.gotType
	ld a, [hl]
	ld [sRandoWant + 1], a
.try
	ld b, 0                      ; tries: after 256 of one type, any type
.again
	push bc
	call RandoRngByte
	pop bc
	and a
	jr z, .miss
	cp NUM_ATTACKS + 1
	jr nc, .miss
	ld [sRandoWant + 3], a       ; the try
	push bc
	call .wanted
	pop bc
	jr nz, .found
.miss
	dec b
	jr nz, .again
	ld a, $ff
	ld [sRandoWant + 1], a
	jr .again
.found
	ld a, [sRandoWant + 3]
	ld d, a
	jp RandoCloseSRAM

; a = move -> nz if wanted (c = the move)
.wanted
	ld c, a
	ld a, [sRandoWant + 2]
	cp c
	jr z, .no
	ld a, c
	push bc
	call RandoHMMove
	pop bc
	jr c, .no
	ld a, c
	push bc
	call RandoMoveInfoOf
	pop bc
	ld b, a
	and $80
	ld hl, sRandoWant
	cp [hl]
	jr nz, .no
	inc hl
	ld a, [hl]
	cp $ff
	jr z, .yes
	ld a, b
	and $7f
	cp [hl]
	jr nz, .no
.yes
	or 1
	ret
.no
	xor a
	ret

; -> a = a random byte from sRandoRng (save RAM open; de kept)
RandoRngByte:
	push de
	callba RandoRngByteFar
	ld a, e
	pop de
	ret

; rando_learnset (macros): wRandoLearnset holds a pointer to a #MON's evolutions
; and learnset (EvosMovesPointerTable's bank), wRandoLearnsetSpecies the
; #MON: copy them there with LEARNSETS' moves
RandoBuildLearnset::
	ld hl, wRandoLearnset
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wRandoLearnset
	ld bc, RANDO_LEARNSET_SIZE
	ld a, BANK(EvosMovesPointerTable)
	call FarCopyData
	ld hl, wRandoLearnset
.evolutions
	ld a, [hli]
	and a
	jr z, .moves
	cp EV_ITEM
	jr nz, .threeBytes
	inc hl
.threeBytes
	inc hl
	inc hl
	jr .evolutions
.moves
	ld a, [hli]                  ; the level
	and a
	ret z
	push hl
	ld d, [hl]
	ld a, [wRandoLearnsetSpecies]
	ld e, a
	call RandoLearnMove
	pop hl
	ld [hl], d
	inc hl
	jr .moves

; GetMonHeader: the four moves it starts with (wMonHMoves), with LEARNSETS
; (METRONOME: just the one)
RandoHeaderMoves::
	ld a, [wRandoFlags3]
	and RANDO3_LEARN
	ret z
	ld hl, wMonHMoves
	ld b, NUM_MOVES
.loop
	push bc
	push hl
	ld d, [hl]
	ld a, [wd0b5]
	ld e, a
	call RandoLearnMove
	pop hl
	pop bc
	ld a, b
	cp NUM_MOVES
	jr z, .put
	ld a, d
	cp METRONOME
	jr nz, .put
	ld d, 0                      ; METRONOME once
.put
	ld [hl], d
	inc hl
	dec b
	jr nz, .loop
	ret
