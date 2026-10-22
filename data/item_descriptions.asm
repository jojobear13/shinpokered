; the bag's two lines on each item (engine/menu/item_descriptions.asm), by
; item number from 1; 0 for none (badges, floors, the coin)
ItemDescriptions:
	dw DescMasterBall
	dw DescUltraBall
	dw DescGreatBall
	dw DescPokeBall
	dw DescTownMap
	dw DescBicycle
	dw DescSurfboard
	dw DescSafariBall
	dw DescPokedex
	dw DescMoonStone
	dw DescAntidote
	dw DescBurnHeal
	dw DescIceHeal
	dw DescAwakening
	dw DescParlyzHeal
	dw DescFullRestore
	dw DescMaxPotion
	dw DescHyperPotion
	dw DescSuperPotion
	dw DescPotion
	dw 0 ; BOULDERBADGE
	dw 0 ; CASCADEBADGE
	dw 0 ; THUNDERBADGE
	dw 0 ; RAINBOWBADGE
	dw 0 ; SOULBADGE
	dw 0 ; MARSHBADGE
	dw 0 ; VOLCANOBADGE
	dw 0 ; EARTHBADGE
	dw DescEscapeRope
	dw DescRepel
	dw DescOldAmber
	dw DescFireStone
	dw DescThunderStone
	dw DescWaterStone
	dw DescHpUp
	dw DescProtein
	dw DescIron
	dw DescCarbos
	dw DescCalcium
	dw DescRareCandy
	dw DescDomeFossil
	dw DescHelixFossil
	dw DescSecretKey
	dw DescMistStone
	dw DescBikeVoucher
	dw DescXAccuracy
	dw DescLeafStone
	dw DescCardKey
	dw DescNugget
	dw DescMGene
	dw DescPokeDoll
	dw DescFullHeal
	dw DescRevive
	dw DescMaxRevive
	dw DescGuardSpec
	dw DescSuperRepel
	dw DescMaxRepel
	dw DescDireHit
	dw 0 ; COIN
	dw DescFreshWater
	dw DescSodaPop
	dw DescLemonade
	dw DescSSTicket
	dw DescGoldTeeth
	dw DescXAttack
	dw DescXDefend
	dw DescXSpeed
	dw DescXSpecial
	dw DescCoinCase
	dw DescOaksParcel
	dw DescItemfinder
	dw DescSilphScope
	dw DescPokeFlute
	dw DescLiftKey
	dw DescExpAll
	dw DescOldRod
	dw DescGoodRod
	dw DescSuperRod
	dw DescPpUp
	dw DescEther
	dw DescMaxEther
	dw DescElixer
	dw DescMaxElixer
	dw 0 ; FLOOR_B2F
	dw 0 ; FLOOR_B1F
	dw 0 ; FLOOR_1F
	dw 0 ; FLOOR_2F
	dw 0 ; FLOOR_3F
	dw 0 ; FLOOR_4F
	dw 0 ; FLOOR_5F
	dw 0 ; FLOOR_6F
	dw 0 ; FLOOR_7F
	dw 0 ; FLOOR_8F
	dw 0 ; FLOOR_9F
	dw 0 ; FLOOR_10F
	dw 0 ; FLOOR_11F
	dw 0 ; FLOOR_B4F
	dw DescZinc
	dw DescBlackBelt
	dw DescCharcoal
	dw DescDragonFang
	dw DescHardStone
	dw DescMagnet
	dw DescMiracleSeed
	dw DescMysticWater
	dw DescNevermeltice
	dw DescPinkBow
	dw DescPoisonBarb
	dw DescSharpBeak
	dw DescSilverpowder
	dw DescSoftSand
	dw DescSpellTag
	dw DescTwistedspoon
	dw DescBerry
	dw DescGoldBerry
	dw DescSitrusBerry
	dw DescPrzcureberry
	dw DescMintBerry
	dw DescPsncureberry
	dw DescIceBerry
	dw DescBurntBerry
	dw DescBitterBerry
	dw DescMiracleberry
	dw DescMysteryberry
	dw DescLeftovers
	dw DescQuickClaw
	dw DescKingsRock
	dw DescScopeLens
	dw DescBrightpowder
	dw DescFocusBand
	dw DescLightBall
	dw DescThickClub
	dw DescMetalPowder
	dw DescLuckyEgg
	dw DescAmuletCoin
	dw DescEverstone
	dw DescExpShare
	dw DescSmokeBall
	dw DescCleanseTag
	dw DescStick
	dw DescLuckyPunch
	dw DescChoiceBand
	dw DescChoiceSpecs
	dw DescChoiceScarf
	dw DescLifeOrb
	dw DescEviolite
	dw DescFocusSash
	dw DescMetalCoat
	dw DescBlackglasses
	dw DescFairyfeather
	dw DescDexrepel

