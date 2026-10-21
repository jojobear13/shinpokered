; The door shuffle (Randomizer.shuffle_doors): the world is attached to the
; start one entrance at a time. An entrance not reached yet (a slot) is
; paired with a random open one (reached, not paired) of the kind that may
; lead to it: dead ends first while there are doorways of their kind to
; spare, then places that open more doors. When everything is reached, the
; open ones left are paired among themselves. Carry if part of the world
; was cut off.

RandoShuffleDoors:
	call RandoDoorsStart
.step
	call RandoClassify
	jr z, .attached
	call RandoPickF
	push de
	call RandoNeedOf            ; a = the kind of door f needs
	ld [sRandoKind], a
	ld e, a
	ld d, 0
	ld hl, sRandoOpenN
	add hl, de
	ld c, [hl]
	ld b, 0
	call RandoRand
	call RandoNthOpenOfKind     ; de = e
	pop bc                      ; bc = f
	push bc
	call RandoPair
	pop de
	call RandoNodeOf
	call RandoVisit
	call RandoClosure
	jr .step

.attached
	; a slot neither paired nor reached: that part of the world is cut off
	ld de, 0
.check
	call RandoIsFresh
	jr z, .paired
	scf
	ret
.paired
	inc de
	call RandoDESlotsDone
	jr nz, .check

	; the outside doors left with the inside doors left
.outside
	ld a, KIND_OUT
	call RandoFirstUnpairedOfKind
	jr c, .stairs
	push de
	ld a, KIND_IN
	ld [sRandoKind], a
	ld de, $ffff
	call RandoCountUnpaired     ; bc = how many
	call RandoRand
	ld de, $ffff
	call RandoNthUnpaired       ; de = b
	pop bc
	call RandoPair
	jr .outside
	; the stairs left among themselves
.stairs
	ld a, KIND_STAIRS
	call RandoFirstUnpairedOfKind
	jr c, .done
	push de
	ld a, KIND_STAIRS
	ld [sRandoKind], a
	call RandoCountUnpaired     ; not counting de
	call RandoRand
	pop de
	push de
	call RandoNthUnpaired
	pop bc
	call RandoPair
	jr .stairs
.done
	and a
	ret

; every slot unpaired; reach (with the key items, and the events reached)
; from the start
RandoDoorsStart:
	ld hl, sRandoPartner
	ld bc, 2 * RANDO_SLOTS
	ld a, $ff
	call FillMemory
	ld hl, sRandoState
	ld bc, RANDO_SLOTS
	call RandoClearBC
	ld hl, sRandoWitness
	ld bc, RANDO_SLOTS
	call RandoClearBC
	ld hl, sRandoOpenN
	ld bc, 3
	call RandoClearBC
	call RandoKeyItemsHave
	ld hl, sRandoStartHave
	ld de, sRandoHave
	ld bc, 4
	call CopyData
	ld a, MODE_EVENTS
	ld de, RANDO_START
	jp RandoSearchReach

; nz while de < RANDO_SLOTS
RandoDESlotsDone:
	ld a, e
	cp LOW(RANDO_SLOTS)
	ret nz
	ld a, d
	cp HIGH(RANDO_SLOTS)
	ret

; pair slots bc and de
RandoPair:
	call RandoPaired
	push de
	ld d, b
	ld e, c
	call RandoPaired
	pop de
	ld hl, sRandoPartner
	add hl, de
	add hl, de
	ld a, c
	ld [hli], a
	ld [hl], b
	ld hl, sRandoPartner
	add hl, bc
	add hl, bc
	ld a, e
	ld [hli], a
	ld [hl], d
	ret

; slot de is paired now (no longer open)
RandoPaired:
	push bc
	ld hl, sRandoState
	add hl, de
	ld a, [hl]
	ld [hl], STATE_PAIRED
	cp STATE_OPEN
	jr nz, .done
	call RandoKindOf
	ld c, a
	ld b, 0
	ld hl, sRandoOpenN
	add hl, bc
	dec [hl]
.done
	pop bc
	ret

