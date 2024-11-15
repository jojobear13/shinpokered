# Shin Pokémon Red, Blue, Green, Red-JP, & Blue-JP

Version 1.24.6

Future bugfixes here will be eventually migrated to the Shin Pokemon master branch

#Patch Info  
-----------
BPS patches are provided for entry into your preferred emulator, patching tool, or other accessory that supports the BPS format.  
Download and enter a patch which corresponds to the ROM of which you own a lawful copy.  
- **Red patches (shin pokemon red, red_origback, and red-jp) are intended for USA Red.**
  - MD5 Hash: 3d45c1ee9abd5738df46d2bdda8b57dc
- **All other patches (Blues and Greens) are intended for USA Blue.**
  - MD5 Hash: 50927e843568814f7ed45ec4f944bd8b
- The "_origback" patches are alternatives that keep the original back sprites. 


***Includes Pokemon Green and Japanese Red!***
- The compiler primarily builds the graphics and cerulean cave layout back to the original japanese release.
- Pokedex entries adapt the original Green version text that was translated in Fire Red.
- Pokedex uses metric units.

***Includes Japanese Blue!***
- Primarily builds the lists for encounters, trades, and prizes that were in the never-localized japanese release.
- Pokedex uses metric units.
- Other minor graphical adjustments.

***Updating Your Save File***
Deactivate all special options and NPC toggles in the old save if it's from an earlier patch.  
When loading an old save file with the latest patch, the player is automatically warped to Pallet Town.  
Normally this will be enough to update the save file without doing anything else.  
It's possible you may still have issues upon loading a save from a previous patch or an unpatched game.  
To prevent this from happening, save in the outdoor Pallet Town map on the old save.  
You might be blocked by invisible walls upon loading the game.  
To fix this, you must use the Softlock Warp detailed below to teleport back to Pallet Town.  

		
#Compatibility Notes
-----------

- **Certain emulators are known to cause bugs due to inaccuracies in replicating the original hardware**
  - An accurate emulator, preferably a GBC-dedicated emulator, is required in order to avoid unexpected bugs
  - Goomba and Visual Boy Advance in particular are known to be problematic
  - BGB is the supported standard due to its accuracy and debugging tools
- Compatible with original Gameboy hardware (DMG, Super, Pocket, Color, Advance, SP)
- Potentially compatible with Pokemon Stadium 1 & 2 (using original Nintendo hardware)
  - Simpler flash carts (like cheap bootlegs) are recognized, but products with firmware like the EZ Flash JR. will not work.
  - Works with the save file operations (importing pokemon, item management, and box management) of both Stadium 1 and 2.
  - Will play and save in the GB Tower of Stadium 2.
  - Will **not work** with the GB Tower of Stadium 1.
- Might be possible to use a save from vanilla USA red/blue with this rom hack 
  - Save outside in Pallet Town before transferring over
  - Use the Softlock Warp to clear any invisible walls
- New builds are tested and debugged with the BGB 1.5.8 emulator and verified using original hardware
- Link trading with an original retail cartridge appears to work properly on real hardware
- Link trading between the lite and master branches appears to work properly on real hardware
- Link battles are still largely untested, and they are unsupported in the following ways:
  - Link battling between a master branch build and any other non-master branch build
  - Link battling between a lite branch build and any other non-lite branch build
  - Link battling between builds of dissimilar revisions
- A revision control function has been added that will cancel unsupported cable links
- Link functions via 3DS hardware and its Virtual Console emulator are not supported at this time


#Changelog From the Last Full Release
-----------
**Note: Changelogs may contain spoilers**  
[View the Consolidated Changelog Document from 1.23 to 1.24.0](/patches_and_info/changelog_from_v1.23.md)  

v1.24.6
- Fixed an issue with the title menu becoming dark when saving in rock tunnel
- Fixed rock tunnel darkness affecting option menu
- Fixed desync problem during link battles with Rage, Thrash, and trapping moves
- The 'bwoop' sfx now plays when registering pokemon with short names like "Onix"
- Fixed wrong color palette being loaded for player back sprite tiles during screen shake animation
- Fixed an oversight where the player does not face the Viridian Gym door during the message saying it's locked
- Fixed a bug in the AI that caused trainers to use poison-effect moves inaccurately
- Corrected the text in green & red-jp pokedex entries
- Fixed missing punctuation in Oak's pokedex evaluation
- Fixed Full Restores undoing burn/paralysis stat changes when healing a non-active pokemon

v1.24.5
- Fix Psywave symmetry

v1.24.4
- Can no longer fish or surf using the right wall corner tile on the SS Anne.
- Fixed incorrect sign text in safari area 1
- Adjusted some city names on signs
- Lance and the player will face each other when speaking.
- Increased the speed of the HP bar animation

v1.24.3  
- Disable and static damage moves will not crit or show super/not very effectiveness
- Fixed an issue with NPCs overlapping menu and text boxes
- Adjusted the parity of in-game trades across versions
- Option menu graphics tweak
- Toggling the gamma shader in the extra options menu now automatically updates the palette
- Moved NPC in celadon prize house two spaces to the right
- Optimized the GBC smooth fading a little bit

v1.24.2  
- Fixed a text bug on multi-hit moves

