_Lab4Text_75dc6::
	text "Hiya!"

	para "I am important"
	line "doctor!"

	para "I study here rare"
	line "#MON fossils!"

	para "You! Have you a"
	line "fossil for me?"
	prompt

_Lab4Text_75dcb::
	text "No! Is too bad!"
	done

_Lab4Text_75dd0::
	text "I take a little"
	line "time!"

	para "You go for walk a"
	line "little while!"
	done

_Lab4Text_75dd5::
	text "Where were you?"

	para "Your fossil is"
	line "back to life!"

	para "It was @"
	TX_RAM wcf4b
	db $0
	line "like I think!"
	prompt

_Lab4Text_610ae::
	text "Oh! That is"
	line "@"
	TX_RAM wcd6d
	text "!"

	para "It is fossil of"
	line "@"
	TX_RAM wcf4b
	text ", a"
	cont "#MON that is"
	cont "already extinct!"

	para "My Resurrection"
	line "Machine will make"
	cont "that #MON live"
	cont "again!"
	done

_Lab4Text_610b3::
	text "So! You hurry and"
	line "give me that!"

	para "<PLAYER> handed"
	line "over @"
	TX_RAM wcd6d
	text "!"
	prompt

_Lab4Text_610b8::
	text "I take a little"
	line "time!"

	para "You go for walk a"
	line "little while!"
	done

_Lab4Text_610bd::
	text "Aiyah! You come"
	line "again!"
	done

;joenote - text for cloning guy
_Lab4Text_Clone0::
	text "A Punnett Square"
	line "analysis is ¥200."
	cont "You interested?"
	done
	
_Lab4Text_Clone1::
	text "Gene sequence:"
	line "@"
;	TX_NUM hDexRatingNumMonsOwned, 1, 3
;	text " #MON owned"
	TX_NUM wBuffer, 1, 2
	text " @"
	TX_NUM wBuffer+1, 1, 2
	text " @"
	TX_NUM wBuffer+2, 1, 2
	text " @"
	TX_NUM wBuffer+3, 1, 2
	text " @"
	TX_NUM wBuffer+4, 1, 2
	text " @"
	TX_NUM wBuffer+5, 1, 2
	cont "Okay?"
	done
	
_Lab4Text_Clone2::
	text "To clone these"
	line "genes is ¥10000."
	cont "Still interested?"
	done

_Lab4Text_Clone3::
	text "Come back after a"
	line "bit while we work"
	cont "on gestation."
	done

_Lab4Text_Clone4::
	text "Your brand new"
	line "#MON is all"
	cont "ready to go!"
	prompt

_Lab4Text_MachineUsed::
	text "Our machines are"
	line "at full capacity."
	done

_Lab4Text_Bye::
	text "Maybe later."
	done

_Lab4Text_NoMoney::
	text "You don't have"
	line "enough money."
	done	

_Lab4Text_Party::
	text "Come back when"
	line "your team is"
	cont "2 to 5 #MON."
	done	

_Lab4Text_Legend::
	text "Our computers"
	line "can't analyze"
	cont "the #MON in"
	cont "your top spot."
	
	para "It's beyond our"
	line "capabilities."
	done	

_Lab4Text_Book0::
	text "Read it?"
	done
	
_Lab4Text_Book1A::
	text "MODIFIED CLONES"
	prompt
_Lab4Text_Book1B::
	text "This creates a"
	line "gene-spliced"
	cont "clone of your 1st"
	cont "spot #MON with"
	cont "DNA from your 2nd"
	cont "spot #MON."

	para "A Punnet Square"
	line "analysis is done"
	cont "on each gene,"
	cont "and a predicted"
	cont "gene sequence is"
	cont "approved prior to"
	cont "gestation."
	done

_Lab4Text_Book2A::
	text "#MON GENES"
	prompt
_Lab4Text_Book2B::
	text "All Pokemon have"
	line "DETERMINED VALUES"
	cont "that effectively"
	cont "act as genes."

	para "Every Pokemon has"
	line "2 genes: A and B."
	cont "Each gene has 2"
	cont "alleles: Hi / Lo."
	cont "This forms a gene"
	cont "sequence notation"
	cont "for each Pokemon."

	para "Gene sequences"
	line "are ordered from"
	cont "left to right as:"

	para "Gene-A Hi allele,"
	line "Gene-A Lo allele,"
	cont "Gene-B Hi allele,"
	cont "Gene-B Lo allele."

	para "Respectively they"
	line "affect ATTACK," 
	cont "DEFENSE, SPEED,"
	cont "and SPCL.ATK in"
	cont "that order."

	para "SPCL.DEF has a"
	line "third gene of its"
	cont "own, passed down"
	cont "whole from one"
	cont "parent or the"
	cont "other."
	done

_Lab4Text_Book3A::
	text "MIXING #MON DNA"
	prompt
_Lab4Text_Book3B::

	text "Punnet Squares"
	line "mix two A genes"
	cont "or two B genes."

	para "A Hi allele is"
	line "always before a"
	cont "Lo allele within"
	cont "a quadrant. 2 Hi"
	cont "alleles or 2 Lo"
	cont "alleles within a" 
	cont "quadrant have a"
	cont "1-in-2 chance to"
	cont "swap positions."

	para "This way you can"
	line "predict all the"
	cont "possible outcomes"
	cont "of combining two"
	cont "genes together."
	done