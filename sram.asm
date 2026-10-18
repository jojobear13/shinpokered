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
sDayCareData:: ds DAY_CARE_DATA_LENGTH
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
