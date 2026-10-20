EndOfBattle:
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jr nz, .notLinkBattle
; link battle
	ld a, [wEnemyMonPartyPos]
	ld hl, wEnemyMon1Status
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld a, [wEnemyMonStatus]
	ld [hl], a
	call ClearScreen
	callab DisplayLinkBattleVersusTextBox
	ld a, [wBattleResult]
	cp $1
	ld de, YouWinText
	jr c, .placeWinOrLoseString
	ld de, YouLoseText
	jr z, .placeWinOrLoseString
	ld de, DrawText
.placeWinOrLoseString
	coord hl, 6, 8
	call PlaceString
	ld c, 200
	call DelayFrames
	jr .evolution
.notLinkBattle
	callab PartyPickup
	ld a, [wBattleResult]
	and a
	jr nz, .resetVariables
	ld hl, wTotalPayDayMoney
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	jr z, .evolution ; if pay day money is 0, jump
	ld de, wPlayerMoney + 2
	ld c, $3
	predef AddBCDPredef
	ld hl, PickUpPayDayMoneyText
	call PrintText
.evolution
	xor a
	ld [wForceEvolution], a
	predef EvolutionAfterBattle
.resetVariables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - set the 7th bit of wUnusedD5A3 so it signifies coming out of a battle
	ld a, [wUnusedD5A3]
	set 7, a
	ld [wUnusedD5A3], a
;handle stuff for the nuzlocke mode; anything with zero HP will be marked dead if there was no forfeit
	predef EndOfBattle_NuzlockeHandler
;reset the flag used forfeiting
	ld a, [wUnusedD721]
	res 1, a
	ld [wUnusedD721], a
;fully heal the party after winning a trainer battle (dead nuzlocke mons stay dead)
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	jr z, .noTrainerVictoryHeal
	ld a, [wIsInBattle]
	cp 2 ; trainer battle?
	jr nz, .noTrainerVictoryHeal
	ld a, [wBattleResult]
	and a ; did the player win?
	jr nz, .noTrainerVictoryHeal
	CheckEvent EVENT_NO_WIN_HEAL ; the HEAL ON WIN rule
	jr nz, .noTrainerVictoryHeal
	predef HealParty
.noTrainerVictoryHeal
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	xor a
	ld [wLowHealthAlarm], a ;disable low health alarm
	ld [wChannelSoundIDs + Ch4], a
	ld [wIsInBattle], a
	ld [wBattleType], a
	ld [wMoveMissed], a
	ld [wCurOpponent], a
	ld [wForcePlayerToChooseMon], a
	ld [wNumRunAttempts], a
	ld [wEscapedFromBattle], a
	ld hl, wPartyAndBillsPCSavedMenuItem
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [wListScrollOffset], a

;joenote - zero the damage address
	ld hl, wDamage
	ld [hli], a
	ld [hl], a

	ld hl, wPlayerStatsToDouble
	ld b, $18
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	ld hl, wd72c
	set 0, [hl]
	call WaitForSoundToFinish
	call GBPalWhiteOut
	ld a, $ff
	ld [wDestinationWarpID], a
	ret

YouWinText:
	db "YOU WIN@"

YouLoseText:
	db "YOU LOSE@"

DrawText:
	db "  DRAW@"

PickUpPayDayMoneyText:
	TX_FAR _PickUpPayDayMoneyText
	db "@"
