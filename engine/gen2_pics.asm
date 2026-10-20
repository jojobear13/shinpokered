; Gen 2 sprites (the extra options' SPRITES: GEN 2): GetMonHeader takes a
; species' front and back pics from Gen2PicHeaders (Crystal's, from pret's
; pokecrystal; tools/gen_gen2_pics.py) instead of its base stats. The backs
; are 48x48, shown unscaled (LoadUncompressedBackPics), as the Spaceworld
; backs are.

; [wd11e] = a Pokédex number -> with the option on, wMonHPicBank,
; wMonHSpriteDim, wMonHFrontSprite and wMonHBackSprite from Gen2PicHeaders
Gen2PicHeader:
	ld a, [wSpriteOptions]
	bit BIT_GEN2_SPRITES, a
	ret z
	ld a, [wd11e]
	dec a
	ld hl, Gen2PicHeaders
	ld bc, GEN2_PIC_HEADER_LENGTH
	call AddNTimes
	ld a, [hli]
	ld [wMonHPicBank], a
	ld a, [hli]
	ld [wMonHSpriteDim], a
	ld de, wMonHFrontSprite
	ld bc, 4 ; and wMonHBackSprite
	jp CopyData

; nz if the mon backs being shown are 48x48 (the Spaceworld backs, or Gen 2
; sprites), z if they're Gen 1's 32x32, shown doubled
BackPicsAreLarge::
IF DEF(_SWBACKS)
	or 1
	ret
ELSE
	ld a, [wSpriteOptions]
	and 1 << BIT_GEN2_SPRITES
	ret
ENDC

INCLUDE "data/gen2_pics.asm"
