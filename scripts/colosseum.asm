ColosseumScript:
	jp TradeCenterScript

ColosseumTextPointers:
	dw ColosseumText1
	dw ColosseumResetClauses

ColosseumText1:
	TX_FAR _ColosseumText1
	db "@"

;joenote - for battle clauses	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ColosseumResetClauses:
	TX_ASM
	ld a, 1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld hl, _TXTAskReset
	call PrintText
	call .choice
	jr z, .end
	
	ResetEvent EVENT_8DC 
	ResetEvent EVENT_8DD 
	ResetEvent EVENT_8C5 
	ResetEvent EVENT_8C8 
	
	ld hl, _TXTSleep
	call PrintText
	call .choice
	call nz, .sleep

	ld hl, _TXTFreeze
	call PrintText
	call .choice
	call nz, .freeze

	ld hl, _TXTTrap
	call PrintText
	call .choice
	call nz, .trapping

	ld hl, _TXTHBeam
	call PrintText
	call .choice
	call nz, .hyperbeam

.end
	xor a
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld hl, _TXTDone
	call PrintText
	jp TextScriptEnd

.choice
	call NoYesChoice ; no/yes menu
	ld a, [wCurrentMenuItem]
	and a
	ret
.sleep
	SetEvent EVENT_8DC 
	ret
.freeze
	SetEvent EVENT_8DD 
	ret
.trapping
	SetEvent EVENT_8C5 
	ret
.hyperbeam
	SetEvent EVENT_8C8 
	ret

_TXTAskReset:
	text "Any battle clauses"
	line "you have active"
	cont "will be combined"
	cont "with those of the"
	cont "opponent."

	para "Want to erase and"
	line "re-select your"
	cont "clauses?"
	done
	db "@"

_TXTSleep:
	text "Activate"
	line "sleep clause?"
	done
	db "@"

_TXTFreeze:
	text "Activate"
	line "freeze clause?"
	done
	db "@"

_TXTTrap:
	text "Activate"
	line "trapping clause?"
	done
	db "@"

_TXTHBeam:
	text "Activate Hyper"
	line "Beam clause?"
	done
	db "@"

_TXTDone:
	text "Confirmed!"
	done
	db "@"
