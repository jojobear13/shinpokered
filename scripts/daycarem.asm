DayCareMScript:
	jp EnableAutoTextBoxDrawing

DayCareMTextPointers:
	dw DayCareMText1

DayCareMText1:
	TX_ASM
	call SaveScreenTilesToBuffer2
	ld a, [wDayCareEggReady]
	and a
	jr z, .noEgg
	ld hl, DayCareEggText ; an egg first
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .declineEgg
	ld a, [wPartyCount]
	cp PARTY_LENGTH
	ld hl, DayCareNoRoomForEggText
	jp nc, .done
	callab GiveDayCareEgg
	ld hl, DayCareReceivedEggText
	jp .done
.declineEgg
	xor a
	ld [wDayCareEggReady], a ; gone
	ld hl, DayCareKeepEggText
	jp .done
.noEgg
	ld a, [wDayCareInUse]
	and a
	jr z, .offer
	cp DAY_CARE_SLOTS
	jr z, .chooseMon
	ld hl, DayCareRaiseAnotherText ; one is here: another, or that one back?
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jp nz, .daycareInUse
	jr .deposit
.chooseMon
	callab DayCareCompatibility
	ld hl, DayCarePlayWithOthersText
	and a
	jr z, .gotCompatibility
	ld hl, DayCareDontLikeEachOtherText
	cp BREED_LOW
	jr z, .gotCompatibility
	ld hl, DayCareGetAlongText
	cp BREED_MEDIUM
	jr z, .gotCompatibility
	ld hl, DayCareGetAlongVeryWellText
.gotCompatibility
	call PrintText
	ld hl, DayCareWhichBackText
	call PrintText
	call DayCareChooseMon
	ld hl, DayCareComeAgainText
	jp c, .done
	and a
	call nz, SwapDayCareMons ; the chosen one first
	jp .daycareInUse
.offer
	ld hl, DayCareIntroText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	ld hl, DayCareComeAgainText
	jp nz, .done
.deposit
	ld a, [wPartyCount]
	dec a
	ld hl, DayCareOnlyHaveOneMonText
	jp z, .done
	ld hl, DayCareWhichMonText
	call PrintText
	xor a
	ld [wUpdateSpritesEnabled], a
	ld [wPartyMenuTypeOrMessageID], a
	ld [wMenuItemToSwap], a
	call DisplayPartyMenu
	push af
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadGBPal
	pop af
	ld hl, DayCareAllRightThenText
	jp c, .done
	ld a, [wcf91]
	cp EGG
	ld hl, DayCareCantTakeEggText
	jp z, .done
	callab PartyHasOtherBattler
	ld hl, DayCareLastMonText
	jp nc, .done
;joenote - HM moves are not needed to travel between the daycare and the Cerulean Pokemon Center,
;			so disallowing HM moves does nothing to prevent a softlock here.
;			This can be commented out safely.
;	callab KnowsHMMove
;	ld hl, DayCareCantAcceptMonWithHMText
;	jp c, .done
	xor a
	ld [wPartyAndBillsPCSavedMenuItem], a
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	ld hl, DayCareWillLookAfterMonText
	call PrintText
	ld a, [wDayCareInUse]
	and a
	call nz, SwapDayCareMons ; the one already here goes second
	ld hl, wDayCareInUse
	inc [hl]
	ld a, PARTY_TO_DAYCARE
	ld [wMoveMonType], a
	call MoveMon
	xor a
	ld [wRemoveMonFromBox], a
	call RemovePokemon
	ld a, [wcf91]
	call PlayCry
	ld hl, DayCareComeSeeMeInAWhileText
	jp .done

.daycareInUse
	call OpenBox ; the day-care mon is in save RAM
	xor a
	ld hl, sDayCareMonName
	call GetPartyMonName
	call CloseBox
	ld a, DAYCARE_DATA
	ld [wMonDataLocation], a
	call LoadMonData
	callab CalcLevelFromExperience
	ld a, d
	cp MAX_LEVEL
	jr c, .skipCalcExp

	ld d, MAX_LEVEL
	callab CalcExperience
	call OpenBox
	ld hl, sDayCareMonExp
	ld a, [hExperience]
	ld [hli], a
	ld a, [hExperience + 1]
	ld [hli], a
	ld a, [hExperience + 2]
	ld [hl], a
	call CloseBox
	ld d, MAX_LEVEL

