**New features exclusively for the master branch**
- Added nuzlocke mode

- Hold SELECT and press START while on the bag menu or PC item box menu to auto-sort your items

- The girl in Oak's lab toggles a built-in randomizer for wild pokemon and your starters
  - Shuffles all pokemon that can be gained through walking, surfing, fishing, or from the game corner
  - If activated early enough, your starter pokemon options are shuffled as well
  - Randomizes using a saved seed value, so the shuffled order is always preserved between play sessions
  - A new random seed is generated upon each new game
  - There are three pokemon lists based on base-stat-total; A, B, and C tiers
  - Pokemon are only shuffled within their own list in order to maintain some modicum of balance
  - Scripted events are unaffected (gifts, in-game trades, static encounters, etc)
  - The game's five legendary pokemon are excluded from randomization
  - The AREA feature of the pokedex automatically adjusts to show the new pokemon locations

- Relocated one of the rocket grunts in celadon city, and he now sells bulk coins in the post-game
  
- Trade evolutions no longer evolve at level 45
- Trade evolutions now alternately evolve with a stone at a certain level with some new hinting NPC text
  - Kadabra
    - Use a moon stone at level 35
	- Hinted at by a NPC in the Pewter Museum that comments on the moon stone
  - Haunter
    - Use a thunder stone at level 35
	- Hinted at by the Lavender Town NPC that asks if you believe in ghosts
  - Graveler
    - Use a fire stone at level 35
	- Hinted at by a NPC on Cinnabar Island that talks about the mansion
  - Machoke
    - Use a leaf stone at level 35
	- Hinted at by a house NPC in Pewter City that talks about trainers teaching pokemon

- A new NPC is in the north-south underground path for post-game mirror matches

- Added a new Clause Brother for activating the Trapping Move Clause
  - A counter tracks if the player or the opponent use trapping moves like Wrap multiple times in a row 
  - The counter increments only if a trapping effect move is selected to be used and it does not miss
  - After the counter has incremented to 2, 
    - selecting a trapping effect move additional times will make the move to go 2nd in the round 
	- this is the same priority as the move Counter
  - The counter only gets reset by switching or using a move that does not have the trapping effect 
  - Reseting the counter will restore normal priority to trapping effect moves.

- Added a fifth Clause Brother for the hyper beam clause; hyper beam will recharge if it KOs the opponent

- A new drink stand on the route 19 beach sells vending machine drinks

- Paras is gifted in the Route 2 house in case the player has no pokemon that can learn Cut

- Unused beedrill trade has been restored and placed on Route 22

- Added cloning and gene splicing

- Added shiny mercy
  - When a player encounters an AI trainer shiny pokemon, the next wild encounter will be shiny
  - Side effect: Because trainer 'mons can't be shiny in regular difficulty, hard mode gives more chances to find wild shinies

- Added new superboss at the seafoam shore (activated the same as the existing missingno fight)
- Beating the seafoam missingo battle will certify you as a pokemon master on your diploma

- Show Mewtwo to Mr. Fuji after beating the Elite 4 for a M.GENE

- Added Bill's secret garden behind his house
  - Put Mew in your top spot and show Bill to gain access
  - You will encounter the starter pokemon plus some other rarer pokemon
  - Shiny rates are 1-in-128 in this area

- Added the MIST STONE
  - It will max-out all the stat exp of the lvl > 30 pokemon on which it is used
  - If all the stat exp is already at max, then it will set all the DVs to maximum instead

- Defeat Lance with a Dragonite in your top spot and it will be given a catch rate of 168
  - Dragonite's cry will play to confirm that this has happened
  - You can swap with another Dragonite in your party and listen to his after-battle text again to repeat the process
  - In this community patch, a dragonite with this catch rate can be taught Fly via HM
  - This catch rate makes it hold a gorgeous box if transferred to Gen 2
  - Likewise, a dragonite holding a gorgeous box can learn fly if transferred into this community patch

- Implemented the old Down+B urban legend for pokeballs as a cheat code
  - The timing is different. You have to hold Down+B before the "[PLAYER] used [ITEM]" text finishes printing.
  - If successful, the ball tossed will be twice as effective as normal

