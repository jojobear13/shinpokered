_TM18PreReceiveText::
	text "Oh, hi! I finally"
	line "finished #mon!"

	para "Not done yet?"
	line "This might be"
	cont "useful!"
	prompt

_ReceivedTM18Text::
	text "<PLAYER> received"
	line "@"
	TX_RAM wcf4b
	text "!@@"

_TM18ExplanationText::
	text "TM18 is counter!"
	line "Not like the one"
	cont "I'm leaning on,"
	cont "mind you!"
	
	para "It meets normal"
	line "or fighting moves"
	cont "with 2x damage!"
	done

_TM18NoRoomText::
	text "Your pack is full"
	line "of items!"
	done

_CeladonMart3Text2::
	text "Captured #mon"
	line "are registered"
	cont "with an ID No."
	cont "and OT, the name"
	cont "of the Original"
	cont "Trainer that"
	cont "caught it!"
	done

IF DEF(_JPTXT)	;joenote - this was changed in the localization for some reason
_CeladonMart3Text3::
	text "All right!"

	para "My buddy's going"
	line "to trade me his"
	cont "Kangaskhan for my"
	cont "Haunter!"
	done

_CeladonMart3Text4::
	text "Come on, my sweet"
	line "haunty-pie!"

	para "I'm an absolute"
	line "Haunter maniac."

	para "... ...Huh?"

	para "Haunter turned"
	line "into a different"
	cont "#mon!"
	done
ELSE
_CeladonMart3Text3::
	text "All right!"

	para "My buddy's going"
	line "to trade me his"
	cont "Kangaskhan for my"
	cont "Graveler!"
	done

_CeladonMart3Text4::
	text "Come on Graveler!"

	para "I love Graveler!"
	line "I collect them!"

	para "Huh?"

	para "Graveler turned"
	line "into a different"
	cont "#mon!"
	done
ENDC

_CeladonMart3Text5::
	text "You can identify"
	line "#mon you got"
	cont "in trades by"
	cont "their ID Numbers!"
	done

_CeladonMart3Text6::
	text "It's an SNES!"
	done

_CeladonMart3Text7::
	text "An RPG! There's"
	line "no time for that!"
	done

_CeladonMart3Text9::
	text "A sports game!"
	line "Dad'll like that!"
	done

_CeladonMart3Text11::
	text "A puzzle game!"
	line "Looks addictive!"
	done

_CeladonMart3Text13::
	text "A fighting game!"
	line "Looks tough!"
	done

_CeladonMart3Text14::
	text "3F: TV Game Shop"
	done

_CeladonMart3Text15::
	text "That little man"
	line "jumps really high!"
	done

_CeladonMart3Blocker::
	text "This vendor will"
	line "be open after the"
	cont "#mon League"
	cont "Championship."
	
	para "Come back to buy"
	line "rare new items"
	cont "from Silph Co."
	
	para "Phew!"
	line "It is really hot"
	cont "in this costume."
	done