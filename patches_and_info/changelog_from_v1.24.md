**New features exclusively for the master branch**

- Added Debug Stat Reset feature

- PokeDex Area enhancements
  - The AREA function of the PokeDex now takes the Super Rod into account
  - It will also notify you if the Pokemon you are referencing is available on the currently loaded map
  - If available on the current map, it will notify you if it can be found by walking, surfing, or by super rod
  - The Cerulean Cave is an "unknown dungeon" so...
    - Nest icons will not display for this location
    - But the notification for the current map will still function

- Psywave has been enhanced with a hidden mechanic
  - Psywave will now roll for damage multiple times and use the best roll
  - The number of times that damage is rolled is based on the target's current HP with more HP causing more re-rolls

- Certain moves now affect catching mechanics if known by your active pokemon in battle
  - Razor Wind & Skull Bash - additive +10 to catch rate per toss of a non-safari ball
  - Roar & Whirlwind - additive +20 to catch rate per toss of a non-safari ball
  - Take Down - improves the ball factor of non-safari balls by 2
  - Egg Bomb - improves the ball factor of non-safari balls by 2 and additive +10 to catch rate per toss of a non-safari ball

- The battle clauses between link players now sync and are applied during battles

- The stat displays of the active pokemon in battle will display its current-time stats instead of its unmodified stats

- Can move items to the non-active bag space
  - Place the cursor is over an item in the bag menu
  - Press and hold LEFT or RIGHT then press START to send it to the extra bag space

- After buying the Magikarp from the man in the Mt. Moon pokemon center, he will serve as a move tutor
  - This is a throwback to certain Japan-only event pokemon giveaways
  - Talk to him with Magikarp at the top of your party, and he will offer to teach it Dragon Rage for 5000 yen.
  - Talk to him with Fearow or Rapidash at the top of your party, and he will offer to teach it Pay Day for 1000 yen.
  - Talk to him with Pikachu at the top of your party that has an empty move slot, and he can teach it Fly for 2000 yen.

- Psyduck Learning Amnesia  
  - You must first have 151 pokemon registered as owned in your pokedex.  
  - Place a Psyduck in your 1st party slot then go talk to the Psyduck in Mr. Fuji's house.  
  - It will now try to learn the Amnesia move.  

- Undocumented secret move tutors; these are considered cheats and are just for fun
  - Lickitung can learn Lick via the move-relearner in Saffron City
  - Flareon can learn Agility and Low Kick from the Karate Master
  - Hitmonlee can learn Agility and Quick Attack from the Pikachu in the Vermilion Fan Club
  - Moltres can learn Flamethrower from Blaine
  - Pidgeot and Pidgeotto can learn Drill Peck from the Fearow in the Route 16 house
  - Ninetales can learn Hypnosis from Mr. Psychic in Saffron City
  - Vileplume, Gloom, and Oddish can learn Leech Seed from Bill
  - Examine the Omanyte sign in Fuschia city with one of these pokemon at the top of your party
    - Omastar will learn Rock Slide
	- Kabutops will learn Mega Drain
	- Aerodactyl will learn Earthquake
  - Ninja Scyther: Scyther can get a "ninja form" by defeating Koga as your sole party member
    - Will exchange its Flying type for Ghost type
	- Koga becomes a move tutor and can teach it a selection of new moves:
	  - Confuse Ray
	  - Hypnosis
	  - Light Screen
	  - Pin Missile
	  - Rolling Kick


---
**New adjustments exclusively for the master branch**

- Shiny pokemon gain a 4x multiplier for the coin guy in celadon hotel and selling to the game corner chief

- If active, the shimmer will always manifest on the applicable pokemon of Bruno, Agatha, and the Karate Master
- The shimmer transformation's text box no longer requires a button prompt to scroll through
- The shimmer adds double level to the special stat exclusively for Hitmonchan

- Karate Master's pokemon increased from level 37 to 38
- Made the karate dojo master act like a special trainer
- Champion Rival's charizard swaps out swords dance for fly
- Giovanni gym battle exchanges rhyhorn for kangaskhan
- Some Cueball teams include Pinsir
- Biker teams can now include Beedrill, Magmar, an Electrode, and more Voltorbs

