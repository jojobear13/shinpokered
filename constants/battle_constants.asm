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
