ApplyOutOfBattlePoisonDamage:
	ld a, [wd730]
	add a
	jp c, .noBlackOut ; no black out if joypad states are being simulated
	ld a, [wPartyCount]
	and a
	jp z, .noBlackOut
	call IncrementDayCareMonExp
	callba DayCareEggStep ; carry if an egg hatches
	jr nc, .noHatch
	xor a
	ld [wJoyIgnore], a
	call EnableAutoTextBoxDrawing
	ld a, TEXT_EGG_HATCHING
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
.noHatch
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - every interval of steps, have a chance to respawn both 1 missible and 1 hidden item if E4 have been beaten
;	push bc
;	CheckEvent EVENT_908	;has elite 4 been beaten?
;	jr z, .no_item_respawn
;	ld a, [wStepCounter]
;	and $3F ; is the counter a multiple of 64?
;	jp nz, .no_item_respawn
;	callba ResetRandItemsOnInterval
;.no_item_respawn
;	pop bc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;joenote - do not allow poison damage in the safari zone minigame
;This prevents blacking out in the safari zone	
	CheckEvent EVENT_IN_SAFARI_ZONE
	jp nz, .skipPoisonEffectAndSound
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld a, [wStepCounter]
	and $3 ; is the counter a multiple of 4?
	;jp nz, .noBlackOut ; only apply poison damage every fourth step
	jp nz, .skipPoisonEffectAndSound	;joenote - check for blackout every step like in pokeyellow
	ld [wWhichPokemon], a
	ld hl, wPartyMon1Status
	ld de, wPartySpecies
.applyDamageLoop
	ld a, [hl]
	and (1 << PSN)
	jr z, .nextMon2 ; not poisoned
	dec hl
	dec hl
	ld a, [hld]
	ld b, a
	ld a, [hli]
	or b
	jr z, .nextMon ; already fainted
; subtract 1 from HP
	ld a, [hl]
	dec a
	ld [hld], a
	inc a
	jr nz, .noBorrow
; borrow 1 from upper byte of HP
	dec [hl]
	inc hl
	jr .nextMon
.noBorrow
	ld a, [hli]
	or [hl]
	jr nz, .nextMon ; didn't faint from damage
; the mon fainted from the damage
	push hl
	inc hl
	inc hl
	ld [hl], a
	ld a, [de]
	ld [wd11e], a
	push de
	ld a, [wWhichPokemon]
	ld hl, wPartyMonNicks
	call GetPartyMonName
	xor a
	ld [wJoyIgnore], a
	call EnableAutoTextBoxDrawing
	ld a, TEXT_MON_FAINTED
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;joenote - update dead pokemon for nuzlocke mode
	predef OverwoldDamage_NuzlockeHandler
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	pop de
	pop hl
.nextMon
	inc hl
	inc hl
.nextMon2
	inc de
	ld a, [de]
	inc a
	jr z, .applyDamageLoopDone
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc
	push hl
	ld hl, wWhichPokemon
	inc [hl]
	pop hl
	jr .applyDamageLoop
.applyDamageLoopDone
	ld hl, wPartyMon1Status
	ld a, [wPartyCount]
	ld d, a
	ld e, 0
.countPoisonedLoop
	ld a, [hl]
	and (1 << PSN)
	or e
	ld e, a
	ld bc, wPartyMon2 - wPartyMon1
	add hl, bc
	dec d
	jr nz, .countPoisonedLoop
	ld a, e
	and a ; are any party members poisoned?
	jr z, .skipPoisonEffectAndSound
	ld b, $2
	predef ChangeBGPalColor0_4Frames ; change BG white to dark grey for 4 frames
	ld a, SFX_POISONED
	call PlaySound
.skipPoisonEffectAndSound
	predef AnyPartyAlive
	ld a, d
	and a
	jr nz, .noBlackOut
	call EnableAutoTextBoxDrawing
	ld a, TEXT_BLACKED_OUT
	ld [hSpriteIndexOrTextID], a
	call DisplayTextID
	ld hl, wd72e
	set 5, [hl]
	ld a, $ff
	jr .done
.noBlackOut
	xor a
.done
	ld [wOutOfBattleBlackout], a
	ret
