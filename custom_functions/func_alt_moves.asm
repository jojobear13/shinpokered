; writes the moves a mon has at level [wCurEnemyLVL] to [de]
; move slots are being filled up sequentially and shifted if all slots are full
WriteMonMoves_Alt:
	ld hl, EvosMovesPointerTable_Alt
	ld b, 0
	ld a, [wcf91]  ; cur mon ID
	dec a
	add a
	rl b
	ld c, a
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
;.skipEvoEntriesLoop
;	ld a, [hli]
;	and a
;	jr nz, .skipEvoEntriesLoop
	jr .firstMove
.nextMove
	pop de
.nextMove2
	inc hl
.firstMove
	ld a, [hli]       ; read level of next move in learnset
	and a
	jp z, .done       ; end of list
	ld b, a
	ld a, [wCurEnemyLVL]
	cp b
	jp c, .done       ; mon level < move level (assumption: learnset is sorted by level)

;	ld a, [wLearningMovesFromDayCare]
;	and a
;	jr z, .skipMinLevelCheck
;	ld a, [wDayCareStartLevel]
;	cp b
;	jr nc, .nextMove2 ; min level >= move level

.skipMinLevelCheck

; check if the move is already known
	push de
	ld c, NUM_MOVES
.alreadyKnowsCheckLoop
	ld a, [de]
	inc de
	cp [hl]
	jr z, .nextMove
	dec c
	jr nz, .alreadyKnowsCheckLoop

; try to find an empty move slot
	pop de
	push de
	ld c, NUM_MOVES
.findEmptySlotLoop
	ld a, [de]
	and a
	jr z, .writeMoveToSlot2
	inc de
	dec c
	jr nz, .findEmptySlotLoop

; no empty move slots found
	pop de
	push de
	push hl
	ld h, d
	ld l, e
	call WriteMonMoves_ShiftMoveData_Alt ; shift all moves one up (deleting move 1)

;	ld a, [wLearningMovesFromDayCare]
;	and a
;	jr z, .writeMoveToSlot
;; shift PP as well if learning moves from day care
;	push de
;	ld bc, wPartyMon1PP - (wPartyMon1Moves + 3)
;	add hl, bc
;	ld d, h
;	ld e, l
;	call WriteMonMoves_ShiftMoveData_Alt ; shift all move PP data one up
;	pop de

.writeMoveToSlot
	pop hl
.writeMoveToSlot2
	ld a, [hl]
	ld [de], a

;	ld a, [wLearningMovesFromDayCare]
;	and a
;	jr z, .nextMove
;; write move PP value if learning moves from day care
;	push hl
;	ld a, [hl]
;	ld hl, wPartyMon1PP - wPartyMon1Moves
;	add hl, de
;	push hl
;	dec a
;	ld hl, Moves
;	ld bc, MoveEnd - Moves
;	call AddNTimes
;	ld de, wBuffer
;	ld a, BANK(Moves)
;	call FarCopyData
;	ld a, [wBuffer + 5]
;	pop hl
;	ld [hl], a
;	pop hl

	jr .nextMove

.done
	ret

; shifts all move data one up (freeing 4th move slot)
WriteMonMoves_ShiftMoveData_Alt:
	ld c, NUM_MOVES - 1
.loop
	inc de
	ld a, [de]
	ld [hli], a
	dec c
	jr nz, .loop
	ret

	
