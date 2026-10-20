; Breeding, as in Gen 6 on (design brief): every 256 steps the day care's two
; mons may make an egg, if they're compatible; the man keeps it until the
; player takes it. An egg in the party hatches after its species' egg cycles
; of 256 steps (twice as fast with a Flame Body mon in the party), at level 1.
;
; An egg is EGG in a party's or box's species list. Its data is a mon's: its
; real species, 0 HP (so it never battles), level 1, its egg cycles left where
; the held item goes, and "EGG" for a nickname.

; a day-care block (sDayCareMonName on): the nickname, the OT name, the mon
DC_OT  EQU NAME_LENGTH
DC_MON EQU 2 * NAME_LENGTH
; the box struct (box_struct in wram.asm)
BOX_SPECIES EQU $00
BOX_LEVEL   EQU $03
BOX_TYPE1   EQU $05
BOX_TYPE2   EQU $06
BOX_ITEM    EQU $07 ; an egg's cycles left
BOX_MOVES   EQU $08
BOX_OTID    EQU $0C
BOX_EXP     EQU $0E
BOX_IVS     EQU $17
BOX_PP      EQU $1B
ASSERT BOX_LEVEL == wPartyMon1BoxLevel - wPartyMon1
ASSERT BOX_TYPE1 == wPartyMon1Type1 - wPartyMon1
ASSERT BOX_ITEM == wPartyMon1CatchRate - wPartyMon1
ASSERT BOX_MOVES == wPartyMon1Moves - wPartyMon1
ASSERT BOX_OTID == wPartyMon1OTID - wPartyMon1
ASSERT BOX_EXP == wPartyMon1Exp - wPartyMon1
ASSERT BOX_IVS == wPartyMon1IVs - wPartyMon1
ASSERT BOX_PP == wPartyMon1PP - wPartyMon1

; once a step out of battle (ApplyOutOfBattlePoisonDamage): every 256 steps
; the day care may lay an egg and the party's eggs get a cycle closer to
; hatching -> carry if an egg is ready to hatch (DisplayEggHatchingText)
DayCareEggStep::
	ld hl, wEggStepCounter
	inc [hl]
	jr nz, .noCycle
	call DayCareMaybeLayEgg
	call EggCycle
.noCycle
	jp EggReadyToHatch

DayCareMaybeLayEgg:
	ld a, [wDayCareEggReady]
	and a
	ret nz ; one at a time
	call DayCareCompatibility
	and a
	ret z
	ld b, BREED_LOW * 256 / 100
	cp BREED_LOW
	jr z, .gotChance
	ld b, BREED_MEDIUM * 256 / 100
	cp BREED_MEDIUM
	jr z, .gotChance
	ld b, BREED_HIGH * 256 / 100
.gotChance
	call Random
	cp b
	ret nc
	jp DayCareMakeEgg

; the party's eggs lose a cycle (two with Flame Body)
EggCycle:
	callab PartyHasFlameBody
	ld a, 1
	jr nc, .gotCycles
	inc a
.gotCycles
	ld c, a
	ld hl, wPartySpecies
	ld de, wPartyMon1CatchRate
.loop
	ld a, [hli]
	cp $ff
	ret z
	cp EGG
	jr nz, .next
	ld a, [de]
	sub c
	jr nc, .gotLeft
	xor a
.gotLeft
	ld [de], a
.next
	push hl
	ld hl, wPartyMon2 - wPartyMon1
	add hl, de
	ld d, h
	ld e, l
	pop hl
	jr .loop

; carry and wWhichPokemon = the first party egg with no cycles left, if any
EggReadyToHatch::
	ld hl, wPartySpecies
	ld de, wPartyMon1CatchRate
	ld c, 0
.loop
	ld a, [hli]
	cp $ff
	ret z ; no carry
	cp EGG
	jr nz, .next
	ld a, [de]
	and a
	jr nz, .next
	ld a, c
	ld [wWhichPokemon], a
	scf
	ret
