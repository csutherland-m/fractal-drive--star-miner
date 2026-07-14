# Fractal Drive: Star Miner

This is the Codex working copy of the Godot project.

## Current Shape

- Main menu loads first.
- The main menu uses a single static baked star background to avoid oversized animated stars and reduce title-screen GPU/CPU load.
- Play starts the Star System View.
- The Star System View is a clickable 2D local-system map with a star, orbit rings, orbiting planets, an asteroid belt, and a starship marker.
- Planet visuals use placeholder sprite art from `Sprites/Planets/Placeholders/`.
- Each generated local system guarantees at least one rocky planet and one gas giant, then fills the remaining planet slots from a random mix of rocky, ice, lava, and gas giant worlds.
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
- The mining HUD includes a bottom gauge cluster image with live fuel needle and depth readout overlays; depth increases by 10m per row below the surface.
- The mining map extends downward as the player descends, with a camera follow, nearby tile reveal, and visible starting surface layers.
- The mining world currently uses a deeper 240-row resource progression curve for playtesting faster exploration.
- Dirt blocks use a depth tint overlay: they darken toward chocolate brown, snap to bright red at 1000m, then fade toward a darker burnt red.
- The mining surface has a landed shop ship resting above the center tile, while the miner starts two tiles to its right.
- The lander menu now shows a Return to Starship goal requiring 20 tons of rocket fuel and the Planet Core before departure is available.
- Planetary Upgrades now exists as an upgrade category; the first one-time build is a Fuel Depot next to the lander.

## Main Scenes

- `Scenes/main_game_menu.tscn`: title/menu screen.
- `Scenes/StarSystemView.tscn`: clickable local star-system navigation scene.
- `Scenes/AsteroidMining.tscn`: current planet mining scene. The file has not been renamed yet.
- `Scenes/UI/PauseMenu.tscn`: reusable pause menu.

## Main Scripts

- `Scripts/main_game_menu.gd`: menu buttons.
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
- `W` or up arrow: thrust upward like a small rocket.
- Hold left, right, or down toward a block to mine it. Blocks have hardness/HP, and the drill deals damage over time.
- Mining emits placeholder dust/sparks and floating pickup text. These are code-driven now; replacement particle textures can be assigned on `MiningEffects.gd` later without changing mining logic.
- The base miner moves 30 percent faster and mines 50 percent faster than the first prototype tuning.
- Block hardness increases by 10 percent per row below the surface.
- Dirt and rock do not take cargo space.
- Starting two rows below the surface, dirt has a 2 percent chance to seed a small void pocket. Each pocket rolls 1-4 connected blocks, randomizes its shape from the starting dirt block, and remains hidden by fog of war until revealed.
- Lode Stone starts appearing at 500m by replacing some normal rock blocks. It starts at a 1 percent conversion chance, scales upward with depth, cannot be mined yet, and is affected by gravity when unsupported. Landing impacts trigger a dust burst and short camera shake.
- Normal ore blocks roll their yield when mined, giving 2-10 units of that resource. Raw fuel blocks still yield one raw fuel item for processing.
- Treasure blocks yield exactly one Treasure. At the lander, each Treasure can improve a random non-maxed upgrade across any category, with an 80% chance of +1 level, 15% of +2, and 5% of +3, capped at its normal maximum.
- The miner's ground and airborne horizontal deceleration are 50% stronger, producing a quicker stop when directional input is released.
- Planet Core is a unique once-per-planet material. For current testing it appears once somewhere on the 1000m row; later this should be moved to the intended 5000m row.
- Ore and raw fuel fill cargo. Starting miner cargo capacity is 100 units.
- The lander Cargo Hold starts at 5,000 units, 50x the base miner capacity, and deposits stop when it is full.
- Raw fuel is a coal-tinted dirt-style block that appears more often than iron but less often than copper.
- Miner fuel is measured in kg, with 1 kg providing 1 second of drive time.
- Idling consumes fuel slowly, using 1 kg every 10 seconds.
- A segmented teal fuel bar across the top of the screen shows remaining fuel in 10-second chunks and blinks red below 30 percent.
- The player starts with 100 Credits.
- Raw fuel can be processed in the lander into 200 kg of mining fuel and 1 ton of rocket fuel per block.
- Fuel processing takes 30 seconds per 1 ton of rocket fuel. The Lander screen shows the remaining processing time.
- Raw fuel that does not fit in the lander fuel tanks remains in the cargo hold.
- The starship can store 7000 kg of mining fuel and currently starts with 1000 kg for playtesting.
- On landing, the starship transfers enough mining fuel to fill the lander tank when available.
- Refueling the miner consumes lander mining fuel kg when available.
- If the lander mining fuel tank is empty, emergency refueling costs 10 Credits per kg.
- The lander has separate storage tanks for mining fuel and rocket fuel.
- The base lander rocket fuel tank holds 20 tons. Returning to the starship currently requires 20 tons plus the Planet Core and triggers the current win-state message before returning to the main menu.
- Building the Fuel Depot adds 20 tons of rocket fuel capacity, raising total first-pass storage from 20 to 40 tons.
- Touch the lander above the surface to deposit cargo, open the Lander screen, sell ore, process raw fuel, refuel, and buy upgrades.
- The shop main screen includes a playtest God Mode button that maxes all upgrade levels, fills current miner/lander fuel tanks, and prevents miner fuel from depleting for the run.
- The Lander screen shows Cargo Hold contents in a left-side icon list.
- Selling, processing, and upgrades can use resources from both miner cargo and the cargo hold.
- Existing non-credit upgrade resource costs are scaled by 10 for the new 2-10 ore yield economy. Credit costs are unchanged.
- Planetary Upgrades currently contains Fuel Depot, a one-time build costing scaled ore/resources and Credits.
- Infrastructure sprites render as `Sprite2D` children of `MineTiles` with z-index 8, above terrain and below the miner at z-index 10.
- `Esc`: pause.

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
- In game, confirm the player starts beyond the asteroid belt, all orbiting bodies move slowly, raider markers look like hostile HUD reticles, raider clicks transfer the ship to enemy orbit before combat, and planet clicks intercept the future planet position before freezing and transitioning to mining.
- In game, mine normal ore to confirm 2-10 unit rolls, deposit ore into the 5,000-unit Cargo Hold, process raw fuel, and build Planetary Upgrades -> Fuel Depot to confirm capacity increases to 40 tons.

## Recommended Next Step

Improve the mining prototype:

1. Add better mining feel and feedback.
2. Add clearer shop feedback and button states.
3. Add a way to return from the mining scene to flight.
4. Add more upgrade tiers for fuel, cargo, drill, and sensors.
