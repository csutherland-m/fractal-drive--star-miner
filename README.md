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
- The mining map extends downward as the player descends, with a camera follow, nearby tile reveal, and visible starting surface layers.
- The mining surface has a landed shop ship resting above the center tile, while the miner starts two tiles to its right.

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
- Dirt and rock do not take cargo space.
- Ore and raw fuel fill cargo. Starting cargo capacity is 10 items.
- Raw fuel is a coal-tinted dirt-style block that appears more often than iron but less often than copper.
- Miner fuel is measured in kg, with 1 kg providing 1 second of drive time.
- Idling consumes fuel slowly, using 1 kg every 10 seconds.
- A segmented teal fuel bar across the top of the screen shows remaining fuel in 10-second chunks and blinks red below 30 percent.
- The player starts with 100 Credits.
- Raw fuel can be processed in the lander into 200 kg of mining fuel and 1 ton of rocket fuel per block.
- Raw fuel that does not fit in the lander fuel tanks remains in the cargo hold.
- The starship can store 7000 kg of mining fuel and currently starts with 1000 kg for playtesting.
- On landing, the starship transfers enough mining fuel to fill the lander tank when available.
- Refueling the miner consumes lander mining fuel kg when available.
- If the lander mining fuel tank is empty, emergency refueling costs 10 Credits per kg.
- The lander has separate storage tanks for mining fuel and rocket fuel.
- Touch the lander above the surface to deposit cargo, open the Lander screen, sell ore, process raw fuel, refuel, and buy upgrades.
- The Lander screen shows Cargo Hold contents in a left-side icon list.
- Selling, processing, and upgrades can use resources from both miner cargo and the cargo hold.
- `Esc`: pause.

## Recommended Next Step

Improve the mining prototype:

1. Add better mining feel and feedback.
2. Add clearer shop feedback and button states.
3. Add a way to return from the mining scene to flight.
4. Add more upgrade tiers for fuel, cargo, drill, and sensors.