- Scaled back fishing, reduced its randomness, and made it more map-dependent
- When using the old rod, press and hold B within about 1 second to always hook a magikarp

- Improved itemfinder function
  - If an item is detected, it will play 1 to 3 chimes depending on how close it is (more chimes means closer to the item).
  - Lines will point in the direction of the item and flash with the chimes.
  - If the player is right on top of the item, no lines will show and the chime till play four times.
  - If the SELECT button is held while selecting to USE the itemfinder, then the original itemfinder function is used.

- Added spaceworld-style trainer back sprites for consistency with the spaceworld 'mon back sprites 
- Blue-JP has spaceworld-style back sprites, and a corresponding _origback patch has been added

- The silhouette effect at the start of battle now displays when playing on a DMG gameboy

- Recalibrated the experience gain at the daycare
- the daycare lets you select moves to forget (if any) upon retreiving your pokemon
- Retrieving a daycare pokemon that could have evolved via level will trigger evolution and learn any missed-out moves
- Added a PC to the daycare
- The daycare can now support two evolutions back-to-back

- Teaching a TM as a field move (Dig/Teleport) no longer consumes the TM

- Added visual indicator when swapping bag space

- Tweaked a flag for shinies so it can be used as a debugging toggle

- Organized the female trainer code to be activated via assembler tags in the makefile (for easy reference)

- Added max revives to post-game shop on celadon mart 3f
- Cerulean mart sells escape rope per Yellow version
- Fuschia mart sells hyper potions per Yellow version
- Added a hidden max revive in celadon city
- Added a hidden super potion in celadon city
- Added a hidden moon stone in diglett's cave
- Added a hidden nugget in diglett's cave
- Added hidden potion on route 22
- Additional hidden potion in viridian city
- Added two hidden repels to pewter city
- Added a hidden great ball and pokedoll on route 6
- Added hidden max revive on route 11
- Added hidden ultra ball on route 8

- Lance now has 2 hyper potions per pokemon like the rest of the elite 4
- The Rival battles from the SS Anne through Pokemon Tower use super potions
- The Rival battles after Pokemon Tower and up through Route 22 2nd-round use hyper potions
- The Champion can use Full Heals in response to a status effect with a 25% chance
- All trainers that use any kind of potion now use it with a 50% chance if their HP is low enough
  - Gym Leaders and mid-game Rival: below 1/5th total
  - Elite-4 and Champion: below 1/3th total

- Added "The Shimmer", a cheat feature for those who want viability when using certain low-regarded pokemon.
  - Toggled ON/OFF via the glass pokeball decoration in the rival's house.
  - Pokemon Eligible: EKANS, CATERPIE, METAPOD, WEEDLE, KAKUNA, ZUBAT, PSYDUCK, PARAS, PONYTA, RATTATA, SANDSHREW, HORSEA, GOLDEEN, VENONAT, JIGGLYPUFF, ARBOK, BEEDRILL, BUTTERFREE, DITTO, FARFETCHD, GOLBAT, GOLDUCK, HITMONCHAN, LICKITUNG, ONIX, PARASECT, PINSIR, PORYGON, RAPIDASH, RATICATE, SANDSLASH, SEADRA, SEAKING, VENOMOTH, WIGGLYTUFF
  - The shimmer factor appears randomly and secretly, and is more likely to occur if you favor sending out eligible 'mons.
  - The shimmer only manifests in 'mons that are fully evolved, even if their pre-evos gained the secret shimmer factor.
  - When the shimmer manifests as a 'mon gets sent out, that 'mon gets a large boost to stats that are low-to-poor.
- Technical details of the shimmer
  - A 'mon eligible for shimmer that is sent out, either by player or enemy trainer, can get the shimmer factor.
  - The chance of getting the shimmer factor is 1-in-256 per send-out, rewarding a player that uses the 'mon frequently.
  - The odds increase by +(1-in-256) per 2048 HP-StatExp that the sent-out pokemon has, encouraging player investment.
  - The shimmer factor is defined via the pokemon's catch rate byte and is a value of $6D (held Miracle Berry in Gen-2).
  - The manifestation of the shimmer boosts one-to-four of a 'mons unmodified stats.
	- If 3/8ths of an unmodified stat is less than the mon's level, then the level value is added to that stat.
    - Stats that can be boosted are: attack, defense, speed, or special.


