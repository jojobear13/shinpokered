db DEX_WIGGLYTUFF ; pokedex id
db 140 ; base hp
db 70 ; base attack
db 45 ; base defense
db 45 ; base speed
db 75 ; base special attack
db 50 ; base special defense
db NORMAL ; species type 1
db FAIRY ; species type 2
db 50 ; catch rate
db 109 ; base exp yield
INCBIN WIGGLYTUFF_FR,0,1 ; 66, sprite dimensions
dw WigglytuffPicFront
dw WigglytuffPicBack
; attacks known at lvl 0
db SING
;db DISABLE
;db DEFENSE_CURL
;db DOUBLESLAP
db 0
db 0
db 0
db 4 ; growth rate
; learnset
	tmlearn 1,5,6,8
	tmlearn 9,10,11,12,13,14,15
	tmlearn 17,18,19,20,22,24
	tmlearn 25,29,30,31,32
	tmlearn 33,34,38,40
	tmlearn 44,45,46
	tmlearn 49,50,54,55
;	db 0 ; padding
	db BANK(WigglytuffPicFront)
	assert BANK(WigglytuffPicFront) == BANK(WigglytuffPicBack)

