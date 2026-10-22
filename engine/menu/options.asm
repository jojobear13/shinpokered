; The OPTION screen, from the title screen's menu and the start menu. It
; replaces the original three-option screen, the extra options screen that
; SELECT opened and that screen's RULES page: the options are in pages, with
; a two-line explanation of the one under the cursor at the bottom.
;
; UP and DOWN move the cursor, A or RIGHT gives the option its next value and
; LEFT its previous one. On the page's name, LEFT and RIGHT turn the page;
; SELECT turns it from anywhere. B or START closes the screen.
;
; Every option starts as the original game played (InitOptions): MEDIUM text,
; animations on, SHIFT, mono, 30 frames a second, Gen 1's pictures and
; everything else off.

; an option is a row of OPT_LENGTH bytes:
; label, explanation, kind, mask or number of values, the flag's address or
; the routine that gets the value (in a), the routine that sets it (from a),
; and the list of the values' names
OPT_KIND   EQU 4
OPT_VALUES EQU 10
OPT_LENGTH EQU 12

	const_def
	const OPT_BIT    ; a bit in RAM or an event flag: off or on
	const OPT_CUSTOM ; values the routines get and set
	const OPT_ACTION ; a routine that A runs

MACRO opt_bit ; label, explanation, address, mask, values
	dw \1, \2
	db OPT_BIT, \4
	dw \3, 0, \5
ENDM

MACRO opt_event ; label, explanation, event, values
	opt_bit \1, \2, wEventFlags + (\3) / 8, 1 << ((\3) % 8), \4
ENDM

MACRO opt_custom ; label, explanation, number of values, getter, setter, values
	dw \1, \2
	db OPT_CUSTOM, \3
	dw \4, \5, \6
ENDM

MACRO opt_action ; label, explanation, routine
	dw \1, \2
	db OPT_ACTION, 0
	dw \3, 0, 0
ENDM

OptionPages:
	dw OptionsPageGame
	dw OptionsPageDisplay
	dw OptionsPageChallenge
	dw OptionsPageClauses
	dw OptionsPageExtras
	dw OptionsPageRandomizer
	dw OptionsPageRandomMons
NUM_OPTION_PAGES EQU (@ - OptionPages) / 2

; each page: its name, its number of options, then the options (at most 7)
OptionsPageGame:
	db "GAME@", 6
	opt_custom OptTextTextSpeed, OptHelpTextSpeed, 4, GetTextSpeedOption, SetTextSpeedOption, OptValuesTextSpeed
	opt_bit    OptTextAnimation, OptHelpAnimation, wOptions, 1 << BIT_BATTLE_ANIMATION, OptValuesOnOff
	opt_bit    OptTextStyle, OptHelpStyle, wOptions, 1 << BIT_BATTLE_SHIFT, OptValuesStyle
	opt_custom OptTextAudio, OptHelpAudio, 4, GetAudioOption, SetAudioOption, OptValuesAudio
	opt_event  OptTextExpShare, OptHelpExpShare, EVENT_EXP_SHARE_ON, OptValuesOffOn
	opt_action OptTextSoundTest, OptHelpSoundTest, OptionsSoundTest

OptionsPageDisplay:
	db "DISPLAY@", 7
	opt_bit    OptTextFrameRate, OptHelpFrameRate, wUnusedD721, 1 << 4, OptValuesFrameRate
	opt_bit    OptTextSprites, OptHelpSprites, wDisplayOptions, 1 << BIT_GEN2_SPRITES, OptValuesSprites
	opt_custom OptTextMoreColor, OptHelpMoreColor, 2, GetMoreColorOption, SetMoreColorOption, OptValuesOffOn
	opt_custom OptTextColorFix, OptHelpColorFix, 2, GetColorFixOption, SetColorFixOption, OptValuesOffOn
	opt_event  OptTextSymbols, OptHelpSymbols, EVENT_90E, OptValuesOffOn
	opt_custom OptTextTypeHint, OptHelpTypeHint, 3, GetTypeHintOption, SetTypeHintOption, OptValuesTypeHint
	opt_bit    OptTextHPPercent, OptHelpHPPercent, wDisplayOptions, 1 << BIT_HP_PERCENT, OptValuesOffOn

