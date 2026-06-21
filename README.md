# Fractal Drive: Star Miner

This is the Codex working copy of the Godot project.

## Current Shape

- Main menu loads first.
- Play starts the flight test scene.
- The player ship stays centered while the starfield and asteroids scroll.
- Large mineable asteroids send the player to the asteroid mining scene.
- The asteroid mining scene has first-pass movement, gravity, collision, and one-block mining.

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

## Mining Test Controls

- `A/D` or arrow keys: move.
- `W` or up arrow: thrust upward like a small rocket.
- Hold movement toward a block to mine it. Blocks have hardness/HP, and the drill deals damage over time.
- `Esc`: pause.

## Recommended Next Step

Improve the mining prototype:

1. Add better mining feel and feedback.
2. Add resource values and inventory rules.
3. Add a way to return from the mining scene to flight.
4. Add a simple upgrade purchase.
