SSAnne6Script:
	call EnableAutoTextBoxDrawing
	
;joenote - set up tournament
	CheckEvent EVENT_90D
	jr z, .mainreturn
	ld a, [wIsInBattle]
	cp $ff	;don't continue the tournament if you lost
	jr z, .endReturn
	call ContinueTournament
.mainreturn
	ret
.endReturn
	ResetEvent EVENT_90D
	ret

SSAnne6TextPointers:
	dw SSAnne6Text1
	dw SSAnne6Text2
	dw SSAnne6Text3
	dw SSAnne6Text4
	dw SSAnne6Text5
	dw SSAnne6Text6
	dw SSAnne6Text7
	dw SSAnne6Text8	;joenote - gym guy for post-game tournament

SSAnne6Text1:
	TX_FAR _SSAnne6Text1
	db "@"

SSAnne6Text2:
	TX_FAR _SSAnne6Text2
	db "@"

SSAnne6Text3:
	TX_FAR _SSAnne6Text3
	db "@"

SSAnne6Text4:
	TX_FAR _SSAnne6Text4
	db "@"

SSAnne6Text5:
	TX_FAR _SSAnne6Text5
	db "@"

SSAnne6Text6:
	TX_FAR _SSAnne6Text6
	db "@"

SSAnne6Text7:
	TX_ASM
	ld hl, SSAnne6Text_61807
	call PrintText
	ld a, [hRandomAdd]
	bit 7, a
	jr z, .asm_93eb1
	ld hl, SSAnne6Text_6180c
	jr .asm_63292
.asm_93eb1
	bit 4, a
	jr z, .asm_7436c
	ld hl, SSAnne6Text_61811
	jr .asm_63292
.asm_7436c
	ld hl, SSAnne6Text_61816
.asm_63292
	call PrintText
	jp TextScriptEnd


SSAnne6Text8: ;joenote - gym guy for post-game tournament
	TX_ASM

	;check if your are in tournament
	CheckEvent EVENT_90D
	jr z, .promptdefaulttext
	predef HealParty
	
	;check if you won tournament
	ld a, [wUnusedD5A3]
	cp 7	;# matches to win
	jr c, .notyet
	push bc
	ld bc, $0101
	call GiveItem
	pop bc
	ld hl, SSAnne6Text_GymGuy_win
	call PrintText
	call SetSurfingPikachu
	jr .endtournament
.notyet

	;ask if continue
	ld hl, SSAnne6Text_GymGuy_keepgoing
	call PrintText
	call YesNoChoice	;ask if you want to keep going
	ld a, [wCurrentMenuItem]	
	and a	
	jr nz, .endtournament	;leave if NO
	jr .startbattle

.promptdefaulttext	
	ld hl, SSAnne6Text_GymGuy	;load default text
	CheckEvent EVENT_908
	jp z, .endprint
	ld hl, SSAnne6Text_GymGuy2	;load intro text after beating elite 4
	call PrintText
	call YesNoChoice	;ask if you want to join tournament
	ld a, [wCurrentMenuItem]	
	and a	
	jr nz, .endtournament	;leave if NO
	
	;make sure the bag isn't full
	ld a, [wNumBagItems]
	cp 20
	jr nc, .nobagroom
	
	;make sure party is 3 pkmn
	ld a, [wPartyCount]
	cp 3
	jr nz, .partynot3
	
	predef HealParty

.startbattle
	;if everything checks out, begin initiating battle with a random trainer
	SetEvent EVENT_90D	;used for the 3-pkmn tournament
	ld hl, SSAnne6Text_GymGuy_ready
	call PrintText
	ld hl, wd72d;set the bits for triggering battle
	set 6, [hl]	;
	set 7, [hl]	;
	ld hl, SSAnne6Text_GymGuy_battleend	;load text for when you win
	ld de, SSAnne6Text_GymGuy_battleend	;load text for when you lose
	call SaveEndBattleTextPointers	;save the win/lose text
	ld a, [H_SPRITEINDEX]
	ld [wSpriteIndex], a
	callba GetRandTrainer
	call InitBattleEnemyParameters
	;increment victory counter for the random trainer
	ld a, [wUnusedD5A3]
	inc a
	ld [wUnusedD5A3], a
	xor a
	ld [hJoyHeld], a
	jr .end
.partynot3
	ld hl, SSAnne6Text_GymGuy_party
	jr .endprint
.nobagroom
	ld hl, SSAnne6Text_GymGuy_noroom
	jr .endprint
.endtournament
	xor a
	ld [wUnusedD5A3], a
	ResetEvent EVENT_90D
	ld hl, SSAnne6Text_GymGuy_bye
.endprint
	call PrintText
.end
	jp TextScriptEnd
	
ContinueTournament:
	ld a, $8
	ld [hSpriteIndexOrTextID], a
	jp DisplayTextID
	
SetSurfingPikachu:
	push bc
	push hl
	ld hl, wPartyMon1Species
	ld bc, wPartyMon2 - wPartyMon1
	ld a, [hl]
	cp PIKACHU
	jr z, .set
	add hl, bc
	ld a, [hl]
	cp PIKACHU
	jr z, .set
	add hl, bc
	ld a, [hl]
	cp PIKACHU
	jr nz, .return
.set
	ld bc, $0007
	add hl, bc
	ld a, 168
	ld [hl], a
	ld hl, SSAnne6Text_GymGuy_pikachu
	call PrintText
.return
	pop hl
	pop bc
	ret
	
	
SSAnne6Text_61807:
	TX_FAR _SSAnne6Text_61807
	db "@"

SSAnne6Text_6180c:
	TX_FAR _SSAnne6Text_6180c
	db "@"

SSAnne6Text_61811:
	TX_FAR _SSAnne6Text_61811
	db "@"

SSAnne6Text_61816:
	TX_FAR _SSAnne6Text_61816
	db "@"

SSAnne6Text_GymGuy:
	TX_FAR _SSAnne6Text_GymGuy
	db "@"
SSAnne6Text_GymGuy2:
	TX_FAR _SSAnne6Text_GymGuy2
	db "@"
SSAnne6Text_GymGuy_bye:
	TX_FAR _SSAnne6Text_GymGuy_bye
	db "@"
SSAnne6Text_GymGuy_ready:
	TX_FAR _SSAnne6Text_GymGuy_ready
	db "@"
SSAnne6Text_GymGuy_battleend:
	TX_FAR _SSAnne6Text_GymGuy_battleend
	db "@"
SSAnne6Text_GymGuy_party:
	TX_FAR _SSAnne6Text_GymGuy_party
	db "@"
SSAnne6Text_GymGuy_noroom:
	TX_FAR _SSAnne6Text_GymGuy_noroom
	db "@"
SSAnne6Text_GymGuy_keepgoing:
	TX_FAR _SSAnne6Text_GymGuy_keepgoing
	db "@"
SSAnne6Text_GymGuy_win:
	TX_FAR _SSAnne6Text_GymGuy_win
	TX_SFX_ITEM_1
	db "@"
SSAnne6Text_GymGuy_pikachu:
	TX_FAR _SSAnne6Text_GymGuy_pikachu
	db "@"