v1.24.1  
- Optimized smooth fades to eliminate graphical jank during battle black-outs
- Trainers will not use non-healing items if they or the player are at low HP, making them more aggressive
- AI will not switch if its HP is below 25% as it's ususally not worth it
- Fades in or out to white in GBC mode with gamma shader enabled will no longer have a frame of incorrect color
- The move Transform now decrements PP properly when used by the AI recursively
- Spinner tiles animate properly without resorting to vblank-induced slowdown
- Fixed wrong color for move animation when it comes after self-inflicted confusion damage
- Reworked the prize mon level function and synchronized DVs for gift pokemon added to party or box
- Fixed typed effectiveness being applied the wrong way to static damage moves
- All the extra options on the option menu have been moved to their own separate menu
- Fixed a bug catcher on route 9 being able to walk onto a ledge
- The message for substitute taking damage now only displays after the first attack of a multi-attack move
- Multi-attack moves display effectivenes only on first attack instead of the last attack
- Twineedle does not print redundant messages like other multi-hit moves


#Bugfixes
-----------

- Battle engine fixes
  - PP usage is now tracked for both wild and AI trainer pokemon
  - Moves no longer have a default 1/256 chance to miss
  - Fixed freeze that occurs in defense stat scaling (def < 4 glitch)
  - Enemy ai ignores type effectiveness for moves that have zero power
     - prevents things like spamming agility against poison pkmn
  - Enemy ai ignores super-effectiveness for moves that do static amounts of damage
  - Fixed skipping move-learn on level-up glitch. 
     - when gaining multiple levels at a time, each in-between level is incrementally checked for moves learned
     - this prevents a pkmn from skipping learnable moves if gaining multiple levels in battle
	 - also does this when evolving via level-up for the new evolution's movelist
  - Burn & Paralyze stat penalties are now properly applied after Speed & Attack stats get updated/recalculated
  - Badge stat-ups don't get stacked anymore
  - The function that applies badge stat-ups now selectively boosts the correct stat when called during a stat-up/down effect
  - If player is frozen, the hyperbeam recharge bit is now cleared
     - now matches how enemy mon's recharge bit is cleared upon being frozen
     - this prevents getting stuck in a loop unable to do anything on your turn
  - Blaine will not use a healing item at full HP
  - The BIRD type has been reinstated and renamed to TYPELESS. It acts as a universally neutral type (particularly for Struggle)
  - AI trainers have priority on switching or using an item
  - AI type effectiveness function now takes type 1 and 2 into account together 
	 - Before AI would only look at the type it encountered first in a list search
     - AI will now treat a move as neutral if type 1 makes it supereffective but type 2 makes it not effective
  - Stat changes from burn and paralyze are applied when the ai sends out a pkmn with those conditions
  - AI routine #2 (prioritize buffing or use a status move) now activates on the 1st turn after sendout instead of the 2nd
  - New custom function for undoing the stat changes of burn and paralysis
    - undoing paralysis is accurate to within 0 to -3 points
    - undoing burn is accurate to within 0 to -1 point
  - PP-up uses are disregarded when determining to use STRUGGLE if one or more moves are disabled
  - AI will not do actions during Rage or when recharging
  - Fixed wrong crit damage for lvl > 127
  - Made adjustments to critical hit damage
    - Damage factor is now 2*(2*level)/5 + 4 instead of 2*(2*level)/5 + 2 to simplify some algebra
    - If non-crit damage would be >= crit damage, the regular modified stat values are applied instead
  - The player can now select a move even if frozen, and this fixes a PP underflow and link desync glitch
  - Accounted for underflow with switch-out messages
  - Safari Zone engine fixes:
    - The eating/angry message in safari battles will no longer display incorrectly when returning to neutral
	- The eating/angry safari state counter correctly increases by 1-5 turns instead of 0-4 turns
	- Safari battles correctly reset the catch rate when either eating/angry state returns to neutral


- Move fixes
  - Transform-related fixes:
      - Move slots cannot be rearranged when transformed (prevents acquiring glitch moves)
      - Fixing Transformation loops
	    - If Transform copies an opponent's Transform move, 
		- and the the PP of that move is < 6, 
		- it will copy that move's instantaneous PP less 1.
		- This limits the PP of using transform repeatedly between two pokemon
      - Enemy DVs can no longer be manipulated by having it use transform multiple times
	  - Fixed a conflict where transforming while disabled can leave the new moves disabled
	  - Fixed transformed 'mons reseting their moves when learning a level-up move
	  - Fixed a typo so now transformed 'mons retain their original palette
  - disable cannot critically hit nor print effectiveness message
  - dire hit/focus energy now quadruples crit rate instead of quarters
  - sleep now normal-chance hits a pkmn recharging from hyperbeam, but has no effect if it's already status-effected
  - the fly/dig invulnerability bit is cleared when a pkmn hurts itself from confusion or is fully paralyzed
  - psywave damage is always min 1 be it an opponent or yourself (prevents desync)
  - Fixed Psywave underflow/overflow with levels of 0, 1, and above 170
  - Substitute-related fixes:
    - all hp drain moves (including dream eater and leech seed) miss against substitute
    - substitute will not work if it would bring you to exactly 0 hp
    - zero power moves that inflict stat-downs, sleep, or paralyze will not affect a substitute
    - the confusion side-effect of damaging moves is blocked by a substitute
	- recoil damage from jump kicks or hurting oneself in confusion is now applied to user's substitute
  - healing moves work with restoring exactly 255 or 511 hp 
  - light screen and reflect now have a cap of 999
  - Haze removing sleep/freeze will not prevent a multi-turn move from getting stuck (also fixes the sleep-trap glitch)
     - Fixed by allowing sleeping/frozen pkmn to use a move after haze restores them
     - on the plus size, haze now restores both opponent and user's status conditions as was intended in gen 1
  - Haze resets the enemy and player toxic counter
  - Rest now does the following:
     - clears the toxic bit and toxic counter
     - undoes the stat changes of burn and paralysis
  - fixed-damage move fixes (seismic toss, dragon rage, etc):
    - can no longer critically hit
    - obey type immunities
	- ignore effectiveness text & sfx
	- use 2 bytes for damage instead of 1
  - Struggle is now TYPELESS so that it can always neutrally damage something
  - Metronome & mirror move will not increment PP if the user is transformed
     - This prevents adding PP to hidden dummy moves that prevent a pkmn from going into Struggle
     - This also prevents Disable from freezing the game by targeting a dummy move
  - Mirror Move is checked against partial trapping moves in a link battle to prevent desync
  - Bide's accumulated damage bytes are now both set to zero on an enemy faint in order to prevent desync
  - Jump Kick moves now do the correct recoil damage on a miss
  - The effects of Leech Seed and Toxic no longer stack
  - Trapping effects only clear the hyperbeam recharge bit on a hit, preventing its automatic use on a miss
  - Trapping move PP can no longer underflow due to an opponent switching pkmn
  - Raging and Thrashing no longer suffers from accuracy degradation
  - Breaking a substitute does not nullify explosion/self-destruct, hyper beam recharge, or recoil damage
  - Hyper beam must recharge if it knocks out the opposing pkmn
  - Bugfixes involving Counter:
    - works against BIRD type, which is now typeless and assigned only to STRUGGLE
    - To prevent desync, pressing B to get out of the move selection menu zeros-out the ram location for selected move & move power
    - last damage dealt is zeroed in these cases (also fixes some issues with Bide):
	  - it's the start of the round without a trapping move active (fixes most issues since Counter always goes second)
	  - player/enemy pkmn is fully paralyzed or after hurting itself in confusion
    - Crash damage from jump kicks and pkmn hurting itself cannot be Countered
  - To prevent infinite loops, Rage ends after 2 to 3 turns (attack boosts are kept)
  - Non-link enemy mons now have PP, so always run checks for 0 PP during the disable effect
  - Fixed an issue with Disable's counter on slower 'mons and also corrected the statistical outcomes of the counter

	
