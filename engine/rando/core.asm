; The randomizer's searches, assembled into both of the generator's banks:
; every label is {RP}Name, RP being the bank's prefix (RandoA, RandoB).
;
; A search grows the node set sRandoVisited points at (staying within the
; one sRandoLimit points at, if not 0), along the edges (sRandoDir 0) or
; against them (1). With MODE_EVENTS it takes the events whose places it
; reaches; with MODE_LOCS the locations too, and the progression items
; sRandoPlace holds there. What that gains goes into sRandoHave and opens
; the edges it allows (from the nodes already reached: {RP}AtomSrc), so a
; search runs once through the world, however much it gains on the way.

; ---- bit sets

; hl = set, de = index -> hl = its byte, c = its mask
{RP}Bit:
	push de
	ld a, e
	and 7
	ld c, a
	srl d
	rr e
	srl d
	rr e
	srl d
	rr e
	add hl, de
	push hl
	ld hl, {RP}BitMasks
	ld e, c
	ld d, 0
	add hl, de
	ld c, [hl]
	pop hl
	pop de
	ret

{RP}BitMasks:
	db 1, 2, 4, 8, 16, 32, 64, 128

; nz if bit de of the set at hl is set (hl, bc, de kept)
{RP}Test:
	push hl
	push bc
	call {RP}Bit
	ld a, [hl]
	and c
	pop bc
	pop hl
	ret

{RP}Set:
	push hl
	push bc
	call {RP}Bit
	ld a, [hl]
	or c
	ld [hl], a
	pop bc
	pop hl
	ret

{RP}Clear4:
	ld bc, 4
	jr {RP}ClearBC

{RP}ClearNodes:
	ld bc, NODE_BYTES
{RP}ClearBC:
	xor a
	jp FillMemory

; nz if atom a is held
{RP}Has:
	push de
	ld e, a
	ld d, 0
	ld hl, sRandoHave
	call {RP}Test
	pop de
	ret

; ---- the stack (wOverworldMap: no map is loaded while the generator runs)

{RP}Push:
	ld hl, sRandoSP
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, e
	ld [hli], a
	ld a, d
	ld [hli], a
	ld a, l
	ld [sRandoSP], a
	ld a, h
	ld [sRandoSP + 1], a
	ret

; z if the stack is empty, else de = the node popped
{RP}Pop:
	ld hl, sRandoSP
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, l
	cp LOW(wOverworldMap)
	jr nz, .pop
	ld a, h
	cp HIGH(wOverworldMap)
	ret z
.pop
	dec hl
	ld d, [hl]
	dec hl
	ld e, [hl]
	ld a, l
	ld [sRandoSP], a
	ld a, h
	ld [sRandoSP + 1], a
	or 1
	ret

{RP}ResetStack:
	ld a, LOW(wOverworldMap)
	ld [sRandoSP], a
	ld a, HIGH(wOverworldMap)
	ld [sRandoSP + 1], a
	ret

; ---- slots

; de = slot -> de = its partner (carry if none)
{RP}PartnerOf:
	ld hl, sRandoPartner
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld a, [hl]
	ld d, a
	and e
	inc a
	ret nz
	scf
	ret

; de = slot -> de = its node (where one arrives through it, and leaves it from)
{RP}NodeOf:
	ld hl, {RP}SlotNode
	add hl, de
	add hl, de
	ld a, [hli]
	ld e, a
	ld d, [hl]
	ret

; de = slot -> de = the second node it is left from ($ffff if none)
{RP}Node2Of:
	ld hl, {RP}SlotNode2
.loop
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	and c
	inc a
	jr z, .none
	ld a, c
	cp e
	jr nz, .next
	ld a, b
	cp d
	jr nz, .next
	ld a, [hli]
	ld e, a
	ld d, [hl]
	ret
.next
	inc hl
	inc hl
	jr .loop
.none
	ld de, $ffff
	ret

; de = slot -> a = its kind
{RP}KindOf:
	ld hl, {RP}SlotKind
	add hl, de
	ld a, [hl]
	ret