.next
	push hl
	ld hl, wPartyMon2 - wPartyMon1
	add hl, de
	ld d, h
	ld e, l
	pop hl
	inc c
	jr .loop

; -> a = the chance in 100 (BREED_*) of the day care's mons making an egg each
; cycle, and wBreedMother = the parent it would come from. Two can when one is
; a Ditto and the other isn't (nor of the no-eggs group), or when one is male
; and the other female and they share an egg group. Same species, different
; original trainers, is likeliest.
DayCareCompatibility::
	ld a, [wDayCareInUse]
	cp DAY_CARE_SLOTS
	jr c, .none
	call BreedLoadParents
	xor a
	call BreedGetInfo
	ld a, 1
	call BreedGetInfo
	ld a, [wBreedInfo + BREED_INFO_GROUP1]
	cp EGG_NONE
	jr z, .none
	ld b, a
	ld a, [wBreedInfo + BREED_INFO_LENGTH + BREED_INFO_GROUP1]
	cp EGG_NONE
	jr z, .none
	cp EGG_DITTO
	jr z, .secondIsDitto
	ld a, b
	cp EGG_DITTO
	jr z, .firstIsDitto
; a male and a female (the mother), with an egg group in common
	ld a, [wBreedInfo + BREED_INFO_LENGTH + BREED_INFO_GENDER]
	ld c, a
	and a
	jr z, .none
	ld a, [wBreedInfo + BREED_INFO_GENDER]
	and a
	jr z, .none
	cp c
	jr z, .none
	cp "♀"
	ld a, 0
	jr z, .gotMother
	inc a
.gotMother
	ld [wBreedMother], a
	call BreedShareEggGroup
	jr nc, .none
	ld a, [wBreedInfo + BREED_INFO_SPECIES]
	ld b, a
	ld a, [wBreedInfo + BREED_INFO_LENGTH + BREED_INFO_SPECIES]
	cp b
	jr nz, .differentSpecies
	call BreedSameOT
	ld a, BREED_HIGH
	ret nz
	ld a, BREED_MEDIUM
	ret
.secondIsDitto
	ld a, b
	cp EGG_DITTO
	jr z, .none ; two Dittos
	xor a ; the mother is the other
	jr .ditto
.firstIsDitto
	ld a, 1
.ditto
	ld [wBreedMother], a
.differentSpecies
	call BreedSameOT
	ld a, BREED_MEDIUM
	ret nz
	ld a, BREED_LOW
	ret
.none
	xor a ; BREED_NONE
	ret

; carry if the parents share an egg group
BreedShareEggGroup:
	ld hl, wBreedInfo + BREED_INFO_GROUP1
	ld a, [hli]
	ld d, a
	ld e, [hl]
	ld hl, wBreedInfo + BREED_INFO_LENGTH + BREED_INFO_GROUP1
	ld b, 2
.loop
	ld a, [hli]
	cp d
	jr z, .yes
	cp e
	jr z, .yes
	dec b
	jr nz, .loop
	and a
	ret
.yes
	scf
	ret

; z if the parents have the same original trainer (OT ID)
BreedSameOT:
	ld c, BOX_OTID
	xor a
	call BreedParentField
	ld d, h
	ld e, l
	ld a, 1
	call BreedParentField
	ld a, [de]
	cp [hl]
	ret nz
	inc de
	inc hl
	ld a, [de]
	cp [hl]
	ret

; the day care's two mons -> wBreedParents
BreedLoadParents:
	call OpenBox
	ld hl, sDayCareMonName
	ld de, wBreedParents
	ld bc, DAY_CARE_DATA_LENGTH * DAY_CARE_SLOTS
	call CopyData
	jp CloseBox

; a = a parent (0 or 1), c = a box struct offset (BOX_*) -> hl = that byte of
; the parent in wBreedParents; keeps bc and de
BreedParentField:
	push de
	ld hl, wBreedParents + DC_MON
	and a
	jr z, .gotParent
	ld de, DAY_CARE_DATA_LENGTH
	add hl, de
