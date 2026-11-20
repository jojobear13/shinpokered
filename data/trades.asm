TradeMons:
; givemonster, getmonster, textstring, nickname (11 bytes), 14 bytes total
IF DEF(_ENCBLUEJP)
	db RHYDON,		KANGASKHAN,	0, "Rodan@@@@@@"
	db JIGGLYPUFF,	MR_MIME,   	0, "Masaru@@@@@"
	db BUTTERFREE,	BEEDRILL,  	2, "Chikuchiku@";japanese onomatopoeia for a needle-like type of prickling pain
	db GROWLITHE,	KRABBY,     0, "Doraku@@@@@";reference to the Kani Dōraku japanese restaraunt chain
	db PIDGEY,		FARFETCHD, 	2, "Akka@@@@@@@"
	db PERSIAN,		TAUROS, 	0, "Gyuta@@@@@@"
	db MACHOKE,		HAUNTER,	1, "Ghosuke@@@@"
	db KADABRA,		GRAVELER,	1, "Saburo@@@@@"
	db SEEL,		SLOWPOKE,	2, "Oscar@@@@@@"
	db RATTATA,		POLIWAG,	2, "Poli-Tan@@@"
;unused localization names for blue-jp trades per 
;https://tcrf.net/Development:Pok%C3%A9mon_Red_and_Blue/Localization#Pok%C3%A9mon_Nicknames
;	FLUFFY
;	MYMO
;	<beedrill has no localized name>
;	VALERIE
;	SWANNY
;	JIMBO
;	MICHELLE
;	JENNY
;	SHANE
;	WAGSTER
ELIF DEF(_ENCBLUEGREEN)
	db NIDORINO,  NIDORINA, 0,"Terry@@@@@@"
	db ABRA,      MR_MIME,  0,"Marcel@@@@@"
	db BUTTERFREE,BEEDRILL, 2,"Prickly@@@@"
	db PONYTA,    SEEL,     0,"Sailor@@@@@"
	db SPEAROW,   FARFETCHD,2,"Dux@@@@@@@@"
	db SLOWBRO,   LICKITUNG,0,"Marc@@@@@@@"
	db POLIWHIRL, JYNX,     1,"Lola@@@@@@@"
	db RAICHU,    ELECTRODE,1,"Doris@@@@@@"
	db VENONAT,   TANGELA,  2,"Crinkles@@@"
;	db NIDORAN_M, NIDORAN_F,2,"SPOT@@@@@@@"	;joenote - this was probably accidentally swapped by the localization team
	db NIDORAN_F, NIDORAN_M,2,"Spot@@@@@@@"

ELIF DEF(_ENCRED)	;joenote - swap the sexes of the Nidos for red version and alter the beedrill trade
	db NIDORINA,  NIDORINO, 0,"Henry@@@@@@"
	db ABRA,      MR_MIME,  0,"Marcel@@@@@"
	db BEEDRILL, BUTTERFREE,2,"Malcolm@@@@"
	db PONYTA,    SEEL,     0,"Newton@@@@@"
	db SPEAROW,   FARFETCHD,2,"Wuhan@@@@@@"
	db SLOWBRO,   LICKITUNG,0,"Fidelio@@@@"
	db POLIWHIRL, JYNX,     1,"Sambo@@@@@@"
	db RAICHU,    ELECTRODE,1,"Theodore@@@"
	db VENONAT,   TANGELA,  2,"Shibari@@@@"
	db NIDORAN_M, NIDORAN_F,2,"Anne@@@@@@@"


ELSE ;default to use if there is a compiler tag issue
	db NIDORINO,  NIDORINA, 0,"Terry@@@@@@"
	db ABRA,      MR_MIME,  0,"Marcel@@@@@"
	db BUTTERFREE,BEEDRILL, 2,"Prickly@@@@"
	db PONYTA,    SEEL,     0,"Sailor@@@@@"
	db SPEAROW,   FARFETCHD,2,"Dux@@@@@@@@"
	db SLOWBRO,   LICKITUNG,0,"Marc@@@@@@@"
	db POLIWHIRL, JYNX,     1,"Lola@@@@@@@"
	db RAICHU,    ELECTRODE,1,"Doris@@@@@@"
	db VENONAT,   TANGELA,  2,"Crinkles@@@"
	db NIDORAN_M, NIDORAN_F,2,"Spot@@@@@@@"
ENDC