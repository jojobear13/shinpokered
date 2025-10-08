w2MapViewHLPointer			EQU $d0fa	;wram bank 2 backup. 2 bytes
w2CurMap					EQU $d0fc
w2CurMapTileset				EQU $d0fd
w2MapViewVRAMPointer		EQU $d0fe	;wram bank 2 backup. 2 bytes
w2BGMapAttributes 			EQU $d100 	;In wram bank 2 (GBC only). This is 1024 bytes (32 by 32).
w2GBCFullPalBuffer			EQU $d500	;secondary buffer that is 128 bytes

END_OF_OVERWORLD_TILES 		EQU $60		;This is 1 plus the value of the last overworld tile.

MACRO GBCEnh_Dark1
		dw (11 << 10 | 5 << 5 | 7)
ENDM
MACRO GBCEnh_Dark2
		dw (6 << 10 | 3 << 5 | 3)
ENDM

MACRO GBCEnh_Black
		dw (3 << 10 | 3 << 5 | 3)
ENDM
MACRO GBCEnh_White
		dw (31 << 10 | 31 << 5 | 31)
ENDM

const_value = 0

	const PAL_ENH_OVW_RED     	; $00
	const PAL_ENH_OVW_PINK  	; $01
	const PAL_ENH_OVW_PURPLE 	; $02
	const PAL_ENH_OVW_GRAY   	; $03
	const PAL_ENH_OVW_GREEN    	; $04
	const PAL_ENH_OVW_YELLOW  	; $05
	const PAL_ENH_OVW_BROWN    	; $06
	const PAL_ENH_OVW_BLUE  	; $07

GBCEnhancedOverworldPalettes:	
	; PAL_ENH_OVW_RED     	; $00
	GBCEnh_White
	RGB 31, 10,  0
	RGB 21,  0,  0
	GBCEnh_Black
	
	; PAL_ENH_OVW_PINK  	; $01
	GBCEnh_White
	RGB 31, 15, 18
	RGB 31,  0,  6
	GBCEnh_Black

	; PAL_ENH_OVW_PURPLE 	; $02
	GBCEnh_White
	RGB 25, 15, 31
	RGB 19,  0, 22
	GBCEnh_Black

	; PAL_ENH_OVW_GRAY   	; $03
	GBCEnh_White
	RGB 20, 23, 10
	RGB 11, 11,  5
	GBCEnh_Black

	; PAL_ENH_OVW_GREEN    	; $04
	GBCEnh_White
	RGB 17, 31, 11
	RGB  1, 22,  6
	GBCEnh_Black
	
	; PAL_ENH_OVW_YELLOW  	; $05
	GBCEnh_White
	RGB 31, 31,  0
	RGB 28, 14,  0
	GBCEnh_Black

	; PAL_ENH_OVW_BROWN    	; $06
	GBCEnh_White
	RGB 22, 16,  5
	RGB 15,  7,  3
	GBCEnh_Black

	; PAL_ENH_OVW_BLUE  	; $07
	GBCEnh_White
	RGB 12, 14, 31
	RGB  0,  1, 25
	GBCEnh_Black


	
GBCEnhancedOverworldPalettes_ColdCavern:	;just used for seafoam islands for aesthetic
	; PAL_ENH_OVW_RED     	; $00
	GBCEnh_White
	RGB 31, 10,  0
	RGB 21,  0,  0
	GBCEnh_Black
	
	; PAL_ENH_OVW_PINK  	; $01
	GBCEnh_White
	RGB 31, 15, 18
	RGB 31,  0,  6
	GBCEnh_Black

	; PAL_ENH_OVW_PURPLE 	; $02
	GBCEnh_White
	RGB 25, 15, 31
	RGB 19,  0, 22
	GBCEnh_Black

	; PAL_ENH_OVW_GRAY   	; $03
	GBCEnh_White
	RGB $12, $12, $18
	RGB $A, $A,  $F
	GBCEnh_Black

	; PAL_ENH_OVW_GREEN    	; $04
	GBCEnh_White
	RGB 17, 31, 11
	RGB  1, 22,  6
	GBCEnh_Black
	
	; PAL_ENH_OVW_YELLOW  	; $05
	GBCEnh_White
	RGB 31, 31,  0
	RGB 28, 14,  0
	GBCEnh_Black

	; PAL_ENH_OVW_BROWN    	; $06
	GBCEnh_White
	RGB $10, $5, $16
	RGB $7, $3,  $F
	GBCEnh_Black

	; PAL_ENH_OVW_BLUE  	; $07
	GBCEnh_White
	RGB 12, 14, 31
	RGB  0,  1, 25
	GBCEnh_Black


	
GBCEnhancedOverworldPalettes_DarkCavern:	;palette set used for darkened areas like Rock Tunnel

	; PAL_ENH_OVW_RED     	; $00
	GBCEnh_White
	GBCEnh_Dark1
	GBCEnh_Dark1
	GBCEnh_Dark2
	
	; PAL_ENH_OVW_PINK  	; $01
	GBCEnh_White
	GBCEnh_Dark1
	GBCEnh_Dark1
	GBCEnh_Dark2

	; PAL_ENH_OVW_PURPLE 	; $02
	GBCEnh_White
	GBCEnh_Dark1
	GBCEnh_Dark1
	GBCEnh_Dark2

	; PAL_ENH_OVW_GRAY   	; $03
	GBCEnh_White
	GBCEnh_Dark1
	GBCEnh_Dark1
	GBCEnh_Dark2

	; PAL_ENH_OVW_GREEN    	; $04
	GBCEnh_White
	GBCEnh_Dark1
	GBCEnh_Dark1
	GBCEnh_Dark2
	
	; PAL_ENH_OVW_YELLOW  	; $05
	GBCEnh_White
	GBCEnh_Dark1
	GBCEnh_Dark1
	GBCEnh_Dark2

	; PAL_ENH_OVW_BROWN    	; $06
	GBCEnh_White
	GBCEnh_Dark1
	GBCEnh_Dark1
	GBCEnh_Dark2

	; PAL_ENH_OVW_BLUE  	; $07
	GBCEnh_White
	GBCEnh_Dark1
	GBCEnh_Dark1
	GBCEnh_Dark2


	
OverworldTilePalPointers:
	dw PalSettings_OVERWORLD    ; 0
	dw PalSettings_REDS_HOUSE_1 ; 1
	dw PalSettings_MART         ; 2
	dw PalSettings_FOREST       ; 3
	dw PalSettings_REDS_HOUSE_2 ; 4
	dw PalSettings_DOJO         ; 5
	dw PalSettings_POKECENTER   ; 6
	dw PalSettings_GYM          ; 7
	dw PalSettings_HOUSE        ; 8
	dw PalSettings_FOREST_GATE  ; 9
	dw PalSettings_MUSEUM       ; 10
	dw PalSettings_UNDERGROUND  ; 11
	dw PalSettings_GATE         ; 12
	dw PalSettings_SHIP         ; 13
	dw PalSettings_SHIP_PORT    ; 14
	dw PalSettings_CEMETERY     ; 15
	dw PalSettings_INTERIOR     ; 16
	dw PalSettings_CAVERN       ; 17
	dw PalSettings_LOBBY        ; 18
	dw PalSettings_MANSION      ; 19
	dw PalSettings_LAB          ; 20
	dw PalSettings_CLUB         ; 21
	dw PalSettings_FACILITY     ; 22
	dw PalSettings_PLATEAU      ; 23

