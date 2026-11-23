_LavenderHouse1Text_1d8d1::
	text "That's odd, mr.Fuji"
	line "isn't here."
	cont "Where'd he go?"
	done

_LavenderHouse1Text_1d8d6::
	text "Mr.Fuji had been"
	line "praying alone for"
	cont "Cubone's mother."
	done

_LavenderHouse1Text_1d8f4::
	text "This is really"
	line "mr.Fuji's house."

	para "He's really kind!"

	para "He looks after"
	line "abandoned and"
	cont "orphaned #mon!"
	done

_LavenderHouse1Text_1d8f9::
	text "It's so warm!"
	line "#mon are so"
	cont "nice to hug!"
	done

_LavenderHouse1Text3::
	text "Psyduck: Gwappa!@@"

_LavenderHouse1Text4::
	text "Nidorino: Gaoo!@@"

_LavenderHouse1Text_1d94c::
	text "Mr.Fuji: <PLAYER>."

	para "Your #dex quest"
	line "may fail without"
	cont "love for your"
	cont "#mon."

	para "I think this may"
	line "help your quest."
	prompt

_ReceivedFluteText::
	text "<PLAYER> received"
	line "a @"
	TX_RAM wcf4b
	text "!@@"

_FluteExplanationText::
	db $0
	para "Upon hearing #"
	line "Flute, sleeping"
	cont "#mon will"
	cont "spring awake."

	para "It works on all"
	line "sleeping #mon."
	done

_FluteNoRoomText::
	text "You must make"
	line "room for this!"
	done

_MrFujiAfterFluteText::
	text "Mr.Fuji: Has my"
	line "flute helped you?"
	done

_LavenderHouse1Text6::
	text "#mon Monthly"
	line "Grand Prize"
	cont "Drawing!"

	para "The application"
	line "form is..."

	para "Gone! It's been"
	line "clipped out!"
	done

;;;;;;;;;;;;;;;;;;;;;;joenote - adding text for fuji battle
_FujiText_challenge::
	text "Do you challenge"
	line "mr.Fuji to a"
	cont "#mon battle?"
	done

_FujiText_prebattle::
	text "So you know about"
	line "my former life as"
	cont "a scientist."
	
	para "Then you also"
	line "know why I quit."
	
	para "The gene splicing"
	line "data, samples,"
	cont "test subjects..."
	
	para "All was cast into"
	line "the waters of an"
	cont "unknown dungeon"
	
	para "I'd advise you to"
	line "stay away from"
	cont "there and leave"
	cont "the past buried."
	done

_FujiTextVictorySpeech::
	text "Hmm..."
	line "I'm a bit worried."
	
	para "The test dittos"
	line "might still be"
	cont "replicating."
	
	para "Who knows what"
	line "kind of #mon"
	cont "they might have"
	cont "cloned themselves"
	cont "into?"

	para "Go if you must."
	line "Maybe it's you"
	cont "who can help fix"
	cont "past mistakes."

	para "Silph's chief is"
	line "an old friend, so"
	cont "battle him too."
	prompt
	
_FujiTextMewtwo::
	text "That Mewtwo you"
	line "have with you..."
	
	para "...Such an angry"
	line "disposition. Yet"
	cont "you have soothed"
	cont "its wrath."
	
	para "You must possess"
	line "a great love for"
	cont "your #mon."
	
	para "Take this. I have"
	line "no reason to keep"
	cont "holding onto it."
	prompt
