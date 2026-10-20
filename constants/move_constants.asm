const_value = 1

	const POUND        ; 01
	const KARATE_CHOP  ; 02
	const DOUBLESLAP   ; 03
	const COMET_PUNCH  ; 04
	const MEGA_PUNCH   ; 05
	const PAY_DAY      ; 06
	const FIRE_PUNCH   ; 07
	const ICE_PUNCH    ; 08
	const THUNDERPUNCH ; 09
	const SCRATCH      ; 0a
	const VICEGRIP     ; 0b
	const GUILLOTINE   ; 0c
	const RAZOR_WIND   ; 0d
	const SWORDS_DANCE ; 0e
	const CUT          ; 0f
	const GUST         ; 10
	const WING_ATTACK  ; 11
	const WHIRLWIND    ; 12
	const FLY          ; 13
	const BIND         ; 14
	const SLAM         ; 15
	const VINE_WHIP    ; 16
	const STOMP        ; 17
	const DOUBLE_KICK  ; 18
	const MEGA_KICK    ; 19
	const JUMP_KICK    ; 1a
	const ROLLING_KICK ; 1b
	const SAND_ATTACK  ; 1c
	const HEADBUTT     ; 1d
	const HORN_ATTACK  ; 1e
	const FURY_ATTACK  ; 1f
	const HORN_DRILL   ; 20
	const TACKLE       ; 21
	const BODY_SLAM    ; 22
	const WRAP         ; 23
	const TAKE_DOWN    ; 24
	const THRASH       ; 25
	const DOUBLE_EDGE  ; 26
	const TAIL_WHIP    ; 27
	const POISON_STING ; 28
	const TWINEEDLE    ; 29
	const PIN_MISSILE  ; 2a
	const LEER         ; 2b
	const BITE         ; 2c
	const GROWL        ; 2d
	const ROAR         ; 2e
	const SING         ; 2f
	const SUPERSONIC   ; 30
	const SONICBOOM    ; 31
	const DISABLE      ; 32
	const ACID         ; 33
	const EMBER        ; 34
	const FLAMETHROWER ; 35
	const MIST         ; 36
	const WATER_GUN    ; 37
	const HYDRO_PUMP   ; 38
	const SURF         ; 39
	const ICE_BEAM     ; 3a
	const BLIZZARD     ; 3b
	const PSYBEAM      ; 3c
	const BUBBLEBEAM   ; 3d
	const AURORA_BEAM  ; 3e
	const HYPER_BEAM   ; 3f
	const PECK         ; 40
	const DRILL_PECK   ; 41
	const SUBMISSION   ; 42
	const LOW_KICK     ; 43
	const COUNTER      ; 44
	const SEISMIC_TOSS ; 45
	const STRENGTH     ; 46
	const ABSORB       ; 47
	const MEGA_DRAIN   ; 48
	const LEECH_SEED   ; 49
	const GROWTH       ; 4a
	const RAZOR_LEAF   ; 4b
	const SOLARBEAM    ; 4c
	const POISONPOWDER ; 4d
	const STUN_SPORE   ; 4e
	const SLEEP_POWDER ; 4f
	const PETAL_DANCE  ; 50
	const STRING_SHOT  ; 51
	const DRAGON_RAGE  ; 52
	const FIRE_SPIN    ; 53
	const THUNDERSHOCK ; 54
	const THUNDERBOLT  ; 55
	const THUNDER_WAVE ; 56
	const THUNDER      ; 57
	const ROCK_THROW   ; 58
	const EARTHQUAKE   ; 59
	const FISSURE      ; 5a
	const DIG          ; 5b
	const TOXIC        ; 5c
	const CONFUSION    ; 5d
	const PSYCHIC_M    ; 5e
	const HYPNOSIS     ; 5f
	const MEDITATE     ; 60
	const AGILITY      ; 61
	const QUICK_ATTACK ; 62
	const RAGE         ; 63
	const TELEPORT     ; 64
	const NIGHT_SHADE  ; 65
	const MIMIC        ; 66
	const SCREECH      ; 67
	const DOUBLE_TEAM  ; 68
	const RECOVER      ; 69
	const HARDEN       ; 6a
	const MINIMIZE     ; 6b
	const SMOKESCREEN  ; 6c
	const CONFUSE_RAY  ; 6d
	const WITHDRAW     ; 6e
	const DEFENSE_CURL ; 6f
	const BARRIER      ; 70
	const LIGHT_SCREEN ; 71
	const HAZE         ; 72
	const REFLECT      ; 73
	const FOCUS_ENERGY ; 74
	const BIDE         ; 75
	const METRONOME    ; 76
	const MIRROR_MOVE  ; 77
	const SELFDESTRUCT ; 78
	const EGG_BOMB     ; 79
	const LICK         ; 7a
	const SMOG         ; 7b
	const SLUDGE       ; 7c
	const BONE_CLUB    ; 7d
	const FIRE_BLAST   ; 7e
	const WATERFALL    ; 7f
	const CLAMP        ; 80
	const SWIFT        ; 81
	const SKULL_BASH   ; 82
	const SPIKE_CANNON ; 83
	const CONSTRICT    ; 84
	const AMNESIA      ; 85
	const KINESIS      ; 86
	const SOFTBOILED   ; 87
	const HI_JUMP_KICK ; 88
	const GLARE        ; 89
	const DREAM_EATER  ; 8a
	const POISON_GAS   ; 8b
	const BARRAGE      ; 8c
	const LEECH_LIFE   ; 8d
	const LOVELY_KISS  ; 8e
	const SKY_ATTACK   ; 8f
	const TRANSFORM    ; 90
	const BUBBLE       ; 91
	const DIZZY_PUNCH  ; 92
	const SPORE        ; 93
	const FLASH        ; 94
	const PSYWAVE      ; 95
	const SPLASH       ; 96
	const ACID_ARMOR   ; 97
	const CRABHAMMER   ; 98
	const EXPLOSION    ; 99
	const FURY_SWIPES  ; 9a
	const BONEMERANG   ; 9b
	const REST         ; 9c
	const ROCK_SLIDE   ; 9d
	const HYPER_FANG   ; 9e
	const SHARPEN      ; 9f
	const CONVERSION   ; a0
	const TRI_ATTACK   ; a1
	const SUPER_FANG   ; a2
	const SLASH        ; a3
	const SUBSTITUTE   ; a4