; slot de (unpaired) is reached: open, if it wasn't (the door shuffle's state)
{RP}MarkOpen:
	ld hl, sRandoState
	add hl, de
	ld a, [hl]
	and a
	ret nz
	ld [hl], STATE_OPEN
	call {RP}KindOf
	ld c, a
	ld b, 0
	ld hl, sRandoOpenN
	add hl, bc
	inc [hl]
	ret

; ---- searching

; reach node de if allowed and not reached yet (and push it)
{RP}Visit:
	ld a, [sRandoLimit]
	ld l, a
	ld a, [sRandoLimit + 1]
	ld h, a
	or l
	jr z, .free
	call {RP}Test
	ret z
.free
	ld a, [sRandoVisited]
	ld l, a
	ld a, [sRandoVisited + 1]
	ld h, a
	call {RP}Test
	ret nz
	call {RP}Set
	jp {RP}Push

; nz if node de has been reached
{RP}Visited:
	ld a, [sRandoVisited]
	ld l, a
	ld a, [sRandoVisited + 1]
	ld h, a
	jp {RP}Test

; the edges of node de: hl = the first, bc = how many
{RP}EdgesOf:
IF DEF(RANDO_HAS_REV)
	ld a, [sRandoDir]
	and a
	ld hl, {RP}AdjIndex
	ld bc, {RP}Adj
	jr z, .got
	ld hl, {RP}RevIndex
	ld bc, {RP}Rev
.got
ELSE
	ld hl, {RP}AdjIndex
	ld bc, {RP}Adj
ENDC
	push bc
	add hl, de
	add hl, de
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a
	ld a, [hli]
	sub c
	ld e, a
	ld a, [hl]
	sbc b
	ld d, a
	pop hl
	add hl, bc
	srl d
	rr e
	ld b, d
	ld c, e
	ret

; follow the edges of node de that what's held allows; then (MODE_LOCS)
; take the locations there
{RP}Process:
	push de
	call {RP}EdgesOf
.loop
	ld a, b
	or c
	jr z, .done
	push bc
	ld a, [hli]
	ld e, a
	ld a, [hli]
	push hl
	ld d, a
	and %111
	ld b, a                     ; b:e = to
	ld a, d
	rrca
	rrca
	rrca
	and %11111                  ; a = code
	ld d, b
	jr z, .go
	cp RANDO_WARP
	jr z, .warp
	dec a
	call {RP}Has
	jr z, .next
.go
	call {RP}Visit
	jr .next
.warp
	ld a, [sRandoDir]
	and a
	jr nz, .warpBack
	; along: through slot de to its partner's node
	push de
	call {RP}PartnerOf
	jr c, .unpaired
	pop af
	call {RP}NodeOf
	call {RP}Visit
	jr .next
.unpaired
	pop de
	call {RP}MarkOpen
	jr .next
.warpBack
	; against: de is a slot arrived at; the way back leaves through its partner
	call {RP}PartnerOf
	jr c, .next
	push de
	call {RP}NodeOf
	call {RP}Visit
	pop de
	call {RP}Node2Of
	ld a, d
	and e
	inc a
	call nz, {RP}Visit
.next
	pop hl
	pop bc
	dec bc
	jr .loop
.done
	pop de
	ld a, [sRandoMode]
	bit MODE_LOCS_F, a
	ret z
	; fall through

; take the locations at node de whose requirement is held
{RP}TakeNodeLocs:
	push de
	ld hl, {RP}NodeLocsIndex
	add hl, de
	ld a, [hli]
	ld c, a
	ld a, [hl]
	sub c
	jr z, .done
	ld b, a                     ; how many
	ld e, c
	ld d, 0
	ld hl, {RP}NodeLocs
	add hl, de
.loop
	ld a, [hli]
	push hl
	push bc
	ld e, a
	ld d, 0
	call {RP}TakeLoc
	pop bc
	pop hl
	dec b
	jr nz, .loop
.done
	pop de
	ret

; take location de (if not taken and its requirement is held)
{RP}TakeLoc:
	ld hl, sRandoTaken
	call {RP}Test
	ret nz
	call {RP}LocInfoOf
	ld a, [hl]
	and a
	jr z, .free
	dec a
	call {RP}Has
	ret z
