
;Various emulator checks to test for problems
EmulatorChecks:
	call EmuCheckWriteMode3
;	call EmuCheck_OAM_Timing
	call MemModify_Check_main
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;joenote - This function attempts to write and read values to VRAM during STAT mode 3.
;On real hardware, this is not allowed because the LCD controller is accessing VRAM.
;However, not all emulation implements this which will cause problems.
;If the values are allowed to be written and read, an error message will display.

;FAIL: VisualBoyAdvance-1.8.0-beta3, Goomba Emulator
;PASS: BGB, MGBA, Delta

EmuCheckWriteMode3:
	ld b, 3	;give it some extra chances to pass
.test
	ld hl, $8000
	ld de, $BEEF
	call .waitMode3
	ld a, $BE
	cp d
	jr nz, .pass
	ld a, $EF
	cp e
	jr nz, .pass
.fail
	dec b
	jr nz, .test
	ld de, EmuFailText1
	coord hl, $00, $09
	call PlaceString
	ld a, 1
	and a
	ret
.pass
	xor a
	ret
.waitMode3
	di
.waitMode3_loop
	ldh a, [rSTAT]		;read from stat register to get the mode
	and %11				;4 cycles
	cp 3				;4 cycles
	jr nz, .waitMode3_loop	;6 cycles to pass or 10 to loop
	ld a, d
	ld [hli], a
	ld a, e
	ld [hld], a
	ld a, [hli]
	ld d, a
	ld a, [hld]
	ld e, a
	ei
	ret
EmuFailText1:
	db "Emulator ERROR! Mode-3 access violation.@"
	
	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;joenote - This function checks how long it takes to go from the LCD turning on to the first OAM interrupt.

;FAIL: VisualBoyAdvance-M-2.1.11, VisualBoyAdvance-1.8.0-beta3, various FPGA clone hardware (FPGBC, Analogue Pocket, etc)
;PASS: BGB, MGBA, Delta

EmuCheck_OAM_Timing:
	di
	call DisableLCD
	
	ld a, [rSTAT]
	push af
	ld a, %00100000	;enable Mode 2 OAM interrupt for LCDC
	ldh [rSTAT], a
	
	ld a, [rIE]
	push af
	ld a, %00000010	;enable LCDC STAT control interrupts
	ldh [rIE], a
	
	xor a
	ldh [rIF], a

	ei
	
	;Enable the LCD
	ld a, [rLCDC]
	set rLCDC_ENABLE, a
	ld [rLCDC], a
	
	xor a
REPT 200
	inc a
ENDR	
	
	di
	pop af
	ldh [rIE], a
	pop af
	ldh [rSTAT], a
	ei
	
	ld a, [$FFF5]
	cp 111
	ret z	;pass
	ld de, EmuFailText2	;fail
	coord hl, $00, $0B
	call PlaceString
	ld a, 1
	and a
	ret
EmuFailText2:
	db "Emulator ERROR! Incorrect OAMint timing.@"
	
	
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;Game Boy CPU Memory Modification Access Timing Test
;Adapted from the source code written by Shay Green <gblargg@gmail.com>

;This checks multiple memory modification opcodes to make sure they execute within the correct amount of time

;FAIL: VisualBoyAdvance-M-2.1.11, VisualBoyAdvance-1.8.0-beta3, Goomba Emulator
;PASS: BGB, MGBA, Delta, gambatte-speedrun-r717-psr

MemModifyInstructions:
     ; last values are read/write times
     db $35,$00,$00,2,3 ; DEC  (HL)
     db $34,$00,$00,2,3 ; INC  (HL)
     db $CB,$06,$00,3,4 ; RLC  (HL)
     db $CB,$0E,$00,3,4 ; RRC  (HL)
     db $CB,$16,$00,3,4 ; RL   (HL)
     db $CB,$1E,$00,3,4 ; RR   (HL)
     db $CB,$26,$00,3,4 ; SLA  (HL)
     db $CB,$2E,$00,3,4 ; SRA  (HL)
     db $CB,$36,$00,3,4 ; SWAP (HL)
     db $CB,$3E,$00,3,4 ; SRL  (HL)
     db $CB,$86,$00,3,4 ; RES  0,(HL)
     db $CB,$8E,$00,3,4 ; RES  1,(HL)
     db $CB,$96,$00,3,4 ; RES  2,(HL)
     db $CB,$9E,$00,3,4 ; RES  3,(HL)
     db $CB,$A6,$00,3,4 ; RES  4,(HL)
     db $CB,$AE,$00,3,4 ; RES  5,(HL)
     db $CB,$B6,$00,3,4 ; RES  6,(HL)
     db $CB,$BE,$00,3,4 ; RES  7,(HL)
     db $CB,$C6,$00,3,4 ; SET  0,(HL)
     db $CB,$CE,$00,3,4 ; SET  1,(HL)
     db $CB,$D6,$00,3,4 ; SET  2,(HL)
     db $CB,$DE,$00,3,4 ; SET  3,(HL)
     db $CB,$E6,$00,3,4 ; SET  4,(HL)
     db $CB,$EE,$00,3,4 ; SET  5,(HL)
     db $CB,$F6,$00,3,4 ; SET  6,(HL)
     db $CB,$FE,$00,3,4 ; SET  7,(HL)
	 db $FF

