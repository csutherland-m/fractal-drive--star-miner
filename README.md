# Fractal Drive: Star Miner

This is the Codex working copy of the Godot project.

## Current Shape

- Main menu loads first.
- The main menu uses a single static baked star background to avoid oversized animated stars and reduce title-screen GPU/CPU load.
- Play starts a fresh default-seeded run directly on the stranded tutorial planet.
- The Star System View is a clickable 2D local-system map with a star, orbit rings, orbiting planets, an asteroid belt, and a starship marker.
- Planet visuals use placeholder sprite art from `Sprites/Planets/Placeholders/`.
- Each seeded local system guarantees at least one rocky planet and one gas giant, then fills the remaining planet slots from a deterministic mix of rocky, ice, lava, gas giant, crystal, and ferric worlds.
- Solar-system orbital motion is scaled by `ORBIT_SPEED_MULTIPLIER = 0.1` in `Scripts/StarSystemView.gd` so planets, enemies, the asteroid belt, and player orbital motion move at roughly one tenth of the previous speed.
- Orbital visuals support up to 120 FPS and use subpixel positioning, keeping slow-moving planets, enemies, asteroids, and the player ship from stepping between whole pixels.
- The star-system field renders at half scale for a 2x zoomed-out view, with antialiased enemy reticles and orbital geometry for smoother motion.
- Planetary orbit rings are spaced 50% farther apart, and the outermost planet always orbits at least one full ring spacing beyond the asteroid belt.
- Moving the mouse to a screen edge smoothly pans the star-system map, with diagonal scrolling at corners and bounded camera travel; HUD layers remain fixed in place.
- The mouse wheel zooms toward the cursor from a 200-pixel-padded full-system view up to 175% of normal zoom; panning automatically recenters at the widest view.
- Procedural systems can now include Crystal Worlds rich in luminous exotic minerals and Ferric Worlds built from iron-heavy industrial strata, each with dedicated generated planet art.
- The player ship now spawns outside the asteroid belt and begins in orbit around the system center before the player chooses a destination.
- Clicking a planet predicts the planet's future orbital position based on estimated transfer time, plots a curved orbital-style path to that intercept, freezes orbital motion on arrival, then enters the current planet mining scene.
- Clicking the asteroid belt plots a curved approach and currently stops at a placeholder arrival message; the future asteroid-belt flight scene will branch from here.
- The Star System View now includes strategic combat encounters: three visible raider HUD markers orbit the system, and one surprise ambush interrupts the first normal travel attempt.
- Each visible raider independently rolls between orbiting the central star and appearing as a fixed escort marker above-right of a randomly selected planet; planetary markers follow their host without orbiting it and remain valid interception targets.
- Enemy markers are custom-drawn hostile HUD reticles instead of plain red triangle placeholders.
- Clicking a raider transfers the player ship to the enemy orbit first, then opens the combat encounter once the transfer completes.
- Combat is resolved in a modal window with round-by-round rolls. The starter ship has 10,000 hull, enemies use 1,000 hull for normal raiders, damage is in the hundreds, and armor plus shields block roughly half of incoming raw damage.
- The current mining scene has movement, gravity, collision, fuel, cargo, fog of war, and one-block mining. It is now treated as the planet mining scene, even though the file is still named `AsteroidMining.tscn` for stability.
- Mining feedback is centralized in `Scripts/MiningEffects.gd`, which currently creates code-generated placeholder dust, sparks, floating pickup text, lode stone impact bursts, and camera shake.
- Miner cargo displays as resource icons with counts in the mining HUD.
- The mining HUD is one modular bottom-left retro-industrial control panel (`Scenes/UI/MiningHud.tscn`). The previous separate fuel bar, hull bar, Q/E row, and two-dial gauge cluster are no longer instantiated.
- `Sprites/UI/mining_hud_housing.png` is static transparent housing art. Fuel/hull/heat fills, scalable capacity tick marks, the fuel needle, Q/E lighting, cooldown progress, and depth digits are independent Godot-rendered layers.
- Fuel uses 10 kg capacity ticks in a fixed-size window. If capacity grows too large to remain readable, `HudSegmentedMeter` automatically increases the tick interval by powers of ten instead of resizing the HUD. Hull uses the same scalable system with 100 HP base ticks.
- The center fuel needle shows current fuel percentage. Heat stays visibly dormant at zero. Depth increases by 10m per row and uses a five-digit amber seven-segment display styled after an old digital clock.
- Q and E use chunky Apollo-era twist-light-style button art. Ready buttons are illuminated; disabled/cooldown buttons darken, while the recessed bar beneath each button fills toward ready and displays remaining time.
- The mining map extends downward as the player descends, with a camera follow, nearby tile reveal, and visible starting surface layers.
- The mining world currently uses a deeper 240-row resource progression curve for playtesting faster exploration.
- Mining terrain uses a neutral depth-darkening gradient: foreground blocks and exposed background dirt stay close to normal at the surface and gradually darken together with depth.
- The mining surface has a landed shop ship resting above the center tile, while the miner starts two tiles to its right.
- On the starting planet, the lander menu requires 20 tons of processed rocket fuel before departure; later/non-tutorial mining runs retain the existing Planet Core requirement.
- Planetary Upgrades now exists as an upgrade category; the first one-time build is a Fuel Depot next to the lander.

