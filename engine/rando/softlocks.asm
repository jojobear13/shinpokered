; The softlock check (regions.softlocks), in the generator's second bank:
; round by round through a playthrough, the places a player could walk
; into but not back out of to the start. Only the sink components of those
; need checking (every one drains into one): from each, can the game still
; be finished? sRandoSoftlock: 1 if somewhere can't.

RandoBSoftlocks::
	xor a
	ld [sRandoSoftlock], a
	ld hl, sRandoSlHave
	call RandoBClear4
	ld hl, sRandoSlTaken
	ld bc, LOC_BYTES
	call RandoBClearBC
.round
	call RandoBSlHaveIn
	; seen: along the edges from the start
	ld hl, sRandoSeen
	ld bc, 0
	xor a
	call RandoBSearch
	; back: against them
	ld hl, sRandoBack
	ld bc, 0
	ld a, 1
	call RandoBSearch
	; bad: seen and not back
	ld hl, sRandoSeen
	ld de, sRandoBack
	ld bc, sRandoBad
	ld a, NODE_BYTES
.bad
	push af
	ld a, [de]
	cpl
	and [hl]
	ld [bc], a
	inc hl
	inc de
	inc bc
	pop af
	dec a
	jr nz, .bad
	ld hl, sRandoDone
	call RandoBClearNodes
	ld de, 0
.node
	ld hl, sRandoBad
	call RandoBTest
	jp z, .nextNode
	ld hl, sRandoDone
	call RandoBTest
	jp nz, .nextNode
	push de
	call RandoBSlHaveIn         ; (a sweep from the last sink held more)
	pop de
	push de
	ld hl, sRandoFwd            ; along the edges, within bad
	ld bc, sRandoBad
	xor a
	call RandoBSearchFrom
	pop de
	push de
	ld hl, sRandoBk             ; against them
	ld bc, sRandoBad
	ld a, 1
	call RandoBSearchFrom
	call RandoBFwdInBk
	pop de
	push de
	jr nz, .notSink
	; a sink: can the game still be finished from there?
	call RandoBSlHaveIn
	ld hl, sRandoSlTaken
	ld de, sRandoTaken
	ld bc, LOC_BYTES
	call CopyData
	pop de
	push de
	call RandoBSweepFrom
	call RandoBBeaten
	jr nc, .softlock
	ld hl, sRandoFwd            ; done |= fwd
	ld bc, sRandoDone
	call RandoBOrInto
	jr .popNext
.notSink
	ld hl, sRandoFwd            ; done |= fwd & bk: its component
	ld de, sRandoBk
	ld bc, sRandoDone
	ld a, NODE_BYTES
.comp
	push af
	ld a, [de]
	and [hl]
	push hl
	ld h, b
	ld l, c
	or [hl]
	ld [hl], a
	pop hl
	inc hl
	inc de
	inc bc
	pop af
	dec a
	jr nz, .comp
.popNext
	pop de
.nextNode
	inc de
	ld a, e
	cp LOW(RANDO_NODES)
	jp nz, .node
	ld a, d
	cp HIGH(RANDO_NODES)
	jp nz, .node

	; the round's events and locations, from seen, with what was held
	; before them (gathered apart in sRandoNew)
	call RandoBSlHaveIn
	ld hl, sRandoNew
	call RandoBClear4
	ld a, LOW(sRandoSeen)
	ld [sRandoVisited], a
	ld a, HIGH(sRandoSeen)
	ld [sRandoVisited + 1], a
	call RandoBRoundEvents
	call RandoBRoundLocs
	; have |= new, then what follows
	ld hl, sRandoNew
	ld de, sRandoHave
	ld c, 4
.or
	ld a, [de]
	or [hl]
	ld [de], a
	inc hl
	inc de
	dec c
	jr nz, .or
	call RandoBDerive
	; grown?
	ld hl, sRandoHave
	ld de, sRandoSlHave
	ld c, 4
	ld b, 0
