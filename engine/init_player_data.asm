InitPlayerData:
InitPlayerData2:

;useless, so commenting out
;	ld a, $ff
;	ld [wUnusedD71B], a

;joenote - check if doing NG+
	ld a, [hJoyHeld]
	and SELECT
	jr nz, .newgameplus	;skip the next few things if NG+
	
	;generate a new player ID
	;call Random
	;ld a, [hRandomSub]
	;ld [wPlayerID], a
	;call Random
	;ld a, [hRandomAdd]
	;ld [wPlayerID + 1], a

	;joenote - changing this to be more optimal
	call Random
	ld [wPlayerID], a
	call Random
	ld [wPlayerID + 1], a
	
	;joenote - generate a random seed for fisher-yates randomizer functions
	call Random
	ld [wRandomizerSeed], a
	
	;write a new box terminator to empty the box list
	call OpenBox ; the box is in save RAM
	ld hl, sNumInBox
	call InitializeEmptyList
	call CloseBox
.newgameplus
	
	ld a, $ff
	ld [wUnusedD71B], a

	ld hl, wPartyCount
	call InitializeEmptyList

	ld hl, wNumBagItems
	call InitializeEmptyList

	ld hl, wNumBoxItems
	call InitializeEmptyList


START_MONEY EQU $3000
	ld hl, wPlayerMoney + 1
	ld a, START_MONEY / $100
	ld [hld], a
	xor a
	ld [hli], a
	inc hl
	ld [hl], a

	ld [wMonDataLocation], a

	ld hl, wObtainedBadges
	ld [hli], a

	ld [hl], a

	ld hl, wPlayerCoins
	ld [hli], a
	ld [hl], a

	ld hl, wGameProgressFlags
	ld bc, wGameProgressFlagsEnd - wGameProgressFlags
	call FillMemory ; clear all game progress flags

	jp InitializeMissableObjectsFlags

InitializeEmptyList:
	xor a ; count
	ld [hli], a
	dec a ; terminator
	ld [hl], a
	ret
