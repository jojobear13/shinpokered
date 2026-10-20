; tests if mon [wcf91] can learn move [wMoveNum]
CanLearnTM:
	ld a, [wcf91]
	ld [wd0b5], a
	call GetMonHeader
	ld hl, wMonHLearnset

	call SpecialMachineMove ;joenote - handle a pokemon that can learn machines not normally allowed (like surfing pikachu)
	
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

;let pikachu learn surf
;HL must equal wMonHLearnset and be called from CanLearnTM
SpecialMachineMove:
	call CheckGorgeousBox
	ret nz

	push hl
	ld a, [wcf91]
	ld b, a
	ld hl, SpecialMachineMoveList - 1
.loop
	inc hl
	ld a, [hli]
	cp $ff
	jr z, .ret_ff
	cp b
	jr nz, .loop
.end_loop
	ld a, [hl]
	pop hl

	call MachineMoveInC
	ld b, FLAG_SET
	predef_jump FlagActionPredef

.ret_ff
	pop hl
	and a
	ret
	
;ret z if the pokemon is holding a Gen 2 gorgeous box according to its catch rate
CheckGorgeousBox:
	push bc
	push hl
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1CatchRate
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hl]
	cp 168
	pop hl
	pop bc
	ret
	
SpecialMachineMoveList:
	db PIKACHU, SURF
	db DRAGONITE, FLY
	db $ff
		
INCLUDE "data/tms.asm"