.skipCalcExp
	xor a
	ld [wDayCareNumLevelsGrown], a
	call OpenBox
	ld hl, sDayCareMonBoxLevel
	ld a, [hl]
	ld [wDayCareStartLevel], a
	cp d
	ld [hl], d
	call CloseBox ; keeps the flags from cp
	ld hl, DayCareMonNeedsMoreTimeText
	jr z, .next
	ld a, [wDayCareStartLevel]
	ld b, a
	ld a, d
	sub b
	ld [wDayCareNumLevelsGrown], a
	ld hl, DayCareMonHasGrownText

.next
	call PrintText
	ld a, [wPartyCount]
	cp PARTY_LENGTH
	ld hl, DayCareNoRoomForMonText
	jp z, .leaveMonInDayCare
	ld de, wDayCareTotalCost
	xor a
	ld [de], a
	inc de
	ld [de], a
	ld hl, wDayCarePerLevelCost
	ld a, $1		;loading $0100 into wDayCarePerLevelCost & wDayCarePerLevelCost+1 for 100 money
	ld [hli], a
	ld [hl], $0
	ld a, [wDayCareNumLevelsGrown]
	inc a
	ld b, a
	ld c, 2
.calcPriceLoop
	push hl
	push de
	push bc
	predef AddBCDPredef
	pop bc
	pop de
	pop hl
	dec b
	jr nz, .calcPriceLoop
	ld hl, DayCareOweMoneyText
	call PrintText
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	call YesNoChoice
	ld hl, DayCareAllRightThenText
	ld a, [wCurrentMenuItem]
	and a
	jp nz, .leaveMonInDayCare
	ld hl, wDayCareTotalCost
	ld [hMoney], a
	ld a, [hli]
	ld [hMoney + 1], a
	ld a, [hl]
	ld [hMoney + 2], a
	call HasEnoughMoney
	jr nc, .enoughMoney
	ld hl, DayCareNotEnoughMoneyText
	jp .leaveMonInDayCare

.enoughMoney
	ld hl, wDayCareInUse
	dec [hl]
	xor a
	ld hl, wDayCareNumLevelsGrown
	ld [hli], a
	inc hl
	ld de, wPlayerMoney + 2
	ld c, $3
	predef SubBCDPredef
	ld a, SFX_PURCHASE
	call PlaySoundWaitForCurrent
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	ld hl, DayCareHeresYourMonText
	call PrintText
	ld a, DAYCARE_TO_PARTY
	ld [wMoveMonType], a
	call MoveMon
	call OpenBox
	ld a, [sDayCareMonSpecies]
	ld [wcf91], a
	call CloseBox
	ld a, [wPartyCount]
	dec a
	push af
	ld bc, wPartyMon2 - wPartyMon1
	push bc
	ld hl, wPartyMon1Moves
	call AddNTimes
	ld d, h
	ld e, l
;	ld a, 1			;joenote - not going to be used anymore
;	ld [wLearningMovesFromDayCare], a
;	predef WriteMonMoves
	pop bc
	pop af

	ld [wWhichPokemon], a	;joenote - update wWhichPokemon
	push af	;back up wWhichPokemon for the end
	
	ld a, [wcf91]
	call PlayCry
	
;joenote - prompt move learning and evolution if possible
	call OpenBox
	ld a, [sDayCareMonSpecies]
	ld [wd11e], a
	call CloseBox
	call DaycareMoveLearning
	call DaycareEvolution	;returns with z flag set if evolution did not happen
	jr z, .doneEvos
	ld a, [wEvolutionOccurred]
	cp 2
	jr z, .doneEvos
	
	;if an evolution completed, check if another one needs to happen
	ld a, [wWhichPokemon]
	dec a	;wWhichPokemon is +1 too many from DaycareEvolution routines, so decrement
	ld [wWhichPokemon], a
	ld hl, wPartyMon1Species
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hl]
	ld [wd11e], a	;update the species to the new evolution
	call DaycareEvolution	;See if a 2nd evolution is needed

