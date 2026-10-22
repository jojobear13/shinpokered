; The bag screen: the whole screen, one pocket at a time (LEFT and RIGHT
; change pockets), the bag being kept in pocket order (SortBag). Returns
; as DisplayListMenuID does for the bag: carry if cancelled, else wcf91 = the
; item, wWhichPokemon = its index in the bag, wMaxItemQuantity = how many,
; and its name in wcd6d and wcf4b.

BAG_ROWS EQU 4 ; entries on the screen, two lines each (the description
               ; box is under them: engine/menu/item_descriptions.asm)
BAG_TOP EQU 4 ; the first entry's row

BagMenu::
	ld hl, wUpdateSpritesEnabled ; no overworld sprites over the screen
	ld a, [hl]
	push af
	ld [hl], $ff
	call BagMenuMain
	pop bc
	ld a, b
	ld [wUpdateSpritesEnabled], a ; (keeps the carry)
	ret

BagMenuMain:
	call SortBag ; into pocket order (never while an item is being added or
	             ; removed: those go by the index the bag had)
	ld hl, wd730
	set 6, [hl] ; no delay between letters
	call ClearSprites
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	ld [wMenuItemToSwap], a
	ld a, [wBagPocket]
	cp NUM_POCKETS
	jr c, .gotPocket
	xor a
	ld [wBagPocket], a
.gotPocket
	call BagLoadPocket
.redraw
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call BagDrawScreen
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
	ld a, [rBGP]
	and a ; whited out? (back from using an item on the party menu)
	call z, LoadGBPal ; then show the bag now, not on the next input
.input
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	bit BIT_A_BUTTON, b
	jp nz, .choose
	bit BIT_B_BUTTON, b
	jp nz, .cancel
	bit BIT_D_UP, b
	jr nz, .up
	bit BIT_D_DOWN, b
	jr nz, .down
	bit BIT_D_LEFT, b
	jr nz, .left
	bit BIT_D_RIGHT, b
	jr nz, .right
	jr .input
.up
	ld hl, wBagCursor
	ld a, [hl]
	and a
	jr z, .input
	dec [hl]
	ld a, [wBagScroll]
	cp [hl]
	jr c, .redraw
	jr z, .redraw
	ld a, [hl]
	ld [wBagScroll], a
	jr .redraw
.down
	ld hl, wBagCursor
	ld a, [wBagPocketList]
	cp [hl]
	jr z, .input ; on CANCEL
	inc [hl]
	ld a, [wBagScroll]
	add BAG_ROWS - 1
	cp [hl]
	jr nc, .redraw
	ld hl, wBagScroll
	inc [hl]
	jr .redraw
.left
	ld a, [wBagPocket]
	and a
	jr nz, .previous
	ld a, NUM_POCKETS
.previous
	dec a
	jr .newPocket
.right
	ld a, [wBagPocket]
	inc a
	cp NUM_POCKETS
	jr c, .newPocket
	xor a
.newPocket
	ld [wBagPocket], a
	xor a
	ld [wBagCursor], a
	ld [wBagScroll], a
	call BagLoadPocket
	ld a, SFX_PRESS_AB
	call PlaySound
	jp .redraw
.choose
	ld a, [wBagPocketList]
	ld c, a
	ld a, [wBagCursor]
	cp c
	jr z, .cancel ; CANCEL
	ld c, a
	ld b, 0
	ld hl, wBagPocketList + 1
	add hl, bc
	ld a, [hl] ; its index in the bag
	ld [wWhichPokemon], a
	ld c, a
	ld hl, wBagItems
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld [wcf91], a
	ld [wd11e], a
	ld a, [hl]
	ld [wMaxItemQuantity], a
	call GetItemName
	call CopyStringToCF4B
	call BagCursorAddress
	ld [hl], "▷"
	ld a, CHOSE_MENU_ITEM
	ld [wMenuExitMethod], a
	ld a, [wBagCursor]
	ld [wChosenMenuItem], a
	ld hl, wd730
	res 6, [hl]
	and a
	ret
