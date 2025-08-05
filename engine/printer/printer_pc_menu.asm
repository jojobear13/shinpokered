;adding GB_PRINTER

OpenPrinterPC:
	ld hl, wd730
	set 6, [hl]		;set instant text
	xor a
	ld [wParentMenuItem], a
	ld a, [wListScrollOffset]
	push af
	ld a, [wParentMenuItem]
	ld [wCurrentMenuItem], a

	CheckEvent EVENT_90B	;check if dex diploma has been seen
	jr nz, .yesDiploma
.noDiploma
	;size of menu text box
	coord hl, 0, 0
	ld b, 10
	ld c, 15
	call TextBoxBorder
	coord hl, 2, 2
	ld de, PrinterPCMenuText_noDiploma
	call PlaceString
	jr .doneMenuText
.yesDiploma
	;size of menu text box
	coord hl, 0, 0
	ld b, 12
	ld c, 15
	call TextBoxBorder
	coord hl, 2, 2
	ld de, PrinterPCMenuText
	call PlaceString
.doneMenuText

	ld hl, wTopMenuItemY
	ld a, 2
	ld [hli], a ; wTopMenuItemY
	dec a
	ld [hli], a ; wTopMenuItemX
	inc hl
	inc hl

	CheckEvent EVENT_90B	;check if dex diploma has been seen
	jr nz, .yesDiploma2
.noDiploma2
	ld a, 4	;number of non-cancel menu items
	jr .doneMenuText2
.yesDiploma2
	ld a, 5	;number of non-cancel menu items
.doneMenuText2	
	ld [hli], a ; wMaxMenuItem

	ld a, A_BUTTON | B_BUTTON
	ld [hli], a ; wMenuWatchedKeys
	xor a
	ld [hli], a ; wLastMenuItem
	ld [hli], a ; wPartyAndBillsPCSavedMenuItem
	ld hl, wListScrollOffset
	ld [hli], a ; wListScrollOffset
	ld [hl], a ; wMenuWatchMovingOutOfBounds
	ld [wPlayerMonNumber], a

;now handle the text box giving the current box number
	coord hl, 9, 14
	ld b, 2
	ld c, 9
	call TextBoxBorder
	ld a, [wCurrentBoxNum]
	and $7f
	cp 9
	jr c, .singleDigitBoxNum
; two digit box num
	sub 9
	coord hl, 17, 16
	ld [hl], "1"
	add "0"
	jr .next
.singleDigitBoxNum
	add "1"
.next
	Coorda 18, 16
	coord hl, 10, 16
	ld de, PrintBoxNoPCText
	call PlaceString

;now do menu controls
	ld a, 1
	ld [H_AUTOBGTRANSFERENABLED], a
	call Delay3
	call HandleMenuInput
	bit 1, a
	jp nz, ExitPrinterPC ; b button
	call PlaceUnfilledArrowMenuCursor

	CheckEvent EVENT_90B	;check if dex diploma has been seen
	jr nz, .yesDiploma3
.noDiploma3
	ld a, [wCurrentMenuItem]
	ld [wParentMenuItem], a
	and a
	jp z, PCPrintSettings
	cp $1
	jp z, PCPrintDex
	cp $2
	jp z, PCPrintMon
	cp $3
	jp z, PCPrintBox
	jr .doneMenuText3
.yesDiploma3
	ld a, [wCurrentMenuItem]
	ld [wParentMenuItem], a
	and a
	jp z, PCPrintSettings
	cp $1
	jp z, PCPrintDex
	cp $2
	jp z, PCPrintMon
	cp $3
	jp z, PCPrintBox
	cp $4
	jp z, PCPrintDiploma
.doneMenuText3
	;fall through for exiting
ExitPrinterPC:
	pop af
	ld [wListScrollOffset], a
	ld hl, wd730
	res 6, [hl]
	ret
LoopPrinterPC:
	pop af
	ld [wListScrollOffset], a
	ld hl, wd730
	res 6, [hl]
	jp OpenPrinterPC

PrinterPCMenuText:
	db   "SETTINGS"
	next "PRINT #DEX"
	next "PRINT #MON"
	next "PRINT BOX"
	next "PRINT DIPLOMA"
	next "CANCEL"
	db "@"
PrinterPCMenuText_noDiploma:
	db   "SETTINGS"
	next "PRINT #DEX"
	next "PRINT #MON"
	next "PRINT BOX"
	next "CANCEL"
	db "@"
PrintBoxNoPCText:
	db "BOX No.@"


	
	
	