.gotParent
	ld e, c
	ld d, 0
	add hl, de
	pop de
	ret

; a = a parent (0 or 1), c = BREED_INFO_* -> hl = that byte of its wBreedInfo;
; keeps bc and de
BreedInfoField:
	ld hl, wBreedInfo
	and a
	jr z, .gotParent
	ld hl, wBreedInfo + BREED_INFO_LENGTH
.gotParent
	push de
	ld e, c
	ld d, 0
	add hl, de
	pop de
	ret

; a = a parent (0 or 1) -> its wBreedInfo
BreedGetInfo:
	ld [wBreedTemp], a
	ld c, BOX_SPECIES
	call BreedParentField
	ld b, [hl]
	ld a, [wBreedTemp]
	ld c, BREED_INFO_SPECIES
	call BreedInfoField
	ld [hl], b
	inc hl
	ld a, b
	call SpeciesToDex
	ld [hli], a ; BREED_INFO_DEX
	push hl
	dec a
	ld l, a
	ld h, 0
	add hl, hl ; (up to 302)
	ld de, EggGroups
	add hl, de
	ld a, [hli]
	ld d, [hl]
	pop hl
	ld [hli], a ; BREED_INFO_GROUP1
	ld [hl], d ; BREED_INFO_GROUP2
	inc hl
	push hl
	ld a, [wBreedTemp]
	ld c, BOX_IVS
	call BreedParentField
	ld a, [hli]
	inc hl
	xor [hl] ; the gender byte: the first and third IV bytes xored
	ld e, a
	ld d, b
	callba DetermineMonGender ; d = "♂", "♀" or 0
	pop hl
	ld [hl], d ; BREED_INFO_GENDER
	ret

; a = a species -> a = its Pokédex number; keeps bc, de and hl
SpeciesToDex:
	push hl
	push de
	push bc
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	pop bc
	pop de
	pop hl
	ret

; the egg from the day care's mons (DayCareCompatibility has looked at them)
; -> sDayCareEgg, and wDayCareEggReady set
DayCareMakeEgg::
; its species: the first of the mother's line (a Nidoran either one)
	ld a, [wBreedMother]
	ld c, BREED_INFO_DEX
	call BreedInfoField
	ld a, [hl]
	dec a
	ld e, a
	ld d, 0
	ld hl, BaseForms
	add hl, de
	ld a, [hl]
	cp NIDORAN_F
	jr z, .nidoran
	cp NIDORAN_M
	jr nz, .gotSpecies
.nidoran
	call Random
	rrca
	ld a, NIDORAN_F
	jr c, .gotSpecies
	ld a, NIDORAN_M
.gotSpecies
	ld [wBreedTemp + 1], a
	ld [wd0b5], a
	call GetMonHeader
	ld hl, wBreedEgg
	ld bc, DAY_CARE_DATA_LENGTH
	xor a
	call FillMemory
	ld hl, EggName
	ld de, wBreedEgg
	ld bc, EggNameEnd - EggName
	call CopyData
	ld hl, wPlayerName
	ld de, wBreedEgg + DC_OT
	ld bc, NAME_LENGTH
	call CopyData
	ld a, [wBreedTemp + 1]
	ld [wBreedEgg + DC_MON + BOX_SPECIES], a
	ld a, 1
	ld [wBreedEgg + DC_MON + BOX_LEVEL], a
	ld a, [wMonHType1]
	ld [wBreedEgg + DC_MON + BOX_TYPE1], a
	ld a, [wMonHType2]
	ld [wBreedEgg + DC_MON + BOX_TYPE2], a
	ld a, [wBreedTemp + 1]
	call SpeciesToDex
	dec a
	ld e, a
	ld d, 0
	ld hl, EggCycles
	add hl, de
	ld a, [hl]
	ld [wBreedEgg + DC_MON + BOX_ITEM], a
	ld a, [wPlayerID]
	ld [wBreedEgg + DC_MON + BOX_OTID], a
	ld a, [wPlayerID + 1]
	ld [wBreedEgg + DC_MON + BOX_OTID + 1], a
	ld d, 1
	callab CalcExperience ; level 1's
	ld a, [hExperience]
	ld [wBreedEgg + DC_MON + BOX_EXP], a
	ld a, [hExperience + 1]
	ld [wBreedEgg + DC_MON + BOX_EXP + 1], a
	ld a, [hExperience + 2]
	ld [wBreedEgg + DC_MON + BOX_EXP + 2], a
	call BreedEggMoves
	call BreedEggPP
	call BreedEggIVs
	call OpenBox
	ld hl, wBreedEgg
	ld de, sDayCareEggName
	ld bc, DAY_CARE_DATA_LENGTH
	call CopyData
	call CloseBox
	ld a, 1
	ld [wDayCareEggReady], a
	ret