.cmp
	ld a, [de]
	cp [hl]
	jr z, .same
	inc b
.same
	ld a, [hli]
	ld [de], a
	inc de
	dec c
	jr nz, .cmp
	ld a, b
	and a
	jp nz, .round
	ret
.softlock
	pop de
	ld a, 1
	ld [sRandoSoftlock], a
	ret

; sRandoHave = sRandoSlHave
RandoBSlHaveIn:
	ld hl, sRandoSlHave
	ld de, sRandoHave
	ld bc, 4
	jp CopyData

; search from the start into the set at hl, a = 0 along the edges, 1
; against them; no limit, nothing taken
RandoBSearch:
	ld de, RANDO_START
	ld bc, 0
; ... from node de, staying within the set at bc (0: none)
RandoBSearchFrom:
	ld [sRandoDir], a
	xor a
	ld [sRandoMode], a
	ld a, l
	ld [sRandoVisited], a
	ld a, h
	ld [sRandoVisited + 1], a
	ld a, c
	ld [sRandoLimit], a
	ld a, b
	ld [sRandoLimit + 1], a
	push de
	call RandoBClearNodes
	call RandoBResetStack
	pop de
	call RandoBVisit
	jp RandoBDrain

; z if sRandoFwd is within sRandoBk
RandoBFwdInBk:
	ld hl, sRandoFwd
	ld de, sRandoBk
	ld c, NODE_BYTES
.loop
	ld a, [de]
	cpl
	and [hl]
	ret nz
	inc hl
	inc de
	dec c
	jr nz, .loop
	xor a
	ret

; or the node set at hl into the one at bc
RandoBOrInto:
	ld e, NODE_BYTES
.loop
	ld a, [bc]
	or [hl]
	ld [bc], a
	inc hl
	inc bc
	dec e
	jr nz, .loop
	ret

; the events not held whose places were seen: into sRandoNew
RandoBRoundEvents:
	ld hl, RandoBEvents
.loop
	ld a, [hli]
	cp $ff
	ret z
	ld b, a                     ; atom
	ld a, [hli]
	ld c, a                     ; nodes
	ld a, b
	push hl
	call RandoBHas
	pop hl
	jr nz, .skip
	push bc
	call RandoBAnyVisited
	pop bc
	jr z, .loop
	push hl
	ld e, b
	ld d, 0
	ld hl, sRandoNew
	call RandoBSet
	pop hl
	jr .loop
.skip
	ld b, 0
	add hl, bc
	add hl, bc
	jr .loop

; the locations seen, not taken, whose requirement was held: taken (into
; sRandoSlTaken), their progression items into sRandoNew
RandoBRoundLocs:
	ld de, 0
.node
	call RandoBVisited
	jr z, .nextNode
	push de
	ld hl, RandoBNodeLocsIndex
	add hl, de
	ld a, [hli]
	ld c, a
	ld a, [hl]
	sub c
	jr z, .done
	ld b, a
	ld e, c
	ld d, 0
	ld hl, RandoBNodeLocs
	add hl, de
.loc
	ld a, [hli]
	push hl
	push bc
	ld e, a
	ld d, 0
	call .take
	pop bc
	pop hl
	dec b
	jr nz, .loc
.done
	pop de
.nextNode
	inc de
	ld a, e
	cp LOW(RANDO_NODES)
	jr nz, .node
	ld a, d
	cp HIGH(RANDO_NODES)
	jr nz, .node
	ret

.take
	ld hl, sRandoSlTaken
	call RandoBTest
	ret nz
	call RandoBLocInfoOf
	ld a, [hl]
	and a
	jr z, .free
	dec a
	call RandoBHas
	ret z
.free
	ld hl, sRandoSlTaken
	call RandoBSet
	ld hl, sRandoPlace
	add hl, de
	ld a, [hl]
	call RandoBProgAtom
	ret nc
	ld e, a
	ld d, 0
	ld hl, sRandoNew
	jp RandoBSet
