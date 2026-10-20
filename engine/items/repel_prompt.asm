; When a repel wears off (TryDoWildEncounter), Gen 6+'s offer to use another
; of the same kind, if the bag has one (wLastRepelUsed, set by
; ItemUseRepelCommon).
RepelWoreOff:
	ld a, [wLastRepelUsed]
	and a
	jr z, .woreOff
	ld b, a
	call IsItemInBag
	jr z, .woreOff
	ld a, [wLastRepelUsed]
	ld [wd11e], a
	call GetItemName
	ld hl, RepelUseAnotherText
	call PrintText
	call YesNoChoice
	ld a, [wCurrentMenuItem]
	and a
	ret nz
	ld a, [wLastRepelUsed]
	ld [hItemToRemoveID], a
	call RepelSteps
	ld [wRepelRemainingSteps], a
	callba RemoveItemByID
	ld hl, RepelUsedAnotherText
	call PrintText
	ld a, SFX_HEAL_AILMENT ; as using one from the bag sounds
	jp PlaySound
.woreOff
	ld hl, RepelWoreOffText
	jp PrintText

; a = the steps the repel in a lasts (ItemUseRepel and the others)
RepelSteps:
	ld b, 250
	cp MAX_REPEL
	jr z, .done
	ld b, 200
	cp SUPER_REPEL
	jr z, .done
	ld b, 100
.done
	ld a, b
	ret

RepelWoreOffText:
	TX_FAR _RepelWoreOffText
	db "@"

RepelUseAnotherText:
	TX_FAR _RepelUseAnotherText
	db "@"

RepelUsedAnotherText:
	TX_FAR _RepelUsedAnotherText
	db "@"
