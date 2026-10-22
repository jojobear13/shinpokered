; The bag screen's frame, out of the bag's own bank (which is full): the
; pocket header on rows 0-2 and, on rows 13-17, two lines on the entry under
; the cursor (Gold and Silver's bag does the same). The list between them is
; the bag's (engine/menu/bag_menu.asm).
BagDrawFrame::
	coord hl, 0, 0
	lb bc, 1, 18
	call TextBoxBorder
	coord hl, 1, 1
	lb bc, 1, 18
	call ClearScreenArea
	coord hl, 1, 1
	ld [hl], "◀"
	coord hl, 18, 1
	ld [hl], "▶"
	ld a, [wBagPocket]
	add a
	ld c, a
	ld b, 0
	ld hl, PocketNames
	add hl, bc
	ld a, [hli]
	ld d, [hl]
	ld e, a
	coord hl, 4, 1
	call PlaceString
; the description box
	coord hl, 0, 13
	lb bc, 3, 18
	call TextBoxBorder
	ld a, [wBagPocketList]
	ld c, a
	ld a, [wBagCursor]
	cp c
	ld de, CancelDescription
	jr z, .gotText ; on CANCEL
	ld c, a
	ld b, 0
	ld hl, wBagPocketList + 1
	add hl, bc
	ld c, [hl] ; its index in the bag
	ld hl, wBagItems
	add hl, bc
	add hl, bc
	ld a, [hl] ; the item
	call ItemDescription
	ret z ; none
.gotText
	coord hl, 1, 14
	jp PlaceString

CancelDescription:
	db   "Close the bag.@"

; a = an item (not a TM or HM) -> de = its two lines, z if it has none
ItemDescription:
	dec a
	ld c, a
	ld b, 0
	ld hl, ItemDescriptions
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld d, [hl]
	ld e, a
	or d
	ret

; The shop's buy list (from MenuItemDescription, as its cursor moves): two
; lines on the entry under the cursor in the text box under the list, where
; "Take your time." was. A TM or HM names its move.
MartDrawDescription::
	coord hl, 1, 13
	lb bc, 4, 18
	call ClearScreenArea
	ld a, [wListScrollOffset]
	ld c, a
	ld a, [wCurrentMenuItem]
	add c
	ld c, a ; the entry
	ld a, [wListCount]
	cp c
	ld de, MartCancelDescription
	jr z, .gotText ; CANCEL
	jr c, .gotText
	ld b, 0
	ld hl, wItemList + 1
	add hl, bc
	ld a, [hl]
	cp HM_01
	jr nc, .machine
	call ItemDescription
	ret z
.gotText
	coord hl, 1, 14
	jp PlaceString
.machine
	call MachineIndex
	ld e, a
	callba RandoTMMoveFar ; its move (TM MOVES)
	ld a, e
	ld [wd11e], a
	call GetMoveName
	ld de, MachineDescription
	coord hl, 1, 14
	call PlaceString
	ld de, wcd6d
	coord hl, 1, 16
	call PlaceString
	ld h, b
	ld l, c
	ld [hl], "."
	ret

MartCancelDescription:
	db   "Done shopping.@"

MachineDescription:
	db   "Teaches the move@"

PocketNames:
	dw .items, .medicine, .balls, .battle, .berries, .key
.items
	db "ITEMS@"
.medicine
	db "MEDICINE@"
.balls
	db "# BALLS@"
.battle
	db "BATTLE ITEMS@"
.berries
	db "BERRIES@"
.key
	db "KEY ITEMS@"

INCLUDE "data/item_descriptions.asm"