;Assign a color register to be used for each tile in every tileset.
;A value of 8 is a "wild card" to set the color register based on the current town.
PalSettings_OVERWORLD:   	; 0		- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	6,	6,	1,	6,	8,	8,	8,	8,	8,	3,	6,	6,	3,	6,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	6,	8,	6,	7,	8,	8,	8,	8,	8,	3,	6,	6,	3,	6,	3;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	3,	3,	3,	3,	6,	8,	8,	6,	8,	8,	3,	3,	4,	4,	4,	3;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	4,	6,	6,	6,	6,	6,	6,	6,	8,	4,	3,	3,	6,	4,	4,	3;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	4,	4,	0,	0,	7,	7,	6,	6,	6,	6,	3,	3,	8,	8,	3,	3;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	4,	4,	4,	8,	6,	6,	6,	6,	6,	6,	8,	0,	8,	8,	3,	3;
PalSettings_REDS_HOUSE_1:	; 1		-done
PalSettings_REDS_HOUSE_2:	; 4
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	6,	3,	3,	3,	2,	3,	7,	7,	4,	4,	6,	6,	6,	6,	3,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	3,	3,	3,	2,	3,	7,	7,	6,	6,	6,	6,	6,	6,	3,	3;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	3,	3,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	3,	3,	6;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	6,	6,	3,	3,	4,	4,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	3,	3,	3;
PalSettings_FOREST:      	; 3		- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	4,	3,	6,	6,	4,	4,	4,	4,	6,	6,	3,	3,	6,	6,	6,	6;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	0,	0,	6,	6,	7,	4,	4,	4,	6,	6,	3,	3,	6,	6,	6,	6;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	4,	6,	6,	4,	4,	4,	4,	4,	6,	6,	6,	6,	6,	6,	6,	6;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	4,	6,	6,	3,	4,	6,	6,	3,	6,	4,	6,	6,	6,	6,	6,	6;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	3,	3,	3,	3,	6,	6,	6,	6,	6,	6,	6,	3,	3,	6,	6,	6;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	6,	6,	6,	6,	4,	4,	4,	4,	6,	6,	6,	6,	6,	6,	4,	4;
PalSettings_MART:        	; 2
PalSettings_POKECENTER:  	; 6		- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	4,	1,	1,	6,	6,	3,	3,	6,	3,	6,	4,	2,	3,	6,	6;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	6,	4,	1,	1,	6,	6,	3,	6,	5,	5,	3,	4,	2,	6,	6,	6;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	4,	4,	6,	6,	0,	0,	0,	0,	6,	6,	0,	0,	7,	7,	7,	7;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	4,	4,	6,	6,	0,	0,	3,	0,	6,	3,	6,	6,	3,	0,	7,	7;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	3,	3,	3,	3,	3,	3,	3,	3,	3,	3,	6,	6,	6,	6,	5,	5;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	3,	3,	3,	3,	3,	3,	3,	3,	3,	6,	0,	0,	3,	3,	3,	3;
PalSettings_DOJO:        	; 5
PalSettings_GYM:          	; 7		- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	6,	6,	1,	6,	7,	5,	6,	6,	7,	7,	6,	6,	3,	3,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	7,	6,	6,	6,	7,	6,	5,	6,	6,	7,	7,	6,	6,	3,	3,	6;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	6,	6,	3,	3,	3,	3,	3,	3,	0,	3,	3,	4,	4,	4,	4,	4;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	6,	6,	3,	3,	7,	3,	3,	3,	6,	3,	7,	3,	2,	2,	7,	6;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	4,	4,	7,	7,	7,	7,	7,	7,	3,	3,	3,	3,	2,	2,	3,	3;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	4,	4,	7,	7,	7,	3,	7,	7,	6,	6,	6,	3,	3,	3,	3,	3;
PalSettings_HOUSE:        	; 8		- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	6,	3,	3,	3,	1,	3,	7,	7,	4,	4,	4,	4,	4,	4,	6,	6;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	3,	3,	3,	1,	3,	7,	7,	6,	6,	6,	6,	3,	3,	6,	6;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	3,	3,	2,	6,	6,	6,	6,	6,	6,	6,	4,	4,	6,	6,	6,	6;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	6,	6,	3,	3,	3,	3,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	3,	3;
PalSettings_FOREST_GATE:  	; 9
PalSettings_MUSEUM:       	; 10
PalSettings_GATE:         	; 12	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	6,	4,	3,	3,	7,	4,	4,	4,	4,	4,	3,	3,	3,	3,	3,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	3,	3,	3,	7,	4,	4,	4,	4,	7,	3,	3,	3,	3,	3,	3;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	3,	3,	3,	3,	3,	6,	6,	7,	7,	6,	6,	6,	7,	7,	7,	4;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	7,	7,	6,	6,	3,	6,	6,	7,	7,	3,	7,	6,	7,	7,	7,	3;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	3,	3,	3,	3,	3,	3,	7,	7,	1,	3,	1,	3,	3,	3,	2,	2;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	3,	3,	3,	3,	3,	3,	3,	3,	3,	3,	3,	3,	3,	3,	7,	3;
PalSettings_UNDERGROUND:  	; 11	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	2,	7,	1,	1,	7,	7,	7,	7,	7,	7,	1,	1,	0,	0,	0;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	7,	7,	1,	1,	1,	7,	7,	1,	0,	0,	0,	0,	0,	0,	0;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
PalSettings_SHIP:         	; 13	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	3,	7,	7,	6,	3,	3,	7,	7,	3,	3,	3,	3,	7,	0,	0;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	0,	7,	7,	7,	3,	3,	7,	7,	3,	3,	3,	3,	7,	0,	0;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	3,	3,	0,	6,	0,	3,	3,	3,	3,	3,	3,	0,	3,	3,	5,	5;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	7,	7,	0,	3,	0,	3,	0,	3,	3,	3,	3,	3,	3,	3,	5,	5;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	3,	3,	7,	7,	3,	3,	3,	3,	7,	7,	6,	3,	3,	3,	3,	3;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	3,	3,	3,	3,	7,	7,	3,	3,	7,	7,	3,	3,	3,	3,	3,	3;
PalSettings_SHIP_PORT:    	; 14	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	7,	0,	7,	7,	7,	7,	7,	7,	7,	7,	6,	7,	7,	7,	7,	7;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	7,	3,	6,	7,	7,	7,	7,	7,	7,	7,	6,	6,	6,	7,	7,	7;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	7,	7,	7,	7,	7,	7,	7,	7,	6,	6,	6,	6,	6,	7,	7,	7;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	0,	7,	7,	7,	7,	7,	0,	0,	6,	6,	7,	7,	7,	7,	7,	7;
PalSettings_CEMETERY:     	; 15	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	2,	6,	3,	3,	3,	3,	6,	6,	3,	3,	3,	3,	6,	6,	4;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	4,	3,	6,	3,	3,	3,	3,	6,	6,	3,	3,	3,	3,	6,	6,	4;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	4,	4,	7,	4,	3,	3,	6,	2,	6,	6,	2,	2,	2,	2,	2,	2;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	4,	4,	4,	4,	3,	6,	6,	2,	6,	6,	2,	2,	2,	3,	3,	2;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	3,	3,	4,	3,	6,	6,	6,	3,	6,	6,	3,	3,	3,	3,	7,	6;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	3,	3,	4,	6,	6,	2,	3,	4,	3,	4,	3,	3,	0,	0,	0,	0;
PalSettings_INTERIOR:     	; 16	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	3,	3,	7,	7,	3,	3,	3,	3,	3,	3,	3,	3,	3,	3,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	6,	6,	2,	2,	3,	3,	3,	3,	3,	3,	3,	3,	3,	3,	7;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	7,	6,	6,	2,	2,	7,	7,	3,	3,	3,	3,	3,	3,	6,	6,	3;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	7,	2,	2,	2,	3,	7,	7,	3,	3,	3,	3,	3,	3,	3,	3,	6;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	6,	2,	2,	2,	2,	7,	4,	4,	6,	6,	6,	6,	6,	6,	6,	6;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	3,	6,	6,	1,	1,	1,	1,	6,	6,	6,	6,	6,	6,	3,	3,	3;
PalSettings_CAVERN:       	; 17	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	3,	6,	6,	3,	6,	3,	3,	3,	3,	3,	3,	3,	3,	3,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	6,	6,	6,	6,	7,	6,	6,	6,	3,	3,	3,	3,	3,	3,	3,	3;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	3,	5,	3,	3,	3,	6,	6,	3,	6,	6,	6,	3,	3,	3,	3,	3;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	3,	6,	7,	7,	7,	7,	7,	7,	7,	7,	7,	7,	3,	6,	6,	6;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	6,	6,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
PalSettings_LOBBY:        	; 18	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	4,	3,	3,	0,	7,	4,	2,	2,	7,	3,	3,	3,	3,	3,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	7,	3,	3,	0,	7,	4,	2,	2,	7,	3,	3,	3,	3,	3,	3;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	2,	4,	7,	7,	7,	7,	7,	7,	5,	7,	3,	3,	3,	3,	3,	3;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	7,	7,	7,	7,	7,	7,	7,	2,	5,	7,	3,	3,	3,	3,	7,	4;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	3,	3,	3,	3,	7,	3,	7,	7,	4,	4,	3,	7,	7,	7,	7,	7;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	3,	3,	3,	3,	7,	7,	3,	3,	4,	4,	3,	2,	7,	7,	3,	0;
PalSettings_MANSION:      	; 19	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	3,	7,	7,	4,	7,	1,	1,	4,	4,	3,	3,	3,	3,	3,	1;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	7,	7,	7,	4,	5,	1,	1,	6,	6,	3,	3,	3,	3,	1,	1;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	7,	1,	6,	6,	3,	3,	6,	6,	5,	6,	1,	1,	3,	6,	6,	6;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	1,	1,	6,	6,	3,	3,	6,	6,	5,	6,	6,	6,	6,	3,	3,	6;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	3,	3,	3,	3,	4,	4,	6,	6,	1,	1,	1,	1,	3,	3,	1,	3;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	6,	1,	1,	1,	1,	7,	7,	5,	1,	1,	1,	1,	1,	1,	3,	0;
PalSettings_LAB:          	; 20	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	1,	3,	3,	3,	3,	6,	6,	6,	6,	3,	3,	3,	3,	3,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	6,	6,	3,	3,	3,	3,	6,	6,	3,	3,	3,	3,	7,	7,	3,	3;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	6,	6,	6,	6,	7,	7,	3,	7,	6,	6,	6,	6,	4,	4,	6,	6;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	6,	6,	6,	6,	5,	5,	3,	7,	3,	3,	6,	7,	4,	4,	6,	6;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	6,	6,	6,	6,	6,	3,	3,	7,	6,	6,	3,	3,	5,	5,	7,	3;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	6,	6,	6,	6,	6,	3,	3,	7,	7,	7,	3,	3,	3,	0,	0,	0;
PalSettings_CLUB:         	; 21	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	0,	6,	6,	6,	0,	1,	6,	1,	1,	0,	4,	0,	0,	7,	0,	3;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	1,	6,	6,	6,	0,	7,	7,	2,	2,	3,	4,	0,	0,	7,	3,	3;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	7,	7,	7,	7,	7,	7,	7,	7,	0,	0,	7,	7,	0,	0,	0,	0;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	1,	1,	1,	1,	5,	5,	1,	3,	3,	3,	3,	3,	3,	3,	3,	4;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	3,	3,	4,	4,	4,	4,	4,	3,	3,	3,	3,	3,	0,	0,	0,	0;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
PalSettings_FACILITY:     	; 22	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	3,	6,	3,	3,	4,	4,	6,	3,	6,	6,	3,	3,	6,	6,	6;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	3,	3,	6,	3,	7,	4,	4,	6,	3,	6,	6,	3,	3,	6,	6,	6;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	2,	2,	1,	5,	3,	3,	6,	2,	6,	6,	7,	7,	7,	7,	7,	2;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	2,	2,	1,	3,	3,	6,	6,	2,	6,	6,	7,	7,	7,	3,	3,	2;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	3,	3,	1,	3,	6,	6,	5,	7,	5,	5,	3,	3,	3,	3,	3,	6;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	3,	3,	1,	6,	6,	3,	3,	7,	3,	7,	3,	3,	7,	7,	3,	7;
PalSettings_PLATEAU:      	; 23	- done
;	00	01	02	03	04	05	06	07	08	09	0A	0B	0C	0D	0E	0F
db	3,	6,	6,	7,	7,	3,	3,	4,	4,	6,	6,	6,	6,	7,	7,	7;
;	10	11	12	13	14	15	16	17	18	19	1A	1B	1C	1D	1E	1F
db	7,	6,	7,	0,	7,	3,	3,	4,	4,	6,	6,	6,	6,	6,	6,	6;
;	20	21	22	23	24	25	26	27	28	29	2A	2B	2C	2D	2E	2F
db	7,	7,	6,	3,	6,	7,	7,	6,	7,	7,	6,	6,	4,	4,	3,	3;
;	30	31	32	33	34	35	36	37	38	39	3A	3B	3C	3D	3E	3F
db	3,	3,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	6,	8,	8,	8;
;	40	41	42	43	44	45	46	47	48	49	4A	4B	4C	4D	4E	4F
db	8,	8,	8,	8,	8,	4,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;
;	50	51	52	53	54	55	56	57	58	59	5A	5B	5C	5D	5E	5F
db	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0;