- Graphical Fixes
  - Gym leader names have been restored on the trainer card
    - These were removed during localization as a simple and expedient solution
    - So this is more of a correction to the localization than a strict graphical error
  - Restored intro "Presents" for all builds as localizers did not need to do this for Nintendo of America
  - Glitched sprites can no longer cause a buffer overflow that corrupts the hall of fame
  - Returning from the status screen when an opponent is in substitute/minimize no longer glitches the graphics
  - PC graphic restored to celadon hotel
  - A tile in cinnabar mansion 3f is slightly modified to prevent getting permanently stuck
  - A tile in cerulean cave 1f adjusted so there isn't a walkable cliff tile
  - Fixed a wall in cerulean cave level 3 that violated the mapping rules so was walkable
  - Added ledge to route 25 to prevent softlock
  - After defeating the cerulean burglar rocket, the guard itself always moves to prevent getting stuck in the front door
  - No more ABCD glitched sprites when using teleport without a super gameboy
  - The transitional frame when turning 180 degrees now shows correctly
  - The lower right corner tile of the mon back pic is no longer blanked
  - Amazing man can no longer be triggered by text boxes or the start menu (via a code tweak from Yellow-version)
  - The rival encounters on route 22 now show an exclamation bubble that never showed up originally
  - Erika uses her pic from yellow version which alters her funerary clothes to a proper kimono
  - Fixed a scrolling text artifact in the credits when running in GBC-mode
  - Fixed amazing man glitch when triggered by a hidden object
  - Fixed amazing man glitch in the route 16 gate
  - Fixed tower ghost pic not loading after exiting status screen
  - Fixed bumping into invisible shrub
  - Fixed holding left to force past the cycling road guards
  - Fixed being able to leave the safari zone without clearing the event
  - Minor tweak to Pallet Town object data for Prof Oak
  - Minor tweaks to the Rival's object data in various maps
  - Fixed menu not clearing if A is held after saving
  - Fixed a missed increment that makes a map's 15th object not update its facing properly
  - Adjusted two spin-stop tiles in Viridian Gym
  - Made Agility's animation more apparent
  - On GBC, moves animations are colored according to type
  - Gym leader names have been restored on the trainer card
    - These were removed during localization as a simple and expedient solution
    - So this is more of a correction to the localization than a strict graphical error
  - Restored intro "Presents" for all builds as localizers did not need to do this for Nintendo of America
  - Changed border block on route 16 to water to make it consistent with route 17
  - Changed border block in cerulean city to field to make it consistent with route 5
  - Fixed screen tearing in battle when player or 'mon slides off the screen
  - Fixed a bug from the vanilla game where boulder dust clouds do not show up well when pushing downwards
  - Fixed a bug from the vanilla game where random NPC walk delay can underflow to 255 ticks
  - Minor bugfix for CollisionCheckOnWater; no effect on gameplay
  - Fixed minor graphical glitch when surfing from the menu
  - Cannot surf from the party menu if a NPC is in front of the player (entering or exiting surf)
  - Player now faces up instead of left when stopped in the route 8 guard house
  - Fixed a graphical error when Bide unleashes energy against a 'mon that is not being displayed
  - Fixed minor graphical glitch when surfing from the menu
  - Added missing dungeon maps to battle transition functions
  - Wavy line animation (psychic/psywave/night shade) now scrolls the top three screen lines
  - Fixed glitchy trainer card transition screens on GB-DMG
  - Made many TextIDs close when pressing A instead of releasing A
  - Binoculars can no longer pause the overworld by holding A from the wrong side
  - Can no longer change facing while pushing a boulder
  - Downward-moving sprites now get hidden behind text boxes
  - NPC walking animation now updates during player movement
  - Fixed a graphical bug on the naming screen that apears on cheapo flash carts
  - Original flashing move animations from Red-JP and Green are tethered to the (unused) _JPFLASHING makefile tag  
  - The enemy trainer's HUD is now updated after it uses a healing item
  - Added optimizations to how OAM data is prepared so that overworld sprites wobble less
  - On battle slide-in, fixed the 1-frame flicker when playing on a DMG gameboy
  - White 1-frame flash on battle load (affecting DMG and GBC modes) as been removed
  - White 1-frame flash on map load (affecting DMG and GBC modes) as been removed
  - Fixed garbage tiles display for 1 frame after a battle on the DMG
  - Fixed a bug where HP bar animation can print the wrong tile for 1 frame
  - Fixed junk tiles displaying for 1 frame when the game resets after displaying THE END
  - Fixed transitions when entering and exiting Rock Tunnel
  - The rocket grunt in Cerulean city has a minor fix to the timing of when its sprite disappears
  - Fixed wrong color palette being loaded for player back sprite tiles during screen shake animation
  - Fixed an issue with the title menu becoming dark when saving in rock tunnel
  - Fixed rock tunnel darkness affecting option menu


