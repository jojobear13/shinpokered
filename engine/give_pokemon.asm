_GivePokemon:
; returns success in carry
; and whether the mon was added to the party in [wAddedToParty]
	call EnableAutoTextBoxDrawing
	xor a
	ld [wAddedToParty], a
	ld a, [wPartyCount]
	cp PARTY_LENGTH
	jr c, .addToParty
	call GetNumInBox ; the box is in save RAM
	cp MONS_PER_BOX
	jr nc, .boxFull
; add to box
	xor a
	ld [wEnemyBattleStatus3], a
	ld a, [wcf91]
	ld [wEnemyMonSpecies2], a
	callab LoadEnemyMonData	;when sent to box, generates DVs as if it is a wild pokemon

	;joenote - makes pkmn given to player (being sent to the box) have average IVs at minimum
	ld hl, wEnemyMonDVs+1
	ld a, [hld]
	or $88	
	ld b, a
	ld a, [hl]
	or $98
	ld [hli], a
	ld [hl], b
	;joenote - make sure to heal up to the new HP value based on the new DVs
	ld de, wEnemyMonMaxHP
	ld hl, wEnemyMonHP
	ld b, 0
	push hl
	call CalcStats
	pop hl
	ld a, [wEnemyMonMaxHP]
	ld [hli], a
	ld a, [wEnemyMonMaxHP+1]
	ld [hli], a

	call SetPokedexOwnedFlag
	callab SendNewMonToBox
	ld hl, wcf4b
	ld a, [wCurrentBoxNum]
	and $7f
	cp 9
	jr c, .singleDigitBoxNum
	sub 9
	ld [hl], "1"
	inc hl
	add "0"
	jr .next
.singleDigitBoxNum
	add "1"
.next
	ld [hli], a
	ld [hl], "@"
	ld hl, SetToBoxText
	call PrintText
	scf
	ret
.boxFull
	ld hl, BoxIsFullText
	call PrintText
	and a
	ret
.addToParty
	call SetPokedexOwnedFlag
	call AddPartyMon	;if adding it directly to party, use a different function
	ld a, 1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld [wAddedToParty], a
	scf
	ret

SetPokedexOwnedFlag:
	ld a, [wcf91]
	push af
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	dec a
	ld c, a
	ld hl, wPokedexOwned
	ld b, FLAG_SET
	predef FlagActionPredef
	pop af
	ld [wd11e], a
	call GetMonName
	ld hl, GotMonText
	jp PrintText

GotMonText:
	TX_FAR _GotMonText
	TX_SFX_ITEM_1
	db "@"

SetToBoxText:
	TX_FAR _SetToBoxText
	db "@"

BoxIsFullText:
	TX_FAR _BoxIsFullText
	db "@"
