NUM_MUSIC_TRACKS EQU 45

DisplaySoundTestMenu:
	ld a, SFX_PRESS_AB
	call PlaySound
	call ClearScreen
	ld a, 1
	ld [hJoy7], a
	
;place the static strings for the screen
	coord hl, 5, 1
	ld de, SoundTestTextInstructions3
	call PlaceString
	coord hl, 1, 14
	ld de, SoundTestTextInstructions2
	call PlaceString
	coord hl, 1, 16
	ld de, SoundTestTextInstructions1
	call PlaceString
;draw text box for the audio track
	coord hl, 0, 6
	ld b, 1
	ld c, 18
	call TextBoxBorder

;update to initial track in the list
	xor a
	ld [wWhichPokemon], a
	call .updatetrackname


.loop

	call Delay3

.getJoypadStateLoop
	call JoypadLowSensitivity
	ld a, [hJoy5]
	ld b, a
	bit BIT_B_BUTTON, b ; B button pressed?
	jr nz, .exitMenu
	bit BIT_SELECT, b
	jr nz, .exitMenu
	bit BIT_A_BUTTON, b ; A button pressed?
	jr nz, .play_selection
.checkDirectionKeys
	bit BIT_D_LEFT, b ; Left pressed?
	jr nz, .dec_track
	bit BIT_D_RIGHT, b ; Right pressed?
	jr nz, .inc_track
	jr .getJoypadStateLoop
.exitMenu
	xor a
	ld [hJoy7], a
	ld a, SFX_PRESS_AB
	call PlaySound
	call ClearScreen
	ret
	
.inc_track
	ld a, [wWhichPokemon]
	add 1
	cp NUM_MUSIC_TRACKS
	jr c, .inc_track_next
	xor a
.inc_track_next
	ld [wWhichPokemon], a
	call .updatetrackname
	jr .loop
	
.dec_track
	ld a, [wWhichPokemon]
	sub 1
	jr nc, .dec_track_next
	ld a, NUM_MUSIC_TRACKS-1
.dec_track_next
	ld [wWhichPokemon], a
	call .updatetrackname
	jr .loop
	
.play_selection
	ld hl, SoundTestTrackList
	ld a, [wWhichPokemon]
	ld b, 0
	ld c, a
	sla c
	rl b
	sla c
	rl b
	add hl, bc
	inc hl
	inc hl
	
	ld a, [hli]
	ld c, a
	ld a, [hl]
	call PlayMusic

	jr .getJoypadStateLoop

.updatetrackname
	;blank track name
	coord hl, 1, 7
	ld de, SoundTestTextBlankTrack
	call PlaceString

	ld hl, SoundTestTrackList
	ld a, [wWhichPokemon]
	ld b, 0
	ld c, a
	sla c
	rl b
	sla c
	rl b
	add hl, bc

	ld a, [hli]	;read low nybble of track name address
	ld e, a
	ld a, [hli]	;read high nybble of track name address
	ld d, a

	;print track name
	coord hl, 1, 7
	call PlaceString
	ret
	
SoundTestTextInstructions1:
	db "A: Play   B: Exit@"
SoundTestTextInstructions2:
	db "L/R: Change Track@"
SoundTestTextInstructions3:
	db "SOUND TEST@"
SoundTestTextBlankTrack:
	db "                  @"
