const_value = 1

	const MASTER_BALL   ; $01
	const ULTRA_BALL    ; $02
	const GREAT_BALL    ; $03
	const POKE_BALL     ; $04
	const TOWN_MAP      ; $05
	const BICYCLE       ; $06
	const SURFBOARD     ; $07 buggy?
	const SAFARI_BALL   ; $08
	const POKEDEX       ; $09
	const MOON_STONE    ; $0A
	const ANTIDOTE      ; $0B
	const BURN_HEAL     ; $0C
	const ICE_HEAL      ; $0D
	const AWAKENING     ; $0E
	const PARLYZ_HEAL   ; $0F
	const FULL_RESTORE  ; $10
	const MAX_POTION    ; $11
	const HYPER_POTION  ; $12
	const SUPER_POTION  ; $13
	const POTION        ; $14
	const BOULDERBADGE  ; $15
	const CASCADEBADGE  ; $16
SAFARI_BAIT           EQU $15 ; overload
SAFARI_ROCK           EQU $16 ; overload
	const THUNDERBADGE  ; $17
	const RAINBOWBADGE  ; $18
	const SOULBADGE     ; $19
	const MARSHBADGE    ; $1A
	const VOLCANOBADGE  ; $1B
	const EARTHBADGE    ; $1C
	const ESCAPE_ROPE   ; $1D
	const REPEL         ; $1E
	const OLD_AMBER     ; $1F
	const FIRE_STONE    ; $20
	const THUNDER_STONE ; $21
	const WATER_STONE   ; $22
	const HP_UP         ; $23
	const PROTEIN       ; $24
	const IRON          ; $25
	const CARBOS        ; $26
	const CALCIUM       ; $27
	const RARE_CANDY    ; $28
	const DOME_FOSSIL   ; $29
	const HELIX_FOSSIL  ; $2A
	const SECRET_KEY    ; $2B
;	const UNUSED_ITEM    ; $2C "?????"
	const MIST_STONE	; $2C	joenote - custom item
	const BIKE_VOUCHER  ; $2D
	const X_ACCURACY    ; $2E
	const LEAF_STONE    ; $2F
	const CARD_KEY      ; $30
	const NUGGET        ; $31
	;const PP_UP_2       ; $32	unused pp_up
	const M_GENE		; $32	joenote - custom item
	const POKE_DOLL     ; $33
	const FULL_HEAL     ; $34
	const REVIVE        ; $35
	const MAX_REVIVE    ; $36
	const GUARD_SPEC    ; $37
	const SUPER_REPEL   ; $38
	const MAX_REPEL     ; $39
	const DIRE_HIT      ; $3A
	const COIN          ; $3B
	const FRESH_WATER   ; $3C
	const SODA_POP      ; $3D
	const LEMONADE      ; $3E
	const S_S_TICKET    ; $3F
	const GOLD_TEETH    ; $40
	const X_ATTACK      ; $41
	const X_DEFEND      ; $42
	const X_SPEED       ; $43
	const X_SPECIAL     ; $44
	const COIN_CASE     ; $45
	const OAKS_PARCEL   ; $46
	const ITEMFINDER    ; $47
	const SILPH_SCOPE   ; $48
	const POKE_FLUTE    ; $49
	const LIFT_KEY      ; $4A
	const EXP_ALL       ; $4B
	const OLD_ROD       ; $4C
	const GOOD_ROD      ; $4D
	const SUPER_ROD     ; $4E
	const PP_UP         ; $4F
	const ETHER         ; $50
	const MAX_ETHER     ; $51
	const ELIXER        ; $52
	const MAX_ELIXER    ; $53
	const FLOOR_B2F     ; $54
	const FLOOR_B1F     ; $55
	const FLOOR_1F      ; $56
	const FLOOR_2F      ; $57
	const FLOOR_3F      ; $58
	const FLOOR_4F      ; $59
	const FLOOR_5F      ; $5A
	const FLOOR_6F      ; $5B
	const FLOOR_7F      ; $5C
	const FLOOR_8F      ; $5D
	const FLOOR_9F      ; $5E
	const FLOOR_10F     ; $5F
	const FLOOR_11F     ; $60
	const FLOOR_B4F     ; $61
	const ZINC          ; $62 Gen 2's special defense vitamin
