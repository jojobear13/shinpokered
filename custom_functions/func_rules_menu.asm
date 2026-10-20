; The RULES page of the extra options menu. These rules used to be toggled by
; talking to NPCs (the girl and aides in OAK's lab, aides in the VIRIDIAN
; #MON CENTER and CELADON DINER, the old man in the VIRIDIAN school, the
; clause brothers in VIRIDIAN CITY and a guard at the SAFARI ZONE gate). Each
; is still an event flag, so the code that follows a rule is unchanged.

MACRO rule
	dw \1 ; label, or 0 for a flag with no row of its own
	dwEventFlagAddress \2
	db 1 << ((\2) % 8)
ENDM

; one entry per row, then the flags that share a row with another
RuleFlags:
	rule RulesTextWild,       EVENT_8DE ; randomize wild #MON (special-cased below)
	rule RulesTextTrainers,   EVENT_8D8 ; randomize regular trainers' #MON
	rule RulesTextScaling,    EVENT_90C ; scale trainers to the player's level
	rule RulesTextAltMoves,   EVENT_8C9 ; alternate trainer move sets
	rule RulesTextCatchUpExp, EVENT_8D9 ; catch-up EXP boost
	rule RulesTextSymbols,    EVENT_90E ; caught and gender symbols
	rule RulesTextItem,       EVENT_8DB ; item clause
	rule RulesTextSleep,      EVENT_8DC ; sleep clause
	rule RulesTextFreeze,     EVENT_8DD ; freeze clause
	rule RulesTextHyperBeam,  EVENT_8C8 ; hyper beam clause
	rule RulesTextSafari,     EVENT_90F ; special safari zone event
RuleFlagsRowsEnd:
	rule 0,                   EVENT_8D7 ; full rather than tiered wild randomization
RuleFlagsEnd:

RULE_ENTRY_LENGTH EQU 5
NUM_RULE_ROWS EQU (RuleFlagsRowsEnd - RuleFlags) / RULE_ENTRY_LENGTH
NUM_RULE_FLAGS EQU (RuleFlagsEnd - RuleFlags) / RULE_ENTRY_LENGTH
RULES_BACK_ROW EQU NUM_RULE_ROWS + 3

DisplayRulesMenu:
	call ClearScreen
	xor a
	ld [wCurrentMenuItem], a
	ld [wLastMenuItem], a
	inc a
	ld [wTopMenuItemY], a
	ld [wTopMenuItemX], a
	coord hl, 0, 0
	ld b, NUM_RULE_ROWS
	ld c, 18
	call TextBoxBorder
	call PlaceRulesMenuStrings
	call ShowRules
	call Delay3
.loop
	call PlaceMenuCursor
.getJoypadStateLoop
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	and B_BUTTON | START
	jr nz, .exitMenu
	ld a, [wTopMenuItemY]
	bit BIT_D_DOWN, b
	jr nz, .downPressed
	bit BIT_D_UP, b
	jr nz, .upPressed
	ld c, a
	ld a, b
	and A_BUTTON | D_LEFT | D_RIGHT
	jr z, .getJoypadStateLoop
	ld a, c
	cp RULES_BACK_ROW
	jr z, .exitMenu
	dec a
	call ToggleRule
	call ShowRules
	jr .getJoypadStateLoop
.downPressed
	cp RULES_BACK_ROW
	ld b, 1 - RULES_BACK_ROW
	jr z, .updateMenuVariables
	cp NUM_RULE_ROWS
	ld b, RULES_BACK_ROW - NUM_RULE_ROWS
	jr z, .updateMenuVariables
	ld b, 1
	jr .updateMenuVariables
.upPressed
	cp 1
	ld b, RULES_BACK_ROW - 1
	jr z, .updateMenuVariables
	cp RULES_BACK_ROW
	ld b, NUM_RULE_ROWS - RULES_BACK_ROW
	jr z, .updateMenuVariables
	ld b, -1
.updateMenuVariables
	add b
	ld [wTopMenuItemY], a
	call PlaceRulesMenuStrings
	jr .loop
.exitMenu
	ld a, SFX_PRESS_AB
	call PlaySound
	jp ClearScreen