.free
	ld hl, sRandoTaken
	call {RP}Set
	ld hl, sRandoPlace
	add hl, de
	ld a, [hl]
	call {RP}ProgAtom
	ret nc
	; fall through

; gain atom a (into sRandoHave; what it opens is followed after the drain)
{RP}Gain:
	push de
	ld e, a
	ld d, 0
	ld hl, sRandoHave
	call {RP}Test
	jr nz, .done
	call {RP}Set
	ld hl, sRandoPending
	call {RP}Set
	call {RP}Derive
.done
	pop de
	ret

; de = location -> hl = its 3 bytes: the atom it needs + 1 (0: none),
; flags (bit 0: may hold a key item), its vanilla item
{RP}LocInfoOf:
	ld hl, {RP}LocInfo
	add hl, de
	add hl, de
	add hl, de
	ret

; a = item -> carry and a = its atom if it's a progression item
{RP}ProgAtom:
	and a
	ret z
	ld hl, {RP}ProgItems
	ld c, 0
.loop
	cp [hl]
	jr z, .found
	inc hl
	inc c
	ld b, a
	ld a, c
	cp RANDO_NUM_PROG
	ld a, b
	jr nz, .loop
	and a
	ret
.found
	ld a, c
	add RANDO_ATOM_S_S_TICKET
	scf
	ret

; what follows from what's held (logic.derived)
{RP}Derive:
	ld a, [sRandoHave]          ; the badges are atoms 0-7
	ld b, a
	ld a, [sRandoHave + RANDO_ATOM_HM_01 / 8]
	bit RANDO_ATOM_HM_01 % 8, a
	jr z, .noCut
	bit RANDO_ATOM_CASCADEBADGE, b
	jr z, .noCut
	push bc
	ld a, RANDO_ATOM_CUT
	call {RP}Gain
	pop bc
.noCut
	ld a, [sRandoHave + RANDO_ATOM_HM_03 / 8]
	bit RANDO_ATOM_HM_03 % 8, a
	jr z, .noSurf
	bit RANDO_ATOM_SOULBADGE, b
	jr z, .noSurf
	push bc
	ld a, RANDO_ATOM_SURF
	call {RP}Gain
	pop bc
.noSurf
	ld a, [sRandoHave + RANDO_ATOM_HM_04 / 8]
	bit RANDO_ATOM_HM_04 % 8, a
	jr z, .noStrength
	bit RANDO_ATOM_RAINBOWBADGE, b
	jr z, .noStrength
	push bc
	ld a, RANDO_ATOM_STRENGTH
	call {RP}Gain
	pop bc
.noStrength
	ld a, b
	and %01111111
	cp %01111111
	ret nz
	push bc
	ld a, RANDO_ATOM_BADGES7
	call {RP}Gain
	pop bc
	ld a, b
	inc a
	ret nz
	ld a, RANDO_ATOM_BADGES8
	jp {RP}Gain

; empty the stack, following edges
{RP}Drain:
	call {RP}Pop
	ret z
	call {RP}Process
	jr {RP}Drain

; drain; take the events reached (MODE_EVENTS); follow what was gained; until
; nothing more opens
{RP}Closure:
	call {RP}Drain
	ld a, [sRandoMode]
	bit MODE_EVENTS_F, a
	call nz, {RP}TakeEvents
	call {RP}FollowGains
	jr c, {RP}Closure
	ret

; events not held whose places are reached: gained
{RP}TakeEvents:
	ld hl, {RP}Events
.loop
	ld a, [hli]
	cp $ff
	ret z
	ld b, a                     ; atom
	ld a, [hli]
	ld c, a                     ; nodes
	ld a, b
	push hl
	call {RP}Has
	pop hl
	jr nz, .skip
	push bc
	call {RP}AnyVisited
	pop bc
	jr z, .loop
	push hl
	ld a, b
	call {RP}Gain
	pop hl
	jr .loop
.skip
	ld b, 0
	add hl, bc
	add hl, bc
	jr .loop

