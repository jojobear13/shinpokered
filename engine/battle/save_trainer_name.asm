SaveTrainerName:
	ld hl, TrainerNamePointers
	ld a, [wTrainerClass]
	dec a
	ld c, a
	ld b, 0
	add hl, bc
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld de, wcd6d
.CopyCharacter
	ld a, [hli]
	ld [de], a
	inc de
	cp "@"
	jr nz, .CopyCharacter
	ret

TrainerNamePointers:
; what is the point of these?
	dw YoungsterName
	dw BugCatcherName
	dw LassName
	dw wTrainerName
	dw JrTrainerMName
	dw JrTrainerFName
	dw PokemaniacName
	dw SuperNerdName
	dw wTrainerName
	dw wTrainerName
	dw BurglarName
	dw EngineerName
	dw JugglerXName
	dw wTrainerName
	dw SwimmerName
	dw wTrainerName
	dw wTrainerName
	dw BeautyName
	dw wTrainerName
	dw RockerName
	dw JugglerName
	dw wTrainerName
	dw wTrainerName
	dw BlackbeltName
	dw wTrainerName
	dw ProfOakName
	dw ChiefName
	dw ScientistName
	dw wTrainerName
	dw RocketName
	dw CooltrainerMName
	dw CooltrainerFName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName
	dw wTrainerName

YoungsterName:
	db "Youngster@"
BugCatcherName:
	db "Bug Catcher@"
LassName:
	db "Lass@"
JrTrainerMName:
	db "Jr.Trainer♂@"
JrTrainerFName:
	db "Jr.Trainer♀@"
PokemaniacName:
	db "Pokémaniac@"
SuperNerdName:
	db "Super Nerd@"
BurglarName:
	db "Burglar@"
EngineerName:
	db "Engineer@"
JugglerXName:
	db "Juggler@"
SwimmerName:
	db "Swimmer@"
BeautyName:
	db "Beauty@"
RockerName:
	db "Rocker@"
JugglerName:
	db "Juggler@"
BlackbeltName:
	db "Blackbelt@"
ProfOakName:
	db "Prof.Oak@"
ChiefName:
	db "Chief@"
ScientistName:
	db "Scientist@"
RocketName:
	db "Rocket@"
CooltrainerMName:
	db "Cooltrainer♂@"
CooltrainerFName:
	db "Cooltrainer♀@"
