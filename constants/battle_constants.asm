; stat numbers used by CalcStat and GetEnemyMonStat
STAT_HP      EQU 1
STAT_ATTACK  EQU 2
STAT_DEFENSE EQU 3
STAT_SPEED   EQU 4
STAT_SPECIAL EQU 5

; wDamageVarsIndex: which side is attacking and with which kind of move.
; Tables indexed by it are ordered player physical, player special,
; enemy physical, enemy special (the same order as the CritHitStats predefs).
DAMAGEVARS_SPECIAL EQU 1
DAMAGEVARS_ENEMY   EQU 2