DescMasterBall:
	db   "The best BALL. It"
	next "never misses.@"
DescUltraBall:
	db   "A BALL with a high"
	next "catch rate.@"
DescGreatBall:
	db   "A BALL with a good"
	next "catch rate.@"
DescPokeBall:
	db   "A BALL for"
	next "catching #MON.@"
DescTownMap:
	db   "Shows where you"
	next "are in KANTO.@"
DescBicycle:
	db   "Ride it to move"
	next "twice as fast.@"
DescSurfboard:
	db   "Ride the waves"
	next "without SURF.@"
DescSafariBall:
	db   "Only for use in"
	next "the SAFARI ZONE.@"
DescPokedex:
	db   "A high-tech record"
	next "of #MON.@"
DescMoonStone:
	db   "Makes certain"
	next "#MON evolve.@"
DescAntidote:
	db   "Cures a #MON"
	next "of poison.@"
DescBurnHeal:
	db   "Cures a #MON"
	next "of a burn.@"
DescIceHeal:
	db   "Thaws a frozen"
	next "#MON.@"
DescAwakening:
	db   "Wakes up a"
	next "sleeping #MON.@"
DescParlyzHeal:
	db   "Cures a #MON"
	next "of paralysis.@"
DescFullRestore:
	db   "Restores all HP"
	next "and cures status.@"
DescMaxPotion:
	db   "Restores all of a"
	next "#MON's HP.@"
DescHyperPotion:
	db   "Restores 200 HP"
	next "to a #MON.@"
DescSuperPotion:
	db   "Restores 50 HP"
	next "to a #MON.@"
DescPotion:
	db   "Restores 20 HP"
	next "to a #MON.@"
DescEscapeRope:
	db   "Takes you out of"
	next "a cave or dungeon.@"
DescRepel:
	db   "Keeps weak wild"
	next "#MON away: 100.@"
DescOldAmber:
	db   "Holds the genes of"
	next "an old #MON.@"
DescFireStone:
	db   "Makes certain"
	next "#MON evolve.@"
DescThunderStone:
	db   "Makes certain"
	next "#MON evolve.@"
DescWaterStone:
	db   "Makes certain"
	next "#MON evolve.@"
DescHpUp:
	db   "Raises the base"
	next "HP of a #MON.@"
DescProtein:
	db   "Raises the base"
	next "ATTACK stat.@"
DescIron:
	db   "Raises the base"
	next "DEFENSE stat.@"
DescCarbos:
	db   "Raises the base"
	next "SPEED stat.@"
DescCalcium:
	db   "Raises the base"
	next "SPCL.ATK stat.@"
DescRareCandy:
	db   "Raises a #MON"
	next "by one level.@"
DescDomeFossil:
	db   "The fossil of an"
	next "old sea #MON.@"
DescHelixFossil:
	db   "The fossil of an"
	next "old sea #MON.@"
DescSecretKey:
	db   "Opens the door of"
	next "CINNABAR's GYM.@"
DescMistStone:
	db   "Makes all of a"
	next "#MON's IVs 31.@"
DescBikeVoucher:
	db   "Trade it for a"
	next "BICYCLE.@"