## Seeded Runs and Galaxy Foundation

- `Scripts/SeedManager.gd` is an autoload registered in `project.godot`. It is the single owner of `current_run_seed`, `galaxy_seed`, `starting_system_seed`, `starting_planet_seed`, scenario state, galaxy data, current system, and committed path history.
- New games call `SeedManager.start_new_run()` with `STAR_MINER_DEFAULT_SEED_001`. The function also accepts another seed string for future manual-seed UI. A stable text hash and purpose-specific derived seeds keep galaxy, system, and planet generation isolated from one another.
- The starting planet uses its own `RandomNumberGenerator` seeded from `starting_planet_seed`. Block types, ore/resource positions, voids, background dirt variants, foreground tile variants, Lode Stones, and the Planet Core location are deterministic. Mining-time ore yield and Treasure upgrade rolls intentionally remain runtime rolls in this pass.
- Dynamic rows use the same dedicated planet RNG, so unrelated particles, combat rolls, elapsed time, and other global randomness cannot change the later planet layout.
- The Starship begins with zero escape-fuel tons. The starting scenario progresses through `STARTING_STRANDED`, `MINING_FOR_ESCAPE_FUEL`, `READY_TO_LEAVE_STARTING_PLANET`, and `GALAXY_MAP_UNLOCKED`. The tutorial departure requires 20 tons of rocket fuel but does not require the Planet Core.
- A one-time `AcceptDialog` transmission from a friendly cargo hauler appears on the first starting-planet landing. It explains the mining/fuel objective and warns about Demon systems; `cargo_hauler_intro_shown` prevents repeats during that run.
- The seeded galaxy contains exactly 64 systems: one depth-0 tutorial system and nine systems at each depth from 1 through 7. Each system stores `system_id`, `display_name`, `system_seed`, `path_depth`, `difficulty_tier`, `available_resources`, `is_demon_system`, and `connected_system_ids`.
- Difficulty tiers currently map directly from path depths 0-7 to tiers 1-8. Demon flags begin at depth 6 and become more common at depth 7; they are data hooks only for now.
- The starting system exposes three forward choices; later systems expose two. `get_available_next_systems()` retrieves valid choices, `select_next_system()` commits one forward step without allowing backtracking, and `print_available_next_systems()` provides the current debug listing. A complete run path is therefore about eight systems including the tutorial system.
- Leaving the tutorial planet unlocks the existing Star System View as a route-selection placeholder. It displays the current system, depth, difficulty, and available next-system names, but it is not the final Slay-the-Spire-style galaxy UI.

### Determinism Test

Run:

`Godot_v4.6.3-stable_win64_console.exe --headless --path <project path> --script res://Tests/SeedFoundationTest.gd`

The regression starts two new games, generates both galaxies, both seeded local-system layouts, and the first 120 starting-planet rows, then verifies identical seeds, galaxy JSON, system/orbit data, terrain/resource/tile signature, Planet Core location, route choices, Demon flags, route commitment, escape-fuel state, guide one-shot state, scenario transitions, and the unlocked route placeholder. The current default planet signature is `1199700337`.

### Seed Foundation Files

- `project.godot`: registers the `SeedManager` autoload.
- `Scripts/SeedManager.gd`: seeds, run/scenario state, 64-system graph, difficulty, Demon flags, route selection, and guide-message tracking.
- `Scripts/main_game_menu.gd`: starts a new seeded run and enters the tutorial planet.
- `Scripts/AsteroidMining.gd`: deterministic planet generation, layout signature, guide placeholder, escape gating, and galaxy unlock transition.
- `Scripts/StarSystemView.gd`: deterministic local-system generation and route-foundation status text.
- `Tests/SeedFoundationTest.gd`: headless determinism and state regression.
- `README.md`: architecture, testing, limitations, and follow-up notes.

### Current Limitations and Suggested Next Steps

- Run state persists across scene changes through the autoload but is not saved to disk yet.
- The final galaxy/path-selection screen, route buttons, path visualization, intro cinematic, dialogue tree, and cargo-hauler character art are not implemented.
- Selecting a graph destination currently requires the `SeedManager.select_next_system(system_id)` API/debugger; the existing Star System View only lists available destinations.
- Later-system planet seed selection and full difficulty application to enemies/resources remain future work. This pass only guarantees and balances the starting planet seed.
- Next: build a dedicated branching galaxy-map scene, connect its buttons to `select_next_system()`, persist run state, derive later planet seeds from the selected system/planet, and feed `difficulty_tier` into encounter and resource tuning.

## Main Scenes

- `Scenes/main_game_menu.tscn`: title/menu screen.
- `Scenes/StarSystemView.tscn`: clickable local star-system navigation scene.
- `Scenes/AsteroidMining.tscn`: current planet mining scene. The file has not been renamed yet.
- `Scenes/UI/PauseMenu.tscn`: reusable pause menu.

## Main Scripts

