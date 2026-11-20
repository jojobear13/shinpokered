CreditsTextPointers:
	dw CredVersion
	dw CredTajiri
	dw CredTaOota
	dw CredMorimoto
	dw CredWatanabe
	dw CredMasuda
	dw CredNisino
	dw CredSugimori
	dw CredNishida
	dw CredMiyamoto
	dw CredKawaguchi
	dw CredIshihara
	dw CredYamauchi
	dw CredZinnai
	dw CredHishida
	dw CredSakai
	dw CredYamaguchi
	dw CredYamamoto
	dw CredTaniguchi
	dw CredNonomura
	dw CredFuziwara
	dw CredMatsusima
	dw CredTomisawa
	dw CredKawamoto
	dw CredKakei
	dw CredTsuchiya
	dw CredTaNakamura
	dw CredYuda
	dw CredMon
	dw CredDirector
	dw CredProgrammers
	dw CredCharDesign
	dw CredMusic
	dw CredSoundEffects
	dw CredGameDesign
	dw CredMonsterDesign
	dw CredGameScene
	dw CredParam
	dw CredMap
	dw CredTest
	dw CredSpecial
	dw CredProducers
	dw CredProducer
	dw CredExecutive
	dw CredTamada
	dw CredSaOota
	dw CredYoshikawa
	dw CredToOota
	dw CredUSStaff
	dw CredUSCoord
	dw CredTilden
	dw CredKawakami
	dw CredHiNakamura
	dw CredGiese
	dw CredOsborne
	dw CredTrans
	dw CredOgasawara
	dw CredIwata
	dw CredIzushi
	dw CredHarada
	dw CredMurakawa
	dw CredFukui
	dw CredClub
	dw CredPAAD

CredVersion: ; this 1 byte difference makes all bank addresses offset by 1 in the blue version
IF DEF(_RED)
	db -8, "Red Version Staff@"
ENDC
IF DEF(_BLUE)
	db -8, "Blue Version Staff@"
ENDC
IF DEF(_GREEN)
	db -8, "Green Version Staff@"
ENDC
CredTajiri:
	db -6, "Satoshi Tajiri@"
CredTaOota:
	db -6, "Takenori Oota@"
CredMorimoto:
	db -7, "Shigeki Morimoto@"
CredWatanabe:
	db -7, "Tetsuya Watanabe@"
CredMasuda:
	db -6, "Junichi Masuda@"
CredNisino:
	db -5, "Kohji Nisino@"
CredSugimori:
	db -5, "Ken Sugimori@"
CredNishida:
	db -6, "Atsuko Nishida@"
CredMiyamoto:
	db -7, "Shigeru Miyamoto@"
CredKawaguchi:
	db -8, "Takashi Kawaguchi@"
CredIshihara:
	db -8, "Tsunekazu Ishihara@"
CredYamauchi:
	db -7, "Hiroshi Yamauchi@"
CredZinnai:
	db -7, "Hiroyuki Zinnai@"
CredHishida:
	db -7, "Tatsuya Hishida@"
CredSakai:
	db -6, "Yasuhiro Sakai@"
CredYamaguchi:
	db -7, "Wataru Yamaguchi@"
CredYamamoto:
	db -8, "Kazuyuki Yamamoto@"
CredTaniguchi:
	db -8, "Ryohsuke Taniguchi@"
CredNonomura:
	db -8, "Fumihiro Nonomura@"
CredFuziwara:
	db -7, "Motofumi Fuziwara@"
CredMatsusima:
	db -7, "Kenji Matsusima@"
CredTomisawa:
	db -7, "Akihito Tomisawa@"
CredKawamoto:
	db -7, "Hiroshi Kawamoto@"
CredKakei:
	db -6, "Akiyoshi Kakei@"
CredTsuchiya:
	db -7, "Kazuki Tsuchiya@"
CredTaNakamura:
	db -6, "Takeo Nakamura@"
CredYuda:
	db -6, "Masamitsu Yuda@"
CredMon:
	db -3, "#Mon@"
CredDirector:
	db -3, "Director@"
CredProgrammers:
	db -5, "Programmers@"
CredCharDesign:
	db -7, "Character Design@"
CredMusic:
	db -2, "Music@"
CredSoundEffects:
	db -6, "Sound Effects@"
CredGameDesign:
	db -5, "Game Design@"
CredMonsterDesign:
	db -6, "Monster Design@"
CredGameScene:
	db -6, "Game Scenario@"
CredParam:
	db -8, "Parametric Design@"
CredMap:
	db -4, "Map Design@"
CredTest:
	db -7, "Product Testing@"
CredSpecial:
	db -6, "Special Thanks@"
CredProducers:
	db -4, "Producers@"
CredProducer:
	db -4, "Producer@"
CredExecutive:
	db -8, "Executive Producer@"
CredTamada:
	db -6, "Sousuke Tamada@"
CredSaOota:
	db -5, "Satoshi Oota@"
CredYoshikawa:
	db -6, "Rena Yoshikawa@"
CredToOota:
	db -6, "Tomomichi Oota@"
CredUSStaff:
	db -7, "Us Version Staff@"
CredUSCoord:
	db -7, "Us Coordination@"
CredTilden:
	db -5, "Gail Tilden@"
CredKawakami:
	db -6, "Naoko Kawakami@"
CredHiNakamura:
	db -6, "Hiro Nakamura@"
CredGiese:
	db -6, "William Giese@"
CredOsborne:
	db -5, "Sara Osborne@"
CredTrans:
	db -7, "Text Translation@"
CredOgasawara:
	db -6, "Nob Ogasawara@"
CredIwata:
	db -5, "Satoru Iwata@"
CredIzushi:
	db -7, "Takehiro Izushi@"
CredHarada:
	db -7, "Takahiro Harada@"
CredMurakawa:
	db -7, "Teruki Murakawa@"
CredFukui:
	db -5, "Kohta Fukui@"
CredClub:
	db -9, "Ncl Super Mario Club@"
CredPAAD:
	db -5, "Paad Testing@"
