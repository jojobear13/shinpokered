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
	call CheckForBumpingSameMove_Alt	;joenote - extra functionality
	jr nz, .alreadyKnowsCheckLoop_end
	ld c, NUM_MOVES
.alreadyKnowsCheckLoop
	ld a, [de]
	inc de
	cp [hl]
	jr z, .nextMove
	dec c
	jr nz, .alreadyKnowsCheckLoop
.alreadyKnowsCheckLoop_end

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

;joenote - This function makes it so that if a move is in the first slot you can bump it out with itself in a learn list 
CheckForBumpingSameMove_Alt:
;DE points to first move slot on the pokemon
;HL points to move on the learn list
;return with z flag set if the move on the learn list is to be ignored
;return with z flag cleared if the learn list move is... 
;	- the same as the 1st move slot
;	- and all four move slots are full
;	- and the intent is to bump the move out of the 1st move slot and slide the same move into the 4th slot
	push de
	;increment to 4th move slot
	inc de
	inc de
	inc de
	;return if this slot is $00, since it means the slots are not all full
	ld a, [de]
	and a
	jr z, .return
	;else all the slots are full, so point back to the first slot
	pop de
	push de
	;see if the list move and the 1st slot move are the same
	ld a, [de]
	cp [hl]
	jr z, .clear_z_flag
	xor a
	jr .return
.clear_z_flag
	ld a, 1
	and a
.return
	pop de
	ret

	
EvosMovesPointerTable_Alt:
	dw RhydonEvosMoves_Alt
	dw KangaskhanEvosMoves_Alt
	dw Nidoran_mEvosMoves_Alt
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
	dw Nidoran_fEvosMoves_Alt
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
	dw Mr_mimeEvosMoves_Alt
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
    db 1, GROWL
    db 1, TACKLE
    db 7, LEECH_SEED
    db 13, VINE_WHIP
    db 20, POISONPOWDER
    db 27, SOLARBEAM
    db 34, GROWTH
    db 38, BODY_SLAM
    db 41, SLEEP_POWDER
    db 45, RAZOR_LEAF
    db 48, SWORDS_DANCE 
	db 0
	
IvysaurEvosMoves_Alt:
    db 1, GROWL
    db 1, TACKLE
    db 1, LEECH_SEED
    db 7, LEECH_SEED
    db 13, VINE_WHIP
    db 22, POISONPOWDER
    db 30, SOLARBEAM
    db 38, GROWTH
    db 42, BODY_SLAM
    db 46, SLEEP_POWDER
    db 50, RAZOR_LEAF
    db 54, SWORDS_DANCE 
	db 0
	
VenusaurEvosMoves_Alt:
    db 1, GROWL
    db 1, TACKLE
    db 1, LEECH_SEED
    db 1, VINE_WHIP
    db 7, LEECH_SEED
    db 13, VINE_WHIP
    db 22, POISONPOWDER
    db 30, SOLARBEAM
    db 43, GROWTH
    db 47, BODY_SLAM
    db 55, SLEEP_POWDER
    db 60, RAZOR_LEAF
    db 65, SWORDS_DANCE 
	db 0
	
CharmanderEvosMoves_Alt:
    db 1, GROWL
    db 1, SCRATCH
    db 9, EMBER
    db 15, LEER
    db 22, DIG
    db 30, SLASH
    db 38, FLAMETHROWER
    db 46, FIRE_SPIN
    db 48, SWORDS_DANCE
    db 50, BODY_SLAM
    db 52, FIRE_BLAST
    db 54, SLASH 
	db 0
	
CharmeleonEvosMoves_Alt:
    db 1, GROWL
    db 1, SCRATCH
    db 1, EMBER
    db 9, EMBER
    db 15, LEER
    db 24, DIG
    db 33, SLASH
    db 42, FLAMETHROWER
    db 56, FIRE_SPIN
    db 58, SWORDS_DANCE
    db 60, BODY_SLAM
    db 62, FIRE_BLAST
    db 64, SLASH 
	db 0
	
CharizardEvosMoves_Alt:
    db 1, GROWL
    db 1, SCRATCH
    db 1, EMBER
    db 1, LEER
    db 9, EMBER
    db 15, LEER
    db 24, DIG
    db 36, SLASH
    db 46, FLAMETHROWER
    db 55, FIRE_SPIN
    db 58, EARTHQUAKE
    db 60, BODY_SLAM
    db 63, FIRE_BLAST
    db 65, SLASH 
	db 0
	
SquirtleEvosMoves_Alt:
    db 1, TACKLE
    db 1, TAIL_WHIP
    db 8, WATER_GUN
    db 15, REFLECT
    db 22, BITE
    db 23, COUNTER
    db 25, SURF
    db 27, ICE_BEAM
    db 28, SEISMIC_TOSS
    db 35, BODY_SLAM
    db 42, HYDRO_PUMP
    db 50, BLIZZARD 
	db 0
	
WartortleEvosMoves_Alt:
    db 1, TACKLE
    db 1, TAIL_WHIP
    db 1, WATER_GUN
    db 8, WATER_GUN
    db 15, REFLECT
    db 24, BITE
    db 26, COUNTER
    db 28, SURF
    db 30, ICE_BEAM
    db 31, SEISMIC_TOSS
    db 39, BODY_SLAM
    db 47, HYDRO_PUMP
    db 56, BLIZZARD 
	db 0
	
BlastoiseEvosMoves_Alt:
    db 1, TACKLE
    db 1, TAIL_WHIP
    db 1, WATER_GUN
    db 1, REFLECT
    db 8, WATER_GUN
    db 15, REFLECT
    db 24, BITE
    db 26, COUNTER
    db 28, SURF
    db 30, ICE_BEAM
    db 31, SEISMIC_TOSS
    db 42, BODY_SLAM
    db 52, HYDRO_PUMP
    db 60, BLIZZARD 
	db 0
	
CaterpieEvosMoves_Alt:
    db 1, TACKLE
    db 1, STRING_SHOT 
	db 0
	
MetapodEvosMoves_Alt:
    db 1, HARDEN
    db 2, TACKLE 
	db 0
	
ButterfreeEvosMoves_Alt:
    db 1, CONFUSION
    db 12, CONFUSION
    db 15, POISONPOWDER
    db 16, STUN_SPORE
    db 17, SLEEP_POWDER
    db 19, MEGA_DRAIN
    db 21, SUPERSONIC
    db 26, SWIFT
    db 32, PSYCHIC_M
    db 35, STUN_SPORE
    db 37, SLEEP_POWDER
    db 40, SUPERSONIC 
	db 0
	
WeedleEvosMoves_Alt:
    db 1, POISON_STING
    db 1, STRING_SHOT 
	db 0
	
KakunaEvosMoves_Alt:
    db 1, HARDEN
    db 2, POISON_STING 
	db 0
	
