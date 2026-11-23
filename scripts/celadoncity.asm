CeladonCityScript:
	call EnableAutoTextBoxDrawing
	ResetEvents EVENT_1B8, EVENT_1BF
	ResetEvent EVENT_67F
	ld a, 0
	ld [wCeladonGameCornerCurScript], a	;something is writing $18 to the game corner script number and I don't know what
	ld [wRocketHideout3CurScript], a	;something is writing $06 to this and I don't know what
	ret

CeladonCityTextPointers:
	dw CeladonCityText1
	dw CeladonCityText2
	dw CeladonCityText3
	dw CeladonCityText4
	dw CeladonCityText5
	dw CeladonCityText6
	dw CeladonCityText7
	dw CeladonCityText8
	dw CeladonCityText9
	dw CeladonCityText10
	dw CeladonCityText11
	dw PokeCenterSignText
	dw CeladonCityText13
	dw CeladonCityText14
	dw CeladonCityText15
	dw CeladonCityText16
	dw CeladonCityText17
	dw CeladonCityText18

CeladonCityText1:
	TX_FAR _CeladonCityText1
	db "@"

CeladonCityText2:
	TX_FAR _CeladonCityText2
	db "@"

CeladonCityText3:
	TX_FAR _CeladonCityText3
	db "@"

CeladonCityText4:
	TX_FAR _CeladonCityText4
	db "@"

CeladonCityText5:
	TX_ASM
	CheckEvent EVENT_GOT_TM41
	jr nz, .asm_7053f
	ld hl, TM41PreText
	call PrintText
	lb bc, TM_41, 1
	call GiveItem
	jr c, .Success
	ld hl, TM41NoRoomText
	call PrintText
	jr .Done
.Success
	ld hl, ReceivedTM41Text
	call PrintText
	SetEvent EVENT_GOT_TM41
	jr .Done
.asm_7053f
	ld hl, TM41ExplanationText
	call PrintText
.Done
	jp TextScriptEnd

TM41PreText:
	TX_FAR _TM41PreText
	db "@"

ReceivedTM41Text:
	TX_FAR _ReceivedTM41Text
	TX_SFX_ITEM_1
	db "@"

TM41ExplanationText:
	TX_FAR _TM41ExplanationText
	db "@"

TM41NoRoomText:
	TX_FAR _TM41NoRoomText
	db "@"

CeladonCityText6:
	TX_FAR _CeladonCityText6
	db "@"

CeladonCityText7:
	TX_FAR _CeladonCityText7
	TX_ASM
	ld a, POLIWRATH
	call PlayCry
	jp TextScriptEnd

	
CeladonCityText8:	;joenote - make this rocket hint about buying master balls
	TX_ASM
	CheckEvent EVENT_908
	ld hl, CeladonCityText8_alternate
	jr nz, .next	
	ld hl, CeladonCityText8_continue
.next
	call PrintText
	jp TextScriptEnd
CeladonCityText8_continue:
	TX_FAR _CeladonCityText8
	db "@"
CeladonCityText8_alternate:
	text "I got an -in- at"
	line "Silph Co. for the"
	cont "Masterball tech,"
	cont "and I supply to a"
	cont "guy at the dept."
	cont "Store on the sly."
	
	para "Who needs team"
	line "rocket for money?"
	done
	db "@"

CeladonCityText9:	;joenote - make this rocket grunt sell coins in the post-game
	TX_ASM
	CheckEvent EVENT_908
	jp nz, BuyCoinsFromRocket	
	ld hl, CeladonCityText9_continue
	call PrintText
	jp TextScriptEnd
CeladonCityText9_continue:
	TX_FAR _CeladonCityText9
	db "@"

CeladonCityText10:
	TX_FAR _CeladonCityText10
	db "@"

CeladonCityText11:
	TX_FAR _CeladonCityText11
	db "@"

CeladonCityText13:
	TX_FAR _CeladonCityText13
	db "@"

CeladonCityText14:
	TX_FAR _CeladonCityText14
	db "@"

CeladonCityText15:
	TX_FAR _CeladonCityText15
	db "@"

CeladonCityText16:
	TX_FAR _CeladonCityText16
	db "@"

CeladonCityText17:
	TX_FAR _CeladonCityText17
	db "@"

CeladonCityText18:
	TX_FAR _CeladonCityText18
	db "@"

	
	
BuyCoinsFromRocket:
	callba CeladonGameCornerScript_48f1e
	ld hl, _TXTSolicitCoins
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .refuse
	ld b, COIN_CASE
	call IsItemInBag
	jr z, .no_case
	callba Has9990Coins
	jr nc, .tooManyCoins
	xor a
	ld [hMoney], a
	ld [hMoney + 2], a
	ld a, $10
	ld [hMoney + 1], a
	call HasEnoughMoney
	jr nc, .havemoney
	ld hl, _NotEnoughMoney
	jr .end
.havemoney
	xor a
	ld [hMoney + 2], a
	ld a, $50
	ld [hMoney + 1], a
	ld a, $01
	ld [hMoney], a
	ld hl, hMoney + 2
	ld de, wPlayerMoney + 2
	ld c, $3
	predef SubBCDPredef
	xor a
	ld [hUnusedCoinsByte], a
	ld [hCoins + 1], a
	ld a, $10
	ld [hCoins], a
	ld de, wPlayerCoins + 1
	ld hl, hCoins + 1
	ld c, $2
	predef AddBCDPredef
	callba CeladonGameCornerScript_48f1e
	ld a, SFX_PURCHASE
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	ld hl, _TXTBoughtCoins
	jr .end
.refuse
	ld hl, _TXTRefuseCoins
	jr .end
.tooManyCoins
	ld hl, _TXTCoinCaseFull
	jr .end
.no_case
	ld hl, _TXTNeedCoinCase
.end
	call PrintText
	jp TextScriptEnd

_TXTSolicitCoins:
	text "Pssst! Hey kid."
	line "Wanna buy some"
	cont "coins? 1000 for"
	cont "only ¥15000."
	done
	db "@"
_TXTRefuseCoins:
	text "Then make like a"
	line "Bellsprout and"
	cont "leave!"
	
	para "It's hard enough"
	line "making money now"
	cont "that Team Rocket"
	cont "is gone."
	done
	db "@"
_TXTNeedCoinCase:
	text "Then bring your"
	line "Coin Case, dork."
	done
	db "@"
_TXTCoinCaseFull:
	text "Looks like you"
	line "don't need any."
	done
	db "@"
_NotEnoughMoney:	
	text "Come back with"
	line "the cash or don't"
	cont "waste my time!"
	done
	db "@"
_TXTBoughtCoins:
	text "Thanks. Don't ask"
	line "where I got 'em."
	done
	db "@"