- Item Fixes  
  - Great ball has a ball factor of 12 now
  - Stone evolutions cannot be triggered via level-up anymore
  - Ether and elixer now account for PP-ups used when determining if move is at full PP
  - PP-restoring items no longer affect transformed moves and only restore the original moves
  - EXP ALL fixes
    - should now dispense the correct exp if multiple pokemon take place in a battle
	- no longer counts fainted pokemon when dividing exp
	- handles exp correctly when all your battle participants are knocked out
  - Fixed a bug where itemfinder can't locate objects with a zero x or y coord
  - Surfboard bugfixes:
	  - cannot use the surfboard if being forced to ride the bicycle
	  - no longer freezes the game when using it from the item menu to get back on land
  - The Full Heal used by the AI now undoes brn/par stat changes
  - Condition healing items (including using Full Restore at max hp) no longer reset all stats
    - Burn heal undoes the attack stat changes
    - Paralyze heal undoes the speed stat changes
    - Full restore at max hp undoes the stat changes of brn/par
  - Full Restore when used in battle to heal HP now undoes the stat changes of brn/par
  - Pokedoll is disallowed during ghost marowak battle
  - Encountering Missingno will not give 128 of the item in the sixth bag slot
  - Fixed the pokeflute posting the wrong message in wild pokemon battles
  

- Audio fixes
  - Audio engine has been back-ported from Yellow version
    - Fixes some channel conflicts between cries and the low-health alarm
    - Fixes some audio hiccups with Yellow's color palettes on the GBC
    - Press SELECT on the option menu to go to the extra menu and change the audio mixing option under "AUDIO"
  - Fuschia gym plays the correct sfx when getting the TM from Koga
  - Vermilion gym plays the correct sfx when getting the TM from Surge
  - Restored sfx for getting a badge
    - A sfx is supposed to play when getting a badge, but not for all gym leaders and the sfx used is inconsistent
	- Looks like the idea was dropped in development due to issues with having separate audio banks
	- However, there is a unique unused sfx in the battle audio bank that signifies getting some kind of important item
	- This is likely what was going to be used for getting a badge at some point, and it has been restored
  - Bike music stops playing now when going down a hole
  - The proper forget-move poof sfx plays during battle
  - Fixed a bug having to do with rare instances of bending the audio pitch
  - Victory music won't play if a wild 'mon faints but the player has no 'mons remaining; it's a blackout
  - The jingle for finding a hidden item will no longer be skipped during an audio fadeout
  - Fixed ball toss sfx not resetting the pitch envelope settings
  - Added protection against oak's lab music cutting a channel off
  - Removed restore sfx from the AI x-accuracy item
  - Added the restore sfx to all AI hp-recovery items
  - Fixed *thud* sfx playing when exiting via a warp tile
  - Fixed certain text sfx not playing when using zero-delay text
  - Meet Trainer jingle should not play before loading into the gym leader battle music
  - AI using dire hit item now plays a SFX
  - The 'bwoop' sfx now plays when registering pokemon with short names like "Onix"
  

