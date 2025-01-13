;universally prints the play clock
PrintPlayTime:	;joenote - moved this into a predef
	call GetPredefRegisters

	ld a, [wPlayTimeMaxed]
	push af
	ld a, [wPlayTimeHours]
	push af

	push de
	ld e, a
	ld a, [wPlayTimeMaxed]
	ld [wPlayTimeHours], a
	ld a, e
	ld [wPlayTimeMaxed], a
	ld de, wPlayTimeHours
	lb bc, 2, 5
	call PrintNumber
	pop de

	pop af
	ld [wPlayTimeHours], a
	pop af
	ld [wPlayTimeMaxed], a

	ld a, d
	ld [hl], a
	inc hl
	ld de, wPlayTimeMinutes
	lb bc, LEADING_ZEROES | 1, 2
	jp PrintNumber



;sets both of the vermilion gym switches at the same time
DetermineVermilionGymSwitches:
;do first switch
	call Random
	and $e
	ld [wFirstLockTrashCanIndex], a
	
;do second switch
;did some improvements to this so it works better
	ld hl, GymTrashCans
	ld a, [wFirstLockTrashCanIndex]
	; multiply by 5
	ld b, a
	add a
	add a
	add b
	
	ld d, 0
	ld e, a
	add hl, de
	ld a, [hli]
	ld [hGymTrashCanRandNumMask], a

	push hl
	ld a, [hGymTrashCanRandNumMask]
	ld b, a
.tryagain
	call Random
	swap a
	and $03
	cp b
	jr nc, .tryagain
	pop hl

	ld d, 0
	ld e, a
	add hl, de
	ld a, [hl]
	and $f
	ld [wSecondLockTrashCanIndex], a	
	ret
GymTrashCans:
; byte 0: mask for random number
; bytes 1-4: indices of the trash cans that can have the second lock
; Note that the mask is simply the number of valid trash can indices that
; follow. The remaining bytes are filled with 0 to pad the length of each entry
; to 5 bytes.
	db 2,  1,  3,  0,  0 ; 0
	db 3,  0,  2,  4,  0 ; 1
	db 2,  1,  5,  0,  0 ; 2
	db 3,  0,  4,  6,  0 ; 3
	db 4,  1,  3,  5,  7 ; 4
	db 3,  2,  4,  8,  0 ; 5
	db 3,  3,  7,  9,  0 ; 6
	db 4,  4,  6,  8, 10 ; 7
	db 3,  5,  7, 11,  0 ; 8
	db 3,  6, 10, 12,  0 ; 9
	db 4,  7,  9, 11, 13 ; 10
	db 3,  8, 10, 14,  0 ; 11
	db 2,  9, 13,  0,  0 ; 12
	db 3, 10, 12, 14,  0 ; 13
	db 2, 11, 13,  0,  0 ; 14


;Sets the CPU speed of the GBC back to normal
SingleCPUSpeed:
	ld a, [hGBC]
	and a
	jr z, .return	;double speed is only a GBC feature
	ld a, [rKEY1]
	and %10000000
	call nz, ToggleCPUSpeed
.return
	call GetPredefRegisters
	ret
;Set the cpu speed in GBC mode based on if 60fps mode is active
SetCPUSpeed:
	ld a, [hGBC]
	and a
	jr z, .return	;double speed is only a GBC feature
	
	ld a, [wUnusedD721]
	and %00010000
	rlca
	rlca
	rlca
	ld b, a
	ld a, [rKEY1]
	and %10000000
	cp b
	call nz, ToggleCPUSpeed
.return
	call GetPredefRegisters
	ret
;Toggles between 2x and 1x cpu speed
ToggleCPUSpeed:
	di
	ld a, [rIE]
	push af
	xor a
	ld [rIE], a
	ld [rIF], a
	ld a, $30
	ld [rJOYP], a
	ld a, $01
	ld [rKEY1], a
	stop
	pop af
	ld [rIE], a
	ei
	ret