BeedrillEvosMoves_Alt:
    db 1, FURY_ATTACK
    db 12, FURY_ATTACK
    db 16, FOCUS_ENERGY
    db 20, TWINEEDLE
    db 25, DOUBLE_EDGE
    db 30, PIN_MISSILE
    db 35, MEGA_DRAIN
    db 37, SUBSTITUTE
    db 40, TWINEEDLE
    db 43, DOUBLE_EDGE 
	db 0
	
PidgeyEvosMoves_Alt:
    db 1, GUST
    db 5, SAND_ATTACK
    db 12, QUICK_ATTACK
    db 19, SWIFT
    db 28, FLY
    db 32, SUBSTITUTE
    db 36, DOUBLE_EDGE
    db 44, QUICK_ATTACK 
	db 0
	
PidgeottoEvosMoves_Alt:
    db 1, GUST
    db 1, SAND_ATTACK
    db 5, SAND_ATTACK
    db 12, QUICK_ATTACK
    db 21, SWIFT
    db 31, FLY
    db 35, SUBSTITUTE
    db 40, DOUBLE_EDGE
    db 49, QUICK_ATTACK 
	db 0
	
PidgeotEvosMoves_Alt:
    db 1, GUST
    db 1, SAND_ATTACK
    db 1, QUICK_ATTACK
    db 5, SAND_ATTACK
    db 12, QUICK_ATTACK
    db 21, SWIFT
    db 31, FLY
    db 37, SUBSTITUTE
    db 44, DOUBLE_EDGE
    db 54, HYPER_BEAM 
	db 0
	
RattataEvosMoves_Alt:
    db 1, TACKLE
    db 1, TAIL_WHIP
    db 7, QUICK_ATTACK
    db 14, HYPER_FANG
    db 23, FOCUS_ENERGY
    db 28, BUBBLEBEAM
    db 34, SUPER_FANG
    db 38, BODY_SLAM
    db 42, DIG 
	db 0
	
RaticateEvosMoves_Alt:
    db 1, TACKLE
    db 1, TAIL_WHIP
    db 1, QUICK_ATTACK
    db 7, QUICK_ATTACK
    db 14, HYPER_FANG
    db 27, FOCUS_ENERGY
    db 34, BUBBLEBEAM
    db 41, SUPER_FANG
    db 45, BODY_SLAM
    db 50, DIG
    db 54, HYPER_BEAM
	db 0
	
SpearowEvosMoves_Alt:
    db 1, GROWL
    db 1, PECK
    db 9, LEER
    db 15, FURY_ATTACK
    db 22, SUBSTITUTE
    db 29, DRILL_PECK
    db 36, DOUBLE_EDGE
    db 40, DOUBLE_TEAM 
	db 0
	
FearowEvosMoves_Alt:
    db 1, GROWL
    db 1, PECK
    db 1, LEER
    db 9, LEER
    db 15, FURY_ATTACK
    db 25, SUBSTITUTE
    db 34, DRILL_PECK
    db 43, DOUBLE_EDGE
    db 48, HYPER_BEAM 
	db 0
	
EkansEvosMoves_Alt:
    db 1, WRAP
    db 1, LEER
    db 10, TOXIC
    db 17, BODY_SLAM
    db 24, GLARE
    db 31, ROCK_SLIDE
    db 38, EARTHQUAKE 
	db 0
	
ArbokEvosMoves_Alt:
    db 1, WRAP
    db 1, LEER
    db 1, TOXIC
    db 10, TOXIC
    db 17, BODY_SLAM
    db 27, GLARE
    db 36, ROCK_SLIDE
    db 47, EARTHQUAKE
    db 52, HYPER_BEAM
	db 0
	
PikachuEvosMoves_Alt:
    db 1, THUNDERSHOCK
    db 1, GROWL
    db 9, THUNDER_WAVE
    db 16, QUICK_ATTACK
    db 26, SWIFT
    db 33, AGILITY
    db 43, THUNDER 
	db 0
	
RaichuEvosMoves_Alt:
    db 5, THUNDERBOLT
    db 10, SEISMIC_TOSS
    db 15, THUNDER_WAVE
    db 20, SURF 
	db 0
	

SandshrewEvosMoves_Alt:
    db 1, SCRATCH
    db 10, SAND_ATTACK
    db 17, SLASH
    db 24, EARTHQUAKE
    db 31, BODY_SLAM
    db 38, SUBSTITUTE
	db 0
	
SandslashEvosMoves_Alt:
    db 1, SCRATCH
    db 1, SAND_ATTACK
    db 10, SAND_ATTACK
    db 17, SLASH
    db 27, EARTHQUAKE
    db 36, BODY_SLAM
    db 47, SUBSTITUTE 
	db 0
	
Nidoran_fEvosMoves_Alt:
    db 1, GROWL
    db 1, TACKLE
    db 8, SCRATCH
    db 14, POISON_STING
    db 21, TAIL_WHIP
    db 29, BITE
    db 36, FURY_SWIPES
    db 43, DOUBLE_KICK 
	db 0
	
NidorinaEvosMoves_Alt:
    db 1, GROWL
    db 1, TACKLE
    db 1, SCRATCH
    db 8, SCRATCH
    db 14, POISON_STING
    db 23, TAIL_WHIP
    db 32, BITE
    db 41, FURY_SWIPES
    db 50, DOUBLE_KICK 
	db 0
	
NidoqueenEvosMoves_Alt:
    db 1, TACKLE
    db 1, SCRATCH
    db 1, TAIL_WHIP
    db 1, BODY_SLAM
    db 8, THUNDERBOLT
    db 14, BLIZZARD
    db 23, BODY_SLAM
    db 30, EARTHQUAKE 
	db 0
	
Nidoran_mEvosMoves_Alt:
    db 1, LEER
    db 1, TACKLE
    db 8, HORN_ATTACK
    db 14, POISON_STING
    db 21, FOCUS_ENERGY
    db 29, FURY_ATTACK
    db 36, HORN_DRILL
    db 43, DOUBLE_KICK 
	db 0
	
NidorinoEvosMoves_Alt:
    db 1, LEER
    db 1, TACKLE
    db 1, HORN_ATTACK
    db 8, HORN_ATTACK
    db 14, POISON_STING
    db 23, FOCUS_ENERGY
    db 32, FURY_ATTACK
    db 41, HORN_DRILL
    db 50, DOUBLE_KICK 
	db 0
	
NidokingEvosMoves_Alt:
    db 1, TACKLE
    db 1, HORN_ATTACK
    db 1, POISON_STING
    db 1, THRASH
    db 8, BODY_SLAM
    db 14, THUNDERBOLT
    db 23, EARTHQUAKE
    db 30, BLIZZARD 
	db 0
	
ClefairyEvosMoves_Alt:
    db 1, POUND
    db 1, GROWL
    db 13, SING
    db 18, DOUBLESLAP
    db 24, MINIMIZE
    db 31, METRONOME
    db 39, DEFENSE_CURL
    db 48, LIGHT_SCREEN 
	db 0
	
