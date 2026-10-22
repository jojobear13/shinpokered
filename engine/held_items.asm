; held items: a mon's held item is in the catch-rate byte of its data (Gen 2
; did the same); 0 for none

; The enemy mon's held item, for its battle struct (written at de): a
; trainer's mon's from its party data, a wild mon's from WildHeldItems.
; Preserves de
GetEnemyHeldItem:
	ld a, [wIsInBattle]
	cp 2
	jr nz, .wild
	push de
	ld hl, wEnemyMon1CatchRate
	ld a, [wWhichPokemon]
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	pop de
	ld a, [hl]
	ld [de], a
	ret
.wild
	push de
	ld a, [wEnemyMonSpecies]
	ld b, a
	ld hl, WildHeldItems
.find
	ld a, [hli]
	cp -1
	jr z, .none
	cp b
	jr z, .found
	inc hl
	inc hl
	jr .find
.found
	call Random
	cp 59 ; 23%
	jr c, .gotItem
	inc hl
	cp 59 + 5 ; 2%
	jr c, .gotItem
.none
	ld hl, .noItem
.gotItem
	ld a, [hl]
	pop de
	ld [de], a
	ret
.noItem
	db 0

; A mon being added to a party: none, unless it's the wild mon being caught,
; which keeps its own. Written at de; preserves de
NewMonHeldItem:
	xor a
	ld [de], a
	ret

; on page 2 of the status screen: the held item, under the mon's name
PrintStatusScreenHeldItem:
	ld a, [wLoadedMonCatchRate]
	and a
	ret z
	ld [wd11e], a
	call GetItemName
	coord hl, 8, 2
	jp PlaceString

; a = 0 for the player's mon or 1 for the enemy's -> a = its held item, z if
; none; preserves bc, de and hl
GetSideItem:
	and a
	ld a, [wBattleMonCatchRate]
	jr z, .got
	ld a, [wEnemyMonCatchRate]
.got
	and a
	ret

; the held item of the mon whose turn it is, and of the other
UserItem:
	ld a, [H_WHOSETURN]
	jr GetSideItem
TargetItem:
	ld a, [H_WHOSETURN]
	xor 1
	jr GetSideItem

; a = side: its held item is used up, in battle and in its party data
; preserves de
ConsumeSideItem:
	and a
	jr nz, .enemy
	ld [wBattleMonCatchRate], a
	ld a, [wPlayerMonNumber]
	ld hl, wPartyMon1CatchRate
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld [hl], 0
	ret
.enemy
	xor a
	ld [wEnemyMonCatchRate], a
	ld a, [wIsInBattle]
	cp 2
	ret nz
	ld a, [wEnemyMonPartyPos]
	ld hl, wEnemyMon1CatchRate
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld [hl], 0
	ret