PalSettings_TownSpecialPal:
	db	PAL_ENH_OVW_PURPLE	;	PALLET_TOWN,		; $00
	db	PAL_ENH_OVW_GREEN	;	VIRIDIAN_CITY,		; $01
	db	PAL_ENH_OVW_GRAY	;	PEWTER_CITY,		; $02
	db	PAL_ENH_OVW_BLUE	;	CERULEAN_CITY,		; $03
	db	PAL_ENH_OVW_PURPLE	;	LAVENDER_TOWN,		; $04
	db	PAL_ENH_OVW_RED		;	VERMILION_CITY,		; $05
	db	PAL_ENH_OVW_GREEN	;	CELADON_CITY,		; $06
	db	PAL_ENH_OVW_PINK	;	FUCHSIA_CITY,		; $07
	db	PAL_ENH_OVW_RED		;	CINNABAR_ISLAND,	; $08
	db	PAL_ENH_OVW_BLUE	;	INDIGO_PLATEAU,		; $09
	db	PAL_ENH_OVW_YELLOW	;	SAFFRON_CITY,		; $0A

	

;This copies everything in wTileMap to w2BGMapAttributes in wram bank 2
;It also converts all the tile values to BG Map Attribute palettes
;Clobbers BC, HL, and DE
;This function is in the same spirit as LoadCurrentMapView, but for GBC color pals instead of tiles
MakeOverworldBGMapAttributes:	
;only do the attributes when walking around, not during a menu or text since that will mess up the settings
	ld a, [H_AUTOBGTRANSFERENABLED]
	and a
	ret nz
