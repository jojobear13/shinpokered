LavenderHouse1Script:
	call EnableAutoTextBoxDrawing
	ld a, [wCurMapScript]
	cp $AA
	jp z, LavenderHouse1ScriptAA
	ret

LavenderHouse1ScriptAA:	;joenote - adding this function to set a flag if you beat the special trainer
	xor a
	ld [wJoyIgnore], a
	ld [wCurMapScript], a
	ld a, [wIsInBattle]
	cp $ff
	ret z
;set the special trainer flag
	ld a, [wBeatGymFlags]
	set 1, a
	ld [wBeatGymFlags], a
	ret

LavenderHouse1TextPointers:
	dw LavenderHouse1Text1
	dw LavenderHouse1Text2
	dw LavenderHouse1Text3
	dw LavenderHouse1Text4
	dw LavenderHouse1Text5
	dw LavenderHouse1Text6

LavenderHouse1Text1:
	TX_ASM
	CheckEvent EVENT_RESCUED_MR_FUJI
	jr nz, .asm_72e5d
	ld hl, LavenderHouse1Text_1d8d1
	call PrintText
	jr .asm_6957f
.asm_72e5d
	ld hl, LavenderHouse1Text_1d8d6
	call PrintText
.asm_6957f
	jp TextScriptEnd

LavenderHouse1Text_1d8d1:
	TX_FAR _LavenderHouse1Text_1d8d1
	db "@"

LavenderHouse1Text_1d8d6:
	TX_FAR _LavenderHouse1Text_1d8d6
	db "@"

LavenderHouse1Text2:
	TX_ASM
	CheckEvent EVENT_RESCUED_MR_FUJI
	jr nz, .asm_06470
	ld hl, LavenderHouse1Text_1d8f4
	call PrintText
	jr .asm_3d208
.asm_06470
	ld hl, LavenderHouse1Text_1d8f9
	call PrintText
.asm_3d208
	jp TextScriptEnd

LavenderHouse1Text_1d8f4:
	TX_FAR _LavenderHouse1Text_1d8f4
	db "@"

LavenderHouse1Text_1d8f9:
	TX_FAR _LavenderHouse1Text_1d8f9
	db "@"

LavenderHouse1Text3:
	TX_FAR _LavenderHouse1Text3
	TX_ASM
	ld a, PSYDUCK
	call PlayCry
	call CheckAmnesiaPsyduck	;joenote - secret event for getting amnesia psyduck
	jp TextScriptEnd

LavenderHouse1Text4:
	TX_FAR _LavenderHouse1Text4
	TX_ASM
	ld a, NIDORINO
	call PlayCry
	jp TextScriptEnd

LavenderHouse1Text5:
	TX_ASM
	CheckEvent EVENT_GOT_POKE_FLUTE
	jr nz, .asm_15ac2
	ld hl, LavenderHouse1Text_1d94c
	call PrintText
	lb bc, POKE_FLUTE, 1
	call GiveItem
	jr nc, .BagFull
	ld hl, ReceivedFluteText
	call PrintText
	SetEvent EVENT_GOT_POKE_FLUTE
	jr .asm_da749
.BagFull
	ld hl, FluteNoRoomText
	call PrintText
	jr .asm_da749
.asm_15ac2
;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - fuji battle and MGENE item
	CheckEvent EVENT_908	;has elite 4 been beaten?
	jr z, .no_e4_beaten		;kick out if e4 not beaten
	
	CheckEvent EVENT_129	;got the MGENE from showing mewtwo to Fuji?
	jr nz, .doBattle
	ld a, [wPartyMon1Species]
	cp MEWTWO	;is mewtwo at the top of the party?
	jr nz, .doBattle
	;if so, give MGENE item
	ld hl, FujiTextMewtwo
	call PrintText
	lb bc, M_GENE, 1
	call GiveItem
	jr nc, .BagFull
	ld hl, ReceivedMGENEText
	call PrintText
	SetEvent EVENT_129
	jr .asm_da749
	
.doBattle
	ld hl, FujiText_challenge	;else ask if you want to challenge
	call PrintText	;print the challenge text
	call YesNoChoice	;prompt a yes/no choice
	ld a, [wCurrentMenuItem]	;load the player choice
	and a	;check the player choice
	jr nz, .no_e4_beaten	;kick out if no chosen
	;otherwise begin loading battle
	ld hl, FujiText_prebattle	;load pre battle text
	call PrintText	;print the pre battle text
	ld hl, wd72d;set the bits for triggering battle
	set 6, [hl]	;
	set 7, [hl]	;
	ld hl, FujiTextVictorySpeech	;load text for when you win
	ld de, FujiTextVictorySpeech	;load text for when you lose
	call SaveEndBattleTextPointers	;save the win/lose text
	ld a, $8
	ld [wGymLeaderNo], a	;set bgm to gym leader music
	ld a, OPP_GENTLEMAN	;load the trainer type
	ld [wCurOpponent], a	;set as the current opponent
	ld a, 5	;get the right roster
	ld [wTrainerNo], a
	xor a
	ld [hJoyHeld], a
	ld a, $AA
	ld [wCurMapScript], a
	jp TextScriptEnd
.no_e4_beaten
;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, MrFujiAfterFluteText
	call PrintText
.asm_da749
	jp TextScriptEnd

LavenderHouse1Text_1d94c:
	TX_FAR _LavenderHouse1Text_1d94c
	db "@"

ReceivedFluteText:
	TX_FAR _ReceivedFluteText
	TX_SFX_KEY_ITEM
	TX_FAR _FluteExplanationText
	db "@"

FluteNoRoomText:
	TX_FAR _FluteNoRoomText
	db "@"

MrFujiAfterFluteText:
	TX_FAR _MrFujiAfterFluteText
	db "@"

LavenderHouse1Text6:
	TX_FAR _LavenderHouse1Text6
	db "@"

FujiText_challenge:
	TX_FAR _FujiText_challenge
	db "@"
FujiText_prebattle:
	TX_FAR _FujiText_prebattle
	db "@"
FujiTextVictorySpeech:
	TX_FAR _FujiTextVictorySpeech
	db "@"
	
FujiTextMewtwo:
	TX_FAR _FujiTextMewtwo
	db "@"
ReceivedMGENEText:
	TX_FAR _ReceivedFluteText
	TX_SFX_ITEM_1
	db "@"


;joenote - place a psyduck at the top of your party
;then talk to the psyduck in Mr. Fuji's house
;if you have caught all 151 pokemon, your psyduck will learn amnesia
CheckAmnesiaPsyduck:
	ld hl, wPokedexOwned
	ld b, wPokedexOwnedEnd - wPokedexOwned
	call CountSetBits
	ld a, [wNumSetBits]
	cp 151
	ret c

	ld a, [wPartyMon1Species]
	cp PSYDUCK
	ret nz

	xor a
	ld [wWhichPokemon], a

	ld a, AMNESIA
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
	text "PSYDUCK looks at"
	line "you awkwardly."
	prompt
	db "@"
