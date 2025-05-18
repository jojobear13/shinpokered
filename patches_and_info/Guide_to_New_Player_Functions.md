#Updating an Old Save File
-----------------------------------------------
If the old save was from an earlier Shin Pokemon version, deactivate all special options and NPC toggles.  
Make a copy of the old save file. This will be your new save file.  
Load the new save with the latest version of Shin Pokemon.  
You will be automatically warped to Pallet Town.  
Save the game. Your save file is now updated.  

#### Troubleshooting  
If you are blocked by invisible walls, use the Softlock Warp (detailed below).  
On the old save, before transferring it over, saving outside in Pallet town can solve certain issues.  


#Some Changes to Particular Mechanics
-----------------------------------------------
#### Trade Evolutions  
Except for the Lite patches, pokemon that evolve by trade can also evolve by other means.  
  - Kadabra: Hinted at by a Pewter Museum NPC that comments on the moon stone. Use a moon stone at level 35.  
  - Haunter: Hinted at by the Lavender Town NPC that asks if you believe in ghosts. Use a thunder stone at level 35.  
  - Graveler: Hinted at by a Cinnabar Island NPC that talks about the mansion. Use a fire stone at level 35.  
  - Machoke: Hinted at by a house NPC in Pewter City that talks about trainers teaching pokemon. Use a leaf stone at level 35.  

Evolution by trade is still allowed and works as normal.  
  
#### Type Interactions  
Ghost moves (i.e. Lick) are now supereffective against Psychic types.  
Night Shade deals no damage to Normal type pokemon.  
Seismic Toss deals no damage to Ghost type pokemon.  
Normal-type trapping moves (Wrap and Bind) will not restrain Ghost types.  

#### Rage  
This move now lasts 2 to 3 turns to prevent getting stuck in an infinite loop.  
Any attack boosts gained during Rage are retained when it ends.  
In this way, Rage is almost like an alternate take on Bide.  
Having your Raging pokemon tank a multi-hit move is a great way to setup for a physical sweep.  

#### Bide  
Each hit of a multi-hit move now adds to Bide's damage instead of just the first.  
Needless to say, using Double Kick on a Bide-user has the potential to backfire horribly.  
Bide can still hit targets in the fly/dig state because, though technically a bug, why make Bide an even worse move?  

#### Transform  
Move slots cannot be rearranged when transformed to prevent acquiring glitch moves.  
When transforming into a pokemon and copying its Transform move, the PP of the copied move is set thusly.  
- The PP of the Transform move getting copied is read at the current instant.
- If > 5, then the copy Transform is set to 5 PP.
- If <= 5, then the copy transform is set to the current instant PP - 1.

This will prevent endless battles between two pokemon who can only transform.  

#### Sleep Status  
You can choose a move while asleep, and the move is used upon waking up.  
Sleep starts with a counter of at least 2 in order to maintain the accuracy of sleep effect moves.  
Rest now sets the sleep counter to 3 in order to preserve its lose-2-turns penalty.  
These changes help to remove the "infinite combo" that could be done by high-speed users of sleep moves.  
Overall, the only loss is that sleep has a maximum possible lost-turn number of 6 instead of 7.  

#### Trapping Moves  
Switching out of trapping moves (Wrap, Clamp, Fire Spin, etc) ends the move and wastes the trapper's turn.  
This matches what Pokemon Stadium enforces upon trapping moves.  
Additionally, except for the Lite patches, a 'poof' animation plays to signal the last turn of a trapping move.  

#### Critical Hits  
If a critical hit would do less damage than its non-critical amount, the non-critical amount will be used instead.  
Furthermore, the effect for Dire Hit and Focus Energy now work correctly and quadruple the critical hit rate.  
Also, each hit of a multi-hit move (such as Fury Attack) now has its own chance to critically hit.  

#### Accuracy, X-Accuracy, and One-Hit-K.O. Moves  
The 1-in-256 chance to miss bug on all moves has been fixed.  
X-Accuracy no longer gives OHKO moves 100% accuracy.  
X-Accuracy now allows OHKO moves to hit a faster opponent.  

#### New Random Number Engine  
The game now uses an XOR-shift-style pseudorandom number generator.  
This method is a good and speedy solution for 8-bit processors.  
The random seeds are taken from garbage values in HRAM on boot-up. Power-cycle your game if your luck is bad.  
Of note, all wild pokemon DV combinations are now possible regardless of the current map.  

#### Fixes/Improvements to Catching Mechanics and Safari Zone  
- The ball factors of 8 for Great balls and 12 for Safari balls have been swapped.  
  - This means that Great balls are no better at catching full-health pokemon than its peers.  
  - It also means that Safari balls are much better for catching full-health pokemon, as was likely intended.  