ClefableEvosMoves_Alt:
    db 1, SING
    db 1, DOUBLESLAP
    db 1, MINIMIZE
    db 1, METRONOME
    db 10, THUNDER_WAVE
    db 20, BODY_SLAM
    db 30, THUNDERBOLT
    db 40, BLIZZARD 
	db 0
	
VulpixEvosMoves_Alt:
    db 1, EMBER
    db 1, TAIL_WHIP
    db 16, QUICK_ATTACK
    db 21, ROAR
    db 28, CONFUSE_RAY
    db 35, FLAMETHROWER
    db 42, FIRE_SPIN 
	db 0
	
NinetalesEvosMoves_Alt:
    db 1, EMBER
    db 1, TAIL_WHIP
    db 1, QUICK_ATTACK
    db 1, ROAR
    db 15, FIRE_BLAST
    db 25, CONFUSE_RAY
    db 35, BODY_SLAM
    db 45, TAIL_WHIP 
	db 0
	
JigglypuffEvosMoves_Alt:
    db 1, SING
    db 9, POUND
    db 14, DISABLE
    db 19, DEFENSE_CURL
    db 24, DOUBLESLAP
    db 29, REST
    db 34, BODY_SLAM
    db 39, DOUBLE_EDGE 
	db 0
	
WigglytuffEvosMoves_Alt:
    db 1, SING
    db 1, DISABLE
    db 1, DEFENSE_CURL
    db 1, DOUBLESLAP
    db 10, BODY_SLAM
    db 20, PSYCHIC_M
    db 30, THUNDER_WAVE
    db 40, COUNTER 
	db 0
	
ZubatEvosMoves_Alt:
    db 1, LEECH_LIFE
    db 10, SUPERSONIC
    db 15, BITE
    db 21, CONFUSE_RAY
    db 28, WING_ATTACK
    db 36, MEGA_DRAIN
    db 40, DOUBLE_EDGE 
	db 0
	
GolbatEvosMoves_Alt:
    db 1, LEECH_LIFE
    db 1, SCREECH
    db 1, BITE
    db 10, SUPERSONIC
    db 15, BITE
    db 21, CONFUSE_RAY
    db 32, WING_ATTACK
    db 43, MEGA_DRAIN
    db 48, DOUBLE_EDGE 
	db 0
	
OddishEvosMoves_Alt:
    db 1, ABSORB
    db 15, POISONPOWDER
    db 17, STUN_SPORE
    db 19, SLEEP_POWDER
    db 24, ACID
    db 33, PETAL_DANCE
    db 46, SOLARBEAM 
	db 0
	
GloomEvosMoves_Alt:
    db 1, ABSORB
    db 1, POISONPOWDER
    db 1, STUN_SPORE
    db 15, POISONPOWDER
    db 17, STUN_SPORE
    db 19, SLEEP_POWDER
    db 28, ACID
    db 38, PETAL_DANCE
    db 52, SOLARBEAM 
	db 0
	
VileplumeEvosMoves_Alt:
    db 1, STUN_SPORE
    db 1, SLEEP_POWDER
    db 1, ACID
    db 1, PETAL_DANCE
    db 15, POISONPOWDER
    db 17, STUN_SPORE
    db 19, SLEEP_POWDER
    db 25, MEGA_DRAIN
    db 35, BODY_SLAM 
	db 0
	
ParasEvosMoves_Alt:
    db 1, SCRATCH
    db 13, STUN_SPORE
    db 18, BODY_SLAM
    db 20, LEECH_LIFE
    db 27, SPORE
    db 30, MEGA_DRAIN
    db 34, SLASH
    db 41, GROWTH 
	db 0
	
ParasectEvosMoves_Alt:
    db 1, SCRATCH
    db 1, STUN_SPORE
    db 1, LEECH_LIFE
    db 13, STUN_SPORE
    db 18, BODY_SLAM
    db 20, LEECH_LIFE
    db 30, SPORE
    db 35, MEGA_DRAIN
    db 39, STUN_SPORE
    db 48, BODY_SLAM
	db 0
	
VenonatEvosMoves_Alt:
    db 1, TACKLE
    db 1, DISABLE
    db 20, PSYCHIC_M
    db 24, POISONPOWDER
    db 27, LEECH_LIFE
    db 30, STUN_SPORE
    db 35, PSYWAVE
    db 38, SLEEP_POWDER
    db 43, PSYCHIC_M 
	db 0
	
VenomothEvosMoves_Alt:
    db 1, TACKLE
    db 1, DISABLE
    db 1, POISONPOWDER
    db 1, LEECH_LIFE
    db 20, PSYCHIC_M
    db 24, POISONPOWDER
    db 27, LEECH_LIFE
    db 30, STUN_SPORE
    db 38, SUPERSONIC
    db 43, SLEEP_POWDER
    db 50, PSYCHIC_M 
	db 0
	
DiglettEvosMoves_Alt:
    db 1, SCRATCH
    db 15, GROWL
    db 19, DIG
    db 24, SAND_ATTACK
    db 31, SLASH
    db 40, EARTHQUAKE
    db 45, SUBSTITUTE 
	db 0
	
DugtrioEvosMoves_Alt:
    db 1, SCRATCH
    db 1, GROWL
    db 1, DIG
    db 15, GROWL
    db 19, DIG
    db 24, SAND_ATTACK
    db 35, SLASH
    db 47, EARTHQUAKE
    db 50, SUBSTITUTE 
	db 0
	
MeowthEvosMoves_Alt:
    db 1, SCRATCH
    db 1, GROWL
    db 12, BITE
    db 17, PAY_DAY
    db 24, SCREECH
    db 33, FURY_SWIPES
    db 37, THUNDERBOLT
    db 40, BUBBLEBEAM
    db 44, SLASH
    db 48, BODY_SLAM 
	db 0
	
PersianEvosMoves_Alt:
    db 1, SCRATCH
    db 1, GROWL
    db 1, BITE
    db 1, SCREECH
    db 12, BITE
    db 17, PAY_DAY
    db 24, SCREECH
    db 37, FURY_SWIPES
    db 42, THUNDERBOLT
    db 47, BUBBLEBEAM
    db 51, SLASH
    db 55, BODY_SLAM 
	db 0
	
PsyduckEvosMoves_Alt:
    db 1, SCRATCH
    db 9, WATER_GUN
    db 18, AMNESIA
    db 28, SKULL_BASH
    db 31, DISABLE
    db 33, BUBBLEBEAM
    db 36, CONFUSION
    db 40, AMNESIA
    db 43, REST
    db 48, BLIZZARD
    db 52, HYDRO_PUMP 
	db 0
	
GolduckEvosMoves_Alt:
    db 1, SCRATCH
    db 1, TAIL_WHIP
    db 1, DISABLE
    db 2, COUNTER
    db 9, WATER_GUN
    db 18, AMNESIA
    db 28, SKULL_BASH
    db 31, DISABLE
    db 35, BUBBLEBEAM
    db 39, CONFUSION
    db 44, AMNESIA
    db 48, REST
    db 54, BLIZZARD
    db 59, HYDRO_PUMP 
	db 0
	