EvosMovesPointerTable_Alt:
	dw RhydonEvosMoves_Alt
	dw KangaskhanEvosMoves_Alt
	dw NidoranMEvosMoves_Alt
	dw ClefairyEvosMoves_Alt
	dw SpearowEvosMoves_Alt
	dw VoltorbEvosMoves_Alt
	dw NidokingEvosMoves_Alt
	dw SlowbroEvosMoves_Alt
	dw IvysaurEvosMoves_Alt
	dw ExeggutorEvosMoves_Alt
	dw LickitungEvosMoves_Alt
	dw ExeggcuteEvosMoves_Alt
	dw GrimerEvosMoves_Alt
	dw GengarEvosMoves_Alt
	dw NidoranFEvosMoves_Alt
	dw NidoqueenEvosMoves_Alt
	dw CuboneEvosMoves_Alt
	dw RhyhornEvosMoves_Alt
	dw LaprasEvosMoves_Alt
	dw ArcanineEvosMoves_Alt
	dw MewEvosMoves_Alt
	dw GyaradosEvosMoves_Alt
	dw ShellderEvosMoves_Alt
	dw TentacoolEvosMoves_Alt
	dw GastlyEvosMoves_Alt
	dw ScytherEvosMoves_Alt
	dw StaryuEvosMoves_Alt
	dw BlastoiseEvosMoves_Alt
	dw PinsirEvosMoves_Alt
	dw TangelaEvosMoves_Alt
	dw MissingNo1FEvosMoves_Alt
	dw MissingNo20EvosMoves_Alt
	dw GrowlitheEvosMoves_Alt
	dw OnixEvosMoves_Alt
	dw FearowEvosMoves_Alt
	dw PidgeyEvosMoves_Alt
	dw SlowpokeEvosMoves_Alt
	dw KadabraEvosMoves_Alt
	dw GravelerEvosMoves_Alt
	dw ChanseyEvosMoves_Alt
	dw MachokeEvosMoves_Alt
	dw MrMimeEvosMoves_Alt
	dw HitmonleeEvosMoves_Alt
	dw HitmonchanEvosMoves_Alt
	dw ArbokEvosMoves_Alt
	dw ParasectEvosMoves_Alt
	dw PsyduckEvosMoves_Alt
	dw DrowzeeEvosMoves_Alt
	dw GolemEvosMoves_Alt
	dw MissingNo32EvosMoves_Alt
	dw MagmarEvosMoves_Alt
	dw MissingNo34EvosMoves_Alt
	dw ElectabuzzEvosMoves_Alt
	dw MagnetonEvosMoves_Alt
	dw KoffingEvosMoves_Alt
	dw MissingNo38EvosMoves_Alt
	dw MankeyEvosMoves_Alt
	dw SeelEvosMoves_Alt
	dw DiglettEvosMoves_Alt
	dw TaurosEvosMoves_Alt
	dw MissingNo3DEvosMoves_Alt
	dw MissingNo3EEvosMoves_Alt
	dw MissingNo3FEvosMoves_Alt
	dw FarfetchdEvosMoves_Alt
	dw VenonatEvosMoves_Alt
	dw DragoniteEvosMoves_Alt
	dw MissingNo43EvosMoves_Alt
	dw MissingNo44EvosMoves_Alt
	dw MissingNo45EvosMoves_Alt
	dw DoduoEvosMoves_Alt
	dw PoliwagEvosMoves_Alt
	dw JynxEvosMoves_Alt
	dw MoltresEvosMoves_Alt
	dw ArticunoEvosMoves_Alt
	dw ZapdosEvosMoves_Alt
	dw DittoEvosMoves_Alt
	dw MeowthEvosMoves_Alt
	dw KrabbyEvosMoves_Alt
	dw MissingNo4FEvosMoves_Alt
	dw MissingNo50EvosMoves_Alt
	dw MissingNo51EvosMoves_Alt
	dw VulpixEvosMoves_Alt
	dw NinetalesEvosMoves_Alt
	dw PikachuEvosMoves_Alt
	dw RaichuEvosMoves_Alt
	dw MissingNo56EvosMoves_Alt
	dw MissingNo57EvosMoves_Alt
	dw DratiniEvosMoves_Alt
	dw DragonairEvosMoves_Alt
	dw KabutoEvosMoves_Alt
	dw KabutopsEvosMoves_Alt
	dw HorseaEvosMoves_Alt
	dw SeadraEvosMoves_Alt
	dw MissingNo5EEvosMoves_Alt
	dw MissingNo5FEvosMoves_Alt
	dw SandshrewEvosMoves_Alt
	dw SandslashEvosMoves_Alt
	dw OmanyteEvosMoves_Alt
	dw OmastarEvosMoves_Alt
	dw JigglypuffEvosMoves_Alt
	dw WigglytuffEvosMoves_Alt
	dw EeveeEvosMoves_Alt
	dw FlareonEvosMoves_Alt
	dw JolteonEvosMoves_Alt
	dw VaporeonEvosMoves_Alt
	dw MachopEvosMoves_Alt
	dw ZubatEvosMoves_Alt
	dw EkansEvosMoves_Alt
	dw ParasEvosMoves_Alt
	dw PoliwhirlEvosMoves_Alt
	dw PoliwrathEvosMoves_Alt
	dw WeedleEvosMoves_Alt
	dw KakunaEvosMoves_Alt
	dw BeedrillEvosMoves_Alt
	dw MissingNo73EvosMoves_Alt
	dw DodrioEvosMoves_Alt
	dw PrimeapeEvosMoves_Alt
	dw DugtrioEvosMoves_Alt
	dw VenomothEvosMoves_Alt
	dw DewgongEvosMoves_Alt
	dw MissingNo79EvosMoves_Alt
	dw MissingNo7AEvosMoves_Alt
	dw CaterpieEvosMoves_Alt
	dw MetapodEvosMoves_Alt
	dw ButterfreeEvosMoves_Alt
	dw MachampEvosMoves_Alt
	dw MissingNo7FEvosMoves_Alt
	dw GolduckEvosMoves_Alt
	dw HypnoEvosMoves_Alt
	dw GolbatEvosMoves_Alt
	dw MewtwoEvosMoves_Alt
	dw SnorlaxEvosMoves_Alt
	dw MagikarpEvosMoves_Alt
	dw MissingNo86EvosMoves_Alt
	dw MissingNo87EvosMoves_Alt
	dw MukEvosMoves_Alt
	dw MissingNo8AEvosMoves_Alt
	dw KinglerEvosMoves_Alt
	dw CloysterEvosMoves_Alt
	dw MissingNo8CEvosMoves_Alt
	dw ElectrodeEvosMoves_Alt
	dw ClefableEvosMoves_Alt
	dw WeezingEvosMoves_Alt
	dw PersianEvosMoves_Alt
	dw MarowakEvosMoves_Alt
	dw MissingNo92EvosMoves_Alt
	dw HaunterEvosMoves_Alt
	dw AbraEvosMoves_Alt
	dw AlakazamEvosMoves_Alt
	dw PidgeottoEvosMoves_Alt
	dw PidgeotEvosMoves_Alt
	dw StarmieEvosMoves_Alt
	dw BulbasaurEvosMoves_Alt
	dw VenusaurEvosMoves_Alt
	dw TentacruelEvosMoves_Alt
	dw MissingNo9CEvosMoves_Alt
	dw GoldeenEvosMoves_Alt
	dw SeakingEvosMoves_Alt
	dw MissingNo9FEvosMoves_Alt
	dw MissingNoA0EvosMoves_Alt
	dw MissingNoA1EvosMoves_Alt
	dw MissingNoA2EvosMoves_Alt
	dw PonytaEvosMoves_Alt
	dw RapidashEvosMoves_Alt
	dw RattataEvosMoves_Alt
	dw RaticateEvosMoves_Alt
	dw NidorinoEvosMoves_Alt
	dw NidorinaEvosMoves_Alt
	dw GeodudeEvosMoves_Alt
	dw PorygonEvosMoves_Alt
	dw AerodactylEvosMoves_Alt
	dw MissingNoACEvosMoves_Alt
	dw MagnemiteEvosMoves_Alt
	dw MissingNoAEEvosMoves_Alt
	dw MissingNoAFEvosMoves_Alt
	dw CharmanderEvosMoves_Alt
	dw SquirtleEvosMoves_Alt
	dw CharmeleonEvosMoves_Alt
	dw WartortleEvosMoves_Alt
	dw CharizardEvosMoves_Alt
	dw MissingNoB5EvosMoves_Alt
	dw FossilKabutopsEvosMoves_Alt
	dw FossilAerodactylEvosMoves_Alt
	dw MonGhostEvosMoves_Alt
	dw OddishEvosMoves_Alt
	dw GloomEvosMoves_Alt
	dw VileplumeEvosMoves_Alt
	dw BellsproutEvosMoves_Alt
	dw WeepinbellEvosMoves_Alt
	dw VictreebelEvosMoves_Alt
	dw $FFFF

	
	
;FORMAT
; db <level>, <move>
;  ...
; db 0 	<--- each pokemon must terminate with zero to designate the end of its move list
;
; Can learn multiple moves at the same level.
; Can learn a move multiple times at different levels.
; Starting moves are set by making them learned at level 1.
;	
;EXAMPLE
;LickitungEvosMoves_Alt:
;; Learnset
;	db 1, LICK
;	db 1, POUND
;	db 1, SUPERSONIC
;	db 7, STOMP
;	db 15, DISABLE
;	db 20, LICK
;	db 23, BODY_SLAM
;	db 23, DEFENSE_CURL
;	db 31, SLAM
;	db 39, SCREECH
;	db 0

BulbasaurEvosMoves_Alt:
; Learnset
	db 7, LEECH_SEED
	db 13, VINE_WHIP
	db 20, POISONPOWDER
	db 27, RAZOR_LEAF
	db 34, GROWTH
	db 41, SLEEP_POWDER
	db 48, SOLARBEAM
	db 0

VenusaurEvosMoves_Alt:
; Learnset
	db 7, LEECH_SEED
	db 13, VINE_WHIP
	db 22, POISONPOWDER
	db 30, RAZOR_LEAF
	db 43, GROWTH
	db 55, SLEEP_POWDER
	db 65, SOLARBEAM
	db 0

IvysaurEvosMoves_Alt:
; Learnset
	db 7, LEECH_SEED
	db 13, VINE_WHIP
	db 22, POISONPOWDER
	db 30, RAZOR_LEAF
	db 38, GROWTH
	db 46, SLEEP_POWDER
	db 54, SOLARBEAM
	db 0

CharmanderEvosMoves_Alt:
; Learnset
	db 9, EMBER
	db 15, LEER
	db 22, RAGE
	db 30, SLASH
	db 38, FLAMETHROWER
	db 46, FIRE_SPIN
	db 0

CharmeleonEvosMoves_Alt:
; Learnset
	db 9, EMBER
	db 15, LEER
	db 24, RAGE
	db 33, SLASH
	db 42, FLAMETHROWER
	db 56, FIRE_SPIN
	db 0

CharizardEvosMoves_Alt:
; Learnset
	db 9, EMBER
	db 15, LEER
	db 24, RAGE
	db 36, SLASH
	db 46, FLAMETHROWER
	db 55, FIRE_SPIN
	db 0

