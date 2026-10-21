;the Mew-to-Ditto swap alone, without marking Mew as met, so a repel judges
;the mon that would really appear (WildRepelCheck)
ReplaceDisallowedWildMew:
	ld a, [wcf91]
	cp MEW
	ret nz
	CheckEvent EVENT_90B
	jr z, DisallowWildMew.replace_mew
	CheckEvent EVENT_8C0
	ret z
	jr DisallowWildMew.replace_mew

;replace random mew encounters with ditto if dex diploma not attained
DisallowWildMew:
	ld a, [wcf91]	;get the current pokemon in question
	cp MEW	;is it mew? zet zero flag if true
	ret nz	;if not mew, then return
	;else we have a potential mew encounter on our hands
	CheckEvent EVENT_90B
	jr z, .replace_mew	;if event 90B is zero, then diploma has not been granted. mew is not allowed.
	CheckEvent EVENT_8C0
	jr z, .mew_allowed	;mew can appear if not already encountered
.replace_mew
	ld a, DITTO	;load the ditto constant
	ld [wcf91], a	;overwrite mew with ditto
	ld [wEnemyMonSpecies2], a
	ret
.mew_allowed
;	;the slot that triggered the mew encounter has it's likelihood of a mew cut in half
;	;idea is to give mew a 0.6% encounter rate (lowest in the game)
;	ld a, [hRandomSub]
;	bit 0, a
;	jr nz, .replace_mew
	;going to encounter mew now
	SetEvent EVENT_8C0 ;mew has been encountered now
	ResetEvent EVENT_8C2 ;turn on mew notification
	ret

	
	

CheckIfPkmnReal:
;set the carry if pokemon number in 'a' is found on the list of legit pokemon
	push hl
	push de
	push bc
	ld hl, ListRealPkmn
	ld de, $0001
	call IsInArray
	pop bc
	pop de
	pop hl

;This function loads a random trainer class (value of $01 to $2F)
GetRandTrainer:
.reroll
	call Random
	and $30
	cp $30
	jr z, .reroll
	push bc
	ld b, a
	call Random
	and $0F
	add b
	pop bc
	and a
	jr z, .reroll
	add $C8
	ld [wEngagedTrainerClass], a
	ld a, 1
	ld [wEngagedTrainerSet], a
	ret

;gets a random pokemon and puts its hex ID in register a and wcf91
GetRandMonAny:
	ld de, ListRealPkmn
	;fall through
GetRandMon:
	push hl
	push bc
	ld h, d
	ld l, e
	call Random
	ld b, a
.loop
	ld a, b
	and a
	jr z, .endloop
	inc hl
	dec b
	ld a, [hl]
	and a
	jr nz, .loop
	ld h, d
	ld l, e
	jr .loop
.endloop
	ld a, [hl]
	pop bc
	pop hl
	ld [wcf91], a
	ret
	
;generates a randomized 6-party enemy trainer roster
GetRandRoster:
	push bc
	push de
	ld b, 6
	ld de, ListNonMythPkmn
	CheckEvent EVENT_90B	;check for diploma
	jp z, GetRandRosterLoop	;no mew if no diploma
	ld de, ListRealPkmn
	jp GetRandRosterLoop
GetRandRoster3:	;3-mon party
	push bc
	push de
	ld de, ListNonMewPkmn
	ld b, 3
GetRandRosterLoop:
	call GetHighestLevel

	push bc
	ld b, a
	ld c, 4
.calibrate1	;subtract 3 from the highest party level or make it zero if it underflows
	ld a, b
	dec c
	sub c
	jr c, .calibrate1
	ld b, a	
.calibrate2
	call Random
	and %11
	add b	;add 0 to 3 to the adjusted highest party level
	cp 2
	jr c, .calibrate2	;do not allow the adjusted highest party level to be less than 2
	pop bc
	
.loadbaselvl	
	ld [wCurEnemyLVL], a

.loop	
	push bc
	push de
	call GetRandMon
	ld a, ENEMY_PARTY_DATA
	ld [wMonDataLocation], a
	
	push hl
	call ScaleTrainer
	pop hl
	
	push hl
	call AddPartyMon
	call Random
	and $01
	ld b, a
	ld a, [wCurEnemyLVL]
	add b
	call PreventARegOverflow
	ld [wCurEnemyLVL], a
	pop hl
	
	pop de
	pop bc
	dec b
	jr nz, .loop
;end of loop
	pop de
	pop bc
	xor a	;set the zero flag before returning
	ret	



GetWeightedLevel:
	ld a, [wPartyCount]
	dec a
	jp z, GetHighestLevel

	push hl
	push bc
	push de
	
	ld hl, wWeightedLevelScratch+5	;need 6 bytes of working space
	
	ld de, wStartBattleLevels
	ld a, [wPartyCount]
	ld c, a
.loop
	ld a, [de]
	ld [hld], a
	inc de
	dec c
	jr nz, .loop

	ld a, [wPartyCount]
	ld c, a