; held items (Gen 2's, with a few later staples); the catch-rate byte of a
; mon's data holds one
FIRST_HELD_ITEM EQU const_value
	const BLACK_BELT    ; $63
	const CHARCOAL      ; $64
	const DRAGON_FANG   ; $65
	const HARD_STONE    ; $66
	const MAGNET        ; $67
	const MIRACLE_SEED  ; $68
	const MYSTIC_WATER  ; $69
	const NEVERMELTICE  ; $6A
	const PINK_BOW      ; $6B
	const POISON_BARB   ; $6C
	const SHARP_BEAK    ; $6D
	const SILVERPOWDER  ; $6E
	const SOFT_SAND     ; $6F
	const SPELL_TAG     ; $70
	const TWISTEDSPOON  ; $71
	const BERRY         ; $72
	const GOLD_BERRY    ; $73
	const SITRUS_BERRY  ; $74
	const PRZCUREBERRY  ; $75
	const MINT_BERRY    ; $76
	const PSNCUREBERRY  ; $77
	const ICE_BERRY     ; $78
	const BURNT_BERRY   ; $79
	const BITTER_BERRY  ; $7A
	const MIRACLEBERRY  ; $7B
	const MYSTERYBERRY  ; $7C
	const LEFTOVERS     ; $7D
	const QUICK_CLAW    ; $7E
	const KINGS_ROCK    ; $7F
	const SCOPE_LENS    ; $80
	const BRIGHTPOWDER  ; $81
	const FOCUS_BAND    ; $82
	const LIGHT_BALL    ; $83
	const THICK_CLUB    ; $84
	const METAL_POWDER  ; $85
	const LUCKY_EGG     ; $86
	const AMULET_COIN   ; $87
	const EVERSTONE     ; $88
	const EXP_SHARE     ; $89
	const SMOKE_BALL    ; $8A
	const CLEANSE_TAG   ; $8B
	const STICK         ; $8C
	const LUCKY_PUNCH   ; $8D
	const CHOICE_BAND   ; $8E
	const CHOICE_SPECS  ; $8F
	const CHOICE_SCARF  ; $90
	const LIFE_ORB      ; $91
	const EVIOLITE      ; $92
	const FOCUS_SASH    ; $93
	const METAL_COAT    ; $94 the new types' boosting items
	const BLACKGLASSES  ; $95
	const FAIRYFEATHER  ; $96
	const DEXREPEL      ; $97 a key item: keeps away wild mons already caught
NUM_ITEMS_AND_FLOORS EQU const_value - 1

const_value = $C4

	const HM_01         ; $C4
	const HM_02         ; $C5
	const HM_03         ; $C6
	const HM_04         ; $C7
	const HM_05         ; $C8
	const TM_01         ; $C9
	const TM_02         ; $CA
	const TM_03         ; $CB
	const TM_04         ; $CC
	const TM_05         ; $CD
	const TM_06         ; $CE
	const TM_07         ; $CF
	const TM_08         ; $D0
	const TM_09         ; $D1
	const TM_10         ; $D2
	const TM_11         ; $D3
	const TM_12         ; $D4
	const TM_13         ; $D5
	const TM_14         ; $D6
	const TM_15         ; $D7
	const TM_16         ; $D8
	const TM_17         ; $D9
	const TM_18         ; $DA
	const TM_19         ; $DB
	const TM_20         ; $DC
	const TM_21         ; $DD
	const TM_22         ; $DE
	const TM_23         ; $DF
	const TM_24         ; $E0
	const TM_25         ; $E1
	const TM_26         ; $E2
	const TM_27         ; $E3
	const TM_28         ; $E4
	const TM_29         ; $E5
	const TM_30         ; $E6
	const TM_31         ; $E7
	const TM_32         ; $E8
	const TM_33         ; $E9
	const TM_34         ; $EA
	const TM_35         ; $EB
	const TM_36         ; $EC
	const TM_37         ; $ED
	const TM_38         ; $EE
	const TM_39         ; $EF
	const TM_40         ; $F0
	const TM_41         ; $F1
	const TM_42         ; $F2
	const TM_43         ; $F3
	const TM_44         ; $F4
	const TM_45         ; $F5
	const TM_46         ; $F6
	const TM_47         ; $F7
	const TM_48         ; $F8
	const TM_49         ; $F9
	const TM_50         ; $FA

; the bag's pockets (data/item_pockets.asm)
	const_def
	const POCKET_ITEMS
	const POCKET_MEDICINE
	const POCKET_BALLS
	const POCKET_BATTLE
	const POCKET_BERRIES
	const POCKET_KEY
NUM_POCKETS EQU const_value