- `Scripts/main_game_menu.gd`: menu buttons.
- `Scripts/SeedManager.gd`: centralized seeded run state, galaxy graph, starting scenario, and route APIs.
- `Scripts/StarSystemView.gd`: local-system map, orbiting planets, click targets, and curved ship travel.
- `Scripts/CombatResolver.gd`: strategic combat stats and round-resolution math.
- `Scripts/Starfield.gd`: generated moving star background with capped star sizes and throttled redraws.
- `Scripts/AsteroidSpawner.gd`: creates debris and mineable asteroids.
- `Scripts/SpaceDebris.gd`: asteroid/debris behavior and scene transition.
- `Scripts/AsteroidMining.gd`: generated mining grid and future mining controls.
- `Scripts/MiningEffects.gd`: reusable mining feedback effects with exported particle texture slots for replacement art.
- `Scripts/PauseMenu.gd`: shared pause menu signals.
- `Scripts/GameTheme.gd`: button styling.

## Star System View Controls

- Left click a planet: fly to that planet and enter planet mining.
- Left click the asteroid belt: fly to the belt placeholder arrival.
- Left click a raider HUD marker: transfer to that enemy orbit, then open the strategic combat panel.
- In combat, use `Resolve Round` or `Auto Resolve`; close the panel after combat is finished.
- `Esc`: pause.

## Mining Test Controls

