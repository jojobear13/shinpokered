db DEX_KADABRA ; pokedex id
db 40 ; base hp
db 35 ; base attack
db 30 ; base defense
db 105 ; base speed
db 120 ; base special attack
db 70 ; base special defense
db PSYCHIC ; species type 1
db PSYCHIC ; species type 2
db 96 ; catch rate	;joenote - adjusted from 100 to match yellow version
db 145 ; base exp yield
INCBIN KADABRA_FR,0,1 ; 66, sprite dimensions
dw KadabraPicFront
dw KadabraPicBack
; attacks known at lvl 0
db TELEPORT
db KINESIS
db CONFUSION
db DISABLE
db 3 ; growth rate
; learnset
	tmlearn 1,5,6,8
	tmlearn 9,10
	tmlearn 17,18,19,20
	tmlearn 28,29,30,31,32
	tmlearn 33,34,35,40
	tmlearn 44,45,46
	tmlearn 49,50,55
;	db 0 ; padding
	db BANK(KadabraPicFront)
	assert BANK(KadabraPicFront) == BANK(KadabraPicBack)