OptionsPageChallenge:
	db "CHALLENGE@", 6
	opt_bit    OptTextHardMode, OptHelpHardMode, wOptions, BATTLE_HARD_MODE, OptValuesOffOn
	opt_bit    OptTextAISwitching, OptHelpAISwitching, wUnusedD721, BATTLE_NOSWITCH, OptValuesOnOff ; the flag means off
	opt_custom OptTextLevelCap, OptHelpLevelCap, 2, GetLevelCapOption, SetLevelCapOption, OptValuesLevelCap
	opt_event  OptTextScaling, OptHelpScaling, EVENT_90C, OptValuesOffOn
	opt_event  OptTextAltMoves, OptHelpAltMoves, EVENT_8C9, OptValuesOffOn
	opt_bit    OptTextNuzlocke, OptHelpNuzlocke, wUnusedD721, 1 << 6, OptValuesOffOn

OptionsPageClauses:
	db "CLAUSES@", 4
	opt_event  OptTextItemClause, OptHelpItemClause, EVENT_8DB, OptValuesOffOn
	opt_event  OptTextSleepClause, OptHelpSleepClause, EVENT_8DC, OptValuesOffOn
	opt_event  OptTextFreezeClause, OptHelpFreezeClause, EVENT_8DD, OptValuesOffOn
	opt_event  OptTextBeamClause, OptHelpBeamClause, EVENT_8C8, OptValuesOffOn

OptionsPageExtras:
	db "EXTRAS@", 5
	opt_event  OptTextWinHeal, OptHelpWinHeal, EVENT_WIN_HEAL, OptValuesOffOn
	opt_event  OptTextWarpBack, OptHelpWarpBack, EVENT_BLACKOUT_RETURN, OptValuesOffOn
	opt_event  OptTextCatchUpExp, OptHelpCatchUpExp, EVENT_8D9, OptValuesOffOn
	opt_event  OptTextSafari, OptHelpSafari, EVENT_90F, OptValuesOffOn
	opt_event  OptTextMenuPC, OptHelpMenuPC, EVENT_PC_IN_MENU, OptValuesOffOn

; the world's shuffles are chosen before NEW GAME (engine/rando/): from the
; start menu they only show
OptionsPageRandomizer:
	db "RANDOMIZER@", 5
	opt_custom OptTextRandoDoors, OptHelpRandoDoors, 2, GetRandoDoorsOption, SetRandoDoorsOption, OptValuesOffOn
	opt_custom OptTextRandoKeys, OptHelpRandoKeys, 2, GetRandoKeysOption, SetRandoKeysOption, OptValuesOffOn
	opt_custom OptTextRandoItems, OptHelpRandoItems, 2, GetRandoItemsOption, SetRandoItemsOption, OptValuesOffOn
	opt_custom OptTextRandoMarts, OptHelpRandoMarts, 2, GetRandoMartsOption, SetRandoMartsOption, OptValuesOffOn
	opt_custom OptTextRandoTrades, OptHelpRandoTrades, 2, GetRandoTradesOption, SetRandoTradesOption, OptValuesOffOn

OptionsPageRandomMons:
	db "RANDOM #MON@", 7
	opt_custom OptTextRandoStarters, OptHelpRandoStarters, 3, GetRandoStartersOption, SetRandoStartersOption, OptValuesStarters
	opt_custom OptTextRandomWild, OptHelpRandomWild, 4, GetRandomWildOption, SetRandomWildOption, OptValuesRandomWild
	opt_custom OptTextRandomTrainers, OptHelpRandomTrainers, 3, GetRandomTrainersOption, SetRandomTrainersOption, OptValuesRandomTrainers
	opt_custom OptTextRandoSpecial, OptHelpRandoSpecial, 2, GetRandoSpecialOption, SetRandoSpecialOption, OptValuesOffOn
	opt_custom OptTextRandoTMMoves, OptHelpRandoTMMoves, 2, GetRandoTMMovesOption, SetRandoTMMovesOption, OptValuesOffOn
	opt_custom OptTextRandoTMCompat, OptHelpRandoTMCompat, 4, GetRandoTMCompatOption, SetRandoTMCompatOption, OptValuesTMCompat
	opt_custom OptTextRandoLearnsets, OptHelpRandoLearnsets, 4, GetRandoLearnsetsOption, SetRandoLearnsetsOption, OptValuesLearnsets

; from the title screen's menu (DisplayOptionMenuInGame from the start menu)
DisplayOptionMenu:
	xor a
	jr DisplayOptions
DisplayOptionMenuInGame:
	ld a, 1
DisplayOptions:
	ld [wOptionsInGame], a
	call .options
	xor a
	ld [wOptionsInGame], a
	ret
.options
	call GBPalNormal ; ROCK TUNNEL's darkness doesn't reach the menu
	ld a, [wUpdateSpritesEnabled] ; nor do the map's sprites
	push af
	ld a, $ff
	ld [wUpdateSpritesEnabled], a
	call ClearSprites
	call .menu
	pop af
	ld [wUpdateSpritesEnabled], a
	ret