- `A/D` or arrow keys: move.
- `W`, `Space`, or up arrow: thrust upward like a small rocket.
- Hold left, right, or down toward a block to mine it. Blocks have hardness/HP, and the drill deals damage over time.
- `Q` or the HUD button activates Radial Blast, mining all mineable blocks in the 3x3 area centered on the miner. It consumes one loaded explosive charge and has a 5-second cooldown.
- `E` or the HUD button activates Directional Blast, mining the next three mineable blocks in one cardinal direction. It consumes one loaded explosive charge, has no direct miner-fuel cost, and has a 5-second cooldown.
- Pause and choose `Settings` to toggle `Mouse-directed E ability`, the first gameplay setting. When enabled, E selects whichever 90-degree direction from the miner is closest to the cursor. When disabled, hold `W/up`, `S/down`, `A/left`, or `D/right` while activating to aim explicitly; otherwise E uses the drill's current facing.
- Both abilities use a two-second code-generated explosion-to-dust sequence. Blast blocks are now removed after about 0.73 seconds instead of 1.1 seconds—a 50% increase in removal speed—while the complete visual sequence still lasts two seconds. Lode Stone remains unmineable, and an ability does not consume a charge or start its cooldown when it has no valid target.
- Ore caught by a blast is rolled and deposited directly into miner cargo using normal inventory-capacity rules. Ability pickup lines appear in a small list about 200 px above screen center, using the same amount/resource animation as ordinary mining. No ability name, `BLAST RECOVERY` heading, dirt, or rock text is displayed.
- Mining emits placeholder dust/sparks and floating pickup text. These are code-driven now; replacement particle textures can be assigned on `MiningEffects.gd` later without changing mining logic.
- The base miner moves 30 percent faster and mines 50 percent faster than the first prototype tuning.
- Block hardness increases by 10 percent per row below the surface.
- Dirt and rock do not take cargo space.
- Starting two rows below the surface, dirt has a 2 percent chance to seed a small void pocket. Each pocket rolls 1-4 connected blocks, randomizes its shape from the starting dirt block, and remains hidden by fog of war until revealed.
- Lode Stone starts appearing at 500m by replacing some normal rock blocks. It starts at a 1 percent conversion chance, scales upward with depth, cannot be mined yet, and is affected by gravity when unsupported. Landing impacts trigger a dust burst and short camera shake.
- Normal ore blocks roll their own base yield range: Copper 2-9, Iron 2-8, Gold 1-6, Diamond 1-4, Warp Gems 1-3, and Black Hole Crystals 1-2. Drill Yield upgrades expand those ranges; Raw Fuel blocks still yield one item for processing.
- Every ordinarily mined ore displays its pickup number at the mined block. Q/E blast pickups instead appear about 200 px above screen center so a multi-block ability does not obscure the miner. Both use the same rise, slight fall, and fade animation and scale from an 18-point minimum-roll size to a 38-point maximum-roll size. A maximum roll turns gold and flashes twice.
- Copper generation is 50% more frequent in every depth band. Its surface/middle/deep probabilities increase from 1.43%/4.55%/5.2% to 2.145%/6.825%/7.8%; the added probability is taken from dirt so rock and all other resource frequencies remain unchanged.
- Treasure blocks yield exactly one Treasure. At the lander, each Treasure can improve a random non-maxed upgrade across any category, with an 80% chance of +1 level, 15% of +2, and 5% of +3, capped at its normal maximum.
- The miner's ground and airborne horizontal deceleration are 50% stronger, producing a quicker stop when directional input is released.
- Planet Core is a unique once-per-planet material located on the altar in the deterministic cavern below the 7,500m barrier.
- Ore and raw fuel fill cargo. Starting miner cargo capacity is 100 units.
- The miner cargo list is vertically centered along the left edge. As resource types are added it expands equally upward and downward around the center. Icons remain at their reduced 15 px size, while the count font is now 11 px—about 40% larger than its previous 8 px size.
- The miner starts with 100 hull HP, displayed in a HUD health bar. The first damaging speed is calculated from a three-block free fall with `sqrt(2 * gravity * (3 * 64px))`, currently about 588 px/s. Damage begins at 10 HP at that speed and scales linearly to 99 HP at the miner's updated 900 px/s terminal velocity.
- Q and E use Apollo-era illuminated pushbuttons in the modular mining HUD. They darken and report `NO CHARGE` when the miner has no explosive ammunition; otherwise the cooldown recess shows readiness and the shared loaded-charge count.
- Fuel depletion and zero hull HP now route through one standard death sequence. Both display `You lose! You're a fuckin Looser, Bruhhhh`, play the same animated death treatment, start a fresh seeded run, and reload the starting mining planet.
- The lander Cargo Hold starts at 5,000 units, 50x the base miner capacity, and deposits stop when it is full.
- Raw fuel is a coal-tinted dirt-style block that appears more often than iron but less often than copper.
- Miner fuel is measured in kg, with 1 kg providing 1 second of drive time.
- Driving consumes 70% of the base active fuel rate, while actively drilling a mineable block consumes 110% of the base rate. Power Unit Efficiency modifies both rates.
- Idling consumes fuel slowly, using 1 kg every 10 seconds at level 0; Power Unit Efficiency now modifies this power-production fuel use too.
- A segmented teal fuel bar across the top of the screen shows remaining fuel in 10-second chunks and blinks red below 30 percent.
- The player starts with 100 Credits.
- Raw fuel can be processed in the lander into 200 kg of mining fuel and 1 ton of rocket fuel per block.
- Fuel processing takes 30 seconds per 1 ton of rocket fuel. The Lander screen shows the remaining processing time.
- The Lander screen also opens an instant Ammo Fabricator. One Raw Fuel block becomes 10 explosive powder, up to 100 stored powder. One Copper becomes one casing, with lander cargo consumed before miner cargo for both inputs.
- One powder plus one casing assembles one explosive charge. The fabricator stores up to 20 finished charges, while the miner initially carries up to 10 for shared use by Q and E. Loaded explosives use the separate ammo store and never consume ore-cargo capacity. Each charge is equivalent to one Copper plus one tenth of a Raw Fuel block.
- Raw fuel that does not fit in the lander fuel tanks remains in the cargo hold.
- The starship can store 7000 kg of mining fuel and currently starts with 1000 kg for playtesting.
- On landing, the starship transfers enough mining fuel to fill the lander tank when available.
- Refueling the miner consumes lander mining fuel kg when available.
- If the lander mining fuel tank is empty, emergency refueling costs 10 Credits per kg.
- The Surface Shop includes `Repair Ship Hull` directly below Refuel and above Return to Starship. A full repair costs exactly 1 Credit for every missing hull HP; the button shows the missing HP and total price, and disables when the hull is full or the player cannot afford the complete repair.
- The lander has separate storage tanks for mining fuel and rocket fuel.
- The base lander rocket fuel tank holds 20 tons. The starting scenario requires all 20 tons to unlock galaxy-route access; later/non-tutorial runs still use the existing 20-ton-plus-Planet-Core completion rule.
- Building the Fuel Depot adds 20 tons of rocket fuel capacity, raising total first-pass storage from 20 to 40 tons.
- Touch the lander above the surface to deposit cargo, open the Lander screen, sell ore, process raw fuel, refuel, and buy upgrades.
- Press `Ctrl+T` in the mining scene to open the Developer Test Setup panel. It can teleport to an exact depth, assign exact upgrade levels, and set test credits, Raw Fuel, lander rocket fuel, and active miner fuel without playing through progression first.
- The Lander screen shows Cargo Hold contents in a left-side icon list.
- Each lander-market resource has compact `Sell`, `10`, and `All` buttons that sell one unit, up to ten units, or that resource's complete lander-held stack. The global `Sell All` button sells every resource in the lander. None of these actions sell resources still carried by the miner. Processing and upgrades can continue consuming resources from both miner cargo and the lander hold.
- Existing non-credit upgrade resource costs retain the prior 10x economy scale. Credit costs are unchanged; Mk 1 additions use first-pass costs pending economy balancing against the new per-ore yield ranges.
- Planetary Upgrades currently contains Fuel Depot, a one-time build costing scaled ore/resources and Credits.
- Infrastructure sprites render as `Sprite2D` children of `MineTiles` with z-index 8, above terrain and below the miner at z-index 10.
- `Esc`: pause.
- `Ctrl+T`: open or close the Developer Test Setup panel.

## Ground Enemy Foundation

