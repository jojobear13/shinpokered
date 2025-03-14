ReadTrainer:

; don't change any moves in a link battle
	ld a, [wLinkState]
	and a
	ret nz

; set [wEnemyPartyCount] to 0, [wEnemyPartyMons] to FF
; XXX first is total enemy pokemon?
; XXX second is species of first pokemon?
	ld hl, wEnemyPartyCount
	xor a
	ld [hli], a
	dec a
	ld [hl], a


; get the pointer to trainer data for this class
	;ld a, [wCurOpponent]
	;sub $C9 ; convert value from pokemon to trainer
	ld a,[wTrainerClass] ; joenote - just get trainer class directly
	dec a
	add a
	ld hl, TrainerDataPointers
	ld c, a
	ld b, 0
	add hl, bc ; hl points to trainer class
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wTrainerNo]
	ld b, a
; At this point b contains the trainer number,
; and hl points to the trainer class.
; Our next task is to iterate through the trainers,
; decrementing b each time, until we get to the right one.
.outer
	dec b
	jr z, .IterateTrainer
.inner
	ld a, [hli]
	and a
	jr nz, .inner
	jr .outer

; if the first byte of trainer data is FF,
; - each pokemon has a specific level
;      (as opposed to the whole team being of the same level)
; - if [wLoneAttackNo] != 0, one pokemon on the team has a special move ;joenote - not applicable to the Yellow method
; else the first byte is the level of every pokemon on the team
.IterateTrainer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joedebug - get a random 6 pkmn roster based on 1st party mon's level
	CheckEvent EVENT_90A
	jr z, .not_rand_roster
	callba GetRandRoster
	ResetEvent EVENT_90A
	jp z, .FinishUp
.not_rand_roster
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joedebug - get a random 3 pkmn roster based on 1st party mon's level
	CheckEvent EVENT_90D
	jr z, .not_rand_roster3
	callba GetRandRoster3
	jp z, .FinishUp
.not_rand_roster3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [hli]
	cp $FF ; is the trainer special?
	jr z, .SpecialTrainer ; if so, check for special moves
	ld [wCurEnemyLVL], a
	
	push hl
	callba ScaleTrainer_level	;joenote - scale the level of the non-special trainer party if active
	pop hl
	
.LoopTrainerData
	ld a, [hli]
	and a ; have we reached the end of the trainer data?
	;jr z, .FinishUp
	jr z, .AddAdditionalMoveData	;joenote - converting to Yellow version method
	ld [wcf91], a ; write species somewhere (gives flexibility in calling the species)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;adding a custom function here
	push hl
	callba RandomizeRegularTrainerMons
	callba ScaleTrainer_evolution	;joenote - scale the evolution of the non-special trainer party if active
	pop hl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, ENEMY_PARTY_DATA
	ld [wMonDataLocation], a
	push hl
	call AddPartyMon
	pop hl
	jr .LoopTrainerData
.SpecialTrainer
; if this code is being run:
; - each pokemon has a specific level
;      (as opposed to the whole team being of the same level)
; - if [wLoneAttackNo] != 0, one pokemon on the team has a special move ;joenote - not applicable to the Yellow method
	ld a, [hli]
	and a ; have we reached the end of the trainer data?
	;jr z, .AddLoneMove
	jr z, .AddAdditionalMoveData ;joenote - converting to Yellow version method
	ld [wCurEnemyLVL], a
	ld a, [hli]
	ld [wcf91], a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;adding a custom function here
	push hl
	callba ScaleTrainer
	pop hl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, ENEMY_PARTY_DATA
	ld [wMonDataLocation], a
	push hl
	call AddPartyMon
	pop hl
	jr .SpecialTrainer
	
