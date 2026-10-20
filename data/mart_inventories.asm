; mart inventories are below
; they are texts: $FE and an index into MartInventories
;joenote - added moon stone, fossils, amber, pp_up, all kinds of TMs

; Viridian
ViridianCashierText::
	db $FE, 0 ; mart: its list is in data/mart_lists.asm

; Pewter
PewterCashierText::
	db $FE, 1 ; mart: its list is in data/mart_lists.asm

; Cerulean
CeruleanCashierText::
	db $FE, 2 ; mart: its list is in data/mart_lists.asm

; Bike shop
	db $FE, 3 ; mart: its list is in data/mart_lists.asm

; Vermilion
VermilionCashierText::
	db $FE, 4 ; mart: its list is in data/mart_lists.asm

; Lavender
LavenderCashierText::
	db $FE, 5 ; mart: its list is in data/mart_lists.asm

; Celadon Dept. Store 2F (1)
CeladonMart2Clerk1Text::
	db $FE, 6 ; mart: its list is in data/mart_lists.asm

; Celadon Dept. Store 2F (2)
CeladonMart2Clerk2Text::
	db $FE, 7 ; mart: its list is in data/mart_lists.asm

; Celadon Dept. Store 4F
CeladonMart4ClerkText::
	db $FE, 8 ; mart: its list is in data/mart_lists.asm

; Celadon Dept. Store 5F (1)
CeladonMart5Clerk1Text::
	db $FE, 9 ; mart: its list is in data/mart_lists.asm

; Celadon Dept. Store 5F (2)
CeladonMart5Clerk2Text::
	db $FE, 10 ; mart: its list is in data/mart_lists.asm

; Fuchsia
FuchsiaCashierText::
	db $FE, 11 ; mart: its list is in data/mart_lists.asm

; unused? joenote - repurposing for a new vendor on celadon dept store floor 3
CeladonMart3ClerkText::
	;TX_MART GREAT_BALL, HYPER_POTION, SUPER_POTION, FULL_HEAL, REVIVE
	db $FE, 12 ; mart: its list is in data/mart_lists.asm

; Cinnabar
CinnabarCashierText::
	db $FE, 13 ; mart: its list is in data/mart_lists.asm

; Saffron
SaffronCashierText::
	db $FE, 14 ; mart: its list is in data/mart_lists.asm

; Indigo
IndigoCashierText::
	db $FE, 15 ; mart: its list is in data/mart_lists.asm
	
;joenote - add drink stand
DrinkStandText::
	db $FE, 16 ; mart: its list is in data/mart_lists.asm
