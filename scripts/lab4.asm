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
	
	; each IV is inherited from one parent or the other, at random
	ld de, wPartyMon1IVs
	callab UnpackIVsAtDE
	ld hl, wIVScratch
	ld de, wBuffer + 8
	ld bc, NUM_STATS
	call CopyData ; the first parent's
	ld de, wPartyMon2IVs
	callab UnpackIVsAtDE
	ld hl, wIVScratch
	ld de, wBuffer + 8
	ld c, NUM_STATS
.inheritIV
	call Random
	rrca
	jr nc, .gotParent
	ld a, [de]
	ld [hl], a
.gotParent
	inc hl
	inc de
	dec c
	jr nz, .inheritIV
	ld hl, wIVScratch
	ld de, wBuffer
	ld bc, NUM_STATS
	call CopyData ; to show
	xor a
	ld [wFossilMonIVs + IV_FLAGS], a
	ld de, wFossilMonIVs
	callab PackIVsKeepFlags

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
	ld [hMoney + 2], a	
	ld [hMoney + 1], a  
	ld a, $01
	ld [hMoney], a	
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
	
	; the cloned IVs, with the new mon's own flags (its ability slot), and its stats again
	ld a, [wPartyCount]
	dec a
	ld bc, wPartyMon2 - wPartyMon1
	ld hl, wPartyMon1IVs
	call AddNTimes
	ld de, wFossilMonIVs
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [hl]
	and %11
	ld b, a
	ld a, [de]
	and $FC
	or b
	ld [hl], a
	ld bc, wPartyMon1Species - (wPartyMon1IVs + IV_FLAGS)
	add hl, bc
	ld a, [hl]
	ld [wd0b5], a
	push hl
	call GetMonHeader
	pop hl
	push hl
	ld bc, wPartyMon1Level - wPartyMon1Species
	add hl, bc
	ld a, [hl]
	ld [wCurEnemyLVL], a
	pop hl
	push hl
	ld bc, wPartyMon1Stats - wPartyMon1Species
	add hl, bc
	ld d, h
	ld e, l
	pop hl
	push hl
	ld bc, wPartyMon1EVs - wPartyMon1Species
	add hl, bc
	ld b, 1
	call CalcStats
	pop hl
	ld bc, wPartyMon1MaxHP - wPartyMon1Species
	add hl, bc
	ld a, [hli]
	ld c, [hl]
	ld b, a
	ld de, wPartyMon1HP - (wPartyMon1MaxHP + 1)
	add hl, de
	ld a, b
	ld [hli], a
	ld [hl], c ; full HP

	ResetEvents EVENT_2E3, EVENT_2E4
	jp .end
	

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