---
**community patch-related fixes exclusively for the master branch**
- Fixed gift pokemon not having above-average DVs if sent to the box
- Adjusted Oak's pokemon moves
- Fixed text overlap for trainer Seiga
- The static wild encounters (voltorbs and legendaries) now respond to the Chansey cheat for shiny hunting
- Fixed an issue where the shiny animation has the wrong palette for the opponent on the GBC
- Fixed an oversight to make it so 648 stat exp / lvl function maxes out at lvl 100
- RemoveItemByID is now able to remove items from the backup bag space
- Repels can no longer waste the mew encounter
- Fixed bug in low HP alarm: Some sfx no longer get cut off when the player is at low HP
- Holding start or select will no longer print strange HP numbers when not on the status screen
- Decreased time to encounter missingno by an exponential amount
- Fixed a scripting error on route 20
- Removal of the limits on vitamins in the post-game now only applies to pokemon lvl > 30
- Adjusted the level-up moves of starmie, cloyster, poliwrath, and exeggcutor for legality with gen-2 time-capsule
- Enemy trainer level scaling biases the levels upwards for determining if a pokemon should be evolved
- Strength hotkey requires facing a boulder to activate
- Trapping moves no longer apply a speed penalty
- If trainer scaling is on, you do not need to beat the 1st route 22 rival solo to get oak's pokeballs
- Fixed an issue with the level scaling feature that inadvertantly biased non-special trainers to higher levels
- Fixed a problem where the champion whould not work with level scaling
- Fixed a minor bug when forfeiting a rival battle


---
**Project-related fixes exclusively for the lite branch**
- Cleaned up compiler tags and made it easy to compile with spaceworld-style sprites
- Female trainer can be activated by compiling with the _FPLAYER tag
- TMs and HMs have their names determined by a list now
- Fixed the wrong text pointer in vermilion city


---
**New features and adjustments for both branches**
- Decoupled the harder difficulty to its own option bit and added the hard mode to the Lite branch
  - Pressing RIGHT while the cursor is in the BATTLE STYLE box will toggle the feature on/off
  - Contrasting this, pressing LEFT will let you select a battle style without toggling difficulty
  
- Hard mode adjustments
  - Trainer stat exp has been re-scaled to be more realistic to attainable amounts per level
  - No longer gives an exp bonus
  - Critical hit chance in non-link battles use the Stadium 1 formula
  - Oak's pokeballs will be upgraded to great balls if you beat the route 22 rival in hard mode
  - Wild pokemon DVs get 1 re-roll each if less than 4, biasing them upwards a little bit
  - Trainers now roll their DVs twice and use the better result
  - Only boss trainers (giovanni, elite 4, gym leaders, later-game rival) cannot have DVs below 8 in hard mode

- Vanilla Options Reset: Deactivates all special options (such as in preparation to update to a new patch)
  - go to the start menu and put the cursor on the top option (usually POKEDEX)
  - press and hold UP on the d-pad (the cursor will now be on EXIT)
  - while continuing to hold UP, press and hold SELECT
  - while continuing to hold those two buttons, press B
  - the start menu should close and you will hear a jingle confirming that the option reset worked
	
- Debug Damage Display: Damage values will be displayed in battle as the UI updates as a debug cheat
  - Toggled on/off the same way as the softlock warp, but by using 'A' instead of 'B'.
  - Zero damage is not displayed
  - Damage is not displayed if either pokemon has zero HP remaining

- Press and hold A+SELECT at the title screen to print the current RNG seed at the main menu

- Switched over to the xor-shift method of RNG
- If a zero-value random seed is detected, a new random seed gets generated using the original DIV register method

- Gamma shader is now 23% faster thanks to optimizations by easyaspi314

- The 60fps mode has better performance when playing in GBC-mode
  - Does this by using the double-speed feature of the GBC's processor 
  - Uses more battery as a trade-off