.doneEvos
	ld a, 0
	ld [wEvolutionOccurred], a
	
	pop af	;get back wWhichPokemon

	; set mon's HP to max
	ld bc, wPartyMon2HP - wPartyMon1HP
	ld hl, wPartyMon1HP
	call AddNTimes
	ld d, h
	ld e, l
	ld bc, wPartyMon1MaxHP - wPartyMon1HP
	add hl, bc
	ld a, [hli]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a

	; the returned mon is last in the party; its name goes to wcd6d for the text
	ld a, [wPartyCount]
	dec a
	ld hl, wPartyMonNicks
	call GetPartyMonName
	ld a, [wDayCareInUse]
	and a
	call nz, SwapDayCareMons ; the one still here goes first
	ld hl, DayCareGotMonBackText
	jr .done

.leaveMonInDayCare
	ld a, [wDayCareStartLevel]
	call OpenBox
	ld [sDayCareMonBoxLevel], a
	call CloseBox

.done
	call PrintText
	jp TextScriptEnd


; swaps the two day-care mons in save RAM: the day care works on the first
SwapDayCareMons:
	call OpenBox
	ld hl, sDayCareMonName
	ld de, sDayCareMon2Name
	ld c, DAY_CARE_DATA_LENGTH
.loop
	ld a, [de]
	ld b, [hl]
	ld [hli], a
	ld a, b
	ld [de], a
	inc de
	dec c
	jr nz, .loop
	jp CloseBox

; a menu of the two day-care mons and CANCEL -> a = the one chosen (0 or 1),
; carry if cancelled
DayCareChooseMon:
	call SaveScreenTilesToBuffer1
	coord hl, 7, 4
	lb bc, 5, 11
	call TextBoxBorder
	call OpenBox
	coord hl, 9, 5
	ld de, sDayCareMonName
	call PlaceString
	coord hl, 9, 7
	ld de, sDayCareMon2Name
	call PlaceString
	call CloseBox
	coord hl, 9, 9
	ld de, DayCareCancelText
	call PlaceString
	ld hl, wTopMenuItemY
	ld a, 5
	ld [hli], a ; wTopMenuItemY
	ld a, 8
	ld [hli], a ; wTopMenuItemX
	xor a
	ld [hli], a ; wCurrentMenuItem
	inc hl
	ld a, 2
	ld [hli], a ; wMaxMenuItem
	ld a, A_BUTTON | B_BUTTON
	ld [hli], a ; wMenuWatchedKeys
	xor a
	ld [hl], a ; wLastMenuItem
	call HandleMenuInput
	push af
	call LoadScreenTilesFromBuffer1
	pop af
	bit BIT_B_BUTTON, a
	jr nz, .cancel
	ld a, [wCurrentMenuItem]
	cp 2
	jr z, .cancel
	and a
	ret
.cancel
	scf
	ret

DayCareCancelText:
	db "CANCEL@"

DaycareEvolution:
;sets z flag if no evolution happened
;clears z flag if evolution happened
	xor a 
	ld [wMonDataLocation], a	; PLAYER_PARTY_DATA
	ld [wForceEvolution], a

	ld a, [wLetterPrintingDelayFlags]
	push af
	xor a
	ld [wLetterPrintingDelayFlags], a

	;Evolution will be done as if it was happening after a battle.
	;So wStartBattleLevels needs to be updated or else the move learning will be wonky.
	ld hl, wStartBattleLevels
	ld a, [wWhichPokemon]
	push bc
	ld c, a
	ld b, 0
	add hl, bc
	pop bc
	ld a, [wDayCareStartLevel]
	ld [hl], a
	
	;make it so evolution is treated as if it were happening at the end of a battle
	ld hl, wFlags_D733
	set 6, [hl]
	push hl

	callab TryEvolvingMon

	pop hl
	res 6, [hl]
	
	pop af
	ld [wLetterPrintingDelayFlags], a

	ld a, [wEvolutionOccurred]	;check to see if any evolution started (even if cancelled with the B button)
	and a
	jr z, .no_evolve
	call WaitForSoundToFinish
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadGBPal
	ld a, 1
	and a
.no_evolve
	ret

