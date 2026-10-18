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
sLiveDataEnd::


SECTION "Save Data", SRAM, BANK[1]
	ds $598

sPlayerName::  ds NAME_LENGTH ; a598
sMainData::    ds wMainDataEnd   - wMainDataStart ; a5a3
sSpriteData::  ds wSpriteDataEnd - wSpriteDataStart ; ad2c
sPartyData::   ds wPartyDataEnd  - wPartyDataStart ; af2c
sCurBoxData::  ds wBoxDataEnd    - wBoxDataStart ; b0c0
sDayCareData:: ds DAY_CARE_DATA_LENGTH ; b522, snapshot of sDayCareMonName..sLiveDataEnd
sTilesetType:: ds 1 ; b559
sMainDataCheckSum:: ds 1 ; b55a


SECTION "Saved Boxes 1", SRAM, BANK[2]

sBox1:: ds wBoxDataEnd - wBoxDataStart ; a000
sBox2:: ds wBoxDataEnd - wBoxDataStart ; a462
sBox3:: ds wBoxDataEnd - wBoxDataStart ; a8c4
sBox4:: ds wBoxDataEnd - wBoxDataStart ; ad26
sBox5:: ds wBoxDataEnd - wBoxDataStart ; b188
sBox6:: ds wBoxDataEnd - wBoxDataStart ; b5ea
sBank2AllBoxesChecksum:: ds 1 ; ba4c
sBank2IndividualBoxChecksums:: ds 6 ; ba4d


SECTION "Saved Boxes 2", SRAM, BANK[3]

sBox7::  ds wBoxDataEnd - wBoxDataStart ; a000
sBox8::  ds wBoxDataEnd - wBoxDataStart ; a462
sBox9::  ds wBoxDataEnd - wBoxDataStart ; a8c4
sBox10:: ds wBoxDataEnd - wBoxDataStart ; ad26
sBox11:: ds wBoxDataEnd - wBoxDataStart ; b188
sBox12:: ds wBoxDataEnd - wBoxDataStart ; b5ea
sBank3AllBoxesChecksum:: ds 1 ; ba4c
sBank3IndividualBoxChecksums:: ds 6 ; ba4d