- Improved fade-in and fade-out to black/white transitions when playing on GBC in 60FPS mode
  
- Adjustments to multi-attack moves animation and messaging to improve battle flow
  - Multi-attack moves only print the effectiveness message after the last attack
  - 2-attack moves do not print "hit 2 times" because its obvious that they always hit twice
  - Multi-attack moves hide the substitute sprite on the first attack and only restore it after the last attack
  - Twineedle is unaffected by all this due to how it swaps out its effect on the fly to a poison side-effect
  
- Added optimizations to how OAM data is prepared so that overworld sprites wobble less

- DelayFrame now manualy calls VBlank if it runs while the LCD is disabled

- Added community patch version tracking for save files
  - It's a single byte in the save file that gets incremented each version
  - If the save byte does not match, the player is automatically warped back to Pallet Town
  - Helps prevent crashes and glitches when updating an older save file
- You will now be given the choice to warp if the community patch version does not match

- If on GBC, intitializing options in a New Game turns 60 fps ON

- In GBC-mode, when a pokemon is caught, the resting ball now has a defined color
- Tossing pokeballs have color in GBC mode

- Increased the maximum game clock to 32767 hours

- Using X-Accuracy with a OHKO move now allows it to hit faster opponents
- HP-UP item now preserves your HP ratio

- The position of both switches in Vermilion Gym are now determined at the same time
- The switches in Vermilion Gym can now be discovered independently from one another
- Switches in Vermilion Gym will now properly take into acount vertical adjacents
- Restored unused text in the vermilion gym puzzle for finding the 2nd switch

- Daycare allows HM moves on entered pokemon

- Green and Red-JP have the original front sprites for fossil kabutops and fossil aerodactyl
- Green and Red-JP have the original text box corners 
- Restored intro "Presents" for all builds
- Adapted the japanese title screen logo, sfx, and motion for the jp builds
- Re-added the reference to the Kanto region in the JP translation
- Restored SHOP and POKE building tiles in Blue-JP
- SGB borders for JP versions are restored (with fixed centering for text)
- Added more text corrections for JP versions
- Added sfx variations unique to JP versions
- Swapped a trade NPC to a gentleman in Green and RedJP
- Restored the saucy innuendo for the Nugget bridge dialogue in the jp builds
- Restored the religious text in the Pewter museum in the jp builds
- Adjusted intro and title screen and palettes slightly in JP red & green for accuracy

- Fixed pokemon category translation: "Rat" to "Mouse"
- Fixed pokemon category translation: "Shellfish" to "Shell"
- Fixed translation: Route 14 trainer's comment about the legendary birds
- Fixed text giving the wrong description of guard spec.
- Fixed woman on silph co 10F having a blank line in her text 

- The function that shows the dex entry for starter pokemon is now more robust
  - It now works for any pokemon (like if the starters are changed or randomized)
  - It keeps a backup of the pokedex-owned flags instead of erasing them
  - Removed the unused Ivysaur flag

- The female trainer pic will now display on the diploma if applicable

- AI can now handle fly/dig loops between the two pokemon
- Adjusted some AI anti-spam for status moves
- AI switch scoring applies an extra penalty for possibly switching a pokemon into a super-effective move
- AI layer 1: If the player used and item or switched, AI is blind to the player's sleep counter when considering dream eater
- AI layer 3 will slightly discourage a move 25% of the time if it hits neutral with no STAB
  - Wherein a special move is being used on a 'mon with greater attack than special stat
  - Wherein a physical move is being used on a 'mon with greater special than attack stat
- AI layer 3: The enemy is blind to the player type if considering a poisoning effect move and the player just switched
- AI layer 3: There is a 90.625% chance per damaging move that AI is blind to player type after player switches
  - Prevents situations where AI will always pick the ideal move against a switch-in
  - 'Blind' in this case means the AI will act as if the move being considered has neutral effectiveness
  - The AI might still favor a STAB move or a move that works better with its own stats

