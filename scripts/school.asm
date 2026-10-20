SchoolScript:
	jp EnableAutoTextBoxDrawing

SchoolTextPointers:
	dw SchoolText1
	dw SchoolText2
	dw SchoolText3 ;joenote - added more text

SchoolText1:
	TX_FAR _SchoolText1
	db "@"

SchoolText2:
	TX_FAR _SchoolText2
	db "@"

SchoolText3:
	TX_FAR _SchoolText3
	db "@"
	
