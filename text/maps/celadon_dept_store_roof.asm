_CeladonMartRoofText_484ee::
	text "Give her which"
	line "drink?"
	done

_CeladonMartRoofText_484f3::
	text "Yay!"

	para "Fresh Water!"

	para "Thank you!"

	para "You can have this"
	line "from me!@@"

_CeladonMartRoofText_484f9::
	text "<PLAYER> received"
	line "@"
	TX_RAM wcf4b
	text "!@@"

_CeladonMartRoofText_484fe::
	db $0
	para "@"
	;TX_RAM wcf4b
	;text " contains"
	text "TM13 contains"	;joenote - don't dynamically call the name as it just messes up the text borders
	line "Ice Beam!"

	para "It can freeze the"
	line "target sometimes!@@"

_CeladonMartRoofText_48504::
	text "Yay!"

	para "Soda Pop!"

	para "Thank you!"

	para "You can have this"
	line "from me!@@"

_CeladonMartRoofText_4850a::
	text "<PLAYER> received"
	line "@"
	TX_RAM wcf4b
	text "!@@"

_CeladonMartRoofText_4850f::
	db $0
	para "@"
	;TX_RAM wcf4b
	;text " contains"	;joenote - don't dynamically call the name as it just messes up the text borders
	text "TM48 contains"
;	line "ROCK SLIDE!"	;joenote - this is inaccurate in gen 1, and Yellow removes this text.
;
;	para "It can spook the"
;	line "target sometimes!@@"
	line "Rock Slide!@@"

_CeladonMartRoofText_48515::
	text "Yay!"

	para "Lemonade!"

	para "Thank you!"

	para "You can have this"
	line "from me!@@"

_ReceivedTM49Text::
	text "<PLAYER> received"
	line "TM49!@@"

_CeladonMartRoofText_48520::
	db $0
	para "TM49 contains"
	line "Tri Attack!@@"

_CeladonMartRoofText_48526::
	text "You don't have"
	line "space for this!@@"

_CeladonMartRoofText_4852c::
	text "No thank you!"
	line "I'm not thirsty"
	cont "after all!@@"

_CeladonMartRoofText1::
	text "My sister is a"
	line "trainer, believe"
	cont "it or not."

	para "But, she's so"
	line "immature, she"
	cont "drives me nuts!"
	done

_CeladonMartRoofText_48598::
	text "I'm thirsty!"
	line "I want something"
	cont "to drink!"
	done

_CeladonMartRoofText4::
	text "I'm thirsty!"
	line "I want something"
	cont "to drink!"

	para "Give her a drink?"
	done

_CeladonMartRoofText6::
	text "Rooftop square:"
	line "vending machines"
	done

_VendingMachineText1::
	text "A vending machine!"
	line "Here's the menu!"
	prompt

_VendingMachineText4::
	text "Oops, not enough"
	line "money!"
	done

_VendingMachineText5::
	TX_RAM wcf4b
	db $0
	line "popped out!"
	done

_VendingMachineText6::
	text "There's no more"
	line "room for stuff!"
	done

_VendingMachineText7::
	text "Not thirsty!"
	done