SoundTestTrackList:
	dw Title_Music_PalletTown, (MUSIC_PALLET_TOWN << 8) | Bank(Music_PalletTown)
	dw Title_Music_Pokecenter, (MUSIC_POKECENTER << 8) | Bank(Music_Pokecenter)
	dw Title_Music_Gym, (MUSIC_GYM << 8) | Bank(Music_Gym)
	dw Title_Music_Cities1, (MUSIC_CITIES1 << 8) | Bank(Music_Cities1)
	dw Title_Music_Cities2, (MUSIC_CITIES2 << 8) | Bank(Music_Cities2)
	dw Title_Music_Celadon, (MUSIC_CELADON << 8) | Bank(Music_Celadon)
	dw Title_Music_Cinnabar, (MUSIC_CINNABAR << 8) | Bank(Music_Cinnabar)
	dw Title_Music_Vermilion, (MUSIC_VERMILION << 8) | Bank(Music_Vermilion)
	dw Title_Music_Lavender, (MUSIC_LAVENDER << 8) | Bank(Music_Lavender)
	dw Title_Music_SSAnne, (MUSIC_SS_ANNE << 8) | Bank(Music_SSAnne)
	dw Title_Music_MeetProfOak, (MUSIC_MEET_PROF_OAK << 8) | Bank(Music_MeetProfOak)
	dw Title_Music_MeetRival, (MUSIC_MEET_RIVAL << 8) | Bank(Music_MeetRival)
	dw Title_Music_MuseumGuy, (MUSIC_MUSEUM_GUY << 8) | Bank(Music_MuseumGuy)
	dw Title_Music_SafariZone, (MUSIC_SAFARI_ZONE << 8) | Bank(Music_SafariZone)
	dw Title_Music_PkmnHealed, (MUSIC_PKMN_HEALED << 8) | Bank(Music_PkmnHealed)
	dw Title_Music_Routes1, (MUSIC_ROUTES1 << 8) | Bank(Music_Routes1)
	dw Title_Music_Routes2, (MUSIC_ROUTES2 << 8) | Bank(Music_Routes2)
	dw Title_Music_Routes3, (MUSIC_ROUTES3 << 8) | Bank(Music_Routes3)
	dw Title_Music_Routes4, (MUSIC_ROUTES4 << 8) | Bank(Music_Routes4)
	dw Title_Music_IndigoPlateau, (MUSIC_INDIGO_PLATEAU << 8) | Bank(Music_IndigoPlateau)
	dw Title_Music_GymLeaderBattle, (MUSIC_GYM_LEADER_BATTLE << 8) | Bank(Music_GymLeaderBattle)
	dw Title_Music_TrainerBattle, (MUSIC_TRAINER_BATTLE << 8) | Bank(Music_TrainerBattle)
	dw Title_Music_WildBattle, (MUSIC_WILD_BATTLE << 8) | Bank(Music_WildBattle)
	dw Title_Music_FinalBattle, (MUSIC_FINAL_BATTLE << 8) | Bank(Music_FinalBattle)
	dw Title_Music_DefeatedTrainer, (MUSIC_DEFEATED_TRAINER << 8) | Bank(Music_DefeatedTrainer)
	dw Title_Music_DefeatedWildMon, (MUSIC_DEFEATED_WILD_MON << 8) | Bank(Music_DefeatedWildMon)
	dw Title_Music_DefeatedGymLeader, (MUSIC_DEFEATED_GYM_LEADER << 8) | Bank(Music_DefeatedGymLeader)
	dw Title_Music_TitleScreen, (MUSIC_TITLE_SCREEN << 8) | Bank(Music_TitleScreen)
	dw Title_Music_Credits, (MUSIC_CREDITS << 8) | Bank(Music_Credits)
	dw Title_Music_HallOfFame, (MUSIC_HALL_OF_FAME << 8) | Bank(Music_HallOfFame)
	dw Title_Music_OaksLab, (MUSIC_OAKS_LAB << 8) | Bank(Music_OaksLab)
	dw Title_Music_JigglypuffSong, (MUSIC_JIGGLYPUFF_SONG << 8) | Bank(Music_JigglypuffSong)
	dw Title_Music_BikeRiding, (MUSIC_BIKE_RIDING << 8) | Bank(Music_BikeRiding)
	dw Title_Music_Surfing, (MUSIC_SURFING << 8) | Bank(Music_Surfing)
	dw Title_Music_GameCorner, (MUSIC_GAME_CORNER << 8) | Bank(Music_GameCorner)
	dw Title_Music_IntroBattle, (MUSIC_INTRO_BATTLE << 8) | Bank(Music_IntroBattle)
	dw Title_Music_Dungeon1, (MUSIC_DUNGEON1 << 8) | Bank(Music_Dungeon1)
	dw Title_Music_Dungeon2, (MUSIC_DUNGEON2 << 8) | Bank(Music_Dungeon2)
	dw Title_Music_Dungeon3, (MUSIC_DUNGEON3 << 8) | Bank(Music_Dungeon3)
	dw Title_Music_CinnabarMansion, (MUSIC_CINNABAR_MANSION << 8) | Bank(Music_CinnabarMansion)
	dw Title_Music_PokemonTower, (MUSIC_POKEMON_TOWER << 8) | Bank(Music_PokemonTower)
	dw Title_Music_SilphCo, (MUSIC_SILPH_CO << 8) | Bank(Music_SilphCo)
	dw Title_Music_MeetEvilTrainer, (MUSIC_MEET_EVIL_TRAINER << 8) | Bank(Music_MeetEvilTrainer)
	dw Title_Music_MeetFemaleTrainer, (MUSIC_MEET_FEMALE_TRAINER << 8) | Bank(Music_MeetFemaleTrainer)
	dw Title_Music_MeetMaleTrainer, (MUSIC_MEET_MALE_TRAINER << 8) | Bank(Music_MeetMaleTrainer)