- Misc. fixes
  - Cinnabar/seafoam islands coast glitch fixed (no more missingo or artificially loading pokemon data)
  - Catching a transformed pokemon no longer defaults to catching a ditto
  - Vending machine now checks for the correct amount of money
  - Vermilion Gym switch puzzle fixes
    - Prevented byte overflow when determining the trash can with 2nd switch in vermilion gym
	- The position of both switches in Vermilion Gym are now determined at the same time
    - The switches in Vermilion Gym can now be discovered independently from one another
  - Hidden nugget in safari entrance now obtainable
  - Slot machine reel bug fixed
  - Fixed oversights in reel functionality to better match Gamfreak's intent
  - The lift key in the rocket hideout drops during the end of battle text like in Yellow-version
  - An unused bit is now used to determine the ghost marowak battle
  - Can't use surf/teleport/escape rope to escape from trainer encounters
  - Fixed trainer escape glitch via blacking out from a wild battle
  - Can't fish or surf in the bases of statues
  - Can no longer fish or surf using the right wall corner tile on the SS Anne
  - Seafoam islands fast current applied to the right steps on floor B3
  - Each of the two boulder puzzles in seafoam islands will fully reset until completed
  - The boulder switches never reset while inside victory road and they will always reset upon leaving
  - While inside victory road, boulders placed on switches will stay there between floor transitions
  - The formula functions for exp now have underflow protection.
  - General RNG improved to use the xor-shift method (fast and allows for all possible DVs naturally)
    - Poor emulators and flash carts with loader GUIs often clear the RAM resulting in a random seed of zero
	- If this problem is detected, an attempt is made to generate a random seed using the original DIV register method
  - Cannot bypass Brock's gym via the start menu
  - Fixed bugged npc movement constraints
  - Fixed the instant-text glitch that can happen in the bike shop
  - Fixed using escape rope in bill's house and the fan club
  - Added nop after halt commands (safety prevention for a rare processor bug)
  - Streamlined how the ghost marowak battle is triggered (now allows for non-ghost marowaks in pokemon tower)
  - Fixed a coordinate typo in pokemon tower left by gamefreak
  - Fixed an issue with the silph co 11f elevator doors
  - Can no longer walk up to 4 steps with a fainted team
  - Water warps in seafoam island 4 & 5 are now scripted movement
  - Fixed a bug in the GetName: function that treated lists over 195 entries as item lists
  - You can Fly and Teleport out of maps with the forest tileset
  - Fixed a grass tile in the Forest tileset not counting for encouner generation
  - Fixed input priority on menus
  - Fixed A-button input priority on the left side of the scrolling pokedex list
  - Fixed an issue where pressing a button on a menu while holding A is treated as an A-press
  - RAM adress D732 now gets cleared upon starting a new game
  - Cannot use poison to black yourself out of the cable club because entering the club now heals your party
  - Cannot use poison to black yourself out of the safari zone because the safari minigame now stops poison damage
  - Cannot perform the 99-stack glitch anymore
  - Fixed an offset bug with the lucky game corner machine
  - Minor bugfix for CollisionCheckOnWater; no effect on gameplay
  - Fixed reading the route 16 sign from the other side on route 17 
  - Fixed using a ledge to land on a NPC
  - The party heal function now detects glitch moves and loads 0 PP for them
  - Exit won't block you when warped to Fuji's house from Pokemon Tower
  - Closed 255 clone pokemon glitch
  - Applied the pokeyellow fix for in-game trade evolutions
  - Can no longer get blocked at the cinnabar gym door
  - Fixed hidden coins not giving the correct amount
  - Fixed NPCs treating the last visible screen column/row as off-screen
  - Slot machine no longer copies too much tile data
  - Fixed increment bug in CheckForTilePairCollisions
  - You can now get Oak's pokeballs even if you evolve your starter
  - Fixed the tiles in Mt. Moon floor 3 that prevent encounters
  - Fixed picking a fossil causing all trainers on Mt. Moon floor 3 to lose line of sight
  - Fixed an underflow issue which caused trainers above the player to not see beyond 3 spaces downward
  - Lance and the player will face each other when speaking.
  - Fixed an oversight where the player does not face the Viridian Gym door during the message saying it's locked
 
 
#Tweaks
-----------
- Press SELECT on the option menu to get to the extra options menu and toggle various new features
- Added built-in gamma shader for backlit LCD screens in GBC mode (press SELECT at the copyright screen)
  - Gamma shader defaults ON if the destination code in the rom header is set to 00 (JP)
  - Pressing SELECT at the copyright info now switches the shader from its default state
  - It can also be toggled in the extra menu under "Y SHADER" so you don't have to reset the game to change it
  - The default state of the gamma shader can be changed with any gameboy rom header editor
  - Alternately, remove the 'j' in 'cjsv' in the Makefile to compile with a JP destination code
- The Gameboy Color palette functionality from pokemon Yellow has been back-ported into the game
  - Scrolling mons on the title screen have their own palettes loaded on the GBC.
  - In the blue version intro, jigglypuff has it's own palette loaded on the GBC. 
  - Oak-speech nidorino has its color palette on the GBC.
- Additional GBC color additions
  - Scrolling mons on the title screen have their own palettes loaded on the GBC.
  - In the blue version intro, jigglypuff has it's own palette loaded on the GBC.
  - Oak-speech nidorino has its color palette on the GBC.
  - When playing in GBC-mode, move animations are colored based on their type
  - In GBC-mode, when a pokemon is caught, the resting ball now has a defined color
  - Tossing pokeballs have color in GBC mode
- Added an option to make the overworld run in 60fps
  - Feature is a proof-of-concept and is still a bit rusty
  - Toggle this in the extra options menu
  - Takes advantage of double-speed CPU mode when played as a GBC game
- Starting a New Game while in GBC-mode will default 60FPS mode to ON
- Text with zero frame delay can be toggled in the extra options menu
- A hard mode option has been added to provide increased difficulty
  - Toggle this in the extra options menu
  - Enemy trainer pokemon are assigned level-appropriate stat exp
  - Enemy trainer pokemon have randomized DVs that are above-average
  - Boss trainers (giovanni, elite 4, gym leaders, later-game rival) cannot have DVs below 8
  - Wild pokemon DVs get 1 re-roll each if less than 4, biasing them upwards a little bit
  - Badge-granted stat boosts are disabled in trainer battles
  - X-stat items have double the effect like in more recent generations
  - Revive items cannot be used in battles
  - Mewtwo will prevent you from using a master ball on it and use AI to choose moves
  - Non-link battles in hard mode use the Stadium 1 formulas for critical hit probability
  - Oak's pokeballs will be upgraded to great balls if you beat the route 22 rival in hard mode
- Softlock Warp 
  - instantly teleport back to your mom's house if you get stuck or are unable to move after updating to a new patch
  - sets money to at least 1000 if you have less than that
  - Intructions to perform:
    - go to the start menu and put the cursor on OPTION
    - press and hold DOWN on the d-pad (the cursor will now be on EXIT)
    - while continuing to hold DOWN, press and hold SELECT
    - while continuing to hold those two buttons, press B
    - the start menu should close and you will warp back to your mom's house
