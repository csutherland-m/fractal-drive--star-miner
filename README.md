# Fractal Drive: Star Miner

This is the Codex working copy of the Godot project.

## Current Shape

- Main menu loads first.
- Play starts the flight test scene.
- The player starship stays centered while the starfield and asteroids scroll.
- The starship uses side-profile art, slowly rotates toward its travel direction, mirrors to stay upright, and has a visible engine flame.
- Large mineable asteroids trigger a short orbit-and-lander cutscene before the asteroid mining scene.
- The asteroid mining scene has movement, gravity, collision, fuel, cargo, fog of war, and one-block mining.
- The mining map extends downward as the player descends, with a camera follow, nearby tile reveal, and visible starting surface layers.
- The mining surface has a landed shop ship resting on the left side of the first ground layer, while the miner starts centered.

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
- Hold movement toward a block to mine it. Blocks have hardness/HP, and the drill deals damage over time.
- Dirt and rock do not take cargo space.
- Ore and raw fuel fill cargo. Starting cargo capacity is 10 items.
- Raw fuel is a coal-tinted dirt-style block that appears more often than iron but less often than copper.
- Fuel lasts for 60 seconds of movement.
- A segmented teal fuel bar across the top of the screen shows remaining fuel in 10-second chunks and blinks red below 30 percent.
- The player starts with 100 gold coins.
- Refueling costs 2 gold coins per started 10 seconds of missing fuel.
- Touch the lander above the surface to sell ore, store ore in the warehouse, refuel, and buy the first drill and sensor upgrades.
- Warehouse ore is safe from cargo selling and can still be used for upgrades.
- `Esc`: pause.

## Recommended Next Step

Improve the mining prototype:

1. Add better mining feel and feedback.
2. Add clearer shop feedback and button states.
3. Add a way to return from the mining scene to flight.
4. Add more upgrade tiers for fuel, cargo, drill, and sensors.
