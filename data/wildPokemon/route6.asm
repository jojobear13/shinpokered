Route6Mons:;joenote - added squirtle
	db $0F
	IF DEF(_ENCRED)
		db 13,ODDISH
		db 13,PIDGEY
		db 15,PIDGEY
		db 12,MANKEY
		db 15,ODDISH
		db 16,ODDISH
		db 16,PIDGEY
		db 14,MANKEY
		db 10,SQUIRTLE
		db 16,MANKEY
	ELIF DEF(_ENCBLUEJP)
		db 13, ODDISH
		db 13, PIDGEY
		db 15, PIDGEY
		db 12, MEOWTH
		db 15, ODDISH
		db 16, ODDISH
		db 16, PIDGEY
		db 14, MEOWTH
		db 10,SQUIRTLE
		db 16, MEOWTH
	ELIF DEF(_ENCBLUEGREEN)
		db 13,BELLSPROUT
		db 13,PIDGEY
		db 15,PIDGEY
		db 12,MEOWTH
		db 15,BELLSPROUT
		db 16,BELLSPROUT
		db 16,PIDGEY
		db 14,MEOWTH
		db 10,SQUIRTLE
		db 16,MEOWTH
	ENDC
	db $00