- Vanilla Options Reset 
  - Deactivates all special options (such as in preparation to update to a new patch)
  - Intructions to perform:
    - go to the start menu and put the cursor on the top option (usually POKEDEX)
    - press and hold UP on the d-pad (the cursor will now be on EXIT)
    - while continuing to hold UP, press and hold SELECT
    - while continuing to hold those two buttons, press B
    - the start menu should close and you will hear a jingle confirming that the option reset worked
- Debug Damage Display: As a debugging cheat, damage values will be displayed in battle as the UI updates
  - Toggled on/off the same way as the softlock warp, but by using 'A' instead of 'B'
  - Zero damage is not displayed
  - Damage is not displayed if either pokemon has zero HP remaining
- Slot machine coin counter runs twice as fast
- Interaction of slot reel modes tweaked for better gameplay
- The surfboard, a nugget, and TM 15 are hidden items added to the vermilion dock
- Blaine has a touched-up battle sprite so he doesn't look like an alien
  - Snagged this off reddit, but original artist unknown (let me know if this is yours)
- L: block doesn't disappear when level hits three digits
- Greatly increased the speed and performance of spin tiles
- Can cut the grass on the plateau tileset
- Initiating the Pokemon Tower rival battle will deactivate the following skippable rival battles
  - The Cerulean encounter
  - The SS Anne encounter
- Daycare allows HM moves on entered pokemon
- Improved fade-in and fade-out to black/white transitions when playing on GBC in 60FPS mode
- The silhouette effect at the start of battle now displays when playing on a DMG gameboy
- Adjusted the parity of in-game trades across versions
- Increased the speed of the HP bar animation

- Fixed mistakes in the game text
  - Attacks reduced to zero damage now say the target is unaffected instead of missing
  - Man in cinnabar won't mention raichu evolving (also applies to the jynx trade in cerulean)
  - Koga correctly says soul badge increases speed
  - Lt. Surge correctly says thunder badge increases defense
  - Correct type effectiveness information & sfx should now be displayed when attacking dual-type pkmn
  - Viridian girl's notebook 2nd page revised for pkmn-catching effectiveness
  - Viridian blackboard BRN info corrected (BRN does not reduce speed)
  - Viridian Blackboard PAR info updated
  - Cerulean badge-house guy has updated text
  - Prof. oak's speech plays the correct Nidorino cry
  - Text for using a TM/HM now refers to the "machine" rather than just "TM"
  - Fixed daycare man capitalization
  - Fixed capitalization in safari zone entrance
  - Fixed the flipped text for a girl in Saffron and the letter she is writing
  - Fixed text overlap with Oak giving you pokeballs
  - Reactivated lost text that was meant to play when you lose to your rival
  - Fixed text giving the wrong description of guard spec.
  - Fixed woman on silph co 10F having a blank line in her text 
  - Viridian gym statue will not spoil the gym leader's name reveal
  - Fixed inaccurate text when getting the rock slide TM
  - Adjusted some city names on signs
  - Fixed incorrect sign text in safari area 1
  - Fixed missing punctuation in Oak's pokedex evaluation
- Made adjustments to the game text
  - When a pkmn is caught and fills the box, a reminder is printed that the box is full
  - PC has a text prompt to tell you if its full after depositing
  - TM 18 given an actual explanation 
  - New student in viridian school explains ohko moves
  - Exp.all now prints one message when splitting exp instead of for each party member
  - Adjusted some of Giovanni's final lines for clarity
  - Clarified "chem" to mean grade in chemistry
  - Fixed pokemon category translation: "Rat" to "Mouse"
  - Fixed pokemon category translation: "Shellfish" to "Shell"
  - Fixed translation: Route 14 trainer's comment about the legendary birds
  - Restored unused text in the vermilion gym puzzle for finding the 2nd switch
  - Corrected and clarified the quiz text in the cinnabar gym
  - Clarified the text for the super repel on 2F of the celadon dept store
- Adjustments to multi-attack moves animation and messaging to improve battle flow
  - Multi-attack moves only print the effectiveness message after the last attack
  - 2-attack moves do not print "hit 2 times" because its obvious that they always hit twice
  - Multi-attack moves hide the substitute sprite on the first attack and only restore it after the last attack
  - Twineedle is unaffected by all this due to how it swaps out its effect on the fly to a poison side-effect

  
- Adjustments to moves  
  - Stat-down moves no longer have a 25% miss chance in AI matches
  - Moves that hit multiple times in a turn now calculate damage and critical hits for each individual attack
  - Switching out of a trapping move ends it immediately and wastes its user's turn (prevents PP underflow glitch)
  - Ghost moves (i.e. just Lick) do 2x against psychic as was always intended
  - Changes to Bide
    - damage accumulation is done after taking a damaging hit instead of during turn execution (less room for glitches)
	- side effect: bide is buffed because multi-hit moves now add damage to bide for each of the 2 to 5 hits
	- changed to Typeless to play nicer with AI routine 3 (it ignores the type chart regardless)
  - Rest's sleep condition increased to 3 turns since attacking on wakeup is now allowed.
  - Acid armor's animation changed so that does not make its user disappear
  - Metronome now classified as a Typeless special damage move to play better with the AI
  - Type immunity prevents trapping moves from taking hold at all
  - Changes to Rage
	- Now only lasts 2 to 3 moves like Bide in order to prevent an infinite loop
	- As a tradeoff, attack boosts from rage are kept when it ends
  - Minor code correction to Twineedle to prevent future errors, but this has no effect on gameplay
  