MankeyEvosMoves_Alt:
    db 1, SCRATCH
    db 1, LEER
    db 15, KARATE_CHOP
    db 21, FURY_SWIPES
    db 27, FOCUS_ENERGY
    db 30, LOW_KICK
    db 33, BODY_SLAM
    db 36, ROCK_SLIDE
    db 39, THUNDER 
	db 0
	
PrimeapeEvosMoves_Alt:
    db 1, SCRATCH
    db 1, LEER
    db 1, KARATE_CHOP
    db 1, FURY_SWIPES
    db 15, KARATE_CHOP
    db 21, FURY_SWIPES
    db 27, FOCUS_ENERGY
    db 32, LOW_KICK
    db 37, BODY_SLAM
    db 42, ROCK_SLIDE
    db 46, HYPER_BEAM
	db 0
	
GrowlitheEvosMoves_Alt:
    db 1, BITE
    db 1, ROAR
    db 18, EMBER
    db 23, LEER
    db 30, TAKE_DOWN
    db 39, AGILITY
    db 50, FLAMETHROWER 
	db 0
	
ArcanineEvosMoves_Alt:
    db 1, ROAR
    db 1, EMBER
    db 1, LEER
    db 1, TAKE_DOWN
    db 10, BODY_SLAM
    db 20, FIRE_BLAST
    db 30, HYPER_BEAM
    db 40, SUBSTITUTE
	db 0
	
PoliwagEvosMoves_Alt:
    db 1, BUBBLE
    db 16, HYPNOSIS
    db 19, WATER_GUN
    db 25, DOUBLESLAP
    db 31, BODY_SLAM
    db 38, AMNESIA
    db 45, HYDRO_PUMP 
	db 0
	
PoliwhirlEvosMoves_Alt:
    db 1, BUBBLE
    db 1, HYPNOSIS
    db 1, WATER_GUN
    db 16, HYPNOSIS
    db 19, WATER_GUN
    db 26, DOUBLESLAP
    db 33, BODY_SLAM
    db 41, AMNESIA
    db 49, HYDRO_PUMP 
	db 0
	
PoliwrathEvosMoves_Alt:
    db 1, HYPNOSIS
    db 1, WATER_GUN
    db 1, DOUBLESLAP
    db 1, BODY_SLAM
    db 16, PSYWAVE
    db 19, SURF
    db 24, HYPNOSIS
    db 34, BLIZZARD
    db 44, AMNESIA 
	db 0
	
AbraEvosMoves_Alt:
    db 2, KINESIS
    db 2, COUNTER
    db 2, PSYWAVE
    db 10, METRONOME
    db 20, PSYCHIC_M 
	db 0
	
KadabraEvosMoves_Alt:
    db 1, TELEPORT
    db 1, CONFUSION
    db 1, DISABLE
    db 16, CONFUSION
    db 20, REFLECT
    db 27, PSYBEAM
    db 29, THUNDER_WAVE
    db 31, RECOVER
    db 38, PSYCHIC_M
    db 42, SEISMIC_TOSS 
	db 0
	
AlakazamEvosMoves_Alt:
    db 1, TELEPORT
    db 1, CONFUSION
    db 1, DISABLE
    db 16, CONFUSION
    db 20, REFLECT
    db 27, PSYBEAM
    db 29, THUNDER_WAVE
    db 31, RECOVER
    db 38, PSYCHIC_M
    db 42, SEISMIC_TOSS 
	db 0
	
MachopEvosMoves_Alt:
    db 1, KARATE_CHOP
    db 20, LOW_KICK
    db 25, LEER
    db 28, SEISMIC_TOSS
    db 32, FOCUS_ENERGY
    db 35, SUBMISSION
    db 39, BODY_SLAM
    db 42, ROCK_SLIDE
    db 46, EARTHQUAKE 
	db 0
	
MachokeEvosMoves_Alt:
    db 1, KARATE_CHOP
    db 1, LOW_KICK
    db 1, LEER
    db 20, LOW_KICK
    db 25, LEER
    db 30, SEISMIC_TOSS
    db 36, FOCUS_ENERGY
    db 40, SUBMISSION
    db 44, BODY_SLAM
    db 48, ROCK_SLIDE
    db 52, EARTHQUAKE 
	db 0
	
MachampEvosMoves_Alt:
    db 1, KARATE_CHOP
    db 1, LOW_KICK
    db 1, LEER
    db 20, LOW_KICK
    db 25, LEER
    db 30, SEISMIC_TOSS
    db 36, FOCUS_ENERGY
    db 40, SUBMISSION
    db 44, BODY_SLAM
    db 48, EARTHQUAKE
    db 52, HYPER_BEAM 
	db 0
	
BellsproutEvosMoves_Alt:
    db 1, VINE_WHIP
    db 1, GROWTH
    db 13, WRAP
    db 15, POISONPOWDER
    db 18, SLEEP_POWDER
    db 21, STUN_SPORE
    db 26, ACID
    db 33, RAZOR_LEAF
    db 42, SLAM 
	db 0
	
WeepinbellEvosMoves_Alt:
    db 1, VINE_WHIP
    db 1, GROWTH
    db 1, WRAP
    db 13, WRAP
    db 15, POISONPOWDER
    db 18, SLEEP_POWDER
    db 23, STUN_SPORE
    db 29, ACID
    db 38, RAZOR_LEAF
    db 49, SLAM 
	db 0
	
VictreebelEvosMoves_Alt:
    db 1, SLEEP_POWDER
    db 1, STUN_SPORE
    db 1, ACID
    db 1, RAZOR_LEAF
    db 13, WRAP
    db 15, POISONPOWDER
    db 18, SLEEP_POWDER
    db 23, MEGA_DRAIN
    db 28, BODY_SLAM
    db 33, STUN_SPORE
    db 38, RAZOR_LEAF
    db 43, SLEEP_POWDER 
	db 0
	
TentacoolEvosMoves_Alt:
    db 1, ACID
    db 7, SUPERSONIC
    db 13, WRAP
    db 18, POISON_STING
    db 22, WATER_GUN
    db 27, CONSTRICT
    db 30, REFLECT
    db 33, ACID
    db 36, SURF
    db 40, SWORDS_DANCE
    db 48, BLIZZARD 
	db 0
	
TentacruelEvosMoves_Alt:
    db 1, ACID
    db 1, SUPERSONIC
    db 1, WRAP
    db 7, SUPERSONIC
    db 13, WRAP
    db 18, POISON_STING
    db 22, WATER_GUN
    db 27, CONSTRICT
    db 31, REFLECT
    db 35, ACID
    db 39, SURF
    db 43, SWORDS_DANCE
    db 50, BLIZZARD 
	db 0
	
GeodudeEvosMoves_Alt:
    db 1, TACKLE
    db 11, DEFENSE_CURL
    db 16, ROCK_THROW
    db 21, SELFDESTRUCT
    db 26, BODY_SLAM
    db 31, EARTHQUAKE
    db 34, ROCK_SLIDE
    db 36, EXPLOSION 
	db 0
	
