; The MOVES screen (party menu → MOVES): change party mon wWhichPokemon's
; moves. Choosing one of its four slots, or its field move slot, lists what can
; go there: the moves of its learnset up to its level (its starting moves
; included), and the TMs and HMs the player owns that it can learn, which are
; never used up. REMOVE empties the slot (a mon keeps at least one move).

MOVES_ROWS EQU 7 ; choices on the screen, one line each
MOVES_TOP EQU 4 ; the first row of the list
MOVES_FIELD_SLOT EQU NUM_MOVES ; the slot after the four moves
MOVES_FIELD_ROW EQU 10 ; the field move slot's row

MovesScreen::
	call ClearSprites
	ld hl, wd730
	set 6, [hl] ; no delay between letters
	xor a
	ld [wMovesSlotCursor], a
.slots
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call MovesDrawSlots
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
.slotInput
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	bit BIT_A_BUTTON, b
	jr nz, .chooseSlot
	bit BIT_B_BUTTON, b
	jr nz, .exit
	ld hl, wMovesSlotCursor
	bit BIT_D_UP, b
	jr nz, .up
	bit BIT_D_DOWN, b
	jr z, .slotInput
	ld a, [hl]
	cp MOVES_FIELD_SLOT
	jr z, .slotInput
	inc [hl]
	jr .slots
.up
	ld a, [hl]
	and a
	jr z, .slotInput
	dec [hl]
	jr .slots
.exit
	ld hl, wd730
	res 6, [hl]
	ret
.chooseSlot
	ld a, SFX_PRESS_AB
	call PlaySound
	ld a, [wMovesSlotCursor]
	ld [wMovesSlot], a
	call MovesBuildChoices
	xor a
	ld [wMovesCursor], a
	ld [wMovesScroll], a
.choices
	xor a
	ld [H_AUTOBGTRANSFERENABLED], a
	call MovesDrawChoices
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
.choiceInput
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	bit BIT_B_BUTTON, b
	jp nz, .slots
	ld a, [wMovesChoices]
	and a
	jr z, .choiceInput ; nothing to choose
	bit BIT_A_BUTTON, b
	jr nz, .apply
	ld hl, wMovesCursor
	bit BIT_D_UP, b
	jr nz, .choiceUp
	bit BIT_D_DOWN, b
	jr z, .choiceInput
	ld a, [wMovesChoices]
	dec a
	cp [hl]
	jr z, .choiceInput ; on the last
	inc [hl]
	ld a, [wMovesScroll]
	add MOVES_ROWS - 1
	cp [hl]
	jr nc, .choices
	ld hl, wMovesScroll
	inc [hl]
	jr .choices
.choiceUp
	ld a, [hl]
	and a
	jr z, .choiceInput
	dec [hl]
	ld a, [wMovesScroll]
	cp [hl]
	jr c, .choices
	jr z, .choices
	ld a, [hl]
	ld [wMovesScroll], a
	jr .choices
.apply
	call MovesApply
	ld a, SFX_SWAP
	call PlaySound
	jp .slots

; the choice under the cursor goes in slot wMovesSlot
MovesApply:
	ld a, [wMovesCursor]
	ld c, a
	ld b, 0
	ld hl, wMovesChoices + 1
	add hl, bc
	add hl, bc
	ld d, [hl] ; the move, 0 to REMOVE
	ld a, [wMovesSlot]
	cp MOVES_FIELD_SLOT
	jr nz, .moveSlot
	call MovesFieldSlotAddress
	ld [hl], d
	ret
.moveSlot
	ld a, d
	and a
	jr z, .remove
	call MovesCount ; into the slot, or the first empty one
	ld b, a
	ld a, [wMovesSlot]
	cp b
	jr c, .gotSlot
	ld a, b
.gotSlot
	ld c, a
	ld b, 0
	call MovesPartyMonMoves
	add hl, bc
	ld [hl], d
	push hl
	ld a, d
	call MovesGetData
	pop hl
	ld bc, wPartyMon1PP - wPartyMon1Moves
	add hl, bc
	ld a, [wMovesData + 5] ; its full PP, no PP Ups
	ld [hl], a
	ret