SquirtleEvosMoves_Alt:
; Learnset
	db 8, BUBBLE
	db 15, WATER_GUN
	db 22, BITE
	db 28, WITHDRAW
	db 35, SKULL_BASH
	db 42, HYDRO_PUMP
	db 0

WartortleEvosMoves_Alt:
; Learnset
	db 8, BUBBLE
	db 15, WATER_GUN
	db 24, BITE
	db 31, WITHDRAW
	db 39, SKULL_BASH
	db 47, HYDRO_PUMP
	db 0

BlastoiseEvosMoves_Alt:
; Learnset
	db 8, BUBBLE
	db 15, WATER_GUN
	db 24, BITE
	db 31, WITHDRAW
	db 42, SKULL_BASH
	db 52, HYDRO_PUMP
	db 0

CaterpieEvosMoves_Alt:	
; Learnset
	db 0

MetapodEvosMoves_Alt:
; Learnset
	db 7, HARDEN
	db 0

ButterfreeEvosMoves_Alt:
; Learnset
	db 10, CONFUSION
	db 13, POISONPOWDER
	db 14, STUN_SPORE
	db 15, SLEEP_POWDER
	db 18, SUPERSONIC
	db 23, WHIRLWIND
	db 28, GUST;joenote - yellow update
	db 32, PSYBEAM
	db 0

WeedleEvosMoves_Alt:
; Learnset
	db 0

KakunaEvosMoves_Alt:
; Learnset
	db 7, HARDEN
	db 0

BeedrillEvosMoves_Alt:
; Learnset
	db 12, FURY_ATTACK
	db 16, FOCUS_ENERGY
	db 20, TWINEEDLE
	db 25, RAGE
	db 30, PIN_MISSILE
	db 35, AGILITY
	db 0

PidgeyEvosMoves_Alt:
; Learnset
	db 5, SAND_ATTACK
	db 12, QUICK_ATTACK
	db 19, WHIRLWIND
	db 28, WING_ATTACK
	db 36, AGILITY
	db 44, MIRROR_MOVE
	db 0

PidgeottoEvosMoves_Alt:
; Learnset
	db 5, SAND_ATTACK
	db 12, QUICK_ATTACK
	db 21, WHIRLWIND
	db 31, WING_ATTACK
	db 40, AGILITY
	db 49, MIRROR_MOVE
	db 0

PidgeotEvosMoves_Alt:
; Learnset
	db 5, SAND_ATTACK
	db 12, QUICK_ATTACK
	db 21, WHIRLWIND
	db 31, WING_ATTACK
	db 44, AGILITY
	db 54, MIRROR_MOVE
	db 0

RattataEvosMoves_Alt:
; Learnset
	db 7, QUICK_ATTACK
	db 14, HYPER_FANG
	db 23, FOCUS_ENERGY
	db 34, SUPER_FANG
	db 0

RaticateEvosMoves_Alt:
; Learnset
	db 7, QUICK_ATTACK
	db 14, HYPER_FANG
	db 27, FOCUS_ENERGY
	db 41, SUPER_FANG
	db 0

SpearowEvosMoves_Alt:
; Learnset
	db 9, LEER
	db 15, FURY_ATTACK
	db 22, MIRROR_MOVE
	db 29, DRILL_PECK
	db 36, AGILITY
	db 0

FearowEvosMoves_Alt:
; Learnset
	db 9, LEER
	db 15, FURY_ATTACK
	db 25, MIRROR_MOVE
	db 34, DRILL_PECK
	db 43, AGILITY
	db 0

EkansEvosMoves_Alt:
; Learnset
	db 10, POISON_STING
	db 17, BITE
	db 24, GLARE
	db 31, SCREECH
	db 38, ACID
	db 0

ArbokEvosMoves_Alt:
; Learnset
	db 10, POISON_STING
	db 17, BITE
	db 27, GLARE
	db 36, SCREECH
	db 47, ACID
	db 0

PikachuEvosMoves_Alt:
; Learnset
	db 6, TAIL_WHIP
	db 8, THUNDER_WAVE
	db 11, QUICK_ATTACK
	db 11, THUNDERSHOCK
	db 15, DOUBLE_TEAM
	db 20, SLAM
	db 26, THUNDERBOLT
	db 29, SWIFT
	db 33, AGILITY
	db 41, THUNDER
	db 50, LIGHT_SCREEN
	db 0

RaichuEvosMoves_Alt:
; Learnset;joenote-modified just for fun
	db 11, TAIL_WHIP
	db 13, THUNDER_WAVE
	db 25, SLAM
	db 31, THUNDER
	db 46, REFLECT
	db 55, LIGHT_SCREEN
	db 0

SandshrewEvosMoves_Alt:
; Learnset
	db 10, SAND_ATTACK
	db 17, SLASH
	db 24, POISON_STING
	db 31, SWIFT
	db 38, FURY_SWIPES
	db 0

SandslashEvosMoves_Alt:
; Learnset
	db 10, SAND_ATTACK
	db 17, SLASH
	db 27, POISON_STING
	db 36, SWIFT
	db 47, FURY_SWIPES
	db 0

NidoranFEvosMoves_Alt:
; Learnset
	db 8, SCRATCH
	db 12, DOUBLE_KICK
	db 17, POISON_STING
	db 23, TAIL_WHIP
	db 30, BITE
	db 38, FURY_SWIPES
	db 0

NidorinaEvosMoves_Alt:
; Learnset
	db 8, SCRATCH
	db 12, DOUBLE_KICK
	db 19, POISON_STING
	db 27, TAIL_WHIP
	db 36, BITE
	db 46, FURY_SWIPES
	db 0

NidoqueenEvosMoves_Alt:
; Learnset
	db 8, SCRATCH
	db 12, DOUBLE_KICK
	db 19, POISON_STING
	db 23, BODY_SLAM
	db 0

NidoranMEvosMoves_Alt:
; Learnset
	db 8, HORN_ATTACK
	db 12, DOUBLE_KICK
	db 17, POISON_STING
	db 23, FOCUS_ENERGY
	db 30, FURY_ATTACK
	db 38, HORN_DRILL
	db 0

NidorinoEvosMoves_Alt:
; Learnset
	db 8, HORN_ATTACK
	db 12, DOUBLE_KICK
	db 19, POISON_STING
	db 27, FOCUS_ENERGY
	db 36, FURY_ATTACK
	db 46, HORN_DRILL
	db 0

NidokingEvosMoves_Alt:
; Learnset
	db 8, HORN_ATTACK
	db 12, DOUBLE_KICK
	db 19, POISON_STING
	db 23, THRASH
	db 0

ClefairyEvosMoves_Alt:
; Learnset
	db 13, SING
	db 18, DOUBLESLAP
	db 24, MINIMIZE
	db 31, METRONOME
	db 39, DEFENSE_CURL
	db 48, LIGHT_SCREEN
	db 0

ClefableEvosMoves_Alt:
; Learnset
	db 13, SING
	db 18, DOUBLESLAP
	db 24, MINIMIZE
	db 31, METRONOME
	db 0

VulpixEvosMoves_Alt:
; Learnset
	db 16, QUICK_ATTACK
	db 21, ROAR
	db 28, CONFUSE_RAY
	db 35, FLAMETHROWER
	db 42, FIRE_SPIN
	db 0

NinetalesEvosMoves_Alt:
; Learnset
	db 20, QUICK_ATTACK
	db 28, CONFUSE_RAY
	db 36, FLAMETHROWER
	db 44, FIRE_SPIN
	db 0

