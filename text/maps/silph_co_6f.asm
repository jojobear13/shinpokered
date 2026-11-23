_SilphCo6Text_1a24a::
	text "The Rockets came"
	line "and took over the"
	cont "building!"
	done

_SilphCo6Text_1a24f::
	text "Well, better get"
	line "back to work!"
	done

_SilphCo6Text_1a261::
	text "Oh dear, oh dear."
	line "Help me please!"
	done

_SilphCo6Text_1a266::
	text "We got engaged!"
	line "Heheh!"
	done

_SilphCo6Text_1a278::
	text "Look at him! He's"
	line "such a coward!"
	done

_SilphCo6Text_1a27d::
	text "I feel so sorry"
	line "for him, I have"
	cont "to marry him!"
	done

_SilphCo6Text_1a28f::
	text "Team Rocket is"
	line "trying to conquer"
	cont "the world with"
	cont "#mon!"
	done

_SilphCo6Text_1a294::
	text "Team Rocket ran"
	line "because of you!"
	done

_SilphCo6Text_1a2a6::
	text "They must have"
	line "targeted Silph"
	cont "for our #mon"
	cont "products."
	done

_SilphCo6Text_1a2ab::
	text "Come work for"
	line "Silph when you"
	cont "get older!"
	done

_SilphCo6BattleText2::
	text "I am one of the 4"
	line "Rocket Brothers!"
	done

_SilphCo6EndBattleText2::
	text "Flame"
	line "out!"
	prompt

_SilphCo6AfterBattleText2::
	text "No matter!"
	line "My brothers will"
	cont "avenge me!"
	done

_SilphCo6BattleText3::
	text "That rotten"
	line "president!"

	para "He shouldn't have"
	line "sent me to the"
IF DEF(_JPTXT)
	cont "tunguska branch!"
ELSE
	cont "Wintown branch!"
ENDC
	done

_SilphCo6EndBattleText3::
	text "Shoot!"
	prompt

_SilphCo6AfterBattleText3::
IF DEF(_JPTXT)
	text "Tunguska branch?"
ELSE
	text "Wintown branch?"
ENDC
	line "It's in Fiore's"
	cont "no man's land!"
	done

_SilphCo6BattleText4::
	text "You dare betray"
	line "Team Rocket?"
	done

_SilphCo6EndBattleText4::
	text "You"
	line "traitor!"
	prompt

_SilphCo6AfterBattleText4::
	text "If you stand for"
	line "justice, you"
	cont "betray evil!"
	done
