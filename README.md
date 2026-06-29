# Fractal Drive: Star Miner

This is the Codex working copy of the Godot project.

## Current Shape

- Main menu loads first.
- Play starts the flight test scene.
- The player starship stays centered while the starfield and asteroids scroll.
- The starship uses side-profile art, slowly rotates toward its travel direction, mirrors to stay upright, and has a visible engine flame.
- Large mineable asteroids trigger a short orbit-and-lander cutscene before the asteroid mining scene.
- The asteroid mining scene has movement, gravity, collision, fuel, cargo, fog of war, and one-block mining.
- Miner cargo displays as resource icons with counts in the mining HUD.
- The mining HUD includes a bottom gauge cluster image with live fuel needle and depth readout overlays; depth increases by 10m per row below the surface.
- The mining map extends downward as the player descends, with a camera follow, nearby tile reveal, and visible starting surface layers.
- The mining world currently uses a deeper 240-row resource progression curve for playtesting faster exploration.
- The mining surface has a landed shop ship resting above the center tile, while the miner starts two tiles to its right.
- The lander menu now shows a Return to Starship goal requiring 20 tons of rocket fuel before departure is available.
- Planetary Upgrades now exists as an upgrade category; the first one-time build is a Fuel Depot next to the lander.

## Main Scenes

- `Scenes/main_game_menu.tscn`: title/menu screen.
- `Scenes/FlightTest.tscn`: current space flight scene.
- `Scenes/AsteroidMining.tscn`: early mining prototype.
- `Scenes/UI/PauseMenu.tscn`: reusable pause menu.

## Main Scripts

- `Scripts/main_game_menu.gd`: menu buttons.
- `Scripts/FlightTest.gd`: ship input, rotation, scrolling space.
- `Scripts/Starfield.gd`: generated moving star background.
- `Scripts/AsteroidSpawner.gd`: creates debris and mineable asteroids.
- `Scripts/SpaceDebris.gd`: asteroid/debris behavior and scene transition.
- `Scripts/AsteroidMining.gd`: generated mining grid and future mining controls.
- `Scripts/PauseMenu.gd`: shared pause menu signals.
- `Scripts/GameTheme.gd`: button styling.

## Flight Test Controls

- `W/A/S/D`: main thrust direction.
- `Q/E`: strafe left or right.
- `Esc`: pause.

## Mining Test Controls

- `A/D` or arrow keys: move.
- `W` or up arrow: thrust upward like a small rocket.
- Hold left, right, or down toward a block to mine it. Blocks have hardness/HP, and the drill deals damage over time.
- The base miner moves 30 percent faster and mines 50 percent faster than the first prototype tuning.
- Block hardness increases by 10 percent per row below the surface.
- Dirt and rock do not take cargo space.
- Normal ore blocks roll their yield when mined, giving 2-10 units of that resource. Raw fuel blocks still yield one raw fuel item for processing.
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
- The base lander rocket fuel tank holds 20 tons. Returning to the starship currently requires 20 tons and uses a stubbed scene-transition message.
- Building the Fuel Depot adds 20 tons of rocket fuel capacity, raising total first-pass storage from 20 to 40 tons.
- Touch the lander above the surface to deposit cargo, open the Lander screen, sell ore, process raw fuel, refuel, and buy upgrades.
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

## Future Planetary Infrastructure

- Filling stations are planned as underground refuel points.
- Filling stations should not increase total fuel capacity.
- Future pipe connections should require a straight-line path from the Fuel Depot to the station.
- `Scripts/AsteroidMining.gd` includes TODO hooks for filling stations, pipe connections, and straight-line pipe validation.

## Test Instructions

- Run the project headless: `Godot_v4.6.3-stable_win64.exe --headless --path <project path> --quit`.
- Run the mining scene headless: `Godot_v4.6.3-stable_win64.exe --headless --path <project path> res://Scenes/AsteroidMining.tscn --quit`.
- In game, mine normal ore to confirm 2-10 unit rolls, deposit ore into the 5,000-unit Cargo Hold, process raw fuel, and build Planetary Upgrades -> Fuel Depot to confirm capacity increases to 40 tons.

## Recommended Next Step

Improve the mining prototype:

1. Add better mining feel and feedback.
2. Add clearer shop feedback and button states.
3. Add a way to return from the mining scene to flight.
4. Add more upgrade tiers for fuel, cargo, drill, and sensors.