JigglypuffEvosMoves_Alt:
; Learnset
	db 9, POUND
	db 14, DISABLE
	db 19, DEFENSE_CURL
	db 24, DOUBLESLAP
	db 29, REST
	db 34, BODY_SLAM
	db 39, DOUBLE_EDGE
	db 0

WigglytuffEvosMoves_Alt:
; Learnset
	db 9, POUND
	db 14, DISABLE
	db 19, DEFENSE_CURL
	db 24, SING
	db 29, DOUBLESLAP
	db 34, DISABLE
	db 39, BODY_SLAM
	db 0

ZubatEvosMoves_Alt:
; Learnset
	db 10, SUPERSONIC
	db 15, BITE
	db 21, CONFUSE_RAY
	db 28, WING_ATTACK
	db 36, HAZE
	db 0

GolbatEvosMoves_Alt:
; Learnset
	db 10, SUPERSONIC
	db 15, BITE
	db 21, CONFUSE_RAY
	db 32, WING_ATTACK
	db 43, HAZE
	db 0

OddishEvosMoves_Alt:
; Learnset
	db 15, POISONPOWDER
	db 17, STUN_SPORE
	db 19, SLEEP_POWDER
	db 24, ACID
	db 33, PETAL_DANCE
	db 46, SOLARBEAM
	db 0

GloomEvosMoves_Alt:
; Learnset
	db 15, POISONPOWDER
	db 17, STUN_SPORE
	db 19, SLEEP_POWDER
	db 28, ACID
	db 38, PETAL_DANCE
	db 52, SOLARBEAM
	db 0

VileplumeEvosMoves_Alt:
; Learnset
	db 15, POISONPOWDER
	db 17, STUN_SPORE
	db 19, SLEEP_POWDER
	db 30, ACID
	db 40, PETAL_DANCE
	db 0

ParasEvosMoves_Alt:
; Learnset
	db 13, STUN_SPORE
	db 20, LEECH_LIFE
	db 27, SPORE
	db 34, SLASH
	db 41, GROWTH
	db 0

ParasectEvosMoves_Alt:
; Learnset
	db 13, STUN_SPORE
	db 20, LEECH_LIFE
	db 30, SPORE
	db 39, SLASH
	db 48, GROWTH
	db 0

VenonatEvosMoves_Alt:
; Learnset
	db 11, SUPERSONIC
	db 19, CONFUSION
	db 22, POISONPOWDER
	db 27, LEECH_LIFE
	db 30, STUN_SPORE
	db 35, PSYBEAM
	db 38, SLEEP_POWDER
	db 43, PSYCHIC_M
	db 0

VenomothEvosMoves_Alt:
; Learnset
	db 11, SUPERSONIC
	db 19, CONFUSION
	db 22, POISONPOWDER
	db 27, LEECH_LIFE
	db 30, STUN_SPORE
	db 38, PSYBEAM
	db 43, SLEEP_POWDER
	db 50, PSYCHIC_M
	db 0

DiglettEvosMoves_Alt:
; Learnset
	db 15, GROWL
	db 19, DIG
	db 24, SAND_ATTACK
	db 31, SLASH
	db 40, EARTHQUAKE
	db 0

DugtrioEvosMoves_Alt:
; Learnset
	db 15, GROWL
	db 19, DIG
	db 24, SAND_ATTACK
	db 35, SLASH
	db 47, EARTHQUAKE
	db 0

MeowthEvosMoves_Alt:
; Learnset
	db 12, BITE
	db 17, PAY_DAY
	db 24, SCREECH
	db 33, FURY_SWIPES
	db 44, SLASH
	db 0

PersianEvosMoves_Alt:
; Learnset
	db 12, BITE
	db 17, PAY_DAY
	db 24, SCREECH
	db 37, FURY_SWIPES
	db 51, SLASH
	db 0

PsyduckEvosMoves_Alt:
; Learnset
	db 28, TAIL_WHIP
	db 31, DISABLE
	db 36, CONFUSION
	db 43, FURY_SWIPES
	db 52, HYDRO_PUMP
	db 0

GolduckEvosMoves_Alt:
; Learnset
	db 28, TAIL_WHIP
	db 31, DISABLE
	db 39, CONFUSION
	db 48, FURY_SWIPES
	db 59, HYDRO_PUMP
	db 0

MankeyEvosMoves_Alt:
; Learnset
	db 9, LOW_KICK
	db 15, KARATE_CHOP
	db 21, FURY_SWIPES
	db 27, FOCUS_ENERGY
	db 33, SEISMIC_TOSS
	db 39, THRASH
	db 45, SCREECH
	db 0

PrimeapeEvosMoves_Alt:
; Learnset
	db 9, LOW_KICK
	db 15, KARATE_CHOP
	db 21, FURY_SWIPES
	db 27, FOCUS_ENERGY
	db 28, RAGE
	db 37, SEISMIC_TOSS
	db 45, SCREECH
	db 46, THRASH
	db 0

GrowlitheEvosMoves_Alt:
; Learnset
	db 18, EMBER
	db 23, LEER
	db 30, TAKE_DOWN
	db 39, AGILITY
	db 50, FLAMETHROWER
	db 0

ArcanineEvosMoves_Alt:
; Learnset
	db 20, EMBER
	db 20, BITE
	db 30, LEER
	db 40, TAKE_DOWN
	db 50, FLAMETHROWER
	db 0

PoliwagEvosMoves_Alt:
; Learnset
	db 16, HYPNOSIS
	db 19, WATER_GUN
	db 25, DOUBLESLAP
	db 31, BODY_SLAM
	db 38, AMNESIA
	db 45, HYDRO_PUMP
	db 0

PoliwhirlEvosMoves_Alt:
; Learnset
	db 16, HYPNOSIS
	db 19, WATER_GUN
	db 26, DOUBLESLAP
	db 33, BODY_SLAM
	db 41, AMNESIA
	db 49, HYDRO_PUMP
	db 0

PoliwrathEvosMoves_Alt:
; Learnset
	db 16, WATER_GUN
	db 19, HYPNOSIS
	db 27, DOUBLESLAP
	db 35, SUBMISSION
	db 44, BUBBLEBEAM
	db 0

AbraEvosMoves_Alt:
; Learnset
	db 0

KadabraEvosMoves_Alt:
; Learnset
	db 16, KINESIS
	db 16, CONFUSION
	db 20, DISABLE
	db 27, PSYBEAM
	db 31, RECOVER
	db 38, PSYCHIC_M
	db 42, REFLECT
	db 0

AlakazamEvosMoves_Alt:
; Learnset
	db 16, CONFUSION
	db 20, DISABLE
	db 27, PSYBEAM
	db 31, RECOVER
	db 38, PSYCHIC_M
	db 42, REFLECT
	db 0

MachopEvosMoves_Alt:
; Learnset
	db 20, LOW_KICK
	db 25, LEER
	db 32, FOCUS_ENERGY
	db 39, SEISMIC_TOSS
	db 46, SUBMISSION
	db 0

MachokeEvosMoves_Alt:
; Learnset
	db 20, LOW_KICK
	db 25, LEER
	db 36, FOCUS_ENERGY
	db 44, SEISMIC_TOSS
	db 52, SUBMISSION
	db 0

