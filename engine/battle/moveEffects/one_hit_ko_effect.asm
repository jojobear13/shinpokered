;hl for user's speed
;de for victim's speed
OneHitKOEffect_:
	ld hl, wDamage
	xor a
	ld [hli], a
	ld [hl], a ; set the damage output to zero
	dec a
	ld [wCriticalHitOrOHKO], a
	ld hl, wBattleMonSpeed + 1
	ld de, wEnemyMonSpeed + 1
	ld bc, wPlayerBattleStatus2
	ld a, [H_WHOSETURN]
	and a
	jr z, .compareSpeed
	ld hl, wEnemyMonSpeed + 1
	ld de, wBattleMonSpeed + 1
	ld bc, wEnemyBattleStatus2
.ohko_xacc ;joenote - make it so using x-accuracy lets a slower user hit with it
	ld a, [bc]
	bit USING_X_ACCURACY, a
	jr nz, .userCanHit
.compareSpeed
;check if the user's current speed is higher than the target's
	ld a, [de]
	dec de
	ld b, a
	ld a, [hld]
	sub b
	ld a, [de]
	ld b, a
	ld a, [hl]
	sbc b
	jr c, .userIsSlower
.userCanHit
	;user is allowed to hit with the move, so load 65535 damage and set the OHKO flag
	ld hl, wDamage
	ld a, $ff
	ld [hli], a
	ld [hl], a
	ld a, $2
	ld [wCriticalHitOrOHKO], a
	ret
.userIsSlower
; user is slower than target, so keep damage at 0 and set move missed flag
	ld a, $1
	ld [wMoveMissed], a
	ret