.endAutoBGTransferFlag
;only for GBC and only if option is active
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	bit 7, a
	ret z
	

	ld a, [wMapViewVRAMPointer]
	ld b, a
	ld a, [wMapViewVRAMPointer+1]
	ld c, a
.jump_in	;label used for being called from other functions
	ld a, [wCurMap]
	ld d, a
	ld a, [wCurMapTileset]
	ld e, a
	
	di	;disable the interrupts while messing around in the other wram bank since a bunch of stuff runs during vblank

	ld hl, rSVBK
	set 1, [hl]		;switch over to wram bank 2 (covers everything from address D700 to DFFF)
	
	ld a, b
	ld [w2MapViewVRAMPointer], a
	ld a, c
	ld [w2MapViewVRAMPointer+1], a
	ld a, d
	ld [w2CurMap], a
	ld a, e
	ld [w2CurMapTileset], a
	
	ld hl, hFlags_0xFFF6
	bit 3, [hl]
	jp nz, MakeOverworldBGMapAttributes_RolColUpdate	

;back up the stack pointer
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;copy wTileMap to w2BGMapAttributes
	ld hl, wTileMap
	ld sp, hl
	ld hl, w2BGMapAttributes - vBGMap0
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	ld b, a
	add hl, bc
	

	ld b, SCREEN_HEIGHT 	;tile map height
.w2ramCopyLoop_Y
	ld a, h
	ld [w2MapViewHLPointer], a
	ld a, l
	ld [w2MapViewHLPointer+1], a
	ld c, SCREEN_WIDTH	;tile map width
.w2ramCopyLoop_X
	pop de
	ld a, e
	ld [hli], a
	ld a, d
	ld [hl], a
	ld a, l
	and $1f
	cp $1f
	jr c, .w2ramCopyLoop_X_nowrap
	ld a, l
	sub BG_MAP_WIDTH
	ld l, a
	ld a, h
	sbc 0
	ld h, a
.w2ramCopyLoop_X_nowrap	
	inc hl
	dec c
	dec c
	jr nz, .w2ramCopyLoop_X

	ld a, [w2MapViewHLPointer+1]
	add BG_MAP_WIDTH
	ld l, a
	ld a, [w2MapViewHLPointer]
	adc 0
	cp $d5
	jr c, .w2ramCopyLoop_Y_nowrap
	sub 4
.w2ramCopyLoop_Y_nowrap
	ld h, a
	dec b
	jr nz, .w2ramCopyLoop_Y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;restore the stack pointer
	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl

;get the current map tileset
;based on the tileset, point HL to the correct list of BG map attributes for its tiles
	ld a, [w2CurMapTileset]
	ld c, a
	ld b, 0
	ld hl, OverworldTilePalPointers	
	add hl, bc
	add hl, bc
	ld a, [hli]   
	ld b, a       
	ld a, [hl]    
	ld h, a
	ld a, b
	ld l, a

;backup this HL pointer
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP+1], a

;now point DE to w2BGMapAttributes
	ld hl, w2BGMapAttributes - vBGMap0
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	ld b, a
	add hl, bc
	ld d, h
	ld e, l
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
;Convert the tile values in w2BGMapAttributes to color attribute settings
	ld b, SCREEN_HEIGHT 	;tile map height
.w2ramCopyLoop2_Y

	ld a, d
	ld [w2MapViewHLPointer], a
	ld a, e
	ld [w2MapViewHLPointer+1], a
	ld c, SCREEN_WIDTH	;tile map width
.w2ramCopyLoop2_X
	;get the tileset address pointer
	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP+1]
	ld l, a

	;point to the correct tile
	ld a, [de]

;error trap
	cp END_OF_OVERWORLD_TILES
	ld a, PAL_ENH_OVW_GRAY
	jr nc, .copyColorAttribute
	ld a, [de]
	
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
	
	;get the correct color
	ld a, [hl]
	cp 8
	jr c, .copyColorAttribute
	call .townColor
.copyColorAttribute	
	ld [de], a
	ld a, e
	and $1f
	cp $1f
	jr c, .w2ramCopyLoop2_X_nowrap
	ld a, e
	sub BG_MAP_WIDTH
	ld e, a
	ld a, d
	sbc 0
	ld d, a
.w2ramCopyLoop2_X_nowrap	
	inc de
	dec c
	jr nz, .w2ramCopyLoop2_X

	ld a, [w2MapViewHLPointer+1]
	add BG_MAP_WIDTH
	ld e, a
	ld a, [w2MapViewHLPointer]
	adc 0
	cp $d5
	jr c, .w2ramCopyLoop2_Y_nowrap
	sub 4
.w2ramCopyLoop2_Y_nowrap	
	ld d, a
	dec b
	jr nz, .w2ramCopyLoop2_Y
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.return
;restore the original wram bank and return
	ld hl, rSVBK
	res 1, [hl]
	ei	;re-enable interrupts
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.townColor
	push hl
	push bc
	ld a, [w2CurMap]
	ld c, a
	ld b, 0
	ld hl, PalSettings_TownSpecialPal	
	add hl, bc
	ld a, c
	cp SAFFRON_CITY+1	;set flags
	ld a, [hl]	;get pal value into A
	pop bc
	pop hl
	
	ret c
	ld a, PAL_ENH_OVW_BROWN	;for routes and other such maps
	ret
	
	
;same as above but just for updating the row/column when the player walks
MakeOverworldBGMapAttributes_RolColUpdate:	
	call .getTileset
	ld a, [wSpriteStateData1 + 3]
	cp $01
	jr z, .south
	cp $ff
	jr z, .north
	ld a, [wSpriteStateData1 + 5]
	cp $01
	jr z, .east
	cp $ff
	jr z, .west
	jp MakeOverworldBGMapAttributes.return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.south
	ld hl, wTileMap + (SCREEN_WIDTH*SCREEN_HEIGHT - 2*SCREEN_WIDTH)
	
	;vram should be the $9800 table right now
	;get the pointer offset into BC
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	sub $98
	ld b, a
	
	;point to w2BGMapAttributes + offset
	ld de, w2BGMapAttributes
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	ld d, a
	
	;point to w2BGMapAttributes + offset + offset to the last two rows of the map view
	ld bc, BG_MAP_WIDTH*(SCREEN_HEIGHT-2)
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	cp $d5
	jr c, .south_no_wrap
	sub 4
