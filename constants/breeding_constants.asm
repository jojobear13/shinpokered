; breeding (engine/breeding.asm)

; an egg, in a party's or box's species list (its data has its real species,
; 0 HP, and its egg cycles left where a mon's held item goes)
EGG EQU $FD

; egg groups (data/breeding.asm), PokeAPI's numbering
	const_def
const_value = 1
	const EGG_MONSTER     ; 1
	const EGG_WATER_1     ; 2
	const EGG_BUG         ; 3
	const EGG_FLYING      ; 4
	const EGG_FIELD       ; 5
	const EGG_FAIRY       ; 6
	const EGG_GRASS       ; 7
	const EGG_HUMAN_LIKE  ; 8
	const EGG_WATER_3     ; 9
	const EGG_MINERAL     ; 10
	const EGG_AMORPHOUS   ; 11
	const EGG_WATER_2     ; 12
	const EGG_DITTO       ; 13
	const EGG_DRAGON      ; 14
	const EGG_NONE        ; 15: no eggs

; DayCareCompatibility's answers: the chance in 100 of an egg each cycle
BREED_NONE      EQU 0  ; "prefer to play with other #MON"
BREED_LOW       EQU 20 ; "don't seem to like each other"
BREED_MEDIUM    EQU 50 ; "seem to get along"
BREED_HIGH      EQU 70 ; "seem to get along very well"

EGG_INHERITED_IVS EQU 3 ; IVs from the parents (Gen 6+, without a Destiny Knot)
EGG_ABILITY_KEPT EQU 205 ; out of 256 (80%): the egg has the mother's ability slot

; wBreedInfo, for each parent
	const_def
	const BREED_INFO_SPECIES
	const BREED_INFO_DEX
	const BREED_INFO_GROUP1
	const BREED_INFO_GROUP2
	const BREED_INFO_GENDER ; "♂", "♀", or 0 for none
BREED_INFO_LENGTH EQU const_value

; the party icon for an egg (engine/mon_party_sprites.asm): tiles $28 on in
; vSprites, free between the other icons' first frames
EGG_ICON EQU $A
