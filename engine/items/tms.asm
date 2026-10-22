; tests if mon [wcf91] can learn move [wMoveNum]
CanLearnTM:
	ld a, [wcf91]
	ld [wd0b5], a
	call GetMonHeader
	ld hl, wMonHLearnset

	call SpecialMachineMove ;joenote - handle a pokemon that can learn machines not normally allowed (like surfing pikachu)

	; TM MOVES and TM COMPAT.
	ld a, [wMoveNum]
	ld e, a
	callba RandoCanLearnTM
	ld a, e
	cp $ff
	jr z, .asTheyWere
	ld c, a
	ret
.asTheyWere
	ld hl, wMonHLearnset
	ld a, [wMoveNum]
	call MachineMoveInC
	ld b, FLAG_TEST
	predef_jump FlagActionPredef

;takes a machine move in A, finds the corresponding arry bit offset, and puts that into C
MachineMoveInC:
	push hl
	ld b, a
	ld c, $0
	ld hl, TechnicalMachines
.findTMloop
	ld a, [hli]
	cp b
	jr z, .TMfoundLoop
	inc c
	jr .findTMloop
.TMfoundLoop
	pop hl
	ret

;let pikachu learn surf, and dragonite fly: earned by a Pikachu winning the
;S.S. Anne tournament and a Dragonite leading against Lance. (Shin marked
;the mon itself with catch rate 168; that byte is the held item now, so the
;feat is an event flag and applies to the species.)
;HL must equal wMonHLearnset and be called from CanLearnTM
SpecialMachineMove:
	ld a, [wcf91]
	cp PIKACHU
	jr nz, .dragonite
	CheckEvent EVENT_SURFING_PIKACHU
	ret z
	ld a, SURF
	jr .teach
.dragonite
	cp DRAGONITE
	ret nz
	CheckEvent EVENT_FLYING_DRAGONITE
	ret z
	ld a, FLY
.teach
	call MachineMoveInC
	ld b, FLAG_SET
	predef_jump FlagActionPredef

INCLUDE "data/tms.asm"
