TitleScroll_WaitBall:
; Wait around for the TitleBall animation to play out.
; hi: speed
; lo: duration
	db $05, $05, 0

TitleScroll_In:
; Scroll a TitleMon in from the right.
; hi: speed
; lo: duration
	db $a2, $94, $84, $63, $52, $31, $11, 0

TitleScroll_Out:
; Scroll a TitleMon out to the left.
; hi: speed
; lo: duration
	db $12, $22, $32, $42, $52, $62, $83, $93, $a3, 0	;joenote - added a3 at the end for a bit more scrolling

TitleScroll:
	ld a, d		;d = 0 or 1

;japanese red/green has its own scrolling parameters
IF DEF(_RGTITLE)
	lb bc, $8, $14

	and a
	jr z, .ok

	ld d, $a0
	ld c, $c
ELSE
	ld bc, TitleScroll_In
	ld d, $88
	ld e, 0 ; don't animate titleball

	and a
	jr nz, .ok

	ld bc, TitleScroll_Out
	ld d, $00
	ld e, 0 ; don't animate titleball
ENDC
.ok

IF DEF(_RGTITLE)
;do nothing
ELSE
_TitleScroll:
	ld a, [bc]
	and a
	ret z

	inc bc
	push bc

	ld b, a
	and $f
	ld c, a
	ld a, b
	and $f0
	swap a
	ld b, a
ENDC

.loop
	ld h, d
	ld l, $48
	call .ScrollBetween

	ld h, $00
	ld l, $88
	call .ScrollBetween

	ld a, d
	add b
	ld d, a

;japanese red/green does not have the title screen pokeball
IF DEF(_RGTITLE)
	;do nothing
ELSE
	call GetTitleBallY
ENDC

	dec c
	jr nz, .loop

IF DEF(_RGTITLE)
	ret
ELSE
	pop bc	;the corresponding push is in the _TitleScroll conditional
	jr _TitleScroll
ENDC

.ScrollBetween:
	predef BGLayerScrollingUpdate	;joenote - consolidated into a predef that also fixes some issues

.wait2
	ld a, [rLY] ; rLY
	cp h
	jr z, .wait2
	ret

TitleBallYTable:
; OBJ y-positions for the Poke Ball held by Red in the title screen.
; This is really two 0-terminated lists. Initiated with an index of 1.
IF DEF(_REDGREENJP)
	db 0, $70, 0
ELSE
	db 0, $71, $6f, $6e, $6d, $6c, $6d, $6e, $6f, $71, $74, 0
ENDC

IF DEF(_REDGREENJP)
;nothing
ELSE
TitleScreenAnimateBallIfStarterOut:
; Animate the TitleBall if a starter just got scrolled out.
	ld a, [wTitleMonSpecies]
	cp STARTER1
	jr z, .ok
	cp STARTER2
	jr z, .ok
	cp STARTER3
	ret nz
.ok
	ld e, 1 ; animate titleball
	ld bc, TitleScroll_WaitBall
	ld d, 0
	jp _TitleScroll
ENDC

GetTitleBallY:
; Get position e from TitleBallYTable
	push de
	push hl
	xor a
	ld d, a
	ld hl, TitleBallYTable
	add hl, de
	ld a, [hl]
	pop hl
	pop de
	and a
	ret z
	ld [wOAMBuffer + $28], a
	inc e
	ret