MachampEvosMoves_Alt:
; Learnset
	db 20, LOW_KICK
	db 25, LEER
	db 36, FOCUS_ENERGY
	db 44, SEISMIC_TOSS
	db 52, SUBMISSION
	db 0

BellsproutEvosMoves_Alt:
; Learnset
	db 13, WRAP
	db 15, POISONPOWDER
	db 18, SLEEP_POWDER
	db 21, STUN_SPORE
	db 26, ACID
	db 33, RAZOR_LEAF
	db 42, SLAM
	db 0

WeepinbellEvosMoves_Alt:
; Learnset
	db 13, WRAP
	db 15, POISONPOWDER
	db 18, SLEEP_POWDER
	db 23, STUN_SPORE
	db 29, ACID
	db 38, RAZOR_LEAF
	db 49, SLAM
	db 0

VictreebelEvosMoves_Alt:
; Learnset
	db 13, WRAP
	db 18, POISONPOWDER
	db 23, SLEEP_POWDER
	db 30, STUN_SPORE
	db 37, ACID
	db 44, RAZOR_LEAF
	db 0

TentacoolEvosMoves_Alt:
; Learnset
	db 7, SUPERSONIC
	db 13, WRAP
	db 18, POISON_STING
	db 22, WATER_GUN
	db 27, CONSTRICT
	db 33, BARRIER
	db 40, SCREECH
	db 48, HYDRO_PUMP
	db 0

TentacruelEvosMoves_Alt:
; Learnset
	db 7, SUPERSONIC
	db 13, WRAP
	db 18, POISON_STING
	db 22, WATER_GUN
	db 27, CONSTRICT
	db 35, BARRIER
	db 43, SCREECH
	db 50, HYDRO_PUMP
	db 0

GeodudeEvosMoves_Alt:
; Learnset
	db 11, DEFENSE_CURL
	db 16, ROCK_THROW
	db 21, SELFDESTRUCT
	db 26, BODY_SLAM	;added for late-game trainers
	db 26, HARDEN
	db 31, EARTHQUAKE
	db 36, EXPLOSION
	db 0

GravelerEvosMoves_Alt:
; Learnset
	db 11, DEFENSE_CURL
	db 16, ROCK_THROW
	db 21, SELFDESTRUCT
	db 29, BODY_SLAM	;added for late-game trainers
	db 29, HARDEN
	db 36, EARTHQUAKE
	db 43, EXPLOSION
	db 0

GolemEvosMoves_Alt:
; Learnset
	db 11, DEFENSE_CURL
	db 16, ROCK_THROW
	db 21, SELFDESTRUCT
	db 29, BODY_SLAM	;joenote - added for late-game trainers
	db 29, HARDEN
	db 36, EARTHQUAKE
	db 43, EXPLOSION
	db 0

PonytaEvosMoves_Alt:
; Learnset
	db 30, TAIL_WHIP
	db 32, STOMP
	db 35, GROWL
	db 39, FIRE_SPIN
	db 43, TAKE_DOWN
	db 48, AGILITY
	db 0

RapidashEvosMoves_Alt:
; Learnset
	db 30, TAIL_WHIP
	db 32, STOMP
	db 35, GROWL
	db 39, FIRE_SPIN
	db 47, TAKE_DOWN
	db 55, AGILITY
	db 0

SlowpokeEvosMoves_Alt:
; Learnset
	db 18, DISABLE
	db 22, HEADBUTT
	db 27, GROWL
	db 33, WATER_GUN
	db 40, AMNESIA
	db 48, PSYCHIC_M
	db 0

SlowbroEvosMoves_Alt:
; Learnset
	db 18, DISABLE
	db 22, HEADBUTT
	db 27, GROWL
	db 33, WATER_GUN
	db 37, WITHDRAW
	db 44, AMNESIA
	db 55, PSYCHIC_M
	db 0

MagnemiteEvosMoves_Alt:
; Learnset
	db 21, SONICBOOM
	db 25, THUNDERSHOCK
	db 29, SUPERSONIC
	db 35, THUNDER_WAVE
	db 41, SWIFT
	db 47, SCREECH
	db 0

MagnetonEvosMoves_Alt:
; Learnset
	db 21, SONICBOOM
	db 25, THUNDERSHOCK
	db 29, SUPERSONIC
	db 38, THUNDER_WAVE
	db 46, SWIFT
	db 54, SCREECH
	db 0

FarfetchdEvosMoves_Alt:
; Learnset
	db 7, LEER
	db 15, FURY_ATTACK
	db 23, SWORDS_DANCE
	db 31, AGILITY
	db 39, SLASH
	db 0

DoduoEvosMoves_Alt:
; Learnset
	db 20, GROWL
	db 24, FURY_ATTACK
	db 30, DRILL_PECK
	db 36, RAGE
	db 40, TRI_ATTACK
	db 44, AGILITY
	db 0

DodrioEvosMoves_Alt:
; Learnset
	db 20, GROWL
	db 24, FURY_ATTACK
	db 30, DRILL_PECK
	db 39, RAGE
	db 45, TRI_ATTACK
	db 51, AGILITY
	db 0

SeelEvosMoves_Alt:
; Learnset
	db 30, GROWL
	db 35, AURORA_BEAM
	db 40, REST
	db 45, TAKE_DOWN
	db 50, ICE_BEAM
	db 0

DewgongEvosMoves_Alt:
; Learnset
	db 30, GROWL
	db 35, AURORA_BEAM
	db 44, REST
	db 50, TAKE_DOWN
	db 56, ICE_BEAM
	db 0

GrimerEvosMoves_Alt:
; Learnset
	db 30, POISON_GAS
	db 33, MINIMIZE
	db 37, SLUDGE
	db 42, HARDEN
	db 48, SCREECH
	db 55, ACID_ARMOR
	db 0

MukEvosMoves_Alt:
; Learnset
	db 30, POISON_GAS
	db 33, MINIMIZE
	db 37, SLUDGE
	db 45, HARDEN
	db 53, SCREECH
	db 60, ACID_ARMOR
	db 0

ShellderEvosMoves_Alt:
; Learnset
	db 18, SUPERSONIC
	db 23, CLAMP
	db 30, AURORA_BEAM
	db 39, LEER
	db 50, ICE_BEAM
	db 0

CloysterEvosMoves_Alt:
; Learnset
	db 18, SUPERSONIC
	db 23, CLAMP
	db 30, WATER_GUN
	db 39, AURORA_BEAM
	db 50, SPIKE_CANNON
	db 0

GastlyEvosMoves_Alt:
; Learnset
	db 27, HYPNOSIS
	db 35, DREAM_EATER
	db 0

HaunterEvosMoves_Alt:
; Learnset
	db 29, HYPNOSIS
	db 38, DREAM_EATER
	db 0

GengarEvosMoves_Alt:
; Learnset
	db 29, HYPNOSIS
	db 38, DREAM_EATER
	db 0

OnixEvosMoves_Alt:
; Learnset
	db 15, BIND
	db 19, ROCK_THROW
	db 25, RAGE
	db 33, SLAM
	db 43, HARDEN
	db 0

DrowzeeEvosMoves_Alt:
; Learnset
	db 12, DISABLE
	db 17, CONFUSION
	db 24, HEADBUTT
	db 29, POISON_GAS
	db 32, PSYCHIC_M
	db 37, MEDITATE
	db 0

HypnoEvosMoves_Alt:
; Learnset
	db 12, DISABLE
	db 17, CONFUSION
	db 24, HEADBUTT
	db 33, POISON_GAS
	db 37, PSYCHIC_M
	db 43, MEDITATE
	db 0