; de = slot -> a = the kind of door it pairs with
RandoNeedOf:
	call RandoKindOf
	cp KIND_STAIRS
	ret z
	xor 1
	ret

; nz if slot de is open
RandoIsOpen:
	ld hl, sRandoState
	add hl, de
	bit 1, [hl]
	ret

; nz if slot de is unpaired and not open: one still to reach
RandoIsFresh:
	ld hl, sRandoState
	add hl, de
	ld a, [hl]
	and a
	jr z, .fresh
	xor a
	ret
.fresh
	or 1
	ret

; Go through the slots still to reach (unpaired, not open, with an open
; door of the kind they need: the candidates), noting in sRandoClass
; whether each one's area has more to reach, and counting what deciding
; their classes needs:
;  1 a dead end that may be attached (open doors of its kind to spare, or
;    the only one needing that kind)
;  2 a place that opens more doors
;  3 such a floor whose area also has a door outside, without stairs to
;    spare: better reached through that door
;  4 the rest
; z if there are no candidates.
DEF CLASS_CAND EQU 1 << 7
DEF CLASS_MORE EQU 1 << 6
DEF CLASS_NOT_STAIRS EQU 1 << 5
RandoClassify:
	ld hl, sRandoDemand
	ld bc, sRandoCountsEnd - sRandoDemand
	call RandoClearBC
	ld de, 0
.loop
	ld hl, sRandoState
	add hl, de
	ld a, [hl]
	ld bc, sRandoClass - sRandoState
	add hl, bc
	ld [hl], 0
	and a
	jp nz, .next                ; not one to reach
	ld hl, RandoSlotKind
	add hl, de
	ld a, [hl]
	cp KIND_STAIRS
	jr z, .need
	xor 1
.need
	ld c, a                     ; the kind it needs
	ld b, 0
	ld hl, sRandoOpenN
	add hl, bc
	ld a, [hl]
	and a
	jp z, .next                 ; none of those open
	ld [sRandoTmp], a           ; open doors of the kind it needs
	ld a, c
	ld [sRandoTmp + 1], a       ; that kind
	ld hl, sRandoDemand
	add hl, bc
	inc [hl]
	ld hl, sRandoCands
	call RandoInc16
	call RandoMore
	or CLASS_CAND
	ld hl, sRandoClass
	add hl, de
	ld [hl], a
	bit 6, a
	jr z, .deadEnd
	; opens more
	bit 5, a
	jr z, .grower
	ld hl, RandoSlotKind
	add hl, de
	ld a, [hl]
	cp KIND_STAIRS
	jr nz, .grower
	ld hl, sRandoStairsAnch
	call RandoInc16
	jr .next
.grower
	ld hl, sRandoGrowers
	call RandoInc16
	jr .next
.deadEnd
	ld hl, RandoSlotKind
	add hl, de
	ld a, [hl]
	cp KIND_STAIRS
	jr nz, .notStairs
	ld hl, sRandoDeadStairs
	call RandoInc16
.notStairs
	ld a, [sRandoTmp]
	cp 2
	jr c, .cond
	ld hl, sRandoLeaves
	call RandoInc16
	jr .next
.cond
	; a leaf only if it's the only one needing its kind (known at the end)
	ld a, [sRandoTmp + 1]
	add a
	ld c, a
	ld b, 0
	ld hl, sRandoLeafCond
	add hl, bc
	call RandoInc16
.next
	inc de
	ld a, e
	cp LOW(RANDO_SLOTS)
	jp nz, .loop
	ld a, d
	cp HIGH(RANDO_SLOTS)
	jp nz, .loop
	; stairs to spare? more open stairs than dead-end stairs to reach
	ld a, [sRandoDeadStairs + 1]
	and a
	ld b, 0
	jr nz, .spareKnown
	ld a, [sRandoDeadStairs]
	ld c, a
	ld a, [sRandoOpenN + KIND_STAIRS]
	cp c
	jr z, .spareKnown
	jr c, .spareKnown
	inc b
.spareKnown
	ld a, b
	ld [sRandoSpare], a
	; the leaves whose kind only one needs
	ld c, 0
