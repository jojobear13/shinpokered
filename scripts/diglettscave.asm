;joenote - add secret cave for mist_stone with associated warps
DiglettsCaveScript:
	jp EnableAutoTextBoxDrawing

DiglettsCaveTextPointers:
;	db "@"
	dw Mist_Stone_Text
	dw BoulderText
	
Mist_Stone_Text:
	TX_ASM

	CheckEvent EVENT_8C4
	jr nz, .read_book
	
	CheckEvent EVENT_8C3
	jr z, .read_book
	
.mist_stone
	;give MIST_STONE item
	lb bc, MIST_STONE, 1
	call GiveItem
	ld hl, _TXTBag
	jr nc, .next	;jump if not enough room in bag
	SetEvent EVENT_8C4
	ld hl, _TXTMist_Stone
	call PrintText
	ld a, SFX_GET_ITEM_1
	call PlaySound 
	call WaitForSoundToFinish
	jr .end

.read_book		
	ld a, $1
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a

	ld hl, _TXTBookDesc
	call PrintText
	call .choice
	jr nz, .end
	
	ld hl, _TXTBookP1
	call PrintText
	call .choice
	jr nz, .end
	
	ld hl, _TXTBookP2
	call PrintText
	call .choice
	jr nz, .end
	
	xor a
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ld hl, _TXTBookP3
.next
	call PrintText
.end
	jp TextScriptEnd
.choice
	call YesNoChoice ; yes/no menu
	ld a, [wCurrentMenuItem]
	and a
	ret
	
_TXTBookDesc:
	text "This journal is"
	line "badly rotted from"
	cont "the heavy mist"
	cont "within this cave."

	para "A few parts are"
	line "still legible."
	cont "Try reading it?"
	done
	db "@"

_TXTBookP1:
	text "This is my secret"
	line "room. It was dug-"
	cont "out by a group of"
	cont "wild Diglett."

	para "Read some more?"
	done
	db "@"

_TXTBookP2:
	text "I heard Bill has"
	line "a secret garden"
	cont "behind his house."
	
	para "But he'll neither"
	line "confirm nor deny"
	cont "it to anyone."
	
	para "Maybe if I show"
	line "him a new species"
	cont "of #mon..."
	
	para "Keep reading?"
	done
	db "@"
	
_TXTBookP3:
	text "It's said that a"
	line "Mist Stone can"
	cont "unlock the hidden"
	cont "potential within"
	cont "a #mon."
	
	para "Where to find it?"
	line "Perhaps here, in"
	cont "this very room."
	
	para "The misty air of"
	line "this cave might"
	cont "provide the right"
	cont "conditions."
	done
	db "@"
	
_TXTMist_Stone:
	text "Under the rotted"
	line "journal is a"
	cont "small crevice in"
	cont "the floor."
	
	para "An object shines"
	line "a little ways in."
	
	para "You recieved the"
	line "Mist Stone!@@"
	db "@"
	
_TXTBag:
	text "There's something"
	line "here, but your"
	cont "bag is full."
	done
	db "@"
