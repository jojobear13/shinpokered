FuchsiaGymScript:
	call FuchsiaGymScript_75453
	call EnableAutoTextBoxDrawing
	ld hl, FuchsiaGymTrainerHeader0
	ld de, FuchsiaGymScriptPointers
	ld a, [wFuchsiaGymCurScript]
	call ExecuteCurMapScriptInTable
	ld [wFuchsiaGymCurScript], a
	ret

FuchsiaGymScript_75453:
	ld hl, wCurrentMapScriptFlags
	bit 6, [hl]
	res 6, [hl]
	ret z
	ld hl, Gym5CityName
	ld de, Gym5LeaderName
	call LoadGymLeaderAndCityName
	ret

Gym5CityName:
	db "Fuchsia City@"
Gym5LeaderName:
	db "Koga@"

FuchsiaGymScript_75477:
	xor a
	ld [wJoyIgnore], a
	ld [wFuchsiaGymCurScript], a
	ld [wCurMapScript], a
	ret

FuchsiaGymScriptPointers:
	dw CheckFightingMapTrainers
	dw DisplayEnemyTrainerTextAndStartBattle
	dw EndTrainerBattle
	dw FuchsiaGymScript3

FuchsiaGymScript3:
	ld a, [wIsInBattle]
	cp $ff
	jp z, FuchsiaGymScript_75477

	ld a, [wPartyCount]
	dec a
	jr nz, .notutor	;party count must be 1
	ld a, [wPartyMon1Species]
	cp SCYTHER
	jr nz, .notutor	;must have a solo scyther
	ld a, [wPartyMon1Type2]
	cp GHOST
	jr z, .notutor	;can't aready have a ghost scyther
	ld a, 12
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
.notutor

	ld a, $f0
	ld [wJoyIgnore], a
;;;;joenote - added for rematch to skip gym leader tm
	CheckEvent EVENT_GOT_TM06
	jp nz, FuchsiaGymScript_75477
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
FuchsiaGymScript3_75497:
	ld a, $9
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	SetEvent EVENT_BEAT_KOGA
	lb bc, TM_06, 1
	call GiveItem
	jr nc, .BagFull
	ld a, $a
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	SetEvent EVENT_GOT_TM06
	jr .asm_754c0
.BagFull
	ld a, $b
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
.asm_754c0
	ld hl, wObtainedBadges
	set 4, [hl]
	;ld hl, wBeatGymFlags	;joenote - redundant
	;set 4, [hl]

	; deactivate gym trainers
	SetEventRange EVENT_BEAT_FUCHSIA_GYM_TRAINER_0, EVENT_BEAT_FUCHSIA_GYM_TRAINER_5

	jp FuchsiaGymScript_75477

FuchsiaGymTextPointers:
	dw FuchsiaGymText1
	dw FuchsiaGymText2
	dw FuchsiaGymText3
	dw FuchsiaGymText4
	dw FuchsiaGymText5
	dw FuchsiaGymText6
	dw FuchsiaGymText7
	dw FuchsiaGymText8
	dw FuchsiaGymText9
	dw FuchsiaGymText10
	dw FuchsiaGymText11
	dw KogaScytherNinjaTraining

FuchsiaGymTrainerHeader0:
	dbEventFlagBit EVENT_BEAT_FUCHSIA_GYM_TRAINER_0
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FUCHSIA_GYM_TRAINER_0
	dw FuchsiaGymBattleText1 ; TextBeforeBattle
	dw FuchsiaGymAfterBattleText1 ; TextAfterBattle
	dw FuchsiaGymEndBattleText1 ; TextEndBattle
	dw FuchsiaGymEndBattleText1 ; TextEndBattle

FuchsiaGymTrainerHeader1:
	dbEventFlagBit EVENT_BEAT_FUCHSIA_GYM_TRAINER_1
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FUCHSIA_GYM_TRAINER_1
	dw FuchsiaGymBattleText2 ; TextBeforeBattle
	dw FuchsiaGymAfterBattleText2 ; TextAfterBattle
	dw FuchsiaGymEndBattleText2 ; TextEndBattle
	dw FuchsiaGymEndBattleText2 ; TextEndBattle

