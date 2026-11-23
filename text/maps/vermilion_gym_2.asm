_VermilionGymText_5cb72::
	text "A little word of"
	line "advice, kid!"

	para "Electricity is"
	line "sure powerful!"

	para "But, it's useless"
	line "against ground-"
	cont "type #mon!"
	done

_VermilionGymText_5cb77::
	text "The Thunderbadge"
	line "cranks up your"
	cont "#mon's defense!"	;joenote - changed SPEED to DEFENSE in order to fix a typo

	para "It also lets your"
	line "#mon fly any"
	cont "time, kid!"

	para "You're special,"
	line "kid! Take this!"
	done

_ReceivedTM24Text::
	text "<PLAYER> received "
	line "@"
	TX_RAM wcf4b
	text "!@@"

_TM24ExplanationText::
	db $0
	para "TM24 contains"
	line "thunderbolt!"

	para "Teach it to an"
	line "electric #mon!"
	done

_TM24NoRoomText::
	text "Yo kid, make room"
	line "in your pack!"
	done

_ReceivedThunderbadgeText::
	text "Whoa!"

	para "You're the real"
	line "deal, kid!"

	para "Fine then, take"
	line "the Thunderbadge!"
	prompt

_VermilionGymBattleText1::
	text "When I was in the"
	line "Army, lt.Surge"
	cont "was my strict co!"
	done

_VermilionGymEndBattleText1::
	text "Stop!"
	line "You're very good!"
	prompt

_VermilionGymAfterBattleText1::
	text "The door won't"
	line "open?"

	para "Lt.Surge always"
	line "was cautious!"
	done

_VermilionGymBattleText2::
	text "I'm a lightweight,"
	line "but I'm good with"
	cont "electricity!"
	done

_VermilionGymEndBattleText2::
	text "Fried!"
	prompt

_VermilionGymAfterBattleText2::
	text "Okay, I'll talk!"

	para "Lt.Surge said he"
	line "hid door switches"
	cont "inside something!"
	done

_VermilionGymBattleText3::
	text "This is no place"
	line "for kids!"
	done

_VermilionGymEndBattleText3::
	text "Wow!"
	line "Surprised me!"
	prompt

_VermilionGymAfterBattleText3::
	text "Lt.Surge set up"
	line "double locks!"
	cont "Here's a hint!"

	para "When you open the"
	line "1st lock, the 2nd"
	cont "lock is right"
	cont "next to it!"
	done

_VermilionGymText_5cbf4::
	text "Yo! Champ in"
	line "making!"

	para "Lt.Surge has a"
	line "nickname. People"
	cont "refer to him as"
	cont "the Lightning"
	cont "Unovan!"

	para "He's an expert on"
	line "electric #mon!"

;	para "Birds and water"	;joenote - This is a text error that was translated. Supposed to be flying not bird.
	para "Flying and water"
	line "#mon are at"
	cont "risk! Beware of"
	cont "paralysis too!"

	para "Lt.Surge is very"
	line "cautious!"

	para "You'll have to"
	line "break a code to"
	cont "get to him!"
	done

_VermilionGymText_5cbf9::
	text "Whew! That match"
	line "was electric!"
	done