;Convert a value from the 1st party pkmn into a normalized BCD-value score stored in wcd6d+1 & wcd6d+2
;takes a number loaded into wcd6d to determine value:
;	1 is catch rate
;	2 is level
;	default is DVs
Mon1BCDScore:
	push de
	push hl
	push bc
	ld a, [wcd6d]

	cp 2
	jr nz, .next1
	;make a = 1 * wPartyMon1Level
	ld a, [wPartyMon1Level]
	jr .AddToTotal

.next1
	cp 1
	jr nz, .default
	;calculate a = $FF - wPartyMon1CatchRate
	ld a, [wPartyMon1CatchRate]
	ld b, a
	ld a, $FF
	sub b
	jr .AddToTotal

.default
	;calculate a = $00 to $FF based on average of DVs
	ld a, [wPartyMon1DVs]	;load first two nybbles of DVs
	call .add_nybbles
	push bc
	ld a, [wPartyMon1DVs + 1]	;load second two nybbles of DVs
	call .add_nybbles
	ld a, b
	srl a	;a = mean of first two nybbles
	pop bc
	srl b	;b = mean of second two nybbles
	add b
	srl a	;a = mean of all four nybbles
	ld b, a
	swap a
	add b	;use mean to make a byte of 00,11,22...,EE,FF

.AddToTotal
	;double the score and return it
	ld b, a
	xor a
	ld [hCoins], a
	ld [hCoins + 1], a
	ld [wcd6d], a
	ld [wcd6d + 1], a
	ld [wcd6d + 2], a
	
	ld a, b
	ld hl, hCoins
	call Hex2BCD
	
	ld de, wcd6d + 2
	ld hl, hCoins + 1
	ld c, $2
	predef AddBCDPredef	;add value in hl location to value in de location
	ld de, wcd6d + 2
	ld hl, hCoins + 1
	ld c, $2
	predef AddBCDPredef	;add value in hl location to value in de location

	xor a
	ld [hCoins], a
	ld [hCoins + 1], a

	pop bc
	pop hl
	pop de
	ret
.add_nybbles
	;get first nybble
	push af
	and $F0
	swap a
	ld b, a
	pop af
	;add second nybble
	push af
	and $0F
	add b
	ld b, a
	pop af
	ret

	
;play cry if the 1st pokemon has payday in its move set
LuckySlotDetect:
	push hl
	ld b, NUM_MOVES + 1
	ld hl, wPartyMon1Moves
.loop
	dec b
	jr z, .return
	ld a, [hli]
	cp PAY_DAY
	jr nz, .loop
	ld a, [wPartyMon1Species]
	call PlayCry
.return
	pop hl
	ret
	

;this function makes glitched pokemon names stable by restoring them back to the normal nickname format
;this is called from GetPartyMonName
; FixNickNames:
	; ld c, 1
	; ld h, d
	; ld l, e
	; ld a, [hl]
	; cp $50
	; jr z, .notvalid
; .loop
	; ld a, c
	; cp NAME_LENGTH
	; jr z, .finish
	; ld a, [hl]
	
	; cp $50
	; jr z, .eol
	
	; cp $7F
	; jr c, .notvalid
	
	; cp $F6
	; jr nc, .notvalid
	
	; cp $E1
	; jr nc, .valid
	
	; cp $C0
	; jr c, .valid

; .notvalid
	; ld [hl], $F1
; .valid
	; inc hl
	; inc c
	; jr .loop

; .finish
	; ld a, [hl]
	; cp $50
	; ret z
	; ld [hl], $50
	; ret
	
; .eol
	; inc c
	; inc hl
	; ld a, c
	; cp NAME_LENGTH
	; jr z, .finish
	; ld [hl], $50
	; jr .eol
	
	
Hex2BCD:	;convert number in A to BCD in HL
	ld [H_DIVIDEND + 3], a
	xor a
	ld [H_DIVIDEND], a
	ld [H_DIVIDEND + 1], a
	ld [H_DIVIDEND + 2], a
	ld a, 100
	ld [H_DIVISOR], a
	ld b, $4
	call Divide
	ld a, [H_QUOTIENT + 3]
	ld [hli], a
	ld a, [H_REMAINDER]
	ld [H_DIVIDEND + 3], a
	ld a, 10
	ld [H_DIVISOR], a
	ld b, $4
	call Divide
	ld a, [H_QUOTIENT + 3]
	swap a
	ld b, a
	ld a, [H_REMAINDER]
	add b
	ld [hl], a
	ret