; hl = c node numbers: nz if any has been reached (hl moves past them)
{RP}AnyVisited:
	ld b, 0
.loop
	ld a, c
	and a
	jr z, .done
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push hl
	call {RP}Visited
	pop hl
	jr z, .no
	ld b, 1
.no
	dec c
	jr .loop
.done
	ld a, b
	and a
	ret

; the atoms gained and not followed yet (sRandoPending): from the nodes
; reached, the edges they open; the locations that need them. Carry if
; there were any.
{RP}FollowGains:
	ld e, 0
	ld d, 0
	ld a, d
	ld [sRandoGot], a
.atom
	ld hl, sRandoPending
	call {RP}Test
	jr z, .next
	call {RP}Bit
	ld a, c
	cpl
	and [hl]
	ld [hl], a
	ld a, 1
	ld [sRandoGot], a
	push de
	call {RP}FollowAtom
	pop de
.next
	inc e
	ld a, e
	cp RANDO_NUM_ATOMS
	jr nz, .atom
	ld a, [sRandoGot]
	and a
	ret z
	scf
	ret

; atom e was gained
{RP}FollowAtom:
	ld hl, {RP}AtomSrcIndex
	add hl, de
	add hl, de
	ld a, [hli]
	ld c, a
	ld a, [hli]
	ld b, a                     ; bc = its offset
	ld a, [hli]
	sub c
	ld e, a
	ld a, [hl]
	sbc b
	ld d, a
	srl d
	rr e                        ; de = how many nodes
	ld hl, {RP}AtomSrc
	add hl, bc
	ld b, d
	ld c, e
.src
	ld a, b
	or c
	jr z, .locs
	ld a, [hli]
	ld e, a
	ld a, [hli]
	ld d, a
	push hl
	push bc
	call {RP}Visited
	call nz, {RP}Process
	pop bc
	pop hl
	dec bc
	jr .src
.locs
	; the locations that need something, if one of their nodes is reached
	ld a, [sRandoMode]
	bit MODE_LOCS_F, a
	ret z
	ld hl, {RP}ReqLocs
.loc
	ld a, [hli]
	cp $ff
	ret z
	ld b, a                     ; location
	ld a, [hli]
	ld c, a                     ; nodes
	push bc
	call {RP}AnyVisited
	pop bc
	jr z, .loc
	push hl
	ld e, b
	ld d, 0
	call {RP}TakeLoc
	pop hl
	jr .loc

; ---- the sweep (Compact.sweep, sweep_from): from node de with sRandoHave,
; taking the events and locations reached, until nothing more opens

{RP}SweepFromStart:
	ld hl, sRandoStartHave
	ld de, sRandoHave
	ld bc, 4
	call CopyData
	ld hl, sRandoTaken
	ld bc, LOC_BYTES
	call {RP}ClearBC
	ld de, RANDO_START
{RP}SweepFrom:
	ld a, MODE_EVENTS | MODE_LOCS
{RP}SearchReach:
	ld [sRandoMode], a
	push de
	ld a, LOW(sRandoReach)
	ld [sRandoVisited], a
	ld a, HIGH(sRandoReach)
	ld [sRandoVisited + 1], a
	xor a
	ld [sRandoLimit], a
	ld [sRandoLimit + 1], a
	ld [sRandoDir], a
	ld hl, sRandoReach
	call {RP}ClearNodes
	ld hl, sRandoPending
	call {RP}Clear4
	call {RP}ResetStack
	call {RP}Derive
	pop de
	call {RP}Visit
	jp {RP}Closure

; carry if the game can be finished: all eight badges and the lobby reached
{RP}Beaten:
	ld a, RANDO_ATOM_BADGES8
	call {RP}Has
	jr z, .no
	ld a, LOW(sRandoReach)
	ld [sRandoVisited], a
	ld a, HIGH(sRandoReach)
	ld [sRandoVisited + 1], a
	ld hl, {RP}Goal
	ld a, [hli]
	ld c, a
	call {RP}AnyVisited
	jr z, .no
	scf
	ret
.no
	and a
	ret