.menu
	xor a
	ld [wOptionsPage], a
	ld [wOptionsRow], a
	inc a
	ld [wLetterPrintingDelayFlags], a
	ld [H_AUTOBGTRANSFERENABLED], a
.drawPage
	call DrawOptionsPage
.drawCursor
	call DrawOptionsCursor
.input
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	and B_BUTTON | START
	jr nz, .exit
	bit BIT_SELECT, b
	jr nz, .nextPage
	bit BIT_D_UP, b
	jr nz, .up
	bit BIT_D_DOWN, b
	jr nz, .down
	ld a, b
	and A_BUTTON | D_LEFT | D_RIGHT
	jr z, .input
	ld a, [wOptionsRow]
	and a
	jr z, .turnPage
	call ChangeOption
	jr c, .drawPage
	jr .input
.turnPage
	bit BIT_D_LEFT, b
	jr z, .nextPage
	ld a, [wOptionsPage]
	and a
	jr nz, .previousPage
	ld a, NUM_OPTION_PAGES
.previousPage
	dec a
	jr .setPage
.nextPage
	ld a, [wOptionsPage]
	inc a
	cp NUM_OPTION_PAGES
	jr c, .setPage
	xor a
.setPage
	ld [wOptionsPage], a
	call GetOptionCount ; keep the cursor on the page
	ld b, a
	ld a, [wOptionsRow]
	cp b
	jr c, .drawPage
	ld a, b
	ld [wOptionsRow], a
	jr .drawPage
.up
	ld a, [wOptionsRow]
	and a
	jr nz, .upOne
	call GetOptionCount
	inc a
.upOne
	dec a
	jr .setRow
.down
	call GetOptionCount
	ld b, a
	ld a, [wOptionsRow]
	cp b
	jr c, .downOne
	ld a, -1
.downOne
	inc a
.setRow
	ld [wOptionsRow], a
	jr .drawCursor
.exit
	ld a, SFX_PRESS_AB
	jp PlaySound

; the page's name and its options (the explanation's box is the cursor's)
DrawOptionsPage:
	coord hl, 0, 0
	lb bc, 1, SCREEN_WIDTH - 2
	call TextBoxBorder
	coord hl, 0, 3
	lb bc, 7, SCREEN_WIDTH - 2
	call TextBoxBorder
	coord hl, 3, 1
	ld [hl], "◀"
	call GetOptionsPage
	ld d, h
	ld e, l
	coord hl, 5, 1
	call PlaceString
	ld h, b
	ld l, c
	inc hl
	ld [hl], "▶"
	call GetOptionCount
	ld c, a
	xor a
.loop
	push bc
	push af
	call DrawOption
	pop af
	pop bc
	inc a
	cp c
	jr c, .loop
	ret

; the cursor, and the explanation of what it's on
DrawOptionsCursor:
	coord hl, 1, 1
	ld [hl], " "
	coord hl, 1, 4
	ld bc, SCREEN_WIDTH
	ld a, 7
.clear
	ld [hl], " "
	add hl, bc
	dec a
	jr nz, .clear
	ld a, [wOptionsRow]
	and a
	coord hl, 1, 1
	jr z, .placeCursor
	coord hl, 1, 3
	call AddNTimes
.placeCursor
	ld [hl], "▶"
	coord hl, 0, 12
	lb bc, 4, SCREEN_WIDTH - 2
	call TextBoxBorder
	ld de, OptHelpPage
	ld a, [wOptionsRow]
	and a
	jr z, .placeHelp
	call CurrentOptionEntry
	inc hl
	inc hl
	ld a, [hli]
	ld d, [hl]
	ld e, a
.placeHelp
	coord hl, 1, 14
	jp PlaceString

; a = the option's index: its row, with the value right-aligned
DrawOption:
	push af
	coord hl, 2, 4
	ld bc, SCREEN_WIDTH
	call AddNTimes
	push hl
	ld a, " "
	ld b, SCREEN_WIDTH - 3
.clear
	ld [hli], a
	dec b
	jr nz, .clear
	pop de
	pop af
	push de
	call GetOptionEntry
	push hl
	call GetOptionValueName
	pop hl
	pop bc
	push hl ; the option
	push bc ; where its row starts
	jr z, .label
	call StringLength
	cpl
	add SCREEN_WIDTH - 2 ; 17 - the length: the value ends at column 18
	pop hl
	push hl
	add l
	ld l, a
	adc h
	sub l
	ld h, a
	call PlaceString