;returns z if not owned and nz if owned
IsEnemyMonOwned:
	push de
	ld a, [wEnemyMonSpecies]
	ld [wd11e], a
	predef IndexToPokedex
	callba IsPokemonOwnedBitSet
	pop de
	ret
	
;play an enemy mon's cry if it's already owned in the dex
CryIfOwned:
	call IsEnemyMonOwned
	ret z	;return if not owned
	ld a, [wEnemyMonSpecies]
	call PlayCry
	ret
	

; This function called to store PKMN Levels. Usually at the beginning of battle.
StorePKMNLevels:
	push hl
	push de
	ld a, [wPartyCount]	;1 to 6
	ld b, a	;use b for countdown
	ld hl, wPartyMon1Level
	ld de, wStartBattleLevels
.loopStorePKMNLevels
	ld a, [hl]
	ld [de], a	
	dec b
	jr z, .doneStorePKMNLevels
	push bc
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc
	inc de
	pop bc
	jr .loopStorePKMNLevels
.doneStorePKMNLevels
	pop de
	pop hl
	ret

	
;joenote - Consolidate horizontal scrolling that uses SCX (such as title screen mons scrolling)
;this is prevents two vblanks from happening when waiting on scrolling to update
;prevents some artifacts when 'mons are panning across the screen
BGLayerScrollingUpdate:
	call GetPredefRegisters
	ld a, NOT_VBLANKED	;set H_VBLANKOCCURRED to a non-zero value ; it becomes zero to indicate vblank happened
	ld [H_VBLANKOCCURRED], a
.wait
	ld a, [rLY] ; rLY
	cp l
	jr z, .update	;update SCX if we have reached the line specified in 'l'
	ld a, [H_VBLANKOCCURRED]	;otherwise see if vblank happened in the meantime
	and a
	jr nz, .wait	;if vblank hasn't happened, then keep waiting to reach the needed line
	ld a, [rLY]	;otherwise vblank happened already while waiting; get the current line
	cp l	;is the current line still less than the needed line?
	jr c, .wait	;if so keep waiting; otherwise just go ahead and update SCX to head off another vblank
.update
	ld a, h
	ld [rSCX], a
	ret
	
	

;joenote - this will check to see if facing is being forced on a sprite that normally has random facing	
CheckForcedFacing:
	ld h, $c2
	ld a, [H_CURRENTSPRITEOFFSET]
	add $1
	ld l, a
	ld a, [hl]
	cp 1
	ld a, 0
	ld [hl], a
	jr nz, .clearcarryret
	ld h, $c1
	ld a, [H_CURRENTSPRITEOFFSET]
	add $9
	ld l, a
	ld a, [hl]
	swap a
	ld d, a
	scf
	ret
.clearcarryret
	xor a
	ret
	
	
	
;joenote - moved this here to save space in Home bank
		;Now loads value at DE from a backup location
_PrintNumber:
; Print the c-digit, b-byte value at de.
; Allows 2 to 8 digits. For 1-digit numbers, add
; the value to char "0" instead of calling PrintNumber.
; Flags LEADING_ZEROES and LEFT_ALIGN can be given
; in bits 7 and 6 of b respectively.
	call GetPredefRegisters
	push bc
	push de
	ld de, wPrintNumDE
	
	xor a
	ld [H_PASTLEADINGZEROES], a
	ld [H_NUMTOPRINT], a
	ld [H_NUMTOPRINT + 1], a
	ld a, b
	and $f
	cp 1
	jr z, .byte
	cp 2
	jr z, .word
.long
	ld a, [de]
	ld [H_NUMTOPRINT], a
	inc de
	ld a, [de]
	ld [H_NUMTOPRINT + 1], a
	inc de
	ld a, [de]
	ld [H_NUMTOPRINT + 2], a
	jr .start

.word
	ld a, [de]
	ld [H_NUMTOPRINT + 1], a
	inc de
	ld a, [de]
	ld [H_NUMTOPRINT + 2], a
	jr .start

