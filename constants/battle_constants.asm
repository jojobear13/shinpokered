; stat numbers used by CalcStat and GetEnemyMonStat
STAT_HP      EQU 1
STAT_ATTACK  EQU 2
STAT_DEFENSE EQU 3
STAT_SPEED   EQU 4
STAT_SPECIAL EQU 5

; hBattleSide: which side a merged player/enemy battle routine is working on.
; Each routine documents whether that is the attacker or the target.
; bit 0: 0 = the player's mon, 1 = the enemy's mon
; bit 1: set by GetDamageVars for a special move
BATTLE_SIDE_ENEMY_F   EQU 0
BATTLE_SIDE_SPECIAL_F EQU 1
BATTLE_SIDE_ENEMY     EQU 1 << BATTLE_SIDE_ENEMY_F
BATTLE_SIDE_SPECIAL   EQU 1 << BATTLE_SIDE_SPECIAL_F
