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
	ld b, a
	ld a, [wRandoFlags2]
	or b
	ld b, a
	ld a, [wRandoFlags3]
	or b
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
	ld a, [wRandoFlags2]
	ld e, a
	callba RandoHashByte
	ld a, [wRandoFlags3]
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
; and RANDOM TRNR; 0 if nothing (wRandoFlags2 and 3 hold the rest)
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

; ---- the world, as the player goes

; save RAM bank 1, if the world is built and something in it is shuffled: nc;
; else carry (and save RAM closed)
RandoOpenWorld:
	ld a, [wRandoFlags]
	and RANDO_WORLD
	scf
	ret z
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, 1
	ld [MBC1SRamBank], a
	ld a, [sRandoValid]
	cp RANDO_DATA_VERSION
	ret z
	call RandoCloseSRAM
	scf
	ret

; WarpFound2: through a shuffled door, to where its partner leads
RandoWarp::
	ld a, [wRandoFlags]
	bit RANDO_DOORS_F, a
	ret z
	ld a, [wWarpedFromWhichMap]
	ld l, a
	ld h, 0
	add hl, hl
	ld de, RandoMapWarps
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	ret z                        ; no shuffled doors on this map
	ld a, [wWarpedFromWhichWarp]
	ld e, a
	ld d, 0
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld d, [hl]
	and d
	inc a
	ret z                        ; this warp stays
	call RandoOpenWorld
	ret c
	ld hl, sRandoPartner
	add hl, de
	add hl, de
	ld a, [hli]
	ld d, [hl]
	ld e, a
	call RandoCloseSRAM
	ld hl, RandoSlotWarp
	add hl, de
	add hl, de
	ld a, [hli]
	ld [hWarpDestinationMap], a
	ld a, [hl]
	ld [wDestinationWarpID], a
	ret

; e = location, d = its vanilla item -> e = the item there
RandoGiftItem::
	call RandoOpenWorld
	jr c, .vanilla
	ld hl, sRandoPlace
	ld d, 0
	add hl, de
	ld e, [hl]
	jp RandoCloseSRAM
.vanilla
	ld e, d
	ret

; PickUpItem: e = the ball's vanilla item (hSpriteIndexOrTextID on wCurMap)
; -> e = the item there
RandoBallItem::
	ld d, e
	ld hl, RandoBallLocs
	ld a, [hSpriteIndexOrTextID]
	ld c, a
	ld a, [wCurMap]
	ld b, a
.find
	ld a, [hli]
	cp $ff
	jr z, .vanilla
	cp b
	jr nz, .skip
	ld a, [hl]
	cp c
	jr z, .found
.skip
	inc hl
	inc hl
	jr .find
.found
	inc hl
	ld e, [hl]
	jr RandoGiftItem
.vanilla
	ld e, d
	ret

; HiddenItems: wHiddenObjectFunctionArgument becomes the item there
RandoHiddenItem::
	ld a, [wHiddenItemOrCoinsIndex]
	ld e, a
	ld d, 0
	ld hl, RandoHiddenLocs
	add hl, de
	ld a, [hl]
	cp $ff
	ret z
	ld e, a
	ld a, [wHiddenObjectFunctionArgument]
	ld d, a
	call RandoGiftItem
	ld a, e
	ld [wHiddenObjectFunctionArgument], a
	ret

; LoadMartInventory: with MARTS, mart [wItemScratch]'s wItemList is made
; from the seed (randomizer.mart): what every mart sells, then picks from
; the pool, as many as it sold before. Nothing is stored.
RandoMart::
	ld a, [wRandoFlags]
	bit RANDO_MARTS_F, a
	ret z
	ld a, [wItemScratch]
	ld e, a
	ld d, 0
	ld hl, RandoMartSizes
	add hl, de
	ld a, [hl]
	and a
	ret z                        ; this one keeps its list
	push af
	; its random numbers: the seed xor its key (never 0)
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, 1
	ld [MBC1SRamBank], a
	ld hl, RandoMartKeys
	add hl, de
	add hl, de
	add hl, de
	add hl, de
	ld de, wRandoSeed
	ld bc, sRandoRng
	ld a, 4