GravelerEvosMoves_Alt:
    db 1, TACKLE
    db 1, DEFENSE_CURL
    db 11, DEFENSE_CURL
    db 16, ROCK_THROW
    db 21, SELFDESTRUCT
    db 29, BODY_SLAM
    db 36, EARTHQUAKE
    db 40, ROCK_SLIDE
    db 43, EXPLOSION 
	db 0
	
GolemEvosMoves_Alt:
    db 1, TACKLE
    db 1, DEFENSE_CURL
    db 11, DEFENSE_CURL
    db 16, ROCK_THROW
    db 21, SELFDESTRUCT
    db 29, BODY_SLAM
    db 36, EARTHQUAKE
    db 40, ROCK_SLIDE
    db 43, EXPLOSION 
	db 0
	
PonytaEvosMoves_Alt:
    db 1, EMBER
    db 30, TAIL_WHIP
    db 32, STOMP
    db 35, GROWL
    db 39, FIRE_SPIN
    db 43, BODY_SLAM
    db 46, FIRE_BLAST
    db 48, AGILITY 
	db 0
	
RapidashEvosMoves_Alt:
    db 1, EMBER
    db 1, TAIL_WHIP
    db 1, STOMP
    db 1, GROWL
    db 30, TAIL_WHIP
    db 32, STOMP
    db 35, GROWL
    db 39, FIRE_SPIN
    db 43, HORN_DRILL
    db 47, BODY_SLAM
    db 51, FIRE_BLAST
    db 55, SUBSTITUTE 
	db 0
	
SlowpokeEvosMoves_Alt:
    db 1, CONFUSION
    db 9, WATER_GUN
    db 18, DISABLE
    db 22, HEADBUTT
    db 27, PSYCHIC_M
    db 33, THUNDER_WAVE
    db 36, REST
    db 40, AMNESIA
    db 48, SURF 
	db 0
	
SlowbroEvosMoves_Alt:
    db 1, CONFUSION
    db 1, DISABLE
    db 1, HEADBUTT
    db 9, WATER_GUN
    db 18, DISABLE
    db 22, HEADBUTT
    db 27, PSYCHIC_M
    db 33, THUNDER_WAVE
    db 37, REST
    db 44, AMNESIA
    db 55, SURF 
	db 0
	
MagnemiteEvosMoves_Alt:
    db 1, TACKLE
    db 7, FLASH
    db 14, SWIFT
    db 21, SONICBOOM
    db 25, THUNDERSHOCK
    db 29, SUPERSONIC
    db 35, THUNDERBOLT
    db 41, THUNDER_WAVE
    db 47, DOUBLE_TEAM 
	db 0
	
MagnetonEvosMoves_Alt:
    db 1, TACKLE
    db 1, SONICBOOM
    db 1, THUNDERSHOCK
    db 7, FLASH
    db 14, SWIFT
    db 21, SONICBOOM
    db 25, THUNDERSHOCK
    db 29, SUPERSONIC
    db 38, THUNDERBOLT
    db 46, THUNDER_WAVE
    db 54, DOUBLE_TEAM 
	db 0
	
FarfetchdEvosMoves_Alt:
    db 1, PECK
    db 1, SAND_ATTACK
    db 7, LEER
    db 15, FURY_ATTACK
    db 23, SWORDS_DANCE
    db 31, AGILITY
    db 35, FLY
    db 39, SLASH
    db 43, SUBSTITUTE 
	db 0
	
DoduoEvosMoves_Alt:
    db 1, PECK
    db 20, GROWL
    db 24, FURY_ATTACK
    db 27, TRI_ATTACK
    db 30, DRILL_PECK
    db 36, BODY_SLAM
    db 40, DOUBLE_EDGE
    db 44, AGILITY 
	db 0
	
DodrioEvosMoves_Alt:
    db 1, PECK
    db 1, GROWL
    db 1, FURY_ATTACK
    db 20, GROWL
    db 24, FURY_ATTACK
    db 27, TRI_ATTACK
    db 30, DRILL_PECK
    db 39, BODY_SLAM
    db 45, SUBSTITUTE
    db 51, HYPER_BEAM
	db 0
	
SeelEvosMoves_Alt:
    db 1, HEADBUTT
    db 8, WATER_GUN
    db 16, BIDE
    db 25, SKULL_BASH
    db 30, BUBBLEBEAM
    db 35, AURORA_BEAM
    db 37, GROWL
    db 40, REST
    db 45, BODY_SLAM
    db 50, ICE_BEAM 
	db 0
	
DewgongEvosMoves_Alt:
    db 1, HEADBUTT
    db 1, GROWL
    db 1, AURORA_BEAM
    db 15, WATER_GUN
    db 20, BIDE
    db 25, SKULL_BASH
    db 30, BUBBLEBEAM
    db 35, AURORA_BEAM
    db 40, GROWL
    db 44, REST
    db 50, BODY_SLAM
    db 56, ICE_BEAM 
	db 0
	
GrimerEvosMoves_Alt:
    db 1, POUND
    db 1, DISABLE
    db 30, POISON_GAS
    db 33, MINIMIZE
    db 37, SLUDGE
    db 40, BODY_SLAM
    db 42, EXPLOSION
    db 48, THUNDERBOLT
    db 55, FIRE_BLAST 
	db 0
	
MukEvosMoves_Alt:
    db 1, POUND
    db 1, DISABLE
    db 1, POISON_GAS
    db 30, POISON_GAS
    db 33, MINIMIZE
    db 37, SLUDGE
    db 40, BODY_SLAM
    db 45, EXPLOSION
    db 53, THUNDERBOLT
    db 60, FIRE_BLAST 
	db 0
	
ShellderEvosMoves_Alt:
    db 1, TACKLE
    db 1, WITHDRAW
    db 18, SUPERSONIC
    db 23, CLAMP
    db 30, AURORA_BEAM
    db 39, LEER
    db 50, ICE_BEAM 
	db 0
	
CloysterEvosMoves_Alt:
    db 1, WITHDRAW
    db 1, SUPERSONIC
    db 1, CLAMP
    db 1, AURORA_BEAM
    db 20, SURF
    db 30, BLIZZARD
    db 40, SUPERSONIC
    db 50, EXPLOSION 
	db 0
	
GastlyEvosMoves_Alt:
    db 1, LICK
    db 1, CONFUSE_RAY
    db 1, NIGHT_SHADE
    db 27, HYPNOSIS
    db 35, PSYCHIC_M
    db 40, EXPLOSION
    db 45, CONFUSE_RAY 
	db 0
	
HaunterEvosMoves_Alt:
    db 1, LICK
    db 1, CONFUSE_RAY
    db 1, NIGHT_SHADE
    db 29, HYPNOSIS
    db 38, PSYCHIC_M
    db 43, EXPLOSION
    db 48, CONFUSE_RAY 
	db 0
	