.remove ; the moves after it move up
	ld a, [wMovesSlot]
	ld c, a
	ld b, 0
	call MovesPartyMonMoves
	add hl, bc
	ld a, NUM_MOVES - 1
	sub c
	jr z, .clearLast
	ld b, a
.shift
	inc hl
	ld a, [hld]
	ld [hl], a
	push hl
	ld de, wPartyMon1PP - wPartyMon1Moves
	add hl, de
	inc hl
	ld a, [hld]
	ld [hl], a
	pop hl
	inc hl
	dec b
	jr nz, .shift
.clearLast
	xor a
	ld [hl], a
	ld de, wPartyMon1PP - wPartyMon1Moves
	add hl, de
	ld [hl], a
	ret

; wMovesChoices = what can go in slot wMovesSlot: REMOVE (if the slot can be
; emptied), then the learnset's moves up to the mon's level, then the owned
; TMs and HMs it can learn; each with its source (MovesAddChoice)
MovesBuildChoices:
	xor a
	ld [wMovesChoices], a
	ld a, [wMovesSlot]
	call MovesSlotMove
	and a
	jr z, .noRemove
	ld a, [wMovesSlot]
	cp MOVES_FIELD_SLOT
	jr z, .remove
	call MovesCount
	cp 2
	jr c, .noRemove ; its only move
.remove
	lb de, 0, 0
	call MovesAppendChoice
.noRemove
	ld a, [wWhichPokemon]
	ld c, a
	ld b, 0
	ld hl, wPartySpecies
	add hl, bc
	ld a, [hl]
	ld [wd0b5], a
	ld [wcf91], a ; for CanLearnTM
	ld [wMovesSpecies], a
	call GetMonHeader
	ld hl, wMonHMoves ; its starting moves, as level 1's
	ld c, NUM_MOVES
.starting
	ld a, [hli]
	ld d, a
	ld e, 1
	push hl
	push bc
	call MovesAddChoice
	pop bc
	pop hl
	dec c
	jr nz, .starting
; the learnset
	ld a, [wMovesSpecies]
	dec a
	ld l, a
	ld h, 0
	add hl, hl
	ld bc, EvosMovesPointerTable
	add hl, bc
	ld de, wMovesLearnset
	ld bc, 2
	ld a, BANK(EvosMovesPointerTable)
	call FarCopyData
	ld hl, wMovesLearnset
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wMovesLearnset
	ld bc, MOVES_LEARNSET_LENGTH
	ld a, BANK(EvosMovesPointerTable)
	call FarCopyData
	ld hl, wMovesLearnset
.skipEvolutions
	ld a, [hli]
	and a
	jr nz, .skipEvolutions
.learnset
	ld a, [hli]
	and a
	jr z, .machines
	ld e, a ; the level
	ld a, [hli]
	ld d, a ; the move
	call MovesMonLevel
	cp e
	jr c, .learnset ; not yet
	push hl
	call MovesAddChoice
	pop hl
	jr .learnset
.machines
	xor a
	ld [wMovesMachine], a
.machine
	ld a, [wMovesMachine]
	ld c, a
	ld b, FLAG_TEST
	ld hl, wTMsOwned
	predef FlagActionPredef
	ld a, c
	and a
	jr z, .nextMachine
	ld a, [wMovesMachine]
	ld c, a
	ld b, 0
	ld hl, TechnicalMachines
	add hl, bc
	ld de, wMoveNum
	ld bc, 1
	ld a, BANK(TechnicalMachines)
	call FarCopyData
	ld a, [wMovesSpecies]
	ld [wcf91], a
	predef CanLearnTM
	ld a, c
	and a
	jr z, .nextMachine
	ld a, [wMoveNum]
	ld d, a
	ld a, [wMovesMachine]
	cp NUM_TMS
	jr nc, .hm
	add TM_01
	jr .gotItem
.hm
	add HM_01 - NUM_TMS
.gotItem
	ld e, a
	call MovesAddChoice
.nextMachine
	ld hl, wMovesMachine
	inc [hl]
	ld a, [hl]
	cp NUM_MACHINES
	jr c, .machine
	ret