- Adjustment to stat mods, conditions, and items
  - Sleep does not prevent choosing a move
  - Waking up from sleep does not waste the turn and the chosen move is used
    - The sleep counter's minimum value is increased by +1 to maintain accuracy of sleep moves
  - Badge stat-ups are now only applied in wild pokemon battles to give parity to enemy trainers (only in hard mode)
  - The effect of X-Accuracy is no longer applied to one-hit K.O. moves (it originally made them auto-hit)
  - Using X-Accuracy with a OHKO move now allows it to hit faster opponents
  - Upped the power of safari balls to account for lower ball factor
  - In hard mode, X-stat items have double the effect
  - HP-UP item now preserves your HP ratio
  - Non-link battles in hard mode use the Stadium 1 formulas for critical hit probability
  
- Trainer ai routine #1 (recognition of stats, hp, and conditions) has been modified
  - using a move with a dream eater effect is heavily discouraged against non-sleeping opponents
  - using a move with a dream eater effect is slightly encouraged against a sleeping opponent
  - using a zero-power confusion effect move is heavily discouraged against confused opponents
  - moves that would miss against an active substitute are heavily discouraged
  - stat buff/debuffs are heavily discouraged if it would have no effect due to hitting the buff/debuff stage limit
  - heavily discourage double-using lightscreen, reflect, mist, substitute, focus energy, and leech seed
  - leech seed won't be used against grass pkmn
  - do not use moves that would be blocked by an active mist effect
  - rules for using healing moves:
    - heavily discourage healing if at max hp
	- slightly encourage healing if below 1/3 hp
	- slightly discourage healing if above 1/2 hp
  - heavily discourage using Counter against a non-applicable move
  - heavily discourage roar, teleport, & whirlwind
  - heavily discourage disable against a pkmn already disabled
  - Substitute discouraged if less that 1/4 hp remains
  - Will discourage using Haze if unstatus'd or has net-neutral or better stat mods
  - Discourages explosion moves in proportion to HP remaining
  - Will heavily discourage boosting defense against special, OHKO, or static-damaging attacks
  - AI layer changes that affect most 0-power moves (with only a few exceptions like heal effects)
    - now has a hard stop on using 0-power moves on consecutive turns with a few effect exceptions
	- heavily discourages 0-power moves if below 1/3 hp
  - Discourage exploding effects if faster than a player in fly/dig state
  - Randomly discourage usage of 2-turn moves when confused/paralyzed
  - 79.68% chance per status move that the AI is blind to a player switching or using an item
    - Prevents situations where AI will always re-status the player after the player switches or heals
	- An AI mon with three status moves will have about a 50% chance of ignoring item-use or switching
  - Discourage using fly/dig if faster than the player who is also picking fly/dig
  - If the player used and item or switched, AI is blind to the player's sleep counter when considering dream eater

- Trainer ai routine #3 (choosing effective moves) has been modified
  - It now heavily discourages moves that would have no effect due to type immunity
  - OHKO moves are heavily discouraged if the ai pkmn is slower than the player pkmn (they would never hit)
  - Static damage moves are randomly preferenced 25% of the time to spice things up
  - Thunder Wave is not used against immune types
  - Poisoning moves discouraged against poison types
  - Added some strategy to handle when the player uses fly/dig
  - Slightly preference regular effectiveness moves if STAB exists (25% chance per move)
  - Slightly discourage a move 25% of the time if it hits neutral with no STAB
    - Wherein a special move is being used on a 'mon with greater attack than special stat
    - Wherein a physical move is being used on a 'mon with greater special than attack stat
  - Slightly discourage a move 25% of the time if it hits neutral with no STAB
  - The enemy is blind to the player type if considering a poisoning effect move and the player just switched
  - 90.625% chance per damaging move that AI is blind to player type after player switches
    - Prevents situations where AI will always pick the ideal move against a switch-in
	- 'Blind' in this case means the AI will act as if the move being considered has neutral effectiveness
	- The AI might still favor a STAB move or a move that works better with its own stats

- Trainer ai routine #4 is no longer unused. It now does rudimentary trainer switching.
  - AI will not switch if its HP is below 25% as it's ususally not worth it 
  - chance to switch based on power of incoming supereffective move
  - 12.5% chance to switch if a move is disabled
  - 12.5% chance to switch if afflicted with leech seed
  - 34% chance to switch if afflicted with toxic poison
  - 25% chance to switch if opponent is using a trapping move
  - 25% chance to switch if active pkmn is confused
  - on the lowest stat mod, 12.5% chance to switch per lowered stage
  - There is a chance for the AI to switch a sleeping pokemon based on the sleep counter
    -chance is 0% if counter <= 3
	-chance is 12.5% if counter > 3
  - Additionally, every pokemon in the enemy roster is scored 
    - based on various criteria to determine which mon gets sent out
	- score might dictate that the current mon is the best choice and abort switching
	- an enemy mon is flagged when sent out; non-volatile (except sleeping) status or low hp cannot initiate switching
	- enemy mon that is recalled back due to a super effective move is flagged; it is demerited from being switched-in
	- switch flags are all cleared when player sends out a new mon since the situation is now different
  - AI scoring for switching puts a heavier penalty on potentially switching in a bad type matchup
  - AI scoring imposes a very heavy penalty for potentially switching in pokemon with less than 1/4 HP
  - AI switch scoring now penalizes bad match-ups between player and enemy 'mon types
  - AI switch scoring applies an extra penalty for possibly switching a pokemon into a super-effective move
  