- The deterministic starting planet now plans an irregular cave around every 1,000-meter depth milestone. Each cave center is seeded within 100 meters above or below its milestone and carves roughly a varied 7x7 foreground void through either dirt or rock.
- Every cave is enclosed by a complete deterministic shell of ordinary Rock between 2 and 5 blocks thick. Cave-wall cells cannot become Lode Stone, ore, or random dirt voids; existing saves receive the same seeded rock-shell retrofit without replacing wall blocks the player mines afterward.
- Every planned cave contains a tribal-demon altar and portal. The first-pass altar is code-drawn stone with a glowing artifact; the portal is a pulsing purple-and-green oval. These are isolated placeholder visuals that can be replaced without changing encounter logic.
- Approach an unopened altar and press `F` when the interaction prompt appears. Looting currently awards one Treasure, marks the altar opened, activates its portal, and schedules three tribal demons. A full miner cargo prevents looting until room is available.
- Tribal demons currently use a code-drawn blue Godot-style placeholder face with horns and tribal paint. They pursue the miner inside open terrain and fire poison-green blow darts when they have clear line of sight.
- Blow darts deal 5 hull damage and use the standard zero-hull death flow. Q/E blast cells deal 3 damage to demons, enough to defeat the current 3 HP placeholder enemy.
- Cave definitions, altar/portal state, pending portal spawns, defeated counts, and active demon positions/health are included in mining saves. Active darts are intentionally transient and are not restored.
- Existing mining saves are supported: deterministic milestone caves are planned and carved into already-generated terrain when the save loads, while preserving the Planet Core if a planned cave would overlap it.
- Current limitation: this is the combat foundation, not final enemy AI. Demons use simple direct movement and line-of-sight attacks rather than navigation meshes, advanced ground traversal, animation, or final loot tables.

## Planet Core Barrier and Vault Encounter

- The Planet Core has moved from its former shallow test placement to a deterministic grand altar around 7,650 meters, inside a 42x18-block cavern that begins at 7,500 meters.
- From 7,000 through 7,490 meters, every foreground block is ordinary Rock or a rare high-value block. The barrier contains no Dirt, Raw Fuel, Copper, Iron, or Lode Stone. Its seeded first-pass distribution is 97.55% Rock, 1.5% Treasure, 0.6% Diamond, 0.25% Warp Gems, and 0.1% Black Hole Crystals.
- Normal milestone caves stop before the 7,000-meter barrier. Breaking through the final barrier row opens directly into the massive core cavern.
- The core rests on an oversized code-drawn basalt altar surrounded by green and purple demon-tech conduits. Four dormant portal positions surround the chamber.
- Mining the Planet Core adds it to the miner inventory, closes a visible demon-tech ceiling seal, locks the cavern perimeter against drilling/blast escape, and starts a five-wave lockdown encounter.
- Wave counts are 3, 5, 7, 9, and 12 demons. Later waves gain health, movement speed, attack frequency, and blow-dart damage. A boss HUD reports the current wave and remaining enemies.
- After the fifth wave is defeated, all portals deactivate, the ceiling reopens, the perimeter becomes mineable again, and the secured Planet Core can be returned to the Starship through the existing flow.
- Core-vault layout, encounter wave, pending spawns, active demons, lock state, and completion are included in mining saves. Existing saves move an unclaimed old core into the new deterministic vault and retrofit already-generated barrier/cavern terrain.
- Current limitation: the altar, demon technology, seals, portals, and enemies use code-drawn placeholder art; the encounter currently uses increasingly strong tribal demons rather than a unique final boss model.

## Miner Laser, Capacitor, and Shield

- Hold the left mouse button to fire the miner's placeholder turret toward the cursor. The muzzle currently floats 42 pixels above the miner until final turret art is added.
- The turret fires up to three cyan laser bolts per second. Bolts travel at 1,400 pixels per second and disappear when they hit a tribal demon, a foreground terrain block, or the generated mining-area boundary.
- Electrical values use a 100x engineering scale so percentage upgrades can remain integer-friendly. The starting capacitor holds 2,000 kJ. The Power Unit generates 600 kW, Life Support consumes 50 kW, the shield consumes 200 kW, mobility draws a base 200 kW at full throttle, and each laser costs 200 kJ. Essential Life Support and shield maintenance are supplied first; mobility scales down rather than drawing beyond available generation, while the capacitor covers essential shortfalls and weapon shots.
- The shield begins with 100 HP and absorbs ordinary enemy/projectile damage before the hull. Fall damage and falling Lode Stone impacts bypass it; falling Lode Stones currently deal 25 hull damage.
- Each successful laser shot restarts a two-second shield-recharge delay. At full throttle, the base vehicle retains 150 kW after Life Support, shield upkeep, and mobility; while stationary, the surplus is 350 kW. After the delay, incoming surplus is diverted into damaged shields at 2 HP per 100 kJ, up to the base 6 HP-per-second recharge ceiling, with any remaining generation charging the capacitor.
- The shield is invisible in this pass. Stored capacitor energy is preserved for firing rather than drained by shield repair; shield repair uses the incoming generation surplus after essential and active mobility loads.
- The former upper-left fuel bar is now the capacitor indicator, and the former heat strip now displays shield HP. The center dial is divided vertically: its cyan left needle shows mining fuel and its orange right needle shows heat from laser firing. Heat currently cools passively and has no overheat penalty.
- Capacitor energy, shield HP, laser cooldown, shield-recharge delay, and heat are included in mining saves. In-flight laser bolts are intentionally transient.
- Electrical upgrade rates are rounded to the nearest whole kW/kJ after each compounded level. Mining saves now carry a power-scale version; older saves automatically multiply stored capacitor energy by 100 so their charge percentage is preserved.