GengarEvosMoves_Alt:
    db 1, LICK
    db 1, CONFUSE_RAY
    db 1, NIGHT_SHADE
    db 29, HYPNOSIS
    db 38, PSYCHIC_M
    db 43, EXPLOSION
    db 48, CONFUSE_RAY 
	db 0
	
OnixEvosMoves_Alt:
    db 1, TACKLE
    db 1, SCREECH
    db 15, BIND
    db 19, ROCK_THROW
    db 25, BODY_SLAM
    db 33, EXPLOSION
    db 43, EARTHQUAKE
    db 48, ROCK_SLIDE 
	db 0
	
DrowzeeEvosMoves_Alt:
    db 1, POUND
    db 1, HYPNOSIS
    db 12, DISABLE
    db 17, CONFUSION
    db 24, HEADBUTT
    db 29, THUNDER_WAVE
    db 32, PSYCHIC_M
    db 35, HYPNOSIS
    db 37, SEISMIC_TOSS
	db 0
	
HypnoEvosMoves_Alt:
    db 1, POUND
    db 1, HYPNOSIS
    db 1, DISABLE
    db 1, CONFUSION
    db 12, DISABLE
    db 17, CONFUSION
    db 24, HEADBUTT
    db 33, THUNDER_WAVE
    db 37, PSYCHIC_M
    db 40, HYPNOSIS
    db 43, SEISMIC_TOSS
	db 0
	
KrabbyEvosMoves_Alt:
    db 1, BUBBLE
    db 1, LEER
    db 20, VICEGRIP
    db 25, GUILLOTINE
    db 30, STOMP
    db 35, CRABHAMMER
    db 40, BODY_SLAM 
	db 0
	
KinglerEvosMoves_Alt:
    db 1, BUBBLE
    db 1, LEER
    db 1, VICEGRIP
    db 20, VICEGRIP
    db 25, GUILLOTINE
    db 34, STOMP
    db 42, CRABHAMMER
    db 49, BODY_SLAM 
    db 52, SWORDS_DANCE
    db 55, HYPER_BEAM
	db 0
	
VoltorbEvosMoves_Alt:
    db 1, TACKLE
    db 1, SCREECH
    db 17, SONICBOOM
    db 22, SELFDESTRUCT
    db 29, THUNDER_WAVE
    db 36, TAKE_DOWN
    db 40, THUNDERBOLT
    db 43, EXPLOSION 
	db 0
	
ElectrodeEvosMoves_Alt:
    db 1, TACKLE
    db 1, SCREECH
    db 1, SONICBOOM
    db 17, SONICBOOM
    db 22, SELFDESTRUCT
    db 29, THUNDER_WAVE
    db 40, TAKE_DOWN
    db 45, THUNDERBOLT
    db 50, EXPLOSION 
	db 0
	
ExeggcuteEvosMoves_Alt:
    db 1, BARRAGE
    db 1, HYPNOSIS
    db 25, REFLECT
    db 28, LEECH_SEED
    db 32, STUN_SPORE
    db 37, POISONPOWDER
    db 42, SOLARBEAM
    db 48, SLEEP_POWDER 
	db 0
	
ExeggutorEvosMoves_Alt:
    db 1, BARRAGE
    db 1, HYPNOSIS
    db 28, STOMP
    db 30, STUN_SPORE
    db 35, PSYCHIC_M
    db 40, EXPLOSION
    db 50, SLEEP_POWDER 
	db 0
	
CuboneEvosMoves_Alt:
    db 1, BONE_CLUB
    db 1, GROWL
    db 25, LEER
    db 31, FOCUS_ENERGY
    db 34, BODY_SLAM
    db 38, FIRE_BLAST
    db 43, EARTHQUAKE
    db 46, BLIZZARD 
	db 0
	
MarowakEvosMoves_Alt:
    db 1, BONE_CLUB
    db 1, GROWL
    db 1, LEER
    db 1, FOCUS_ENERGY
    db 25, LEER
    db 33, FOCUS_ENERGY
    db 37, BODY_SLAM
    db 41, FIRE_BLAST
    db 48, EARTHQUAKE
    db 55, BLIZZARD 
	db 0
	
HitmonleeEvosMoves_Alt:
    db 1, DOUBLE_KICK
    db 1, MEDITATE
    db 33, MEGA_KICK
    db 38, JUMP_KICK
    db 40, FOCUS_ENERGY
    db 43, ROLLING_KICK
    db 48, HI_JUMP_KICK
    db 53, BODY_SLAM
    db 55, MEGA_KICK
	db 0
	
HitmonchanEvosMoves_Alt:
    db 1, COMET_PUNCH
    db 1, AGILITY
    db 33, MEGA_PUNCH
    db 38, ICE_PUNCH
    db 43, THUNDERPUNCH
    db 48, FIRE_PUNCH
    db 50, BODY_SLAM
    db 53, COUNTER
    db 55, SUBMISSION 
    db 58, MEGA_KICK
	db 0
	
LickitungEvosMoves_Alt:
    db 1, WRAP
    db 1, SUPERSONIC
    db 7, STOMP
    db 15, DISABLE
    db 23, DEFENSE_CURL
    db 27, MEGA_KICK
    db 31, BODY_SLAM
    db 39, SWORDS_DANCE
    db 45, EARTHQUAKE 
    db 50, HYPER_BEAM
	db 0
	
KoffingEvosMoves_Alt:
    db 1, TACKLE
    db 1, SMOG
    db 32, SLUDGE
    db 37, SMOKESCREEN
    db 39, SELFDESTRUCT
    db 40, THUNDERBOLT
    db 43, FIRE_BLAST
    db 45, SLUDGE
    db 48, EXPLOSION 
	db 0
	
WeezingEvosMoves_Alt:
    db 1, TACKLE
    db 1, SMOG
    db 1, SLUDGE
    db 32, SLUDGE
    db 39, SMOKESCREEN
    db 41, SELFDESTRUCT
    db 43, THUNDERBOLT
    db 46, FIRE_BLAST
    db 49, SLUDGE
    db 53, EXPLOSION 
	db 0
	
RhyhornEvosMoves_Alt:
    db 1, HORN_ATTACK
    db 30, STOMP
    db 35, TAIL_WHIP
    db 40, ROCK_SLIDE
    db 45, EARTHQUAKE
    db 50, BODY_SLAM
    db 55, SUBSTITUTE 
	db 0
	
RhydonEvosMoves_Alt:
    db 1, HORN_ATTACK
    db 1, STOMP
    db 1, TAIL_WHIP
    db 1, FURY_ATTACK
    db 30, STOMP
    db 35, TAIL_WHIP
    db 40, ROCK_SLIDE
    db 48, EARTHQUAKE
    db 55, BODY_SLAM
    db 64, SUBSTITUTE
	db 0
	
