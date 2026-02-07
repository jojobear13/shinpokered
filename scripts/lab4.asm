Lab4Script:
	jp EnableAutoTextBoxDrawing

Lab4TextPointers:
	dw Lab4Text1
	dw Lab4Text2
	dw Lab4Text3
	dw Lab4Text4
	dw Lab4Text5
	dw Lab4Text6

Lab4Script_GetFossilsInBag:
; construct a list of all fossils in the player's bag
	xor a
	ld [wFilteredBagItemsCount], a
	ld de, wFilteredBagItems
	ld hl, FossilsList
.loop
	ld a, [hli]
	and a
	jr z, .done
	push hl
	push de
	ld [wd11e], a
	ld b, a
	predef GetQuantityOfItemInBag
	pop de
	pop hl
	ld a, b
	and a
	jr z, .loop

	; A fossil's in the bag
	ld a, [wd11e]
	ld [de], a
	inc de
	push hl
	ld hl, wFilteredBagItemsCount
	inc [hl]
	pop hl
	jr .loop
.done
	ld a, $ff
	ld [de], a
	ret

FossilsList:
	db DOME_FOSSIL
	db HELIX_FOSSIL
	db OLD_AMBER
	db $00

Lab4Text1:
	TX_ASM
	
	;joenote - do not allow if the cloning event sequence has been initiated
	ld hl, Lab4Text_MachineUsed
	CheckEvent EVENT_2E3
	jr nz, .done
	CheckEvent EVENT_2E4
	jr nz, .done

	CheckEvent EVENT_GAVE_FOSSIL_TO_LAB
	jr nz, .asm_75d96
	ld hl, Lab4Text_75dc6
	call PrintText
	call Lab4Script_GetFossilsInBag
	ld a, [wFilteredBagItemsCount]
	and a
	jr z, .asm_75d8d
	callba GiveFossilToCinnabarLab
	jr .asm_75d93
.asm_75d8d
	ld hl, Lab4Text_75dcb
.done
	call PrintText
.asm_75d93
	jp TextScriptEnd
.asm_75d96
	CheckEventAfterBranchReuseA EVENT_LAB_STILL_REVIVING_FOSSIL, EVENT_GAVE_FOSSIL_TO_LAB
	jr z, .asm_75da2
	ld hl, Lab4Text_75dd0
	call PrintText
	jr .asm_75d93
.asm_75da2
	call LoadFossilItemAndMonNameBank1D
	ld hl, Lab4Text_75dd5
	call PrintText
	SetEvent EVENT_LAB_HANDING_OVER_FOSSIL_MON
	ld a, [wFossilMon]
	ld b, a
	ld c, 30
	call GivePokemon
	jr nc, .asm_75d93
	ResetEvents EVENT_GAVE_FOSSIL_TO_LAB, EVENT_LAB_STILL_REVIVING_FOSSIL, EVENT_LAB_HANDING_OVER_FOSSIL_MON
	jr .asm_75d93

Lab4Text_75dc6:
	TX_FAR _Lab4Text_75dc6
	db "@"

Lab4Text_75dcb:
	TX_FAR _Lab4Text_75dcb
	db "@"

Lab4Text_75dd0:
	TX_FAR _Lab4Text_75dd0
	db "@"

Lab4Text_75dd5:
	TX_FAR _Lab4Text_75dd5
	db "@"

Lab4Text2:
	TX_ASM
	ld a, $3
	ld [wWhichTrade], a
	predef DoInGameTradeDialogue
	jp TextScriptEnd

LoadFossilItemAndMonNameBank1D:
	jpba LoadFossilItemAndMonName

	
;joenote - adding a cloning NPC
Lab4Text3:
	TX_ASM
;do not allow if the fossil event sequence has been initiated
	ld hl, Lab4Text_MachineUsed
	CheckEvent EVENT_GAVE_FOSSIL_TO_LAB
	jp nz, .done
	CheckEvent EVENT_LAB_STILL_REVIVING_FOSSIL
	jp nz, .done
	CheckEvent EVENT_LAB_HANDING_OVER_FOSSIL_MON
	jp nz, .done
	CheckEvent EVENT_2E4	;still gestating pokemon
	jp nz, .done
	
	ld hl, Lab4Text_Party
	ld a, [wPartyCount]
	cp 2
	jp c, .done
	cp 6
	jp nc, .done
	
	CheckEvent EVENT_2E3	;gave gene sample to lab
	jp nz, .getMon
	
;do not allow cloning of legendary pokemon
	ld a, [wPartyMon1Species]
	ld hl, Lab4Text_Legend
	cp MEW
	jp z, .done
	cp MEWTWO
	jp z, .done
	cp ARTICUNO
	jp z, .done
	cp ZAPDOS
	jp z, .done
	cp MOLTRES
	jp z, .done

	callba GenericMoneyDisplayScript
	ld hl, Lab4Text_Clone0
	call PrintText
	call YesNoChoice
	ld hl, Lab4Text_Bye
	ld a, [wCurrentMenuItem]
	and a
	jp nz, .done
	
	;charge 200 money
	xor a
	ld [hMoney], a	
	ld [hMoney + 2], a	
	ld a, $02
	ld [hMoney + 1], a  
	call HasEnoughMoney
	jr nc, .enoughMoney
	; not enough money
	ld hl, Lab4Text_NoMoney
	jp .done