DescXAccuracy:
	db   "In battle, moves"
	next "don't miss.@"
DescLeafStone:
	db   "Makes certain"
	next "#MON evolve.@"
DescCardKey:
	db   "Opens the doors"
	next "in SILPH CO.@"
DescNugget:
	db   "A gold nugget."
	next "Sells for a lot.@"
DescMGene:
	db   "Rerolls a #MON's"
	next "IVs to 16 or more.@"
DescPokeDoll:
	db   "Use it to run from"
	next "a wild #MON.@"
DescFullHeal:
	db   "Cures any status"
	next "problem.@"
DescRevive:
	db   "Revives a fainted"
	next "#MON: half HP.@"
DescMaxRevive:
	db   "Revives a fainted"
	next "#MON: all HP.@"
DescGuardSpec:
	db   "Stops stat drops"
	next "for 5 turns.@"
DescSuperRepel:
	db   "Keeps weak wild"
	next "#MON away: 200.@"
DescMaxRepel:
	db   "Keeps weak wild"
	next "#MON away: 250.@"
DescDireHit:
	db   "Raises the chance"
	next "of critical hits.@"
DescFreshWater:
	db   "Water with lots of"
	next "minerals. 50 HP.@"
DescSodaPop:
	db   "A fizzy soda."
	next "Restores 60 HP.@"
DescLemonade:
	db   "A sweet drink."
	next "Restores 80 HP.@"
DescSSTicket:
	db   "A ticket for the"
	next "S.S.ANNE.@"
DescGoldTeeth:
	db   "The SAFARI ZONE"
	next "WARDEN's teeth.@"
DescXAttack:
	db   "In battle, raises"
	next "ATTACK.@"
DescXDefend:
	db   "In battle, raises"
	next "DEFENSE.@"
DescXSpeed:
	db   "In battle, raises"
	next "SPEED.@"
DescXSpecial:
	db   "In battle, raises"
	next "SPCL.ATK.@"
DescCoinCase:
	db   "Holds up to 9999"
	next "GAME CORNER COINs.@"
DescOaksParcel:
	db   "A parcel for"
	next "PROF.OAK.@"
DescItemfinder:
	db   "Finds hidden items"
	next "nearby.@"
DescSilphScope:
	db   "Shows what GHOSTs"
	next "really are.@"
DescPokeFlute:
	db   "Wakes sleeping"
	next "#MON.@"
DescLiftKey:
	db   "Runs the ROCKET"
	next "HIDEOUT's lift.@"
DescExpAll:
	db   "The whole team"
	next "gets EXP. Points.@"
DescOldRod:
	db   "Fish for #MON"
	next "in the water.@"
DescGoodRod:
	db   "A better rod for"
	next "fishing.@"
DescSuperRod:
	db   "The best rod for"
	next "fishing.@"
DescPpUp:
	db   "Raises the max PP"
	next "of a move.@"
DescEther:
	db   "Restores 10 PP"
	next "to one move.@"
DescMaxEther:
	db   "Restores all PP"
	next "to one move.@"
DescElixer:
	db   "Restores 10 PP"
	next "to every move.@"
DescMaxElixer:
	db   "Restores all PP"
	next "to every move.@"
DescZinc:
	db   "Raises the base"
	next "SPCL.DEF stat.@"
DescBlackBelt:
	db   "Held: powers up"
	next "FIGHTING moves.@"
DescCharcoal:
	db   "Held: powers up"
	next "FIRE moves.@"
DescDragonFang:
	db   "Held: powers up"
	next "DRAGON moves.@"
DescHardStone:
	db   "Held: powers up"
	next "ROCK moves.@"
DescMagnet:
	db   "Held: powers up"
	next "ELECTRIC moves.@"
DescMiracleSeed:
	db   "Held: powers up"
	next "GRASS moves.@"
DescMysticWater:
	db   "Held: powers up"
	next "WATER moves.@"
DescNevermeltice:
	db   "Held: powers up"
	next "ICE moves.@"