FuchsiaGymTrainerHeader2:
	dbEventFlagBit EVENT_BEAT_FUCHSIA_GYM_TRAINER_2
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FUCHSIA_GYM_TRAINER_2
	dw FuchsiaGymBattleText3 ; TextBeforeBattle
	dw FuchsiaGymAfterBattleText3 ; TextAfterBattle
	dw FuchsiaGymEndBattleText3 ; TextEndBattle
	dw FuchsiaGymEndBattleText3 ; TextEndBattle

FuchsiaGymTrainerHeader3:
	dbEventFlagBit EVENT_BEAT_FUCHSIA_GYM_TRAINER_3
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FUCHSIA_GYM_TRAINER_3
	dw FuchsiaGymBattleText4 ; TextBeforeBattle
	dw FuchsiaGymAfterBattleText4 ; TextAfterBattle
	dw FuchsiaGymEndBattleText4 ; TextEndBattle
	dw FuchsiaGymEndBattleText4 ; TextEndBattle

FuchsiaGymTrainerHeader4:
	dbEventFlagBit EVENT_BEAT_FUCHSIA_GYM_TRAINER_4
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FUCHSIA_GYM_TRAINER_4
	dw FuchsiaGymBattleText5 ; TextBeforeBattle
	dw FuchsiaGymAfterBattleText5 ; TextAfterBattle
	dw FuchsiaGymEndBattleText5 ; TextEndBattle
	dw FuchsiaGymEndBattleText5 ; TextEndBattle