DaycareMoveLearning:
	xor a 
	ld [wMonDataLocation], a	; PLAYER_PARTY_DATA
	ld [wForceEvolution], a

	ld a, [wLetterPrintingDelayFlags]
	push af
	xor a
	ld [wLetterPrintingDelayFlags], a
	
	push bc
	ld a, [wCurEnemyLVL]	; load the final level into a.
	ld c, a	; load the final level to over to c
	ld a, [wDayCareStartLevel]	; load the original level into a
	ld b, a	; load the original level over to b
	dec b
.inc_level	; marker for looping back 
	inc b	;increment the current level
	ld a, b	;put the current level in a
	ld [wCurEnemyLVL], a	;and set the final level to the current level in the loop
	push bc	;save b & c on the stack as they hold the currently tracked loop level a true final level
	ld a, [wFlags_D733]
	set 6, a
	ld [wFlags_D733], a		;make it so the move-forget list covers up sprites
	predef LearnMoveFromLevelUp
	ld a, [wFlags_D733]
	res 6, a
	ld [wFlags_D733], a
	pop bc	;get the current loop level and final level values back from the stack
	ld a, b	;load the current loop level into a
	cp c	;compare it with the final level
	jr c, .inc_level	;loop back again if final level has not been reached
	pop bc
	
	pop af
	ld [wLetterPrintingDelayFlags], a
	ret

	
	
DayCareIntroText:
	TX_FAR _DayCareIntroText
	db "@"

DayCareEggText:
	TX_FAR _DayCareEggText
	db "@"

DayCareReceivedEggText:
	TX_FAR _DayCareReceivedEggText
	TX_SFX_ITEM_1
	TX_FAR _DayCareTakeCareOfEggText
	db "@"

DayCareNoRoomForEggText:
	TX_FAR _DayCareNoRoomForEggText
	db "@"

DayCareKeepEggText:
	TX_FAR _DayCareKeepEggText
	db "@"

DayCareGetAlongVeryWellText:
	TX_FAR _DayCareGetAlongVeryWellText
	db "@"

DayCareGetAlongText:
	TX_FAR _DayCareGetAlongText
	db "@"

DayCareDontLikeEachOtherText:
	TX_FAR _DayCareDontLikeEachOtherText
	db "@"

DayCarePlayWithOthersText:
	TX_FAR _DayCarePlayWithOthersText
	db "@"

DayCareCantTakeEggText:
	TX_FAR _DayCareCantTakeEggText
	db "@"

DayCareLastMonText:
	TX_FAR _DayCareLastMonText
	db "@"

DayCareRaiseAnotherText:
	TX_FAR _DayCareRaiseAnotherText
	db "@"

DayCareWhichBackText:
	TX_FAR _DayCareWhichBackText
	db "@"

DayCareWhichMonText:
	TX_FAR _DayCareWhichMonText
	db "@"

DayCareWillLookAfterMonText:
	TX_FAR _DayCareWillLookAfterMonText
	db "@"

DayCareComeSeeMeInAWhileText:
	TX_FAR _DayCareComeSeeMeInAWhileText
	db "@"

DayCareMonHasGrownText:
	TX_FAR _DayCareMonHasGrownText
	db "@"

DayCareOweMoneyText:
	TX_FAR _DayCareOweMoneyText
	db "@"

DayCareGotMonBackText:
	TX_FAR _DayCareGotMonBackText
	db "@"

DayCareMonNeedsMoreTimeText:
	TX_FAR _DayCareMonNeedsMoreTimeText
	db "@"

DayCareAllRightThenText:
	TX_FAR _DayCareAllRightThenText
DayCareComeAgainText:
	TX_FAR _DayCareComeAgainText
	db "@"

DayCareNoRoomForMonText:
	TX_FAR _DayCareNoRoomForMonText
	db "@"

DayCareOnlyHaveOneMonText:
	TX_FAR _DayCareOnlyHaveOneMonText
	db "@"

DayCareCantAcceptMonWithHMText:
	TX_FAR _DayCareCantAcceptMonWithHMText
	db "@"

DayCareHeresYourMonText:
	TX_FAR _DayCareHeresYourMonText
	db "@"

DayCareNotEnoughMoneyText:
	TX_FAR _DayCareNotEnoughMoneyText
	db "@"