; Gen 9 moves (the learnset audit's), with their PokeAPI ids for tools/gen_move_data.py
	const AERIAL_ACE   ; a5
	const AIR_SLASH    ; a6
	const ANCIENTPOWER ; a7
	const AQUA_JET     ; a8
	const BRINE        ; a9
	const BUG_BITE     ; aa
	const BUG_BUZZ     ; ab
	const BULLDOZE     ; ac
	const CLOSE_COMBAT ; ad
	const CROSS_CHOP   ; ae
	const CRUNCH       ; af
	const DISARM_VOICE ; b0
	const DISCHARGE    ; b1
	const DRAGONBREATH ; b2
	const DRAGON_RUSH  ; b3
	const DRILL_RUN    ; b4
	const DYNAMICPUNCH ; b5
	const EARTH_POWER  ; b6
	const EXTREMESPEED ; b7
	const FIRE_FANG    ; b8
	const FLAME_WHEEL  ; b9
	const FLARE_BLITZ  ; ba
	const FLASH_CANNON ; bb
	const GIGA_DRAIN   ; bc
	const GUNK_SHOT    ; bd
	const HEAT_WAVE    ; be
	const HYPER_VOICE  ; bf
	const ICICLE_CRASH ; c0
	const INCINERATE   ; c1
	const LEAF_BLADE   ; c2
	const LIQUIDATION  ; c3
	const LOW_SWEEP    ; c4
	const MACH_PUNCH   ; c5
	const MOONBLAST    ; c6
	const PLUCK        ; c7
	const POISON_FANG  ; c8
	const POISON_JAB   ; c9
	const POWDER_SNOW  ; ca
	const PSYSHOCK     ; cb
	const RAZOR_SHELL  ; cc
	const ROUND_M        ; cd
	const SEED_BOMB    ; ce
	const SHADOW_BALL  ; cf
	const SLUDGE_BOMB  ; d0
	const STOMPTANTRUM ; d1
	const STONE_EDGE   ; d2
	const TWISTER      ; d3
	const WATER_PULSE  ; d4
	const X_SCISSOR    ; d5
; pokeapi AERIAL_ACE 332
; pokeapi AIR_SLASH 403
; pokeapi ANCIENTPOWER 246
; pokeapi AQUA_JET 453
; pokeapi BRINE 362
; pokeapi BUG_BITE 450
; pokeapi BUG_BUZZ 405
; pokeapi BULLDOZE 523
; pokeapi CLOSE_COMBAT 370
; pokeapi CROSS_CHOP 238
; pokeapi CRUNCH 242
; pokeapi DISARM_VOICE 574
; pokeapi DISCHARGE 435
; pokeapi DRAGONBREATH 225
; pokeapi DRAGON_RUSH 407
; pokeapi DRILL_RUN 529
; pokeapi DYNAMICPUNCH 223
; pokeapi EARTH_POWER 414
; pokeapi EXTREMESPEED 245
; pokeapi FIRE_FANG 424
; pokeapi FLAME_WHEEL 172
; pokeapi FLARE_BLITZ 394
; pokeapi FLASH_CANNON 430
; pokeapi GIGA_DRAIN 202
; pokeapi GUNK_SHOT 441
; pokeapi HEAT_WAVE 257
; pokeapi HYPER_VOICE 304
; pokeapi ICICLE_CRASH 556
; pokeapi INCINERATE 510
; pokeapi LEAF_BLADE 348
; pokeapi LIQUIDATION 710
; pokeapi LOW_SWEEP 490
; pokeapi MACH_PUNCH 183
; pokeapi MOONBLAST 585
; pokeapi PLUCK 365
; pokeapi POISON_FANG 305
; pokeapi POISON_JAB 398
; pokeapi POWDER_SNOW 181
; pokeapi PSYSHOCK 473
; pokeapi RAZOR_SHELL 534
; pokeapi ROUND_M 496
; pokeapi SEED_BOMB 402
; pokeapi SHADOW_BALL 247
; pokeapi SLUDGE_BOMB 188
; pokeapi STOMPTANTRUM 707
; pokeapi STONE_EDGE 444
; pokeapi TWISTER 239
; pokeapi WATER_PULSE 352
; pokeapi X_SCISSOR 404

NUM_ATTACKS EQU const_value + -1

	const STRUGGLE     ; d6

	; Moves do double duty as animation identifiers.

	const SHOWPIC_ANIM
	const STATUS_AFFECTED_ANIM
	const ANIM_A8
	const ANIM_A9
	const TRADE_BALL_DROP_ANIM
	const TRADE_BALL_SHAKE_ANIM
	const TRADE_BALL_TILT_ANIM
	const TRADE_BALL_POOF_ANIM
	const XSTATITEM_ANIM ; use X Attack/Defense/Speed/Special
	const ANIM_AF
	const ANIM_B0
	const ANIM_B1
	const ANIM_B2
	const ANIM_B3
	const ANIM_B4
	const ANIM_B5
	const ANIM_B6
	const ANIM_B7
	const ANIM_B8
	const ANIM_B9
	const BURN_PSN_ANIM ; Plays when a monster is burned or poisoned
	const ANIM_BB
	const ANIM_BC
	const SLP_ANIM ; sleeping monster
	const ANIM_BE
	const CONF_ANIM ; confused monster
	const ANIM_C0
	const TOSS_ANIM ; toss Poké Ball
	const SHAKE_ANIM ; shaking Poké Ball when catching monster
	const POOF_ANIM ; puff of smoke
	const BLOCKBALL_ANIM ; trainer knocks away Poké Ball
	const GREATTOSS_ANIM ; toss Great Ball
	const ULTRATOSS_ANIM ; toss Ultra Ball or Master Ball
	const ANIM_C7
	const HIDEPIC_ANIM ; monster disappears
	const ROCK_ANIM ; throw rock
	const BAIT_ANIM ; throw bait
