;blue-jp and red/green are slightly different
;credit Masaru2 https://github.com/Masaru2/pokejp/commit/199e3a6a99664e727bb6f280fe7e4469b3ff369d
IF DEF(_REDGREENJP)
SFX_Intro_Hip_Ch7:
	noisenote 4, 13, 1, 65
ELIF DEF(_BLUEJP)
SFX_Intro_Hip_Ch4:
	duty 2
	pitchenvelope 2, 6
	squarenote 12, 12, 2, 1856
	pitchenvelope 0, 8
ELSE
SFX_Intro_Hip_Ch4:
	duty 2
	pitchenvelope 2, 6
	squarenote 12, 12, 2, 1856
	pitchenvelope 0, 0
ENDC
	endchannel