; d = a move, e = where it comes from (the level it's learned at, or the TM or
; HM item) -> a choice, unless the mon knows it, it's listed already, or it
; doesn't fit the slot (the field move slot takes field moves only)
MovesAddChoice:
	ld a, d
	and a
	ret z
	call MovesPartyMonMoves
	ld b, NUM_MOVES
.known
	ld a, [hli]
	cp d
	ret z
	dec b
	jr nz, .known
	ld a, [wMovesSlot]
	cp MOVES_FIELD_SLOT
	jr nz, .listed
	call MovesFieldSlotAddress
	ld a, [hl]
	cp d
	ret z
	ld a, d
	push de
	ld hl, MovesFieldMoves
	ld de, 1
	call IsInArray
	pop de
	ret nc
.listed
	ld hl, wMovesChoices
	ld a, [hli]
	and a
	jr z, MovesAppendChoice
	ld b, a
.listedLoop
	ld a, [hli]
	inc hl
	cp d
	ret z
	dec b
	jr nz, .listedLoop
; fall through
; d, e -> the next choice
MovesAppendChoice:
	ld hl, wMovesChoices
	ld a, [hl]
	cp MAX_MOVE_CHOICES
	ret nc
	inc [hl]
	ld c, a
	ld b, 0
	inc hl
	add hl, bc
	add hl, bc
	ld [hl], d
	inc hl
	ld [hl], e
	ret

; the moves the field move slot takes (FieldMoveDisplayData's)
MovesFieldMoves:
	db CUT, FLY, SURF, STRENGTH, FLASH, DIG, TELEPORT, SOFTBOILED
	db $ff

; hl = party mon wWhichPokemon's moves; keeps bc and de
MovesPartyMonMoves:
	push bc
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Moves
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	pop bc
	ret

; a = party mon wWhichPokemon's level; keeps bc, de and hl
MovesMonLevel:
	push hl
	push bc
	ld a, [wWhichPokemon]
	ld hl, wPartyMon1Level
	ld bc, wPartyMon2 - wPartyMon1
	call AddNTimes
	ld a, [hl]
	pop bc
	pop hl
	ret

; hl = party mon wWhichPokemon's field move slot (Shin's temporary field move);
; keeps bc and de
MovesFieldSlotAddress:
	push bc
	ld a, [wWhichPokemon]
	ld c, a
	ld b, 0
	ld hl, wTempFieldMoveSlots
	add hl, bc
	pop bc
	ret

; a = how many moves party mon wWhichPokemon knows; keeps bc and de
MovesCount:
	push bc
	call MovesPartyMonMoves
	ld bc, NUM_MOVES << 8
.loop
	ld a, [hli]
	and a
	jr z, .done
	inc c
	dec b
	jr nz, .loop
.done
	ld a, c
	pop bc
	ret

; a = a slot (0-3, or MOVES_FIELD_SLOT) -> a = its move, 0 if empty
MovesSlotMove:
	cp MOVES_FIELD_SLOT
	jr z, .field
	ld c, a
	ld b, 0
	call MovesPartyMonMoves
	add hl, bc
	ld a, [hl]
	ret
.field
	call MovesFieldSlotAddress
	ld a, [hl]
	ret

; a = a move -> wMovesData = its Moves entry
MovesGetData:
	dec a
	ld hl, Moves
	ld bc, MoveEnd - Moves
	call AddNTimes
	ld de, wMovesData
	ld bc, MoveEnd - Moves
	ld a, BANK(Moves)
	jp FarCopyData

MovesDrawFrame:
	coord hl, 0, 0
	lb bc, 1, 18
	call TextBoxBorder
	coord hl, 0, MOVES_TOP - 1
	lb bc, MOVES_ROWS, 18
	call TextBoxBorder
	coord hl, 0, MOVES_TOP + MOVES_ROWS + 1
	lb bc, 4, 18
	jp TextBoxBorder

; the mon's slots, the cursor on wMovesSlotCursor, and that slot's move
MovesDrawSlots:
	call MovesDrawFrame
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	coord hl, 1, 1
	call PlaceString
	call MovesMonLevel
	ld [wLoadedMonLevel], a
	coord hl, 14, 1
	call PrintLevelFull
	xor a
