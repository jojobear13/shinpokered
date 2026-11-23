_Route24BattleText1::
	text "I saw your feat"
	line "from the grass!"
	done

_Route24EndBattleText1::
	text "I"
	line "thought not!"
	prompt

_Route24AfterBattleText1::
	text "I hid because the"
	line "people on the"
	cont "bridge scared me!"
	done

_Route24BattleText2::
	text "OK! I'm No. 5!"
IF DEF(_JPTXT)	;joenote - dirty joke lost in translation
	line "This time, I'll"
	cont "be your partner."
ELSE
	line "I'll stomp you!"
ENDC
	done

_Route24EndBattleText2::
	text "Whoa!"
IF DEF(_JPTXT)	;joenote - dirty joke lost in translation
	line "You're too wild"
	cont "for me!"
ELSE
	line "Too much!"
ENDC
	prompt

_Route24AfterBattleText2::
	text "I did my best, I"
	line "have no regrets!"
	done

_Route24BattleText3::
	text "I'm No. 4!"
	line "Getting tired?"
	done

_Route24EndBattleText3::
	text "I lost"
	line "too!"
	prompt

_Route24AfterBattleText3::
	text "I did my best, so"
	line "I've no regrets!"
	done

_Route24BattleText4::
	text "Here's No. 3!"
IF DEF(_JPTXT)	;joenote - dirty joke lost in translation
	line "I won't finish"
	cont "so quickly!"
ELSE
	line "I won't be easy!"
ENDC
	done

_Route24EndBattleText4::
IF DEF(_JPTXT)	;joenote - dirty joke lost in translation
	text "Ugh!"
	line "I can't last"
	cont "any longer."
ELSE
	text "Ow!"
	line "Stomped flat!"
ENDC
	prompt

_Route24AfterBattleText4::
	text "I did my best, I"
	line "have no regrets!"
	done

_Route24BattleText5::
	text "I'm second!"
IF DEF(_JPTXT)	;joenote - dirty joke lost in translation
	line "I'm ready to go"
	cont "all the way!"
ELSE
	line "Now it's serious!"
ENDC
	done

_Route24EndBattleText5::
IF DEF(_JPTXT)	;joenote - dirty joke lost in translation
	text "That was"
	line "unbelieveable."
ELSE
	text "How could I"
	line "lose?"
ENDC
	prompt

_Route24AfterBattleText5::
;joenote - girls are supposed to be slightly different
;	text "I did my best, I"
;	line "have no regrets!"
	text "I did my best, so"
	line "I've no regrets!"
	done

_Route24BattleText6::
	text "This is Nugget"
	line "bridge! Beat us 5"
	cont "trainers and win"
IF DEF(_JPTXT)	;joenote - dirty joke lost in translation
	cont "a surprise from"
	cont "the nugget sack!"
ELSE
	cont "a fabulous prize!"
ENDC

	para "Think you got"
	line "what it takes?"
	done

_Route24EndBattleText6::
	text "Whoo!"
	line "Good stuff!"
	prompt

_Route24AfterBattleText6::
	text "I did my best, I"
	line "have no regrets!"
	done
