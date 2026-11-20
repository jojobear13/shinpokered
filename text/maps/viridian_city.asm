_ViridianCityText1::
	text "Those # BALLs"
	line "at your waist!"
	cont "You have #mon!"

	para "It's great that"
	line "you can carry and"
	cont "use #mon any"
	cont "time, anywhere!"
	done

_ViridianCityText_19122::
	text "This #mon gym"
	line "is always closed."

	para "I wonder who the"
	line "leader is?"
	done

_ViridianCityText_19127::
	text "Viridian gym's"
	line "leader returned!"
	done

_ViridianCityText_1914d::
	text "You want to know"
	line "about the 2 kinds"
	cont "of caterpillar"
	cont "#mon?"
	done

_ViridianCityText_19152::
	text "Oh, OK then!"
	done

_ViridianCityText_19157::
	text "Caterpie has no"
	line "poison, but"
	cont "Weedle does."

	para "Watch out for its"
	line "Poison Sting!"
	done
IF DEF(_JPTXT)
_ViridianCityText_19175::
	text "Oh Grandpa! Don't"
	line "pass out here!"
	cont "My goodness..."
	cont "Sorry, but we'll"
	cont "have to wait till"
	cont "he sobers up."
	done
ELSE
_ViridianCityText_19175::
	text "Oh Grandpa! Don't"
	line "be so mean!"
	cont "He hasn't had his"
	cont "coffee yet."
	done
ENDC

_ViridianCityText_1917a::
	text "When I go shop in"
	line "Pewter City, I"
	cont "have to take the"
	cont "winding trail in"
	cont "Viridian Forest."
	done

IF DEF(_JPTXT)
_ViridianCityText_19191::
	text "Urgh! Hic..."
	line "hold on there!"
	cont "C'mere an lissen"
	cont "to what I hafta"
	cont "say!"

	para "...Hey!"
	line "I said don't go!"
	done
ELSE
_ViridianCityText_19191::
	text "You can't go"
	line "through here!"

	para "This is private"
	line "property!"
	done
ENDC

_ViridianCityText_191ca::
	text "Yawn!"
	line "I must have dozed"
	cont "off in the sun."

	para "I had this dream"
	line "about a Drowzee"
	cont "eating my dream."
	cont "What's this?"
	cont "Where did this TM"
	cont "come from?"

	para "This is spooky!"
	line "Here, you can"
	cont "have this TM."
	prompt

_ReceivedTM42Text::
	text "<PLAYER> received"
	line "TM42!@@"

_TM42Explanation::
	text "TM42 contains"
	line "Dream Eater..."
	cont "...Snore..."
	done

_TM42NoRoomText::
	text "You have too much"
	line "stuff already."
	done
IF DEF(_JPTXT)
_ViridianCityText_1920a::
	text "Mmm......"
	line "Seems like I was"
	cont "pretty drunk!"

	para "My head hurts..."

	para "Are you in a"
	line "hurry?"
	done
ELSE
_ViridianCityText_1920a::
	text "Ahh, I've had my"
	line "coffee now and I"
	cont "feel great!"

	para "Sure you can go"
	line "through!"

	para "Are you in a"
	line "hurry?"
	done
ENDC

_ViridianCityText_1920f::
	text "I see you're using"
	line "a #dex."

	para "When you catch a"
	line "#mon, #dex"
	cont "is automatically"
	cont "updated."

	para "What? Don't you"
	line "know how to catch"
	cont "#mon?"

	para "I'll show you"
	line "how to then."
	done

_ViridianCityText_19214::
	text "Time is money..."
	line "Go along then."
	done

_ViridianCityText_19219::
	text "First, you need"
	line "to weaken the"
	cont "target #mon."
	done

_ViridianCityText8::
	text "Viridian City "
	line "The Eternally"
	cont "Green Paradise"
	done

_ViridianCityText9::
	text "Trainer tips"

	para "Catch #mon"
	line "and expand your"
	cont "collection!"

	para "The more you have,"
	line "the easier it is"
	cont "to fight!"
	done

_ViridianCityText10::
	text "Trainer tips"

	para "The battle moves"
	line "of #mon are"
	cont "limited by their"
	cont "power POINTs, PP."

	para "To replenish PP,"
	line "rest your tired"
	cont "#mon at a"
	cont "#mon Center!"
	done

_ViridianCityText13::
	text "Viridian City"
	line "#mon gym"
	done

_ViridianCityText14::
	text "The gym's doors"
	line "are locked..."
	done
