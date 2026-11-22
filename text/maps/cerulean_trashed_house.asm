_CeruleanTrashedText_1d6ab::
	text "Those miserable"
	line "Rockets!"

	para "Look what they"
	line "did here!"

	para "They stole a TM"
	line "for teaching"
	cont "#mon how to"
	cont "dig holes!"

	para "That cost me a"
	line "bundle, it did!"
	done

_CeruleanTrashedText_1d6b0::
	text "I figure what's"
	line "lost is lost!"

	para "I decided to teach"
	line "Diglett how to"
	cont "dig without a TM!"
	done

_CeruleanHouseTrashedText2::
	text "Team Rocket must"
	line "be trying to dig"
	cont "their way into no"
	cont "good!"
	done

IF DEF(_JPTXT)
_CeruleanHouseTrashedText3::
	text "You can exit via"
	line "this wall breach!"
	done
ELSE
_CeruleanHouseTrashedText3::
	text "Team Rocket left"
	line "a way out!"
	done
ENDC