EggName:
	db "EGG@"
EggNameEnd:

; the egg's moves, as from Gen 6 (each new one pushing out the oldest if it
; knows four): its level 1 moves, then the moves of its learnset both parents
; know, then its egg moves either parent knows
BreedEggMoves:
	ld hl, wMonHMoves ; its starting moves first
	ld b, NUM_MOVES
.starting
	ld a, [hli]
	push hl
	push bc
	call BreedAddMove
	pop bc
	pop hl
	dec b
	jr nz, .starting
	call BreedLoadLearnset
.levelOne
	ld a, [hli]
	and a
	jr z, .learnset
	cp 2
	ld a, [hli]
	jr nc, .levelOne
	push hl
	call BreedAddMove
	pop hl
	jr .levelOne
.learnset
	call BreedLearnsetStart
.bothKnow
	ld a, [hli]
	and a
	jr z, .eggMoves
	ld a, [hli]
	push hl
	ld e, a
	xor a
	call BreedParentKnows
	jr nz, .notBoth
	ld a, 1
	call BreedParentKnows
	jr nz, .notBoth
	ld a, e
	call BreedAddMove
.notBoth
	pop hl
	jr .bothKnow
.eggMoves
	ld a, [wBreedTemp + 1]
	call SpeciesToDex
	dec a
	ld l, a
	ld h, 0
	add hl, hl ; (up to 302)
	ld de, EggMovePointers
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
.eggMove
	ld a, [hli]
	and a
	ret z
	push hl
	ld e, a
	xor a
	call BreedParentKnows
	jr z, .add
	ld a, 1
	call BreedParentKnows
	jr nz, .skip
.add
	ld a, e
	call BreedAddMove
.skip
	pop hl
	jr .eggMove

; a = a move -> into the egg's moves (if new), pushing out the oldest if it
; knows four
BreedAddMove:
	and a
	ret z
	ld c, a
	ld hl, wBreedEgg + DC_MON + BOX_MOVES
	ld b, NUM_MOVES
.find
	ld a, [hl]
	cp c
	ret z ; known already
	and a
	jr z, .put
	inc hl
	dec b
	jr nz, .find
	ld hl, wBreedEgg + DC_MON + BOX_MOVES + 1
	ld de, wBreedEgg + DC_MON + BOX_MOVES
	ld b, NUM_MOVES - 1
.shift
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .shift
	dec hl
.put
	ld [hl], c
	ret

; a = a parent (0 or 1), e = a move -> z if the parent knows it; keeps de and hl
BreedParentKnows:
	push hl
	push bc
	ld c, BOX_MOVES
	call BreedParentField
	ld b, NUM_MOVES
.loop
	ld a, [hli]
	cp e
	jr z, .done
	dec b
	jr nz, .loop
	inc b ; nz
.done
	pop bc
	pop hl
	ret

