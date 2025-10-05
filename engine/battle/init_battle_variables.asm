InitBattleVariables:
	ld a, [hTilesetType]
	ld [wSavedTilesetType], a

;joenote - make the trainer pokeballs red
	ld a, [wCurOpponent]
	cp 201	;is this a trainer battle?
	ld hl, wPlayerHPBarColor
	ld a, HP_BAR_RED
	ld [hli], a ; wPlayerHPBarColor
	jr nc, .clearbattlevars	;jump if this is a trainer battle
	ld a, HP_BAR_GREEN	;set to green if this is a wild battle
.clearbattlevars
	ld [hl], a ; wEnemyHPBarColor

	xor a
	ld [wActionResultOrTookBattleTurn], a
	ld [wBattleResult], a
	ld hl, wPartyAndBillsPCSavedMenuItem
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld [wListScrollOffset], a
	ld [wCriticalHitOrOHKO], a
	ld [wBattleMonSpecies], a
	ld [wPartyGainExpFlags], a
	ld [wPlayerMonNumber], a
	ld [wEscapedFromBattle], a
	ld [wMapPalOffset], a
;	ld hl, wPlayerHPBarColor
;a=0=HP_BAR_GREEN
;	ld [hli], a ; wPlayerHPBarColor
;	ld [hl], a ; wEnemyHPBarColor
	ld hl, wCanEvolveFlags
	ld b, $3c
.loop
	ld [hli], a
	dec b
	jr nz, .loop
	inc a ; POUND
	ld [wTestBattlePlayerSelectedMove], a
	ld a, [wCurMap]
	cp SAFARI_ZONE_EAST
	jr c, .notSafariBattle
	cp SAFARI_ZONE_REST_HOUSE_1
	jr nc, .notSafariBattle
	ld a, BATTLE_TYPE_SAFARI
	ld [wBattleType], a
.notSafariBattle
	jpab PlayBattleMusic