## Mk 1 Mining Vehicle Upgrades

- The former flat Miner list is now an extensible set of component categories: Drill Assembly, Power Unit, Mobility System, Fuel Cell, Cargo Capacity, Thermal Management, Life Support, Shield Generator, Structural Frame, Capacitor Bank, and Weapon Systems. Each is data-driven and can accept future Mk 2-Mk 10 definitions without rebuilding the upgrade UI or developer panel.
- Unless noted otherwise, a 10% improvement compounds each level: increases use `base * 1.1^level`, while consumption and delay reductions use `base * 0.9^level`.
- Drill Yield uses per-ore starting ranges. Copper is 2-9, Iron 2-8, Gold 1-6, Diamond 1-4, Warp Gems 1-3, and Black Hole Crystals 1-2. Odd levels raise the minimum by one and even levels raise the maximum by one, relative to each ore's base.
- Power Unit output controls electrical generation rather than vehicle speed. Its efficiency reduces all mining-fuel drain associated with keeping the Power Unit active, including idle, driving, and drilling drain. Mobility speed, acceleration/deceleration, and vertical climb are independently upgradeable; every level in any of those three performance lines compounds full-throttle mobility power draw by 6%. Kinetic Efficiency separately compounds that resulting draw downward by 10% per level. With all four Mobility lines at level 5, rounded full-throttle draw is 283 kW, 41.5% above the 200 kW base.
- Mk 1 Power Output is intentionally capped at level 7: the rounded progression is 600, 660, 726, 799, 879, 967, 1,064, and 1,170 kW. With all other electrical upgrades at level 10 and continuous full-rate shields, movement, and weapons, this creates an approximately 125 kW (9.7%) deficit that the capacitor can cover for roughly 41 seconds.
- Shield upgrades independently control HP, recharge delay, recharge-rate ceiling, and both maintenance/recharge efficiency. Structural Frame controls hull integrity and flat armor. Armor is calculated once per incoming hull hit after shield absorption, including shield-bypassing fall and boulder damage, and always allows at least 1 hull damage through.
- Weapon upgrades affect the laser's final floating-point damage, energy cost, fire rate, and critical chance. Critical chance adds 2 percentage points per level; a critical applies 200% after the normal damage modifiers.
- Life Support Tolerance is intentionally present as a non-functional placeholder for later environment mechanics. Sensor Strength was not in the Mk 1 specification, so it remains available under Retained Miner Upgrades for later review. All existing Lander, Planetary, Starship, and Global upgrades are also retained unchanged.

### Upgrade Replacement Change Log

- `Drill Efficiency`: retained at 10% compounded drill damage per level (description clarified from “faster”).
- `Cargo Capacity`: retained at 10% compounded capacity per level.
- `Fuel Tank` (`miner_fuel_tank`): renamed/migrated to Fuel Cell Capacity (`miner_fuel_cell_capacity`); its 10% capacity behavior is unchanged.
- `Engine Power` (`miner_engine_power`): previously increased speed and acceleration 5% per level; renamed/migrated to Power Unit Output (`miner_power_unit_output`) and now increases electrical generation 10% per level. Mobility upgrades now own movement performance.
- `Engine Efficiency` (`miner_engine_efficiency`): previously reduced movement/drilling fuel consumption 10% per level; renamed/migrated to Power Unit Efficiency (`miner_power_unit_efficiency`) and now also applies to idle power-production fuel use.
- `Hull Strength` (`miner_hull_strength`): previously a non-functional placeholder; renamed/migrated to Structural Frame Maximum Integrity (`miner_structural_integrity`) and now increases maximum hull HP 10% per level.
- Added functional Drill Yield, four Mobility, Thermal Management, Life Support Efficiency, four Shield Generator, Structural Armor, Capacitor Capacity, and four Weapon Systems upgrade lines.
- Existing saves migrate renamed string IDs when mining state loads. If both an old and new ID are present, the higher level wins. Current hull, shield, capacitor, and fuel values remain valid and gain newly purchased capacity rather than being reset.

Changed files for this upgrade pass are `Scripts/AsteroidMining.gd`, `Scripts/DamageRules.gd`, `Scripts/MinerLaserSystem.gd`, `Scripts/GroundEncounterSystem.gd`, `Tests/SeedFoundationTest.gd`, and `README.md`. Current limitations: costs are first-pass extensions of the existing economy; Power Unit fuel use remains represented by the mining scene's continuous fuel drain rather than a separate generator simulation; Life Support failure and Tolerance effects are not implemented; heat has no penalty; and the shop does not yet group upgrades by Mk tier.

## Developer Test Setup