; the egg's species' evolutions and learnset -> wMovesLearnset, and hl = the
; learnset's first entry
BreedLoadLearnset:
	ld a, [wBreedTemp + 1]
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld bc, EvosMovesPointerTable
	add hl, bc
	ld de, wMovesLearnset
	ld bc, 2
	ld a, BANK(EvosMovesPointerTable)
	call FarCopyData
	ld hl, wMovesLearnset
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wMovesLearnset
	ld bc, MOVES_LEARNSET_LENGTH
	ld a, BANK(EvosMovesPointerTable)
	call FarCopyData
BreedLearnsetStart:
	ld hl, wMovesLearnset
.skipEvolutions
	ld a, [hli]
	and a
	jr nz, .skipEvolutions
	ret

; each of the egg's moves' full PP
BreedEggPP:
	ld hl, wBreedEgg + DC_MON + BOX_MOVES
	ld de, wBreedEgg + DC_MON + BOX_PP
	ld b, NUM_MOVES
.loop
	ld a, [hli]
	and a
	jr z, .next
	push hl
	push de
	push bc
	dec a
	ld hl, Moves + 5 ; PP
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld de, wBreedTemp
	ld bc, 1
	ld a, BANK(Moves)
	call FarCopyData
	pop bc
	pop de
	pop hl
	ld a, [wBreedTemp]
	ld [de], a
.next
	inc de
	dec b
	jr nz, .loop
	ret

; the egg's IVs, as from Gen 6: three, at random, from one parent or the other,
; the rest at random; the mother's ability slot 80% of the time, else the other;
; and a parent's nature if it holds an Everstone
BreedEggIVs:
	xor a
	ld c, BOX_IVS
	call BreedParentField
	ld d, h
	ld e, l
	callab UnpackIVsAtDE
	ld hl, wIVScratch
	ld de, wBreedParentIVs
	ld bc, NUM_STATS
	call CopyData
	ld a, 1
	ld c, BOX_IVS
	call BreedParentField
	ld d, h
	ld e, l
	callab UnpackIVsAtDE
	ld hl, wIVScratch
	ld de, wBreedParentIVs + NUM_STATS
	ld bc, NUM_STATS
	call CopyData
	ld hl, wIVScratch
	ld b, NUM_STATS
.random
	call Random
	and %11111
	ld [hli], a
	dec b
	jr nz, .random
	xor a
	ld [wBreedInherited], a
	ld b, EGG_INHERITED_IVS
.inherit
	call Random
	and %111
	cp NUM_STATS
	jr nc, .inherit
	ld c, a ; a stat not yet inherited
	ld e, 1
	and a
	jr z, .gotBit
.bit
	sla e
	dec a
	jr nz, .bit
.gotBit
	ld a, [wBreedInherited]
	and e
	jr nz, .inherit
	ld a, [wBreedInherited]
	or e
	ld [wBreedInherited], a
	call Random
	rrca
	ld hl, wBreedParentIVs
	jr nc, .gotParent
	ld hl, wBreedParentIVs + NUM_STATS
.gotParent
	ld e, c
	ld d, 0
	add hl, de
	ld a, [hl]
	ld hl, wIVScratch
	add hl, de
	ld [hl], a
	dec b
	jr nz, .inherit
; the ability slot
	ld a, [wBreedMother]
	ld c, BOX_IVS + IV_FLAGS
	call BreedParentField
	ld a, [hl]
	and 1
	ld b, a
	call Random
	cp EGG_ABILITY_KEPT
	ld a, b
	jr c, .gotSlot
	xor 1
.gotSlot
	ld [wBreedEgg + DC_MON + BOX_IVS + IV_FLAGS], a
	ld de, wBreedEgg + DC_MON + BOX_IVS
	callab PackIVsKeepFlags
; an Everstone's nature
	ld a, $ff
	ld [wBreedNature], a
	xor a
	call .everstone
	ld a, 1
	call .everstone
	ld a, [wBreedNature]
	cp $ff
	ret z
; it comes from the last IV not inherited: any nature can (25 of its 32 values)
	ld a, [wBreedInherited]
	ld c, NUM_STATS - 1
	ld b, 1 << (NUM_STATS - 1)