- Trainer ai routine #3 added to the following trainer classes
  -brock, surge, sabrina, blaine
  -bruno, agatha

- Trainer ai routine #4 added to the following trainer classes
  -jr trainer M/F, pokemaniac, hiker, cueball, psychic, tamer, black belt, rocket, cooltrainer M/F, gentleman, channeler
  -all rival phases, all gym leaders, elite-4, prof.oak, chief
  
- Trainer switching (ai routine #4)can now toggled ON and OFF
  - While OFF, trainers will not switch intelligently just like in the original retail games.
  - Press SELECT on the option menu to go to the extra menu and toggle this option under "AI SWAPS"
  - Note that Jugglers are unaffected because their official gimmick is that they switch randomly.

- Trainer stat DVs are now randomly generated to a degree (only in hard mode) to be above-average
- Trainer pkmn now have stat experience assigned to them that is scaled to their level (only in hard mode)
  - The stat experience total for a given level 'L' is SIGMA[n=6,L](12n+50)
  - No stat experience is given for level 5 and below.
  - Outside of hard mode, trainer pokemon have 0 stat experience per the vanilla games
- These are real DVs and statEXP values that utilize the existing enemy party_struct which is normally unused by trainer AI
- Trainer pkmn DVs are remembered between switching, and new ones won't be generated on every send-out
- Trainer AI battles now track which enemy pkmn have already been sent out, so it supports the new DVs and stat exp
- Agatha & cooltrainers will not randomly switch since they now have ai routine 4
- Flags for dividing exp among active pokemon are now only reset after fainting an enemy pkmn
  - Originally these get reset every time the opponent send out a pkmn (even switching)
  - Was never really noticed since most trainers never switch nor would have the opportunity
  - Changed based on user feedback since many trainers now try to switch
- Trainers will not use non-healing items if they or the player are at low HP, making them more aggressive

- Adjustments to learnsets and base stats
  - Mewtwo can learn Swift by TM 

- Engine changes just for developers
  - If wGymLeaderNo is set to 9 when loading a battle, then the final battle music will play
  - The trainer move engine has been backported from Yellow version; trainer movesets can now be fully customized
  - Improved exp calculation for developers who want a level cap between 101 and 255
    - EXP calculation routine now does math in 4 bytes instead of 3 bytes
	- Exp calculation result is still capped to 3 bytes regardless of level cap to prevent overflow
	- The byte cap on the exp result means that certain growth rates may have a level cap
	- For example, the "slow" growth rate is theorized to cap at level 237
  - Trainer battle prize money uses 3 bytes instead of 2, lifting the 9999 cap on winnings
  - Adjusted daycare to allow exp values over $500000
  - Allow up to 8 digits when displaying experience on the status screen
  - Pokemon can now learn more than 1 more per level
  - The 1.5x EXP boost function now has overflow protection
  - EXP Gained can now print up to five digits instead of four
  - The "<LF>" character mapping can be used as a line-feed
  - Added rom hack version tracking for save files
    - It's a single byte in the save file that gets incremented each version
    - If the save byte does not match, the player is automatically warped back to Pallet Town
    - Helps prevent crashes and glitches when updating an older save file
    - You will be given the choice to warp to Pallet Town if the rom hack version does not match
  - The function that shows the dex entry for starter pokemon is now more robust
    - It now works for any pokemon (like if the starters are changed or randomized)
	- It keeps a backup of the pokedex-owned flags instead of erasing them
	- Removed the unused Ivysaur flag
  - Increased the maximum game clock to 32767 hours
  - Female trainer can be activated by compiling with the _FPLAYER tag
  - TMs and HMs now have actual name lists
  - Reduced saving delay to 15 frames
  - Tweaked the fly menu to be more responsive and snappy
  - Added an error trap to _Divide function for divide-by-zero calls
  - Withdrawing or depositing a key item from/to the player's PC will default its quantity to 1
  - Item evolutions having a level requirement is now supported
  - DelayFrame now manualy calls VBlank if it runs while the LCD is disabled
  

#Credits / Special Thanks
--------------------------
- Jojobear13's wife, for copywriting and voicework
- The Pret team for the pokered and pokeyellow disassemblies and all the code comments that came with them
- MoriyaFaith's pokejp project for green version assets and code referencing
- Rangi for the tool Polished Map and the jp-style town map from Red/Blue Star
- Exp bar coded by Danny-E 33
- The Pokemon Prism team for the improved RNG used in this project's previous versions
- Patrik Rak for the new xor-shift RNG code
- Move deleter/relearner coded by TheFakeMateo for Pokemon Red++
- Code contributions and bugfixing by wisp92
- GLSWV for correcting the metric conversions of height and weight data 
- SteppoBlazer for the spaceworld-style old man back sprite
- Poketto for the spaceworld-style Trainer Red back sprite
- SPazzzi95 for documenting localization changes
- easyaspi314 for optimizations to the gamma shader and wavy-line animation bugfix
- Dracrius' pocketrgb-en project for finding corrections to jp-build inaccuracies
- powderpup for box covers using Sugimori cardass art

The following folks for their great tutorials, glitch videos, and explanations across the internet
- TheFakeMateo 
- Crystal_
- ChickasaurusGL
- v0id19

The following folks for bugfix collaberation
- kadetPirx
- JOBOalthor1992
- krazsen
- kmalove
- zycain
- jastolze007 
- MStern
- TSinnohTrainer 
- Chirutalis 
- coltongit

  
The shinpokered repository was branched from pret/pokered at [merge pull request #185 committed on Jul 2, 2018](https://github.com/pret/pokered/tree/c8599831992c91e521cf1d467ccae3d9498e42ef)
