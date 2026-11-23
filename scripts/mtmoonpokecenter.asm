MtMoonPokecenterScript:
	call Serial_TryEstablishingExternallyClockedConnection
	jp EnableAutoTextBoxDrawing

MtMoonPokecenterTextPointers:
	dw MtMoonHealNurseText
	dw MtMoonPokecenterText2
	dw MtMoonPokecenterText3
	dw MagikarpSalesmanText
	dw MtMoonPokecenterText5
	dw MtMoonTradeNurseText

MtMoonHealNurseText:
	db $ff

MtMoonPokecenterText2:
	TX_FAR _MtMoonPokecenterText1
	db "@"

MtMoonPokecenterText3:
	TX_FAR _MtMoonPokecenterText3
	db "@"

MagikarpSalesmanText:
	TX_ASM
	CheckEvent EVENT_BOUGHT_MAGIKARP, 1
	jp c, .alreadyBoughtMagikarp
	ld hl, .Text1
	call PrintText
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jp nz, .choseNo
	ld [hMoney], a
	ld [hMoney + 2], a
	ld a, $5
	ld [hMoney + 1], a
	call HasEnoughMoney
	jr nc, .enoughMoney
	ld hl, .NoMoneyText
	jr .printText
.enoughMoney
	lb bc, MAGIKARP, 5
	call GivePokemon
	jr nc, .done
	xor a
	ld [wPriceTemp], a
	ld [wPriceTemp + 2], a
	ld a, $5
	ld [wPriceTemp + 1], a
	ld hl, wPriceTemp + 2
	ld de, wPlayerMoney + 2
	ld c, $3
	predef SubBCDPredef
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	SetEvent EVENT_BOUGHT_MAGIKARP
	jr .done
.choseNo
	ld hl, .RefuseText
	jr .printText
.alreadyBoughtMagikarp
	jp MagikarpSalesmanText_CheckEventMons	;joenote - turning this guy into an event move tutor
.backFromCheckEventMons
	ld hl, .Text2
.printText
	call PrintText
.done
	jp TextScriptEnd

.Text1
	TX_FAR _MagikarpSalesmanText1
	db "@"

.RefuseText
	TX_FAR _MagikarpSalesmanNoText
	db "@"

.NoMoneyText
	TX_FAR _MagikarpSalesmanNoMoneyText
	db "@"

.Text2
	TX_FAR _MagikarpSalesmanText2
	db "@"

MtMoonPokecenterText5:
	TX_FAR _MtMoonPokecenterText5
	db "@"

MtMoonTradeNurseText:
	db $f6

	
	
;joenote - turn this shady guy into a move tutor for japan-only event pokemon moves	

MagikarpSalesmanText_CheckEventMons:
	ld hl, wPartyMon1Species
	ld a, [hl]
	cp MAGIKARP
	jp z, MagikarpSalesmanText_DragonRageKarp
	cp RAPIDASH
	jp z, MagikarpSalesmanText_PayDayRapidashOrFearow
	cp FEAROW
	jp z, MagikarpSalesmanText_PayDayRapidashOrFearow
	cp PIKACHU
	jr nz, .done
	call .CheckOpenMoveSlot
	jp z, MagikarpSalesmanText_FlyingPikachu
.done
	jp MagikarpSalesmanText.backFromCheckEventMons
.CheckOpenMoveSlot	
	push hl
	ld hl, wPartyMon1Moves
	ld c, NUM_MOVES
.loop
	ld a, [hli]
	and a
	jr z, .endloop
	dec c
	jr nz, .loop
.endloop
	and a
	pop hl
	ret
	
MagikarpSalesmanText_DragonRageKarp:
	xor a
	ld [wWhichPokemon], a

	ld a, DRAGON_RAGE
	ld [wMoveNum], a
	ld [wd11e],a
	call GetMoveName
	call CopyStringToCF4B ; copy name to wcf4b

	ld a, [wd11e]
	push af
	ld a, [wPartyMon1Species]
	ld [wd11e], a
	call GetMonName
	pop af
	ld [wd11e], a
	
	callba CheckIfMoveIsKnown
	jp c, MagikarpSalesmanText.backFromCheckEventMons

	ld hl, .Text1
	call PrintText
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jp nz, MagikarpSalesmanText.choseNo
	ld [hMoney], a
	ld [hMoney + 2], a
	ld a, $50
	ld [hMoney + 1], a
	call HasEnoughMoney
	jr nc, .enoughMoney
	ld hl, MagikarpSalesmanText.NoMoneyText
	jp MagikarpSalesmanText.printText
.enoughMoney
	ld hl, wFlags_D733
	set 6, [hl]
	push hl		;make it so the move-forget list covers up sprites
	predef LearnMove
	pop hl
	res 6, [hl]
	ld a, b
	and a
	jp z, MagikarpSalesmanText.choseNo	
	xor a
	ld [wPriceTemp], a
	ld [wPriceTemp + 2], a
	ld a, $50
	ld [wPriceTemp + 1], a
	ld hl, wPriceTemp + 2
	ld de, wPlayerMoney + 2
	ld c, $3
	predef SubBCDPredef
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	ld hl, MagikarpSalesmanText_Thanks
	jp MagikarpSalesmanText.printText