DescPinkBow:
	db   "Held: powers up"
	next "NORMAL moves.@"
DescPoisonBarb:
	db   "Held: powers up"
	next "POISON moves.@"
DescSharpBeak:
	db   "Held: powers up"
	next "FLYING moves.@"
DescSilverpowder:
	db   "Held: powers up"
	next "BUG moves.@"
DescSoftSand:
	db   "Held: powers up"
	next "GROUND moves.@"
DescSpellTag:
	db   "Held: powers up"
	next "GHOST moves.@"
DescTwistedspoon:
	db   "Held: powers up"
	next "PSYCHIC moves.@"
DescBerry:
	db   "Held: restores 10"
	next "HP at half HP.@"
DescGoldBerry:
	db   "Held: restores 30"
	next "HP at half HP.@"
DescSitrusBerry:
	db   "Held: restores 1/4"
	next "HP at half HP.@"
DescPrzcureberry:
	db   "Held: cures"
	next "paralysis.@"
DescMintBerry:
	db   "Held: wakes the"
	next "#MON up.@"
DescPsncureberry:
	db   "Held: cures"
	next "poison.@"
DescIceBerry:
	db   "Held: cures a"
	next "burn.@"
DescBurntBerry:
	db   "Held: thaws the"
	next "#MON out.@"
DescBitterBerry:
	db   "Held: cures"
	next "confusion.@"
DescMiracleberry:
	db   "Held: cures any"
	next "status problem.@"
DescMysteryberry:
	db   "Held: restores 5"
	next "PP to a used move.@"
DescLeftovers:
	db   "Held: restores a"
	next "little HP a turn.@"
DescQuickClaw:
	db   "Held: sometimes it"
	next "moves first.@"
DescKingsRock:
	db   "Held: hits may"
	next "make foes flinch.@"
DescScopeLens:
	db   "Held: raises the"
	next "critical-hit odds.@"
DescBrightpowder:
	db   "Held: lowers the"
	next "foe's accuracy.@"
DescFocusBand:
	db   "Held: may endure a"
	next "hit that would KO.@"
DescLightBall:
	db   "Held by PIKACHU:"
	next "doubles its power.@"
DescThickClub:
	db   "CUBONE, MAROWAK:"
	next "doubles ATTACK.@"
DescMetalPowder:
	db   "Held by DITTO:"
	next "raises DEFENSE.@"
DescLuckyEgg:
	db   "Held: gains more"
	next "EXP. Points.@"
DescAmuletCoin:
	db   "Held: doubles the"
	next "prize money won.@"
DescEverstone:
	db   "Held: stops it"
	next "from evolving.@"
DescExpShare:
	db   "Held: gets EXP."
	next "without battling.@"
DescSmokeBall:
	db   "Held: always runs"
	next "from wild #MON.@"
DescCleanseTag:
	db   "Held by the lead:"
	next "fewer wild ones.@"
DescStick:
	db   "FARFETCH'D: more"
	next "critical hits.@"
DescLuckyPunch:
	db   "CHANSEY: more"
	next "critical hits.@"
DescChoiceBand:
	db   "Held: ATTACK×1.5,"
	next "but one move only.@"
DescChoiceSpecs:
	db   "Held: SPCL.ATK×1.5"
	next "but one move only.@"
DescChoiceScarf:
	db   "Held: SPEED×1.5,"
	next "but one move only.@"
DescLifeOrb:
	db   "Held: stronger"
	next "moves, costing HP.@"
DescEviolite:
	db   "Held: unevolved"
	next "#MON take less.@"
DescFocusSash:
	db   "Held at full HP:"
	next "survives a KO hit.@"
DescMetalCoat:
	db   "Held: powers up"
	next "STEEL moves.@"
DescBlackglasses:
	db   "Held: powers up"
	next "DARK moves.@"
DescFairyfeather:
	db   "Held: powers up"
	next "FAIRY moves.@"
DescDexrepel:
	db   "Keeps away wild"
	next "#MON you own.@"
