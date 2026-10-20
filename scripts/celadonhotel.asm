
;joenote - adding new NPC to give coins for showing him pokemon

CeladonHotelScript:
	ld a, [wUnusedD5A3]	;this location gets cleared between area transistions.
	and a
	jr nz, .jump
	push hl
	callba GetRandMonAny	;get random pkmn in wcf91
	pop hl
	ld a, [wcf91]
	ld [wUnusedD5A3], a
.jump
	jp EnableAutoTextBoxDrawing

CeladonHotelTextPointers:
	dw CeladonHotelText1
	dw CeladonHotelText2
	dw CeladonHotelText3
	dw CeladonHotelCoinGuy	

CeladonHotelCoinGuy:
	TX_ASM
	ld hl, CeladonHotelCoinGuyText_intro	
	ld a, [wUnusedD5A3]
	ld [wd11e], a
	call GetMonName
	call PrintText
	ld b, COIN_CASE
	call IsItemInBag
	jr z, .need_coincase
	
	ld a, [wPartyMon1Species]
	ld b, a
	ld a, [wUnusedD5A3]
	cp b
	ld hl, CeladonHotelCoinGuyText_PC
	jr nz, .endscript_print
	
	xor a
	ld [wcd6d], a
	callba Mon1BCDScore

	;load 100 coins by default
	xor a
	ld [hUnusedCoinsByte], a
	ld [hCoins + 1], a
	ld a, $01
	ld [hCoins], a
	
	;add normalized BCD DV score to current coin payout
	ld de, hCoins + 1
	ld hl, wcd6d + 2
	ld c, $2	;make the addition 2 bytes long
	predef AddBCDPredef	;add value in hl location to value in de location
	
	;is the pokemon shiny?
	ld de, wPartyMon1IVs
	callba ShinyIVsChecker2
	jr z, .payout
	;if so, apply a 4x multiplier
	ld de, hCoins + 1
	ld hl, hCoins + 1
	ld c, $2	;make the addition 2 bytes long
	predef AddBCDPredef	;add value in hl location to value in de location
	ld de, hCoins + 1
	ld hl, hCoins + 1
	ld c, $2	;make the addition 2 bytes long
	predef AddBCDPredef	;add value in hl location to value in de location

.payout	
	ld de, wPlayerCoins + 1
	ld hl, hCoins + 1
	ld c, $2	;make the addition 2 bytes long
	predef AddBCDPredef	;add value in hl location to value in de location
	ld hl, CeladonHotelCoinGuyText_recieved
	call PrintText
	ld a, SFX_PURCHASE
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	xor a
	ld [wUnusedD5A3], a
	jr .endscript
.need_coincase
	ld hl, CeladonHotelCoinGuyText_needcase	
.endscript_print
	call PrintText
.endscript
	jp TextScriptEnd
	
HastTooManyCoins:
	ld a, $94
	ld [hCoins], a
	ld a, $24
	ld [hCoins + 1], a
	jp HasEnoughCoins

	
CeladonHotelText1:
	TX_FAR _CeladonHotelText1
	db "@"

CeladonHotelText2:
	TX_FAR _CeladonHotelText2
	db "@"

CeladonHotelText3:
	TX_FAR _CeladonHotelText3
	db "@"
	
CeladonHotelCoinGuyText_intro:
	TX_FAR _CeladonHotelCoinGuyText_intro
	db "@"

CeladonHotelCoinGuyText_needcase:
	TX_FAR _CeladonHotelCoinGuyText_needcase
	db "@"

CeladonHotelCoinGuyText_recieved:
	TX_FAR _CeladonHotelCoinGuyText_recieved
	db "@"
	
CeladonHotelCoinGuyText_PC:
	TX_FAR _CeladonHotelCoinGuyText_PC
	db "@"