IF DEF(_JPTXT)
_BikeShopText_1d810::
	text "Hi! Welcome to"
	line "miracle cycle."

	para "Have we got just"
	line "the bike for you!"
	prompt
ELSE
_BikeShopText_1d810::
	text "Hi! Welcome to"
	line "our bike shop."

	para "Have we got just"
	line "the bike for you!"
	prompt
ENDC

_BikeShopText_1d815::
	text "It's a cool bike!"
	line "Do you want it?"
	done

_BikeShopCantAffordText::
	text "Sorry! You can't"
	line "afford it!"
	prompt

_BikeShopText_1d81f::
	text "Oh, that's..."

	para "A Bike Voucher!"

	para "Okay! Here you go!"
	prompt

_BikeShopText_1d824::
	text "<PLAYER> exchanged"
	line "the Bike Voucher"
;	cont "for a BICYCLE.@@"
;joenote - add hotkey info
	cont "for a Bicycle."
	para "Hold A and press"
	line "Select to get on"
	cont "or off quickly.@@"


_BikeShopComeAgainText::
	text "Come back again"
	line "some time!"
	done

_BikeShopText_1d82f::
	text "How do you like"
	line "your new Bicycle?"

	para "You can take it"
	line "on Cycling Road"
	cont "and in caves!"
	done

_BikeShopText_1d834::
	text "You better make"
	line "room for this!"
	done

_BikeShopText_1d843::
	text "A plain city bike"
	line "is good enough"
	cont "for me!"

	para "You can't put a"
	line "shopping basket"
	cont "on an MTB!"
	done

_BikeShopText_1d85c::
	text "These bikes are"
	line "cool, but they're"
	cont "way expensive!"
	done

_BikeShopText_1d861::
	text "Wow. Your bike is"
	line "really cool!"
	done