; hl = the entry for rule a
RuleEntry:
	ld hl, RuleFlags
	ld bc, RULE_ENTRY_LENGTH
	jp AddNTimes

; de = the flag's address, a = its mask, for the entry at hl
RuleFlagAddress:
	inc hl
	inc hl
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [hl]
	ret

; a = row
ToggleRule:
	and a
	jr z, .wild
	call RuleEntry
	call RuleFlagAddress
	ld b, a
	ld a, [de]
	xor b
	ld [de], a
	ret
.wild ; off, then tiered, then full
	CheckEvent EVENT_8DE
	jr z, .tiered
	CheckEvent EVENT_8D7
	jr z, .full
	ResetEvent EVENT_8DE
	ResetEvent EVENT_8D7
	ret
.tiered
	SetEvent EVENT_8DE
	ResetEvent EVENT_8D7
	ret
.full
	SetEvent EVENT_8D7
	ret

PlaceRulesMenuStrings:
	xor a
.loop
	push af
	call RuleEntry
	ld a, [hli]
	ld e, a
	ld d, [hl]
	pop af
	push af
	coord hl, 1, 1
	ld bc, SCREEN_WIDTH
	call AddNTimes
	call PlaceString
	pop af
	inc a
	cp NUM_RULE_ROWS
	jr c, .loop
	coord hl, 1, RULES_BACK_ROW
	ld de, RulesTextBack
	jp PlaceString

ShowRules:
	ld de, RulesTextWildOff
	CheckEvent EVENT_8DE
	jr z, .placeWild
	ld de, RulesTextWildTiered
	CheckEvent EVENT_8D7
	jr z, .placeWild
	ld de, RulesTextWildFull
.placeWild
	coord hl, 15, 1
	call PlaceString
	ld a, 1
.loop
	push af
	call RuleEntry
	call RuleFlagAddress
	ld b, a
	ld a, [de]
	and b
	ld de, RulesTextOff
	jr z, .place
	ld de, RulesTextOn
.place
	pop af
	push af
	coord hl, 16, 1
	ld bc, SCREEN_WIDTH
	call AddNTimes
	call PlaceString
	pop af
	inc a
	cp NUM_RULE_ROWS
	jr c, .loop
	ret

; Starting a new game clears every event flag, so these two carry the rules
; across it in wBuffer: a player can set them from the title screen's options
; before choosing NEW GAME.
SaveRuleFlags:
	ld hl, RuleFlags
	ld bc, wBuffer
.loop
	push hl
	call RuleFlagAddress
	ld l, a
	ld a, [de]
	and l
	ld [bc], a
	inc bc
	pop hl
	ld de, RULE_ENTRY_LENGTH
	add hl, de
	ld a, c
	cp LOW(wBuffer + NUM_RULE_FLAGS)
	jr nz, .loop
	ret

RestoreRuleFlags:
	ld hl, RuleFlags
	ld bc, wBuffer
.loop
	push hl
	call RuleFlagAddress
	ld a, [bc]
	ld l, a
	ld a, [de]
	or l
	ld [de], a
	inc bc
	pop hl
	ld de, RULE_ENTRY_LENGTH
	add hl, de
	ld a, c
	cp LOW(wBuffer + NUM_RULE_FLAGS)
	jr nz, .loop
	ret

RulesTextWild:
	db " RANDOM WILD@"
RulesTextTrainers:
	db " RANDOM TRNRS@"
RulesTextScaling:
	db " TRNR SCALING@"
RulesTextAltMoves:
	db " ALT. MOVES@"
RulesTextCatchUpExp:
	db " CATCH-UP EXP@"
RulesTextSymbols:
	db " CAUGHT ICON@"
RulesTextItem:
	db " ITEM CLAUSE@"
RulesTextSleep:
	db " SLEEP CLAUSE@"
RulesTextFreeze:
	db " FREEZE CLAUSE@"
RulesTextHyperBeam:
	db " H.BEAM CLAUSE@"
RulesTextSafari:
	db " SAFARI EVENT@"
RulesTextBack:
	db " BACK@"

RulesTextWildOff:
	db " OFF@"
RulesTextWildTiered:
	db "TIER@"
RulesTextWildFull:
	db "FULL@"
RulesTextOn:
	db "ON @"
RulesTextOff:
	db "OFF@"