- God Mode has been removed. The replacement is a direct, reversible test-loadout panel in `Scripts/DeveloperTestPanel.gd`.
- The panel pauses gameplay while open and provides exact controls for target depth, every upgrade level, Credits, Raw Fuel, lander rocket fuel, and active miner fuel.
- Quick presets include surface/no upgrades and 3000m with Drill Efficiency levels 0, 1, 3, or 5. Presets populate the controls; `Apply Setup + Teleport` performs the change.
- `Teleport 6 Blocks from Nearest Cave` generates the first cave when necessary, selects the cave nearest the miner, and carves a small arrival pocket exactly six cells beyond its outer rock wall. The approach favors the miner-facing side, so a surface test normally approaches from above.
- `Show Nearest Cave Arrow` controls a developer-only orange/yellow arrow above the miner. The teleport action enables it automatically, and it continuously retargets the nearest planned cave as the miner moves.
- A depth teleport generates the same deterministic planet rows that normal descent would generate, moves the miner to the requested depth, reveals a 13x13 inspection area, and carves only a 3x2 arrival pocket. Surrounding ore placement remains untouched for rarity and drill-feel testing.
- Upgrade-derived stats are recalculated from captured base values and explicit `upgrade_levels`. Changing Drill Efficiency from level 5 back to level 1 therefore produces the real level-1 drill speed instead of attempting to reverse accumulated multipliers.
- The panel builds upgrade controls directly from `upgrade_definitions`, including category and `max_level`. New categories and higher upgrade tiers appear automatically.
- Resource controls come from `get_developer_test_resource_definitions()`, which currently derives them from the gameplay resource registry. Adding a new registered resource automatically adds its exact-count field to the panel.
- Quick buttons come from `get_developer_test_presets()`. New system-, biome-, resource-, or progression-specific test profiles can be added as preset dictionaries without editing the panel layout.
- Standard numeric upgrade behavior is registered in `upgrade_stat_rules`. A new multiplicative stat/capacity upgrade needs a definition plus a stat-rule entry; the shared recalculation and developer UI handle its tiers automatically. Unique upgrades such as constructed infrastructure can continue using a small synchronization hook.
- This explicit-level recalculation is intended to be reused by future save loading: a save file can restore upgrade levels and ask the scene to rebuild derived stats.
- Developer changes currently affect only the active run and are not written to disk.

## Save and Continue

- The pause menu now includes `Save Game`, and the main menu includes `Continue`. Continue is disabled until the single local save slot exists.
- `Scripts/SaveManager.gd` owns the versioned JSON format at `user://star_miner_save.json`. Every file records `save_version`, `generator_version`, timestamp, current scene, centralized run/galaxy state, and scene-specific state.
- Mining saves preserve player position/velocity, fuel, hull HP, Credits, miner cargo, lander cargo, lander/starship fuel, processing progress, exact upgrade levels, ability cooldowns, revealed fog cells, Planet Core position, and the planet generator RNG state.
- Every already-generated foreground block and background dirt tile is stored with its cell, block type, atlas coordinate, and tile alternative. Previously visited terrain therefore stays unchanged after loading, including mined blocks and old ore distribution.
- Unexplored rows continue from the stored planet RNG state. They use the current generation code, allowing new ore/resource rules to appear below the player's previously generated world without rewriting visited terrain.
- SeedManager saves the full seeded galaxy graph, starting-scenario state, guide-message state, current system, committed route, and Starship escape fuel.
- Star-system saves preserve player orbit/position, Starship combat stats, planet/enemy orbit state, defeated enemies, asteroid-belt angle, surprise-encounter state, and map camera position/zoom. Active travel and open combat panels resume at a stable non-transition state rather than halfway through an animation.
- Upgrade levels and resource dictionaries are stored by string ID. New resources, categories, or higher upgrade tiers can be added without changing the core file layout; missing new fields use code defaults.
- `SAVE_VERSION` and the migration hook in `SaveManager.migrate_save_data()` are the compatibility boundary for future schema changes. `GENERATOR_VERSION` records which terrain-generation revision existed when the save was written.
- Manual test: start or continue a mining run, change depth/cargo/upgrades, mine a recognizable group of blocks, open the pause menu, and select `Save Game`. Restart the game, select `Continue`, and verify the miner returns to the same location with the same terrain, inventory, upgrades, fuel, hull, and cooldowns. Generate a new deeper row afterward to confirm unexplored terrain still uses the current generator.
- The automated seed-foundation regression also JSON-round-trips both mining and star-system state, confirming that exact terrain and encounter state survive serialization.
- Current limitations: this is one manual local slot, there is no autosave/profile picker/cloud synchronization yet, and New Game does not delete the existing Continue slot until the player saves the new run.

## Game Settings

- The shared pause menu now contains an expandable Settings panel used by both planet mining and the star-system scene.
- The first setting toggles cursor-directed E aiming. The cardinal-direction helper compares the cursor offset's dominant axis, so E always resolves to exactly up, down, left, or right rather than firing diagonally.
- Settings are centralized in the `GameSettings` autoload (`Scripts/GameSettings.gd`) and saved to Godot's per-user `user://game_settings.cfg` file. The setting therefore persists between scenes and later game launches.
- More settings can be added to the Settings panel and the centralized configuration without coupling them to the mining scene.

## Mining Depth Gradient

