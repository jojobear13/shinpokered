_OakSpeechText1::
	text "Hello there!"
	line "Welcome to the"
	cont "world of #mon!"

	para "My name is Oak!"
	line "People call me"
	cont "the #mon prof!"
	prompt

_OakSpeechText2A::
	text "This world is"
	line "inhabited by"
	cont "creatures called"
	cont "#mon!@@"

_OakSpeechText2B::
	text $51,"For some people,"
	line "#mon are"
	cont "pets. Others use"
	cont "them for fights."

	para "Myself..."

	para "I study #mon"
	line "as a profession."
	prompt

_IntroducePlayerText::
	text "First, what is"
	line "your name?"
	prompt

_IntroduceRivalText::
	text "This is my grand-"
	line "son. He's been"
	cont "your rival since"
	cont "you were a baby."

	para "...Erm, what is"
	line "his name again?"
	prompt

_OakSpeechText3::
	text "<PLAYER>!"

	para "Your very own"
	line "#mon legend is"
	cont "about to unfold!"

	para "A world of dreams"
	line "and adventures"
	cont "with #mon"
	cont "awaits! Let's go!"
	done

;joenote - ask if female trainer
IF DEF(_FPLAYER)
_AskIfGirlText::
	text "Are you a boy or"
	line "a girl?"
	done
ENDC
