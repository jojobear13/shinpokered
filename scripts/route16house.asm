Route16HouseScript:
	jp EnableAutoTextBoxDrawing

Route16HouseTextPointers:
	dw Route16HouseText1
	dw Route16HouseText2

Route16HouseText1:
	TX_ASM
	CheckEvent EVENT_GOT_HM02
	ld hl, HM02ExplanationText
	jr nz, .asm_13616
	ld hl, Route16HouseText3
	call PrintText
	lb bc, HM_02, 1
	call GiveItem
	jr nc, .BagFull
	SetEvent EVENT_GOT_HM02
	ld hl, ReceivedHM02Text
	jr .asm_13616
.BagFull
	ld hl, HM02NoRoomText
.asm_13616
	call PrintText
	jp TextScriptEnd

Route16HouseText3:
	TX_FAR _Route16HouseText3
	db "@"

ReceivedHM02Text:
	TX_FAR _ReceivedHM02Text
	TX_SFX_KEY_ITEM
	db "@"

HM02ExplanationText:
	TX_FAR _HM02ExplanationText
	db "@"

HM02NoRoomText:
	TX_FAR _HM02NoRoomText
	db "@"

Route16HouseText2:
	TX_ASM
	ld hl, Route16HouseText_1e652
	call PrintText
	ld a, FEAROW
	call PlayCry
	call WaitForSoundToFinish
	call CheckFearowTutor
	jp TextScriptEnd

Route16HouseText_1e652:
	TX_FAR _Route16HouseText_1e652
	db "@"

;joenote - place a pidgeot or pidgeotto at the top of your party
;then talk to the fearow
;your pokemon will learn drill peck
CheckFearowTutor:
	ld a, [wPartyMon1Species]
	cp PIDGEOTTO
	jr z, .next
	cp PIDGEOT
	jr z, .next
	ret
.next
	xor a
	ld [wWhichPokemon], a

	ld a, DRILL_PECK
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
	jr c, .finish

	ld hl, wFlags_D733
	set 6, [hl]
	push hl		;make it so the move-forget list covers up sprites
	predef LearnMove
	pop hl
	res 6, [hl]
	ld a, b
	and a
	ret z	
.finish
	ld hl, .Text1
	call PrintText
	ret
.Text1
	text "FEAROW darts"
	line "about excitedly."
	prompt
	db "@"