.slot
	push af
	call MovesSlotMove
	ld d, a
	pop af
	push af
	push de
	call MovesSlotRow
	inc hl
	pop de
	ld a, d
	and a
	jr z, .empty
	ld [wd11e], a
	push hl
	call GetMoveName
	pop hl
	call PlaceString
	pop af
	push af
	cp MOVES_FIELD_SLOT
	jr z, .nextSlot
	ld [wCurrentMenuItem], a ; its PP, as now/most
	xor a ; PLAYER_PARTY_DATA
	ld [wMonDataLocation], a
	callab GetMaxPP
	pop af
	push af
	ld c, a
	ld b, 0
	call MovesPartyMonMoves
	add hl, bc
	ld bc, wPartyMon1PP - wPartyMon1Moves
	add hl, bc
	ld a, [hl]
	and %00111111
	ld [wMovesNumber], a
	pop af
	push af
	call MovesSlotRow
	ld bc, 13
	add hl, bc
	ld de, wMovesNumber
	lb bc, 1, 2
	call PrintNumber
	ld [hl], "/"
	inc hl
	ld de, wMaxPP
	lb bc, LEFT_ALIGN | 1, 2
	call PrintNumber
	jr .nextSlot
.empty
	ld [hl], "-"
.nextSlot
	pop af
	inc a
	cp MOVES_FIELD_SLOT + 1
	jr c, .slot
	coord hl, 2, MOVES_FIELD_ROW - 1
	ld de, MovesFieldSlotText
	call PlaceString
	ld a, [wMovesSlotCursor]
	call MovesSlotRow
	ld [hl], "▶"
	ld a, [wMovesSlotCursor]
	call MovesSlotMove
	jp MovesDrawDetails

; a = a slot -> hl = its cursor's tile
MovesSlotRow:
	cp MOVES_FIELD_SLOT
	jr nz, MovesChoiceRow
	ld a, MOVES_FIELD_ROW - MOVES_TOP
; fall through
; a = a row of the list -> hl = its cursor's tile
MovesChoiceRow:
	add MOVES_TOP
	coord hl, 1, 0
	ld bc, SCREEN_WIDTH
	jp AddNTimes

MovesFieldSlotText:
	db "FIELD MOVE@"

; the choices for slot wMovesSlot, the cursor on wMovesCursor, and its move
MovesDrawChoices:
	call MovesDrawFrame
	ld a, [wMovesSlot]
	cp MOVES_FIELD_SLOT
	ld de, MovesFieldSlotText
	jr z, .header
	call MovesSlotMove
	and a
	ld de, MovesLearnText
	jr z, .header
	ld [wd11e], a
	call GetMoveName
	coord hl, 6, 1
	call PlaceString
	ld de, MovesSwapText
.header
	coord hl, 1, 1
	call PlaceString
	ld a, [wMovesChoices]
	and a
	jr nz, .entries
	coord hl, 2, MOVES_TOP
	ld de, MovesNoneText
	jp PlaceString
.entries
	xor a ; the row
.entry
	push af
	ld b, a
	ld a, [wMovesScroll]
	add b
	ld b, a ; the choice
	ld a, [wMovesChoices]
	dec a
	cp b
	jr c, .nextEntry
	ld c, b
	ld b, 0
	ld hl, wMovesChoices + 1
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld e, [hl] ; where it comes from
	ld d, a
	pop af
	push af
	push de
	call MovesChoiceRow
	inc hl
	ld a, d
	and a
	ld de, MovesRemoveText
	jr z, .placeName
	ld [wd11e], a
	push hl
	call GetMoveName
	pop hl
.placeName
	call PlaceString
	pop de
	ld a, d
	and a
	jr z, .nextEntry
	pop af
	push af
	call MovesChoiceRow
	ld bc, 14
	add hl, bc
	ld a, e
	cp HM_01
	jr c, .level
	cp TM_01
	ld b, "H"
	jr c, .machine
	ld b, "T"
	sub TM_01 - HM_01
.machine
	sub HM_01 - 1
	ld [wMovesNumber], a
	ld [hl], b
	inc hl
	ld [hl], "M"
	inc hl
	ld de, wMovesNumber
	lb bc, LEADING_ZEROES | 1, 2
	call PrintNumber
	jr .nextEntry