.label
	pop hl
	pop de
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld d, a
	ld e, c
	jp PlaceString

; a = the length of the string at de
StringLength:
	push de
	ld b, 0
.loop
	ld a, [de]
	cp "@"
	jr z, .done
	inc de
	inc b
	jr .loop
.done
	ld a, b
	pop de
	ret

; b = the buttons: A or RIGHT gives the option under the cursor its next value,
; LEFT its previous one. Returns carry when the page needs drawing again.
ChangeOption:
	push bc
	call CurrentOptionEntry
	pop bc
	ld de, OPT_KIND
	add hl, de
	ld a, [hli]
	cp OPT_ACTION
	jr z, .action
	ld c, 2
	cp OPT_BIT
	jr z, .gotCount
	ld c, [hl]
.gotCount
	push bc
	call CurrentOptionEntry
	call GetOptionValue
	pop bc
	bit BIT_D_LEFT, b
	jr nz, .previous
	inc a
	cp c
	jr c, .set
	xor a
	jr .set
.previous
	and a
	jr nz, .decrement
	ld a, c
.decrement
	dec a
.set
	push af
	call CurrentOptionEntry
	pop af
	call SetOptionValue
	ld a, [wOptionsRow]
	dec a
	call DrawOption
	and a
	ret
.action
	bit BIT_A_BUTTON, b
	ret z
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call CallOptionRoutine
	scf
	ret

; runs the routine at hl with a, keeping the menu's place (the routines draw
; palettes or other screens, which share its WRAM) and the a it returns
CallOptionRoutine:
	push af
	ld a, [wOptionsPage]
	ld d, a
	ld a, [wOptionsRow]
	ld e, a
	pop af
	push de
	call .jumpToRoutine
	pop de
	ld hl, wOptionsPage
	ld [hl], d
	ld hl, wOptionsRow
	ld [hl], e
	ret
.jumpToRoutine
	jp hl

; a = the value of the option at hl
GetOptionValue:
	ld de, OPT_KIND
	add hl, de
	ld a, [hli]
	ld c, [hl]
	inc hl
	ld e, [hl]
	inc hl
	ld d, [hl]
	cp OPT_BIT
	jr z, .bit
	cp OPT_CUSTOM
	jr z, .custom
	xor a
	ret
.custom
	ld h, d
	ld l, e
	jp CallOptionRoutine
.bit
	ld a, [de]
	and c
	ret z
	ld a, 1
	ret

; gives the option at hl the value a
SetOptionValue:
	ld b, a
	ld de, OPT_KIND
	add hl, de
	ld a, [hli]
	cp OPT_BIT
	jr nz, .custom
	ld c, [hl] ; two values: the new one is the other
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [hl]
	xor c
	ld [hl], a
	ret
.custom
	ld de, 3 ; the setter
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, b
	jp CallOptionRoutine

; de = the name of the value of the option at hl, and nz; z if it has none
GetOptionValueName:
	push hl
	call GetOptionValue
	pop hl
	ld de, OPT_VALUES
	add hl, de
	ld e, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	or h
	ret z
	ld d, 0
	add hl, de
	add hl, de
	ld a, [hli]
	ld d, [hl]
	ld e, a
	or 1
	ret

; hl = the page's name
GetOptionsPage:
	ld a, [wOptionsPage]
	add a
	ld e, a
	ld d, 0
	ld hl, OptionPages
	add hl, de
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ret

; a = the number of options on the page, hl = the first
GetOptionCount:
	call GetOptionsPage
.skipName
	ld a, [hli]
	cp "@"
	jr nz, .skipName
	ld a, [hli]
	ret

CurrentOptionEntry:
	ld a, [wOptionsRow]
	dec a
	; fall through
; hl = option a of the page
GetOptionEntry:
	push af
	call GetOptionCount
	pop af
	ld bc, OPT_LENGTH
	jp AddNTimes

; INST. (no delay), FAST, MEDIUM and SLOW: 0, 1, 3 and 5 frames a letter
GetTextSpeedOption:
	ld a, [wOptions]
	and TEXT_DELAY_BITS
	inc a
	srl a
	ret

SetTextSpeedOption:
	and a
	jr z, .delay
	add a
	dec a
.delay
	ld b, a
	ld a, [wOptions]
	and $ff ^ TEXT_DELAY_BITS
	or b
	ld [wOptions], a
	ret

; the move menu's effectiveness marks: OFF, ON, or LEARNED
; (engine/battle/type_chart.asm)
GetTypeHintOption:
	ld a, [wDisplayOptions]
	and TYPE_HINT_MASK
	rrca
	ret