ChanseyEvosMoves_Alt:
    db 1, POUND
    db 1, DOUBLESLAP
    db 24, SING
    db 30, GROWL
    db 38, MINIMIZE
    db 41, SOFTBOILED
    db 44, THUNDER_WAVE
    db 48, ICE_BEAM
    db 54, THUNDERBOLT
	db 0
	
TangelaEvosMoves_Alt:
    db 1, CONSTRICT
    db 1, BIND
    db 20, BODY_SLAM
    db 29, ABSORB
    db 32, POISONPOWDER
    db 36, STUN_SPORE
    db 39, SLEEP_POWDER
    db 45, MEGA_DRAIN
    db 49, BODY_SLAM
	db 0
	
KangaskhanEvosMoves_Alt:
    db 1, COMET_PUNCH
    db 1, RAGE
    db 26, BITE
    db 31, COUNTER
    db 36, BODY_SLAM
    db 41, EARTHQUAKE
    db 46, HYPER_BEAM 
	db 0
	
HorseaEvosMoves_Alt:
    db 1, BUBBLE
    db 19, SMOKESCREEN
    db 24, LEER
    db 30, BUBBLEBEAM
    db 34, DOUBLE_TEAM
    db 37, SUBSTITUTE
    db 41, BLIZZARD
    db 45, HYDRO_PUMP 
	db 0
	
SeadraEvosMoves_Alt:
    db 1, BUBBLE
    db 1, SMOKESCREEN
    db 19, SMOKESCREEN
    db 24, LEER
    db 30, BUBBLEBEAM
    db 36, DOUBLE_TEAM
    db 41, SUBSTITUTE
    db 46, BLIZZARD
    db 52, HYDRO_PUMP 
	db 0
	
GoldeenEvosMoves_Alt:
    db 1, PECK
    db 1, TAIL_WHIP
    db 9, WATER_GUN
    db 19, SUPERSONIC
    db 24, HORN_ATTACK
    db 30, FURY_ATTACK
    db 37, SURF
    db 41, BLIZZARD
    db 45, HORN_DRILL
    db 54, AGILITY 
	db 0
	
SeakingEvosMoves_Alt:
    db 1, PECK
    db 1, TAIL_WHIP
    db 1, SUPERSONIC
    db 9, WATER_GUN
    db 19, SUPERSONIC
    db 24, HORN_ATTACK
    db 30, FURY_ATTACK
    db 39, SURF
    db 44, BLIZZARD
    db 48, HORN_DRILL
    db 54, AGILITY 
	db 0
	
StaryuEvosMoves_Alt:
    db 1, TACKLE
    db 17, WATER_GUN
    db 22, HARDEN
    db 27, RECOVER
    db 32, SWIFT
    db 37, MINIMIZE
    db 42, LIGHT_SCREEN
    db 47, HYDRO_PUMP 
	db 0
	
StarmieEvosMoves_Alt:
    db 1, TACKLE
    db 1, WATER_GUN
    db 1, HARDEN
    db 8, BUBBLEBEAM
    db 16, THUNDER_WAVE
    db 24, PSYCHIC_M
    db 32, RECOVER
    db 40, BLIZZARD 
	db 0
	
Mr_mimeEvosMoves_Alt:
    db 1, CONFUSION
    db 1, BARRIER
    db 15, CONFUSION
    db 23, LIGHT_SCREEN
    db 31, SEISMIC_TOSS
    db 39, PSYCHIC_M
    db 47, THUNDER_WAVE
    db 55, THUNDERBOLT 
	db 0
	
ScytherEvosMoves_Alt:
    db 1, QUICK_ATTACK
    db 17, LEER
    db 20, FOCUS_ENERGY
    db 24, DOUBLE_TEAM
    db 29, SLASH
    db 35, SWORDS_DANCE
    db 42, SUBSTITUTE
    db 50, WING_ATTACK 
	db 0
	
JynxEvosMoves_Alt:
    db 1, POUND
    db 1, LOVELY_KISS
    db 18, LICK
    db 23, DOUBLESLAP
    db 31, ICE_PUNCH
    db 35, PSYCHIC_M
    db 39, BODY_SLAM
    db 47, LOVELY_KISS
    db 52, BLIZZARD 
	db 0
	
ElectabuzzEvosMoves_Alt:
    db 1, QUICK_ATTACK
    db 1, LEER
    db 34, THUNDERSHOCK
    db 37, LIGHT_SCREEN
    db 42, THUNDERPUNCH
    db 45, BODY_SLAM
    db 49, THUNDER_WAVE
    db 51, THUNDERBOLT
    db 54, PSYCHIC_M 
	db 0
	
MagmarEvosMoves_Alt:
    db 1, EMBER
    db 36, LEER
    db 39, CONFUSE_RAY
    db 43, FIRE_PUNCH
    db 48, SEISMIC_TOSS
    db 52, BODY_SLAM
    db 55, FIRE_BLAST
    db 58, CONFUSE_RAY 
	db 0
	
PinsirEvosMoves_Alt:
    db 1, VICEGRIP
    db 25, SEISMIC_TOSS
    db 30, GUILLOTINE
    db 36, FOCUS_ENERGY
    db 43, SWORDS_DANCE
    db 46, BODY_SLAM
    db 49, SLASH
    db 52, SUBMISSION 
	db 0
	
TaurosEvosMoves_Alt:
    db 1, TACKLE
    db 21, STOMP
    db 28, BODY_SLAM
    db 35, EARTHQUAKE
    db 44, BLIZZARD
    db 51, HYPER_BEAM 
	db 0
	
MagikarpEvosMoves_Alt:
    db 1, SPLASH
    db 15, TACKLE 
	db 0
	
GyaradosEvosMoves_Alt:
    db 1, BITE
    db 1, DRAGON_RAGE
    db 1, LEER
    db 1, HYDRO_PUMP
    db 20, BITE
    db 25, DRAGON_RAGE
    db 32, LEER
    db 37, BODY_SLAM
    db 41, HYDRO_PUMP
    db 52, HYPER_BEAM 
	db 0
	
LaprasEvosMoves_Alt:
    db 1, WATER_GUN
    db 1, GROWL
    db 16, SING
    db 20, MIST
    db 25, ICE_BEAM
    db 31, CONFUSE_RAY
    db 35, THUNDERBOLT
    db 38, SING
    db 42, BLIZZARD
    db 46, HYPER_BEAM 
	db 0
	
DittoEvosMoves_Alt:
    db 1, TRANSFORM 
	db 0
	
EeveeEvosMoves_Alt:
    db 1, TACKLE
    db 1, SAND_ATTACK
    db 27, QUICK_ATTACK
    db 31, REFLECT
    db 37, BIDE
    db 45, BODY_SLAM 
	db 0
	
VaporeonEvosMoves_Alt:
    db 1, TACKLE
    db 1, SAND_ATTACK
    db 1, QUICK_ATTACK
    db 1, WATER_GUN
    db 27, QUICK_ATTACK
    db 31, WATER_GUN
    db 37, TAIL_WHIP
    db 40, BITE
    db 42, ACID_ARMOR
    db 44, SURF
    db 48, BODY_SLAM
    db 51, TAIL_WHIP
    db 54, BLIZZARD 
	db 0
	