.byte
	ld a, [de]
	ld [H_NUMTOPRINT + 2], a

.start
	push de

	ld d, b
	ld a, c
	ld b, a
	xor a
	ld c, a
	ld a, b

	cp 2
	jr z, .tens
	cp 3
	jr z, .hundreds
	cp 4
	jr z, .thousands
	cp 5
	jr z, .ten_thousands
	cp 6
	jr z, .hundred_thousands
	cp 7
	jr z, .millions

;joenote - adjusted to allow for 8 digits

MACRO print_digit

if (\1) / $10000
	ld a, \1 / $10000 % $100
else	
	xor a
endc
	ld [H_POWEROFTEN + 0], a

if (\1) / $100
	ld a, \1 / $100   % $100
else	
	xor a
endc
	ld [H_POWEROFTEN + 1], a

	ld a, \1 / $1     % $100
	ld [H_POWEROFTEN + 2], a

	call .PrintDigit
	call .NextDigit
ENDM

.tenmillions       print_digit 10000000
.millions          print_digit 1000000
.hundred_thousands print_digit 100000
.ten_thousands     print_digit 10000
.thousands         print_digit 1000
.hundreds          print_digit 100

.tens
	ld c, 0
	ld a, [H_NUMTOPRINT + 2]
.mod
	cp 10
	jr c, .ok
	sub 10
	inc c
	jr .mod
.ok

	ld b, a
	ld a, [H_PASTLEADINGZEROES]
	or c
	ld [H_PASTLEADINGZEROES], a
	jr nz, .past
	call .PrintLeadingZero
	jr .next
.past
	ld a, "0"
	add c
	ld [hl], a
.next

	call .NextDigit
.ones
	ld a, "0"
	add b
	ld [hli], a
	pop de
	
	pop de
	dec de
	pop bc
	ret

.PrintDigit:
; Divide by the current decimal place.
; Print the quotient, and keep the modulus.
	ld c, 0
.loop
	ld a, [H_POWEROFTEN]
	ld b, a
	ld a, [H_NUMTOPRINT]
	ld [H_SAVEDNUMTOPRINT], a
	cp b
	jr c, .underflow0
	sub b
	ld [H_NUMTOPRINT], a
	ld a, [H_POWEROFTEN + 1]
	ld b, a
	ld a, [H_NUMTOPRINT + 1]
	ld [H_SAVEDNUMTOPRINT + 1], a
	cp b
	jr nc, .noborrow1

	ld a, [H_NUMTOPRINT]
	or 0
	jr z, .underflow1
	dec a
	ld [H_NUMTOPRINT], a
	ld a, [H_NUMTOPRINT + 1]
.noborrow1

	sub b
	ld [H_NUMTOPRINT + 1], a
	ld a, [H_POWEROFTEN + 2]
	ld b, a
	ld a, [H_NUMTOPRINT + 2]
	ld [H_SAVEDNUMTOPRINT + 2], a
	cp b
	jr nc, .noborrow2

	ld a, [H_NUMTOPRINT + 1]
	and a
	jr nz, .borrowed

	ld a, [H_NUMTOPRINT]
	and a
	jr z, .underflow2
	dec a
	ld [H_NUMTOPRINT], a
	xor a
.borrowed

	dec a
	ld [H_NUMTOPRINT + 1], a
	ld a, [H_NUMTOPRINT + 2]
.noborrow2
	sub b
	ld [H_NUMTOPRINT + 2], a
	inc c
	jr .loop

.underflow2
	ld a, [H_SAVEDNUMTOPRINT + 1]
	ld [H_NUMTOPRINT + 1], a
.underflow1
	ld a, [H_SAVEDNUMTOPRINT]
	ld [H_NUMTOPRINT], a
.underflow0
	ld a, [H_PASTLEADINGZEROES]
	or c
	jr z, .PrintLeadingZero

	ld a, "0"
	add c
	ld [hl], a
	ld [H_PASTLEADINGZEROES], a
	ret

.PrintLeadingZero:
	bit BIT_LEADING_ZEROES, d
	ret z
	ld [hl], "0"
	ret