MemModify_Check_main:
	 ld a, [rTAC]
	 push af	;preserve timer control settings
     call init_tima_64
     call Copy_MemTest_to_WRAM
     
     ; Test instructions
     ld   hl,MemModifyInstructions
.loop
     call test_instr
	 jr nz, .fail
     inc  hl
     ld a, [hl]
	 cp $FF
     jr   nz, .loop
.pass
	 pop af	;get back timer control setting
     ld [rTAC], a
	xor a
	ret
.fail
	 pop af	;get back timer control setting
     ld [rTAC], a
	ld de, EmuFailText3	;fail
	coord hl, $00, $0B
	call PlaceString
	ld a, 1
	and a
	ret
EmuFailText3:
	db "Emulator ERROR! Wrong Mem Access timing.@"


Copy_MemTest_to_WRAM:
	push hl
	push bc
	push de
	
	ld hl, time_access_MemTest_START
	ld de, wOverworldMap	;going to copy to here because the overworld should not be loaded yet so it's not being used
	ld bc, (time_access_MemTest_END - time_access_MemTest_START)
	call _CopyData
	
	pop de
	pop bc
	pop hl
	ret

test_instr:		;on return, nz = fail and z = pass
     call time_instr
     ld   a,d
     cp   [hl]
     inc  hl
     jr nz, .retry
     ld   a,e
     cp   [hl]
     ret z
.retry
	dec hl
	dec hl
	dec hl
	dec hl
	 call time_instr
     ld   a,d
     cp   [hl]
     inc  hl
     ret nz
     ld   a,e
     cp   [hl]
    ret

; Times instruction
; HL -> 3-byte instruction
; HL <- HL + 3
time_instr:
     ; Copy instr
     ld   a,[hli]
     ld   [wOverworldMap + (time_access_MemTest_instr - time_access_MemTest_START) + 0],a
     ld   a,[hli]
     ld   [wOverworldMap + (time_access_MemTest_instr - time_access_MemTest_START) + 1],a
     ld   a,[hli]
     ld   [wOverworldMap + (time_access_MemTest_instr - time_access_MemTest_START) + 2],a
     push hl
     
     ; Find result when access doesn't occur
     ld   b,0
     call wOverworldMap
     
     ; Find first access
     call find_next_access
     ld   d,b
     
     ; Find second access
     call find_next_access
     ld   e,b
     
     pop  hl
     ret


; A -> current timer result
; B -> starting clock
; B <- clock next access occurs on
; A <- new timer result
find_next_access:
     ld   c,a
.loop
     call wOverworldMap
     cp   c
     ret  nz
     inc  b
     ld   a,b
     cp   10
     jr   c,.loop
     
     ; Couldn't find time, so return 0/0
     ld   a,c
     ld   b,0
     ld   d,b
     ret


; Initializes timer for use by sync_tima_64
init_tima_64:
	 ld a, 0
	 ld [rTMA], a
     ld a, %111
     ld [rTAC], a
     ret

; Synchronizes to timer
; Preserved: AF, BC, DE, HL
sync_tima_64:
     push af
     push hl
     
     ; Coarse
     ld   hl, rTIMA
     ld   a,0
     ld   [hl],a
.loop
     or   [hl]
     jr   z, .loop
     
     ; Fine
.loop2
     push af
	 ld a, 24
	 call delay_a_20_cycles
	 pop af
     
	 xor  a
     ld   [hl],a
     or   [hl]
	 
     jr .next
.next
     nop
	 jr   z, .loop2
     
     pop  hl
     pop  af
     ret


; Delays A cycles + overhead
; Preserved: BC, DE, HL
; Time: A+20 cycles (including CALL)
delay_a_20_cycles:
.loop
     sub  5    		; 2
     jr   nc, .loop ;3/2 do multiples of 5
     rra       		; 1
     jr   nc, .next	;3/2 bit 0
.next    
	 adc  1    		; 2
     ret  nc   		;5/2 -1: 0 cycles
     ret  z    		;5/2  0: 2 cycles
     nop       		; 1   1: 4 cycles
     ret       		; 4 (thanks to dclxvi for original algorithm)

	 
; Tests for access
; B -> which cycle to test
; A <- timer value after test
time_access_MemTest_START:
     call sync_tima_64
     ld   hl,rTIMA
     ld   [hl],$7F
     ld   a,17
     sub  b
     call delay_a_20_cycles
     xor  a    ; clear flags
time_access_MemTest_instr:
     nop
     nop
     nop

     push af
	 ld a, 3
	 call delay_a_20_cycles
	 pop af

     ld   a,[rTIMA]
     ret
time_access_MemTest_END:



	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	