; The randomizer's world, built from the seed when a game starts (and again
; when one is loaded, if the tables in save RAM aren't that game's).
;
; A port of tools/rando/randomizer.py, step for step: the same random
; numbers in the same order, every list in the same order, so the Python
; reference can check it (tests/test_rando.py). The tables it reads are
; written by tools/rando/gen_data.py; the logic behind them is in
; tools/rando/logic.py.
;
; It works in save RAM bank 1 (sRando*, sram.asm), which stays enabled the
; whole time, and uses wOverworldMap for its search stack: there is no map
; loaded while it runs. Two banks: this one (the doors and the items) and
; RandoB (the softlock check), each with its own copy of the searches
; (core.asm) and of the tables they read.

; Build the world for the seed in sRandoTag (four bytes of seed, then
; wRandoFlags: what to shuffle). Carry set if it couldn't (it always can: 255
; tries, and the reference needs one to ten).
RandoGenerate::
	call RandoSRAM
	xor a
	ld [sRandoValid], a
	ld hl, sRandoTag
	ld de, sRandoRng
	ld bc, 4
	call CopyData
	ld hl, sRandoRng
	ld a, [hli]
	or [hl]
	inc hl
	or [hl]
	inc hl
	or [hl]
	jr nz, .seeded
	ld hl, sRandoRng            ; a zero seed would stay zero
	ld a, $91
	ld [hli], a
	ld a, $f4
	ld [hli], a
	ld a, $45
	ld [hli], a
	ld a, $25
	ld [hl], a
.seeded
	ld a, RANDO_TRIES
	ld [sRandoTries], a
.try
	ld a, [sRandoTag + 4]
	bit RANDO_DOORS_F, a
	jr z, .vanillaDoors
	call RandoShuffleDoors
	jr c, .next
	jr .doors
.vanillaDoors
	ld hl, RandoVanilla
	ld de, sRandoPartner
	ld bc, 2 * RANDO_SLOTS
	call CopyData
.doors
	; with every key item, the events (badges, Mr. Fuji, ...) must be reachable too
	call RandoClearPlace
	call RandoKeyItemsHave
	call RandoSweepFromStart
	call RandoBeaten
	jr nc, .next
	call RandoPlaceItems
	jr c, .next
	ld hl, sRandoStartHave
	call RandoClear4
	call RandoSweepFromStart
	call RandoBeaten
	jr nc, .next
	callba RandoBSoftlocks
	call RandoSRAM
	ld a, [sRandoSoftlock]
	and a
	jr nz, .next
	ld a, RANDO_DATA_VERSION
	ld [sRandoValid], a
	and a
	ret
.next
	ld hl, sRandoTries
	dec [hl]
	jr nz, .try
	scf
	ret

; the seed's hash (RandoNewGame): FNV-1a's start, then each byte xored in
; and stirred with the generator's own random numbers
RandoHashStart::
	call RandoSRAM
	ld hl, sRandoRng
	ld a, $c5
	ld [hli], a
	ld a, $9d
	ld [hli], a
	ld a, $1c
	ld [hli], a
	ld [hl], $81
	ret

; e = the byte
RandoHashByte::
	call RandoSRAM
	ld a, [sRandoRng]
	xor e
	ld [sRandoRng], a
	jp RandoRngNext

RandoHashResult::
	call RandoSRAM
	ld hl, sRandoRng
	ld de, wRandoSeed
	ld bc, 4
	jp CopyData

; save RAM bank 1, where all of this lives
RandoSRAM::
	ld a, SRAM_ENABLE
	ld [MBC1SRamEnable], a
	ld a, 1
	ld [MBC1SRamBank], a
	ret

RandoClearPlace:
	ld hl, sRandoPlace
	ld bc, RANDO_LOCS
	jp RandoClearBC

; sRandoStartHave = the progression items' atoms (every key item held)
RandoKeyItemsHave:
	ld hl, sRandoStartHave
	call RandoClear4
	ld e, RANDO_ATOM_S_S_TICKET
	ld b, RANDO_NUM_PROG
.loop
	push de
	push bc
	ld d, 0
	ld hl, sRandoStartHave
	call RandoSet
	pop bc
	pop de
	inc e
	dec b
	jr nz, .loop
	ret

; ---- random numbers: xorshift32, as Rng in randomizer.py

RandoRngNext:
	; x ^= x << 13: (x << 8) << 5
	ld hl, sRandoRng
	ld de, sRandoTmp
	xor a
	ld [de], a
	inc de
	ld bc, 3
	call CopyData
	ld b, 5
	call RandoTmpShl
	call RandoXorTmp
	; x ^= x >> 17: (x >> 16) >> 1
	ld hl, sRandoRng + 2
	ld de, sRandoTmp
	ld bc, 2
	call CopyData
	xor a
	ld [de], a
	inc de
	ld [de], a
	ld b, 1
	call RandoTmpShr
	call RandoXorTmp
	; x ^= x << 5
	ld hl, sRandoRng
	ld de, sRandoTmp
	ld bc, 4
	call CopyData
	ld b, 5
	call RandoTmpShl
	; fall through

RandoXorTmp:
	ld hl, sRandoRng
	ld de, sRandoTmp
	ld c, 4
.loop
	ld a, [de]
	xor [hl]
	ld [hli], a
	inc de
	dec c
	jr nz, .loop
	ret

RandoTmpShl:
	ld hl, sRandoTmp
	sla [hl]
	inc hl
	rl [hl]
	inc hl
	rl [hl]
	inc hl
	rl [hl]
	dec b
	jr nz, RandoTmpShl
	ret

RandoTmpShr:
	ld hl, sRandoTmp + 3
	srl [hl]
	dec hl
	rr [hl]
	dec hl
	rr [hl]
	dec hl
	rr [hl]
	dec b
	jr nz, RandoTmpShr
	ret

; bc = n (1 to $ffff) -> bc = a random number below n: the top 16 bits of
; the next number times n, top 16 bits of that
RandoRand:
	push de
	push hl
	push bc
	call RandoRngNext
	pop bc
	ld a, [sRandoRng + 2]
	ld e, a
	ld a, [sRandoRng + 3]
	ld d, a
	; (de * bc) >> 16, shifting and adding: the sum's top half in hl,
	; its bottom half in sRandoTmp
	ld hl, 0
	xor a
	ld [sRandoTmp], a
	ld [sRandoTmp + 1], a
	ld a, 16
.loop
	push af
	ld a, [sRandoTmp]
	sla a
	ld [sRandoTmp], a
	ld a, [sRandoTmp + 1]
	rla
	ld [sRandoTmp + 1], a
	ld a, l
	rla
	ld l, a
	ld a, h
	rla
	ld h, a
	sla e
	rl d
	jr nc, .skip
	ld a, [sRandoTmp]
	add c
	ld [sRandoTmp], a
	ld a, [sRandoTmp + 1]
	adc b
	ld [sRandoTmp + 1], a
	jr nc, .skip
	inc hl
.skip
	pop af
	dec a
	jr nz, .loop
	ld b, h
	ld c, l
	pop hl
	pop de
	ret

INCLUDE "engine/rando/core.asm"
INCLUDE "engine/rando/doors.asm"
INCLUDE "engine/rando/items.asm"
