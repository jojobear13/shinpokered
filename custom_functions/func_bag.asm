;joenote - this is a general function for doing stuff with the bag data
;Entered by pressing START on the bag menu list
HandleBagData:
	ld a, [wListMenuID]
	cp ITEMLISTMENU
	ret nz
	
	ld a, [hJoyHeld]
	bit BIT_SELECT, a
	jp nz, SortItems	;if holding SELECT, then prompt to sort items
	
	;if holding RIGHT or LEFT, then send the item to the backup bag space
	bit BIT_D_RIGHT, a	
	jp nz, SendToBackupBag
	bit BIT_D_LEFT, a	
	jp nz, SendToBackupBag
;else fall through	

;joenote - This function swaps the primary bag data with a second set of stored bag data
SwapBagData:
	;do not swap bag data if the current list shown is the PC item box
	ld a, [wFlags_0xcd60]
	bit 4, a
	ret nz
	
	push bc
	push de
	push hl
	
	coord hl, 5, 3
	ld de, .swaptext
	call PlaceString
	ld c, 9
	call DelayFrames
	
	call BackupBagSwap

	call UpdateMenuInfo
	
	ld a, [wNumBagItems]
	ld [wListCount], a
	cp 2 ; does the list have less than 2 entries?
	jr c, .setMenuVariables
	ld a, 2 ; max menu item ID is 2 if the list has at least 2 entries
.setMenuVariables
	ld [wMaxMenuItem], a
	
	ld a, SFX_START_MENU
	call PlaySound
	
	pop hl
	pop de
	pop bc
	ret
.swaptext
	db "…swapping…@"

BackupBagSwap:
	;swap out the items
	push bc
	push de

	;format the terminator at the end
	ld a, $FF
	ld [wBagItemsBackupTerminator], a
	;format the list terminator given the number of items
	ld a, [wBagNumBackup]
	ld b, $00
	ld c, a
	ld hl, wBagItemsBackup
	add hl, bc
	add hl, bc
	ld [hl], $FF
	
	ld c, wBagBackupSpaceEnd - wBagBackupSpace
	ld de, wBagBackupSpace
	ld hl, wNumBagItems
	call SwapDataSmall

	pop de
	pop bc
	ret

SwapDataSmall:
; Swap c bytes from hl to de using a and b.
	ld a, [hl]
	ld b, a
	ld a, [de]
	ld [hl], a
	ld a, b
	ld [de], a
	inc de
	inc hl
	dec c
	jr nz, SwapDataSmall
	ret

UpdateMenuInfo:
	; update menu info
	xor a
	ld [wListScrollOffset], a
	ld [wCurrentMenuItem], a
	ld [wBagSavedMenuItem], a
	ld [wSavedListScrollOffset], a
	ld [wMenuItemToSwap], a
	ret

SendToBackupBag:

	;do not do anything if the current list shown is the PC item box
	ld a, [wFlags_0xcd60]
	bit 4, a
	ret nz

	push bc
	push de
	push hl
;First we have to find out which item the cursor is pointing to and put it in wcf91
	ld a, [wCurrentMenuItem]
	ld c, a
	ld a, [wListScrollOffset]
	add c
	ld c, a
	ld a, [wListCount]
	and a ; is the list empty?
	jr z, .return ; if so, return
	dec a
	cp c ; did the player select Cancel?
	jr c, .return ; if so, exit the menu
	ld a, c
	ld [wWhichPokemon], a	;Store the index (within the inventory) of the item
	sla c ; item entries are 2 bytes long, so multiply by 2
	ld a, [wListPointer]
	ld l, a
	ld a, [wListPointer + 1]
	ld h, a
	inc hl ; hl = beginning of list entries
	ld b, 0
	add hl, bc
	ld a, [hl]
	ld [wcf91], a
;Now to get the quantity of that item and put it in wMaxItemQuantity and wItemQuantity
	inc hl
	ld a, [hl] ; a = item quantity
	ld [wMaxItemQuantity], a
	ld [wItemQuantity], a
;Display some text
	coord hl, 5, 3
	ld de, .shifttext
	call PlaceString
	ld c, 18
	call DelayFrames
