TypeNames:

	dw .Normal
	dw .Fighting
	dw .Flying
	dw .Poison
	dw .Ground
	dw .Rock
	dw .Bird
	dw .Bug
	dw .Ghost
	dw .Steel

	dw .Normal
	dw .Normal
	dw .Normal
	dw .Normal
	dw .Normal
	dw .Normal
	dw .Normal
	dw .Normal
	dw .Normal
	dw .Normal

	dw .Fire
	dw .Water
	dw .Grass
	dw .Electric
	dw .Psychic
	dw .Ice
	dw .Dragon
	dw .Dark
	dw .Fairy

.Normal:   db "NORMAL@"
.Fighting: db "FIGHTING@"
.Flying:   db "FLYING@"
.Poison:   db "POISON@"
.Fire:     db "FIRE@"
.Water:    db "WATER@"
.Grass:    db "GRASS@"
.Electric: db "ELECTRIC@"
.Psychic:  db "PSYCHIC@"
.Ice:      db "ICE@"
.Ground:   db "GROUND@"
.Rock:     db "ROCK@"
.Bird:     db "TYPELESS@"	;joenote - Bird type will be used as a neutral typless dummy type for Struggle
.Bug:      db "BUG@"
.Ghost:    db "GHOST@"
.Dragon:   db "DRAGON@"
.Steel:    db "STEEL@"
.Dark:     db "DARK@"
.Fairy:    db "FAIRY@"
