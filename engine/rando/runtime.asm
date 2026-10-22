; The randomizer in the running game: the seed asked for at NEW GAME, the
; world built from it (engine/rando/generator.asm) and looked up as the
; player goes: the doors, the items, the marts.

; NEW GAME: if anything is randomized, ask for a seed. Players who type the
; same seed with the same choices get the same game; none typed, a random one.
RandoNewGame::
	ld a, [wRandoFlags]
	res RANDO_SEEDED_F, a
	ld [wRandoFlags], a
	call RandoSettings
	and a
	ret z
	callba DisplaySeedNamingScreen
	ld a, [wBuffer]
	cp "@"
	jr z, .random
	; the seed: what was typed, then the settings, hashed
	callba RandoHashStart
	ld hl, wBuffer
.char
	ld a, [hli]
	cp "@"
	jr z, .typed
	ld e, a
	push hl
	callba RandoHashByte
	pop hl
	jr .char
.typed
	call RandoSettings
	ld e, a
	callba RandoHashByte
	callba RandoHashResult       ; into wRandoSeed
	ld hl, wRandoFlags
	set RANDO_SEEDED_F, [hl]
	; Shin's wild randomizer follows its own one-byte seed (never 0)
	ld a, [wRandoSeed]
	and a
	jr nz, .wildSeed
	inc a
.wildSeed
	ld [wRandomizerSeed], a
	jr .world
.random
	ld hl, wRandoSeed
	ld c, 4
.randomByte
	call Random
	ld [hli], a
	dec c
	jr nz, .randomByte
.world
	ld a, [wRandoFlags]
	and RANDO_WORLD
	ret z
	jp RandoBuildWorld

; a = what is randomized: wRandoFlags' choices, then RANDOM WILD (two bits)
; and RANDOM TRNR; 0 if nothing
RandoSettings:
	ld a, [wRandoFlags]
	and $0f
	ld b, a
	CheckEvent EVENT_8DE
	jr z, .noWild
	set 4, b
.noWild
	CheckEvent EVENT_8D7
	jr z, .noFull
	set 5, b
.noFull
	CheckEvent EVENT_8D8
	jr z, .noTrainers
	set 6, b
.noTrainers
	ld a, b
	ret

; CONTINUE: build the world again if save RAM holds another one (or none)
RandoCheckWorld::
	ld a, [wRandoFlags]
	and RANDO_WORLD
	ret z
	callba RandoSRAM
	ld a, [sRandoValid]
	cp RANDO_DATA_VERSION
	jr nz, .build
	ld hl, wRandoSeed
	ld de, sRandoTag
	ld c, 4
.compare
	ld a, [de]
	cp [hl]
	jr nz, .build
	inc de
	inc hl
	dec c
	jr nz, .compare
	ld a, [wRandoFlags]
	and RANDO_WORLD
	ld b, a
	ld a, [de]
	cp b
	jr nz, .build
	jp RandoCloseSRAM
.build
	call RandoBuildWorld
	jp GBPalWhiteOutWithDelay3

; build the world for wRandoSeed and wRandoFlags into save RAM, saying so:
; it takes a while (twice as fast on a Game Boy Color)
RandoBuildWorld:
	call ClearScreen
	call GBPalNormal
	coord hl, 0, 12
	lb bc, 4, 18
	call TextBoxBorder
	coord hl, 1, 14
	ld de, RandoBuildingText
	call PlaceString
	callba RandoSRAM
	ld hl, wRandoSeed
	ld de, sRandoTag
	ld bc, 4
	call CopyData
	ld a, [wRandoFlags]
	and RANDO_WORLD
	ld [sRandoTag + 4], a
	ld a, [hGBC]
	and a
	jr z, .build
	ld a, [rKEY1]
	bit 7, a
	jr nz, .build                ; already fast
	callba ToggleCPUSpeed
	callba RandoGenerate
	callba ToggleCPUSpeed
	jr .built
.build
	callba RandoGenerate
.built
	call RandoCloseSRAM
	jp ClearScreen

RandoCloseSRAM:
	xor a
	ld [MBC1SRamBank], a
	ld [MBC1SRamEnable], a ; SRAM_DISABLE
	ret

RandoBuildingText:
	db   "Building the world"
	next "for this seed...@"