JolteonEvosMoves_Alt:
    db 1, TACKLE
    db 1, SAND_ATTACK
    db 1, QUICK_ATTACK
    db 1, THUNDERSHOCK
    db 27, QUICK_ATTACK
    db 31, THUNDERSHOCK
    db 37, TAIL_WHIP
    db 40, BODY_SLAM
    db 42, DOUBLE_KICK
    db 44, THUNDERBOLT
    db 48, PIN_MISSILE
    db 54, THUNDER_WAVE 
	db 0
	
FlareonEvosMoves_Alt:
    db 1, TACKLE
    db 1, SAND_ATTACK
    db 1, QUICK_ATTACK
    db 1, EMBER
    db 27, QUICK_ATTACK
    db 31, EMBER
    db 37, TAIL_WHIP
    db 40, BITE
    db 42, BODY_SLAM
    db 44, FIRE_BLAST
    db 48, DIG
    db 54, HYPER_BEAM 
	db 0
	
PorygonEvosMoves_Alt:
    db 1, TACKLE
    db 1, SHARPEN
    db 1, CONVERSION
    db 23, PSYBEAM
    db 25, TRI_ATTACK
    db 28, RECOVER
    db 35, THUNDER_WAVE
    db 39, THUNDERBOLT
    db 42, BLIZZARD 
	db 0
	
OmanyteEvosMoves_Alt:
    db 1, WATER_GUN
    db 1, WITHDRAW
    db 34, BODY_SLAM
    db 39, SEISMIC_TOSS
    db 46, SURF
    db 53, BLIZZARD 
	db 0
	
OmastarEvosMoves_Alt:
    db 1, WATER_GUN
    db 1, WITHDRAW
    db 1, HORN_ATTACK
    db 34, BODY_SLAM
    db 39, SURF
    db 44, SEISMIC_TOSS
    db 49, BLIZZARD 
	db 0
	
KabutoEvosMoves_Alt:
    db 1, SCRATCH
    db 1, HARDEN
    db 34, ABSORB
    db 36, BODY_SLAM
    db 39, SLASH
    db 44, SWORDS_DANCE
    db 49, HYDRO_PUMP 
	db 0
	
KabutopsEvosMoves_Alt:
    db 1, SCRATCH
    db 1, HARDEN
    db 1, ABSORB
    db 34, ABSORB
    db 36, BODY_SLAM
    db 39, SLASH
    db 46, SWORDS_DANCE
    db 53, SURF
	db 0
	
AerodactylEvosMoves_Alt:
    db 1, WING_ATTACK
    db 1, AGILITY
    db 33, SUPERSONIC
    db 38, FLY
    db 45, DOUBLE_EDGE
    db 54, SUBSTITUTE
    db 60, HYPER_BEAM
	db 0
	
SnorlaxEvosMoves_Alt:
    db 1, HEADBUTT
    db 1, AMNESIA
    db 1, REST
    db 35, BODY_SLAM
    db 41, EARTHQUAKE
    db 48, REFLECT
	db 0
	
ArticunoEvosMoves_Alt:
    db 1, PECK
    db 1, ICE_BEAM
    db 51, BLIZZARD
    db 55, DOUBLE_EDGE
    db 60, SUBSTITUTE
    db 64, HYPER_BEAM
	db 0
	
ZapdosEvosMoves_Alt:
    db 1, THUNDERSHOCK
    db 1, DRILL_PECK
    db 51, THUNDERBOLT
    db 55, SUBSTITUTE
    db 60, THUNDER_WAVE 
	db 0
	
MoltresEvosMoves_Alt:
    db 1, PECK
    db 1, FIRE_SPIN
    db 51, SKY_ATTACK
    db 53, FIRE_BLAST
    db 55, SUBSTITUTE
    db 57, DOUBLE_EDGE
    db 60, HYPER_BEAM
	db 0
	
DratiniEvosMoves_Alt:
    db 1, WRAP
    db 1, LEER
    db 10, THUNDER_WAVE
    db 20, AGILITY
    db 25, DRAGON_RAGE
    db 30, THUNDERBOLT
    db 35, BODY_SLAM
    db 40, THUNDER_WAVE
    db 45, BLIZZARD
    db 50, HYPER_BEAM 
	db 0
	
DragonairEvosMoves_Alt:
    db 1, WRAP
    db 1, LEER
    db 1, THUNDER_WAVE
    db 10, THUNDER_WAVE
    db 20, AGILITY
    db 27, DRAGON_RAGE
    db 35, THUNDERBOLT
    db 40, BODY_SLAM
    db 45, THUNDER_WAVE
    db 52, BLIZZARD
    db 55, HYPER_BEAM 
	db 0
	
DragoniteEvosMoves_Alt:
    db 1, WRAP
    db 1, LEER
    db 1, THUNDER_WAVE
    db 1, AGILITY
    db 10, THUNDER_WAVE
    db 20, AGILITY
    db 27, DRAGON_RAGE
    db 35, THUNDERBOLT
    db 40, BODY_SLAM
    db 45, THUNDER_WAVE
    db 52, BLIZZARD
    db 60, HYPER_BEAM 
	db 0
	
MewtwoEvosMoves_Alt:
    db 1, CONFUSION
    db 1, DISABLE
    db 1, SWIFT
    db 1, PSYCHIC_M
    db 63, BARRIER
    db 66, PSYCHIC_M
    db 70, RECOVER
    db 75, ICE_BEAM
    db 81, AMNESIA
    db 85, PSYCHIC_M 
	db 0
	
MewEvosMoves_Alt:
    db 1, POUND
    db 10, TRANSFORM
    db 20, MEGA_PUNCH
    db 30, METRONOME
    db 40, PSYCHIC_M
    db 45, SOFTBOILED
    db 50, BODY_SLAM
    db 55, SWORDS_DANCE
    db 60, EARTHQUAKE 
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
	db 1, ONIX, FISSURE, ROCK_SLIDE, $FD
	db $FE
	
	db AGATHA, 1
	db 2, GENGAR, TOXIC, $FD
	db $FE
	
	db LANCE, 1
	db 1, DRAGONITE, HYPER_BEAM, $FD
	db $FE
	
	db SONY3, 0
	db 1, VENUSAUR, RAZOR_LEAF, $FD
	db 1, BLASTOISE, BLIZZARD, $FD
	db 1, CHARIZARD, FIRE_BLAST, $FD
	db $FE
	
	db CHIEF, 3
	db 1, MISSINGNO_B5, LEECH_SEED, TOXIC, SUPER_FANG, NIGHT_SHADE, $FD
	db 2, MISSINGNO_B5, EARTHQUAKE, HYPER_BEAM, CONFUSE_RAY, SPORE, $FD
	db 3, MISSINGNO_B5, PSYCHIC_M, BLIZZARD, THUNDER_WAVE, REST, $FD
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
