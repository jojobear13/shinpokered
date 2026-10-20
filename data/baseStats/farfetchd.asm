db DEX_FARFETCHD ; pokedex id
db 52 ; base hp
db 90 ; base attack
db 55 ; base defense
db 60 ; base speed
db 58 ; base special attack
db 62 ; base special defense
db NORMAL ; species type 1
db FLYING ; species type 2
db 45 ; catch rate
db 94 ; base exp yield
INCBIN FARFETCHD_FR,0,1 ; 66, sprite dimensions
dw FarfetchdPicFront
dw FarfetchdPicBack
; attacks known at lvl 0
db SAND_ATTACK
db PECK
db 0
db 0
db 0 ; growth rate
; learnset
	tmlearn 2,3,4,6,8
	tmlearn 9,10
	tmlearn 20
	tmlearn 31,32
	tmlearn 33,34,39,40
	tmlearn 44
	tmlearn 50,51,52
;	db 0 ; padding
	db BANK(FarfetchdPicFront)
	assert BANK(FarfetchdPicFront) == BANK(FarfetchdPicBack)

