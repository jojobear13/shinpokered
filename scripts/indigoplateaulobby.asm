IndigoPlateauLobbyScript:
	call Serial_TryEstablishingExternallyClockedConnection
	call EnableAutoTextBoxDrawing
	callba RandoLobbyGate
	ld hl, wCurrentMapScriptFlags
	bit 6, [hl]
	res 6, [hl]
	ret z
	; wispnote - This event was probably ment to be reset on Route 23.
	; ResetEvent EVENT_VICTORY_ROAD_1_BOULDER_ON_SWITCH
	ld hl, wBeatLorelei
	bit 1, [hl]
	res 1, [hl]
	ret z
	; Elite 4 events
	ResetEventRange ELITE4_EVENTS_START, EVENT_LANCES_ROOM_LOCK_DOOR
	ret

IndigoPlateauLobbyTextPointers:
	dw IndigoHealNurseText
	dw IndigoPlateauLobbyText2
	dw IndigoPlateauLobbyText3
	dw IndigoCashierText
	dw IndigoTradeNurseText

IndigoHealNurseText:
	TX_POKECENTER_NURSE

IndigoPlateauLobbyText2:
	TX_ASM
	CheckEvent EVENT_908 ;joenote - add text for after beating the elite 4
	ld hl, IndigoPlateauLobbyText2_normal
	jr z, .print
	ld hl, IndigoPlateauLobbyText2_ALT
.print	
	call PrintText
	jp TextScriptEnd
	
IndigoPlateauLobbyText2_normal:
	TX_FAR _IndigoPlateauLobbyText2
	db "@"

IndigoPlateauLobbyText3:
	TX_FAR _IndigoPlateauLobbyText3
	db "@"

IndigoTradeNurseText:
	TX_CABLE_CLUB_RECEPTIONIST

IndigoPlateauLobbyText2_ALT:
	text "Yo! Once and"
	line "future CHAMP!"

	para "At #MON LEAGUE,"
	line "you have to face"
	cont "the ELITE FOUR in"
	cont "succession."

	para "If you lose, you"
	line "have to start all"
	cont "over again! You"
	cont "know the drill by"
	cont "now! Go for it!"
	done
	db "@"
