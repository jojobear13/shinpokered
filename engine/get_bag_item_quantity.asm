GetQuantityOfItemInBag:
; In: b = item ID
; Out: b = how many of that item are in the bag
	call GetPredefRegisters
	ld hl, wNumBagItems
	call .loop
	ret nz	;return if item was found
	ld b, 0
	ret

; gives z and b = b_initial if item not found
; gives nz and b = qty if item found
.loop
	inc hl
	ld a, [hli]
	cp $ff
	ret z
	cp b
	jr nz, .loop
	ld a, [hl]
	ld b, a
	ld a, 1
	and a
	ret
