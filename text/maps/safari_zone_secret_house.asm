_SecretHouseText_4a350::
	text "Ah! Finally!"

	para "You're the first"
	line "person to reach"
	cont "the secret house!"

	para "I was getting"
	line "worried that no"
	cont "one would win our"
	cont "campaign prize."

	para "Congratulations!"
	line "You have won!"

;joenote - add hotkey info
	para "Press Select when"
	line "you are facing a"
	cont "shore to use it."	
	prompt

_ReceivedHM03Text::
	text "<PLAYER> received"
	line "@"
	TX_RAM wcf4b
	text "!@@"

_HM03ExplanationText::
	text "HM03 is Surf!"

	para "#mon will be"
	line "able to ferry you"
	cont "across water!"

	para "And, this HM isn't"
	line "disposable! You"
	cont "can use it over"
	cont "and over!"

	para "You're super lucky"
	line "for winning this"
	cont "fabulous prize!"
	done

_HM03NoRoomText::
	text "You don't have"
	line "room for this"
	cont "fabulous prize!"
	done