.cancel
	ld a, CANCELLED_MENU
	ld [wMenuExitMethod], a
	ld hl, wd730
	res 6, [hl]
	scf
	ret

; wBagPocketList = the bag's entries in pocket wBagPocket; the cursor kept
; within it
BagLoadPocket:
	ld hl, wBagItems
	ld de, wBagPocketList + 1
	ld c, 0 ; the index in the bag
.loop
	ld a, [hli]
	cp $FF
	jr z, .done
	inc hl
	call ItemPocket
	ld b, a
	ld a, [wBagPocket]
	cp b
	jr nz, .next
	ld a, c
	ld [de], a
	inc de
.next
	inc c
	jr .loop
.done
	ld a, e
	sub LOW(wBagPocketList + 1)
	ld [wBagPocketList], a
	ld b, a
	ld a, [wBagCursor] ; at most CANCEL
	cp b
	jr c, .cursorOK
	jr z, .cursorOK
	ld a, b
	ld [wBagCursor], a
.cursorOK
	ld a, [wBagScroll]
	ld hl, wBagCursor
	cp [hl]
	jr c, .scrollOK
	jr z, .scrollOK
	ld a, [hl]
	ld [wBagScroll], a
.scrollOK
	ret

; a = an item (not a TM or HM) -> a = its pocket (POCKET_*); keeps bc, de and hl
ItemPocket::
	push hl
	push bc
	dec a
	ld c, a
	ld b, 0
	ld hl, ItemPockets
	add hl, bc
	ld a, [hl]
	pop bc
	pop hl
	ret

BagDrawScreen:
	callba BagDrawFrame ; the pocket's name, and the description box
	coord hl, 0, BAG_TOP - 1
	lb bc, BAG_ROWS * 2, 18
	call TextBoxBorder
	coord hl, 1, BAG_TOP
	lb bc, BAG_ROWS * 2, 18
	call ClearScreenArea
	xor a ; the row on the screen
.entry
	push af
	ld b, a
	ld a, [wBagScroll]
	add b
	ld b, a ; the entry
	pop af
	push af
	add a
	add BAG_TOP
	ld c, a ; its row
	ld a, [wBagPocketList]
	cp b
	jr c, .nextEntry
	jr z, .cancelEntry
	push bc
	ld hl, wBagPocketList + 1
	ld c, b
	ld b, 0
	add hl, bc
	ld c, [hl]
	ld hl, wBagItems
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld [wd11e], a
	ld [wcf91], a
	ld a, [hl]
	ld [wItemQuantity], a
	call GetItemName
	pop bc
	push bc
	ld a, c
	call BagRowAddress
	inc hl
	inc hl
	call PlaceString
	call IsKeyItem
	pop bc
	ld a, [wIsKeyItem]
	and a
	jr nz, .nextEntry ; no quantity for key items
	ld a, c
	inc a
	call BagRowAddress
	ld de, 14
	add hl, de
	ld [hl], "×"
	inc hl
	ld de, wItemQuantity
	lb bc, 1, 2
	call PrintNumber
	jr .nextEntry
.cancelEntry
	ld a, c
	call BagRowAddress
	inc hl
	inc hl
	ld de, BagCancelText
	call PlaceString
.nextEntry
	pop af
	inc a
	cp BAG_ROWS
	jr c, .entry
; the cursor
	call BagCursorAddress
	ld [hl], "▶"
	ret

; a = a row -> hl = its first tile, inside the box
BagRowAddress:
	coord hl, 1, 0
	ld bc, SCREEN_WIDTH
	jp AddNTimes

; hl = where the cursor goes
BagCursorAddress:
	ld a, [wBagScroll]
	ld b, a
	ld a, [wBagCursor]
	sub b
	add a
	add BAG_TOP
	jr BagRowAddress

BagCancelText:
	db "CANCEL@"