.key
	push af
	ld a, [de]
	xor [hl]
	ld [bc], a
	inc hl
	inc de
	inc bc
	pop af
	dec a
	jr nz, .key
	ld hl, sRandoRng
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	inc hl
	or [hl]
	jr nz, .seeded
	ld hl, sRandoRng
	ld a, $91
	ld [hli], a
	ld a, $f4
	ld [hli], a
	ld a, $45
	ld [hli], a
	ld [hl], $25
.seeded
	; the pool, in save RAM's scratch
	ld hl, RandoMartPool
	ld de, sRandoRest
	ld bc, RANDO_MART_POOL
	call CopyData
	ld a, RANDO_MART_POOL
	ld [sRandoRestN], a
	; the list
	pop af
	ld hl, wItemList
	ld [hli], a
	sub RANDO_MART_ALWAYS
	ld b, a
	ld de, RandoMartAlways
	ld c, RANDO_MART_ALWAYS
.always
	ld a, [de]
	ld [hli], a
	inc de
	dec c
	jr nz, .always
.pick
	ld a, b
	and a
	jr z, .done
	push bc
	push hl
	ld a, [sRandoRestN]
	ld e, a
	ld d, 0
	callba RandoRandDE
	call RandoMartTake           ; a = the item
	pop hl
	pop bc
	ld [hli], a
	dec b
	jr .pick
.done
	ld [hl], $ff
	jp RandoCloseSRAM

; a = sRandoRest[e], taken out of it
RandoMartTake:
	ld d, 0
	ld hl, sRandoRest
	add hl, de
	ld c, [hl]
	ld a, [sRandoRestN]
	dec a
	ld [sRandoRestN], a
	sub e
	jr z, .last
	ld b, a
.shift
	inc hl
	ld a, [hld]
	ld [hli], a
	dec b
	jr nz, .shift
.last
	ld a, c
	ret

; ReadTrainer, from the battle: with a seed and RANDOM TRNR, each trainer's
; random #MON come from the seed and who the trainer is, so players with the
; same seed meet the same teams. The game's own random numbers carry on after.
RandoReadTrainer::
	ld a, [wRandoFlags]
	bit RANDO_SEEDED_F, a
	jr z, .unseeded
	CheckEvent EVENT_8D8
	jr nz, .seeded
.unseeded
	jpab ReadTrainer
.seeded
	ld hl, hRandomAdd
	ld a, [hli]
	ld b, [hl]
	ld c, a
	push bc
	ld hl, hRandomLast
	ld a, [hli]
	ld b, [hl]
	ld c, a
	push bc
	ld a, [wTrainerClass]
	ld b, a
	ld a, [wRandoSeed]
	xor b
	ld [hRandomAdd], a
	ld a, [wTrainerNo]
	ld b, a
	ld a, [wRandoSeed + 1]
	xor b
	ld [hRandomAdd + 1], a
	ld a, [wRandoSeed + 2]
	ld [hRandomLast], a
	ld a, [wRandoSeed + 3]
	or 1                         ; never all 0
	ld [hRandomLast + 1], a
	ld b, 4                      ; stir
.stir
	call Random
	dec b
	jr nz, .stir
	callab ReadTrainer
	pop bc
	ld hl, hRandomLast
	ld a, c
	ld [hli], a
	ld [hl], b
	pop bc
	ld hl, hRandomAdd
	ld a, c
	ld [hli], a
	ld [hl], b
	ret

; INDIGO PLATEAU's lobby: with the doors shuffled it can come early, so the
; ELITE FOUR's door is closed to those without all eight badges (in the
; original game ROUTE 23's guards saw to it)
RandoLobbyGate::
	ld a, [wRandoFlags]
	bit RANDO_DOORS_F, a
	ret z
	ld a, [wObtainedBadges]
	inc a
	ret z
	ld a, [wd730]
	bit 7, a                     ; already being moved
	ret nz
	ld a, [wYCoord]
	cp 1
	ret nz
	ld a, [wXCoord]
	cp 8
	ret nz
	ld hl, RandoLobbyGateText
	call PrintText
	ld a, D_DOWN
	ld [wSimulatedJoypadStatesEnd], a
	ld a, 1
	ld [wSimulatedJoypadStatesIndex], a
	jp StartSimulatingJoypadStates