- Failure to teach a temp field move will now prompt the player to abandon learning it
- All five field moves a pokemon can have will now be displayed in the field move menu.

- The bush that blocks route 9 has been replaced by a blocking event

- Cubone rarity in rock tunnel 2nd floor increased from 1.2% to 6.3%.
- Farfetchd rarity on route 12 increased from 4.3% to 6.3%.
- Farfetchd rarity on route 13 increased from 1.2% to 4.3%.
- Boosted Eevee encounter rate to 5.5%

- The player can now choose whether or not to generate a new Trainer ID when selecting New Game Plus.

- Starting a new game will keep the hard mode off, but now default to fast text speed

- Wild pokemon randomizer lists have been slightly adjusted.
- Talking to the girl in Oak's lab allows the player to generate a new randomization seed value.  
- Talking to the girl in Oak's lab prompts the player if full randomization is preferred.  

- Trainer level scaling has been dampened outside of hard mode
  - It is now based on a weighted average for regular trainers in normal difficulty
  - Gym leaders always use the absolute level scaling regardless of difficulty
- If level scaling is active, traded pokemon will not become disobedient under the normal badge limits.

- Rebalanced a few TMs across pokemart inventories
- Water Gun TM has been replaced by a super repel in Mt. Moon, and it is now found in the Pewter Museum

- Added hidden moon stone to route 4 guarded by the Lass that is near the Cerulean Cave entrance

- Turning the nuzlocke mode on will not reset your difficulty options
- Assuming you start a new save, Nuzlocke mode now knows if you're early in the game and have no access to pokeballs

- Altered the level-up move lists of Starmie and Raichu to work better with Misty and Surge


---
**Project-related fixes exclusively for the master branch**

- Fixed shiny clause so that it is now working in nuzlocke mode
- Extended shiny mercy to tower ghosts, ghost marowak, and old man battle

- Fixed a problem where the Trapping Move Clause reads the move effect from the previous round instead of the current round

- Fixed daycare sometimes prompting to learn the same move twice
- Fixed a problem with undergoing multiple evolutions when taking a pokemon out of the daycare
- Sprites will no longer cover the move list when forgetting moves at the daycare

- Fixed an issue where enemy level-up moves were being skipped

- Fixed full randomization option not activating
- Wild pokemon randomizer will no longer swap a species with itself

- Fixed special HUD symbols displaying during the ghost marowak encounter
- Fixed a minor bug when blacking out of the SS Anne post-game tournament
- Fixed debug damage display not updating properly for some static damage moves

- Girl trainer on route 8 has text adjusted to reflect having a Clefable
- Adjusted some text for post-game world state.
- Minor text edit for SS Anne npc in post-game.
- Tweaked NPC text for extra options
- Increased text delay by half second on area pokedex screen
- Added some proper rematch text instead of reusing the slot machine strings

- The rocket grunt in Cerulean city has a minor fix to the timing of when its sprite disappears

- Fixed the cloning feature in Cinnabar Lab handling the charging of money incorrectly

- Minor fix for Itemfinder when there are multiple hidden items on screen.

- Fixed some oversights with the joke dittos that can be fished in unknown dungeon 3
  - Cannot toss balls if the wild pokemon is above the level cap
  - Made ReadSuperRodData a predef and made it so the Unknown Dungeon 3 fishing data reverts if the randomizer is on

- Fixed serial timer problem with syncing battle clauses over link cable


---
**Project-related fixes exclusively for the lite branch**

None


---
**New features and adjustments for both branches**

- Enhanced GBC color has been added to the extra options menu that colorizes the overworld to a further degree

- Press SELECT on the extra options menu to get a sound test menu
  - Listen to the game's musical tracks
  - They even continue to play once you've backed out of the options menu

- Pressing B on the main battle menu places the cursor over RUN

- Added an emulator check that tests the timing of memory modification opcodes

- Trainers will not use non-healing items if they or the player are at low HP, making them more aggressive
- AI will not switch if its HP is below 25% as it's usually not worth it
- AI Layer 3 will no longer run on the turn a player switches in order to keep battle information from the AI
- On AI Layer 1, biased preference for exploding more towards lower HP
- Rage is slightly discouraged in AI Layer 1

