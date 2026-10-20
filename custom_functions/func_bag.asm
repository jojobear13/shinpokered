; The bag is one list of BAG_ITEM_CAPACITY items, kept in ItemSortList's
; order (data/item_pockets.asm), so each pocket's items sit together; the bag
; screen (engine/menu/bag_menu.asm) shows one pocket at a time.

; From the list menu's START: sorts the PC's item box (the bag sorts itself).
; Sorting was devolov's feature, which Shin brought to the bag and the box
HandleBagData:
	ld a, [wListMenuID]
	cp ITEMLISTMENU
	ret nz
	ld a, [wFlags_0xcd60]
	bit 4, a
	ret z ; not the PC's item box
	push bc
	push de
	push hl
	ld hl, wNumBoxItems
	call SortInventory
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
	ld [wMenuItemToSwap], a
	ld a, SFX_START_MENU
	call PlaySound
	pop hl
	pop de
	pop bc
	ret

; the bag in ItemSortList's order (as the bag screen, the PC's deposit list
; and the mart's sell list open); keeps bc, de and hl
SortBag:
	push hl
	ld hl, wNumBagItems
	call SortInventory
	pop hl
	ret

; hl = an inventory (its count, then item and quantity pairs) -> in
; ItemSortList's order; keeps bc, de and hl
SortInventory:
	push de
	push hl
	push bc
	inc hl
	ld a, l
	ld [wSortInventory], a
	ld a, h
	ld [wSortInventory + 1], a
	ld de, 0
	ld hl, ItemSortList
	ld b, [hl] ; the first item to look for
	call .start
	ld c, 0 ; where the next item found goes, from the start of the list
.loopCurrItemInBag
	ld a, [hl]
	cp $FF
	jr z, .findNextItem
	cp b
	jr z, .hasItem
	inc hl
	inc hl
	jr .loopCurrItemInBag
.findNextItem
	ld d, 0
	inc e
	ld hl, ItemSortList
	add hl, de
	ld b, [hl]
	call .start
	ld a, b
	cp $FF
	jr nz, .loopCurrItemInBag
	pop bc
	pop hl
	pop de
	ret
.hasItem ; c = where it goes, hl = where it is, b = the item
	push de
	ld d, h
	ld e, l
	call .start
	ld a, b
	ld b, 0
	add hl, bc ; where it goes
	ld b, a
	ld a, [de]
	cp [hl]
	jr z, .cont
	ld a, [hl]
	ld [hSwapItemID], a
	inc hl
	ld a, [hld]
	ld [hSwapItemQuantity], a
	ld a, [de]
	ld [hli], a
	inc de
	ld a, [de]
	ld [hl], a
	ld a, [hSwapItemQuantity]
	ld [de], a
	dec de
	ld a, [hSwapItemID]
	ld [de], a
.cont
	inc c
	inc c
	ld h, d
	ld l, e
	inc hl
	inc hl ; on past it: a second stack of the item may follow
	pop de
	jr .loopCurrItemInBag
.start ; hl = the list's first entry
	ld a, [wSortInventory]
	ld l, a
	ld a, [wSortInventory + 1]
	ld h, a
	ret

INCLUDE "data/item_pockets.asm"
