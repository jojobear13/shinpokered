; Placing the items (Randomizer.place_items): the progression items one at a
; time, each where it can be reached holding the ones still to place (the
; "assumed fill"); the other key items anywhere a key item may go; then the
; ground items shuffled into the rest. Carry if an item had nowhere to go.

RandoPlaceItems:
	call RandoClearPlace
	ld hl, RandoProgItems
	ld de, sRandoKeys
	ld bc, RANDO_NUM_PROG
	call CopyData
	ld hl, sRandoKeys
	ld b, RANDO_NUM_PROG
	call RandoShuffleBytes
	xor a
	ld [sRandoKeyIndex], a
.prog
	; hold the ones after this one
	ld hl, sRandoStartHave
	call RandoClear4
	ld a, [sRandoKeyIndex]
	inc a
.held
	cp RANDO_NUM_PROG
	jr z, .sweep
	push af
	ld e, a
	ld d, 0
	ld hl, sRandoKeys
	add hl, de
	ld a, [hl]
	call RandoProgAtom
	ld e, a
	ld d, 0
	ld hl, sRandoStartHave
	call RandoSet
	pop af
	inc a
	jr .held
.sweep
	call RandoSweepFromStart
	ld a, 1
	ld [sRandoNeedTaken], a
	call RandoCountFreeKeyLocs
	ld a, b
	or c
	scf
	ret z
	call RandoRand
	call RandoNthFreeKeyLoc
	ld a, [sRandoKeyIndex]
	ld c, a
	ld b, 0
	ld hl, sRandoKeys
	add hl, bc
	ld a, [hl]
	ld hl, sRandoPlace
	add hl, de
	ld [hl], a
	ld hl, sRandoKeyIndex
	inc [hl]
	ld a, [hl]
	cp RANDO_NUM_PROG
	jr nz, .prog

	; the other key items: any free location a key item may go
	xor a
	ld [sRandoNeedTaken], a
	ld hl, RandoKeyItems
.others
	ld a, [hli]
	cp $ff
	jr z, .ground
	push hl
	ld [sRandoItem], a
	call RandoProgAtom
	jr c, .nextOther
	call RandoCountFreeKeyLocs
	call RandoRand
	call RandoNthFreeKeyLoc
	ld hl, sRandoPlace
	add hl, de
	ld a, [sRandoItem]
	ld [hl], a
.nextOther
	pop hl
	jr .others

.ground
	; every location's vanilla item, less one of each key item, shuffled
	ld de, 0
.vanilla
	push de
	call RandoLocInfoOf
	inc hl
	inc hl
	ld a, [hl]
	pop de
	ld hl, sRandoRest
	add hl, de
	ld [hl], a
	inc de
	ld a, e
	cp RANDO_LOCS
	jr nz, .vanilla
	ld a, RANDO_LOCS
	ld [sRandoRestN], a
	ld hl, RandoKeyItems
.remove
	ld a, [hli]
	cp $ff
	jr z, .shuffle
	push hl
	call RandoRemoveRest
	pop hl
	jr .remove
.shuffle
	ld hl, sRandoRest
	ld a, [sRandoRestN]
	ld b, a
	call RandoShuffleBytes
	; into the free locations, in order
	ld hl, sRandoRest
	ld de, 0
.fill
	push hl
	ld hl, sRandoPlace
	add hl, de
	ld a, [hl]
	and a
	jr nz, .placed
	ld b, h
	ld c, l
	pop hl
	ld a, [hli]
	ld [bc], a
	push hl
.placed
	pop hl
	inc de
	ld a, e
	cp RANDO_LOCS
	jr nz, .fill
	and a
	ret

; shuffle the b bytes at hl (Rng.shuffle: from the end, each swapped with
; one at or before it)
RandoShuffleBytes:
	ld a, l
	ld [sRandoPtr], a
	ld a, h
	ld [sRandoPtr + 1], a
.loop
	dec b
	ret z
	push bc
	ld c, b
	inc c
	ld b, 0
	call RandoRand              ; bc = j, at most i
	pop de                      ; d = i
	push de
	ld a, [sRandoPtr]
	ld l, a
	ld a, [sRandoPtr + 1]
	ld h, a
	push hl
	add hl, bc                  ; hl = &lst[j]
	pop bc
	ld a, d
	add c
	ld c, a
	jr nc, .noCarry
	inc b                       ; bc = &lst[i]
.noCarry
	ld a, [bc]
	ld e, [hl]
	ld [hl], a
	ld a, e
	ld [bc], a
	pop bc
	jr .loop

; remove the first a in sRandoRest (sRandoRestN long)
RandoRemoveRest:
	ld hl, sRandoRest
	ld c, a
	ld a, [sRandoRestN]
	ld b, a
.find
	ld a, [hli]
	cp c
	jr z, .found
	dec b
	jr nz, .find
	ret
.found
	dec b
	jr z, .last
.shift
	ld a, [hld]
	ld [hli], a
	inc hl
	dec b
	jr nz, .shift
.last
	ld hl, sRandoRestN
	dec [hl]
	ret

; bc = the locations that may hold a key item, are free and (if
; sRandoNeedTaken) were reached
RandoCountFreeKeyLocs:
	ld bc, 0
	ld de, 0
.loop
	call RandoFreeKeyLoc
	jr z, .next
	inc bc
.next
	inc de
	ld a, e
	cp RANDO_LOCS
	jr nz, .loop
	ret

; bc = n -> de = the n-th of those
RandoNthFreeKeyLoc:
	ld de, 0
.loop
	call RandoFreeKeyLoc
	jr z, .next
	ld a, b
	or c
	ret z
	dec bc
.next
	inc de
	jr .loop

; nz if location de may hold a key item, is free and (if sRandoNeedTaken) taken
RandoFreeKeyLoc:
	push bc
	ld hl, sRandoPlace
	add hl, de
	ld a, [hl]
	and a
	jr nz, .no
	push de
	call RandoLocInfoOf
	pop de
	inc hl
	bit 0, [hl]
	jr z, .no
	ld a, [sRandoNeedTaken]
	and a
	jr z, .yes
	ld hl, sRandoTaken
	call RandoTest
	jr z, .no
.yes
	pop bc
	or 1
	ret
.no
	pop bc
	xor a
	ret
