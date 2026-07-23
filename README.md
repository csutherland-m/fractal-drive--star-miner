# Fractal Drive: Star Miner

Godot 4.6 prototype combining deterministic planetary mining, vehicle progression,
ground encounters, a Planet Core finale, and a strategic star-system layer.

## Current Game Flow

1. Choose one of three save slots.
2. Begin the guided starting-planet scenario.
3. Mine resources, manage fuel/capacitor/hull/shields, and upgrade the miner.
4. Return resources to the lander for selling, fabrication, refueling, and repair.
5. Clear cave encounters and claim the Planet Core.
6. Process enough rocket fuel to leave the planet.
7. Enter the star-system view for orbital travel and raider combat.

The asteroid-belt destination and later galaxy progression remain incomplete.

## Project Structure

- `Scenes/main_game_menu.tscn` — save-slot selection and run startup.
- `Scenes/AsteroidMining.tscn` — active planetary mining scene.
- `Scenes/StarSystemView.tscn` — orbital navigation and strategic combat.
- `Scenes/UI/MiningHud.tscn` — modular mining instrument cluster.
- `Scenes/UI/PauseMenu.tscn` — save, settings, and pause navigation.
- `Scripts/AsteroidMining.gd` — mining-scene orchestration and gameplay state.
- `Scripts/MiningUpgradeCatalog.gd` — active upgrade definitions and stat rules.
- `Scripts/StartingPlanetBalance.gd` — starting-planet balance and generation constants.
- `Scripts/SeedManager.gd` — deterministic run, galaxy, and tutorial state.
- `Scripts/SaveManager.gd` — three-slot save persistence and schema validation.
- `Scripts/GroundEncounterSystem.gd` — cave altars, demons, darts, and portals.
- `Scripts/CoreVaultSystem.gd` — Planet Core vault and boss waves.
- `Scripts/MinerLaserSystem.gd` — mining-vehicle projectiles.
- `Scripts/MiningEffects.gd` — particles, pickup text, impacts, and camera shake.
- `Scripts/MiningHud.gd` — modular HUD presentation.
- `Tests/SeedFoundationTest.gd` — deterministic integration/regression suite.

Placeholder visual systems are isolated in their corresponding presentation scripts
so they can be replaced without changing progression logic.

## Controls

### Mining

- `A` / `D` or Left / Right — move and drill sideways.
- `S` or Down — drill downward.
- `W`, Up, or Space — upward thrust.
- Left mouse — fire the mining laser.
- `Q` — radial explosive blast.
- `E` — directional explosive blast.
- `F` — interact or use a nearby lift.
- `L` — construct a lift when available.
- `R` — place a fabricated GPS marker.
- `I` — open miner inventory.
- `M` — open the explored planet map.
- `Ctrl+T` — developer test setup.
- Escape — close the current overlay/menu or pause.
- Pause/Break — configurable menu-back action.

### Star-System View

- Click a planet — plot an intercept and descend.
- Click a raider — transfer into combat.
- Click the asteroid belt — plot the current placeholder approach.
- Mouse wheel — zoom.
- Mouse near the screen edge — pan.
- Escape or Pause/Break — pause navigation.

## Deterministic Generation

New games derive isolated galaxy, local-system, and planet seeds from
`STAR_MINER_DEFAULT_SEED_001`. Purpose-specific derived seeds keep changes in one
generator from consuming another generator's random sequence.

The approved starting-planet signature for the first 120 generated rows is
`144209399`. The regression suite verifies both repeatability and this pinned
baseline so an accidental deterministic generation change fails loudly.

If a generation change is intentional, review the generated world first and update
the pinned signature in `Tests/SeedFoundationTest.gd` in the same change.

## Save Compatibility

The current save and generator schema versions are both `3`.

This cleanup intentionally invalidates saves produced by earlier versions. Old slot
files appear as **Outdated** in the main menu and must be restarted. There is no
legacy save migration layer.

Current saves contain:

- deterministic run and galaxy state;
- tutorial and route state;
- mining terrain, revealed cells, caves, core-vault state, lifts, and markers;
- miner, lander, resources, fabrication, upgrades, and combat values;
- star-system orbital and combat state.

## Upgrade Rules

Only upgrades with implemented gameplay effects are exposed. The catalog currently
contains miner component upgrades, lander cargo/fuel capacity, and the planetary
Fuel Depot. Future starship, global, environmental-tolerance, and lander-throughput
concepts should be added only when their runtime effects and tests exist.

Standard numeric rules live in `MiningUpgradeCatalog.gd`; special milestone effects
such as sensor visibility, drill yield, armor, critical chance, and the Fuel Depot
are applied by the mining scene.

## Runtime Efficiency

The mining scene avoids terrain-wide work in normal frame updates:

- lodestones are tracked separately instead of rediscovered by scanning all terrain;
- fog revelation updates only when the player changes cells or sensor radius changes;
- cargo HUD nodes rebuild only when cargo contents change;
- HUD meters and depth displays redraw only when values change;
- the mining target outline redraws only when its target cell changes.

When adding a continuous system, prefer dirty-state or event-driven updates over
rebuilding nodes or scanning generated terrain every frame.

## Developer Test Setup

Press `Ctrl+T` in the mining scene to:

- teleport to an exact depth;
- teleport near a generated cave;
- assign exact active upgrade levels;
- set credits, resources, fuel, and explosive inventory;
- apply reusable test presets.

The panel modifies only the current run.

## Validation

Run the editor import/parser pass:

```powershell
& 'C:\Users\chris\OneDrive\Desktop\Godot\Godot_v4.6.3-stable_win64_console.exe' `
  --headless --path . --editor --quit
```

Run the regression suite:

```powershell
& 'C:\Users\chris\OneDrive\Desktop\Godot\Godot_v4.6.3-stable_win64_console.exe' `
  --headless --path . --script 'res://Tests/SeedFoundationTest.gd'
```

The regression covers seeded generation, tutorial flow, active upgrades, mining
abilities, economy, encounters, Planet Core progression, modular HUD behavior, and
save round trips.

## Assets and Exports

- `Reference Material/` is excluded from Godot resource import.
- Large source sheets, backups, and unused source vehicle art are excluded from
  exports through `export_presets.cfg`.
- Generated playtest packages belong in `Builds/`, which is Git-ignored.
- Keep editable source artwork when useful, but do not preload or export it until it
  has an active runtime consumer.