.loop2
	inc hl
	dec c
	jr nz, .loop2
	
	ld d, h
	ld e, l
	
.sortingpass
	ld h, d
	ld l, e
	ld a, [wPartyCount]	;if in this sorting pass loop, then this number is 2 to 6
	dec a
	ld c, a
.loop3A
	ld a, [hld]
	cp [hl]
	jr c, .swapping
	dec c
	jr z, .weight	;if an entire pass was made with no swapping, then the bytes are sorted
	jr .loop3A
.swapping
	;current [HL] is greater than [HL+1] which is in A
	;need to swap them
	ld b, a
	ld a, [hli]
	ld [hld], a
	ld a, b
	ld [hl], a
	;did the swap
	;if this is the end of the pass, do another pass
	dec c
	jr z, .sortingpass
	;else keep looping through this pass
.loop3B
	ld a, [hld]
	cp [hl]
	jr c, .swapping
	dec c
	jr z, .sortingpass	;if the pass is complete, then then do another pass because a swap was done
	jr .loop3B
	
.weight
	ld h, d
	ld l, e
	ld a, [wPartyCount]
	ld c, a
	dec c	
	ld d, 1
	ld e, 1
.loop4
	dec hl
	ld a, [hl]
.loop4sub1
	srl a
	dec e
	jr nz, .loop4sub1
	ld [hl], a
	inc d
	ld e, d
	dec c
	jr nz, .loop4

.summation
	ld de, $0000
	ld a, [wPartyCount]
	ld c, a
.loop5
	ld a, [hli]
	add e
	ld e, a
	ld a, d
	adc d
	ld d, a
	dec c
	jr nz, .loop5	

.multiplication	;do x32
	ld c, 5
.loop6
	sla e
	rl d
	dec c
	jr nz, .loop6

.prepareDividend
	ld a, d
	ld [H_DIVIDEND+0], a
	ld a, e
	ld [H_DIVIDEND+1], a
	xor a
	ld [H_DIVIDEND+2], a
	ld [H_DIVIDEND+3], a

.getdivisor
	ld a, [wPartyCount]
	ld c, a
	dec c
	ld a, 32
	ld b, 32
.loop7
	srl b
	add b
	dec c
	jr nz, .loop7
	ld [H_DIVISOR], a

	ld b, 2
	call Divide
	ld a, [H_QUOTIENT+3]
	
	pop de
	pop bc
	pop hl
	ret
	

	
GetHighestLevel:	;gets the highest party level into A
	push hl
	push bc
	ld hl, wStartBattleLevels
	ld a, [wPartyCount]	;1 to 6
	ld b, a	;use b for countdown
.loadHigher
	ld a, [hl]
.keepCurrent
	dec b
	jr z, .highestLVLfound
	inc hl
	cp a, [hl]
	jr c, .loadHigher
	jr .keepCurrent
.highestLVLfound
	pop bc
	pop hl
	ret
	
	
;implement a function to scale trainer levels
ScaleTrainer:
	call ScaleTrainer_level
	call ScaleTrainer_evolution
	ret
	
ScaleTrainer_level:
	CheckEvent EVENT_90C
	ret z
	push bc

	ld a, [wGymLeaderNo]
	and a
	jr nz, .hard	;if fighting a boss like a gym leader, use the harder level scaling
	ld a, [wOptions]
	bit BIT_BATTLE_HARD, a
	jr z, .normal	;if it's a regular trainer but playing on hard mode, use the harder level scaling
.hard
	call GetHighestLevel
	jr .got_level
.normal
	call GetWeightedLevel
.got_level
	push af
	ld a, [wCurEnemyLVL]
	ld b, a
	pop af
	
	;at this line, B holds current enemy level and A holds highest/weighted party level
	cp b
	pop bc
	ret c
	ret z
	
	push bc
	ld [wCurEnemyLVL], a
	call Random
	and $03
	ld b, a
	ld a, [wGymLeaderNo]
	and a
	jr z, .notboss
	ld a, [wCurEnemyLVL]
	add b
	call PreventARegOverflow
	ld [wCurEnemyLVL], a
	call Random
	and $03
	ld b, a
.notboss
	ld a, [wCurEnemyLVL]
	add b
	call PreventARegOverflow
	ld [wCurEnemyLVL], a
	pop bc
	ret

ScaleTrainer_evolution:
	CheckEvent EVENT_90C
	ret z
	
	push bc
	ld a, [wCurEnemyLVL]
	ld b, a
	;proceed to bias the enemy mon level against evolving for the sake of progression balance
	;B holds the enemy current level at this line
	push af
	cp 30
	jr c, .next
	srl b
.next
	srl b
	srl b
	sub b
	ld [wCurEnemyLVL], a
	call EnemyMonEvolve
	pop af
	ld [wCurEnemyLVL], a
	pop bc
	ret


; return a = 0 if not in safari zone, else a = 1 if in safari zone
IsInSafariZone:
	ld a, [wCurMap]
	cp SAFARI_ZONE_EAST
	jr c, .notSafari
	cp SAFARI_ZONE_REST_HOUSE_1
	jr nc, .notSafari
	ld a, $01
	jr .return