.level
	ld [wMovesNumber], a
	ld [hl], "L"
	inc hl
	ld de, wMovesNumber
	lb bc, LEFT_ALIGN | 1, 3
	call PrintNumber
.nextEntry
	pop af
	inc a
	cp MOVES_ROWS
	jr c, .entry
	ld a, [wMovesScroll]
	ld b, a
	ld a, [wMovesCursor]
	sub b
	call MovesChoiceRow
	ld [hl], "▶"
	ld a, [wMovesCursor]
	ld c, a
	ld b, 0
	ld hl, wMovesChoices + 1
	add hl, bc
	add hl, bc
	ld a, [hl]
; fall through
; a = a move (0 for none) -> its type, category, power, accuracy and PP
MovesDrawDetails:
	and a
	ret z
	push af
	call MovesGetData
	ld a, [wMovesData + 3] ; type
	add a
	ld c, a
	ld b, 0
	ld hl, TypeNames
	add hl, bc
	ld de, wMovesNumber
	ld bc, 2
	ld a, BANK(TypeNames)
	call FarCopyData
	ld hl, wMovesNumber
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wcd6d
	ld bc, NAME_LENGTH
	ld a, BANK(TypeNames)
	call FarCopyData
	coord hl, 1, MOVES_TOP + MOVES_ROWS + 2
	ld de, wcd6d
	call PlaceString
	pop af
	call GetMoveCategory
	ld de, MovesPhysicalText
	cp PHYSICAL
	jr z, .category
	ld de, MovesSpecialText
	cp SPECIAL
	jr z, .category
	ld de, MovesStatusText
.category
	coord hl, 11, MOVES_TOP + MOVES_ROWS + 2
	call PlaceString
	coord hl, 1, MOVES_TOP + MOVES_ROWS + 4
	ld de, MovesPowerText
	call PlaceString
	coord hl, 5, MOVES_TOP + MOVES_ROWS + 4
	ld a, [wMovesData + 2]
	cp 2
	jr nc, .power
	ld de, MovesNoValueText ; none, or a fixed amount
	call PlaceString
	jr .accuracy
.power
	ld de, wMovesData + 2
	lb bc, 1, 3
	call PrintNumber
.accuracy
	coord hl, 10, MOVES_TOP + MOVES_ROWS + 4
	ld de, MovesAccuracyText
	call PlaceString
; percent = ceil(accuracy x 100 / 255), undoing the data's percent macro
	xor a
	ld [H_MULTIPLICAND], a
	ld [H_MULTIPLICAND + 1], a
	ld a, [wMovesData + 4]
	ld [H_MULTIPLICAND + 2], a
	ld a, 100
	ld [H_MULTIPLIER], a
	call Multiply
	ld a, [H_PRODUCT + 3]
	add 254
	ld [H_DIVIDEND + 3], a
	ld a, [H_PRODUCT + 2]
	adc 0
	ld [H_DIVIDEND + 2], a
	ld a, 255
	ld [H_DIVISOR], a
	ld b, 4
	call Divide
	ld a, [H_QUOTIENT + 3]
	ld [wMovesNumber], a
	coord hl, 14, MOVES_TOP + MOVES_ROWS + 4
	ld de, wMovesNumber
	lb bc, 1, 3
	call PrintNumber
	coord hl, 1, MOVES_TOP + MOVES_ROWS + 5
	ld de, MovesPPText
	call PlaceString
	coord hl, 5, MOVES_TOP + MOVES_ROWS + 5
	ld de, wMovesData + 5
	lb bc, 1, 3
	jp PrintNumber

MovesSwapText:
	db "SWAP@"
MovesLearnText:
	db "LEARN A MOVE@"
MovesNoneText:
	db "NOTHING TO LEARN@"
MovesRemoveText:
	db "REMOVE@"
MovesPhysicalText:
	db "PHYSICAL@"
MovesSpecialText:
	db "SPECIAL@"
MovesStatusText:
	db "STATUS@"
MovesPowerText:
	db "POW@"
MovesAccuracyText:
	db "ACC@"
MovesPPText:
	db "PP@"
MovesNoValueText:
	db "---@"
