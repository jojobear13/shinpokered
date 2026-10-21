SECTION "Sprite Buffers", SRAM, BANK[0]

sSpriteBuffer0:: ds SPRITEBUFFERSIZE ; a000
sSpriteBuffer1:: ds SPRITEBUFFERSIZE ; a188
sSpriteBuffer2:: ds SPRITEBUFFERSIZE ; a310

	ds $100

sHallOfFame:: ds HOF_TEAM * HOF_TEAM_CAPACITY ; a598

; Live game data that used to be in WRAM (design brief, step D). Only
; accessed between OpenBox and CloseBox (home.asm). Saved by copying it to
; the bank 1 snapshot below, so a reset without saving loses changes to it,
; as it did when it was in WRAM.
sLiveDataStart::
sDayCareMonName:: ds NAME_LENGTH ; b858
sDayCareMonOT::   ds NAME_LENGTH ; b863
sDayCareMon:: box_struct sDayCareMon ; b86e
; the second day-care mon, in the same layout: the day care works on the
; first, swapping the two (SwapDayCareMons) to work on this one
sDayCareMon2Name:: ds NAME_LENGTH
sDayCareMon2OT::   ds NAME_LENGTH
sDayCareMon2:: box_struct sDayCareMon2
ASSERT sDayCareMon2Name - sDayCareMonName == DAY_CARE_DATA_LENGTH
; the egg the day care is keeping for the player (wDayCareEggReady), made
; when it was laid, in the same layout
sDayCareEggName:: ds NAME_LENGTH
sDayCareEggOT::   ds NAME_LENGTH
sDayCareEgg:: box_struct sDayCareEgg
ASSERT sDayCareEggName - sDayCareMon2Name == DAY_CARE_DATA_LENGTH

sBoxDataStart:: ; b88f
sNumInBox::  ds 1
sBoxSpecies:: ds MONS_PER_BOX + 1
sBoxMons::
sBoxMon1:: box_struct sBoxMon1
sBoxMon2:: ds box_struct_length * (MONS_PER_BOX + -1)
sBoxMonOT::    ds NAME_LENGTH * MONS_PER_BOX
sBoxMonNicks:: ds NAME_LENGTH * MONS_PER_BOX
sBoxMonNicksEnd::
sBoxDataEnd::
sLiveDataEnd:: ; bcf1


SECTION "Save Data", SRAM, BANK[1]
	ds $598

sPlayerName::  ds NAME_LENGTH ; a598
sMainData::    ds wMainDataEnd   - wMainDataStart ; a5a3
sSpriteData::  ds wSpriteDataEnd - wSpriteDataStart ; ad2c
sPartyData::   ds wPartyDataEnd  - wPartyDataStart ; af2c
sTilesetType:: ds 1 ; b089
sMainDataCheckSum:: ds 1 ; b08a, covers sPlayerName up to here

; The live day care and current box (sLiveDataStart, bank 0) as of the last
; save, in the same layout, with their own checksum. Loading copies this back.
sLiveDataSnapshot:: ; b08b
sDayCareData:: ds DAY_CARE_DATA_LENGTH * (DAY_CARE_SLOTS + 1) ; the egg's too
sCurBoxData::  ds sBoxDataEnd - sBoxDataStart ; b0c2
sLiveDataSnapshotEnd::
sLiveDataSnapshotCheckSum:: ds 1 ; b524
ASSERT sCurBoxData - sLiveDataSnapshot == sBoxDataStart - sLiveDataStart
ASSERT sLiveDataSnapshotEnd - sLiveDataSnapshot == sLiveDataEnd - sLiveDataStart


SECTION "Saved Boxes 1", SRAM, BANK[2]

sBox1:: ds sBoxDataEnd - sBoxDataStart ; a000
sBox2:: ds sBoxDataEnd - sBoxDataStart ; a462
sBox3:: ds sBoxDataEnd - sBoxDataStart ; a8c4
sBox4:: ds sBoxDataEnd - sBoxDataStart ; ad26
sBox5:: ds sBoxDataEnd - sBoxDataStart ; b188
sBox6:: ds sBoxDataEnd - sBoxDataStart ; b5ea
sBank2AllBoxesChecksum:: ds 1 ; ba4c
sBank2IndividualBoxChecksums:: ds 6 ; ba4d