Title_Music_PalletTown: db "Pallet Town@"
Title_Music_Pokecenter: db "#MON Center@"
Title_Music_Gym: db "Gym@"
Title_Music_Cities1: db "City 1@"
Title_Music_Cities2: db "City 2@"
Title_Music_Celadon: db "Celadon City@"
Title_Music_Cinnabar: db "Cinnabar Island@"
Title_Music_Vermilion: db "Vermilion City@"
Title_Music_Lavender: db "Lavender Town@"
Title_Music_SSAnne: db "SS Anne@"
Title_Music_MeetProfOak: db "Prof. Oak@"
Title_Music_MeetRival: db "Rival@"
Title_Music_MuseumGuy: db "To The Museum@"
Title_Music_SafariZone: db "Safari Zone@"
Title_Music_PkmnHealed: db "#MON Healed@"
Title_Music_Routes1: db "Route Theme 1@"
Title_Music_Routes2: db "Route Theme 2@"
Title_Music_Routes3: db "Route Theme 3@"
Title_Music_Routes4: db "Route Theme 4@"
Title_Music_IndigoPlateau: db "Indigo Plateau@"
Title_Music_GymLeaderBattle: db "Leader Battle@"
Title_Music_TrainerBattle: db "Trainer Battle@"
Title_Music_WildBattle: db "Wild Battle@"
Title_Music_FinalBattle: db "Final Battle@"
Title_Music_DefeatedTrainer: db "Trainer Victory@"
Title_Music_DefeatedWildMon: db "Wild Victory@"
Title_Music_DefeatedGymLeader: db "Leader Victory@"
Title_Music_TitleScreen: db "Main Title@"
Title_Music_Credits: db "Credits@"
Title_Music_HallOfFame: db "Hall of Fame@"
Title_Music_OaksLab: db "Oak's Lab@"
Title_Music_JigglypuffSong: db "Jigglypuff's Song@"
Title_Music_BikeRiding: db "Bike Riding@"
Title_Music_Surfing: db "Surfing@"
Title_Music_GameCorner: db "Game Corner@"
Title_Music_IntroBattle: db "Title Intro@"
Title_Music_Dungeon1: db "Dungeon 1@"
Title_Music_Dungeon2: db "Dungeon 2@"
Title_Music_Dungeon3: db "Dungeon 3@"
Title_Music_CinnabarMansion: db "Cinnabar Mansion@"
Title_Music_PokemonTower: db "#MON Tower@"
Title_Music_SilphCo: db "Silph Co.@"
Title_Music_MeetEvilTrainer: db "Evil Trainer@"
Title_Music_MeetFemaleTrainer: db "Female Trainer@"
Title_Music_MeetMaleTrainer: db "Male Trainer@"