.findFree
	ld e, a
	and b
	jr z, .gotFree
	ld a, e
	srl b
	dec c
	jr .findFree
.gotFree
	ld a, c
	ld [wBreedTemp], a ; the stat
	call Random
	and %11111
	ld [wBreedTemp + 1], a ; the value tried
	ld a, 32
	ld [wBreedInherited], a ; tries left (done with it)
.try
	ld a, [wBreedTemp]
	ld e, a
	ld d, 0
	ld hl, wIVScratch
	add hl, de
	ld a, [wBreedTemp + 1]
	ld [hl], a
	ld de, wBreedEgg + DC_MON + BOX_IVS
	callab PackIVsKeepFlags
	ld de, wBreedEgg + DC_MON + BOX_IVS
	callab GetNatureFromIVsAtDE
	ld a, [wBreedNature]
	ld b, a
	ld a, [wCalcStatNature]
	cp b
	ret z
	ld a, [wBreedTemp + 1]
	inc a
	and %11111
	ld [wBreedTemp + 1], a
	ld hl, wBreedInherited
	dec [hl]
	jr nz, .try
	ret

; a = a parent -> wBreedNature = its nature, if it holds an Everstone (one of
; the two at random if both do)
.everstone
	push af
	ld c, BOX_ITEM
	call BreedParentField
	ld a, [hl]
	cp EVERSTONE
	jr nz, .noEverstone
	ld a, [wBreedNature]
	cp $ff
	jr z, .takeNature
	call Random
	rrca
	jr c, .noEverstone
.takeNature
	pop af
	ld c, BOX_IVS
	call BreedParentField
	ld d, h
	ld e, l
	callab GetNatureFromIVsAtDE
	ld a, [wCalcStatNature]
	ld [wBreedNature], a
	ret
.noEverstone
	pop af
	ret

; the day care's egg -> the end of the party (which has room)
GiveDayCareEgg::
	ld hl, wPartyCount
	ld a, [hl]
	ld [wWhichPokemon], a
	inc [hl]
	ld c, a
	ld b, 0
	inc hl
	add hl, bc
	ld a, EGG
	ld [hli], a
	ld [hl], $ff
	ld hl, wTempFieldMoveSlots
	add hl, bc
	ld [hl], 0
	ld a, [wWhichPokemon]
	ld hl, wPartyMons
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	push hl
	ld d, h
	ld e, l
	call OpenBox
	ld hl, sDayCareEgg
	ld bc, wPartyMon1Level - wPartyMon1
	call CopyData
	ld a, [wWhichPokemon]
	ld hl, wPartyMonOT
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, sDayCareEggOT
	ld bc, NAME_LENGTH
	call CopyData
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call SkipFixedLengthTextEntries
	ld d, h
	ld e, l
	ld hl, sDayCareEggName
	ld bc, NAME_LENGTH
	call CopyData
	call CloseBox
	pop hl
	call EggSetStats
	xor a
	ld [wDayCareEggReady], a
	ret

; hl = a party mon -> its level 1 stats (its HP isn't touched)
EggSetStats:
	ld a, [hl]
	ld [wd0b5], a
	push hl
	call GetMonHeader
	pop hl
	push hl
	ld bc, wPartyMon1Level - wPartyMon1
	add hl, bc
	ld a, 1
	ld [hli], a
	ld [wCurEnemyLVL], a
	ld d, h
	ld e, l ; its stats
	pop hl
	push hl
	ld bc, wPartyMon1EVs - wPartyMon1
	add hl, bc
	ld b, 1
	call CalcStats
	pop hl
	ret

; carry if a party mon other than [wWhichPokemon] isn't an egg (so one can
; still battle after it leaves)
PartyHasOtherBattler::
	ld a, [wWhichPokemon]
	ld c, a
	ld hl, wPartySpecies
.loop
	ld a, [hli]
	cp $ff
	ret z ; no carry
	cp EGG
	jr z, .next
	ld a, c
	and a
	scf
	ret nz
