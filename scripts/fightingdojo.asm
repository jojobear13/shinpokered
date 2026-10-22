FightingDojoScript:
	call EnableAutoTextBoxDrawing
	ld hl, FightingDojoTrainerHeader0
	ld de, FightingDojoScriptPointers
	ld a, [wFightingDojoCurScript]
	call ExecuteCurMapScriptInTable
	ld [wFightingDojoCurScript], a
	ret

FightingDojoScript_5cd70:
	xor a
	ld [wJoyIgnore], a
	ld [wFightingDojoCurScript], a
	ld [wCurMapScript], a
	ret

FightingDojoScriptPointers:
	dw FightingDojoScript1
	dw DisplayEnemyTrainerTextAndStartBattle
	dw EndTrainerBattle
	dw FightingDojoScript3

FightingDojoScript1:
	CheckEvent EVENT_DEFEATED_FIGHTING_DOJO
	ret nz
	call CheckFightingMapTrainers
	ld a, [wTrainerHeaderFlagBit]
	and a
	ret nz
	CheckEvent EVENT_BEAT_KARATE_MASTER
	ret nz
	xor a
	ld [hJoyHeld], a
	ld [wcf0d], a
	ld a, [wYCoord]
	cp $3
	ret nz
	ld a, [wXCoord]
	cp $4
	ret nz
	ld a, $1
	ld [wcf0d], a
	ld a, PLAYER_DIR_RIGHT
	ld [wPlayerMovingDirection], a
	ld a, $1
	ld [H_SPRITEINDEX], a
	ld a, SPRITE_FACING_LEFT
	ld [hSpriteFacingDirection], a
	call SetSpriteFacingDirectionAndDelay
	ld a, $1
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	ret

FightingDojoScript3:
	ld a, [wIsInBattle]
	cp $ff
	jp z, FightingDojoScript_5cd70
	ld a, [wcf0d]
	and a
	jr z, .asm_5cde4
	ld a, PLAYER_DIR_RIGHT
	ld [wPlayerMovingDirection], a
	ld a, $1
	ld [H_SPRITEINDEX], a
	ld a, SPRITE_FACING_LEFT
	ld [hSpriteFacingDirection], a
	call SetSpriteFacingDirectionAndDelay

.asm_5cde4
	ld a, $f0
	ld [wJoyIgnore], a
	SetEventRange EVENT_BEAT_KARATE_MASTER, EVENT_BEAT_FIGHTING_DOJO_TRAINER_3
	ld a, $8
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	xor a
	ld [wJoyIgnore], a
	ld [wFightingDojoCurScript], a
	ld [wCurMapScript], a
	ret

FightingDojoTextPointers:
	dw FightingDojoText1
	dw FightingDojoText2
	dw FightingDojoText3
	dw FightingDojoText4
	dw FightingDojoText5
	dw FightingDojoText6
	dw FightingDojoText7
	dw FightingDojoText8

FightingDojoTrainerHeader0:
	dbEventFlagBit EVENT_BEAT_FIGHTING_DOJO_TRAINER_0
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FIGHTING_DOJO_TRAINER_0
	dw FightingDojoBattleText1 ; TextBeforeBattle
	dw FightingDojoAfterBattleText1 ; TextAfterBattle
	dw FightingDojoEndBattleText1 ; TextEndBattle
	dw FightingDojoEndBattleText1 ; TextEndBattle