- `Scripts/AsteroidMining.gd` replaces the old dirt-only chocolate/red overlay, including its bright-red 1000m lava transition, with one grayscale terrain-darkening system.
- A row-wide black overlay is drawn above both `VisualMineTiles` (foreground blocks and ores) and `BackgroundTiles` (dug/background dirt). Because the same row brightness modifies the combined terrain image, background dirt cannot remain bright when a foreground block is removed.
- The overlay remains below the player, lander, Fuel Depot, pipes, mining effects, fog, HUD, and menus, so those elements retain their normal colors and readability.
- `depth_darkening_enabled`, `surface_brightness`, `deep_brightness`, `depth_gradient_start`, and `depth_gradient_end` are exported tuning values on the mining scene script. The defaults fade smoothly from `1.0` brightness at the surface to `0.45` at the end of the existing `depth_distribution_full_row` range (currently 240 rows).
- `depth_gradient_start` and `depth_gradient_end` are normalized positions within that 240-row range. The gradient clamps at `deep_brightness` below the end point.
- Changed files: `Scripts/AsteroidMining.gd` and `README.md`.
- Known limitation: this first pass darkens each complete terrain row uniformly rather than tinting cells individually. Foreground and background therefore share the same brightness, and no biome-specific color tint is applied.

## Placeholder Infrastructure Assets

- `Sprites/UI/fuel_depot_placeholder.png`: generated transparent pixel-art Fuel Depot sprite.
- `Sprites/UI/fuel_station_placeholder.png`: generated transparent pixel-art future Filling Station sprite.
- `Sprites/UI/fuel_pipe_placeholder.png`: generated transparent pipe variant sheet.
- `Sprites/UI/fuel_pipe_horizontal_placeholder.png`: cropped horizontal pipe used for the current Fuel Depot connection.
- `Sprites/UI/fuel_pipe_vertical_placeholder.png`: cropped vertical pipe reserved for future infrastructure.
- Matching `*_source.png` files are the original generated chroma-key images.

## Placeholder Planet Assets

- `Sprites/Planets/Placeholders/ice_world.png`: icy world placeholder.
- `Sprites/Planets/Placeholders/lava_world.png`: volcanic world placeholder.
- `Sprites/Planets/Placeholders/ringed_gas_giant.png`: gas giant placeholder.
- `Sprites/Planets/Placeholders/rocky_world.png`: rocky planet placeholder.

## Replaceable Feedback Art

- `Scripts/MiningEffects.gd` exposes `dust_particle_texture`, `spark_particle_texture`, and `impact_particle_texture`.
- If these texture slots are empty, the game generates small placeholder particle textures in code.
- Mining abilities currently generate their expanding orange blast flashes in code, then reuse the replaceable dust texture for the second half of the two-second effect.
- Future polished art should replace those exported textures instead of changing the mining, ore, or lode stone logic.
- Crack/damage overlay art is not yet implemented; the current mining progress overlay remains code-drawn.

## Future Planetary Infrastructure

- Filling stations are planned as underground refuel points.
- Filling stations should not increase total fuel capacity.
- Future pipe connections should require a straight-line path from the Fuel Depot to the station.
- `Scripts/AsteroidMining.gd` includes TODO hooks for filling stations, pipe connections, and straight-line pipe validation.

## Test Instructions

- Run the project headless: `Godot_v4.6.3-stable_win64.exe --headless --path <project path> --quit`.
- Run the star system scene headless: `Godot_v4.6.3-stable_win64.exe --headless --path <project path> res://Scenes/StarSystemView.tscn --quit`.
- Run the mining scene headless: `Godot_v4.6.3-stable_win64.exe --headless --path <project path> res://Scenes/AsteroidMining.tscn --quit`.
- The seed-foundation regression also checks Q's 3x3 targeting, E's four-direction three-cell targeting, cursor-to-cardinal direction selection, the Settings controls, five-second cooldowns, ammo fabrication and cargo-first input consumption, deterministic cave placement, altar/portal triggering, demon spawning, blow-dart hull damage, explosive save round-tripping, automatic blast-ore inventory capture, and the hull-impact damage thresholds.
- Run the seeded foundation regression: `Godot_v4.6.3-stable_win64_console.exe --headless --path <project path> --script res://Tests/SeedFoundationTest.gd`.
- In game, confirm the player starts beyond the asteroid belt, all orbiting bodies move slowly, raider markers look like hostile HUD reticles, raider clicks transfer the ship to enemy orbit before combat, and planet clicks intercept the future planet position before freezing and transitioning to mining.
- In game, mine Copper to confirm its base 2-9 roll, compare other ores' individual ranges, then use the developer panel to verify Drill Yield alternates minimum/maximum growth. Deposit ore into the 5,000-unit Cargo Hold, process raw fuel, and build Planetary Upgrades -> Fuel Depot to confirm capacity increases to 40 tons.

## Recommended Next Step

Improve the mining prototype:

1. Add better mining feel and feedback.
2. Add clearer shop feedback and button states.
3. Add a way to return from the mining scene to flight.
4. Add more upgrade tiers for fuel, cargo, drill, and sensors.