.cond2
	ld b, 0
	ld hl, sRandoDemand
	add hl, bc
	ld a, [hl]
	cp 1
	jr nz, .nextCond
	push bc
	ld a, c
	add a
	ld c, a
	ld hl, sRandoLeafCond
	add hl, bc
	ld a, [hli]
	ld c, a
	ld b, [hl]
	ld hl, sRandoLeaves
	call RandoAdd16
	pop bc
.nextCond
	inc c
	ld a, c
	cp 3
	jr nz, .cond2
	; with stairs to spare, those floors open more like the rest
	ld a, [sRandoSpare]
	and a
	jr z, .noSpare
	ld hl, sRandoStairsAnch
	ld a, [hli]
	ld c, a
	ld b, [hl]
	ld hl, sRandoGrowers
	call RandoAdd16
	xor a
	ld [sRandoStairsAnch], a
	ld [sRandoStairsAnch + 1], a
.noSpare
	ld hl, sRandoCands
	ld a, [hli]
	or [hl]
	ret

RandoInc16:
	inc [hl]
	ret nz
	inc hl
	inc [hl]
	ret

; [hl] += bc (16 bits)
RandoAdd16:
	ld a, [hl]
	add c
	ld [hli], a
	ld a, [hl]
	adc b
	ld [hl], a
	ret

; slot de -> a: CLASS_MORE if its area has a slot still to reach, and
; CLASS_NOT_STAIRS if one of those isn't stairs. A slot stops being one to
; reach for good, so each looks on from where it last found one
; (sRandoWitness: the low nibble for any, the high for not stairs; 15 none).
RandoMore:
	push de
	ld hl, RandoKindsIndex
	add hl, de
	add hl, de
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	sub c
	srl a
	ld [sRandoKindsN], a        ; how many (at most 14)
	ld hl, RandoKinds
	add hl, bc
	ld a, l
	ld [sRandoPtr], a
	ld a, h
	ld [sRandoPtr + 1], a
	ld hl, sRandoWitness
	add hl, de
	push hl
	ld a, [hl]
	and $f
	ld b, 0                     ; b: any
	call .scan
	ld c, a
	pop hl
	push hl
	ld a, [hl]
	swap a
	and $f
	push bc
	ld b, 1                     ; b: not stairs
	call .scan
	pop bc
	pop hl
	swap a
	or c
	ld [hl], a
	ld b, 0
	ld a, c
	cp $f
	jr z, .noMore
	ld b, CLASS_MORE
.noMore
	ld a, [hl]
	and $f0
	cp $f0
	ld a, b
	jr z, .done
	or CLASS_NOT_STAIRS
.done
	pop de
	ret

; a = where to start -> a = the first fit at or after it (15 if none);
; b = 0: any slot still to reach; 1: one that isn't stairs
.scan
	cp $f
	ret z
	ld c, a
.try
	ld a, [sRandoKindsN]
	cp c
	jr z, .none
	push bc
	ld a, [sRandoPtr]
	ld l, a
	ld a, [sRandoPtr + 1]
	ld h, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld e, a
	ld d, [hl]
	ld hl, sRandoState
	add hl, de
	ld a, [hl]
	pop bc
	and a
	jr nz, .no                  ; not one to reach
	ld a, b
	and a
	jr z, .fit
	ld hl, RandoSlotKind
	add hl, de
	ld a, [hl]
	cp KIND_STAIRS
	jr nz, .fit
.no
	inc c
	jr .try
.fit
	ld a, c
	ret
.none
	ld a, $f
	ret

; slot de's class (sRandoClass and the counts from RandoClassify) -> a (0: not a candidate)
RandoClassOf:
	ld hl, sRandoClass
	add hl, de
	ld a, [hl]
	and a
	ret z
	bit 6, a
	jr z, .deadEnd
	bit 5, a
	jr z, .grower
	call RandoKindOf
	cp KIND_STAIRS
	jr nz, .grower
	ld a, [sRandoSpare]
	and a
	jr nz, .grower
	ld a, 3
	ret