SetTypeHintOption:
	add a
	ld b, a
	ld a, [wDisplayOptions]
	and $ff ^ TYPE_HINT_MASK
	or b
	ld [wDisplayOptions], a
	ret

; MONO, then the three stereo mixes
GetAudioOption:
	ld a, [wOptions]
	and SOUND_STEREO_BITS
	swap a
	ret

SetAudioOption:
	swap a
	ld b, a
	ld a, [wOptions]
	and $ff ^ SOUND_STEREO_BITS
	or b
	ld [wOptions], a
	ret

OptionsSoundTest:
	callba DisplaySoundTestMenu
	ret

; the overworld's further colors, on a Game Boy Color
GetMoreColorOption:
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	and ENH_GBC_COLORS
	ret z
	ld a, 1
	ret

SetMoreColorOption:
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	xor ENH_GBC_COLORS
	ld [wUnusedD721], a
	jp RunDefaultPaletteCommand

; the gamma shader for backlit screens: hGBC is 2 with it, 1 without, 0 off a
; Game Boy Color. The save keeps it (EVENT_9FE).
GetColorFixOption:
	ld a, [hGBC]
	cp 2
	ld a, 1
	ret z
	xor a
	ret

SetColorFixOption:
	ld a, [hGBC]
	and a
	ret z
	xor %11
	ld [hGBC], a
; RunDefaultPaletteCommand would otherwise undo the further colors
	ld hl, hFlagsFFFA
	set 5, [hl]
	call RunDefaultPaletteCommand
	ld hl, hFlagsFFFA
	res 5, [hl]
	ret

; #MON over the badges' level cap disobey; on, the value shows the cap
GetLevelCapOption:
	ld a, [wUnusedD721]
	bit 5, a
	ld a, 0
	ret z
	callba GetBadgeCap
	ld hl, wcf4b
	ld a, "<:L>"
	ld [hli], a
	ld a, "@"
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hl], a
	ld a, d
	ld [wNumSetBits], a
	ld hl, wcf4b + 1
	ld de, wNumSetBits
	lb bc, LEFT_ALIGN | 1, 3
	call PrintNumber
	ld a, 1
	ret

SetLevelCapOption:
	ld hl, wUnusedD721
	ld a, [hl]
	xor 1 << 5
	ld [hl], a
	ret

; OFF, TIER (each #MON swapped for one of its tier), FULL, or AREA (each
; encounter slot its own, every kind somewhere)
GetRandomWildOption:
	ld a, [wRandoFlags2]
	bit RANDO2_WILD_AREA_F, a
	ld a, 3
	ret nz
	CheckEvent EVENT_8DE
	ld a, 0
	ret z
	CheckEvent EVENT_8D7
	ld a, 1
	ret z
	inc a
	ret

SetRandomWildOption:
	call RandoOptionLocked
	ret c
	push af
	ld hl, wRandoFlags2
	res RANDO2_WILD_AREA_F, [hl]
	ResetEvent EVENT_8DE
	ResetEvent EVENT_8D7
	pop af
	and a
	ret z
	cp 3
	jr z, .area
	SetEvent EVENT_8DE
	dec a
	ret z
	SetEvent EVENT_8D7
	ret
.area
	ld hl, wRandoFlags2
	set RANDO2_WILD_AREA_F, [hl]
	ret