.south_no_wrap
	ld d, a
	
	call .copyrow
	call .copyrow
	jp MakeOverworldBGMapAttributes.return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.north
	ld hl, wTileMap
	
	;vram should be the $9800 table right now
	;get the pointer offset into BC
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	sub $98
	ld b, a
	
	;point to w2BGMapAttributes + offset
	ld de, w2BGMapAttributes
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	ld d, a
	
	call .copyrow
	call .copyrow
	jp MakeOverworldBGMapAttributes.return	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.east
	ld hl, wTileMap + (SCREEN_WIDTH - 2)
	
	;vram should be the $9800 table right now
	;get the pointer offset into BC
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	sub $98
	ld b, a
	
	;point to w2BGMapAttributes + offset
	ld de, w2BGMapAttributes
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	ld d, a
	
	;point to w2BGMapAttributes + offset + offset to the last two columns of the map view
	ld a, e
	and %11100000
	ld b, a
	ld a, (SCREEN_WIDTH-2)
	add e
	and %00011111
	or b
	ld e, a
	
	call .copycol
	call .copycol
	jp MakeOverworldBGMapAttributes.return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.west
	ld hl, wTileMap
	
	;vram should be the $9800 table right now
	;get the pointer offset into BC
	ld a, [w2MapViewVRAMPointer]
	ld c, a
	ld a, [w2MapViewVRAMPointer+1]
	sub $98
	ld b, a
	
	;point to w2BGMapAttributes + offset
	ld de, w2BGMapAttributes
	ld a, c
	add e
	ld e, a
	ld a, b
	adc d
	ld d, a
	
	call .copycol
	call .copycol
	jp MakeOverworldBGMapAttributes.return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.copyrow	;copy a row from tile map address in HL to map attribute address in DE
	ld c, SCREEN_WIDTH
	push de
.copyrow_loop
	ld a, [hli]
	ld [de], a
	call .convert
	ld a, e
	and $1F
	cp $1F
	jr c, .notRowEnd
	ld a, e
	sub BG_MAP_WIDTH
	ld e, a
	ld a, d
	sbc 0
	ld d, a
.notRowEnd
	inc de
	dec c
	jr nz, .copyrow_loop
	;move to next row
	pop de
	ld a, BG_MAP_WIDTH
	add e
	ld e, a
	ld a, 0
	adc d
	ld d, a
	;account for rows looping back to the top
	cp $D5
	ret c
	sub 4
	ld d, a
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.copycol	;copy a column from tile map address in HL to map attribute address in DE
	ld c, SCREEN_HEIGHT
	push de
	push hl
.copycol_loop
	ld a, [hl]
	ld [de], a
	call .convert
;increment to the next map view row
	ld a, SCREEN_WIDTH
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a
;increment to the next BG Map attribute row	
	ld a, BG_MAP_WIDTH
	add e
	ld e, a
	ld a, 0
	adc d
	cp $D5
	jr c, .notColEnd
	sub 4
.notColEnd
	ld d, a
;decrement counter
	dec c
	jr nz, .copycol_loop
;move to next column
	pop hl
	pop de
	inc hl
	ld a, e
	and %11100000
	ld b, a
	inc de
	ld a, e
	and %00011111
	or b
	ld e, a
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.convert
	push hl
;based on the tileset, point HL to the correct list of BG map attributes for its tiles
	ld a, [H_SPTEMP]   
	ld h, a
	ld a, [H_SPTEMP+1]   
	ld l, a
;point to the correct tile
	ld a, [de]
	add l
	ld l, a
	ld a, 0
	adc h
	ld h, a	
;get the correct color
	ld a, [hl]
	cp 8
	jr c, .copyColorAttribute
	call MakeOverworldBGMapAttributes.townColor
.copyColorAttribute	
	ld [de], a
	pop hl
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
.getTileset
;get the current map tileset
	ld a, [w2CurMapTileset]
	ld c, a
	ld b, 0
	ld hl, OverworldTilePalPointers	
	add hl, bc
	add hl, bc
	ld a, [hli]   
	ld [H_SPTEMP+1], a
	ld a, [hl]    
	ld [H_SPTEMP], a
	ret
	
	
	
MakeAndTransferOverworldBGMapAttributes_OpenText:	
;only for GBC and only if option is active
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	bit 7, a
	ret z
;only on the overworld bgmap
	ld a, [hFlagsFFFA]
	bit 4, a
	ret z
;opening a text box
	ld bc, $0098	;set the MapView offset to zero
	call MakeOverworldBGMapAttributes.jump_in
	ld a, %10 ;only do vBGMap1 space
	ld [hDivideBCDBuffer+2], a
	jp TransferGBCEnhancedBGMapAttributes.vBGMap_selected

MakeAndTransferOverworldBGMapAttributes_CloseText:	
;only on the overworld bgmap
	ld a, [hFlagsFFFA]
	bit 4, a
	ret z
;closing a text box
	ld a, [wMapViewVRAMPointer]
	ld b, a
	ld a, [wMapViewVRAMPointer+1]
	ld c, a
	call MakeOverworldBGMapAttributes.jump_in	
	ld a, %01 ;only do vBGMap0 space
	ld [hDivideBCDBuffer+2], a
	jp TransferGBCEnhancedBGMapAttributes.vBGMap_selected



;This is called late in VBLANK and transfers the BG Map Attributes for any redrawn rows/columns after RedrawRowOrColumn
GBCEnhancedRedrawRowOrColumn:
	ld a, [hVblankBackup]
	and %00000011
	ld b, a
	ld a, [hVblankBackup]
	and %11111100
	ld [hVblankBackup], a
	
	;only for GBC and only if option is active
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	bit 7, a
	ret z
	
	;only on the overworld bgmap
	ld a, [hFlagsFFFA]
	bit 4, a
	ret z

	dec b
	jr nz, .colorRow
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.colorColumn
	ld a, $1
	ld [rVBK], a	;change to vram bank 1

	ld hl, rSVBK
	set 1, [hl]		;switch over to wram bank 2

	ld a, [hRedrawRowOrColumnDest]
	ld e, a
	ld l, a
	ld a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	ld h, a
	ld bc, (w2BGMapAttributes - vBGMap0)
	add hl, bc
	ld c, SCREEN_HEIGHT
.loopCol

.waitVRAMC1
	ldh a, [rSTAT]		
	and %10				
	jr nz, .waitVRAMC1	

	ld a, [hli]
	ld [de], a
	inc de

.waitVRAMC2
	ldh a, [rSTAT]		
	and %10				
	jr nz, .waitVRAMC2	

	ld a, [hl]
	ld [de], a
	ld a, BG_MAP_WIDTH - 1
	add e
	ld e, a
	ld a, BG_MAP_WIDTH - 1
	add l
	ld l, a
	jr nc, .noCarryCol
	inc d
	inc h
.noCarryCol
; the following lines wrap us from bottom to top if necessary
	ld a, h
	cp $D5
	jr c, .noTopWrap
	ld a, $D1
	ld h, a
	ld a, $98
	ld d, a
.noTopWrap
	dec c
	jr nz, .loopCol