.Text1
	text "Man: Unhappy with"
	line "your Magikarp?"
	para "I'll teach it the"
	line "move Dragon Rage"
	cont "for a mere ¥5000!"
	cont "What do you say?"
	done
	db "@"
	
	
MagikarpSalesmanText_PayDayRapidashOrFearow:
	xor a
	ld [wWhichPokemon], a

	ld a, PAY_DAY
	ld [wMoveNum], a
	ld [wd11e],a
	call GetMoveName
	call CopyStringToCF4B ; copy name to wcf4b

	ld a, [wd11e]
	push af
	ld a, [wPartyMon1Species]
	ld [wd11e], a
	call GetMonName
	pop af
	ld [wd11e], a
	
	callba CheckIfMoveIsKnown
	jp c, MagikarpSalesmanText.backFromCheckEventMons

	ld hl, .Text1
	call PrintText
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jp nz, MagikarpSalesmanText.choseNo
	ld [hMoney], a
	ld [hMoney + 2], a
	ld a, $10
	ld [hMoney + 1], a
	call HasEnoughMoney
	jr nc, .enoughMoney
	ld hl, MagikarpSalesmanText.NoMoneyText
	jp MagikarpSalesmanText.printText
.enoughMoney
	ld hl, wFlags_D733
	set 6, [hl]
	push hl		;make it so the move-forget list covers up sprites
	predef LearnMove
	pop hl
	res 6, [hl]
	ld a, b
	and a
	jp z, MagikarpSalesmanText.choseNo	
	xor a
	ld [wPriceTemp], a
	ld [wPriceTemp + 2], a
	ld a, $10
	ld [wPriceTemp + 1], a
	ld hl, wPriceTemp + 2
	ld de, wPlayerMoney + 2
	ld c, $3
	predef SubBCDPredef
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	ld hl, MagikarpSalesmanText_Thanks
	jp MagikarpSalesmanText.printText
.Text1
	text "Man: Want to make"
	line "money with that"
	cont "@"
	TX_RAM wcd6d
	db $0
	cont "of yours?"
	para "I'll teach it the"
	line "move Pay Day for"
	cont "a paltry ¥1000!"
	cont "What do you say?"
	done
	db "@"


MagikarpSalesmanText_FlyingPikachu:
	xor a
	ld [wWhichPokemon], a

	ld a, FLY
	ld [wMoveNum], a
	ld [wd11e],a
	call GetMoveName
	call CopyStringToCF4B ; copy name to wcf4b

	ld a, [wd11e]
	push af
	ld a, [wPartyMon1Species]
	ld [wd11e], a
	call GetMonName
	pop af
	ld [wd11e], a
	
	callba CheckIfMoveIsKnown
	jp c, MagikarpSalesmanText.backFromCheckEventMons

	ld hl, .Text1
	call PrintText
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jp nz, MagikarpSalesmanText.choseNo
	ld [hMoney], a
	ld [hMoney + 2], a
	ld a, $20
	ld [hMoney + 1], a
	call HasEnoughMoney
	jr nc, .enoughMoney
	ld hl, MagikarpSalesmanText.NoMoneyText
	jp MagikarpSalesmanText.printText
.enoughMoney
	call .GetOpenMoveSlot
	ld a, FLY
	ld [hl], a
	ld bc, (wPartyMon1PP - wPartyMon1Moves)
	add hl, bc
	ld a, 15
	ld [hl], a	;load 15 PP 
	xor a
	ld [wPriceTemp], a
	ld [wPriceTemp + 2], a
	ld a, $20
	ld [wPriceTemp + 1], a
	ld hl, wPriceTemp + 2
	ld de, wPlayerMoney + 2
	ld c, $3
	predef SubBCDPredef
	ld a, MONEY_BOX
	ld [wTextBoxID], a
	call DisplayTextBoxID
	ld hl, .Text2
	call PrintText
	ld a, SFX_GET_ITEM_1
	call PlaySoundWaitForCurrent
	call WaitForSoundToFinish
	ld hl, MagikarpSalesmanText_Thanks
	jp MagikarpSalesmanText.printText
.Text1
	text "Man: Ever see a"
	line "flying Pikachu?"
	para "I'll teach yours"
	line "the move Fly for"
	cont "a measly ¥2000!"
	cont "What do you say?"
	done
	db "@"
.GetOpenMoveSlot	
	ld hl, wPartyMon1Moves
	ld c, NUM_MOVES
.loop
	ld a, [hl]
	and a
	jr z, .endloop
	inc hl
	dec c
	jr nz, .loop
.endloop
	ret
.Text2
	text "Man: Let's see..."
	line "I'll just go and"
	cont "tie some balloons"
	cont "like so. And..."
	cont "Done!"
	para "Your Pikachu has"
	line "learned Fly!"
	done
	db "@"

MagikarpSalesmanText_Thanks:
	text "Man: Thanks kid!"
	done
	db "@"