KrabbyEvosMoves_Alt:
; Learnset
	db 20, VICEGRIP
	db 25, GUILLOTINE
	db 30, STOMP
	db 35, CRABHAMMER
	db 40, HARDEN
	db 0

KinglerEvosMoves_Alt:
; Learnset
	db 20, VICEGRIP
	db 25, GUILLOTINE
	db 34, STOMP
	db 42, CRABHAMMER
	db 49, HARDEN
	db 0

VoltorbEvosMoves_Alt:
; Learnset
	db 17, SONICBOOM
	db 22, SELFDESTRUCT
	db 29, LIGHT_SCREEN
	db 29, REFLECT	
	db 36, SWIFT
	db 43, EXPLOSION
	db 0

ElectrodeEvosMoves_Alt:
; Learnset
	db 17, SONICBOOM
	db 22, SELFDESTRUCT
	db 29, LIGHT_SCREEN
	db 29, REFLECT	;joenote - added for late-game trainers
	db 40, SWIFT
	db 50, EXPLOSION
	db 0

ExeggcuteEvosMoves_Alt:
; Learnset
	db 25, REFLECT
	db 28, LEECH_SEED
	db 32, STUN_SPORE
	db 37, POISONPOWDER
	db 42, SOLARBEAM
	db 48, SLEEP_POWDER
	db 0

ExeggutorEvosMoves_Alt:
; Learnset
	db 19, EGG_BOMB
	db 25, REFLECT
	db 28, STOMP
	db 42, SOLARBEAM
	db 48, HYPNOSIS
	db 0

CuboneEvosMoves_Alt:
; Learnset
	db 13, TAIL_WHIP
	db 16, HEADBUTT
	db 25, LEER
	db 31, FOCUS_ENERGY
	db 38, THRASH
	db 43, BONEMERANG
	db 46, RAGE
	db 0

MarowakEvosMoves_Alt:
; Learnset
	db 13, TAIL_WHIP
	db 16, HEADBUTT
	db 25, LEER
	db 33, FOCUS_ENERGY
	db 41, THRASH
	db 48, BONEMERANG
	db 55, RAGE
	db 0

HitmonleeEvosMoves_Alt:
; Learnset
	db 33, ROLLING_KICK
	db 38, JUMP_KICK
	db 43, FOCUS_ENERGY
	db 48, HI_JUMP_KICK
	db 53, MEGA_KICK
	db 0

HitmonchanEvosMoves_Alt:
; Learnset
	db 33, FIRE_PUNCH
	db 38, ICE_PUNCH
	db 43, THUNDERPUNCH
	db 48, MEGA_PUNCH
	db 53, COUNTER
	db 0

LickitungEvosMoves_Alt:
; Learnset
	db 7, STOMP
	db 15, DISABLE
	db 23, DEFENSE_CURL
	db 31, SLAM
	db 39, SCREECH
	db 0

KoffingEvosMoves_Alt:
; Learnset
	db 32, SLUDGE
	db 37, SMOKESCREEN
	db 40, SELFDESTRUCT
	db 42, MIMIC	;added for late-game trainers
	db 42, SLUDGE	;added for late-game trainers
	db 45, HAZE
	db 48, EXPLOSION
	db 0

WeezingEvosMoves_Alt:
; Learnset
	db 32, SLUDGE
	db 39, SMOKESCREEN
	db 43, SELFDESTRUCT
	db 45, MIMIC	;joenote - added for late-game trainers
	db 47, SLUDGE	;joenote - added for late-game trainers
	db 49, HAZE
	db 53, EXPLOSION
	db 0

RhydonEvosMoves_Alt:
; Learnset
	db 30, STOMP
	db 35, TAIL_WHIP
	db 40, FURY_ATTACK
	db 48, HORN_DRILL
	db 55, LEER
	db 64, TAKE_DOWN
	db 0

RhyhornEvosMoves_Alt:
; Learnset
	db 30, STOMP
	db 35, TAIL_WHIP
	db 40, FURY_ATTACK
	db 45, HORN_DRILL
	db 50, LEER
	db 55, TAKE_DOWN
	db 0

ChanseyEvosMoves_Alt:
; Learnset
	db 12, TAIL_WHIP
	db 24, SING
	db 30, GROWL
	db 38, MINIMIZE
	db 44, DEFENSE_CURL
	db 48, LIGHT_SCREEN
	db 54, DOUBLE_EDGE
	db 0

TangelaEvosMoves_Alt:
; Learnset
	db 27, ABSORB
	db 29, VINE_WHIP
	db 32, POISONPOWDER
	db 36, STUN_SPORE
	db 39, SLEEP_POWDER
	db 45, SLAM
	db 49, GROWTH
	db 0

KangaskhanEvosMoves_Alt:
; Learnset
	db 26, BITE
	db 31, TAIL_WHIP
	db 36, MEGA_PUNCH
	db 41, LEER
	db 46, DIZZY_PUNCH
	db 0

HorseaEvosMoves_Alt:
; Learnset
	db 19, SMOKESCREEN
	db 24, LEER
	db 30, WATER_GUN
	db 37, AGILITY
	db 45, HYDRO_PUMP
	db 0

SeadraEvosMoves_Alt:
; Learnset
	db 19, SMOKESCREEN
	db 24, LEER
	db 30, WATER_GUN
	db 41, AGILITY
	db 52, HYDRO_PUMP
	db 0

GoldeenEvosMoves_Alt:
; Learnset
	db 19, SUPERSONIC
	db 24, HORN_ATTACK
	db 30, FURY_ATTACK
	db 37, WATERFALL
	db 45, HORN_DRILL
	db 54, AGILITY
	db 0

SeakingEvosMoves_Alt:
; Learnset
	db 19, SUPERSONIC
	db 24, HORN_ATTACK
	db 30, FURY_ATTACK
	db 39, WATERFALL
	db 48, HORN_DRILL
	db 54, AGILITY
	db 0

StaryuEvosMoves_Alt:
; Learnset
	db 17, WATER_GUN
	db 22, HARDEN
	db 27, RECOVER
	db 32, SWIFT
	db 37, MINIMIZE
	db 42, LIGHT_SCREEN
	db 47, HYDRO_PUMP
	db 0

StarmieEvosMoves_Alt:
; Learnset
	db 17, WATER_GUN
	db 22, HARDEN
	db 31, RECOVER
	db 38, SWIFT
	db 47, HYDRO_PUMP
	db 54, REFLECT
	db 0

MrMimeEvosMoves_Alt:
; Learnset
	db 15, CONFUSION
	db 23, LIGHT_SCREEN
	db 31, DOUBLESLAP
	db 39, MEDITATE
	db 47, SUBSTITUTE
	db 0

ScytherEvosMoves_Alt:
; Learnset
	db 17, LEER
	db 20, FOCUS_ENERGY
	db 24, DOUBLE_TEAM
	db 29, SLASH
	db 35, SWORDS_DANCE
	db 42, AGILITY
	db 50, WING_ATTACK
	db 0

JynxEvosMoves_Alt:
; Learnset
	db 18, LICK
	db 23, DOUBLESLAP
	db 31, ICE_PUNCH
	db 39, BODY_SLAM
	db 47, THRASH
	db 58, BLIZZARD
	db 0

