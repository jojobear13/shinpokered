SaffronHouse2Script:
	jp EnableAutoTextBoxDrawing

SaffronHouse2TextPointers:
	dw SaffronHouse2Text1

SaffronHouse2Text1:
	TX_ASM
	CheckEvent EVENT_GOT_TM29
	jr nz, .asm_9e72b
	ld hl, TM29PreReceiveText
	call PrintText
	lb bc, TM_29, 1
	call GiveItem
	jr nc, .BagFull
	ld hl, ReceivedTM29Text
	call PrintText
	SetEvent EVENT_GOT_TM29
	jr .asm_fe4e1
.BagFull
	ld hl, TM29NoRoomText
	call PrintText
	jr .asm_fe4e1
.asm_9e72b
	call MrPsychicTutor
	ld hl, TM29ExplanationText
	call PrintText
.asm_fe4e1
	jp TextScriptEnd

TM29PreReceiveText:
	TX_FAR _TM29PreReceiveText
	db "@"

ReceivedTM29Text:
	TX_FAR _ReceivedTM29Text
	TX_SFX_ITEM_1
	db "@"

TM29ExplanationText:
	TX_FAR _TM29ExplanationText
	db "@"

TM29NoRoomText:
	TX_FAR _TM29NoRoomText
	db "@"

	
;joenote - place a ninetales at top of the party.
;Then talk to mr psychic after getting his TM.
;Your pokemon will learn a move.
MrPsychicTutor:
	ld a, [wPartyMon1Species]
	cp NINETALES
	jr z, .next
	ret
.next
	ld hl, .Text1
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .finish
	xor a
	ld [wWhichPokemon], a
	ld a, HYPNOSIS
	call .learnmove
.finish
	ret
.Text1
	text "I sense a great"
	line "mystical power in"
	cont "your Ninetales."
	cont "I could teach it"
	cont "something nice."
	done
	db "@"
.learnmove
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
	ret c	;carry set of move known already

	ld hl, wFlags_D733
	set 6, [hl]
	push hl		;make it so the move-forget list covers up sprites
	predef LearnMove
	pop hl
	res 6, [hl]
	ret