SECTION "Saved Boxes 2", SRAM, BANK[3]

sBox7::  ds sBoxDataEnd - sBoxDataStart ; a000
sBox8::  ds sBoxDataEnd - sBoxDataStart ; a462
sBox9::  ds sBoxDataEnd - sBoxDataStart ; a8c4
sBox10:: ds sBoxDataEnd - sBoxDataStart ; ad26
sBox11:: ds sBoxDataEnd - sBoxDataStart ; b188
sBox12:: ds sBoxDataEnd - sBoxDataStart ; b5ea
sBank3AllBoxesChecksum:: ds 1 ; ba4c
sBank3IndividualBoxChecksums:: ds 6 ; ba4d


; The randomizer's world (engine/rando/): the pairs of shuffled entrances and
; what each location holds, built from the seed by RandoGenerate and kept here
; while they are this game's (sRandoTag). Not part of the save: a game
; rebuilds them from its seed when they aren't. Then the generator's working
; space.
SECTION "Rando", SRAM, BANK[1]

sRandoValid:: ds 1          ; RANDO_DATA_VERSION once built
sRandoTag:: ds 5            ; the seed (4) and settings they were built for
sRandoPartner:: ds 2 * RANDO_SLOTS ; each slot's partner ($ffff while unpaired)
sRandoPlace:: ds RANDO_LOCS ; each location's item

sRandoRng:: ds 4
sRandoTmp:: ds 4
sRandoHave:: ds 4           ; atoms held (tools/rando/gen_data.py ATOMS)
sRandoPending:: ds 4        ; gained, what they open not followed yet
sRandoStartHave:: ds 4
sRandoNew:: ds 4
sRandoSlHave:: ds 4
sRandoSP:: ds 2             ; the search stack's top (in wOverworldMap)
sRandoVisited:: ds 2        ; the set a search grows
sRandoLimit:: ds 2          ; 0, or the set it stays within
sRandoDir:: ds 1            ; 0 along the edges, 1 against them
sRandoMode:: ds 1           ; MODE_EVENTS, MODE_LOCS
sRandoGot:: ds 1
sRandoTries:: ds 1
sRandoSoftlock:: ds 1
sRandoKind:: ds 1
sRandoSkip:: ds 2
sRandoSpare:: ds 1
sRandoKindsN:: ds 1
sRandoOpenN:: ds 3          ; open doors of each kind
; the door shuffle's counts, cleared together
sRandoDemand:: ds 3
sRandoCands:: ds 2
sRandoLeaves:: ds 2
sRandoGrowers:: ds 2
sRandoStairsAnch:: ds 2
sRandoDeadStairs:: ds 2
sRandoLeafCond:: ds 2 * 3
sRandoCountsEnd::
sRandoKeyIndex:: ds 1
sRandoNeedTaken:: ds 1
sRandoItem:: ds 1
sRandoRestN:: ds 1
sRandoPtr:: ds 2
sRandoReach:: ds (RANDO_NODES + 7) / 8
sRandoSeen:: ds (RANDO_NODES + 7) / 8
sRandoBack:: ds (RANDO_NODES + 7) / 8
sRandoBad:: ds (RANDO_NODES + 7) / 8
sRandoDone:: ds (RANDO_NODES + 7) / 8
sRandoFwd:: ds (RANDO_NODES + 7) / 8
sRandoBk:: ds (RANDO_NODES + 7) / 8
sRandoTaken:: ds (RANDO_LOCS + 7) / 8
sRandoSlTaken:: ds (RANDO_LOCS + 7) / 8
sRandoKeys:: ds RANDO_NUM_PROG
; the door shuffle's, then the item placement's
UNION
sRandoState:: ds RANDO_SLOTS ; STATE_PAIRED, STATE_OPEN
sRandoClass:: ds RANDO_SLOTS
sRandoWitness:: ds RANDO_SLOTS
NEXTU
sRandoRest:: ds RANDO_LOCS
ENDU