FuchsiaGymTrainerHeader5:
	dbEventFlagBit EVENT_BEAT_FUCHSIA_GYM_TRAINER_5
	db ($2 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FUCHSIA_GYM_TRAINER_5
	dw FuchsiaGymBattleText6 ; TextBeforeBattle
	dw FuchsiaGymAfterBattleText6 ; TextAfterBattle
	dw FuchsiaGymEndBattleText6 ; TextEndBattle
	dw FuchsiaGymEndBattleText6 ; TextEndBattle

	db $ff

FuchsiaGymText1:
	TX_ASM
	CheckEvent EVENT_BEAT_KOGA
	jr z, .asm_181b6
	CheckEventReuseA EVENT_GOT_TM06
	jr nz, .asm_adc3b
	call z, FuchsiaGymScript3_75497
	call DisableWaitingAfterTextDisplay
	jr .asm_e84c6
.asm_adc3b
	call KogaScytherTutor
	jp z, KogaScytherTutorEndScript
;;;;;;;joenote - have a rematch with gym leader?
	ld hl, RematchTrainerText
	call PrintText
	call NoYesChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .asm_181b6
;;;;;;;
	ld hl, KogaExplainToxicText
	call PrintText
	jr .asm_e84c6
.asm_181b6
	ld hl, KogaBeforeBattleText
	call PrintText
	ld hl, wd72d
	set 6, [hl]
	set 7, [hl]
	ld hl, KogaAfterBattleText
	ld de, KogaAfterBattleText
	call SaveEndBattleTextPointers
	ld a, $5
	ld [wGymLeaderNo], a
	ld a, [H_SPRITEINDEX]
	ld [wSpriteIndex], a
	call EngageMapTrainer
	call InitBattleEnemyParameters
	xor a
	ld [hJoyHeld], a
	ld a, $3
	ld [wFuchsiaGymCurScript], a
.asm_e84c6
	jp TextScriptEnd

KogaBeforeBattleText:
	TX_FAR _KogaBeforeBattleText
	db "@"

KogaAfterBattleText:
	TX_FAR _KogaAfterBattleText
	TX_SFX_KEY_ITEM	;joenote - play an unused sfx instead (triggered by playing GET_KEY_ITEM in battle)
	db "@"

KogaExplainToxicText:
	TX_FAR _KogaExplainToxicText
	db "@"

FuchsiaGymText9:
	TX_FAR _FuchsiaGymText9
	db "@"

FuchsiaGymText10:
	TX_FAR _ReceivedTM06Text
	;TX_SFX_KEY_ITEM	;joenote - wrong SFX played
	TX_SFX_ITEM_1

TM06ExplanationText:
	TX_FAR _TM06ExplanationText
	db "@"

FuchsiaGymText11:
	TX_FAR _TM06NoRoomText
	db "@"

FuchsiaGymText2:
	TX_ASM
	ld hl, FuchsiaGymTrainerHeader0
	call TalkToTrainer
	jp TextScriptEnd

FuchsiaGymBattleText1:
	TX_FAR _FuchsiaGymBattleText1
	db "@"

FuchsiaGymEndBattleText1:
	TX_FAR _FuchsiaGymEndBattleText1
	db "@"

FuchsiaGymAfterBattleText1:
	TX_FAR _FuchsiaGymAfterBattleText1
	db "@"

FuchsiaGymText3:
	TX_ASM
	ld hl, FuchsiaGymTrainerHeader1
	call TalkToTrainer
	jp TextScriptEnd

FuchsiaGymBattleText2:
	TX_FAR _FuchsiaGymBattleText2
	db "@"

FuchsiaGymEndBattleText2:
	TX_FAR _FuchsiaGymEndBattleText2
	db "@"

FuchsiaGymAfterBattleText2:
	TX_FAR _FuchsiaGymAfterBattleText2
	db "@"

FuchsiaGymText4:
	TX_ASM
	ld hl, FuchsiaGymTrainerHeader2
	call TalkToTrainer
	jp TextScriptEnd

FuchsiaGymBattleText3:
	TX_FAR _FuchsiaGymBattleText3
	db "@"

FuchsiaGymEndBattleText3:
	TX_FAR _FuchsiaGymEndBattleText3
	db "@"

FuchsiaGymAfterBattleText3:
	TX_FAR _FuchsiaGymAfterBattleText3
	db "@"

FuchsiaGymText5:
	TX_ASM
	ld hl, FuchsiaGymTrainerHeader3
	call TalkToTrainer
	jp TextScriptEnd

FuchsiaGymBattleText4:
	TX_FAR _FuchsiaGymBattleText4
	db "@"

FuchsiaGymEndBattleText4:
	TX_FAR _FuchsiaGymEndBattleText4
	db "@"

FuchsiaGymAfterBattleText4:
	TX_FAR _FuchsiaGymAfterBattleText4
	db "@"

FuchsiaGymText6:
	TX_ASM
	ld hl, FuchsiaGymTrainerHeader4
	call TalkToTrainer
	jp TextScriptEnd

FuchsiaGymBattleText5:
	TX_FAR _FuchsiaGymBattleText5
	db "@"

FuchsiaGymEndBattleText5:
	TX_FAR _FuchsiaGymEndBattleText5
	db "@"

FuchsiaGymAfterBattleText5:
	TX_FAR _FuchsiaGymAfterBattleText5
	db "@"

FuchsiaGymText7:
	TX_ASM
	ld hl, FuchsiaGymTrainerHeader5
	call TalkToTrainer
	jp TextScriptEnd

FuchsiaGymBattleText6:
	TX_FAR _FuchsiaGymBattleText6
	db "@"

FuchsiaGymEndBattleText6:
	TX_FAR _FuchsiaGymEndBattleText6
	db "@"

FuchsiaGymAfterBattleText6:
	TX_FAR _FuchsiaGymAfterBattleText6
	db "@"

FuchsiaGymText8:
	TX_ASM
	CheckEvent EVENT_BEAT_KOGA
	ld hl, FuchsiaGymText_75653
	jr nz, .asm_50671
	ld hl, FuchsiaGymText_7564e
.asm_50671
	call PrintText
	jp TextScriptEnd

FuchsiaGymText_7564e:
	TX_FAR _FuchsiaGymText_7564e
	db "@"

FuchsiaGymText_75653:
	TX_FAR _FuchsiaGymText_75653
	db "@"

	

	
;joenote - allow Scyther to be trained as a ninja if Koga was beaten solo	
;Gives it bug/ghost typing and allows it to be tutored in a number of ninja-like moves	
	
KogaScytherNinjaTraining:
	TX_ASM
	ld hl, _KogaTutorOffer
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jp nz, KogaScytherTutorEndScript
.yes
	call GBFadeOutToBlack
	ld a, GHOST
	ld [wPartyMon1Type2], a
	ld a, SFX_GET_ITEM_2
	call PlaySound 
	call WaitForSoundToFinish
	call GBFadeInFromBlack	
	ld hl, _KogaTutorOffer2
	call PrintText
.end
	jp TextScriptEnd

KogaScytherTutorEndScript:
	ld hl, _KogaTutorBye
	call PrintText
	jp TextScriptEnd
	
KogaScytherTutor:
	ld a, [wPartyMon1Species]
	cp SCYTHER
	jp nz, .ret_cont
	ld a, [wPartyMon1Type2]
	cp GHOST
	jr nz, .ret_cont
	ld hl, _KogaTutorIntro
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .ret_cont
	
	ld hl, wMoveBuffer+1
	push hl
	

	ld b, 0
	ld de, KogaTutorMoves
.loop2
	ld a, [de]
	and a
	jr z, .endloop2

	ld hl, wPartyMon1Moves
	ld c, 4
.loop1
	cp [hl]
	jr z, .endloop1
	inc hl
	dec c
	jr nz, .loop1
	pop hl
	ld [hli], a
	inc b
	push hl
.endloop1

	inc de
	jr .loop2
.endloop2
	
	
	pop hl
	ld a, $ff
	ld [hl], a
	ld a, b
	ld [wMoveBuffer], a
	
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	ld a, MOVESLISTMENU
	ld [wListMenuID], a
	ld de, wMoveBuffer
	ld hl, wListPointer
	ld [hl], e
	inc hl
	ld [hl], d
	xor a
	ld [wPrintItemPrices], a ; don't print prices
	call DisplayListMenuID
	jr c, .ret_close	;return if cancel selected	
	; Save the selected move id.
	ld a, [wcf91]
	ld [wMoveNum], a
	ld [wd11e],a
	call GetMoveName
	call CopyStringToCF4B ; copy name to wcf4b
	xor a	;working with first party pokemon
	ld [wWhichPokemon], a
	ld a, [wLetterPrintingDelayFlags]
	push af
	xor a
	ld [wLetterPrintingDelayFlags], a
	predef LearnMove
	pop af
	ld [wLetterPrintingDelayFlags], a	
	ret
.ret_close
	xor a
	ret
.ret_cont
	ld a, 1
	and a
	ret

KogaTutorMoves:
	db CONFUSE_RAY	;"erie lights" in japanese, scyther reflects light off its blades
	db HYPNOSIS		;genjutsu
	db PIN_MISSILE	;shuriken
	db ROLLING_KICK	;martial arts
	db LIGHT_SCREEN	;invisible walls
	db $00
	
_KogaTutorOffer:
	text "You have a highly"
	line "talented Scyther."
	cont "I could teach it"
	cont "the secret way of"
	cont "becoming a ninja."

	para "Its motions will"
	line "be so fast that"
	cont "attacks may pass"
	cont "through it as if"
	cont "it were a ghost."
	done
	db "@"

_KogaTutorOffer2:
	text "The training is"
	line "complete. See me"
	cont "again if you want"
	cont "me to tutor it in"
	cont "the way of moves."
	done
	db "@"

_KogaTutorIntro:
	text "Your Scyther is a"
	line "fine ninja. Shall"
	cont "I tutor it more?"
	done
	db "@"

_KogaTutorBye:
	text "I wish you well."
	done
	db "@"
