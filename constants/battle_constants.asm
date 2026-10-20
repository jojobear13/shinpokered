; stat numbers used by CalcStat and GetEnemyMonStat
STAT_HP      EQU 1
STAT_ATTACK  EQU 2
STAT_DEFENSE EQU 3
STAT_SPEED   EQU 4
STAT_SPECIAL_ATTACK  EQU 5
STAT_SPECIAL_DEFENSE EQU 6

; indices into wPlayerMonStatMods and wEnemyMonStatMods. Special defense comes
; after accuracy and evasion so that the original six keep their indices.
MOD_ATTACK          EQU 0
MOD_DEFENSE         EQU 1
MOD_SPEED           EQU 2
MOD_SPECIAL_ATTACK  EQU 3
MOD_ACCURACY        EQU 4
MOD_EVASION         EQU 5
MOD_SPECIAL_DEFENSE EQU 6

; the fixed IVs of trainers' Pokemon outside hard mode: 19 attack, 17 for the
; rest (Gen 1's DVs of 9 and 8, as 2 x DV + 1), as the four IV bytes
TRAINER_IVS_0 EQU $8C
TRAINER_IVS_1 EQU $E3
TRAINER_IVS_2 EQU $18
TRAINER_IVS_3 EQU $C4

; natures, in Gen 3's order: nature = 5 * raised stat + lowered stat, the stats
; counted from attack (attack, defense, speed, special attack, special
; defense); raising and lowering the same stat is neutral
NUM_NATURES EQU 25
	const_def
	const HARDY   ; 0
	const LONELY  ; 1
	const BRAVE   ; 2
	const ADAMANT ; 3
	const NAUGHTY ; 4
	const BOLD    ; 5
	const DOCILE  ; 6
	const RELAXED ; 7
	const IMPISH  ; 8
	const LAX     ; 9
	const TIMID   ; 10
	const HASTY   ; 11
	const SERIOUS ; 12
	const JOLLY   ; 13
	const NAIVE   ; 14
	const MODEST  ; 15
	const MILD    ; 16
	const QUIET   ; 17
	const BASHFUL ; 18
	const RASH    ; 19
	const CALM    ; 20
	const GENTLE  ; 21
	const SASSY   ; 22
	const CAREFUL ; 23
	const QUIRKY  ; 24
; A mon's nature is its IVs, read as one number (without the flag bits), plus
; NATURE_OFFSET, mod 25. The offset makes the fixed trainer IVs come out
; HARDY, so trainers' Pokemon are neutral outside hard mode.
TRAINER_IVS_MOD EQU (((TRAINER_IVS_0 * 256 + TRAINER_IVS_1) % NUM_NATURES * 256 + TRAINER_IVS_2) % NUM_NATURES * 256 + (TRAINER_IVS_3 & $FC)) % NUM_NATURES
NATURE_OFFSET EQU (NUM_NATURES - TRAINER_IVS_MOD) % NUM_NATURES

; move categories (data/move_categories.asm)
PHYSICAL EQU 0
SPECIAL  EQU 1
STATUS   EQU 2

; bits of wObtainedBadges
BIT_BOULDERBADGE EQU 0
BIT_CASCADEBADGE EQU 1
BIT_THUNDERBADGE EQU 2
BIT_RAINBOWBADGE EQU 3
BIT_SOULBADGE    EQU 4
BIT_MARSHBADGE   EQU 5
BIT_VOLCANOBADGE EQU 6
BIT_EARTHBADGE   EQU 7

; hBattleSide: which side a merged player/enemy battle routine is working on.
; Each routine documents whether that is the attacker or the target.
; bit 0: 0 = the player's mon, 1 = the enemy's mon
; bit 1: set by GetDamageVars for a special move
BATTLE_SIDE_ENEMY_F   EQU 0
BATTLE_SIDE_SPECIAL_F EQU 1
BATTLE_SIDE_ENEMY     EQU 1 << BATTLE_SIDE_ENEMY_F
BATTLE_SIDE_SPECIAL   EQU 1 << BATTLE_SIDE_SPECIAL_F

; wAbilityFlags
FLASH_FIRE_PLAYER_F EQU 0 ; the player's mon's Flash Fire has taken a fire move
FLASH_FIRE_ENEMY_F  EQU 1
STURDY_ENDURED_F    EQU 2 ; the target's Sturdy left it 1 HP this move
ENTRY_PENDING_PLAYER_F EQU 3 ; the player's mon came in; its ability hasn't acted yet
ENTRY_PENDING_ENEMY_F  EQU 4
ENTRY_PENDING_PLAYER EQU 1 << ENTRY_PENDING_PLAYER_F
ENTRY_PENDING_ENEMY  EQU 1 << ENTRY_PENDING_ENEMY_F

; wAbilitySnapshot flags
SNAPSHOT_TAKEN_F   EQU 0 ; a move started
SNAPSHOT_DAMAGED_F EQU 1 ; it hit the target for damage

; GiveUserStatus: bad poison, not just poison (a bit the status byte doesn't use)
GIVE_BAD_POISON_F EQU 7

; what a move effect does to the target, for the abilities that keep it off
EFFECT_KIND_SLEEP     EQU 1 << 0
EFFECT_KIND_POISON    EQU 1 << 1
EFFECT_KIND_BURN      EQU 1 << 2
EFFECT_KIND_PARALYSIS EQU 1 << 3
EFFECT_KIND_CONFUSION EQU 1 << 4
EFFECT_KIND_FLINCH    EQU 1 << 5
EFFECT_KIND_STAT_DROP EQU 1 << 6