.next
	dec c
	jr .loop

; DisplayTextID's TEXT_EGG_HATCHING: each party egg with no cycles left hatches
HatchEggs::
	call EggReadyToHatch
	ret nc
	call HatchEgg
	jr HatchEggs

; party egg [wWhichPokemon] hatches: level 1, full HP, its species seen and
; owned; the player can name it
HatchEgg:
	ld hl, EggHatchingText
	call PrintText
	ld a, [wWhichPokemon]
	ld hl, wPartyMons
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hl]
	ld [wcf91], a
	push hl
	ld a, [wWhichPokemon]
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [wcf91]
	ld [hl], a
	pop hl
	push hl
	ld bc, wPartyMon1CatchRate - wPartyMon1
	add hl, bc
	ld [hl], 0 ; no item
	pop hl
	call EggSetStats
	push hl
	ld bc, wPartyMon1MaxHP - wPartyMon1
	add hl, bc
	ld a, [hli]
	ld c, [hl]
	pop hl
	inc hl
	ld [hli], a
	ld [hl], c ; full HP
	ld a, [wcf91]
	call SpeciesToDex
	dec a
	push af
	ld c, a
	ld b, FLAG_SET
	ld hl, wPokedexOwned
	predef FlagActionPredef
	pop af
	ld c, a
	ld b, FLAG_SET
	ld hl, wPokedexSeen
	predef FlagActionPredef
; the scene: the new mon's picture and cry
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	ld a, [wcf91]
	ld [wd0b5], a
	ld [wBattleMonSpecies2], a
	ld [wWholeScreenPaletteMonSpecies], a
	ld b, SET_PAL_POKEMON_WHOLE_SCREEN
	ld c, 0
	call RunPaletteCommand
	call GetMonHeader
	coord hl, 6, 3
	call LoadFrontSpriteByMonIndex
	call GBPalNormal
	ld a, [wcf91]
	call PlayCry
	ld a, [wcf91]
	ld [wd11e], a
	call GetMonName
	ld hl, EggHatchedText
	call PrintText
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call SkipFixedLengthTextEntries
	predef AskName
; back to the map
	call GBPalWhiteOutWithDelay3
	call ReloadMapData
	call RunDefaultPaletteCommand
	jp GBPalNormal

EggHatchingText:
	text "Oh?"
	prompt

EggHatchedText:
	TX_RAM wcd6d
	text " hatched"
	line "from the EGG!"
	prompt

; StatusScreen for an egg: "EGG" and its summary
EggStatusScreen::
	call GBPalWhiteOutWithDelay3
	call ClearScreen
	call UpdateSprites
	coord hl, 0, 0
	lb bc, 1, 18
	call TextBoxBorder
	coord hl, 1, 1
	ld de, EggName
	call PlaceString
	call GBPalNormal
	ld a, [wLoadedMonCatchRate]
	call EggSummaryText
	call PrintText
	ld a, EGG
	ld [wcf91], a ; for StatusScreen2
	ret

; a = an egg's cycles left -> hl = what its summary says
EggSummaryText::
	ld hl, EggSoonText
	cp 6
	ret c
	ld hl, EggCloseText
	cp 11
	ret c
	ld hl, EggNotCloseText
	cp 41
	ret c
	ld hl, EggLongTimeText
	ret

EggSoonText:
	text "Sounds can be"
	line "heard coming from"
	cont "inside! It will"
	cont "hatch soon!"
	prompt

EggCloseText:
	text "It moves around"
	line "inside sometimes."
	cont "It must be close"
	cont "to hatching."
	prompt

EggNotCloseText:
	text "What will hatch"
	line "from this? It"
	cont "doesn't seem close"
	cont "to hatching."
	prompt

EggLongTimeText:
	text "It looks as if"
	line "this EGG will take"
	cont "a long time to"
	cont "hatch."
	prompt

INCLUDE "data/breeding.asm"