.enoughMoney
	; Charge 200 money
	xor a
	ld [wPriceTemp], a
	ld [wPriceTemp + 2], a	
	ld a, $02
	ld [wPriceTemp + 1], a	
	ld hl, wPriceTemp + 2
	ld de, wPlayerMoney + 2
	ld c, $3
	predef SubBCDPredef
	
	callba GenericMoneyDisplayScript
	ld a, SFX_PURCHASE
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	
	ld a, [wPartyMon1DVs]
	ld b, a
	ld a, [wPartyMon1DVs+1]
	ld c, a
	ld a, [wPartyMon2DVs]
	ld d, a
	ld a, [wPartyMon2DVs+1]
	ld e, a
	predef DVPunnettSquare

	ld a, h
	ld [wFossilMonDVs], a
	and $F0
	swap a
	ld [wBuffer], a
	ld a, h
	and $0F
	ld [wBuffer+1], a
	ld a, l
	ld [wFossilMonDVs+1], a
	and $F0
	swap a
	ld [wBuffer+2], a
	ld a, l
	and $0F
	ld [wBuffer+3], a
	
	ld hl, Lab4Text_Clone1
	call PrintText
	call YesNoChoice
	ld hl, Lab4Text_Bye
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .done
	
	ld hl, Lab4Text_Clone2
	call PrintText
	call YesNoChoice
	ld hl, Lab4Text_Bye
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .done
	
	;charge 10000 money
	xor a
	ld [hMoney], a	
	ld [hMoney + 2], a	
	ld a, $10
	ld [hMoney + 1], a  
	call HasEnoughMoney
	jr nc, .enoughMoney2
	; not enough money
	ld hl, Lab4Text_NoMoney
	jr .done
.enoughMoney2
	; Charge 10000 money
	xor a
	ld [wPriceTemp + 2], a	
	ld [wPriceTemp + 1], a	
	ld a, $01
	ld [wPriceTemp], a
	ld hl, wPriceTemp + 2
	ld de, wPlayerMoney + 2
	ld c, $3
	predef SubBCDPredef
	
	callba GenericMoneyDisplayScript
	ld a, SFX_PURCHASE
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	

	ld a, [wPartyMon1Species]
	ld [wFossilMon], a
	SetEvent EVENT_2E3
	SetEvent EVENT_2E4
	ld hl, Lab4Text_Clone3

.done
	call PrintText
.end
	jp TextScriptEnd

.getMon
	ld hl, Lab4Text_Clone4
	call PrintText
	
	ld a, [wFossilMon]
	ld [wcf91], a
	push de
	callba DevolveMon
	callba DevolveMon
	pop de
	
	ld a, [wcf91]
	ld b, a
	ld c, 5
	call GivePokemon
	
	ld a, [wPartyCount]
	dec a
	ld bc, wPartyMon2 - wPartyMon1
	ld hl, wPartyMon1DVs
	call AddNTimes
	ld a, [wFossilMonDVs]
	ld [hli], a
	ld a, [wFossilMonDVs+1]
	ld [hl], a

	ResetEvents EVENT_2E3, EVENT_2E4
	jr .end
	

Lab4Text4:
	TX_ASM
	ld hl, Lab4Text_Book1A
	call PrintText
	ld hl, Lab4Text_Book0
	call PrintText
	call YesNoChoice
	ld hl, Lab4Text_Bye
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .done
	ld hl, Lab4Text_Book1B
.done
	call PrintText
	jp TextScriptEnd

Lab4Text5:
	TX_ASM
	ld hl, Lab4Text_Book2A
	call PrintText
	ld hl, Lab4Text_Book0
	call PrintText
	call YesNoChoice
	ld hl, Lab4Text_Bye
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .done
	ld hl, Lab4Text_Book2B
.done
	call PrintText
	jp TextScriptEnd

Lab4Text6:
	TX_ASM
	ld hl, Lab4Text_Book3A
	call PrintText
	ld hl, Lab4Text_Book0
	call PrintText
	call YesNoChoice
	ld hl, Lab4Text_Bye
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .done
	ld hl, Lab4Text_Book3B
.done
	call PrintText
	jp TextScriptEnd



Lab4Text_Clone0:
	TX_FAR _Lab4Text_Clone0
	db "@"
Lab4Text_Clone1:
	TX_FAR _Lab4Text_Clone1
	db "@"
Lab4Text_Clone2:
	TX_FAR _Lab4Text_Clone2
	db "@"
Lab4Text_Clone3:
	TX_FAR _Lab4Text_Clone3
	db "@"
Lab4Text_Clone4:
	TX_FAR _Lab4Text_Clone4
	db "@"
Lab4Text_MachineUsed:
	TX_FAR _Lab4Text_MachineUsed
	db "@"
Lab4Text_Bye:
	TX_FAR _Lab4Text_Bye
	db "@"
Lab4Text_NoMoney:
	TX_FAR _Lab4Text_NoMoney
	db "@"
Lab4Text_Party:
	TX_FAR _Lab4Text_Party
	db "@"
Lab4Text_Legend:
	TX_FAR _Lab4Text_Legend
	db "@"
Lab4Text_Book0:
	TX_FAR _Lab4Text_Book0
	db "@"
Lab4Text_Book1A:
	TX_FAR _Lab4Text_Book1A
	db "@"
Lab4Text_Book1B:
	TX_FAR _Lab4Text_Book1B
	db "@"
Lab4Text_Book2A:
	TX_FAR _Lab4Text_Book2A
	db "@"
Lab4Text_Book2B:
	TX_FAR _Lab4Text_Book2B
	db "@"
Lab4Text_Book3A:
	TX_FAR _Lab4Text_Book3A
	db "@"
Lab4Text_Book3B:
	TX_FAR _Lab4Text_Book3B
	db "@"