FightingDojoTrainerHeader1:
	dbEventFlagBit EVENT_BEAT_FIGHTING_DOJO_TRAINER_1
	db ($4 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FIGHTING_DOJO_TRAINER_1
	dw FightingDojoBattleText2 ; TextBeforeBattle
	dw FightingDojoAfterBattleText2 ; TextAfterBattle
	dw FightingDojoEndBattleText2 ; TextEndBattle
	dw FightingDojoEndBattleText2 ; TextEndBattle

FightingDojoTrainerHeader2:
	dbEventFlagBit EVENT_BEAT_FIGHTING_DOJO_TRAINER_2
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FIGHTING_DOJO_TRAINER_2
	dw FightingDojoBattleText3 ; TextBeforeBattle
	dw FightingDojoAfterBattleText3 ; TextAfterBattle
	dw FightingDojoEndBattleText3 ; TextEndBattle
	dw FightingDojoEndBattleText3 ; TextEndBattle

FightingDojoTrainerHeader3:
	dbEventFlagBit EVENT_BEAT_FIGHTING_DOJO_TRAINER_3
	db ($3 << 4) ; trainer's view range
	dwEventFlagAddress EVENT_BEAT_FIGHTING_DOJO_TRAINER_3
	dw FightingDojoBattleText4 ; TextBeforeBattle
	dw FightingDojoAfterBattleText4 ; TextAfterBattle
	dw FightingDojoEndBattleText4 ; TextEndBattle
	dw FightingDojoEndBattleText4 ; TextEndBattle

	db $ff

FightingDojoText1:
	TX_ASM
	CheckEvent EVENT_DEFEATED_FIGHTING_DOJO
	jp nz, .continue1
	CheckEventReuseA EVENT_BEAT_KARATE_MASTER
	jp nz, .continue2
.fightkaratemaster	;joenote - added marker
	ld hl, FightingDojoText_5ce8e
	call PrintText
	ld hl, wd72d
	set 6, [hl]
	set 7, [hl]
	ld hl, FightingDojoText_5ce93
	ld de, FightingDojoText_5ce93
	call SaveEndBattleTextPointers

	ld a, [hSpriteIndexOrTextID]
	ld [wSpriteIndex], a
	call EngageMapTrainer
	call InitBattleEnemyParameters
;;;;joenote - added for rematch to skip choosing prize
	CheckEvent EVENT_DEFEATED_FIGHTING_DOJO
	jp nz, TextScriptEnd
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, $3
	ld [wFightingDojoCurScript], a
	ld [wCurMapScript], a
	jr .asm_9dba4
.continue1
;;;;;;;joenote - have a rematch with karate master?
	ld hl, RematchTrainerText
	call PrintText
	call NoYesChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .fightkaratemaster
;;;;;;;
	call KarateMasterTutor
;;;;;;;
	ld hl, FightingDojoText_5ce9d
	call PrintText
	jr .asm_9dba4
.continue2
	ld hl, FightingDojoText8
	call PrintText
.asm_9dba4
	jp TextScriptEnd

FightingDojoText_5ce8e:
	TX_FAR _FightingDojoText_5ce8e
	db "@"

FightingDojoText_5ce93:
	TX_FAR _FightingDojoText_5ce93
	db "@"

FightingDojoText8:
	TX_FAR _FightingDojoText_5ce98
	db "@"

FightingDojoText_5ce9d:
	TX_FAR _FightingDojoText_5ce9d
	db "@"

FightingDojoText2:
	TX_ASM
	ld hl, FightingDojoTrainerHeader0
	call TalkToTrainer
	jp TextScriptEnd

FightingDojoBattleText1:
	TX_FAR _FightingDojoBattleText1
	db "@"

FightingDojoEndBattleText1:
	TX_FAR _FightingDojoEndBattleText1
	db "@"

FightingDojoAfterBattleText1:
	TX_FAR _FightingDojoAfterBattleText1
	db "@"

FightingDojoText3:
	TX_ASM
	ld hl, FightingDojoTrainerHeader1
	call TalkToTrainer
	jp TextScriptEnd

FightingDojoBattleText2:
	TX_FAR _FightingDojoBattleText2
	db "@"

FightingDojoEndBattleText2:
	TX_FAR _FightingDojoEndBattleText2
	db "@"

FightingDojoAfterBattleText2:
	TX_FAR _FightingDojoAfterBattleText2
	db "@"

FightingDojoText4:
	TX_ASM
	ld hl, FightingDojoTrainerHeader2
	call TalkToTrainer
	jp TextScriptEnd

FightingDojoBattleText3:
	TX_FAR _FightingDojoBattleText3
	db "@"

FightingDojoEndBattleText3:
	TX_FAR _FightingDojoEndBattleText3
	db "@"

FightingDojoAfterBattleText3:
	TX_FAR _FightingDojoAfterBattleText3
	db "@"

FightingDojoText5:
	TX_ASM
	ld hl, FightingDojoTrainerHeader3
	call TalkToTrainer
	jp TextScriptEnd

FightingDojoBattleText4:
	TX_FAR _FightingDojoBattleText4
	db "@"

FightingDojoEndBattleText4:
	TX_FAR _FightingDojoEndBattleText4
	db "@"

FightingDojoAfterBattleText4:
	TX_FAR _FightingDojoAfterBattleText4
	db "@"

FightingDojoText6:
; Hitmonlee Poké Ball
	TX_ASM
	CheckEitherEventSet EVENT_GOT_HITMONLEE, EVENT_GOT_HITMONCHAN
	jr z, .GetMon
	ld hl, OtherHitmonText
	call PrintText
	jr .done
.GetMon
	rando_special HITMONLEE
	ld [wcf91], a
	call DisplayPokedex
	ld hl, WantHitmonleeText
	call FightingDojoGiftText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .done
	ld a, [wcf91]
	ld b, a
	ld c, 30
	call GivePokemon
	jr nc, .done

	; once Poké Ball is taken, hide sprite
	ld a, HS_FIGHTING_DOJO_GIFT_1
	ld [wMissableObjectIndex], a
	predef HideObject
	SetEvents EVENT_GOT_HITMONLEE, EVENT_DEFEATED_FIGHTING_DOJO
.done
	jp TextScriptEnd

; hl = the gift's text -> hl = one that names it, if SPECIAL MON changed it
FightingDojoGiftText:
	ld a, [wRandoFlags2]
	bit RANDO2_SPECIAL_F, a
	ret z
	ld a, [wcf91]
	ld [wd11e], a
	call GetMonName
	ld hl, FightingDojoAnyGiftText
	ret

FightingDojoAnyGiftText:
	text "You want"
	line "@"
	TX_RAM wcd6d
	text "?"
	done

WantHitmonleeText:
	TX_FAR _WantHitmonleeText
	db "@"

FightingDojoText7:
; Hitmonchan Poké Ball
	TX_ASM
	CheckEitherEventSet EVENT_GOT_HITMONLEE, EVENT_GOT_HITMONCHAN
	jr z, .GetMon
	ld hl, OtherHitmonText
	call PrintText
	jr .done
.GetMon
	rando_special HITMONCHAN
	ld [wcf91], a
	call DisplayPokedex
	ld hl, WantHitmonchanText
	call FightingDojoGiftText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	jr nz, .done
	ld a, [wcf91]
	ld b, a
	ld c, 30
	call GivePokemon
	jr nc, .done
	SetEvents EVENT_GOT_HITMONCHAN, EVENT_DEFEATED_FIGHTING_DOJO

	; once Poké Ball is taken, hide sprite
	ld a, HS_FIGHTING_DOJO_GIFT_2
	ld [wMissableObjectIndex], a
	predef HideObject
.done
	jp TextScriptEnd

WantHitmonchanText:
	TX_FAR _WantHitmonchanText
	db "@"

OtherHitmonText:
	TX_FAR _OtherHitmonText
	db "@"

	
;joenote - place a Flareon at top of the party.
;Then talk to the Karate Master after completing the dojo questline.
;Decline the rematch.
;Your pokemon will learn a couple moves
KarateMasterTutor:
	ld a, [wPartyMon1Species]
	cp FLAREON
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
	ld a, LOW_KICK
	call .learnmove
	ld a, AGILITY
	call .learnmove
.finish
	ret
.Text1
	text "Your FLAREON has"
	line "the burning heart"
	cont "of a warrior. I"
	cont "could teach it a"
	cont "thing or two."
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