; OFF, ON (Shin's: regular trainers) or ALL (every trainer, themes kept)
GetRandomTrainersOption:
	ld a, [wRandoFlags2]
	bit RANDO2_TRAINERS_F, a
	ld a, 2
	ret nz
	CheckEvent EVENT_8D8
	ld a, 0
	ret z
	inc a
	ret

SetRandomTrainersOption:
	call RandoOptionLocked
	ret c
	push af
	ld hl, wRandoFlags2
	res RANDO2_TRAINERS_F, [hl]
	ResetEvent EVENT_8D8
	pop af
	and a
	ret z
	dec a
	jr nz, .all
	SetEvent EVENT_8D8
	ret
.all
	ld hl, wRandoFlags2
	set RANDO2_TRAINERS_F, [hl]
	ret

; the #MON and move choices: fields of wRandoFlags2 and 3
MACRO rando_field ; name, flags byte, first bit, mask
Get\1Option:
	ld a, [\2]
	and \4
	REPT \3
	srl a
	ENDR
	ret
Set\1Option:
	call RandoOptionLocked
	ret c
	REPT \3
	add a
	ENDR
	ld b, a
	ld a, [\2]
	and ~(\4)
	or b
	ld [\2], a
	ret
ENDM

	rando_field RandoStarters, wRandoFlags2, RANDO2_STARTERS_F, RANDO2_STARTERS
	rando_field RandoSpecial, wRandoFlags2, RANDO2_SPECIAL_F, 1 << RANDO2_SPECIAL_F
	rando_field RandoTrades, wRandoFlags2, RANDO2_TRADES_F, 1 << RANDO2_TRADES_F
	rando_field RandoTMMoves, wRandoFlags3, RANDO3_TM_MOVES_F, 1 << RANDO3_TM_MOVES_F
	rando_field RandoTMCompat, wRandoFlags3, RANDO3_TM_COMPAT_F, RANDO3_TM_COMPAT
	rando_field RandoLearnsets, wRandoFlags3, RANDO3_LEARN_F, RANDO3_LEARN

; carry (and a buzz) from the start menu: these are chosen before NEW GAME
; (a kept)
RandoOptionLocked:
	push af
	ld a, [wOptionsInGame]
	and a
	jr nz, .locked
	pop af
	and a
	ret
.locked
	ld a, SFX_DENIED
	call PlaySound
	pop af
	scf
	ret

; the randomizer's choices (wRandoFlags); shuffled doors need shuffled key
; items, so each turns the other on or off with it
GetRandoDoorsOption:
	ld c, 1 << RANDO_DOORS_F
	jr GetRandoOption
GetRandoKeysOption:
	ld c, 1 << RANDO_KEYS_F
	jr GetRandoOption
GetRandoItemsOption:
	ld c, 1 << RANDO_ITEMS_F
	jr GetRandoOption
GetRandoMartsOption:
	ld c, 1 << RANDO_MARTS_F
GetRandoOption:
	ld a, [wRandoFlags]
	and c
	ret z
	ld a, 1
	ret

SetRandoDoorsOption:
	ld c, 1 << RANDO_DOORS_F
	call SetRandoOption
	ret c
	ret z
	ld c, 1 << RANDO_KEYS_F
	jr SetRandoBit
SetRandoKeysOption:
	ld c, 1 << RANDO_KEYS_F
	call SetRandoOption
	ret c
	ret nz
	ld a, [wRandoFlags]
	res RANDO_DOORS_F, a
	ld [wRandoFlags], a
	ret
SetRandoItemsOption:
	ld c, 1 << RANDO_ITEMS_F
	jr SetRandoOption
SetRandoMartsOption:
	ld c, 1 << RANDO_MARTS_F
; a = 1: set the bit c, 0: clear it (nz if set); from the start menu,
; nothing (carry)
SetRandoOption:
	call RandoOptionLocked
	ret c
	ld b, a
	and a
	jr nz, SetRandoBit
	ld a, c
	cpl
	ld c, a
	ld a, [wRandoFlags]
	and c
	ld [wRandoFlags], a
	xor a ; z, no carry
	ret
SetRandoBit:
	ld a, [wRandoFlags]
	or c
	ld [wRandoFlags], a
	or 1 ; nz, no carry
	ret

; Starting a new game clears every event flag, so these two carry the rules
; that are event flags across it in wBuffer: a player can set them from the
; title screen's options before choosing NEW GAME.
MACRO rule_flag
	dwEventFlagAddress \1
	db 1 << ((\1) % 8)
ENDM

RuleFlags:
	rule_flag EVENT_8DE ; random wild
	rule_flag EVENT_8D7 ; full rather than tiered
	rule_flag EVENT_8D8 ; random trainers
	rule_flag EVENT_90C ; trainer scaling
	rule_flag EVENT_8C9 ; alternate trainer moves
	rule_flag EVENT_8D9 ; catch-up EXP
	rule_flag EVENT_90E ; caught and gender symbols
	rule_flag EVENT_8DB ; item clause
	rule_flag EVENT_8DC ; sleep clause
	rule_flag EVENT_8DD ; freeze clause
	rule_flag EVENT_8C8 ; hyper beam clause
	rule_flag EVENT_90F ; the SAFARI ZONE event
	rule_flag EVENT_WIN_HEAL
	rule_flag EVENT_BLACKOUT_RETURN
	rule_flag EVENT_PC_IN_MENU
	rule_flag EVENT_EXP_SHARE_ON
RuleFlagsEnd:

NUM_RULE_FLAGS EQU (RuleFlagsEnd - RuleFlags) / 3

SaveRuleFlags:
	ld hl, RuleFlags
	ld bc, wBuffer
.loop
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	ld a, [de]
	and [hl]
	inc hl
	ld [bc], a
	inc bc
	ld a, c
	cp LOW(wBuffer + NUM_RULE_FLAGS)
	jr nz, .loop
	ret

RestoreRuleFlags:
	ld hl, RuleFlags
	ld bc, wBuffer
.loop
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	inc hl
	ld a, [bc]
	push hl
	ld h, a
	ld a, [de]
	or h
	ld [de], a
	pop hl
	inc bc
	ld a, c
	cp LOW(wBuffer + NUM_RULE_FLAGS)
	jr nz, .loop
	ret

OptValuesOffOn:
	dw OptTextOff, OptTextOn
OptValuesOnOff:
	dw OptTextOn, OptTextOff
OptValuesTextSpeed:
	dw OptTextInstant, OptTextFast, OptTextMedium, OptTextSlow
OptValuesStyle:
	dw OptTextShift, OptTextSet
OptValuesAudio:
	dw OptTextMono, OptTextEarphone1, OptTextEarphone2, OptTextEarphone3
OptValuesFrameRate:
	dw OptText30, OptText60
OptValuesSprites:
	dw OptTextGen1, OptTextGen2
OptValuesLevelCap:
	dw OptTextOff, wcf4b ; GetLevelCapOption writes the cap there
OptValuesTypeHint:
	dw OptTextOff, OptTextOn, OptTextLearned
OptValuesRandomWild:
	dw OptTextOff, OptTextTier, OptTextFull, OptTextArea
OptValuesRandomTrainers:
	dw OptTextOff, OptTextOn, OptTextAll
OptValuesStarters:
	dw OptTextOff, OptTextRandom, OptTextTypes
OptValuesTMCompat:
	dw OptTextOff, OptTextType, OptTextRandom, OptTextFull
OptValuesLearnsets:
	dw OptTextOff, OptTextType, OptTextRandom, OptTextMetronome

OptTextOff:        db "OFF@"
OptTextOn:         db "ON@"
OptTextInstant:    db "INST.@"
OptTextFast:       db "FAST@"
OptTextMedium:     db "MEDIUM@"
OptTextSlow:       db "SLOW@"
OptTextShift:      db "SHIFT@"
OptTextSet:        db "SET@"
OptTextMono:       db "MONO@"
OptTextEarphone1:  db "EARPHONE1@"
OptTextEarphone2:  db "EARPHONE2@"
OptTextEarphone3:  db "EARPHONE3@"
OptText30:         db "30@"
OptText60:         db "60@"
OptTextGen1:       db "GEN 1@"
OptTextGen2:       db "GEN 2@"
OptTextTier:       db "TIER@"
OptTextFull:       db "FULL@"
OptTextArea:       db "AREA@"
OptTextAll:        db "ALL@"
OptTextRandom:     db "RANDOM@"
OptTextTypes:      db "TYPES@"
OptTextType:       db "TYPE@"
OptTextMetronome:  db "METRONOME@"
OptTextLearned:    db "LEARNED@"

OptTextTextSpeed:      db "TEXT SPEED@"
OptTextAnimation:      db "BATTLE ANIM@"
OptTextStyle:          db "BTL. STYLE@"
OptTextAudio:          db "AUDIO@"
OptTextSoundTest:      db "SOUND TEST@"
OptTextFrameRate:      db "FRAME RATE@"
OptTextSprites:        db "SPRITES@"
OptTextMoreColor:      db "MORE COLOR@"
OptTextColorFix:       db "COLOR FIX@"
OptTextSymbols:        db "SYMBOLS@"
OptTextTypeHint:       db "TYPE HINT@"
OptTextHPPercent:      db "HP PERCENT@"
OptTextExpShare:       db "EXP. SHARE@"
OptTextHardMode:       db "HARD MODE@"
OptTextAISwitching:    db "AI SWITCHING@"
OptTextLevelCap:       db "LEVEL CAP@"
OptTextScaling:        db "SCALING@"
OptTextAltMoves:       db "ALT. MOVES@"
OptTextNuzlocke:       db "NUZLOCKE@"
OptTextItemClause:     db "ITEM@"
OptTextSleepClause:    db "SLEEP@"
OptTextFreezeClause:   db "FREEZE@"
OptTextBeamClause:     db "HYPER BEAM@"
OptTextWinHeal:        db "HEAL ON WIN@"
OptTextWarpBack:       db "WARP BACK@"
OptTextCatchUpExp:     db "CATCH-UP EXP@"
OptTextRandomWild:     db "WILD@"
OptTextRandomTrainers: db "TRAINERS@"
OptTextSafari:         db "SAFARI EVENT@"
OptTextRandoDoors:     db "DOORS@"
OptTextRandoKeys:      db "KEY ITEMS@"
OptTextRandoItems:     db "ITEMS@"
OptTextRandoMarts:     db "MARTS@"
OptTextRandoTrades:    db "TRADES@"
OptTextRandoStarters:  db "STARTERS@"
OptTextRandoSpecial:   db "SPECIAL MON@"
OptTextRandoTMMoves:   db "TM MOVES@"
OptTextRandoTMCompat:  db "TM COMPAT.@"
OptTextRandoLearnsets: db "LEARNSETS@"
OptTextMenuPC:         db "PC IN MENU@"

; the explanations: two lines of at most 18 letters
OptHelpPage:
	db   "◀ ▶ or SELECT turn"
	next "the page. B: done.@"
OptHelpTextSpeed:
	db   "How fast text is"
	next "printed.@"
OptHelpAnimation:
	db   "Show the moves'"
	next "battle animations.@"
OptHelpStyle:
	db   "SHIFT: may switch"
	next "after a foe faints@"
OptHelpAudio:
	db   "MONO, or a stereo"
	next "mix for earphones.@"
OptHelpSoundTest:
	db   "Press A to play"
	next "the game's music.@"
OptHelpFrameRate:
	db   "60 is smoother but"
	next "experimental.@"
OptHelpSprites:
	db   "GEN 2 shows the"
	next "CRYSTAL sprites.@"
OptHelpMoreColor:
	db   "More color in the"
	next "overworld. (GBC)@"
OptHelpColorFix:
	db   "Softer colors for"
	next "backlit screens.@"
OptHelpSymbols:
	db   "Caught and gender"
	next "marks in battle.@"
OptHelpTypeHint:
	db   "▴▼ marks on moves;"
	next "LEARNED: once seen@"
OptHelpHPPercent:
	db   "The foe's HP as a"
	next "percentage.@"
OptHelpExpShare:
	db   "ON: the whole team"
	next "gains EXP (Gen 9).@"
OptHelpHardMode:
	db   "Tougher trainers,"
	next "no battle REVIVEs.@"
OptHelpAISwitching:
	db   "Trainers swap out"
	next "#MON smartly.@"
OptHelpLevelCap:
	db   "#MON over your"
	next "badge cap disobey.@"
OptHelpScaling:
	db   "Trainers' teams"
	next "match your level.@"
OptHelpAltMoves:
	db   "Trainers' #MON"
	next "know better moves.@"
OptHelpNuzlocke:
	db   "#MON that faint"
	next "die. 1 catch/area.@"
OptHelpItemClause:
	db   "No one uses items"
	next "in trainer fights.@"
OptHelpSleepClause:
	db   "Only one #MON"
	next "asleep per team.@"
OptHelpFreezeClause:
	db   "Only one #MON"
	next "frozen per team.@"
OptHelpBeamClause:
	db   "No recharge turn"
	next "if HYPER BEAM KOs.@"
OptHelpWinHeal:
	db   "Heal your party"
	next "after trainer wins@"
OptHelpWarpBack:
	db   "After a blackout,"
	next "offer a warp back.@"
OptHelpCatchUpExp:
	db   "More EXP when the"
	next "foe outlevels you.@"
OptHelpRandomWild:
	db   "TIER keeps power;"
	next "AREA: by the spot.@"
OptHelpRandomTrainers:
	db   "ON: regular ones;"
	next "ALL keeps themes.@"
OptHelpRandoTrades:
	db   "NEW GAME: shuffle"
	next "in-game trades.@"
OptHelpRandoStarters:
	db   "TYPES: each beats"
	next "the next in turn.@"
OptHelpRandoSpecial:
	db   "Gifts, legends,"
	next "SNORLAX, prizes.@"
OptHelpRandoTMMoves:
	db   "What each TM"
	next "teaches (not HMs).@"
OptHelpRandoTMCompat:
	db   "Who can learn TMs;"
	next "TYPE: mostly own.@"
OptHelpRandoLearnsets:
	db   "Level-up moves;"
	next "TYPE: mostly own.@"
OptHelpRandoDoors:
	db   "NEW GAME: shuffle"
	next "doors and keys.@"
OptHelpRandoKeys:
	db   "NEW GAME: shuffle"
	next "key items and HMs.@"
OptHelpRandoItems:
	db   "NEW GAME: shuffle"
	next "other found items.@"
OptHelpRandoMarts:
	db   "NEW GAME: shuffle"
	next "what marts sell.@"
OptHelpSafari:
	db   "SAFARI ZONE: more"
	next "kinds, better IVs.@"
OptHelpMenuPC:
	db   "Use the PC from"
	next "the START menu.@"
