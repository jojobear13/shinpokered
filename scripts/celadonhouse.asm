CeladonHouseScript:
	call EnableAutoTextBoxDrawing
	ret

CeladonHouseTextPointers:
	dw CeladonHouseText1
	dw CeladonHouseText2
	dw CeladonHouseText3

CeladonHouseText1:	;joenote - adding offer to buy pokemon
	TX_ASM
	ld hl, CeladonHouseText1B
	CheckEvent EVENT_908
	jp z, .end
	
	ld a, [wPartyCount]
	dec a
	jp z, .end
	
	xor a
	ld [hItemPrice], a
	ld [hItemPrice + 1], a
	ld [hItemPrice + 2], a
	ld [wcd6d], a
	callba Mon1BCDScore
	ld de, hItemPrice + 2
	ld hl, wcd6d + 2
	ld c, $3
	predef AddBCDPredef	;add value in hl location to value in de location
	
	ld a, 1
	ld [wcd6d], a
	callba Mon1BCDScore
	ld de, hItemPrice + 2
	ld hl, wcd6d + 2
	ld c, $3
	predef AddBCDPredef	;add value in hl location to value in de location
	
	ld a, 2
	ld [wcd6d], a
	callba Mon1BCDScore
	ld de, hItemPrice + 2
	ld hl, wcd6d + 2
	ld c, $3
	predef AddBCDPredef	;add value in hl location to value in de location
	
	;is the pokemon shiny?
	ld de, wPartyMon1IVs
	callba ShinyIVsChecker2
	jr z, .levelmultiplier
	;if so, apply a 4x multiplier
	ld de, hItemPrice + 2
	ld hl, hItemPrice + 2
	ld c, $3
	predef AddBCDPredef	;add value in hl location to value in de location
	ld de, hItemPrice + 2
	ld hl, hItemPrice + 2
	ld c, $3
	predef AddBCDPredef	;add value in hl location to value in de location

	
.levelmultiplier	
;multiply the amount paid by the 'mons level
	ld a, [hItemPrice + 2]
	ld [wcd6d + 2], a
	ld a, [hItemPrice + 1]
	ld [wcd6d + 1], a
	ld a, [hItemPrice + 0]
	ld [wcd6d + 0], a
	
	ld a, [wPartyMon1Level]
	ld b, a
.adder_loop
	push bc
	ld de, hItemPrice + 2
	ld hl, wcd6d + 2
	ld c, $3
	predef AddBCDPredef
	pop bc
	dec b
	jr nz, .adder_loop
	
	
	ld a, [wPartyMon1Species]
	ld [wd11e], a
	call GetMonName
	
	ld hl, CeladonHouseTextChiefIntro
	call PrintText
	
	call NoYesChoice
	ld a, [wCurrentMenuItem]
	and a
	jr z, .nodeal
	
	
	ld hl, hItemPrice + 2
	ld de, wPlayerMoney + 2
	ld c, $3
	predef AddBCDPredef	;add value in hl location to value in de location
	
	xor a
	ld [wWhichPokemon], a
	ld [wRemoveMonFromBox], a
	call RemovePokemon
	
	ld a, SFX_PURCHASE
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	
	xor a 
	ld [wPartyAndBillsPCSavedMenuItem], a	;reset the cursor
	
.nodeal	
	ld hl, CeladonHouseTextChiefDone
.end
	call PrintText
	jp TextScriptEnd


CeladonHouseText1B:
	TX_FAR _CeladonHouseText1
	db "@"

CeladonHouseText2:
	TX_FAR _CeladonHouseText2
	db "@"

CeladonHouseText3:
	TX_FAR _CeladonHouseText3
	db "@"
	
CeladonHouseTextChiefIntro:
	TX_FAR _CeladonHouseTextChiefIntro
	db "@"
	
CeladonHouseTextChiefDone:
	TX_FAR _CeladonHouseTextChiefDone
	db "@"