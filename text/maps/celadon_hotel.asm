_CeladonHotelText1::
	text "#mon? No, this"
	line "is a hotel for"
	cont "people."

	para "We're full up."
	done

_CeladonHotelText2::
	text "I'm on vacation"
	line "with my brother"
	cont "and boy friend."

	para "Celadon is such a"
	line "pretty city!"
	done

_CeladonHotelText3::
	text "Why did she bring"
	line "her brother?"
	done
	
;joenote - adding text for the coin guy

_CeladonHotelCoinGuyText_intro::
	text "I'm flushed with"
	line "coins, yet seeing"
	cont "#mon is what I"
	cont "covet."
	
	para "Show me a fine"
	line "@"
	TX_RAM wcd6d
	db $0
	cont "and I will give a" 
	cont "nice reward."
	prompt

_CeladonHotelCoinGuyText_needcase::
	text "Oh, remember to"
	line "bring a Coin Case."
	done

_CeladonHotelCoinGuyText_recieved::
	text "Oh, I see that you"
	line "have one!"
	
	para "I'll give you"
	line "@"
	TX_BCD hCoins, 2 | LEADING_ZEROES | LEFT_ALIGN
	text " coins!"
	done
	
_CeladonHotelCoinGuyText_PC::
	text "Use the PC over in"
	line "the corner if you"
	cont "need it."
	done