ElectabuzzEvosMoves_Alt:
; Learnset
	db 34, THUNDERSHOCK
	db 37, SCREECH
	db 42, THUNDERPUNCH
	db 49, LIGHT_SCREEN
	db 54, THUNDER
	db 0

MagmarEvosMoves_Alt:
; Learnset
	db 36, LEER
	db 39, CONFUSE_RAY
	db 43, FIRE_PUNCH
	db 48, SMOKESCREEN
	db 52, SMOG
	db 55, FLAMETHROWER
	db 0

PinsirEvosMoves_Alt:
; Learnset
	db 21, BIND
	db 25, SEISMIC_TOSS
	db 30, GUILLOTINE
	db 36, FOCUS_ENERGY
	db 43, HARDEN
	db 49, SLASH
	db 54, SWORDS_DANCE
	db 0

TaurosEvosMoves_Alt:
; Learnset
	db 21, STOMP
	db 28, TAIL_WHIP
	db 35, LEER
	db 44, RAGE
	db 51, TAKE_DOWN
	db 0

MagikarpEvosMoves_Alt:
; Learnset
	db 15, TACKLE
	db 0

GyaradosEvosMoves_Alt:
; Learnset
	db 20, BITE
	db 25, DRAGON_RAGE
	db 32, LEER
	db 41, HYDRO_PUMP
	db 52, HYPER_BEAM
	db 0

LaprasEvosMoves_Alt:
; Learnset
	db 16, SING
	db 20, MIST
	db 25, BODY_SLAM
	db 31, CONFUSE_RAY
	db 38, ICE_BEAM
	db 46, HYDRO_PUMP
	db 0

DittoEvosMoves_Alt:
; Learnset
	db 0

EeveeEvosMoves_Alt:
; Learnset
	db 8, SAND_ATTACK
	db 16, GROWL
	db 23, QUICK_ATTACK
	db 30, BITE
	db 31, TAIL_WHIP
	db 36, FOCUS_ENERGY
	db 42, TAKE_DOWN
	db 0

VaporeonEvosMoves_Alt:
; Learnset
	db 8, SAND_ATTACK
	db 16, GROWL
	db 23, QUICK_ATTACK
	db 30, BITE
	db 31, WATER_GUN
	db 36, AURORA_BEAM
	db 37, TAIL_WHIP
	db 40, BITE
	db 42, ACID_ARMOR
	db 44, HAZE
	db 47, AURORA_BEAM
	db 48, MIST
	db 52, HYDRO_PUMP
	db 0

JolteonEvosMoves_Alt:
; Learnset
	db 8, SAND_ATTACK
	db 16, GROWL
	db 23, QUICK_ATTACK
	db 30, DOUBLE_KICK
	db 31, THUNDERSHOCK
	db 36, PIN_MISSILE
	db 37, TAIL_WHIP
	db 40, DOUBLE_KICK
	db 42, THUNDER_WAVE
	db 44, AGILITY
	db 48, PIN_MISSILE
	db 52, THUNDER
	db 0

FlareonEvosMoves_Alt:
; Learnset
	db 8, SAND_ATTACK
	db 16, GROWL
	db 23, QUICK_ATTACK
	db 30, BITE
	db 31, EMBER
	db 36, FIRE_SPIN
	db 37, TAIL_WHIP
	db 40, BITE
	db 42, LEER
	db 44, FIRE_SPIN
	db 47, SMOG
	db 48, RAGE
	db 52, FLAMETHROWER
	db 0

PorygonEvosMoves_Alt:
; Learnset
	db 23, PSYBEAM
	db 28, RECOVER
	db 35, AGILITY
	db 42, TRI_ATTACK
	db 0

OmanyteEvosMoves_Alt:
; Learnset
	db 34, HORN_ATTACK
	db 39, LEER
	db 46, SPIKE_CANNON
	db 53, HYDRO_PUMP
	db 0

OmastarEvosMoves_Alt:
; Learnset
	db 34, HORN_ATTACK
	db 39, LEER
	db 44, SPIKE_CANNON
	db 49, HYDRO_PUMP
	db 0

KabutoEvosMoves_Alt:
; Learnset
	db 34, ABSORB
	db 39, SLASH
	db 44, LEER
	db 49, HYDRO_PUMP
	db 0

KabutopsEvosMoves_Alt:
; Learnset
	db 34, ABSORB
	db 39, SLASH
	db 46, LEER
	db 53, HYDRO_PUMP
	db 0

AerodactylEvosMoves_Alt:
; Learnset
	db 33, SUPERSONIC
	db 38, BITE
	db 45, TAKE_DOWN
	db 54, HYPER_BEAM
	db 0

SnorlaxEvosMoves_Alt:
; Learnset
	db 35, BODY_SLAM
	db 41, HARDEN
	db 48, DOUBLE_EDGE
	db 56, HYPER_BEAM
	db 0

ArticunoEvosMoves_Alt:
; Learnset
	db 51, BLIZZARD
	db 55, AGILITY
	db 60, MIST
	db 0

ZapdosEvosMoves_Alt:
; Learnset
	db 51, THUNDER
	db 55, AGILITY
	db 60, LIGHT_SCREEN
	db 0

MoltresEvosMoves_Alt:
; Learnset
	db 51, LEER
	db 55, AGILITY
	db 60, SKY_ATTACK
	db 0

DratiniEvosMoves_Alt:
; Learnset
	db 10, THUNDER_WAVE
	db 20, AGILITY
	db 30, SLAM
	db 40, DRAGON_RAGE
	db 50, HYPER_BEAM
	db 0

DragonairEvosMoves_Alt:
; Learnset
	db 10, THUNDER_WAVE
	db 20, AGILITY
	db 35, SLAM
	db 45, DRAGON_RAGE
	db 55, HYPER_BEAM
	db 0

DragoniteEvosMoves_Alt:
; Learnset
	db 10, THUNDER_WAVE
	db 20, AGILITY
	db 35, SLAM
	db 45, DRAGON_RAGE
	db 60, HYPER_BEAM
	db 0

MewtwoEvosMoves_Alt:
; Learnset
	db 63, BARRIER
	db 66, PSYCHIC_M
	db 70, RECOVER
	db 75, MIST
	db 81, AMNESIA
	db 0

MewEvosMoves_Alt:
; Learnset
	db 10, TRANSFORM
	db 20, MEGA_PUNCH
	db 30, METRONOME
	db 40, PSYCHIC_M
	db 0

MissingNo1FEvosMoves_Alt:
MissingNo20EvosMoves_Alt:
MissingNo32EvosMoves_Alt:
MissingNo34EvosMoves_Alt:
MissingNo38EvosMoves_Alt:
MissingNo3DEvosMoves_Alt:
MissingNo3EEvosMoves_Alt:
MissingNo3FEvosMoves_Alt:
MissingNo43EvosMoves_Alt:
MissingNo44EvosMoves_Alt:
MissingNo45EvosMoves_Alt:
MissingNo4FEvosMoves_Alt:
MissingNo50EvosMoves_Alt:
MissingNo51EvosMoves_Alt:
MissingNo56EvosMoves_Alt:
MissingNo57EvosMoves_Alt:
MissingNo5EEvosMoves_Alt:
MissingNo5FEvosMoves_Alt:
MissingNo73EvosMoves_Alt:
MissingNo79EvosMoves_Alt:
MissingNo7AEvosMoves_Alt:
MissingNo7FEvosMoves_Alt:
MissingNo86EvosMoves_Alt:
MissingNo87EvosMoves_Alt:
MissingNo8AEvosMoves_Alt:
MissingNo8CEvosMoves_Alt:
MissingNo92EvosMoves_Alt:
MissingNo9CEvosMoves_Alt:
MissingNo9FEvosMoves_Alt:
MissingNoA0EvosMoves_Alt:
MissingNoA1EvosMoves_Alt:
MissingNoA2EvosMoves_Alt:
MissingNoACEvosMoves_Alt:
MissingNoAEEvosMoves_Alt:
MissingNoAFEvosMoves_Alt:
MissingNoB5EvosMoves_Alt:
FossilKabutopsEvosMoves_Alt:
FossilAerodactylEvosMoves_Alt:
MonGhostEvosMoves_Alt:
; Learnset
	db 0