;Copy item to backup bag space
	ld hl, wBagNumBackup
	call AddItemToInventory
	jr nc, .return	;jump if no room available in the backup bag
;Remove from the active bag space
	ld hl, wNumBagItems
	call RemoveItemFromInventory
;Update the menu list
	call UpdateMenuInfo
	ld a, [wListCount]
	cp 2 ; does the list have less than 2 entries?
	jr c, .setMenuVariables
	ld a, 2 ; max menu item ID is 2 if the list has at least 2 entries
.setMenuVariables
	ld [wMaxMenuItem], a
;Play a sound effect
	ld a, SFX_TINK
	call PlaySound
	call UpdateMenuInfo
.return
	pop hl
	pop de
	pop bc
	ret
.shifttext
	db "…shifting…@"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Implementing the bag sorting feature written by devolov
;Wasn't hard to also make this work with the PC item box
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SortItems:
	push de
	push hl
	push bc
;	ld hl, SortItemsText ; Display the text to ask to sort
;	call PrintText
;	call YesNoChoice
;	ld a, [wCurrentMenuItem]
;	and a
;	jp z, .beginSorting ; If yes
;	jr .done
	jp .beginSorting
.finishedSwapping
	ld a, [hSwapTemp] ; If not 0, then a swap of items did occur
	and a
	jr z, .nothingSorted
;	ld hl, SortComplete
	jr .printResultText
.nothingSorted
;	ld hl, NothingToSort
.printResultText
;	call PrintText
	ld a, SFX_START_MENU
	call PlaySound
.done
	call UpdateMenuInfo
	xor a ; Zeroes a
	pop bc
	pop hl
	pop de
	ret
.beginSorting
	xor a
	ld [hSwapTemp], a ; 1 if something in the bag got sorted
	ld de, 0
	ld hl, ItemSortList
	ld b, [hl] ; This is the first item to check for
	call .ldHLbagorbox
	ld c, 0 ; Relative to wBagItems, this is where we'd like to begin swapping
.loopCurrItemInBag
	ld a, [hl] ; Load the value of hl to a (which is an item number)
	cp $FF ; See if the item number is $ff, which is 'cancel'
	jr z, .findNextItem ; If it is cancel, then move onto the next item
	cp b
	jr z, .hasItem 
	; If it's not b, then go to the next item in the bag
	inc hl ; increments to the quantity past the quantity to the next item to check
	inc hl ; increments past the quantity to the next item to check
	jr .loopCurrItemInBag
.findNextItem
	ld d, 0
	inc e
	ld hl, ItemSortList
	add hl, de
	ld b, [hl]
	call .ldHLbagorbox ; Resets hl to start at the beginning of the bag
	ld a, b
	cp $FF ; Check if we got through all of the items, to the last one
	jr z, .finishedSwapping
	jr .loopCurrItemInBag
.hasItem ; c contains where to swap to relative to the start of wBagItems
		 ; hl contains where the item to swap is absolute
		 ; b contains the item ID
	push de
	ld d, h
	ld e, l
	call .ldHLbagorbox
	ld a, b
	ld b, 0
	add hl, bc ; hl now holds where we'd like to swap to
	ld b, a
	ld a, [de]
	cp [hl]
	jr z, .cont ; If they're the same item
	ld a, 1
	ld [hSwapTemp], a
	ld a, [hl]
	ld [hSwapItemID],a ; [hSwapItemID] = second item ID
	inc hl
	ld a,[hld]
	ld [hSwapItemQuantity],a ; [hSwapItemQuantity] = second item quantity
	ld a,[de]
	ld [hli],a ; put first item ID in second item slot
	inc de
	ld a,[de]
	ld [hl],a ; put first item quantity in second item slot
	ld a,[hSwapItemQuantity]
	ld [de],a ; put second item quantity in first item slot
	dec de
	ld a,[hSwapItemID]
	ld [de],a ; put second item ID in first item slot
.cont
	inc c
	inc c
	ld h, d
	ld l, e
	pop de
	jr .findNextItem