.finishColumn
	xor a
	ld [rVBK], a

	ld hl, rSVBK
	res 1, [hl]
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.colorRow
	ld a, $1
	ld [rVBK], a	;change to vram bank 1

	ld hl, rSVBK
	set 1, [hl]		;switch over to wram bank 2

	ld a, [hRedrawRowOrColumnDest]
	ld e, a
	ld l, a
	ld a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	ld h, a
	ld bc, (w2BGMapAttributes - vBGMap0)
	add hl, bc

; draw upper half
	call .DrawHalf

	ld a, [hRedrawRowOrColumnDest]
	ld e, a
	ld l, a
	ld a, [hRedrawRowOrColumnDest + 1]
	ld d, a
	ld h, a
	ld bc, (w2BGMapAttributes - vBGMap0)
	add hl, bc
	ld a, BG_MAP_WIDTH ; width of VRAM background map
	add e
	ld e, a
	ld a, BG_MAP_WIDTH ; width of VRAM background map
	add l
	ld l, a

; draw lower half
	call .DrawHalf

.finishRow
	xor a
	ld [rVBK], a
	ld hl, rSVBK
	res 1, [hl]
	ret

.DrawHalf
	ld c, SCREEN_WIDTH / 2
.loopRow
.waitVRAMR1
	ldh a, [rSTAT]		
	and %10				
	jr nz, .waitVRAMR1	

	ld a, [hli]
	ld [de], a
	inc de

.waitVRAMR2
	ldh a, [rSTAT]		
	and %10				
	jr nz, .waitVRAMR2

	ld a, [hli]
	ld [de], a
	inc de
; the following lines wrap us from the right edge to the left edge if necessary
	ld a, e
	and $1f
	jr nz, .noSideWrap
	ld a, e
	sub BG_MAP_WIDTH
	ld e, a
	ld a, d
	sbc 0
	ld d, a
	ld a, l
	sub BG_MAP_WIDTH
	ld l, a
	ld a, h
	sbc 0
	ld h, a
.noSideWrap
	dec c
	jr nz, .loopRow
	ret
	
	

TransferGBCEnhancedBGMapAttributes:
;only for GBC and only if option is active
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	bit 7, a
	ret z

	ld a, %11
	ld [hDivideBCDBuffer+2], a

.vBGMap_selected
	ld de, $3F00
	ld hl, w2BGMapAttributes
	ld a, h
	ld [hDivideBCDBuffer], a
	ld a, l
	ld [hDivideBCDBuffer+1], a
	di
	ld hl, rSVBK
	set 1, [hl]
	callba LoadBGMapAttributes_Lite
	ld hl, rSVBK
	res 1, [hl]
	ei	
	ret

	

;This function builds the buffer and writes the palettes used for the overworld to the GBC palette registers
TransferGBCEnhancedOverworldPalettes:
;only for GBC and only if option is active
	ld a, [hGBC]
	and a
	ret z
	ld a, [wUnusedD721]
	bit 7, a
	ret z
	
	call UpdateEnhancedGBCPal_BGP.skipHardwareUpdate
	ld d, CONVERT_OBP0
	call UpdateEnhancedGBCPal_OBP.skipHardwareUpdate
	ld d, CONVERT_OBP1
	call UpdateEnhancedGBCPal_OBP.skipHardwareUpdate

	ret 


	
;joenote - This is a function specifically for translating the default enhanced GBC pals into the GBC color buffer
;DE is passed-in containing the address of a pal pattern...like FadePal4 or something
BufferAllEnhancedColorsGBC:
	call .BGP0to3Loop
	call .BGP4to7Loop
	call .OBP0to3Loop
	call .OBP4to7Loop
	ret	
	
.BGP0to3Loop
	ld hl, wGBCFullPalBuffer
	xor a
.BGP0to3Loop_back
	call .readwriteinc
	cp 16
	jr c, .BGP0to3Loop_back
	ret

.BGP4to7Loop
	ld hl, wGBCFullPalBuffer+32
	ld a, 16
.BGP4to7Loop_back
	call .readwriteinc
	cp 32
	jr c, .BGP4to7Loop_back
	ret

.OBP0to3Loop
	ld hl, wGBCFullPalBuffer+64
	ld a, 32
	inc de	;increment to the rOBP0 portion of the pattern
.OBP0to3Loop_back
	call .readwriteinc
	cp 48
	jr c, .OBP0to3Loop_back
	ret

.OBP4to7Loop
	ld hl, wGBCFullPalBuffer+96
	ld a, 48
	inc de	;already incremented to the rOBP0 portion, so now increment to the rOBP1 portion of the pattern
.OBP4to7Loop_back
	call .readwriteinc
	cp 64
	jr c, .OBP4to7Loop_back
	ret

.readwriteinc
	ld [wGBCColorControl], a
	push de
	push hl
	call .ReadMasterPals	;get the color into DE
	push bc
	predef GBCGamma
	pop bc
	pop hl
	ld a, d
	ld [hli], a		;buffer high byte
	ld a, e
	ld [hli], a		;buffer low byte	
	pop de
	ld a, [wGBCColorControl]
	inc a
	ret

.ReadMasterPals
;first grab the correct base palette from GBCEnhancedOverworldPalettes
;the offset of the correct pointer corresponds to double the value of bits 2, 3, and 4 of the wGBCColorControl value
	push de ;need the value in DE for later because it holds the pal pattern like FadePal4 or something

	and %00011100
	rrca
	rrca
	ld de, $0000
	add a
	add a
	add a
	ld e, a

	ld hl, GBCEnhancedOverworldPalettes
	ld a, [wCurMap]
	cp SEAFOAM_ISLANDS_1
	jr z, .isColdCavern
	cp SEAFOAM_ISLANDS_2
	jr c, .notColdCavern
	cp SEAFOAM_ISLANDS_5 + 1
	jr nc, .notColdCavern
.isColdCavern	
	ld hl, GBCEnhancedOverworldPalettes_ColdCavern
.notColdCavern

	ld a, [wMapPalOffset]
	cp 6
	jr nz, .notdark
	ld hl, GBCEnhancedOverworldPalettes_DarkCavern
.notdark

	add hl, de
	pop de ;get the pal pattern back
	ld a, [de]
	;now put the pattern in E and make D zero
	ld d, 0
	ld e, a

;need to look at the last two bits of wGBCColorControl to determine which hardware pal color is desired
	ld a, [wGBCColorControl]
	and %00000011
	jr z, .zero
	cp 1
	jr z, .one
	cp 2
	jr z, .two
	cp 3
	jr z, .three
	
;roll the bits to get the correct base pal color number for the hardware pal color number
.zero
	sla e
	rl d
	sla e
	rl d
.one
	sla e
	rl d
	sla e
	rl d
.two
	sla e
	rl d
	sla e
	rl d
.three
	sla e
	rl d
	sla e
	rl d

;mask out all but the last two bits of D to get the base pal color number in A
	ld a, d
	and %00000011
	
;colors are 2 bytes, so double A to make it an offset and store back into DE
	add a
	ld d, 0
	ld e, a

;add DE to HL to make HL point to the desired base pal color number
	add hl, de

;load the low byte of the color
	ld a, [hli]
	ld e, a
;load the high byte of the color
	ld a, [hli]
	ld d, a
	
	ret

	

UpdateEnhancedGBCPal_BGP:
	ld a, [rBGP]
	ld [wLastBGP], a
