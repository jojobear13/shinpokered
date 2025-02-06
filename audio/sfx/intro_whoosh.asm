SFX_Intro_Whoosh_Ch7:
IF DEF(_REDGREENJP)	;Whoosh SFX slightly different in red/green
;Credit Masaru2 https://github.com/Masaru2/pokejp/commit/4c72fadca29923b43b0958a7ed59bad59103a302
	noisenote 8, 3, -4, 32
	noisenote 6, 10, 0, 32
	noisenote 8, 11, 0, 33
	noisenote 10, 12, 0, 34
	noisenote 15, 13, 2, 35
ELSE
	noisenote 8, 2, -4, 32
	noisenote 3, 10, 0, 32
	noisenote 3, 11, 0, 33
	noisenote 3, 12, 0, 34
	noisenote 15, 13, 2, 36
ENDC
	endchannel