.notSafari
	ld a, $00
.return
	and a
	ret

;Generate a random mon for an expanded safari zone roster
GetRandMonSafari:
	;return if special safari zone not activated
	CheckEvent EVENT_90F
	ret z	
	;return if not in safari zone
	call IsInSafariZone
	ret z
	;else continue on
	call Random
	cp 26
	ret nc	;only a 26/256 chance to have an expanded encounter
	push hl
	push bc
	call GetSafariList
	call Random
	ld b, a
.loop
	ld a, b
	and a
	jr z, .endloop
	inc hl
	dec b
	ld a, [hl]
	and a
	jr nz, .loop
	call GetSafariList
	jr .loop
.endloop
	ld a, [hl]
	pop bc
	pop hl
	ld [wcf91], a
	ld [wEnemyMonSpecies2], a
	ret	

GetSafariList:	
	ld a, [wCurMap]
	cp SAFARI_ZONE_CENTER
	ld hl, ListNonLegendPkmn
	ret z
	cp SAFARI_ZONE_EAST
	ld hl, ListMidEvolvedPkmn
	ret z
	cp SAFARI_ZONE_NORTH
	ld hl, ListNonEvolvingPkmn
	ret z
	ld hl, ListMostEvolvedPkmn
	ret
	

;this will prevent an overflow of the A register
;typically for custom functions that increase enemy levels
;defaulted to 255 on an overflow
;call after a value was just added to register A
PreventARegOverflow:
	ret nc	;return if there was no overflow
	;else set A to the max
	ld a, $FF
	ret


;randomizes the 'mon in wcf91 to an unevolved 'mon then tries to evolve it	
;A bias is applied so that trainer 'mons need more levels to evolve
;Also, the stronger end of unevolved pokemon will only show up in level-30 or higher trainer teams
RandomizeRegularTrainerMons:
	CheckEvent EVENT_8D8
	ret z
	push de
	ld de, ListNonLegendUnEvoPkmn_early
	ld a, [wCurEnemyLVL]
	push af
	ld b, a
	cp 30
	jr c, .check15
	ld de, ListNonLegendUnEvoPkmn
	srl b
	jr .next
.check15
	cp 15
	jr c, .next
	ld de, ListNonLegendUnEvoPkmn_mid
.next
	srl b
	srl b
	sub b
	ld [wCurEnemyLVL], a
	call GetRandMon
	call EnemyMonEvolve
	pop af
	ld [wCurEnemyLVL], a
	pop de
	ret


;joenote - evolve an enemy mon in wcf91 based on wCurEnemyLVL
EnemyMonEvolve:
	ld hl, EvosMovesPointerTable	;load the address of the pointer table, and worry about the bank later
	ld b, 0
	ld a, [wcf91]
	dec a
	add a
	rl b
	ld c, a		;BC now contains the pokemon's offset in the pointer table
	add hl, bc	;and HL now points to the correct position in the pointer table
	ld de, wEvosMoves
	ld a, BANK(EvosMovesPointerTable)
	ld bc, 2
	call FarCopyData	;switches banks, then copies the 2-byte address that HL points to into wEvosMoves
	ld hl, wEvosMoves	;let's now point HL to said address
	ld a, [hli]
	ld h, [hl]
	ld l, a				;HL now points to the address of the pokemon's evolution list
	ld de, wEvosMoves
	ld a, BANK(EvosMovesPointerTable)
	ld bc, wEvosMoves.end - wEvosMoves
	call FarCopyData	;now copy the evolution list pointed to by HL into wEvosMoves
	ld hl, wEvosMoves	;we can now reference the evolution list by pointing HL to it
	
.evoloop
	ld a, [hli]
	and a
	ret z
	cp EV_LEVEL
	jr z, .lvl_evolve
	cp EV_TRADE
	jr z, .trade_evolve
	;else item evolve
	inc hl
	;only item evolve if lvl 35 or more
	ld b, 35
	ld a, [wCurEnemyLVL]
	cp b
	jr nc, .lvl_evolve ;after incrementing hl one space, maintains the same structure as lvl evolving
.trade_evolve
	inc hl	;increment to see if it level or stone evolves instead
	inc hl
	jr .evoloop

.lvl_evolve
	ld a, [wcf91]
	cp EEVEE	;deal with eevee separately
	jr z, .handleeevee
	ld a, [hli]
	ld b, a
	ld a, [wCurEnemyLVL]
	cp b
	ret c
	ld a, [hl]
	ld [wcf91], a
	jp EnemyMonEvolve

.handleeevee
	call Random
	and $0F
	cp $03
	ret c	;eevee
	push af
	ld a, FLAREON
	ld [wcf91], a
	pop af
	cp $07
	ret c ;flareon
	push af
	ld a, VAPOREON
	ld [wcf91], a
	pop af
	cp $0B
	ret c ;vaporeon
	;else jolteon
	ld a, JOLTEON
	ld [wcf91], a
	ret
	

