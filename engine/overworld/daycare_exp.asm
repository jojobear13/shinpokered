;joenote - This has been completely reworked. It now works as follows.
;It falsifies farming wild encounters against a pokemon with a base exp value of 56.
;The falsified encounter starts at level 5, and it increases 5 more levels per badge obtained.
;With 8 badges, using the daycare is essentially a faster way of farming level 45 basic pokemon.
;The downside of not gaining statexp in the daycare still remains as a tradeoff.
IncrementDayCareMonExp:
	ld a, [wDayCareInUse]
	and a
	ret z

	push bc
	push de
	
	;get exp as if an area with an encounter rate of $0A (pretty common value for a lot of maps)
	;actually, change it to 7 to account for the time that would be spent during the battle
	ld b, $07
	ld a, [hRandomAdd]
	cp b
	jr nc, .return
	
	;load 56 base exp divided by 7 as a basic adder
	ld bc, $0008
	ld hl, $0000
	ld d, $9
	ld a, [wObtainedBadges]
.loop
	;add five levels worth of exp + 5 more per gym badge obtained
	add hl, bc
	add hl, bc
	add hl, bc
	add hl, bc
	add hl, bc
.loop_no_add
	dec d
	jr z, .next
	rrca
	jr c, .loop
	jr .loop_no_add
.next
	ld b, h
	ld c, l
	
	call OpenBox ; the day-care mon is in save RAM
	ld hl, sDayCareMonExp + 2
	;add exp 
	ld a, c	
	add [hl]
	ld [hld], a
	ld a, b
	adc [hl]
	ld [hld], a
	ld a, 0
	adc [hl]
	ld [hl], a
	jr nc, .closeBox
	
;joenote - set the cap at $FFFFFF exp
	ld a, $FF
	ld [hli], a
	ld [hli], a
	ld [hl], a
.closeBox
	call CloseBox
.return
	pop de
	pop bc
	ret