RandoLobbyGateText:
	text "Only trainers with"
	line "all 8 BADGES may"
	cont "face the ELITE 4!"
	done

; SetLastBlackoutMap: with the doors shuffled, the map last left outdoors
; may be any route; a #MON CENTER brings the player back to its own town
RandoBlackoutMap::
	ld a, [wRandoFlags]
	bit RANDO_DOORS_F, a
	ret z
	ld a, [wCurMap]
	ld b, a
	ld hl, RandoCenterTowns
.loop
	ld a, [hli]
	cp -1
	ret z
	cp b
	ld a, [hli]
	jr nz, .loop
	ld [wLastBlackoutMap], a
	ret

RandoCenterTowns:
	db VIRIDIAN_POKECENTER, VIRIDIAN_CITY
	db PEWTER_POKECENTER, PEWTER_CITY
	db CERULEAN_POKECENTER, CERULEAN_CITY
	db MT_MOON_POKECENTER, ROUTE_4
	db ROCK_TUNNEL_POKECENTER, ROUTE_10
	db VERMILION_POKECENTER, VERMILION_CITY
	db CELADON_POKECENTER, CELADON_CITY
	db LAVENDER_POKECENTER, LAVENDER_TOWN
	db FUCHSIA_POKECENTER, FUCHSIA_CITY
	db CINNABAR_POKECENTER, CINNABAR_ISLAND
	db SAFFRON_POKECENTER, SAFFRON_CITY
	db INDIGO_PLATEAU_LOBBY, INDIGO_PLATEAU
	db -1

; ---- levels scaled down: in a world whose order is shuffled (doors or key
; items) a player can arrive anywhere early. A #MON above the party's
; highest level (+2 for a trainer's, +3 for a boss's) comes down to it, and
; if it couldn't have evolved yet at that level, it is what it evolved from.
; Only ever down; Shin's SCALING (up) is its own option.

; before AddPartyMon for a trainer's #MON (wcf91, wCurEnemyLVL)
RandoScaleDown::
	ld c, 2
	ld a, [wGymLeaderNo]
	and a
	jr z, RandoScale
	inc c
	jr RandoScale

; a wild #MON (wcf91 and wEnemyMonSpecies2, wCurEnemyLVL)
RandoScaleDownWild::
	ld c, 0
	call RandoScale
	ld a, [wcf91]
	ld [wEnemyMonSpecies2], a
	ret

; c = how far above the party's highest level it may be
RandoScale:
	ld a, [wRandoFlags]
	and (1 << RANDO_DOORS_F) | (1 << RANDO_KEYS_F)
	ret z
	ld a, [wPartyCount]
	and a
	ret z
	ld b, a
	ld hl, wPartyMon1Level
	ld de, wPartyMon2 - wPartyMon1
	xor a
.highest
	cp [hl]
	jr nc, .lower
	ld a, [hl]
.lower
	add hl, de
	dec b
	jr nz, .highest
	add c
	ld b, a                      ; the cap
	ld a, [wCurEnemyLVL]
	cp b
	ret c
	ret z
	ld a, b
	ld [wCurEnemyLVL], a
.devolve
	ld a, [wcf91]
	and a
	ret z
	cp 191
	ret nc
	dec a
	ld e, a
	ld d, 0
	ld hl, RandoDevolve
	add hl, de
	add hl, de
	ld a, [hli]
	and a
	ret z                        ; nothing before it
	ld d, a
	ld a, [wCurEnemyLVL]
	cp [hl]
	ret nc                       ; old enough to have evolved
	ld a, d
	ld [wcf91], a
	jr .devolve