- The catch rate in Safari battles will now reset when either the "eating" or "angry" state end.  
- Throwing a Safari ball in the Safari Zone simplifies to the following process.  
  - Generate two random numbers: Rand1 in the range of [0, 125] and Rand2 in the range of [0, 255].  
  - A catch is made if (Rand1 <= pokemon's catch rate) and (Rand2 <= 127), effectively a chance of [catch rate / 252].  
- Except for the Lite patches, fleeing chance in the Safari Zone now uses [1.5 x Level] instead of [current speed].  
  - This greatly reins in fleeing by fast pokemon and slightly boosts fleeing by slow pokemon.  
  - The "angry" state flees at about 26%-36% per turn.  
  - Likewise, the "eating" state flees at about 3%-5% percent per turn.  
  - Therefore, rocks are fewer-turns-high-risk while bait is more-turns-low-risk.  
  - Try the following strategy:
    - Push your luck with the "angry" state by throwing rocks, doubling the catch rate each time.
    - Then throw a single bait, switching to the "eating" state at the cost halving the catch rate once.
    - Now throw Safari balls while enjoying a low flee chance with an increased catch rate.  

#### Psywave  
Exept for on the Lite patches, Psywave has undergone alterations to its statistical distribution for damage.  
Psywave will now roll for damage multiple times and use the best roll.  
The number of times that damage is rolled is based on the target's current HP with more HP causing more re-rolls.  
This makes the move have more consistent damage as well as higher average damage.  

#### Moves With Catch Bonuses  
Exept for on the Lite patches, certain moves now affect catching mechanics if known by your active pokemon in battle.  
- Razor Wind & Skull Bash - additive +10 to catch rate per toss of a non-safari ball.  
- Roar & Whirlwind - additive +20 to catch rate per toss of a non-safari ball.  
- Take Down - improves the ball factor of non-safari balls by 2.  
- Egg Bomb - improves the ball factor of non-safari balls by 2 and additive +10 to catch rate per toss of a non-safari ball.  

#### Level-Up Moves and Learnable TM/HMs  
Learnable moves via level and TM/HM have been adapted from Yellow version.  
It is not an exact copy. Particularly so with Eevee and its evolutions since Yellow had it serve as a boss-only Pokemon.  
Stone-based evolutions also get to learn a few more moves by level-up.  
Certain pokemon gain an extra TM move or two in their level-up list to play nicer with the AI.  
For full details, see the "Changes to Pokemon" section.  


#Debug Functions
-----------------------------------------------
#### Softlock Warp  
This will instantly teleport you back to your mom's house in Pallet Town if you get stuck.  
It also sets your money to at least 1000 if you have less than that.  
Use this warp if you find yourself unable to move after updating to a new patch.  
Instructions to perform:  
1 - Go to the start menu and put the cursor on OPTION.  
2 - Press and hold DOWN on the d-pad. The cursor will now be on EXIT.  
3 - While continuing to hold DOWN, press and hold SELECT.  
4 - While still continuing to hold the two aforementioned buttons, press B.  
5 - The start menu should close and you will warp back to your mom's house.  

#### Vanilla Options Reset  
This will undo all of the special options in case you are updating to a new patch.  
Instructions to perform:  
1 - Go to the start menu and put the cursor on the top option (usually POKEDEX).  
2 - Press and hold UP on the d-pad. The cursor will now be on EXIT.  
3 - While continuing to hold UP, press and hold SELECT.  
4 - While still continuing to hold the two aforementioned buttons, press B.  
5 - The start menu should close and you will hear a jingle.  

#### Debug Damage Display  
As a debugging cheat, damage values will be displayed in battle as the UI updates.  
Toggled on/off via the following method:  
1 - Go to the start menu and put the cursor on OPTION.  
2 - Press and hold DOWN on the d-pad. The cursor will now be on EXIT.  
3 - While continuing to hold DOWN, press and hold SELECT.  
4 - While still continuing to hold the two aforementioned buttons, press A.  
5 - The start menu should close. A PC "boot up" sfx will play to indicate ON, or "shutdown" sfx to indicate OFF.  

Zero damage is not displayed.  
Damage is not displayed if either pokemon has zero HP remaining.  

#### Debug RNG Seed Display  
At the title screen, press and hold A + SELECT until the main menu appears.  
This will display the 4-byte RNG seed at the main menu for debugging purposes.  

#### Debug DV / Stat EXP Reset  
Not available in the Lite patches.  
On your POKEMON party screen from the start menu, place the cursor over a desired pokemon.  
Then press A while holding LEFT + SELECT.  
You will be prompted to confirm your decision.  
If YES, that pokemon will have all its Stat EXP reset to zero.  
Also, it's DVs will be set to match the quantities of the first four items in your active bag.  


#Engine Functions
-----------------------------------------------
#### Extra Options Menu  
Press SELECT on the main options menu to go to the extra menu where several new features can be toggled.  

#### Color Correction (Y Shader)  
This applies when playing or emulating as a Gameboy Color game.  
It's assumed you are using a modern backlit screen with no other color correction.  
Under these stated conditions, the colors will be highly saturated.  
Press SELECT at the copyright screen when the game first boots (before the Gamefreak logo). 
- A sfx will play and a symbol will appear at the bottom right to let you know that it worked.  
- This will fix the saturated colors.  

Note: Can also be toggled in the extra options menu.  

Changing the destination code of the rom header to 00 (JP) defaults this to ON and pressing SELECT turns it OFF.  
Use the BGB emulator to easily change the destination code and fix the header checksum (https://youtu.be/2AaCkM597iU).  

#### Audio Type  
Updated Audio mixing has been ported over from Pokemon Yellow.  
Cycle through audio types on the extra options menu.  
You can cycle through mono sound and three types of stereo mixing.  

#### 60 FPS Mode  
This feature is more of a proof-of-concept and is still kinda rusty.  
Toggle this on the extra options menu.  
Playing as a GBC game will take advantage of the GBC's double-speed processor mode.  

#### Zero-Delay Text (Instant Text)  
This feature reinstitutes a speed-running trick that makes text print with zero frame delay.  
Toggle this on the extra options menu.  
Please note that other text speed selections do nothing while this feature is active.  

#### Enhanced Color  
Colorizes the overworld even further when playing an a GBC.  
Toggle this on the extra options menu.  

#### Sound Test  
Press SELECT on the extra options menu to get a sound test menu.
This way you can listen to the game's musical tracks.  
They even continue to play once you've backed out of the options menu.  

#### Quick Cursor Run  
When on the main battle menu, pressing B will automatically place the cursor over RUN.  


#Difficulty Settings
-----------------------------------------------
#### Hard Mode  
Toggle this on the extra options menu.  
Playing in hard mode imposes several changes to the game's systems that increase difficulty:  
1 - Enemy trainer pokemon are assigned level-appropriate StatEXP whereas they previously had none.  
2 - Enemy trainer pokemon have above-average DVs whereas they previously all had values of 8 or 9.  
3 - Stat boosts granted by badges are disabled during trainer battles.  
4 - X-stat items increase by two stages instead of one like in more recent generations.  
5 - Revive items can only be used outside of battle.  
6 - Wild Mewtwo uses trainer AI to choose its moves, and it also blocks you from using a Master Ball.  
7 - Non-link battles in hard mode use the Stadium 1 formulas for critical hit probability.  
8 - Wild pokemon DVs get 1 re-roll each if less than 4, biasing them upwards a little bit.

#### AI Trainer Switching (AI Swaps)  
- Toggle this on the extra options menu. Activate by setting it to SMART. 
- This feature allows enemy trainers to switch somewhat intelligently.
- Note: If disabled, Jugglers are unaffected because their official gimmick is that they switch randomly.

#### Obedience Level Cap  
Not available in the Lite patches.  
There is now an obedience level cap that can be toggled in the extra options menu.  
While active, the current maximum obedience level will display in the extra options menu.  
All pokemon, not just trades, will start to disobey if over the displayed level cap.  
The cap will change based on which badge you have.  
This is intended as an alternative to, and not to be used with, the Scale Enemy Trainer Levels feature.  
It provides a different challenge where one is forced to keep a team within the game's level curve.  
Players should deactivate this feature for post-game adventuring past the level cap.  

#### Scale Enemy Trainer Levels  
Not available in the Lite patches.  
Talk to the aide in the lower-right section of Oak's lab to toggle this feature.  
While active, enemy trainer roster levels will scale upwards relative to the highest-level pokemon in your party.  
Normally, this scaling factor will be based on a weighted average of your whole team.  
But on hard mode, or against Gym Leaders, the scaling will be based on the absolute highest level member of your team.  
Enemy pokemon will evolve by level if applicable (biased to higher levels).  
Gym leaders and the Elite-4 scale slightly higher than normal trainers.  
Warning - The difficulty will be compounded if both trainer scaling and hard mode are active.  


#Battle Modifiers
-----------------------------------------------
Note: These are not available in the Lite patches.    

#### Wild & Starter Pokemon Randomization  
The girl in Oak's lab toggles on/off a built-in randomizer for wild pokemon.  
It shuffles all pokemon that can be gained through walking, surfing, fishing, or from the Celadon Prize Corner.  
If activated early enough in the game, your starter pokemon choices are randomized as well.  
Scripted events are unaffected (gifts, in-game trades, static encounters, etc).  
The game's five legendary pokemon are also excluded from randomization.  
A saved seed value is used, so the shuffled order is always preserved between play sessions.  
This lets the AREA feature of the pokedex automatically adjust for the new pokemon locations.  
And a new random seed is generated upon each new game.  
Talking to the girl in Oak's lab allows the player to generate a new randomization seed value.  
Shuffling is done using three internal pokemon lists defined by base-stat-total: A, B, and C tiers.  
Pokemon are only shuffled within their own tier list in order to maintain some modicum of balance.  
The girl will also ask if full randomization is preferred, which will combine the tiers into one big list.  

#### Regular Trainer Randomization  
One of Oak's Aides has been added to the Viridian Pokemon Center. Talk to him to toggle this feature.  
This randomizes the teams of regular no-name trainers that do not have roster customization.  
This randomization method uses different curated lists based on level in order to maintain some balance.  

#### Sleep, Freeze, and Item Clauses  
The house to the lower-left of Viridian Gym is home to three new NPCs named the Clause Brothers.  
Each one toggles enforcement of either the item, sleep, or freeze clause from Pokemon Stadium.  
The sleep clause in particular works like it does in Stadium with respect to using the Rest move.  
The clauses apply to the player and AI equally, and they only apply during trainer battles.  

#### Trapping Move Clause  
- A fourth brother has been added for this new clause.
  - A counter tracks if the player or the opponent use trapping moves like Wrap multiple times in a row. 
  - The counter increments only if a trapping effect move is selected to be used and it does not miss.
  - After the counter has incremented to 2, 
    - selecting a trapping effect move additional times will make the move to go 2nd in the round. 
    - this is the same priority as the move Counter.
  - The counter only gets reset by switching or using a move that does not have the trapping effect. 
  - Resetting the counter will restore normal priority to trapping effect moves.

#### Hyper Beam Clause  
- Added a fifth Clause Brother for the hyper beam clause.
- Hyper beam will recharge if it KOs the opponent.

#### Battle Clauses Over Link  
- Link battles in the Colosseum now synchronize battle clauses between both players.  
  - The item clause is not applicable because items are not usable in link battles by default.  
  - There is a clipboard in the Colosseum that is used to reset and re-select your battle clauses.  
  - Any active clauses between your opponent and yourself are applied to both players.  
  - A splash screen before battle will display the enforced clauses.  

#### Active Pokemon Stat Displays  
- The stat displays of the active pokemon in battle will:
  - Display its current-moment stats instead of its unmodified stats.  
  - For example, using swords dance will reflect on the active pokemon's status screen in battle.  


#Button-Activated Features
-----------------------------------------------
Note: These are not available in the Lite patches.    

#### Running Shoes  
Hold the B button to move at double your normal speed.  
This also works when surfing or using your bike.  

#### One-Button HM Usage  
You must still have the correct badge and move on one of your pokemon to use a HM in this way.  
HM01 - Press SELECT when facing a shrub or grass tile to use CUT.  
HM03 - Press SELECT when facing a shore to use SURF.  
HM05 - Press SELECT in a dark area to light it with FLASH.  
HM04 - Press SELECT while facing a boulder to activate STRENGTH. Your pokemon's cry plays and the screen will flash.  

#### Quick Fishing Button Combo  
You must have a fishing rod in your bag.  
Face against a shore. You may have to bump against it a single time.  
Press and hold A. While doing that, press SELECT. You can now release the two buttons.  
This will prompt the game to choose the best rod in your bag and use it.  

#### Quick Bike Button Combo  
You must have the bicycle in your bag.  
You must not be facing a shore.  
Text for NPCs, signs, objects, etc, have priority, so do not face toward these things.  
Press and hold A. While doing that, press SELECT. You can now release the two buttons.  
This will tell the game to get on your bike. You can also get off your bike the same way.  

#### Extra Bag Pocket  
The bag now supports an additional item list for an extra 20 slots of space.  
Press START while in the bag menu to hot-swap the item list that populates the active bag.  
Press and hold LEFT or RIGHT then press START to send the item the cursor is over to the non-active bag space.  
This also works in battle or when depositing items into the PC.  
In general, the non-active item list gets recognized by the game's systems.  
For example, you can enter the Cinnabar Gym even if the Secret Key is in the non-active bag space.  
For certain unique systems, like Pokemon Stadium compatibility, only the active bag list is detected.  

#### Bag Auto-Sort  
You can now automatically sort all the items in the bag menu or the PC item menu.  
Hold SELECT and press START while on the bag or PC item menu to auto-sort your items.  

#### Display Pokemon DVs  
Determinant Values (DVs) are the predecessors to the Individual Values (IVs) used in Gen 3 and onwards.  
Unlike IVs, DVs are on a scale from 0 to 15.  
On the pokemon menu, select a pokemon and place the cursor over STATS.  
While holding the START button, press the A button to enter the pokemon's status screen.  
In place of the pokemon's HP and stat values, it's corresponding DVs will be displayed instead.  

#### Display Pokemon Stat EXP  
Stat Experience (StatEXP) is the predecessor to the Effort Values (EVs) used in Gen 3 and onwards.  
Unlike EVs, StatEXP values are on a scale from 0 to 65535 and there is no sum total limit between stats.  
At level 100, a pokemon gains extra points in a stat equal to 0.25 x SQRT(StatEXP) rounded down.  
On the pokemon menu, select a pokemon and place the cursor over STATS.  
While holding the SELECT button, press the A button to enter the pokemon's status screen.  
In place of the pokemon's HP and stat values, it's corresponding StatEXP values will be displayed instead.  

#### Forfeit Trainer Battles  
You can now forfeit a trainer battle to force yourself to black out.  
This can be useful for escaping in-battle softlock scenarios or creating variants of Nuzlocke rules.  
On the main battle menu, place the cursor over RUN.  
While holding the SELECT button, press the A button.  
You will be asked to confirm your decision. Choose YES to forfeit or NO to cancel.  

#### Shiny Pokemon and Viewing a Shiny Palette
Pokemon can be shiny based on the same DV criteria used for Gen-2 Pokemon games where the shiny feature debuted.  
This means caught shiny pokemon can be transferred between Gen-1 and Gen-2 games and still remain shiny.  
An indicator of three sparkles will appear by a pokemon's name in battle and the status menu if it is shiny.  
The shiny pokemon will also have a palette swap color if playing as a Game Boy Color or Super Game Boy game.  
You can view a pokemon's shiny palette easily in the pokedex.  
- Choose a pokemon in the pokedex and place the cursor over DATA.  
- While holding the SELECT button, press the A button to view it's pokedex entry.  
- The pokedex entry will display the pokemon with its shiny palette swap.  

#### Audio Cue for Owned Pokemon  
On the main battle menu, place the cursor over an option in the left column (FIGHT or ITEM).  
Press the SELECT button.  
The active enemy pokemon will play its cry if that species is registered as Owned in your pokedex.  

#### New Game Plus  
Activated under these conditions:  
1 - Must have an existing non-corrupt game save on-file.  
2 - Must have beaten the Elite-4 in the on-file save.  
3 - Press and hold SELECT while choosing the NEW GAME option.  
4 - A jingle will play to indicate NG+ has activated and the SELECT button can now be released.  

Preserves ONLY the following information (your current party will be lost):  
- Boxed pokemon  
- Play clock  
- Pokedex seen/owned registry  
- Hall of Fame (experimental)  
- Option screen selections  
- Trainer ID (boxed pokemon won't count as traded)  
- Wild pokemon randomizer seed

The player can choose whether or not to generate a new Trainer ID when selecting New Game Plus.  


#Gameplay-Related Features
-----------------------------------------------
Note: These are not available in the Lite patches.    

#### Female Trainer Option  
When choosing NEW GAME, you will be asked if you are a boy or a girl.  
Choose GIRL to play as the female trainer.  
Choose BOY to play as the usual male trainer.  

#### Temporary Field Move Slots  
When teaching a pokemon a field move outside of battle, such as with a HM, this feature becomes apparent.  
You will be asked if you would like to teach it as a temporary field move.  
If so, it will be learned into a special field move slot that is separate from the normal list of four moves.  
Such a temporary move cannot be used in battle, but it can be used in the overworld as normal.  
Each pokemon on your team can have one temporary field move at a time.  
Having one will display it on the status screen above the pokemon's other moves.  
A temporary field move cannot be overwritten with another field move.  
But it will be erased if its owning pokemon leaves the party (such as by being deposited in the PC).  
If all four of a pokemon's regular moves are field moves, its temporary field move cannot be menu-selected.  
But if a fifth field move in the temporary slot is a HM, it can still be activated via One-Button HM Usage.  
Teaching a TM as a field move will not consume the TM.  

#### Rematch Trainers  
The gym leaders and most trainers can be rematched.  
Simply talk to them once or twice. Select YES when prompted.  
If Giovanni has disappeared from his gym, exit and re-enter the gym to bring him back.  

#### Reworked Fishing  
- The locations of the Good Rod and the Super Rod have been swapped.  
- Route 12 has been altered to give access to its Fishing Guru without needing the Pokeflute.  
- All rods now randomly add 0 to 7 levels to anything hooked.  
- The Old Rod can fish up two kinds of pokemon (depending on the current map).  
  - Magikarp or Goldeen
  - Magikarp or Poliwag 
- When using the Old Rod, press and hold B within about 1 second to always hook a magikarp.  
- The Good Rod can fish up three or four kinds of pokemon (depending on the current map).  
  - Poliwag, Horsea, Krabby
  - Poliwag, Krabby, Goldeen, Psyduck
  - Goldeen, Psyduck, Shellder
  - Goldeen, Shellder, Horsea, Tentacool
  
#### PokeDex AREA Enhancements  
- The AREA function of the PokeDex now takes the Super Rod into account.
- It will also notify you if the Pokemon you are referencing is available on the currently loaded map.
- If available on the current map, it will notify you if it can be found by walking, surfing, or by super rod.
- The Cerulean Cave is an "unknown dungeon" so...
  - Nest icons will not display for this location.
  - But the notification for the current map will still function.

#### Improved Itemfinder Function  
- If an item is detected, it will play 1 to 3 chimes depending on how close it is (more chimes means closer to the item).
- Lines will point in the direction of the item and flash with the chimes.
- If the player is right on top of the item, no lines will show and the chime will play four times.
- If the SELECT button is held while selecting to USE the itemfinder, then the original itemfinder function is used.
  
#### Reworked Daycare  
The daycare lets you select moves to forget (if any) upon retrieving your pokemon.  
After trying to learn all the moves it can up to its new level, it will try to evolve if applicable.  
After evolving, it tries to learn any other moves between its evolution threshold level and its new level.  
If it can evolve again by level, it will try to do so and once more try to learn any moves it may have missed.  
The daycare experience gain has been recalibrated. It no longer gives 1 exp per step.  
Instead, it falsifies the act of farming wild encounters against a pokemon with a base exp value of 56.  
The falsified encounter starts at level 5, and it increases 5 more levels per badge obtained.  
With 8 badges, using the daycare is essentially a faster way of farming level 45 basic pokemon.  
The downside of not gaining StatEXP in the daycare still remains as a tradeoff.  
Consider using the daycare as a way to outsource some grinding while you go focus on other things.  
And yes, pokemon with HM moves are now allowed in the daycare.  
The daycare now has a PC for the player's convenience.  

#### The Shimmer  
- This is a cheat feature for those who want more viability when using certain low-regarded pokemon.
  - Toggled ON/OFF via the glass pokeball decoration in the rival's house.
  - Pokemon Eligible: EKANS, CATERPIE, METAPOD, WEEDLE, KAKUNA, ZUBAT, PSYDUCK, PARAS, PONYTA, RATTATA, SANDSHREW, HORSEA, GOLDEEN, VENONAT, JIGGLYPUFF, ARBOK, BEEDRILL, BUTTERFREE, DITTO, FARFETCHD, GOLBAT, GOLDUCK, HITMONCHAN, LICKITUNG, ONIX, PARASECT, PINSIR, PORYGON, RAPIDASH, RATICATE, SANDSLASH, SEADRA, SEAKING, VENOMOTH, WIGGLYTUFF
  - The shimmer factor appears randomly and secretly, being more likely to occur by training and sending out eligible 'mons.
    - Each time an eligible 'mon is sent out into battle will trigger a random chance of it occurring.  
    - The base chance is 1-in-256.  
    - The base chance increases by an additional +(1-in-256) for every 2048 StatEXP the 'mon has in its HP stat.  
  - The shimmer only manifests in 'mons that are fully evolved, even if their pre-evos gained the secret shimmer factor.
  - When the shimmer manifests as a 'mon gets sent out, that 'mon gets a large boost to some stats that are low-to-poor.
  - The boost when the shimmer activates is as follows:
    - Affects the pokemon's unmodified Attack, Defense, Speed, and Special when it gets sent into battle.  
    - If a stat is less than 8/3rds its level, then add its level to that stat.  
  - There is a slight chance that the shimmer will manifest on applicable enemy trainer pokemon.
  - Certain boss-like enemy trainers will always manifest the shimmer on their applicable pokemon.


#Trainer-Aiding Features
-----------------------------------------------
Note: These are not available in the Lite patches.    

#### Caught Symbol and Gender Symbol  
Talk to the aide in the lower-left section of Oak's lab to toggle this feature after obtaining the pokedex.  
While active, it has the following effects:  
1 - Wild pokemon have a gender symbol by their names if applicable.  
2 - If applicable, a gender symbol is added to a pokemon's status screen.  
3 - Enemy wild pokemon that have already been registered as Owned will display a pokeball symbol in battle.  

Gender is determined the same way as Gen 2 for the purposes of cross-generation transfers.  

#### Move Deleter and Relearner  
Two new NPCs are added to the Saffron City house below COPYCAT's house.  
Talk to the little girl to delete moves.  
Talk to her tutor to relearn moves for a small fee.  

#### Coin Gentleman  
There is a gentleman added to the Celadon Hotel as an alternative to playing the slots.  
He will give you free game corner coins if you show him the pokemon he requests.  
His request changes every time you enter the hotel, so make use of the hotel's PC to the right.  
Place his requested pokemon at the top of your team and speak to him to get your reward.  

#### Catch-Up EXP Booster  
Talk to the aide in the Celadon Diner to toggle this feature.  
While active, EXP gained is boosted if the active pokemon's level is lower than that of the fainted enemy.  
The boost is 1.5 multiplied by an additional 1.5 for every 3 levels of difference.  
For example, a level difference of 9 results in an EXP multiplier of (1.5)^4 = 5.0625.  
Use this feature to help you train-up new team members in the mid-to-late game.  

#### Get a Free Paras  
Go to the small house on Route 2 just below the exit of Diglett's Cave.  
The Aide NPC inside the house will now gift you a Paras.  
You can use this Paras if you ever find yourself without a pokemon that can learn Cut.  

#### Joe's Drink Stand  
A new drink stand has been set up on the Route 19 beach below Fuchsia City.  
It sells vending machine drinks in multiples like a pokemart.  


#Post-Game Additions
-----------------------------------------------
Note: These are not available in the Lite patches.    

#### SS Anne Tournament  
You can return to the SS Anne after beating the Elite-4. Find the Gym Guy hanging out in the kitchen.  
He is organizing a little tournament with the following rules:  
1 - Seven matches to win.  
2 - Must use a team of exactly three pokemon.  
3 - Your pokemon are healed after every match.  
4 - Enemy pokemon levels are based on the level of your strongest party pokemon.  
5 - You must have an open item slot to claim your prize.  
6 - Any trainer can appear with any three pokemon (excluding mew and mewtwo).  
7 - No breaks allowed in-between battles.  

Winning the tournament rewards you with a Master Ball.  

#### Rare Item Shop  
The 3rd floor of the Celadon Department Store has a shop open up after beating the Elite-4.  
It sells MASTER BALL, MAX REVIVE, RARE CANDY, MOON STONE, DOME FOSSIL, HELIX FOSSIL, OLD AMBER, and the EXP ALL.  

#### Uncapped Vitamins  
After beating the Elite-4, vitamins have no limit placed upon them when used on pokemon of level > 30.  

#### Selling Pokemon  
Find the house with the game corner CHIEF in Celadon City.  
Talk to him after beating the Elite-4 to find he's in some dire straights.  
He will offer to buy the pokemon in your team's first slot from you.  
The value is based on the pokemon's DVs, level, catch rate, and whether it is shiny or not.  

#### Bulk Coin Seller  
One of the Rocket grunts walking around the top left corner of Celadon City will now sell you 1000 coins at a time.  

#### Special Safari Event  
A new NPC can be utilized in the Safari Zone Gate after beating the Elite-4.  
Talk to him to toggle special parameters that have the following effects on the Safari Zone:  
- All pokemon encountered will have above-average DVs.  
- There is a rare chance for any non-legendary pokemon to appear.  

#### Mirror Match Battle Generator  
Pagliacco, a pokemaniac with a flair for theatrics, has been added to the north-south underground path.  
After the Elite-4 are beaten, he will offer to engage you in a mirror match against your own party.  

#### Mr. Fuji and the M.GENE  
Put Mewtwo at the head of your party and talk to Mr. Fuji to get the new M.GENE consumable item.  
The M.Gene can be used on a pokemon out of battle in order to re-randomize its DVs with above-average values.  
This constitutes a scrambling of DNA, so it may affect that pokemon's sex and shiny status.  

#### Random Battle Generator  
There is a sketchy guy added to the west-east underground path.  
After the Elite-4 are beaten, he will offer to engage you in randomized battles.  
Win 5 matches in a row against him without leaving the area to get more M.GENE items.  

#### Finding Mew  
Mew is available to catch after viewing your completed 'Dex diploma in the Celadon Gamefreak building.  
Mew shows up on only one map, it is level 70, and it is a random encounter.  
A message will hint that you are on the right map.  
The random encounter for Mew only happens a single time. You have only one opportunity to catch it.  

#### The Secret of the MIST STONE  
The MIST STONE will max-out all the StatEXP of the lvl > 30 pokemon on which it is used.  
If all the StatEXP is already at max, then it will set all the DVs to maximum instead.  
But this assumes you are able to find the secret room for obtaining it.  
Here's a hint. There is a cave entrance hidden on the overworld just out of sight off the beaten path.  

#### Special Trainer Battles  
There are four special trainers to find and defeat after beating the Elite-4.  
The first is Oak. Talk to him at his lab, and select NO when he asks to rate your 'Dex.  
Each victory will hint towards the next special trainer's location.  
Beating the fourth special trainer at the Vermilion Dock will hint to where Mew is located.  
Beating all four special trainers will enable a final fifth battle outside Bill's Villa.  
Beating the fifth special trainer will:
- Respawn all the legendaries
- Reset the Mew event so it can be re-encountered
- Reset the Mist Stone event to make it re-obtainable
- Reset the fifth trainer itself, so you must defeat the other four again (any order) to re-challenge

#### Bill's Secret Garden  
It is possible to get behind Bill's house if you show him a "new species" of pokemon.  
The area behind this house will let you encounter rare pokemon at level 5 such as the starters.  
These pokemon have a 1-in-128 chance to be shiny.  

#### The Scourge of Missingno  
Missingno can be activated after viewing your completed 'Dex diploma in the Celadon Gamfreak building.  
Talk to the old man in Viridian and watch his catching tutorial. Then start surfing up and down the east Cinnabar shore.  
Win or lose, you have to reactivate the battle via the old man.  
If you win the battle, the item in your 6th bag slot will be multiplied.  

#### The Scourge of Missingno Part II  
An even harder Missingno battle can be challenged.  
It works the same as previous, except the player should start surfing up and down the east Seafoam shore.  
If you win the battle, the item in your 6th bag slot will be multiplied and a special flair will be added to your diploma.  


#Pro-Tips
-----------------------------------------------
Note: These are not applicable to the Lite patches, except for increased trainer aggression. Really...buy healing items.  

#### Gift, Prize, and Trade Pokemon  
Pokemon that are given to you by NPCs have above-average DVs.  
This applies whether it is a gift, in-game trade, or a purchase.  
This means that prize pokemon from the game corner will always have good stats.  
And buying a magikarp from a shady figure might not be such a bad investment.  

#### Stock-Up on Items  
Enemy trainers are more aggressive about attacking, so your team incurs more damage over time.  
Be sure to purchase a reasonable stock of healing items to counter the increased attrition.  

#### Big EXP Gains  
The Catch-Up Booster bonus compounds with other 1.5x EXP bonuses in the game.  
With this is in mind, activate level-scaling and do trainer rematches with a traded pokemon to gain loads of EXP.  

#### Training in Post-Game Without Battling  
Here is an alternative to grinding out battles in the post-game.  
1 - Catch some pokemon.  
2 - Sell them to the game corner chief.  
3 - Buy rare candies and vitamins with the proceeds.  
4 - Take note that vitamins are uncapped in the post-game for 'mons with lvl > 30.  
5 - Use your purchases to train your roster pokemon without battling.  

  
#Item and Pokemon Availability
-----------------------------------------------
Note: These are not applicable to the Lite patches.  

#### Expanded TM Availability  
Though still single-use, all TMs can be repurchased around the region.  
So don't be shy about using TMs acquired from NPCs and exploration.  
- Viridian Mart
  - Egg Bomb
  - Softboiled
- Pewter Mart
  - Pay Day
  - Dream Eater
- Cerulean Mart
  - Whirlwind
  - Bide
- Vermilion Mart
  - Water Gun
  - Thunder Wave
- Lavender Mart
  - Bubble Beam
  - Dig
  - Rest
  - Rockslide
- Celadon Mart 2F
  - Doubleteam
  - Reflect
  - Razorwind
  - Horn Drill
  - Dragon Rage
  - Mega Punch
  - Mega Kick
  - Takedown
  - Submission
- Celadon Mart 5F
  - Body Slam
  - Rage
  - Self-Destruct
- Celadon Prize Corner
  - Thunderbolt
  - Hyper Beam
  - Blizzard
- Fuchsia Mart
  - Teleport
  - Mimic
  - Swift
  - Tri-Attack
  - Substitute
- Saffron Mart
  - Double-Edge
  - Counter
  - Seismic Toss
  - Metronome
- Cinnabar Mart
  - Swords Dance
  - Toxic
  - Ice Beam
  - Mega Drain
  - Skull Bash
  - Psywave
- Indigo Mart
  - Solar Beam
  - Thunder
  - Earthquake
  - Fissure
  - Psychic
  - Fire Blast
  - Sky Attack
  - Explosion

#### Changes to Item Locations  
- Additional hidden potion in viridian city
- Added a hidden potion on route 22
- Added two hidden repels to pewter city
- Water Gun TM has been replaced by a super repel in Mt. Moon
- Water Gun TM is now found in the Pewter Museum
- Added a hidden great ball and pokedoll on route 6
- Added a hidden max revive on route 11
- Added a hidden ultra ball on route 8
- Added a hidden max revive in celadon city
- Added a hidden super potion in celadon city
- Hidden Hyper Beam TM on the vermilion dock
- Hidden nugget on the vermilion dock
- Hidden Moon Stone on Route 4 past the Cerulean Cave entrance

#### Changes to Mart Inventories  
- Pewter city has ethers
- Cerulean mart sells escape rope per Yellow version
- Lavender town has max ethers
- Fuchsia mart sells hyper potions per Yellow version
- Saffron city has elixirs
- Cinnabar island has max elixirs

#### Full Pokemon Availability  
All Pokemon can be caught within a single game pak, but rarity and location sometimes differs with game pak version.  
- route 22 super rod data has changed to give psyduck & poliwag
- sandshrew (5.1%) and ekans (5.1%) on route 3
- bulbasaur on route 4 (4.3%)
- squirtle on route 6 (4.3%)
- charmander on route 25 (4.3%)
- bellsprout (4.3%: red, blue-jp) or oddish (4.3%: blue, green) on route 24
- meowth (9.8%: red) or mankey (9.8%: blue, green, blue-jp) on route 5
- snorlax in digletts cave (5.1%)
- magnemite on route 10 (5.1%)
- cubone added to rock tunnel (5.1% floor 1 and 6.3% floor 2)
- vulpix (4.3%: red, blue-jp) or growlithe (4.3%: blue, green) on route 8
- ponyta on route 7 (9.8%)
- farfetchd on route 12 (6.3%) and route 13 (4.3%)
- dodrio on route 17 (5.1%)
- version-swapped pinser/scyther in safari zone central-area
- lickitung (5.1% red, blue, green) in safari zone east
- kangaskhan (5.1% blue-jp) in safari zone east
- tauros (5.1% blue-jp) in safari zone north
- jynx (5.1% red, blue, green) in safari zone north
- mr mime in safari zone west (5.1%) 
- lapras replaces krabby when using super rod in safari zone
- porygon in the power plant in red version (1.2%)
- electabuzz in power plant in all versions (9.4% red and 5.1% all others)
- magmar in pokemon mansion basement in all versions (4.3%)
- tentacruel on water routes 19, 20, and 21 (6.3%)
- seaking on water routes 19, 20, and 21 (4.3%)
- eevee on route 21 grass (5.5%)
- hitmonchan (5.1%) & hitmonlee (5.1%) in victory road 3f
- version-swapped sandslash/arbok in cerulean cave 1f


#Built-In Nuzlocke Mode
-----------------------------------------------
Note: Not available in the Lite patches.  

- Toggle this mode in the extra options menu.  

- This mode now checks if you have had access to pokeballs on the save file.  
  
#### Rule 1: Pokemon Death  
- A pokemon that faints is considered dead and can no longer be used.
  - Revival items cannot be used in battle.
  - If a battle ends with no forfeiture, all pokemon with 0 HP are marked dead.
  - If a battle ends in a forfeit, all pokemon with 0 HP before the forfeit are marked dead.
  - Pokemon marked as dead have $05 written to their catch rate to permanently mark them.
  - Even if they are traded back and forth, dead pokemon remain marked as dead while in nuzlocke mode.
  - Medicinal items will not work on pokemon marked as dead, nor will Softboiled.
  - Party healing (Mom, Pokemon Center, blacking out, etc) makes a dead pokemon effectively useless.
  - To clarify, it gives a dead pokemon 1 HP, the FRZ status, and 0 PP for all moves.
  - This allows a player to continue the game with boxed pokemon in case of a total party loss.
  - Dead pokemon transferred to Gen-2 games will be holding a pokeball.

#### Rule 2: Restricted Catching  
- You can only catch the 1st wild pokemon that you encounter in an area.
  - An "area" is defined by the name displayed on the town map.
  - You will be unable to throw balls in subsequent wild battles in that area.
  - Static wild battles count for this as well.
  - Wild battles do not count when early in the game and you have no access to pokeballs.
  - Story wild battles (Old Man tutorial, Ghost Marowak, and Tower Ghosts) do not apply.
  - Pokemon gained outside of battle (gifts, prizes, in-game trades, etc) do not apply.
  
#### Rule 3 (Optional): Nicknaming 
- Nickname every pokemon you obtain.
  - You will always go straight to the nickname screen without a Yes/No prompt.
  - You can still opt out of a nickname by leaving the entry field blank.
  
#### Built-in exceptions: Clauses  
- Shiny Clause: Nothing prevents you from throwing balls to catch a wild shiny pokemon.
- Duplication Clause: Encountering a wild "owned" pokemon will not activate Rule 2.
- Rule 2 resets for the Safari Zone area upon paying the entrance fee.
- Catching a pokemon, even if owned, always activates Rule 2. Important for the Safari Zone and New Game+.
- Dead pokemon can still use field moves (HM moves, Teleport, etc).

#### Visual Aides  
- An Up-Down-Arrow symbol will display on the HUD of a wild pokemon if a ball is allowed to be tossed.
- This symbol follows Rule 2 and any built-in exceptions previously described.

#### Nuzlocke and the Safari Zone  
- The Safari Zone is not inherently limited to a single catch opportunity in nuzlocke mode.
- Entering the Safari Zone gives the player an opportunity to catch 1 pokemon per visit.
- This opportunity presents itself again each time the player pays the entry fee.

#### Nuzlocke and New Game+  
- New Game+ preserves the pokedex.
- This means the Duplication Clause will prevent Rule 2 from activating.
- In light of this, Rule 2 will always activate on an area upon the first catch made there.

#### Dead pokemon and Toggling Nuzlocke Mode
- It is possible to cheat by turning off nuzlocke mode, healing a dead pokemon, then turning it back on.
- If this is done, the healed pokemon is still considered dead.
- This means that party-wide healing will make it useless and medicine still has no effect.
- This has the potential for a kind of "undead run" rule variant.
 
#### Removing the Death Marker  
- The only way to unmark a pokemon from being "dead" is by modifying its catch rate byte.
- This is usually done via the Gen-2 time capsule and trading it back without a hold item or a different hold item.


#Gene Engineering Pokemon  
-----------------------------------------------
Note: This is not available in the Lite patches.    

This process clones your 1st spot pokemon and modifies it with DNA from your 2nd spot pokemon.  
It does this by treating a pokemon's two bytes of DV values as if they were two genes with two alleles each.  
Gene-A has the Attack DV as its hi-side (dominant) allele and the Defense DV as its lo-side (recessive) allele.  
Gene-B has the Speed DV as its hi-side (dominant) allele and the Special DV as its lo-side (recessive) allele.  
The A-genes from the two donor pokemon will be mixed to make the clone's A-gene.  
The B-genes from the two donor pokemon will be mixed to make the clone's B-gene.  
Mixing two genes is done via Punnett Squares, and a random result is chosen based on its ratios.  
A DV byte is assembled for each Punnett quadrant:  
- Dominant alleles make up the upper four bits.  
- Recessive alleles make up the lower four bits.  
- When there are two dominant or two recessive alleles...  
  - Randomly choose one of the alleles to make up the upper four bits, changing to or staying dominant.  
  - The other allele will make up the lower four bits, changing to or staying recessive.  

Allele - Stat    
A - Attack  
a - Defense  
B - Speed  
b - Special  

| Parent 1 | Parent 2 A  | Parent 2 a  |  
|:--------:|:-----------:|:-----------:|  
|    A     |A1A2 or A2A1 |    A1a2     |  
|    a     |    A2a1     |a1a2 or a2a1 |  

| Parent 1 | Parent 2 B  | Parent 2 b  |  
|:--------:|:-----------:|:-----------:|  
|    B     |B1B2 or B2B1 |    B1b2     |  
|    b     |    B2b1     |b1b2 or b2b1 |  

Talk to the new scientist in the fossil room of the Cinnabar Lab to get started.  
For a small fee, a gene sequence listing the clone's new DV values in order is randomly determined.  
If the clone's DVs are acceptable, you may pay a larger fee to gestate the clone.  
Hint: This makes it possible to selectively breed for shiny pokemon in a more realistic way.  

Example of selecting for a shiny pokemon:  
- A shiny pokemon in gen 2 has the 2-byte hex value of $XAAA for its DVs.
  - Wherein 'X' is the Attack DV composed of the 4 bits %yy1y.
  - And 'y' bits are "don't care" values that can be either 0 or 1.
- The first goal is to get $AA as the value for the B-gene.
  - The minium requirement is to cross two pokemon that both have at least one $A in their B-genes.
  - This minimum requirement results in a 25% chance of getting a value of $AA. 
- The second goal is to get $A as the lo-side allele value for the A-gene.
  - The minium requirement is that one of the donor pokemon have at least one $A in its A-gene.
  - This minimum requirement has a 12.5% chance of fulfilling the goal if the donor $A is a hi-side allele.
  - Note: Said chance increases to 37.5% if the donor $A is a lo-side allele.
- The third goal is to get a 'X' value (previously described) as the hi-side allele value for the A-gene.
  - The minium requirement is that one of the donor pokemon have at least one 'X' in its A-gene.
  - This minimum requirement has a 12.5% chance of fulfilling the goal if the donor 'X' is a lo-side allele.
  - Note: Said chance increases to 37.5% if the donor 'X' is a hi-side allele.
- Assuming only the most minimal requirements are met, the chance of a shiny is [12.5% * 12.5% * 25%] = 1/256.
  - Keep in mind that the default chance of a shiny pokemon is 1/8192.
  - You can boost the chances higher by increasing the number of donor $A alleles and optimizing allele placement.
  - The chances of getting a shiny by crossing two shiny donors is 50%.

Example:  

| Parent 1 | Parent 2 $4 | Parent 2 $A |  
|:--------:|:-----------:|:-----------:|  
|    $F    | $4F or $F4  |    $FA      |  
|    $5    |    $45      | $5A or $A5  |  

| Parent 1 | Parent 2 $A | Parent 2 $7 |  
|:--------:|:------------|:-----------:|  
|    $9    | $9A or $A9  |    $97      |  
|    $A    |    $AA      | $7A or $A7  |  

Top-right quadrant for the A-gene and bottom-left quadrant for the B-gene gives shiny DVs of FAAA.  


#Changes to Trainers (SPOILERS)  
-----------------------------------------------
Note: These are not applicable to the Lite patches.  

#### Regular Trainer Changes
- Certain Trainers have undergone slight roster changes so that all pokemon can be seen under normal game settings.
  - Lvl 24 lass on route 8 exchanges two meowths for jigglypuff and eevee
  - Lvl 22 lass on route 8 exchanges one clefairy for clefable
  - Lvl 24 jr.trainer-f on route 13 exchages one meowth for dratini
  - Lvl 36 super nerd in cinnabar gym exchanges one vulpix for a flareon
  - Lvl 21 engineer on route 11 exchanges his magnemite for a porygon
  - Lvl 18 engineer on route 11 exchanges two magnemites for ditto and electrode
  - Lvl 24 fisher on route 12 gains omanyte and kabuto
  - Lvl 35 beauty on route 20 swaps her seaking with a vaporeon
  - Lvl 20 rocker in vermilion gym replaces one voltorb with pikachu
  - Lvl 29 rocker on route 12 replaces his voltorb and electrode with electabuzz and jolteon
  - Lvl 48 juggler in victory road 2F replaces his mr. mime with tangela an golem
  - Lvl 34 juggler in Fuchsia gym with drowzee and kadabra replaced by cooltrainer-f with golbat and venomoth (easter egg)
  - Lvl 31 juggler in Fuchsia gym with drowzees and kadabras becomes lvl 33 with oddish, gastly, venonat, and koffing
  - Lvl 38 juggler in Fuchsia gym exchanges his hypno for two exeggute
  - Lvl 36 blackbelt in the dojo exchanges his primape for poliwrath
  - Dojo master increased to level 38
  - Some cueball teams include pinsir
  - Biker teams now include beedrill, magmar, an electrode, and more voltorbs
  
#### Rival / Gym Leader / Elite 4 Guide  
- Route 22 Rival
  - L9 pidgey - gust, sand attack
  - pick one
    - L8 charmander - scratch, growl
    - L8 squirtle - tackle, tail whip, bubble
    - L8 bulbasaur - tackle, growl, leech seed
- Brock
  - L12 geodude - tackle, defense curl
  - L15 onix - tackle, screech, bind, bide
- Cerulean City Rival
  - L18 pidgeotto - gust, sand attack, quick attack
  - L15 abra - teleport, counter, tri attack
  - L15 rattata - tackle, tail whip, quick attack, hyper fang
  - pick one
    - L17 charmander - scratch, growl, ember, leer
    - L17 squirtle - tackle, tail whip, bubble, water gun
    - L17 bulbasaur - tackle, growl, leech seed, vine whip
- Misty
  - L18 staryu - tackle, water gun
  - L22 starmie - tackle, water gun, harden, bubblebeam
- SS Anne Rival
  - L19 pidgeotto - gust, sand attack, quick attack
  - L16 raticate - tackle, tail whip, quick attack, hyper fang
  - L18 kadabra - teleport, kinesis, confusion, disable
  - pick one
    - L20 charmeleon - scratch, growl, ember, leer
    - L20 wartortle - tackle, tail whip, bubble, water gun
    - L20 ivysaur - tackle, growl, leech seed, vine whip
- Surge
  - L18 pikachu - thunder wave, quick attack, thundershock, double team
  - L21 voltorb - tackle, screech, sonic boom
  - L25 raichu - thunderbolt, tail whip, thunder wave, slam
- Pokemon Tower Rival
  - L25 pidgeotto - gust, sand attack, quick attack
  - L20 kadabra - teleport, kinesis, confusion, disable
  - variant 1
    - L23 exeggcute - barrage, hypnosis
    - L22 gyarados - bite, dragon rage, leer, hydro pump
    - L25 charmeleon - growl, ember, leer, rage
  - variant 2
    - L23 growlithe bite, roar, ember, leer
    - L22 exeggcute - barrage, hypnosis
    - L25 wartortle - tail whip, bubble, water gun, bite
  - variant 1
    - L23 gyarados - bite, dragon rage, leer, hydro pump
    - L22 growlithe bite, roar, ember
    - L25 ivysaur - growl, leech seed, vine whip, poison powder
- Erika
  - L29 tangela - constrict, bind, absorb, vine whip
  - L33 victreebel - growth, sleep powder, wrap, razor leaf
  - L33 vileplume - poison powder, mega drain, sleep powder, petal dance
- Koga
  - L37 koffing - explosion, double-team, sludge, smokescreen
  - L39 muk - disable, substitute, minimize, sludge
  - L38 venonat - takedown, supersonic, mega drain, sleep powder
  - L43 weezing - toxic, sludge, mimic, explosion
- Silph Co. Rival
  - L37 pidgeot - wing attack, sand attack, quick attack, whirlwind
  - L35 alakazam - psybeam, confusion, disable, recover
  - variant 1
    - L38 exeggcute - reflect, leech seed, poison powder, stun spore
    - L35 gyarados - bite, dragon rage, leer, hydro pump
    - L40 charizard - slash, ember, leer, rage
  - variant 2
    - L38 growlithe - roar, ember, leer, takedown
    - L35 exeggcute - hypnosis, reflect, leech seed, stun spore
    - L40 blastoise - bubble, water gun, bite, withdraw
  - variant 3
    - L38 gyarados - bite, dragon rage, leer, hydro pump
    - L35 growlithe - roar, ember, leer, takedown
    - L40 venusaur - leech seed, vine whip, poison powder, razor leaf
- Sabrina
  - L37 kadabra - reflect, disable, psybeam, recover
  - L37 mr.mime - confusion, barrier, light screen, seismic toss
  - L38 venomoth - supersonic, leech life, stun spore, psybeam
  - L43 alakazam - psywave, recover, psychic, reflect
- Blaine
  - L40 ninetails - quick attack, swift, confuse ray, flamethrower
  - L43 magmar - strength, counter, confuse ray, fire punch
  - L43 rapidash - tail whip, stomp, double-edge, fire spin
  - L47 arcanine - fire blast, bite, leer, takedown
- Giovanni
  - L46 kangaskhan - earthquake, hyper beam, fissure, dizzy punch
  - L45 dugtrio - fissure, dig, sand attack, slash
  - L46 nidoqueen - earthquake, double kick, thunder, body slam
  - L47 nidoking - earthquake, double kick, ice beam, thrash
  - L52 rhydon - rock slide, body slam, double team, earthquake
- Route 22 Rival Rematch
  - L47 pidgeot - wing attack, agility, quick attack, whirlwind
  - L45 rhyhorn - fury attack, stomp, horn drill, tail whip
  - L50 alakazam - psybeam, psychic, reflect, recover
  - variant 1
    - L45 exeggcute - solar beam, leech seed, poison powder, stun spore
    - L47 gyarados - bite, dragon rage, leer, hydro pump
    - L53 charizard - slash, flamethrower, leer, rage
  - variant 2
    - L45 growlithe - agility, ember, leer, takedown
    - L47 exeggcute - solar beam, leech seed, poison powder, stun spore
    - L53 blastoise - hydro pump, skull bash, bite, withdraw
  - variant 3
    - L45 gyarados - bite, dragon rage, leer, hydro pump
    - L47 growlithe - agility, ember, leer, takedown
    - L53 venusaur - growth, vine whip, poison powder, razor leaf
- Lorelei
  - L54 dewgong - bubblebeam, aurora beam, rest, takedown
  - L54 cloyster - clamp, supersonic, aurora beam, spike cannon
  - L55 slowbro - surf, ice beam, amnesia, psychic
  - L56 jynx - psychic, ice punch, lovely kiss, thrash
  - L56 lapras - body slam, confuse ray, blizzard, hydro pump
- Bruno
  - L53 onix - rock slide, screech, slam, dig
  - L55 hitmonchan - ice punch, thunder punch, mega punch, submission
  - L55 hitmonlee - rolling kick, focus energy, hi jump kick, mega kick
  - L56 onix - bind, body slam, explosion, earthquake
  - L58 machamp - earthquake, focus energy, siesmic toss, submission
- Agatha
  - L55 haunter - confuse ray, mimic, hypnosis, dream eater
  - L56 gengar - confuse ray, substitute, thunderbolt, mega drain
  - L56 golbat - screech, confuse ray, double edge, mega drain
  - L58 arbok - earthquake, glare, screech, acid
  - L60 gengar - confuse ray, psychic, hypnosis, dream eater
- Lance
  - L58 gyarados - dragon rage, bite, hydro pump, hyperbeam
  - L56 dragonair - thunder wave, reflect, thunderbolt, hyperbeam
  - L56 dragonair - surf, body slam, ice beam, hyperbeam
  - L60 aerodactyl - supersonic, fire blast, fly, hyperbeam
  - L62 dragonite - blizzard, fire blast, thunder, hyperbeam
- Champion Rival
  - L61 pidgeot - sky attack, tri-attack, mimic, double team
  - L59 alakazam - thunderwave, recover, psychic, reflect
  - L61 rhydon - thunderbolt, earthquake, rock slide, takedown
  - variant 1
    - L61 exeggutor - leech seed, stomp, solar beam, hypnosis
    - L63 gyarados - ice beam, body slam, hydro pump, hyperbeam
    - L65 charizard - fly, slash, fire blast, fire spin
  - variant 2
    - L61 arcanine - reflect, rest, double edge, flamethrower
    - L63 exeggutor - leech seed, stomp, solar beam, hypnosis
    - L65 blastoise - blizzard, reflect, skull bash, hydro pump
  - variant 3
    - L61 gyarados - ice beam, body slam, hydro pump, hyperbeam
    - L63 arcanine - reflect, rest, double edge, flamethrower
    - L65 venusaur - razor leaf, toxic, sleep powder, solar beam


#Changes to Pokemon (SPOILERS)  
-----------------------------------------------
Note: These are not applicable to the Lite patches.  

#### TM/HM Learnset Changes  
- Charizard can learn FLY.
- Butterfree, Venonat, and Venomoth can learn FLASH.
- Diglett, Dugtrio, and Kabutops can learn CUT.

#### Altered Level-Up Movelists  
Pokemon that have had moves added to their learn-lists or changed levels at which moves are learned:  
- Arcanine
  - L20, EMBER and BITE added
  - L30, LEER added
  - L40, TAKE DOWN added
  - L50, FLAMETHROWER added
- Butterfree
  - L10, CONFUSION
  - L13, POISONPOWDER
  - L14, STUN SPORE
  - L15, SLEEP POWDER
  - L18, SUPERSONIC
  - L23, WHIRLWIND
  - L28, GUST added
- Chansey
  - L12, TAIL WHIP added
- Clefable
  - L13, SING added
  - L18, DOUBLESLAP added
  - L24, MINIMIZE added
  - L31, METRONOME added
- Cloyster
  - L18, SUPERSONIC added
  - L23, CLAMP added
  - L30, WATER GUN added
  - L39, AURORA BEAM added
- Cubone
  - L13, TAIL WHIP added
  - L16, HEADBUTT added
- Eevee
  - L8, SAND ATTACK added
  - L16, GROWL added
  - L23, QUICK ATTACK
  - L30, BITE
  - L36, FOCUS ENERGY added
  - L42, TAKE DOWN
- Electrode
  - L29, LIGHT SCREEN and REFLECT
- Exeggutor
  - L19, EGG BOMB added
  - L25, REFLECT added
  - L42, SOLARBEAM added
  - L48, HYPNOSIS added
- Flareon
  - L8, SAND ATTACK added
  - L16, GROWL added
  - L23, QUICK ATTACK
  - L30, BITE added as extra instance
  - L36, FIRE SPIN added as extra instance
  - L47, SMOG added
  - L52, FLAMETHROWER
- Geodude
  - L29, BODY SLAM added
- Golem
  - L29, BODY SLAM added
- Graveler
  - L29, BODY SLAM added
- Jolteon
  - L8, SAND ATTACK added
  - L16, GROWL added
  - L23, QUICK ATTACK
  - L30, DOUBLE KICK added as extra instance
  - L36, PIN MISSILE added as extra instance
  - L40, DOUBLE KICK
  - L42, THUNDER WAVE
  - L52, THUNDER
- Kadabra
  - L16, KINESIS and CONFUSION
- Kakuna
  - L7, HARDEN added
- Koffing
  - L42, MIMIC added
  - L42, SLUDGE added as extra instance
- Mankey
  - L9, LOW KICK added
  - L45, SCREECH added
- Marowak
  - L13, TAIL WHIP added
  - L16, HEADBUTT added
- Metapod
  - L7, HARDEN added
- Nidoking
  - L12, DOUBLE KICK added
  - L19, POISON STING
- Nidoqueen
  - L12, DOUBLE KICK added
  - L19, POISON STING
- Nidoran (female)
  - L12, DOUBLE KICK
  - L17, POISON STING
  - L23, TAIL WHIP
  - L30, BITE
  - L38, FURY SWIPES
- Nidoran (male)
  - L12, DOUBLE KICK
  - L17, POISON STING
  - L23, FOCUS ENERGY
  - L30, FURY ATTACK
  - L38, HORN DRILL
- Nidorina
  - L12, DOUBLE KICK
  - L19, POISON STING
  - L27, TAIL WHIP
  - L36, BITE
  - L46, FURY SWIPES
- Nidorino
  - L12, DOUBLE KICK
  - L19, POISON STING
  - L27, FOCUS ENERGY
  - L36, FURY ATTACK
  - L46, HORN DRILL
- Ninetales
  - L20, QUICK ATTACK added
  - L28, CONFUSE RAY added
  - L36, FLAMETHROWER added
  - L44, FIRE SPIN added
- Pikachu
  - L6, TAIL WHIP added
  - L8, THUNDER WAVE
  - L11, QUICK ATTACK
  - L11, THUNDERSHOCK added as an extra instance
  - L15, DOUBLE TEAM added
  - L20, SLAM added
  - L26, THUNDERBOLT added
  - L29, SWIFT
  - L41, THUNDER
  - L50, LIGHT SCREEN added
- Pinsir
  - L21, BIND added
- Poliwrath
  - L16, WATER GUN
  - L19, HYPNOSIS
  - L27, DOUBLESLAP added
  - L35, SUBMISSION added
  - L44, BUBBLEBEAM added
- Primeape
  - L9, LOW KICK added
  - L28, RAGE added
  - L45, SCREECH added
- Raichu
  - L11, TAIL WHIP added
  - L13, THUNDER WAVE added
  - L25, SLAM added
  - L31, THUNDER added
  - L46, REFLECT added
  - L55, LIGHT SCREEN added
- Tangela
  - L27, ABSORB
  - L29, VINE WHIP added
- Scyther
  - L50, WING ATTACK added
- Starmie
  - L21, WATER GUN added
  - L26, HARDEN added
  - L31, RECOVER added
  - L38, SWIFT added
  - L47, HYDRO PUMP added
  - L54, REFLECT added
- Vaporeon
  - L8, SAND ATTACK added
  - L16, GROWL added
  - L23, QUICK ATTACK
  - L30, BITE added as extra instance
  - L36, AURORA BEAM added
  - L47, AURORA BEAM added as extra instance
  - L52, HYDRO PUMP
- Venomoth
  - L11, SUPERSONIC added
  - L19, CONFUSION added
  - L22, POISONPOWDER
- Venonat
  - L11, SUPERSONIC added
  - L19, CONFUSION added
  - L22, POISONPOWDER
- Victreebel
  - L18, POISONPOWDER
  - L23, SLEEP POWDER
  - L30, STUN SPORE added
  - L37, ACID added
  - L44, RAZOR LEAF added
- Vileplume
  - L30, ACID added
  - L40, PETAL DANCE added
- Voltorb
  - L29, LIGHT SCREEN and REFLECT
- Weezing
  - L45, MIMIC added
  - L47, SLUDGE added as extra instance
- Wigglytuff
  - L9, POUND added
  - L14, DISABLE added
  - L19, DEFENSE CURL added
  - L24, SING added
  - L29, DOUBLESLAP added
  - L34, DISABLE added
  - L39, BODY SLAM added


#Cheats and Secrets (SPOILERS)
-----------------------------------------------
Note: These are not applicable to the Lite patches. 

#### Mew, Bill's Garden, and the Mist Stone  
The secret room's entrance can be found off the south-east corner of Route 12.  
The journal inside will hint that Bill wants to see a New Species of pokemon.  
If the 'Dex Diploma has been viewed, Mew can be encountered and caught on the lowest level of the Cerulean Cave.  
Show Mew to Bill, and he will let you into his secret garden.  
Return to the journal in the secret room, and you will receive a Mist Stone.  
Follow the path in the secret room, look for a hidden Nugget and Moon Stone, and exit into Diglett's Cave.  

#### Pikachu Learning Surf  
Beat the SS. Anne post-game tournament with a Pikachu in your party.  
The Pikachu's catch rate byte will be modified, and it will be allowed to learn the Surf HM.  

#### Dragonite Learning Fly  
Beat Lance with a Dragonite in your 1st party slot.  
The Dragonite's cry will play and its catch rate byte will be modified.  
It will now be allowed to learn the Fly HM.  

#### Psyduck Learning Amnesia  
You must first have 151 pokemon registered as owned in your pokedex.  
Place a Psyduck in your 1st party slot then go talk to the Psyduck in Mr. Fuji's house.  
It will now try to learn the Amnesia move.  

#### Tutor for Event Moves  
The man in the Mt. Moon pokemon center will serve as a move tutor after buying the Magikarp from him.  
This is a throwback feature for certain Japan-only event pokemon giveaways.  
- Talk to him with Magikarp at the top of your party, and he will offer to teach it Dragon Rage for 5000 yen.
- Talk to him with Fearow or Rapidash at the top of your party, and he will offer to teach it Pay Day for 1000 yen.
- Talk to him with Pikachu at the top of your party that has an empty move slot, and he can teach it Fly for 2000 yen.

#### The Surfboard  
The truck at the Vermilion Dock holds the Surfboard as a hidden item.  
The surfboard substitutes for a pokemon that knows how to Surf.  

#### Strange Dittos  
Use the super rod in the bottom of Cerulean Cave.  
You will fish up Dittos that are above level 100.  
These give the most EXP and StatEXP when knocked out.  

#### Better Chances for Shiny Pokemon  
Having a level-100 Chansey at the top of your party will increase your shiny chances.  
Encountering a shiny is unaffected by repels.  
Place a level-100 Chansey at the top of your party and use a repel to effectively grind shiny pokemon.  

#### Shiny Mercy  
Playing with hard mode ON allows enemy trainer pokemon to be shiny.  
If this happens to you, the next wild pokemon you encounter will be shiny as a form of mercy.  

#### Cheat at the Slots  
A pokemon with Pay Day in the 1st party slot will play its cry when interacting with a lucky slot machine.  
A pokemon with Pay Day in the 1st party slot will play its cry when a slot machine enters payout modes.  
- 1 cry for a normal payout on the next pull
- 2 cries to signal the possibility of all 7s/bars on the next pull
- 3 cries to signal that super payout mode had been entered

#### Gameshark Codes  
Here are some freshly-baked cheat codes unique to Shin Pokemon.  
  - 010042DA: If your play-clock was maxed at 255 from a previous save file, this will unlock the expanded game clock.  
  - 0180C4CF: The next encounter will be a shiny pokemon.
  - 01xx21D7: Resets the options and changes the player graphics to male (xx=00) or female (xx=01).
  - 010472D1: Erases the Nuzlocke death flag for the Pokemon in your first team slot.

#### Force Grayscale  
It is possible, for whatever reason, to force Shin Pokemon to play in grayscale color all the time.  
This can be done with some hex editing directly on the rom file.  
Change both address 0x0143 and address 0x0151 to the value of 00.  
This will force the rom file to operate as an old DMG game with no GBC features.  
