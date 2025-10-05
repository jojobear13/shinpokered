SchoolScript:
	jp EnableAutoTextBoxDrawing

SchoolTextPointers:
	dw SchoolText1
	dw SchoolText2
	dw SchoolText3 ;joenote - added more text
	dw AltMoveListsText ;joenote - added npc toggle for alt move lists

SchoolText1:
	TX_FAR _SchoolText1
	db "@"

SchoolText2:
	TX_FAR _SchoolText2
	db "@"

SchoolText3:
	TX_FAR _SchoolText3
	db "@"
	
;;;;;;;;;;;;;;;;;;;;;;;;;joenote - added npc toggle for alt move lists
AltMoveListsText:
	TX_ASM
	CheckEvent EVENT_8C9
	jr z, .AltMovesON
	ld hl, AltMoveListsOFF 
	call PrintText
	call .choose
	ld hl, AltMoveLists_Gambler_reject
	jr z, .end
	ResetEvent EVENT_8C9
	jr .print_done
.AltMovesON
	ld hl, AltMoveListsON
	call PrintText
	call .choose
	ld hl, AltMoveLists_Gambler_reject
	jr z, .end
	SetEvent EVENT_8C9
.print_done
	ld hl, AltMoveLists_Gambler_done
.end
	call PrintText
	jp TextScriptEnd
.choose
	call NoYesChoice
	ld a, [wCurrentMenuItem]
	and a
	ret

AltMoveListsON:
	text "Feelin' lucky?"
	line "Wanna test yer"
	cont "#MON skills?"
	
	para "I'll set it up so"
	line "#MON of other"
	cont "trainers can have"
	cont "altered move sets"
	cont "in subtle ways."
	done
	db "@"
AltMoveListsOFF:
	text "Undo the trainer"
	line "move changes?"
	done
	db "@"

AltMoveLists_Gambler_done:
	text "I've made it so."
	line "Good luck, kid."
	done
	db "@"
AltMoveLists_Gambler_reject:
	text "No? Alright then."
	line "Maybe later."
	done
	db "@"
