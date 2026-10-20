# Animations for the learnset audit's new moves

Each of the 49 new moves (design brief, Gen 9 rules pass, part 8) plays an
existing move's animation and sound for now (`AttackAnimationPointers` in
`data/animations.asm`, `MoveSoundTable` in `engine/battle/animations.asm`).
The table lists each donor. The 13 moves marked "custom wanted" are the ones
where the reused animation shows the wrong thing (no projectile, missing
element, wrong kind of attack); the rest read well enough with their donor.

Custom animations wanted:

1. **SHADOW BALL**: a dark orb flying at the target; Night Shade's reused screen effect has no projectile.
2. **MOONBLAST**: a moon/pink orb; Confuse Ray's floating light reads as a status move.
3. **AIR SLASH**: blades of air crossing the target; Gust's swirl reads as wind, not cuts.
4. **X-SCISSOR**: two crossing slashes; Slash is a single set of claw marks.
5. **AQUA JET**: the user rushing in a water trail; Quick Attack has no water.
6. **DRAGON RUSH**: the user charging in a draconic aura; Take Down is a plain tackle.
7. **FIRE FANG**: fangs plus flames; Hyper Fang has no fire.
8. **POISON FANG**: fangs plus purple bubbles; Hyper Fang has no poison.
9. **FLAME WHEEL**: the user rolling in a ring of fire; Fire Spin traps the target instead.
10. **FLARE BLITZ**: the user charging wrapped in fire; Fire Blast is a ranged burst.
11. **ICICLE CRASH**: icicles falling on the target; Ice Punch is a punch.
12. **LEAF BLADE**: a single blade slash; Razor Leaf throws leaves.
13. **WATER PULSE**: expanding rings of water; BubbleBeam is a stream of bubbles.

| Move | Animation and sound from | Verdict |
|---|---|---|
| AERIAL ACE | Wing Attack | fine as is |
| AIR SLASH | Gust | **custom wanted**: blades of air crossing the target; Gust's swirl reads as wind, not cuts |
| ANCIENTPOWER | Rock Throw | fine as is |
| AQUA JET | Quick Attack | **custom wanted**: the user rushing in a water trail; Quick Attack has no water |
| BRINE | Bubblebeam | fine as is |
| BUG BITE | Bite | fine as is |
| BUG BUZZ | Supersonic | fine as is |
| BULLDOZE | Earthquake | fine as is |
| CLOSE COMBAT | Comet Punch | fine as is |
| CROSS CHOP | Karate Chop | fine as is |
| CRUNCH | Hyper Fang | fine as is |
| DISARM VOICE | Sing | fine as is |
| DISCHARGE | Thunderbolt | fine as is |
| DRAGONBREATH | Dragon Rage | fine as is |
| DRAGON RUSH | Take Down | **custom wanted**: the user charging in a draconic aura; Take Down is a plain tackle |
| DRILL RUN | Horn Drill | fine as is |
| DYNAMICPUNCH | Mega Punch | fine as is |
| EARTH POWER | Fissure | fine as is |
| EXTREMESPEED | Quick Attack | fine as is |
| FIRE FANG | Hyper Fang | **custom wanted**: fangs plus flames; Hyper Fang has no fire |
| FLAME WHEEL | Fire Spin | **custom wanted**: the user rolling in a ring of fire; Fire Spin traps the target instead |
| FLARE BLITZ | Fire Blast | **custom wanted**: the user charging wrapped in fire; Fire Blast is a ranged burst |
| FLASH CANNON | Aurora Beam | fine as is |
| GIGA DRAIN | Mega Drain | fine as is |
| GUNK SHOT | Sludge | fine as is |
| HEAT WAVE | Flamethrower | fine as is |
| HYPER VOICE | Roar | fine as is |
| ICICLE CRASH | Ice Punch | **custom wanted**: icicles falling on the target; Ice Punch is a punch |
| INCINERATE | Ember | fine as is |
| LEAF BLADE | Razor Leaf | **custom wanted**: a single blade slash; Razor Leaf throws leaves |
| LIQUIDATION | Crabhammer | fine as is |
| LOW SWEEP | Low Kick | fine as is |
| MACH PUNCH | Comet Punch | fine as is |
| MOONBLAST | Confuse Ray | **custom wanted**: a moon/pink orb; Confuse Ray's floating light reads as a status move |
| PLUCK | Peck | fine as is |
| POISON FANG | Hyper Fang | **custom wanted**: fangs plus purple bubbles; Hyper Fang has no poison |
| POISON JAB | Poison Sting | fine as is |
| POWDER SNOW | Blizzard | fine as is |
| PSYSHOCK | Psywave | fine as is |
| RAZOR SHELL | Clamp | fine as is |
| ROUND | Sing | fine as is |
| SEED BOMB | Egg Bomb | fine as is |
| SHADOW BALL | Night Shade | **custom wanted**: a dark orb flying at the target; Night Shade's reused screen effect has no projectile |
| SLUDGE BOMB | Sludge | fine as is |
| STOMPTANTRUM | Stomp | fine as is |
| STONE EDGE | Rock Slide | fine as is |
| TWISTER | Gust | fine as is |
| WATER PULSE | Bubblebeam | **custom wanted**: expanding rings of water; BubbleBeam is a stream of bubbles |
| X-SCISSOR | Slash | **custom wanted**: two crossing slashes; Slash is a single set of claw marks |