; the damage modifiers items make (stage S3, with the abilities')
ItemDamageModifiers:
	call UserItem
	call nz, .userItem
	call TargetItem
	ret z
	cp EVIOLITE
	jr nz, .notEviolite
	ld hl, wEnemyMonSpecies
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotTarget
	ld hl, wBattleMonSpecies
.gotTarget
	ld a, [hl]
	call CanEvolve
	ret nc
	lb bc, 2, 3
	jp ScaleDamage
.notEviolite
	cp METAL_POWDER
	ret nz
	call IsPhysical
	ret nz
	ld hl, wEnemyMonSpecies
	ld bc, wEnemyBattleStatus3
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotDitto
	ld hl, wBattleMonSpecies
	ld bc, wPlayerBattleStatus3
.gotDitto
	ld a, [hl]
	cp DITTO
	ret nz
	ld a, [bc]
	bit TRANSFORMED, a
	ret nz
	lb bc, 1, 2
	jp ScaleDamage

.userItem
	ld d, a
	ld a, wPlayerMoveType - wPlayerMoveNum
	call GetUserMoveField
	ld e, a ; e = the move's type
	ld hl, TypeBoostingItems
.findType
	ld a, [hli]
	and a
	jr z, .notTypeItem
	cp d
	ld a, [hli]
	jr nz, .findType
	cp e
	ret nz
	lb bc, 6, 5
	jp ScaleDamage
.notTypeItem
	ld a, d
	cp CHOICE_BAND
	jr nz, .notBand
	call IsPhysical
	ret nz
	jr .oneAndAHalf
.notBand
	cp CHOICE_SPECS
	jr nz, .notSpecs
	call IsPhysical
	ret z
.oneAndAHalf
	lb bc, 3, 2
	jp ScaleDamage
.notSpecs
	cp LIFE_ORB
	jr nz, .notLifeOrb
	lb bc, 13, 10
	jp ScaleDamage
.notLifeOrb
	call .userSpecies
	ld b, a
	ld a, d
	cp LIGHT_BALL
	jr nz, .notLightBall
	ld a, b
	cp PIKACHU
	ret nz
	jr .double
.notLightBall
	cp THICK_CLUB
	ret nz
	call IsPhysical
	ret nz
	ld a, b
	cp CUBONE
	jr z, .double
	cp MAROWAK
	ret nz
.double
	lb bc, 2, 1
	jp ScaleDamage
.userSpecies
	ld a, [H_WHOSETURN]
	and a
	ld a, [wBattleMonSpecies]
	ret z
	ld a, [wEnemyMonSpecies]
	ret

TypeBoostingItems: ; item, the type of move it boosts by 1/5
	db BLACK_BELT, FIGHTING
	db CHARCOAL, FIRE
	db DRAGON_FANG, DRAGON
	db HARD_STONE, ROCK
	db MAGNET, ELECTRIC
	db MIRACLE_SEED, GRASS
	db MYSTIC_WATER, WATER
	db NEVERMELTICE, ICE
	db PINK_BOW, NORMAL
	db POISON_BARB, POISON
	db SHARP_BEAK, FLYING
	db SILVERPOWDER, BUG
	db SOFT_SAND, GROUND
	db SPELL_TAG, GHOST
	db TWISTEDSPOON, PSYCHIC
	db METAL_COAT, STEEL
	db BLACKGLASSES, DARK
	db FAIRYFEATHER, FAIRY
	db 0

; z if the move being used is physical (hBattleSide, set by GetDamageVars)
IsPhysical:
	ld a, [hBattleSide]
	and BATTLE_SIDE_SPECIAL
	ret

; a = species -> carry if it can evolve (it has an entry in its evolutions)
CanEvolve:
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld bc, EvosMovesPointerTable
	add hl, bc
	ld de, wItemScratch
	ld bc, 2
	ld a, BANK(EvosMovesPointerTable)
	call FarCopyData
	ld hl, wItemScratch
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wItemScratch
	ld bc, 1
	ld a, BANK(EvosMovesPointerTable)
	call FarCopyData
	ld a, [wItemScratch]
	and a
	ret z ; carry clear
	scf
	ret

; [wd0b5] = a species, [wExpScratch] = its level -> carry if it could have
; evolved by level at that level (Gen 9's x1.2 experience)
PastEvolutionLevel:
	ld a, [wd0b5]
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld bc, EvosMovesPointerTable
	add hl, bc
	ld de, wEvoScratch
	ld bc, 2
	ld a, BANK(EvosMovesPointerTable)
	call FarCopyData
	ld hl, wEvoScratch
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wEvoScratch
	ld bc, EVO_SCRATCH_LENGTH
	ld a, BANK(EvosMovesPointerTable)
	call FarCopyData
	ld hl, wEvoScratch
.loop
	ld a, [hli]
	and a
	ret z ; carry clear
	cp EV_ITEM
	jr z, .item
	cp EV_LEVEL
	jr nz, .next ; a trade: its level, its species
	ld a, [wExpScratch]
	cp [hl]
	ccf
	ret c ; at or past it
.next
	inc hl
	inc hl
	jr .loop
.item ; the item, a level, the species
	inc hl
	jr .next

; Who moves first, before speed (same priority): a Quick Claw (20%) that
; goes off for one side only, else the speeds with a Choice Scarf's 1/2 more.
; Carry if decided, then nz for the player first, z for the enemy. In a link
; battle the claws roll in the order both games agree on (the internal-clock
; game's enemy is the other game's player)
ItemTurnOrder:
	ld c, 0 ; bit 0: the player's claw went off, bit 1: the enemy's
	ld a, [hSerialConnectionStatus]
	cp USING_INTERNAL_CLOCK
	jr z, .enemyFirst
	xor a
	call .claw
	ld a, 1
	call .claw
	jr .gotClaws
.enemyFirst
	ld a, 1
	call .claw
	xor a
	call .claw
.gotClaws
	ld a, c
	cp %01
	jr z, .player
	cp %10
	jr z, .enemy
; speeds, with Choice Scarves
	xor a
	call .speed
	push hl
	ld a, 1
	call .speed
	pop de ; de = the player's, hl = the enemy's
	ld a, l
	sub e
	ld a, h
	sbc d ; carry if the player is faster
	jr c, .player
	ld a, e
	cp l
	jr nz, .enemy
	ld a, d
	cp h
	jr nz, .enemy
	and a ; equal: as the game decides ties
	ret
.player
	or 1
	scf
	ret
.enemy
	xor a
	scf
	ret
; side a's Quick Claw: set its bit in c if it goes off
.claw
	ld b, a
	call GetSideItem
	cp QUICK_CLAW
	ret nz
	call BattleRandom
	cp 51 ; 20%
	ret nc
	inc b
	ld a, c
	or b
	ld c, a
	ret
; hl = side a's speed, half again with a Choice Scarf
.speed
	ld b, a
	and a
	ld hl, wBattleMonSpeed
	jr z, .gotSpeed
	ld hl, wEnemyMonSpeed
.gotSpeed
	ld a, [hli]
	ld l, [hl]
	ld h, a
	ld a, b
	call GetSideItem
	cp CHOICE_SCARF
	ret nz
	push bc
	ld b, h
	ld c, l
	srl b
	rr c
	add hl, bc
	pop bc
	ret

; The move menu: carry (having said so) if a Choice item locks the player's
; mon into another move that still has PP
PlayerChoiceLocked:
	ld a, [wPlayerChoiceLock]
	and a
	ret z
	ld b, a
	ld a, [wCurrentMenuItem]
	inc a
	cp b
	ret z ; carry clear
	ld c, b
	dec c
	ld b, 0
	ld hl, wBattleMonPP
	add hl, bc
	ld a, [hl]
	and $3f
	ret z ; the locked move is out of PP: any other goes
	ld hl, wBattleMonMoves
	add hl, bc
	ld a, [hl]
	ld [wd11e], a
	call GetMoveName
	ld hl, ChoiceLockedText
	call PrintText
	scf
	ret

; after the move of the mon whose turn it is (from AbilityAfterMove, while
; the snapshot says what the move did)
ItemsAfterMove:
	call UserFainted
	jr z, .berries
	call ChoiceLock
	call LifeOrb
	call KingsRock
	call MysteryBerry
.berries
	ld a, [H_WHOSETURN]
	xor 1
	call CheckBerries
	ld a, [H_WHOSETURN]
	jp CheckBerries

; a Choice item locks its holder into the move it used
ChoiceLock:
	call UserItem
	cp CHOICE_BAND
	jr z, .choice
	cp CHOICE_SPECS
	jr z, .choice
	cp CHOICE_SCARF
	ret nz
.choice
	xor a ; the move
	call GetUserMoveField
	cp STRUGGLE
	ret z
	ld hl, wPlayerChoiceLock
	ld de, wPlayerMoveListIndex
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotUser
	ld hl, wEnemyChoiceLock
	ld de, wEnemyMoveListIndex
.gotUser
	ld a, [hl]
	and a
	ret nz
	ld a, [de]
	inc a
	ld [hl], a
	ret

; Life Orb: a move that hit for damage costs its user 1/10 of its max HP
LifeOrb:
	call UserItem
	cp LIFE_ORB
	ret nz
	call TargetWasDamaged
	ret z
	call UserAbility
	cp MAGIC_GUARD
	ret z
	ld hl, wBattleMonMaxHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotMaxHP
	ld hl, wEnemyMonMaxHP
.gotMaxHP
	xor a
	ld [H_DIVIDEND], a
	ld [H_DIVIDEND + 1], a
	ld a, [hli]
	ld [H_DIVIDEND + 2], a
	ld a, [hl]
	ld [H_DIVIDEND + 3], a
	ld a, 10
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	ld a, [H_QUOTIENT + 2]
	ld b, a
	ld a, [H_QUOTIENT + 3]
	ld c, a
	or b
	jr nz, .gotAmount
	inc c
.gotAmount
	ld a, [H_WHOSETURN]
	call HurtMon
	ld hl, LifeOrbText
	jp PrintText

; King's Rock: a 10% chance to make the target flinch, as Stench (they don't
; add up)
KingsRock:
	call UserItem
	cp KINGS_ROCK
	ret nz
	call UserAbility
	cp STENCH
	ret z
	jp StenchFlinch

; MysteryBerry: a move left with no PP gets 5 back. Not in a link battle:
; there each game spends only its own player's PP, so the other game would
; never see the move run out, and the two would disagree on the berry
MysteryBerry:
	ld a, [wLinkState]
	cp LINK_STATE_BATTLING
	ret z
	call UserItem
	cp MYSTERYBERRY
	ret nz
	xor a ; the move
	call GetUserMoveField
	cp STRUGGLE
	ret z
	ld hl, wBattleMonPP
	ld de, wPlayerMoveListIndex
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotUser
	ld hl, wEnemyMonPP
	ld de, wEnemyMoveListIndex
.gotUser
	ld a, [de]
	ld c, a
	ld b, 0
	add hl, bc
	ld a, [hl]
	and $3f
	ret nz
	ld a, [hl]
	add 5
	ld [hl], a
	ld a, [H_WHOSETURN]
	and a
	jr nz, .consume
	ld a, [wPlayerBattleStatus3]
	bit TRANSFORMED, a
	jr nz, .consume
	push bc
	ld a, [wPlayerMonNumber]
	ld hl, wPartyMon1PP
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	pop bc
	add hl, bc
	ld a, [hl]
	add 5
	ld [hl], a
.consume
	ld a, [H_WHOSETURN]
	push af
	call ConsumeSideItem
	pop af
	ld b, MYSTERYBERRY
	ld hl, BerryPPRestoredText
	jp PrintSideItemText

; a = side: Leftovers, and berries, for the mon whose turn it is (H_WHOSETURN)
; as its residual damage comes
ItemResidual:
	call UserFainted
	ret z
	call UserItem
	cp LEFTOVERS
	jr nz, .berries
	ld hl, wBattleMonHP
	ld a, [H_WHOSETURN]
	and a
	jr z, .gotHP
	ld hl, wEnemyMonHP
.gotHP
	ld a, [hli]
	ld b, a
	ld a, [hli]
	ld c, a
	ld de, wBattleMonMaxHP - (wBattleMonHP + 2)
	add hl, de
	ld a, [hli]
	cp b
	jr nz, .heal
	ld a, [hl]
	cp c
	jr z, .berries ; full HP
.heal
	dec hl
	ld a, [hli]
	ld b, a
	ld c, [hl]
	ld a, 4
.divideBy16
	srl b
	rr c
	dec a
	jr nz, .divideBy16
	ld a, b
	or c
	jr nz, .gotAmount
	inc c
.gotAmount
	ld a, [H_WHOSETURN]
	call HealMon
	ld a, [H_WHOSETURN]
	ld b, LEFTOVERS
	ld hl, ItemRegainedHealthText
	call PrintSideItemText
.berries
	ld a, [H_WHOSETURN]
	; fall through

; a = side: eats its berry if the berry's moment has come
CheckBerries:
	ld e, a
	push de
	ld a, e
	call GetSideItem
	pop de
	ret z
	ld d, a ; d = the item, e = the side
	ld hl, wBattleMonHP
	ld bc, wBattleMonStatus
	ld a, e
	and a
	jr z, .gotMon
	ld hl, wEnemyMonHP
	ld bc, wEnemyMonStatus
.gotMon
	ld a, [hli]
	or [hl]
	ret z ; fainted
	ld a, d
	cp BERRY
	jr z, .hpBerry
	cp GOLD_BERRY
	jr z, .hpBerry
	cp SITRUS_BERRY
	jr z, .hpBerry
; status berries: b = the statuses it cures, -1 for confusion too
	ld hl, StatusBerries
.find
	ld a, [hli]
	and a
	ret z
	cp d
	ld a, [hli]
	jr nz, .find
	ld h, a ; h = the status bits it cures
	ld a, [bc]
	and h
	jr nz, .cure
	ld a, h
	cp $ff ; MIRACLEBERRY: confusion too
	jr z, .confusion
	cp 1 << 7 ; BITTER_BERRY: confusion only
	ret nz
.confusion
	ld hl, wPlayerBattleStatus1
	ld a, e
	and a
	jr z, .gotStatus1
	ld hl, wEnemyBattleStatus1
.gotStatus1
	bit CONFUSED, [hl]
	ret z
	res CONFUSED, [hl]
	jr .cured
.cure
; as the mon whose turn it is, for the stat penalties and the texts
	ld a, [H_WHOSETURN]
	push af
	ld a, e
	ld [H_WHOSETURN], a
	push bc
	push de
	callab UndoBurnParStats
	pop de
	pop bc
	pop af
	ld [H_WHOSETURN], a
	xor a
	ld [bc], a
	ld hl, wPlayerBattleStatus3
	ld a, e
	and a
	jr z, .gotStatus3
	ld hl, wEnemyBattleStatus3
.gotStatus3
	res BADLY_POISONED, [hl]
.cured
	ld a, e
	push de
	call ConsumeSideItem
	pop de
	ld a, e
	ld b, d
	ld hl, AbilityCuredUserText
	jp PrintSideItemText
.hpBerry
; at half its max HP or less
	push de
	dec hl
	ld a, [hli]
	ld b, a
	ld c, [hl]
	ld de, wBattleMonMaxHP - (wBattleMonHP + 1)
	add hl, de
	ld a, [hli]
	ld d, a
	ld e, [hl] ; de = max HP
	ld h, b
	ld l, c
	add hl, hl ; 2 x HP
	ld a, e
	sub l
	ld a, d
	sbc h
	ld h, d
	ld l, e ; hl = max HP
	pop de
	ret c ; more than half
	ld a, d
	ld bc, 10
	cp BERRY
	jr z, .gotAmount
	ld c, 30
	cp GOLD_BERRY
	jr z, .gotAmount
	srl h
	rr l
	srl h
	rr l
	ld b, h
	ld c, l ; a quarter of max HP
.gotAmount
	push de
	ld a, e
	call HealMon
	pop de
	push de
	ld a, e
	call ConsumeSideItem
	pop de
	ld a, e
	ld b, d
	ld hl, ItemRegainedHealthText
	; fall through

; Prints "<mon>'s <item>!" and then the text at hl, for side a's mon
; (b = the item)
PrintSideItemText:
	push hl
	ld e, a
	ld a, [H_WHOSETURN]
	push af
	ld a, e
	ld [H_WHOSETURN], a
	ld a, b
	ld [wd11e], a
	call GetItemName
	ld hl, ItemActivatedText
	call PrintText
	pop af
	pop hl
	push af
	call PrintText
	pop af
	ld [H_WHOSETURN], a
	ret

StatusBerries: ; berry, the status bits it cures ($80: confusion, $ff: all)
	db PRZCUREBERRY, 1 << PAR
	db MINT_BERRY, SLP
	db PSNCUREBERRY, 1 << PSN
	db ICE_BERRY, 1 << BRN
	db BURNT_BERRY, 1 << FRZ
	db BITTER_BERRY, 1 << 7
	db MIRACLEBERRY, $ff
	db 0

ItemActivatedText:
	text "<USER>'s"
	line "@"
	TX_RAM wcd6d
	text "!"
	prompt

ItemRegainedHealthText:
	TX_FAR _RegainedHealthText
	db "@"

BerryPPRestoredText:
	text "Its PP was"
	line "restored!"
	prompt

LifeOrbText:
	text "<USER>"
	line "lost some of"
	cont "its HP!"
	prompt

ChoiceLockedText:
	text "Its CHOICE item"
	line "allows only"
	cont "@"
	TX_RAM wcd6d
	text "!"
	prompt

; Exp. Share: a party mon holding one counts as having fought (wPartyGainExpFlags),
; and gains experience with those that did
ExpShareHolders:
	ld a, [wPartyCount]
	and a
	ret z
	ld d, a
	ld e, 0 ; party position
	ld hl, wPartyMon1CatchRate
.loop
	ld a, [hl]
	cp EXP_SHARE
	jr nz, .next
	push hl
	push de
	ld c, e
	ld b, FLAG_SET
	ld hl, wPartyGainExpFlags
	predef FlagActionPredef
	pop de
	pop hl
.next
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc
	inc e
	dec d
	jr nz, .loop
	ret

; Amulet Coin: a trainer's prize money doubles when a party mon holds one
AmuletCoinMoney:
	ld a, [wPartyCount]
	and a
	ret z
	ld d, a
	ld hl, wPartyMon1CatchRate
	ld bc, wPartyMon2 - wPartyMon1
.loop
	ld a, [hl]
	cp AMULET_COIN
	jr z, .double
	add hl, bc
	dec d
	jr nz, .loop
	ret
.double
	ld de, wAmountMoneyWon + 2
	ld hl, wAmountMoneyWon + 2
	ld c, 3
	predef_jump AddBCDPredef

INCLUDE "data/wild_held_items.asm"

; the items the gym leaders', the Elite Four's and the Champion's mons hold
; (TrainerHeldItemsData), after their party is read
TrainerHeldItems:
	ld hl, TrainerHeldItemsData
.find
	ld a, [hli]
	and a
	ret z
	ld b, a
	ld a, [wTrainerClass]
	cp b
	ld a, [hli]
	ld c, [hl] ; c = how many
	inc hl
	jr nz, .next
	ld b, a
	ld a, [wTrainerNo]
	cp b
	jr z, .found
.next
	ld b, 0
	add hl, bc
	jr .find
.found
	ld de, wEnemyMon1CatchRate
.loop
	ld a, [hli]
	ld [de], a
	push hl
	ld hl, wEnemyMon2 - wEnemyMon1
	add hl, de
	ld d, h
	ld e, l
	pop hl
	dec c
	jr nz, .loop
	ret

INCLUDE "data/trainer_held_items.asm"

; Load the mart inventory numbered [wItemScratch] into wItemList.
LoadMartInventory:
	ld a, [wItemScratch]
	add a
	ld e, a
	ld d, 0
	ld hl, MartInventories
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call LoadItemList
	jpba RandoMart ; or the randomizer's list

INCLUDE "data/mart_lists.asm"

; Pickup: after a battle (not a link battle), each party mon with it that
; holds nothing picks up an item 10% of the time, without a message. Gen 3's
; items and odds.
PartyPickup:
	ld hl, wPartyMon1
	ld a, [wPartyCount]
	ld b, a
	inc b
.loop
	dec b
	ret z
	push bc
	push hl
	ld de, wPartyMon1CatchRate - wPartyMon1
	add hl, de
	ld a, [hl]
	and a
	jr nz, .next
	ld d, h
	ld e, l ; de = the held item
	pop hl
	push hl
	ld bc, wPartyMon1IVs + IV_FLAGS - wPartyMon1
	add hl, bc
	ld c, [hl]
	pop hl
	push hl
	ld a, [hl] ; species
	call GetMonAbility
	cp PICKUP
	jr nz, .next
	call Random
	cp 26 ; 10%
	jr nc, .next
	call Random
	ld c, a
	ld hl, PickupItems
.find
	ld a, [hli]
	and a
	jr z, .found ; the last one
	ld b, a
	ld a, c
	cp b
	jr c, .found
	inc hl
	jr .find
.found
	ld a, [hl]
	ld [de], a
.next
	pop hl
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc
	pop bc
	jr .loop

PickupItems: ; below this random number (of 256), this item; 0 for the rest
	db 77, SUPER_POTION  ; 30%
	db 103, FULL_HEAL    ; 10%
	db 129, ULTRA_BALL   ; 10%
	db 155, RARE_CANDY   ; 10%
	db 181, FULL_RESTORE ; 10%
	db 207, REVIVE       ; 10%
	db 233, NUGGET       ; 10%
	db 246, PROTEIN      ; 5%
	db 253, PP_UP        ; 3%
	db 0, KINGS_ROCK     ; 1%