- Withdrawing or depositing a key item from/to the player's PC will default its quantity to 1
- Item evolutions having a level requirement is now supported
- Tweaked the fly menu to be more responsive and snappy
- Battle sprite organization updates and extra backs
- Organized front and back battle sprites to be controlled via assembler tags in the makefile
- The move relearner and move deleter code is now tethered to the _MOVENPCS makefile tag
- The running shoes code is now tethered to the _RUNSHOES makefile tag
- Original flashing move animations from Red-JP and Green are tethered to the (unused) _JPFLASHING makefile tag
- Version encounters, trades, and game corner prizes are now tied to their own dedicated assembler tags
- The enemy trainer's HUD is now updated after it uses a healing item

- Removed restore sfx from the AI x-accuracy item
- Added the restore sfx to all AI hp-recovery items

- Trainer switching (ai routine #4)can now be deactivated
  - This feature disallows enemy trainers to switch intelligently, just like in the original retail games.
  - With the cursor in the TEXT SPEED section of the option menu, press A to toggle this feature on and off.
  - the letters "x sw" will appear in the corner of the option menu to indicate that trainer switching is inactive.
  - Note that Jugglers are unaffected because their official gimmick is that they switch randomly.


---
**New fixes for original game bugs for both branches**
- Fixed a grass tile in the Forest tileset not counting for encounter generation
- Changed border block on route 16 to water to make it consistent with route 17
- Fixed a graphical error when Bide unleashes energy against a 'mon that is not being displayed
- Fixed screen tearing in battle when player or 'mon slides off the screen
- Fixed a bug from the vanilla game where boulder dust clouds do not show up well when pushing downwards
- Changed border block in cerulean city to field to make it consistent with route 5
- Fixed reading the route 16 sign from the other side on route 17 
- Added missing dungeon maps to battle transition functions
- Fixed using a ledge to land on a NPC
- Exit won't block you when warped to Fuji's house from Pokemon Tower
- Can no longer get blocked at the cinnabar gym door
- Player now faces up instead of left when stopped in the route 8 guard house
- Wavy line animation (psychic/psywave/night shade) now scrolls the top three screen lines (by easyaspi314)
- Fixed glitchy trainer card transition screens on GB-DMG
- Can no longer change facing while pushing a boulder
- Downward-moving sprites now get hidden behind text boxes
- NPC walking animation now updates during player movement
- Fixed NPCs treating the last visible screen column/row as off-screen
- Fixed a graphical bug on the naming screen that apears on cheapo flash carts
- Fixed double-edge animation being off-center for the enemy pokemon
- Fixed a wall in cerulean cave level 3 that violated the mapping rules so was walkable
- Improved the tile block replacement function (improves cinnabar gym lag)
- On battle slide-in, fixed the bottom window disappearing for 1 frame when playing on a DMG gameboy
- White 1-frame flash on battle load (affecting DMG and GBC modes) as been removed
- White 1-frame flash on map load (affecting DMG and GBC modes) as been removed
- Fixed garbage tiles display for 1 frame after a battle on the DMG
- Fixed a bug where HP bar animation can print the wrong tile for 1 frame
- Fixed junk tiles displaying for 1 frame when the game resets after displaying THE END
- Fixed transitions when entering and exiting Rock Tunnel

- The proper forget-move poof sfx plays during battle
- Fixed a bug having to do with rare instances of bending the audio pitch
- Victory music won't play if a wild 'mon faints but the player has no 'mons remaining; it's a blackout
- The jingle for finding a hidden item will no longer be skipped during an audio fadeout
- Fixed ball toss sfx not resetting the pitch envelope settings
- Added protection against oak's lab music cutting a channel off
- Fixed *thud* sfx playing when exiting via a warp tile
- Fixed certain text sfx not playing when using zero-delay text
- Meet Trainer jingle should not play before loading into the gym leader battle music
- AI using dire hit item now plays a SFX

- Fixed input priority on menus
- Fixed A-button input priority on the left side of the scrolling pokedex list
- Cannot surf from the party menu if a NPC is in front of the player (entering or exiting surf)
- The player can now select a move even if frozen, and this fixes a PP underflow and link desync glitch
- Made many TextIDs close when pressing A instead of releasing A
- Binoculars can no longer pause the overworld by holding A from the wrong side
- Fixed an issue where pressing a button on a menu while holding A is treated as an A-press
- Fixed the pokeflute posting the wrong message in wild pokemon battles

- Cannot use poison to black yourself out of the cable club because entering the club now heals your party
- Cannot use poison to black yourself out of the safari zone because the safari minigame now stops poison damage
- Cannot perform the 99-stack glitch anymore
- RAM adress D732 now gets cleared upon a new game
- The party heal function now detects glitch moves and loads 0 PP for them
- Closed 255 clone pokemon glitch and reduced saving delay to 15 frames
- Fixed trainer escape glitch via blacking out from a wild battle

- Minor code correction to Twineedle to prevent future errors 
- Fixed an issue where the counter for the Disable effect had the wrong distribution if the target was slower
- You can now get Oak's pokeballs even if you evolve your starter

- The eating/angry message in safari battles will no longer display incorrectly when returning to neutral
- The eating/angry safari state counter correctly increases by 1-5 turns instead of 0-4 turns
- Safari battles correctly reset the catch rate when either eating/angry state returns to neutral

- Fixed a bug from the vanilla game where random NPC walk delay can underflow to 255 ticks
- Fixed an offset bug with the lucky game corner machine
- Applied the pokeyellow fix for in-game trade evolutions
- Accounted for underflow with switch-out messages
- Added an error trap to _Divide function for divide-by-zero calls
- Fixed hidden coins not giving the correct amount
- Slot machine no longer copies too much tile data
- Corrected and clarified the quiz text in the cinnabar gym
- Clarified the text for the super repel on 2F of the celadon dept store
- Viridian gym statue will not spoil the gym leader's name reveal
- Fixed increment bug in CheckForTilePairCollisions
- Fixed inaccurate text when getting the rock slide TM
- Fixed the tiles in Mt. Moon floor 3 that prevent encounters
- Fixed picking a fossil causing all trainers on Mt. Moon floor 3 to lose line of sight
- Fixed an underflow issue which caused trainers above the player to not see beyond 3 spaces downward


---
**Project-related fixes for both branches**
- Minor timing fix to title object palette loading
- Fixed Raticate not appearing in Unknown Dungeon 2F in Blue-Jp
- Fixed incorrect encounters on route 13 in Blue-Jp
- Fixed an invalid apostrophe
- Fixed pewter npc following distance in 60 fps mode
- Fixed community patch byte not getting set on new game
- Fixed an issue with trapping moves being allowed on switch-in
- Fixed typo causing incorrect game corner prizes
- Minor adjustments to title screen and intro
- Leech seed health drain animation now has correct coloring on GBC
- Fixed screen whiteouts not looking very smooth in GBC mode (like when entering the 'mon status screen)
- Re-fixed the celadon vending machine code
- More fixes for AI switching
- Made adjustment to EXP All message
- Holding B in zero delay text mode will not revert the text to FAST speed
- Major cleanup of options constants
- Fixed a minor issue where the first pokemon an opponent sends out can't be switched
- TM/HM name list fixed so it can be in any bank
- Fixed extra options not getting initialized correctly
- Updated Makefile organization
- Added script that verifies the RGBDS version when compiling
- Updated the project to build with RGBDS 0.6.0
- Readjusted enemy stat exp accumulation and removed reduntant lines in CriticalHitTest
- Updating a save to a new patch version now checks to see if the elite-4 were already defeated
- Fixed problem with the menu selection byte changing if opponent switches first (affects mimic and others)
- If Transform copies an opponent's Transform move, and the the PP of that move is < 6, it will copy that move's instantaneous PP less 1.
- Fixed a problem where multi-hit moves could overflow the damage effectiveness multiplier
- Restored the gray pokemon coloring used in red/blue/green versions if using red/blue/green-style front sprites.
- Made the speed of japanese flashing animations more accurate to the original
- Systems that generate above-average DVs now use a statistical bias instead of using 9,8,8,8 minimum
- Updated installation instructions and RBGDS version checking
- Minor tweaks to saving/loading code
- Added a sfx and symbol for the color correction
