; The randomizer generator's constants (engine/rando/)

DEF RANDO_WARP EQU 31          ; an edge code: leaving through a shuffled entrance
DEF RANDO_TRIES EQU 255
DEF RANDO_DATA_VERSION EQU 1   ; sRandoValid: the tables were built by this version
DEF NODE_BYTES EQU (RANDO_NODES + 7) / 8
DEF LOC_BYTES EQU (RANDO_LOCS + 7) / 8

; slot kinds
DEF KIND_OUT EQU 0             ; an outside door
DEF KIND_IN EQU 1              ; the inside of an outside door
DEF KIND_STAIRS EQU 2          ; stairs between two inside maps

; sRandoState, a byte per slot while the doors are shuffled
DEF STATE_PAIRED EQU 1
DEF STATE_OPEN EQU 2           ; unpaired, its door reached

; sRandoMode
DEF MODE_EVENTS_F EQU 0        ; a search takes the events it reaches
DEF MODE_LOCS_F EQU 1          ; and the locations
DEF MODE_EVENTS EQU 1 << MODE_EVENTS_F
DEF MODE_LOCS EQU 1 << MODE_LOCS_F

; sRandoClass, a byte per slot while the doors are shuffled
DEF CLASS_CAND EQU 1 << 7      ; one to reach, with an open door it may pair with
DEF CLASS_MORE EQU 1 << 6      ; its area has more slots to reach
DEF CLASS_NOT_STAIRS EQU 1 << 5 ; and one of them isn't stairs
DEF CLASS_KNOWN_F EQU 4        ; the two above are still right (RandoStale)

ASSERT RANDO_NUM_ATOMS <= 32   ; sRandoHave and friends are 4 bytes
ASSERT RANDO_NODES < 2048 && RANDO_SLOTS < 2048 ; RandoBit