;joenote - allow for sorting both the bag and the item PC box
.ldHLbagorbox
	ld hl, wBagItems
	push af
	ld a, [wFlags_0xcd60]
	bit 4, a
	jr z, .ldHLbagorbox_next
	ld hl, wBoxItems
.ldHLbagorbox_next
	pop af
	ret


ItemSortList::	;only for items that are bag-accessed
	; Active-Usage Key Items
	db BICYCLE
	db ITEMFINDER
	db TOWN_MAP
	db SURFBOARD
	; Rods
	db OLD_ROD
	db GOOD_ROD
	db SUPER_ROD
	; Balls
	db POKE_BALL
	db GREAT_BALL
	db ULTRA_BALL
	db MASTER_BALL
	; Common Items
	db REPEL
	db SUPER_REPEL
	db MAX_REPEL
	db ESCAPE_ROPE
	db POKE_DOLL
	; Health
	db POTION
	db SUPER_POTION
	db HYPER_POTION
	db MAX_POTION
	db FULL_RESTORE
	db FRESH_WATER
	db SODA_POP
	db LEMONADE
	; Revival
	db REVIVE
	db MAX_REVIVE
	; Status
	db ANTIDOTE
	db BURN_HEAL
	db ICE_HEAL
	db AWAKENING
	db PARLYZ_HEAL
	db FULL_HEAL
	db POKE_FLUTE
	; PP
	db ETHER
	db MAX_ETHER
	db ELIXER
	db MAX_ELIXER
	; Battle Raises
	db X_ACCURACY
	db X_ATTACK
	db X_DEFEND
	db X_SPEED
	db X_SPECIAL
	db GUARD_SPEC
	db DIRE_HIT	
	; Permanent Raises
	db RARE_CANDY
	db HP_UP
	db PROTEIN
	db IRON
	db CARBOS
	db CALCIUM
	db PP_UP
	db M_GENE
	; Stones
	db LEAF_STONE
	db FIRE_STONE
	db THUNDER_STONE
	db WATER_STONE
	db MOON_STONE
	db MIST_STONE
	; Money
	db COIN_CASE
	db NUGGET
	; Gift Passives
	db EXP_ALL
	db DOME_FOSSIL
	db HELIX_FOSSIL
	db OLD_AMBER
	; Key Items With No Active Use
	db S_S_TICKET
	db SILPH_SCOPE
	db SECRET_KEY
	db LIFT_KEY
	db CARD_KEY
	; Key Items That Are Used For Events
	db GOLD_TEETH
	db BIKE_VOUCHER
	db OAKS_PARCEL
	; TMs
	db TM_01
	db TM_01 + 1
	db TM_01 + 2
	db TM_01 + 3
	db TM_01 + 4
	db TM_01 + 5
	db TM_01 + 6
	db TM_01 + 7
	db TM_01 + 8
	db TM_01 + 9
	db TM_01 + 10
	db TM_01 + 11
	db TM_01 + 12
	db TM_01 + 13
	db TM_01 + 14
	db TM_01 + 15
	db TM_01 + 16
	db TM_01 + 17
	db TM_01 + 18
	db TM_01 + 19
	db TM_01 + 20
	db TM_01 + 21
	db TM_01 + 22
	db TM_01 + 23
	db TM_01 + 24
	db TM_01 + 25
	db TM_01 + 26
	db TM_01 + 27
	db TM_01 + 28
	db TM_01 + 29
	db TM_01 + 30
	db TM_01 + 31
	db TM_01 + 32
	db TM_01 + 33
	db TM_01 + 34
	db TM_01 + 35
	db TM_01 + 36
	db TM_01 + 37
	db TM_01 + 38
	db TM_01 + 39
	db TM_01 + 40
	db TM_01 + 41
	db TM_01 + 42
	db TM_01 + 43
	db TM_01 + 44
	db TM_01 + 45
	db TM_01 + 46
	db TM_01 + 47
	db TM_01 + 48
	db TM_01 + 49
	; HMs
	db HM_01
	db HM_01 + 1
	db HM_01 + 2
	db HM_01 + 3
	db HM_01 + 4
	db $FF ; end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
	
