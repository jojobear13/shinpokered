; Held items used from the bag, and TAKE on the party menu (out of bank 3,
; which is full). The bag's DEXREPEL, a key item after the held items, comes
; here too.

; a held item, used from the bag, is given to a party mon; one it was holding
; goes back in the bag. The bag calls this as it does any other item, so
; this puts the field back as the bag's party menu items have it done for
; them (StartMenu_Item's .useItem_partyMenu): sprites updating again, and
; the map's sprite tiles over the party menu's icons
ItemUseHeldItem_:
	ld a, [wcf91]
	cp DEXREPEL
	jp z, ItemUseDexRepel
	ld a, [wUpdateSpritesEnabled]
	push af
	call GiveHeldItem
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	pop af
	ld [wUpdateSpritesEnabled], a
	ret

GiveHeldItem:
	ld a, [wWhichPokemon] ; the item's place in the bag
	push af
	ld a, [wcf91]
	push af
	ld a, USE_ITEM_PARTY_MENU
	ld [wPartyMenuTypeOrMessageID], a
	ld a, $ff
	ld [wUpdateSpritesEnabled], a
	call DisplayPartyMenu
	pop bc ; b = the item
	jr c, .canceled
	ld a, b
	ld [wcf91], a
	call GetPartyMonHeldItemAddr
	ld a, [hl]
	and a
	jr z, .notHolding
; take the old one back first: that needs room in the bag
	push hl
	ld [wcf91], a
	ld a, 1
	ld [wItemQuantity], a
	ld hl, wNumBagItems
	call AddItemToInventory
	pop hl
	jr nc, .bagFull
	call PrintTookHeldItem
	ld a, b
	ld [wcf91], a
	call GetPartyMonHeldItemAddr
.notHolding
	ld [hl], b
	ld a, b
	ld [wd11e], a
	call GetItemName
	call CopyStringToCF4B
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	ld hl, NowHoldingItemText
	call PrintText
	pop af
	ld [wWhichPokemon], a ; the bag place, to take the item out
	ld hl, wNumBagItems
	ld a, 1
	ld [wItemQuantity], a
	jp RemoveItemFromInventory
.bagFull
	ld hl, BagFullHeldItemText
	call PrintText
.canceled
	xor a
	ld [wActionResultOrTookBattleTurn], a ; item not used
	pop af
	ld [wWhichPokemon], a
	ret

; hl = the held item of party mon wWhichPokemon; preserves bc
GetPartyMonHeldItemAddr:
	push bc
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1CatchRate
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	pop bc
	ret

; TAKE on the party menu: party mon wWhichPokemon's held item goes in the bag
TakeHeldItem:
	call GetPartyMonHeldItemAddr
	ld a, [hl]
	and a
	ret z
	push hl
	ld [wcf91], a
	ld a, 1
	ld [wItemQuantity], a
	ld hl, wNumBagItems
	call AddItemToInventory
	pop hl
	jr nc, HeldItemBagFull
	ld [hl], 0
	; fall through
; "Took <item> from <mon>." for the item in wcf91
PrintTookHeldItem:
	push bc
	ld a, [wcf91]
	ld [wd11e], a
	call GetItemName
	call CopyStringToCF4B
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	ld hl, TookHeldItemText
	call PrintText
	pop bc
	ret

HeldItemBagFull:
	ld hl, BagFullHeldItemText
	jp PrintText

NowHoldingItemText:
	text "@"
	TX_RAM wcd6d
	text " is now"
	line "holding"
	cont "@"
	TX_RAM wcf4b
	text "."
	prompt

TookHeldItemText:
	text "Took @"
	TX_RAM wcf4b
	text ""
	line "from @"
	TX_RAM wcd6d
	text "."
	prompt

BagFullHeldItemText:
	TX_FAR _NoMoreRoomForItemText
	db "@"


; the DEXREPEL: on, wild mons already caught stay away (WildRepelCheck)
ItemUseDexRepel:
	ld hl, wEventFlags + EVENT_DEXREPEL_ON / 8
	ld a, [hl]
	xor 1 << (EVENT_DEXREPEL_ON % 8)
	ld [hl], a
	and 1 << (EVENT_DEXREPEL_ON % 8)
	ld hl, DexRepelOnText
	jr nz, .print
	ld hl, DexRepelOffText
.print
	jp PrintText

DexRepelOnText:
	text "<PLAYER> turned on"
	line "the DEXREPEL!"

	para "#MON you've"
	line "caught will stay"
	cont "away."
	prompt

DexRepelOffText:
	text "<PLAYER> turned off"
	line "the DEXREPEL."
	prompt

; carry if a repel keeps the wild mon (wEnemyMonSpecies2, level
; wCurEnemyLVL) away: the DEXREPEL, if it's owned, or a REPEL, if it's lower
; level than the first party mon (wild_encounters.asm)
WildRepelCheck:
	callba ReplaceDisallowedWildMew ; a Mew that would be a Ditto is judged as one
	CheckEvent EVENT_DEXREPEL_ON
	jr z, .repel
	ld a, [wd11e]
	push af
	ld a, [wEnemyMonSpecies2]
	ld [wd11e], a
	predef IndexToPokedex
	ld a, [wd11e]
	dec a
	ld c, a
	ld hl, wPokedexOwned
	ld b, FLAG_TEST
	predef FlagActionPredef
	pop af
	ld [wd11e], a
	ld a, c
	and a
	scf
	ret nz
.repel
	ld a, [wRepelRemainingSteps]
	and a
	ret z
	ld a, [wPartyMon1Level]
	ld b, a
	ld a, [wCurEnemyLVL]
	cp b
	ret