;joenote - all this is being commented out and replaced with code for Yellow's method of doing custom trainer movesets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;.AddLoneMove
;; does the trainer have a single monster with a different move
;	ld a, [wLoneAttackNo] ; Brock is 01, Misty is 02, Erika is 04, etc
;	and a
;	jr z, .AddTeamMove
;	dec a
;	add a
;	ld c, a
;	ld b, 0
;	ld hl, LoneMoves
;	add hl, bc
;	ld a, [hli]
;	ld d, [hl]
;	ld hl, wEnemyMon1Moves + 2
;	ld bc, wEnemyMon2 - wEnemyMon1
;	call AddNTimes
;	ld [hl], d
;	jr .FinishUp
;.AddTeamMove
;; check if our trainer's team has special moves
;
;; get trainer class number
;	ld a, [wCurOpponent]
;	sub 200
;	ld b, a
;	ld hl, TeamMoves
;
;; iterate through entries in TeamMoves, checking each for our trainer class
;.IterateTeamMoves
;	ld a, [hli]
;	cp b
;	jr z, .GiveTeamMoves ; is there a match?
;	inc hl ; if not, go to the next entry
;	inc a
;	jr nz, .IterateTeamMoves
;
;; no matches found. is this trainer champion rival?
;	ld a, b
;	cp SONY3
;	jr z, .ChampionRival
;	jr .FinishUp ; nope
;.GiveTeamMoves
;	ld a, [hl]
;	ld [wEnemyMon5Moves + 2], a
;	jr .FinishUp
;.ChampionRival ; give moves to his team
;
;; pidgeot
;	ld a, SKY_ATTACK
;	ld [wEnemyMon1Moves + 2], a
;
;; starter
;	ld a, [wRivalStarter]
;	cp STARTER3
;	ld b, MEGA_DRAIN
;	jr z, .GiveStarterMove
;	cp STARTER1
;	ld b, FIRE_BLAST
;	jr z, .GiveStarterMove
;	ld b, BLIZZARD ; must be squirtle
;.GiveStarterMove
;	ld a, b
;	ld [wEnemyMon6Moves + 2], a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.AddAdditionalMoveData
; does the trainer have additional move data?

	CheckEvent EVENT_8C9
	jr z, .YellowMethodMoveData
;If event set, use alternate move list
	push hl
	push bc
	push de
	callba TrainerCustomMoves
	pop de
	pop bc
	pop hl
	jr .FinishUp
	
.YellowMethodMoveData	
	ld a, [wTrainerClass]
	ld b, a
	ld a, [wTrainerNo]
	ld c, a
	ld hl, SpecialTrainerMoves
.loopAdditionalMoveData
	ld a, [hli]
	cp $ff
	jr z, .FinishUp
	cp b
	jr nz, .asm_39c46
	ld a, [hli]
	cp c
	jr nz, .asm_39c46
	ld d, h
	ld e, l
.writeAdditionalMoveDataLoop
	ld a, [de]
	inc de
	and a
	jp z, .FinishUp
	dec a
	ld hl, wEnemyMon1Moves
	ld bc, wEnemyMon2 - wEnemyMon1
	call AddNTimes
	ld a, [de]
	inc de
	dec a
	ld c, a
	ld b, 0
	add hl,bc
	ld a, [de]
	inc de
	ld [hl], a
	jr .writeAdditionalMoveDataLoop
.asm_39c46
	ld a, [hli]
	and a
	jr nz, .asm_39c46
	jr .loopAdditionalMoveData
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

.FinishUp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - check for and load a mirror-match
	CheckAndResetEvent EVENT_8DF
	jr z, .end_mirror_match
	ld bc, wPartyDataEnd - wPartyDataStart
	ld hl, wPartyDataStart
	ld de, wEnemyPartyCount
	call CopyData
.end_mirror_match
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;joenote - prevent prize money from being capped at 9999
; clear wAmountMoneyWon addresses
	xor a
	ld [wTrainerBaseMoney - 1], a
	ld de, wAmountMoneyWon
	ld [de], a
	inc de
	ld [de], a
	inc de
	ld [de], a
	ld a, [wCurEnemyLVL]
	ld b, a
.LastLoop
; update wAmountMoneyWon addresses (money to win) based on enemy's level
	ld hl, wTrainerBaseMoney + 1
	ld c, 3 ; wAmountMoneyWon is a 3-byte number
	push bc
	predef AddBCDPredef
	pop bc
	inc de
	inc de
	inc de
	dec b
	jr nz, .LastLoop ; repeat wCurEnemyLVL times
	ret