.skipHardwareUpdate

;;We're on a GBC and this stuff takes a while. Switch to double speed mode if not already.
;	ld a, [rKEY1]
;	bit 7, a
;	ld a, $ff
;	jr nz, .doublespeed	
;	predef SetCPUSpeed
;	xor a
;.doublespeed
;	push af

	ld de, rBGP	
	call BufferAllEnhancedColorsGBC.BGP0to3Loop
	call BufferAllEnhancedColorsGBC.BGP4to7Loop

	ld a, [rIE]		;manually disable interrupts
	push af
	xor a
	ld [rIE], a

	ld de, wGBCFullPalBuffer

;since the background is getting updates, wait until vblank starts
;this way the scanlines don't update halfway down the screen
	ld a, [rLCDC]
	bit 7, a
	jr z, .next
.wait
	ld a, [rLY]
	cp $90
	jr c, .wait
.next
	call GBCBufferFastTransfer_BGP

	pop af		;re-enable interrupts
	ld [rIE], a
	
;	pop af
;	inc a
;	ret z	;return now if 2x cpu mode was already active at the start of this function
;	;otherwise return to single cpu mode and return
;	predef SingleCPUSpeed
	ret
	


UpdateEnhancedGBCPal_OBP:
; d = CONVERT_OBP0 or CONVERT_OBP1

	ld a, d
	dec a
	jr nz, .OBP1_hardwareUpdate
.OBP0_hardwareUpdate
	ld a, [rOBP0]
	ld [wLastOBP0], a
	jr .skipHardwareUpdate
.OBP1_hardwareUpdate
	ld a, [rOBP1]
	ld [wLastOBP1], a
.skipHardwareUpdate

;;We're on a GBC and this stuff takes a while. Switch to double speed mode if not already.
;	ld a, [rKEY1]
;	bit 7, a
;	ld a, $ff
;	jr nz, .doublespeed	
;	predef SetCPUSpeed
;	xor a
;.doublespeed
;	push af

	ld a, d
	dec a
	push af	;save flag register
	jr nz, .OBP1_buffer
.OBP0_buffer
	ld de, rOBP0
	dec de	;this will get incremented in the next call
	call BufferAllEnhancedColorsGBC.OBP0to3Loop
	jr .transfer
.OBP1_buffer
	ld de, rOBP1
	dec de	;this will get incremented in the next call
	call BufferAllEnhancedColorsGBC.OBP4to7Loop

.transfer
	pop af	;get flag register back
	ld de, wGBCFullPalBuffer
	
	ld a, [rIE]		;manually disable interrupts
	push af
	ld a, 0
	ld [rIE], a

	jr nz, .OBP1_transfer
.OBP0_transfer
	call GBCBufferFastTransfer_OBP0
	jr .done
.OBP1_transfer
	call GBCBufferFastTransfer_OBP1
	
.done	
	pop af		;re-enable interrupts
	ld [rIE], a	

;	pop af
;	inc a
;	ret z	;return now if 2x cpu mode was already active at the start of this function
;	;otherwise return to single cpu mode and return
;	predef SingleCPUSpeed
	ret


	
;This is an extremely fast and lightweight function for transferring an entire 128 byte buffer of colors to the GBC
;Takes DE which points to the address of the buffer to use
;Unlike the reduced versions below for BGP/OBP, this has a built-in 1 frame delay as it waits for LY=$90
;--> Since you're writing every color, it's assumed you want it all to happen during the vblank period
GBCBufferFastTransfer:
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pointer
	
	ld h, d
	ld l, e
	ld sp, hl
	
	ld hl, rBGPI	
	ld a, %10000000	
	ld [hli], a		
	ld c, 32		

.wait
	ldh a, [rLY]		
	cp $90			;8 cycles
	jr nz, .wait	;8 cycles on pass-through
	
.loop
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop	;12 cycles on loop, 8 on pass-through

	;now sitting at 1676 cycles passed
	
	ld hl, rOBPI	;12 cycles
	ld a, %10000000	;8 cycles
	ld [hli], a		;8 cycles
	ld c, 32		;8 cycles

.loop2
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop2	;12 cycles on loop, 8 on pass-through
	
	;completed in 3372 cycles
	;at 456 cycles per scanline, this should fit within the vblank period

	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl
	ret
	
GBCBufferFastTransfer_BGP:
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter
	
	ld h, d
	ld l, e
	ld sp, hl
	
	ld hl, rBGPI	
	ld a, %10000000	
	ld [hli], a		
	ld c, 32		

.loop
	ld a, [rLCDC]
	bit 7, a
	jr z, .next
.wait
; In case we're already in H-blank or V-blank, wait for it to end. This is a
; precaution so that the transfer doesn't extend past the blanking period.
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr z, .wait	;repeat if still in h-blank or v-blank
; Wait for H-blank or V-blank to begin.
.notInBlankingPeriod
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr nz, .notInBlankingPeriod
	
.next
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop	;12 cycles on loop, 8 on pass-through

	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl
	ret
	
GBCBufferFastTransfer_OBP0:
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter
	
	ld h, d
	ld l, e
	ld de, 64
	add hl, de
	ld sp, hl
	
	ld hl, rOBPI	
	ld a, %10000000	
	ld [hli], a		
	ld c, 16		

.loop
	ld a, [rLCDC]
	bit 7, a
	jr z, .next
.wait
; In case we're already in H-blank or V-blank, wait for it to end. This is a
; precaution so that the transfer doesn't extend past the blanking period.
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr z, .wait	;repeat if still in h-blank or v-blank
; Wait for H-blank or V-blank to begin.
.notInBlankingPeriod
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr nz, .notInBlankingPeriod
	
.next
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop	;12 cycles on loop, 8 on pass-through

	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl
	ret
	
GBCBufferFastTransfer_OBP1:
	ld hl, sp + 0
	ld a, h
	ld [H_SPTEMP], a
	ld a, l
	ld [H_SPTEMP + 1], a ; save stack pinter
	
	ld h, d
	ld l, e
	ld de, 96
	add hl, de
	ld sp, hl
	
	ld hl, rOBPI	
	ld a, %10100000	
	ld [hli], a		
	ld c, 16		

.loop
	ld a, [rLCDC]
	bit 7, a
	jr z, .next
.wait
; In case we're already in H-blank or V-blank, wait for it to end. This is a
; precaution so that the transfer doesn't extend past the blanking period.
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr z, .wait	;repeat if still in h-blank or v-blank
; Wait for H-blank or V-blank to begin.
.notInBlankingPeriod
	ld a, [rSTAT]
	and %10 ; mask for non-V-blank/non-H-blank STAT mode
	jr nz, .notInBlankingPeriod
	
.next
	pop de			;12 cycles
	ld a, d			;4 cycles
	ld [hl], a		;8 cycles
	ld a, e			;4 cycles
	ld [hl], a		;8 cycles
	dec c			;4 cycles
	jr nz, .loop	;12 cycles on loop, 8 on pass-through

	ld a, [H_SPTEMP]
	ld h, a
	ld a, [H_SPTEMP + 1]
	ld l, a
	ld sp, hl
	ret

	

