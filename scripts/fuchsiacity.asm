FuchsiaCityScript:
	jp EnableAutoTextBoxDrawing

FuchsiaCityTextPointers:
	dw FuchsiaCityText1
	dw FuchsiaCityText2
	dw FuchsiaCityText3
	dw FuchsiaCityText4
	dw FuchsiaCityText5
	dw FuchsiaCityText6
	dw FuchsiaCityText7
	dw FuchsiaCityText8
	dw FuchsiaCityText9
	dw FuchsiaCityText10
	dw FuchsiaCityText11
	dw FuchsiaCityText12
	dw FuchsiaCityText13
	dw MartSignText
	dw PokeCenterSignText
	dw FuchsiaCityText16
	dw FuchsiaCityText17
	dw FuchsiaCityText18
	dw FuchsiaCityText19
	dw FuchsiaCityText20
	dw FuchsiaCityText21
	dw FuchsiaCityText22
	dw FuchsiaCityText23
	dw FuchsiaCityText24

FuchsiaCityText1:
	TX_FAR _FuchsiaCityText1
	db "@"

FuchsiaCityText2:
	TX_FAR _FuchsiaCityText2
	db "@"

FuchsiaCityText3:
	TX_FAR _FuchsiaCityText3
	db "@"

FuchsiaCityText4:
	TX_FAR _FuchsiaCityText4
	db "@"

FuchsiaCityText5:
FuchsiaCityText6:
FuchsiaCityText7:
FuchsiaCityText8:
FuchsiaCityText9:
FuchsiaCityText10:
	TX_FAR _FuchsiaCityText5
	db "@"

FuchsiaCityText12:
FuchsiaCityText11:
	TX_FAR _FuchsiaCityText11
	db "@"

FuchsiaCityText13:
	TX_FAR _FuchsiaCityText13
	db "@"

FuchsiaCityText16:
	TX_FAR _FuchsiaCityText16
	db "@"

FuchsiaCityText17:
	TX_FAR _FuchsiaCityText17
	db "@"

FuchsiaCityText18:
	TX_FAR _FuchsiaCityText18
	db "@"

FuchsiaCityText19:
	TX_ASM
	ld hl, FuchsiaCityChanseyText
	call PrintText
	ld a, CHANSEY
	call DisplayPokedex
	jp TextScriptEnd

FuchsiaCityChanseyText:
	TX_FAR _FuchsiaCityChanseyText
	db "@"

FuchsiaCityText20:
	TX_ASM
	ld hl, FuchsiaCityVoltorbText
	call PrintText
	ld a, VOLTORB
	call DisplayPokedex
	jp TextScriptEnd

FuchsiaCityVoltorbText:
	TX_FAR _FuchsiaCityVoltorbText
	db "@"

FuchsiaCityText21:
	TX_ASM
	ld hl, FuchsiaCityKangaskhanText
	call PrintText
	ld a, KANGASKHAN
	call DisplayPokedex
	jp TextScriptEnd

FuchsiaCityKangaskhanText:
	TX_FAR _FuchsiaCityKangaskhanText
	db "@"

FuchsiaCityText22:
	TX_ASM
	ld hl, FuchsiaCitySlowpokeText
	call PrintText
	ld a, SLOWPOKE
	call DisplayPokedex
	jp TextScriptEnd

FuchsiaCitySlowpokeText:
	TX_FAR _FuchsiaCitySlowpokeText
	db "@"

FuchsiaCityText23:
	TX_ASM
	ld hl, FuchsiaCityLaprasText
	call PrintText
	ld a, LAPRAS
	call DisplayPokedex
	jp TextScriptEnd

FuchsiaCityLaprasText:
	TX_FAR _FuchsiaCityLaprasText
	db "@"

FuchsiaCityText24:
	TX_ASM
	CheckEvent EVENT_GOT_DOME_FOSSIL
	jr nz, .asm_3b4e8
	CheckEventReuseA EVENT_GOT_HELIX_FOSSIL
	jr nz, .asm_667d5
	ld hl, FuchsiaCityText_19b2a
	call PrintText
	jr .asm_4343f
.asm_3b4e8
	ld hl, FuchsiaCityOmanyteText
	call PrintText
	ld a, OMANYTE
	jr .asm_81556
.asm_667d5
	ld hl, FuchsiaCityKabutoText
	call PrintText
	ld a, KABUTO
.asm_81556
	call DisplayPokedex
.asm_4343f
	call FossilTutor
	jp TextScriptEnd

FuchsiaCityOmanyteText:
	TX_FAR _FuchsiaCityOmanyteText
	db "@"

FuchsiaCityKabutoText:
	TX_FAR _FuchsiaCityKabutoText
	db "@"

FuchsiaCityText_19b2a:
	TX_FAR _FuchsiaCityText_19b2a
	db "@"

	
;joenote - place a fully evolved fossil pokemon at the top of your party
;then examine the omanyte sign
;your pokemon will a move that it knew in the ancient past
FossilTutor:
	ld a, [wPartyMon1Species]
	cp OMASTAR
	ld a, ROCK_SLIDE
	jr z, .next
	ld a, [wPartyMon1Species]
	cp KABUTOPS
	ld a, MEGA_DRAIN
	jr z, .next
	ld a, [wPartyMon1Species]
	cp AERODACTYL
	ld a, EARTHQUAKE
	jr z, .next
	ret
.next
	ld [wMoveNum], a
	ld [wd11e],a
	xor a
	ld [wWhichPokemon], a
	call GetMoveName
	call CopyStringToCF4B ; copy name to wcf4b

	ld hl, .Text1
	call PrintText

	ld a, [wd11e]
	push af
	ld a, [wPartyMon1Species]
	ld [wd11e], a
	call GetMonName
	pop af
	ld [wd11e], a
	
	callba CheckIfMoveIsKnown
	ret c

	ld hl, wFlags_D733
	set 6, [hl]
	push hl		;make it so the move-forget list covers up sprites
	predef LearnMove
	pop hl
	res 6, [hl]
	ret
	nop	;padding to maintain function addresses
	nop
	nop
	nop
.Text1
	text "Your #MON acts"
	line "like it recalled"
	cont "a memory from the"
	cont "distant past."
	prompt
	db "@"