.grower
	ld a, 2
	ret
.deadEnd
	call RandoNeedOf
	ld c, a
	ld b, 0
	ld hl, sRandoOpenN
	add hl, bc
	ld a, [hl]
	cp 2
	jr nc, .leaf
	ld hl, sRandoDemand
	add hl, bc
	ld a, [hl]
	cp 1
	jr z, .leaf
	ld a, 4
	ret
.leaf
	ld a, 1
	ret

; de = the slot to attach: a random one of the first class there is
; (dead ends, places that open more, floors better reached from outside,
; then any candidate)
RandoPickF:
	ld hl, sRandoLeaves
	ld a, [hli]
	ld c, a
	ld b, [hl]
	or b
	ld a, 1
	jr nz, .pick
	ld hl, sRandoGrowers
	ld a, [hli]
	ld c, a
	ld b, [hl]
	or b
	ld a, 2
	jr nz, .pick
	ld hl, sRandoStairsAnch
	ld a, [hli]
	ld c, a
	ld b, [hl]
	or b
	ld a, 3
	jr nz, .pick
	ld hl, sRandoCands
	ld a, [hli]
	ld c, a
	ld b, [hl]
	xor a                       ; any
.pick
	ld [sRandoKind], a
	call RandoRand
	; the bc-th slot of that class, in slot order
	ld de, 0
.scan
	ld hl, sRandoClass
	add hl, de
	ld a, [hl]
	and a
	jr z, .nextScan
	push bc
	call RandoClassOf
	pop bc
	ld h, a
	ld a, [sRandoKind]
	and a
	jr z, .match
	cp h
	jr nz, .nextScan
.match
	ld a, b
	or c
	ret z
	dec bc
.nextScan
	inc de
	jr .scan

; bc = n -> de = the n-th open slot of kind [sRandoKind]
RandoNthOpenOfKind:
	ld de, 0
.loop
	call RandoIsOpen
	jr z, .next
	call RandoKindOf
	ld h, a
	ld a, [sRandoKind]
	cp h
	jr nz, .next
	ld a, b
	or c
	ret z
	dec bc
.next
	inc de
	jr .loop

; a = kind -> de = the first unpaired slot of it (carry if none)
RandoFirstUnpairedOfKind:
	ld [sRandoKind], a
	ld de, 0
.loop
	ld hl, sRandoState
	add hl, de
	bit 0, [hl]
	jr nz, .next
	call RandoKindOf
	ld h, a
	ld a, [sRandoKind]
	cp h
	ret z                       ; carry clear: cp equal
.next
	inc de
	call RandoDESlotsDone
	jr nz, .loop
	scf
	ret

; bc = how many unpaired slots of kind [sRandoKind] there are, not counting slot de
RandoCountUnpaired:
	ld a, d
	ld [sRandoSkip], a
	ld a, e
	ld [sRandoSkip + 1], a
	ld bc, 0
	ld de, 0
.loop
	call RandoUnpairedOfKind
	jr z, .next
	inc bc
.next
	inc de
	call RandoDESlotsDone
	jr nz, .loop
	ret

; bc = n -> de = the n-th unpaired slot of kind [sRandoKind], skipping slot de
RandoNthUnpaired:
	ld a, d
	ld [sRandoSkip], a
	ld a, e
	ld [sRandoSkip + 1], a
	ld de, 0
.loop
	call RandoUnpairedOfKind
	jr z, .next
	ld a, b
	or c
	ret z
	dec bc
.next
	inc de
	jr .loop

; nz if slot de is unpaired, of kind [sRandoKind] and not [sRandoSkip]
RandoUnpairedOfKind:
	ld a, [sRandoSkip]
	cp d
	jr nz, .notSkipped
	ld a, [sRandoSkip + 1]
	cp e
	jr z, .no
.notSkipped
	ld hl, sRandoState
	add hl, de
	bit 0, [hl]
	jr nz, .no
	call RandoKindOf
	ld h, a
	ld a, [sRandoKind]
	cp h
	jr nz, .no
	or 1
	ret
.no
	xor a
	ret