;clobbers bc, hl and de
CopyGBCFullPalBuffer1to2:
	ld a, [rIE]		
	push af
	ld a, [rSVBK]
	push af
	
	ld de, w2GBCFullPalBuffer
	ld hl, wGBCFullPalBuffer
	ld c, 128
.loop
	ld a, [hli]
	ld b, a

	;interrupts off
	di
	;svbk1
	ld a, [rSVBK]
	set 1, a
	ld [rSVBK], a


	ld a, b
	ld [de], a

	;svbk0
	ld a, [rSVBK]
	res 1, a
	ld [rSVBK], a
	;interrupts on
	ei

	inc de
	dec c
	jr nz, .loop
	
	pop af
	ld [rSVBK], a
	pop af
	ld [rIE], a
	ret
	

	
DecrementAllColorsGBC_improved:	
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	ret z
	
	ld c, d
	
	push bc
	call CopyGBCFullPalBuffer1to2
	pop bc
	
	;manually disable interrupts
	ld a, [rIE]		
	push af
	xor a
	ld [rIE], a
	
	ld a, [rSVBK]
	set 1, a
	ld [rSVBK], a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, w2GBCFullPalBuffer
	ld b, 128
.mainLoop
	push bc	;save the value in C, which is the amount to darken this function call

;********************************************************************************************************************
;C = number to subract from each R, G, and B value
;HL = pointer for the color bytes to modify

;blue
	ld a, [hl]
	ld b, a				
	and %00000011	
	ld d, a				;d = blue negative
	ld a, %01111100
	and b				;a = positive
	ld b, c				
	rlc b
	rlc b				;b = amount to subtract from blue
	sub b				;a = a - b
	
	jr c, .makeMinBlue
	cp $C
	jr nc, .meetsMinBlue
.makeMinBlue
	ld a, $C	;minimum blue value if underflow
.meetsMinBlue
	
	or d
	ld [hli], a
	
;red
	ld a, [hl]
	ld b, a
	and %11100000
	ld e, a				;e = red negative
	ld a, %00011111
	and b				;a = positive
	sub c				;a = a - c

	jr c, .makeMinRed
	cp $03
	jr nc, .meetsMinRed
.makeMinRed
	ld a, $03	;minimum red value if underflow
.meetsMinRed

	or e
	ld [hld], a

;green
	ld a, [hli]
	ld b, a
	ld a, [hld]

	;load and shift HL five bits to the left
	push hl		;save the pointer
	ld h, 0
	ld l, c
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl

	ld c, a
	;color is now in BC and number to subtract is in HL
	
	;e = green positive lo = red negative from above
	;d = green positive hi = blue negative from above
	
	;do DE = DE - HL - 3
	ld a, e
	sub l
	ld e, a
	ld a, d
	sbc h
	ld d, a
	jr c, .makeMinGreen
	ld a, e
	sub 3
	ld e, a
	ld a, d
	sbc 0
	ld d, a
	jr nc, .meetsMinGreen	
.makeMinGreen
	ld de, $0060 - 3	;<minimum green value if underflow> - 3
.meetsMinGreen
	
	inc de
	inc de
	inc de
	pop hl	

	;now make BC the green negatives, OR with DE, and load back into HL
	ld a, %01111100
	and b
	or d
	ld [hli], a
	ld a, %00011111
	and c
	or e
	ld [hli], a
;********************************************************************************************************************

	pop bc	;get the number of times to iterate
	dec b
	jr nz, .mainLoop
	ld de, w2GBCFullPalBuffer
	call GBCBufferFastTransfer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ld a, [rSVBK]
	res 1, a
	ld [rSVBK], a

	;re-enable interrupts
	pop af		
	ld [rIE], a

;If not in 2x CPU mode, everything updates in less than 144 scanlines
;Therefore, normal mode needs an audio update but 60 fps mode does not
	ld a, [rKEY1]
	bit 7, a
	push af
	call nz, DelayFrame	;Delay a frame in 60 fps mode to get the timing down right for any fades
	pop af
	jr nz, .return
	callba Audio1_UpdateMusic	
.return
	ld a, 1
	and a
	ret
	
	
	
IncrementAllColorsGBC_improved:	
	;Check if playing on a GBC and return if not so
	ld a, [hGBC]
	and a
	ret z
	
	ld c, d
	
	push bc
	call CopyGBCFullPalBuffer1to2
	pop bc
	
	;manually disable interrupts
	ld a, [rIE]		
	push af
	xor a
	ld [rIE], a
	
	ld a, [rSVBK]
	set 1, a
	ld [rSVBK], a
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	ld hl, w2GBCFullPalBuffer
	ld b, 128
.mainLoop
	push bc	;save the value in C, which is the amount to lighten this function call

;********************************************************************************************************************
;C = number to add to each R, G, and B value
;HL = pointer for the color bytes to modify

;blue
	ld a, [hl]
	ld b, a				
	and %00000011	
	ld d, a				;d = blue negative
	ld a, %01111100
	and b				;a = positive
	ld b, c				
	rlc b
	rlc b				;b = amount to add to blue
	add b				;a = a + b
	
	cp $7C+1
	jr c, .meetsMaxBlue
.makeMaxBlue
	ld a, $7C	;Maximum Blue value if overflow
.meetsMaxBlue
	
	or d
	ld [hli], a
	
;red
	ld a, [hl]
	ld b, a
	and %11100000
	ld e, a				;e = Red negative
	ld a, %00011111
	and b				;a = positive
	add c				;a = a + c

	cp $1F+1
	jr c, .meetsMaxRed
.makeMaxRed
	ld a, $1F	;Maximum Red value if underflow
.meetsMaxRed

	or e
	ld [hld], a

;green
	ld a, [hli]
	ld b, a
	ld a, [hld]

	;load and shift HL five bits to the left
	push hl		;save the pointer
	ld h, 0
	ld l, c
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl
	add hl, hl

	ld c, a
	;color is now in BC and number to add is in HL
	
	;e = green positive lo = red negative from above
	;d = green positive hi = blue negative from above
	
	;do HL = HL + DE then make sure it's < $03E0+1
	add hl, de
	ld a, l
	sub $E1
	ld a, h
	sbc $03
	ld d, h
	ld e, l
	jr c, .meetsMaxGreen
.makeMaxGreen
	ld de, $03E0	;Maximum green value if overflow
.meetsMaxGreen
	
	pop hl	

	;now make BC the green negatives, OR with DE, and load back into HL
	ld a, %01111100
	and b
	or d
	ld [hli], a
	ld a, %00011111
	and c
	or e
	ld [hli], a
;********************************************************************************************************************

	pop bc	;get the number of times to iterate
	dec b
	jr nz, .mainLoop
	ld de, w2GBCFullPalBuffer
	call GBCBufferFastTransfer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ld a, [rSVBK]
	res 1, a
	ld [rSVBK], a

	;re-enable interrupts
	pop af		
	ld [rIE], a

;If not in 2x CPU mode, everything updates in less than 144 scanlines
;Therefore, normal mode needs an audio update but 60 fps mode does not
	ld a, [rKEY1]
	bit 7, a
	push af
	call nz, DelayFrame	;Delay a frame in 60 fps mode to get the timing down right for any fades
	pop af
	jr nz, .return
	callba Audio1_UpdateMusic	
.return
	ld a, 1
	and a
	ret
	
	
	