.NextDigit:
; Increment unless the number is left-aligned,
; leading zeroes are not printed, and no digits
; have been printed yet.
	bit BIT_LEADING_ZEROES, d
	jr nz, .inc
	bit BIT_LEFT_ALIGN, d
	jr z, .inc
	ld a, [H_PASTLEADINGZEROES]
	and a
	ret z
.inc
	inc hl
	ret

	

;determine if the mon should have a gender symbol
;mons that are genderless or a single gender do not get a symbol
;takes a pokemon index in d
;takes its atk dv in e
;symbol is returned in d --> ;$F5 for female and $EF for male
DetermineMonGender:
	xor a
	ld b, a
	ld hl, ListByGenderRatio
.loop
	ld a, [hli]
	and a
	jr z, .nosymbol
	cp d
	jr z, .foundmon
	inc b
	jr .loop
.foundmon
	ld a, b
	call GetGenderRatioTarget
	ld a, e
	cp b
.male
	ld d, $EF
	ret nc
.female
	ld d, $F5
	ret c
.nosymbol
	ld d, $00
	ret


;ResetRandomHiddenItem:
;	;get a random hidden item flag byte
;	call Random
;	and $0F
;	ld hl, wObtainedHiddenItemsFlags
;	ld b, 0
;	ld c, a
;	add hl, bc
;	;get a random bit
;	call Random
;	and $07
;	ld b, a
;	;make sure it's not the surf board
;	call .checksurfboard
;	ret c
;	;clear the flag
;	inc b
;	ld a, %01111111
;.loop
;	rlca
;	dec b
;	jr nz, .loop
;	ld b, a
;	ld a, [hl]
;	and b
;	;all done
;	ret
;.checksurfboard
;do not reset getting the surf board
;	ld a, c
;	cp 6
;	jr nz, .returnNC
;	ld a, b
;	cp 6
;	jr nz, .returnNC
;	scf	;set the carry flag
;	ret
;.returnNC
;	and a	;clear the carry flag
;	ret

;ResetRandomShowItem:
;	call GetRandHideShowItem
;	ld [wMissableObjectIndex], a
;	predef ShowObject 
;	ret
;GetRandHideShowItem:
;	ld hl, ListGameItems
;	call Random
;	ld b, a
;.loop
;	ld a, [hli]
;	and a
;	jr z, .reloadHL
;	ld c, a
;	ld a, b
;	sub 1
;	ld b, a
;	ld a, c
;	ret c
;	jr .loop
;.reloadHL
;	ld hl, ListGameItems
;	jr .loop

;ResetRandItemsOnInterval:
;	call ResetRandomShowItem
;	call ResetRandomHiddenItem
;	ret


;Takes DVs in BC and DE as an input.
;Uses a Punnett square to output new DVs in HL
DVPunnettSquare:
	call GetPredefRegisters
	push bc
	push de

	call _GetPunnettCEtoL
	pop de
	pop bc
	ld h, l

	push bc
	push de
	ld c, b
	ld e, d

	call _GetPunnettCEtoL
	ld a, h
	ld h, l
	ld l, a

	pop de
	pop bc
	ret
_GetPunnettCEtoL:	
	call Random
	call Random
	
	ld a, %11110000
	push af
	and c
	ld l, a
	pop af
	swap a
	and e
	or l
	ld l, a
	push hl
	
	ld a, %11110000
	push af
	and e
	ld l, a
	pop af
	swap a
	and c
	or l
	ld l, a
	push hl
	
	ld a, %11110000
	push af
	and c
	ld l, a
	pop af
	and e
	swap a
	or l
	ld l, a
	ld a, [hRandomLast]
	bit 0, a
	jr z, .next1
	swap l
.next1
	push hl
	
	ld a, %00001111
	push af
	and c
	ld l, a
	pop af
	and e
	swap a
	or l
	ld l, a
	ld a, [hRandomLast]
	bit 1, a
	jr z, .next2
	swap l
.next2
	push hl
	
	ld a, [hRandomAdd]
	and %00000011
	ld b, 4
.loop
	pop hl
	dec b
	push af
	cp b
	jr nz, .next3
	ld d, l
.next3
	pop af
	jr nz, .loop
	
	ld l, d
	ret