;This is a menu for setting how dark to make the prints	
PCPrintSettings:
	xor a
	ld [wParentMenuItem], a
	ld [wCurrentMenuItem], a
	ld a, [wListScrollOffset]
	push af

	;size of menu text box
	coord hl, 0, 0
	ld b, 12
	ld c, 15
	call TextBoxBorder
	coord hl, 2, 2
	ld de, PrinterPCSettingsText
	call PlaceString

	ld hl, wTopMenuItemY
	ld a, 2
	ld [hli], a ; wTopMenuItemY
	dec a
	ld [hli], a ; wTopMenuItemX
	inc hl
	inc hl

	ld a, 5	;number of non-cancel menu items
	ld [hli], a ; wMaxMenuItem

	ld a, A_BUTTON | B_BUTTON
	ld [hli], a ; wMenuWatchedKeys
	xor a
	ld [hli], a ; wLastMenuItem
	ld [hli], a ; wPartyAndBillsPCSavedMenuItem
	ld hl, wListScrollOffset
	ld [hli], a ; wListScrollOffset
	ld [hl], a ; wMenuWatchMovingOutOfBounds
	ld [wPlayerMonNumber], a

;now handle the text box giving the current setting
	coord hl, 9, 14
	ld b, 2
	ld c, 9
	call TextBoxBorder
	call PCPrinterCurrentSettingDisplay

;now do menu controls
	call HandleMenuInput
	bit 1, a
	jr nz, .exitPrinterSettings ; b button
	call PlaceUnfilledArrowMenuCursor

	ld a, [wCurrentMenuItem]
	ld [wParentMenuItem], a
	and a
	jr z, .lightest
	cp $1
	jr z, .lighter
	cp $2
	jr z, .normal
	cp $3
	jr z, .darker
	cp $4
	jr z, .darkest
	jr .exitPrinterSettings
.affirmSettings
	call PCPrinterCurrentSettingDisplay
	ld a, SFX_ENTER_PC
	call PlaySound
	call WaitForSoundToFinish
.exitPrinterSettings
	pop af
	ld [wListScrollOffset], a
	jp LoopPrinterPC
.lightest
	ld a, $00
	ld [wPrinterSettings], a
	jr .affirmSettings
.lighter
	ld a, $20
	ld [wPrinterSettings], a
	jr .affirmSettings
.normal
	ld a, $40
	ld [wPrinterSettings], a
	jr .affirmSettings
.darker
	ld a, $60
	ld [wPrinterSettings], a
	jr .affirmSettings
.darkest
	ld a, $7F
	ld [wPrinterSettings], a
	jr .affirmSettings

PrinterPCSettingsText:
	db   "LIGHTEST"
	next "LIGHTER"
	next "NORMAL"
	next "DARKER"
	next "DARKEST"
	next "BACK"
	db "@"
PrinterPCSettingsTextSingle00:
	db "LIGHTEST@"
PrinterPCSettingsTextSingle20:
	db "LIGHTER @"
PrinterPCSettingsTextSingle40:
	db "NORMAL  @"
PrinterPCSettingsTextSingle60:
	db "DARKER  @"
PrinterPCSettingsTextSingle7F:
	db "DARKEST @"

PCPrinterCurrentSettingDisplay:
	ld a, [wPrinterSettings]
	ld de, PrinterPCSettingsTextSingle00
	and a
	jr z, .next
	ld de, PrinterPCSettingsTextSingle20
	cp $20
	jr z, .next
	ld de, PrinterPCSettingsTextSingle40
	cp $40
	jr z, .next
	ld de, PrinterPCSettingsTextSingle60
	cp $60
	jr z, .next
	ld de, PrinterPCSettingsTextSingle7F
.next
	coord hl, 10, 16
	call PlaceString
	ret
	
	
	
PCPrintDex:
	ld a, [wPrinterSettings]
	set 7, a
	ld [wPrinterSettings], a
	predef ShowPokedexMenu
	ld a, [wPrinterSettings]
	res 7, a
	ld [wPrinterSettings], a
	call LoadGBPal
	jp ExitPrinterPC

	
	
PCPrintMon:
.select_mon_to_print
	call GBPalWhiteOutWithDelay3
	call LoadCurrentMapView
	call SaveScreenTilesToBuffer2
	ld a, $ff
	ld [wUpdateSpritesEnabled], a
	ld a, $00
	ld [wTempTilesetNumTiles], a
	call DisplayPartyMenu
	jp nc, .print
	call GBPalWhiteOutWithDelay3
	call RestoreScreenTilesAndReloadTilePatterns
	jr .exiting
.print
	xor a
	ld [wUpdateSpritesEnabled], a
	callab PrintFanClubPortrait
	call GBPalWhiteOutWithDelay3
	call ReloadTilesetTilePatterns
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadScreenTilesFromBuffer2
	call Delay3
	call GBPalNormal
.exiting
	call LoadGBPal
	jp ExitPrinterPC

	

PCPrintBox:
	callba PrintPCBox
	jp LoopPrinterPC



PCPrintDiploma:
	call SaveScreenTilesToBuffer2
	xor a
	ld [wUpdateSpritesEnabled], a
	ld a, [wPrinterSettings]
	set 7, a
	ld [wPrinterSettings], a
	callab PrintDiploma
	ld a, [wPrinterSettings]
	res 7, a
	ld [wPrinterSettings], a
	call GBPalWhiteOutWithDelay3
	call ReloadTilesetTilePatterns
	call RestoreScreenTilesAndReloadTilePatterns
	call LoadScreenTilesFromBuffer2
	call Delay3
	call GBPalNormal
	call LoadGBPal
	jp ExitPrinterPC