- All the extra options on the option menu have been moved to their own separate menu

- The VS pokeballs in link battles have defined palettes now instead of whatever is in memory
- If the female trainer option is compiled, a female link partner will have corresponding graphics

- Increased the speed of the HP bar animation
- Made the trainer pokeballs red in the battle HUD

- The message for substitute taking damage now only displays after the first attack of a multi-attack move
- Multi-attack moves display effectiveness only on first attack instead of the last attack
- Twineedle does not print redundant messages like other multi-hit moves

- Game now keeps the status of the gamma shader with the save on file

- Oak's five free pokeballs are now obtained based on never having caught a pokemon with a ball

- Moved NPC in celadon prize house two spaces to the right

- Adjusted the parity of in-game trades across versions

- Moved CalcStat function out of home bank to free up space
- Status Screen now prints types from party struct data instead of species header
- Increased the speed of the LoadCurrentMapView function
- Engine now supports up to 255 predefs instead of 127
- The menu for field moves can now support up to five field moves for developer purposes.


---
**New fixes for original game bugs for both branches**

- Fixed typed effectiveness being applied the wrong way to static damage moves
- Disable and static damage moves will not crit or show super/not very effectiveness
- Fixed Psywave symmetry
- Fixed desync problem during link battles with Rage, Thrash, and trapping moves
- Fixed Full Restores undoing burn/paralysis stat changes when healing a non-active pokemon
- Added overflow protection to super-effective damage calculation

- Fixed a bug where interacting with a hidden item or a bookshelf when a trainer spots the player will freeze the game
- Fixed a bug where the no-battle bit in Mt. Moon area 3 won't clear if using dig/teleport/escape rope
- Fixed a bug catcher on route 9 being able to walk onto a ledge
- Can no longer fish or surf using the right wall corner tile on the SS Anne.
- Fixed incorrect sign text in safari area 1
- Adjusted some city names on signs
- Fixed missing punctuation in Oak's pokedex evaluation
- Lance and the player will face each other when speaking.
- Fixed an oversight where the player does not face the Viridian Gym door during the message saying it's locked
- Some hidden Game Corner coins can now be accessed when they previously were not.

- Fixed an issue with the title menu becoming dark when saving in rock tunnel
- Fixed rock tunnel darkness affecting option menu
- Fixed wrong color palette being loaded for player back sprite tiles during screen shake animation
- Fixed graphical display bug when talking to the 15th sprite on a map
- Fixed a bug where cutting grass loads the wrong palette for the animation
- Fixed a minor cursor error on the town map when in route 1 or the power plant

- The 'bwoop' sfx now plays when registering pokemon with short names like "Onix"
- Fixed a bug in Rocket Hideout 1 map where a SFX plays every time the map loads
- Added missing sfx when leaving the trainer card screen
- Fixed a rare infinite loop caused by a text SFX playing right at the end of an audio fadeout

- Fixed text error in Vermilion gym referencing the bird type instead of flying type


---
**Project-related fixes for both branches**

- Fixed a bug in the AI that caused trainers to use poison-effect moves inaccurately

- Optimized smooth fades to eliminate graphical jank during battle black-outs
- Optimized the GBC smooth fading a little bit more
- Fades in or out to white in GBC mode with gamma shader enabled will no longer have a frame of incorrect color
- Fixed wrong color for move animation when it comes after self-inflicted confusion damage
- Spinner tiles animate properly without resorting to vblank-induced slowdown
- Toggling the gamma shader in the extra options menu now automatically updates the palette
- Option menu graphics tweak
- Fixed an issue with NPCs overlapping menu and text boxes
- Fixed the wrong tiles for the border of the pokedex diploma

- The move Transform now decrements PP properly when used by the AI recursively

- Reworked the prize mon level function and also synchronized the DVs for gift pokemon that are added to party or box
- Fixed a serial timer problem with the link cable version verification

- Fixed a text bug on multi-hit moves
- Corrected the text in green & red-jp pokedex entries

- Made japanese patches more accurate to the original, particularly the timing of the intro