SpecialTrainerMoves_ALT:		
;Format Explanation:
;	FD is the terminator for custom moves
;	FE is the terminator for each trainer class entry
;	FF is the terminator for the whole list
;
;A Class entry looks like this:
;	db <trainer class>, <class instance>
;	db <species instance>, <species>, <move to add>, ..., $FD
;	db ...
;	db $FE
;
;	<trainer class> = Constant of the trainer class to be affected.
;
;	<class instance> = Instance of the class to be affected. 
;	Like how there are multiple instances of the champion rival depending on starter chosen.
;	If this is 0, then the moves will be applied to the trainer class regardless of instance.
;
;	<species instance> = 1st, 2nd, 3rd, etc, occurance of a pokemon species on the trainer's team.
;	If this is 0, then the moves will be applied to every one of that species on the trainer's team.
;
;	<species> = Constant of the pokemon species to be affected.
;
;	<move to add> = Constant of the move to be added.
;	Moves that are already known are skipped.
;	Moves will go into unoccupied move slots first.
;	If all move slots are filled...
;		The first move is erased and the other three moves are shifted upwards.
;		The new move is then slotted into the fourth move slot.

	db BROCK, 1
	db 1, ONIX, BIDE, $FD
	db $FE
	
	db MISTY, 1
	db 1, STARMIE, BUBBLEBEAM, $FD
	db $FE
	
	db LT_SURGE, 1
	db 1, RAICHU, THUNDERBOLT, $FD
	db $FE
	
	db ERIKA, 1
	db 1, VILEPLUME, PETAL_DANCE, MEGA_DRAIN, $FD
	db $FE
	
	db KOGA, 1
	db 1, WEEZING, TOXIC, $FD
	db $FE
	
	db SABRINA, 1
	db 1, ALAKAZAM, PSYWAVE, $FD
	db $FE
	
	db BLAINE, 1
	db 1, ARCANINE, FIRE_BLAST, $FD
	db $FE
	
	db GIOVANNI, 3
	db 1, DUGTRIO, FISSURE, $FD
	db $FE
	
	db LORELEI, 1
	db 1, LAPRAS, BLIZZARD, $FD
	db $FE
	
	db BRUNO, 1
	db 0, ONIX, FISSURE, $FD
	db $FE
	
	db AGATHA, 1
	db 2, GENGAR, TOXIC, $FD
	db $FE
	
	db LANCE, 1
	db 1, DRAGONITE, BARRIER, $FD
	db $FE
	
	db SONY3, 0
	db 1, VENUSAUR, MEGA_DRAIN, $FD
	db 1, BLASTOISE, BLIZZARD, $FD
	db 1, CHARIZARD, FIRE_BLAST, $FD
	db $FE
	
	db $FF
	
	
	
TrainerCustomMoves:	
	ld hl, SpecialTrainerMoves_ALT
.load_class
	ld a, [hl]
	cp $FF
	jr z, .return
	ld a, [wTrainerClass]
	cp [hl]	;compare to list trainer class
	jr nz, .loop
	call TrainerCustomMoves_TrainerNum
.loop
	ld a, [hli]
	cp $FE
	jr nz, .loop
	jr .load_class
.return
	ret
	
	
TrainerCustomMoves_TrainerNum:
	inc hl	;point to list trainer number
.load_num
	ld a, [hl]
	and a
	jr z, .next	;an instance of zero treated as 'any'
	ld a, [wTrainerNo]
	cp [hl]
	ret nz
.next
	call TrainerCustomMoves_Mon
	ret

	
TrainerCustomMoves_Mon:
	inc hl	;point to instance of species

.load_instance
	ld a, [hl]
	cp $FE
	ret z
	ld a, [hli]
	ld b, a
	ld d, h
	ld e, l
	inc hl
	;note - hl now points to first desired move
	;note - de now points to desired species
	;note - b now tracks the species instance
	push hl

	ld a, [wEnemyPartyCount]
	ld c, a
	ld hl, wEnemyMon1Species
	;note - c now tracks the party position

.loop
	ld a, [de]
	cp [hl]
	call z, TrainerCustomMoves_Mon_Found
	dec c
	jr z, .end_party_search
.party_search
	push bc
	ld bc, wEnemyMon2Species - wEnemyMon1Species
	add hl, bc
	pop bc
	;HL now points to wEnemyMonXSpecies
	jr .loop

.end_party_search
	pop hl	;note - hl now points to first desired move
	
.end_party_search_loop
	ld a, [hli]
	cp $FD
	jr nz, .end_party_search_loop
	
	jr .load_instance


TrainerCustomMoves_Mon_Found:
;DE points to desired species
;HL points to wEnemyMonXSpecies
;B  tracks species instance
;C  tracks party position - do not clobber
	ld a, b
	and a
	jr z, .mon_load_moves	;if 0-value instance, start loading moves for the mon regardless of real instance
	dec b
	ret nz	;return if not the correct instance
	;if correct instance, start loading moves for the mon
	; also set B to a dummy value > PARTY_LENGTH
	dec b	;make B = FF as a dummy value
	
.mon_load_moves
	push de
	push hl
	ld a, d
	ld d, h
	ld h, a
	ld a, e
	ld e, l
	ld l, a
	inc hl
	;de points to the proper wEnemyMonXSpecies
	;hl points to first desired move
.mon_load_moves_loop
	ld a, [hli]
	cp $FD
	jr z, .done
	;note - A holds the move we want to slot into the pokemon
	call TrainerCustomMoves_AddMove
	jr .mon_load_moves_loop
.done
	pop hl
	pop de
	ret

	
TrainerCustomMoves_AddMove:	
;DE points to wEnemyMonXSpecies
;HL points to the desired move + 1
;B  tracks species instance - do not clobber
;C  tracks party position - do not clobber
;A  equals the desired move
	push bc
	push hl	

	ld h, d
	ld l, e
	ld bc, wEnemyMon1Moves - wEnemyMon1Species
	add hl, bc

	;hl now points to wEnemyMonXMoves
	push hl	

	ld b, a
	ld c, NUM_MOVES
.loop
	ld a, [hl]
	cp b
	jr z, .return	;return if the move is already known
	and a
	jr z, .copy_move	;add the move if a slot is open
	inc hl
	dec c
	jr nz, .loop

	;loop for shifting move list
	ld c, NUM_MOVES-1
	pop hl
	push hl
.loop2
	inc hl
	ld a, [hld]
	ld [hli], a
	dec c
	jr nz, .loop2

.copy_move
	ld a, b
	ld [hl], a
.return
	pop hl
	pop hl
	pop bc
	ret
