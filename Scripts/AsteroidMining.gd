extends Node2D

const FogOverlayScript := preload("res://Scripts/FogOverlay.gd")
const MiningEffectsScript := preload("res://Scripts/MiningEffects.gd")
const DeveloperTestPanelScript := preload("res://Scripts/DeveloperTestPanel.gd")
const MiningHudScene := preload("res://Scenes/UI/MiningHud.tscn")
const GroundEncounterSystemScript := preload("res://Scripts/GroundEncounterSystem.gd")
const MinerLaserSystemScript := preload("res://Scripts/MinerLaserSystem.gd")
const DeveloperCaveDirectionArrowScript := preload("res://Scripts/DeveloperCaveDirectionArrow.gd")
const CoreVaultSystemScript := preload("res://Scripts/CoreVaultSystem.gd")
const StartingPlanetBalance := preload("res://Scripts/StartingPlanetBalance.gd")
const SensorTwinkleOverlayScript := preload("res://Scripts/SensorTwinkleOverlay.gd")
const PlanetMapOverlayScript := preload("res://Scripts/PlanetMapOverlay.gd")
const ResourceTileTexture := preload("res://Sprites/TileSets/MiningTilesVariantsDugDirt64.png")
const LegacyGaugeClusterTexture := preload("res://Sprites/UI/gauge_cluster_concept.png")
const FuelDepotTexture := preload("res://Sprites/UI/fuel_depot_placeholder.png")
const FuelStationTexture := preload("res://Sprites/UI/fuel_station_placeholder.png")
const FuelPipeTexture := preload("res://Sprites/UI/fuel_pipe_placeholder.png")
const FuelPipeHorizontalTexture := preload("res://Sprites/UI/fuel_pipe_horizontal_placeholder.png")
const FuelPipeVerticalTexture := preload("res://Sprites/UI/fuel_pipe_vertical_placeholder.png")
const RadialBlastIcon := preload("res://Sprites/UI/q_radial_blast_icon.svg")
const DirectionalBlastIcon := preload("res://Sprites/UI/e_directional_blast_icon.svg")
const LEGACY_GAUGE_CLUSTER_DESIGN_SIZE := Vector2(560.0, 320.0)
const LEGACY_GAUGE_CLUSTER_SCALE := Vector2(0.63, 0.56)
const LEGACY_GAUGE_CLUSTER_SIZE := Vector2(
	LEGACY_GAUGE_CLUSTER_DESIGN_SIZE.x * LEGACY_GAUGE_CLUSTER_SCALE.x,
	LEGACY_GAUGE_CLUSTER_DESIGN_SIZE.y * LEGACY_GAUGE_CLUSTER_SCALE.y
)
const HUD_LAYER_INDEX := 5
const SHOP_LAYER_INDEX := 10
const TERRAIN_FOREGROUND_Z_INDEX := 8
const PLAYER_Z_INDEX := 10
const STANDARD_DEATH_MESSAGE := "You lose! You're a fuckin Looser, Bruhhhh"
const POWER_SCALE_VERSION := 2
const LEGACY_POWER_SCALE_MULTIPLIER := 100.0
const RESOURCE_SALE_VALUES := {
	"Silicone": 4,
	"Copper": 6,
	"Iron": 10,
	"Gold": 18,
	"Raw Fuel": 8,
	"Treasure": 24,
	"Diamond": 36,
	"Warp Gems": 60,
	"Black Hole Crystals": 90,
	"Planet Core": 0,
	"Silicone Wafer": 6,
	"Explosive Charge": 5,
}
const BAR_BASE_ORES := {
	"Copper Bar": "Copper",
	"Iron Bar": "Iron",
	"Gold Bar": "Gold",
}

enum BlockType {
	EMPTY,
	DIRT,
	ROCK,
	LODESTONE,
	COPPER,
	RAWFUEL,
	IRON,
	GOLD,
	TREASURE,
	DIAMOND,
	WARPGEMS,
	BLACKHOLECRYSTALS,
	PLANETCORE,
}

@onready var mine_tiles: TileMapLayer = $MineTiles
@onready var background_tiles: TileMapLayer = $BackgroundTiles
@onready var visual_mine_tiles: TileMapLayer = $VisualMineTiles
@onready var player_marker: Sprite2D = $MineTiles/PlayerMarker
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var starfield: Node2D = $Starfield

@export var tile_source_id: int = 0

@export var dirt_tiles: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
@export var rock_tiles: Array[Vector2i] = [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)]
@export var rawfuel_tiles: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
@export var copper_tiles: Array[Vector2i] = [Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1)]
@export var treasure_tiles: Array[Vector2i] = [Vector2i(7, 1)]
@export var iron_tiles: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
@export var gold_tiles: Array[Vector2i] = [Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)]
@export var warpgems_tiles: Array[Vector2i] = [Vector2i(6, 2), Vector2i(7, 2)]
@export var blackholecrystal_tiles: Array[Vector2i] = [Vector2i(0, 3), Vector2i(1, 3)]
@export var diamond_tiles: Array[Vector2i] = [Vector2i(2, 3), Vector2i(3, 3)]
@export var dug_dirt_tiles: Array[Vector2i] = [Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3)]

@export var grid_width: int = 60
@export var grid_height: int = 51
@export var empty_top_rows: int = 4
@export var generation_buffer_rows: int = 12
@export var depth_distribution_full_row: int = 240
@export var side_fog_padding_pixels: float = 300.0
@export var depth_meters_per_row: int = 10
@export var depth_darkening_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var surface_brightness: float = 1.0
@export_range(0.0, 1.0, 0.01) var deep_brightness: float = 0.45
@export_range(0.0, 1.0, 0.01) var depth_gradient_start: float = 0.0
@export_range(0.0, 1.0, 0.01) var depth_gradient_end: float = 1.0
@export var planet_core_test_depth_meters: int = 7650
@export var planet_core_future_depth_meters: int = 5000
@export var core_barrier_start_depth_meters: int = 7000
@export var core_vault_start_depth_meters: int = 7500
@export var core_vault_width_blocks: int = 42
@export var core_vault_height_blocks: int = 18
@export var lodestone_start_depth_meters: int = 500
@export var lodestone_base_chance: float = 0.01
@export var lodestone_chance_per_500m: float = 0.01
@export var lodestone_max_chance: float = 0.25
@export var dirt_void_start_depth_rows: int = 2
@export var dirt_void_chance: float = 0.02
@export var dirt_void_min_size: int = 1
@export var dirt_void_max_size: int = 4
@export var ground_cave_interval_meters: int = 1000
@export var ground_cave_depth_tolerance_meters: int = 100
@export var ground_cave_radius_blocks: int = 3
@export var developer_cave_teleport_distance_blocks: int = 6
@export var reveal_radius_tiles: int = 1
@export var surface_revealed_ground_rows: int = 2
@export var max_fuel_seconds: float = 60.0
@export var fuel_warning_ratio: float = 0.3
@export var mining_fuel_seconds_per_kg: float = 1.0
@export var idle_fuel_seconds_per_kg: float = 10.0
@export var driving_fuel_cost_multiplier: float = 0.70
@export var mining_fuel_cost_multiplier: float = 1.10
@export var mining_fuel_kg_per_raw_fuel: int = 200
@export var rocket_fuel_tons_per_raw_fuel: int = 1
@export var explosive_powder_per_raw_fuel: int = 10
@export var casing_per_copper: int = 1
@export var max_explosive_powder: int = 100
@export var max_fabricated_explosive_charges: int = 20
@export var max_miner_explosive_charges: int = 10
@export var max_lander_mining_fuel_kg: int = 200
@export var max_lander_rocket_fuel_tons: int = 20
@export var return_to_starship_required_rocket_fuel_tons: int = 20
@export var fuel_processing_seconds_per_ton: float = 0.0
@export var market_pressure_recovery_seconds_per_unit: float = 30.0
@export var market_minimum_price_ratio: float = 0.4
@export var market_pressure_scale: float = 25.0
@export var fuel_depot_rocket_fuel_capacity_bonus: int = 20
@export var max_starship_mining_fuel_kg: int = 7000
@export var starting_starship_mining_fuel_kg: int = 1000
@export var inventory_capacity: int = 100
@export var cargo_hold_capacity: int = 5000
@export_range(0.0, 1.0, 0.01) var silicone_drop_chance: float = 0.05
@export var ore_yield_min: int = 2
@export var ore_yield_max: int = 10
@export var copper_ore_frequency_multiplier: float = 1.5
@export var shop_lander_texture_path: String = "res://Sprites/Vehicles/RocketLanderEdited.png"
@export var shop_lander_scale: float = 0.75
@export var shop_lander_bottom_padding_pixels: float = 14.0
@export var shop_lander_ground_overlap_pixels: float = 3.0
@export var miner_spawn_offset_from_lander_tiles: int = 2

@export var gravity: float = 900.0
@export var max_fall_speed: float = 900.0
@export var max_lodestone_fall_speed: float = 500.0
@export var falling_lodestone_damage: int = 25
@export var max_hull_health: int = 100
@export var fall_damage_safe_distance_blocks: float = 3.0
@export var fall_damage_block_size_pixels: float = 64.0
@export var minimum_fall_damage: int = 10
@export var terminal_velocity_fall_damage: int = 99
@export var move_speed: float = 200.0
@export var ground_acceleration: float = 650.0
@export var air_acceleration: float = 450.0
@export var ground_deceleration: float = 1275.0
@export var air_deceleration: float = 825.0
@export var upward_thrust: float = 1500.0
@export var max_rise_speed: float = 360.0
@export var player_collision_width: float = 42.0
@export var player_collision_height: float = 58.0
@export var player_sprite_scale: float = 1.0
@export var player_animation_frames: int = 4
@export var player_animation_fps: float = 10.0

@export var drill_damage_per_second: float = StartingPlanetBalance.BASE_DRILL_DPS
@export var copper_drill_cost: int = 5
@export var copper_drill_damage_multiplier: float = 1.25
@export var copper_drill_tint: Color = Color("#C87533")
@export var sensor_upgrade_copper_cost: int = 1
@export var sensor_upgrade_iron_cost: int = 1
@export var upgraded_sensor_reveal_radius: int = 2
@export var copper_drill_credit_cost: int = 20
@export var sensor_upgrade_credit_cost: int = 15
@export var starting_credits: int = 100
@export var emergency_refuel_credit_cost_per_kg: int = 10
@export var hull_repair_credit_cost_per_hp: int = 1
@export var upgrade_resource_cost_scale: int = StartingPlanetBalance.MK1_RESOURCE_COST_SCALE
@export var arrival_countdown_seconds: int = 3
@export var mining_feedback_interval_seconds: float = 0.08
@export var radial_blast_cooldown_seconds: float = 5.0
@export var directional_blast_cooldown_seconds: float = 5.0
@export var ability_effect_duration_seconds: float = 2.0
@export var ability_block_removal_speed_multiplier: float = 1.5
@export var ore_pickup_text_vertical_offset_pixels: float = 200.0
@export var capacitor_capacity: float = 2000.0
@export var engine_charge_per_second: float = 600.0
@export var life_support_power_per_second: float = 50.0
@export var mobility_power_consumption_per_second: float = 200.0
@export var laser_energy_per_shot: float = 200.0
@export var laser_shots_per_second: float = 3.0
@export var laser_damage: float = 1.0
@export var weapon_critical_chance: float = 0.0
@export var laser_muzzle_vertical_offset: float = 42.0
@export var laser_heat_per_shot: float = 0.06
@export var heat_cooling_per_second: float = 0.08
@export var max_shield_health: float = 100.0
@export var shield_energy_per_second: float = 200.0
@export var shield_recharge_delay_seconds: float = 2.0
@export var shield_hp_per_energy: float = 0.02
@export var shield_recharge_hp_per_second: float = 6.0
@export var armor_rating: int = 0

var is_paused: bool = false
var is_shop_open: bool = false
var is_shop_reentry_locked: bool = false
var is_game_over: bool = false
var is_arrival_countdown_active: bool = false
var is_on_ground: bool = false
var player_velocity: Vector2 = Vector2.ZERO
var hull_health: int = 100
var capacitor_energy: float = 2000.0
var shield_health: float = 100.0
var shield_powered: bool = true
var laser_fire_cooldown_remaining: float = 0.0
var shield_recharge_delay_remaining: float = 0.0
var current_mobility_power_ratio: float = 1.0
var last_power_generation: float = 0.0
var last_power_consumption: float = 0.0
var last_mine_direction: Vector2i = Vector2i.DOWN
var current_drill_facing: Vector2i = Vector2i.DOWN
var player_animation_time: float = 0.0
var block_types_by_cell: Dictionary = {}
var planned_void_cells: Dictionary = {}
var planned_ground_cave_rock_cells: Dictionary = {}
var planned_ground_encounters: Array[Dictionary] = []
var resources: Dictionary = {}
var ore_base_yield_ranges: Dictionary = {
	BlockType.COPPER: Vector2i(2, 9),
	BlockType.IRON: Vector2i(2, 8),
	BlockType.GOLD: Vector2i(1, 6),
	BlockType.DIAMOND: Vector2i(1, 4),
	BlockType.WARPGEMS: Vector2i(1, 3),
	BlockType.BLACKHOLECRYSTALS: Vector2i(1, 2),
}
var cargo_hold_resources: Dictionary = {}
var planet_core_cell: Vector2i = Vector2i(-1, -1)
var credits: int = 100
var fuel_seconds: float = 60.0
var lander_mining_fuel_kg: int = 0
var lander_rocket_fuel_tons: int = 0
var starship_mining_fuel_kg: int = 0
var hud_label: Label
var cargo_full_notification: Label
var hud_cargo_icons: VBoxContainer
var modular_mining_hud: MiningHud
var gauge_cluster: Control
var gauge_depth_label: Label
var gauge_fuel_needle: ColorRect
var gauge_heat_needle: ColorRect
var heat_ratio: float = 0.0
var fuel_bar: Control
var fuel_bar_fill: ColorRect
var fuel_bar_segments: Array[ColorRect] = []
var fuel_warning_blink_time: float = 0.0
var hull_bar_fill: ColorRect
var hull_health_label: Label
var radial_blast_button: Button
var directional_blast_button: Button
var radial_blast_cooldown_label: Label
var directional_blast_cooldown_label: Label
var radial_blast_cooldown_remaining: float = 0.0
var directional_blast_cooldown_remaining: float = 0.0
var is_ability_effect_active: bool = false
var shop_button: Sprite2D
var shop_center_position: Vector2 = Vector2.ZERO
var shop_size: Vector2 = Vector2(192.0, 64.0)
var shop_panel: Panel
var shop_status_label: Label
var shop_content: Control
var shop_title_label: Label
var shop_master_tabs: HBoxContainer
var shop_stat_labels: Dictionary = {}
var lander_cargo_hold_list: VBoxContainer
var mining_inventory_panel: Panel
var mining_inventory_list: VBoxContainer
var mining_inventory_previous_paused: bool = false
var refuel_button: Button
var repair_hull_button: Button
var return_to_starship_button: Button
var return_to_starship_status_label: Label
var fuel_processing_status_label: Label
var ammo_fabricator_status_label: Label
var fabricator_available_materials_label: Label
var fabricator_materials_list: VBoxContainer
var treasure_processing_status_label: Label
var upgrade_levels: Dictionary = {}
var upgrade_definitions: Dictionary = {}
var upgrade_stat_rules: Dictionary = {}
var base_upgrade_stats: Dictionary = {}
var last_treasure_processing_result: String = ""
var fuel_consumption_multiplier: float = 1.0
var fuel_processing_active: bool = false
var fuel_processing_remaining_seconds: float = 0.0
var recent_resource_sales: Dictionary = {}
var ammo_fabricator_components: Dictionary = {
	"explosive_powder": 0,
	"explosive_casing": 0,
}
var ammo_fabricator_stock: Dictionary = {"explosive_charge": 0}
var miner_ammo: Dictionary = {"explosive_charge": 0}
var fabricator_unlocked: bool = false
var fabricator_message_shown: bool = false
var fabricator_output: Dictionary = {}
var fabricator_status_message: String = ""
var lift_stations: Array[Dictionary] = []
var lift_station_visuals: Array[Node2D] = []
var gps_marker_cells: Array[Vector2i] = []
var gps_marker_visuals: Array[Node2D] = []
var lift_status_message: String = "Press L underground to construct a lift station."
var progression_metrics: Dictionary = {
	"elapsed_seconds": 0.0,
	"active_drilling_seconds": 0.0,
	"travel_seconds": 0.0,
	"combat_seconds": 0.0,
	"management_seconds": 0.0,
	"time_to_first_upgrade": -1.0,
	"time_to_sensor_level_1": -1.0,
	"time_to_first_fabricated_component": -1.0,
	"time_to_first_lift_activation": -1.0,
	"time_to_planet_core": -1.0,
	"resources_earned": {},
	"resources_spent": {},
}
var has_fuel_depot: bool = false
var fuel_depot_sprite: Sprite2D
var fuel_depot_pipe_sprite: Sprite2D
var planned_filling_stations: Array[Dictionary] = []
var planned_pipe_connections: Array[Dictionary] = []
var game_over_label: Label
var game_over_actions: VBoxContainer
var load_last_save_button: Button
var countdown_label: Label
var cargo_hauler_dialog: AcceptDialog
var cargo_hauler_intro_page: int = 0
var shallow_scan_dialog: AcceptDialog
var developer_test_panel: Node
var developer_cave_direction_arrow: Node2D
var core_vault_system: Node2D
var pending_core_vault_state: Dictionary = {}
var locked_core_vault_seal_cells: Dictionary = {}
var mining_camera: Camera2D
var mining_effects: Node2D
var ground_encounter_system: GroundEncounterSystem
var miner_laser_system: MinerLaserSystem
var pending_ground_encounter_state: Dictionary = {}
var fog_overlay: Node2D
var sensor_twinkle_overlay: Node2D
var planet_map_overlay = null
var map_previous_paused: bool = false
var terrain_depth_darkening_overlay: Node2D
var mining_blink_overlay: Polygon2D
var mining_progress_overlay: Polygon2D
var revealed_cells: Dictionary = {}
var active_mining_cell: Vector2i = Vector2i(-9999, -9999)
var active_mining_damage: float = 0.0
var active_mining_elapsed: float = 0.0
var mining_feedback_cooldown: float = 0.0
var active_block_hardness: float = 0.0
var drill_access_message: String = ""
var drill_access_message_remaining: float = 0.0
var lodestone_fall_speed: float = 0.0
var lodestone_fall_distance: float = 0.0
var has_copper_drill_upgrade: bool = false
var has_sensor_upgrade: bool = false
var generated_row_count: int = 0
var planet_generation_rng := RandomNumberGenerator.new()
var shop_back_callback := Callable()
var enemy_contact_made: bool = false
var first_enemy_cave_warning_shown: bool = false


func _ready() -> void:
	SeedManager.enter_starting_planet()
	configure_crisp_canvas_items()
	pause_menu.resume_requested.connect(_on_resume_pressed)
	pause_menu.quit_requested.connect(_on_quit_pressed)
	initialize_planetary_infrastructure_hooks()
	credits = starting_credits
	fuel_seconds = max_fuel_seconds
	hull_health = max_hull_health
	capacitor_energy = capacitor_capacity
	shield_health = max_shield_health
	starship_mining_fuel_kg = mini(starting_starship_mining_fuel_kg, max_starship_mining_fuel_kg)
	fill_lander_mining_fuel_from_starship()
	
	generate_mine_tiles()
	position_player_in_sky()
	create_surface_shop()
	create_terrain_depth_darkening_overlay()
	create_mining_camera()
	create_mining_effects()
	create_ground_encounter_system()
	create_miner_laser_system()
	create_developer_cave_direction_arrow()
	create_core_vault_system()
	create_fog_overlay()
	create_sensor_twinkle_overlay()
	create_mining_overlays()
	create_shop_ui()
	create_developer_test_panel()
	create_game_over_ui()
	create_hud()
	create_planet_map_overlay()
	update_revealed_cells()
	update_camera()
	update_hud()
	var pending_save := SaveManager.consume_pending_scene_state(scene_file_path)
	if pending_save.is_empty():
		show_cargo_hauler_intro_if_needed()
	else:
		apply_save_data(pending_save)
		show_cargo_hauler_intro_if_needed()


func create_save_data() -> Dictionary:
	var terrain_cells: Array = []
	for cell_value in block_types_by_cell.keys():
		var cell: Vector2i = cell_value
		var atlas := visual_mine_tiles.get_cell_atlas_coords(cell)
		terrain_cells.append([
			cell.x,
			cell.y,
			int(block_types_by_cell[cell]),
			atlas.x,
			atlas.y,
			visual_mine_tiles.get_cell_alternative_tile(cell),
		])
	var background_cells: Array = []
	for cell in background_tiles.get_used_cells():
		var atlas := background_tiles.get_cell_atlas_coords(cell)
		background_cells.append([
			cell.x,
			cell.y,
			atlas.x,
			atlas.y,
			background_tiles.get_cell_alternative_tile(cell),
		])
	var revealed_cell_data: Array = []
	for cell_value in revealed_cells.keys():
		var cell: Vector2i = cell_value
		revealed_cell_data.append([cell.x, cell.y])
	var planned_void_data: Array = []
	for cell_value in planned_void_cells.keys():
		var cell: Vector2i = cell_value
		planned_void_data.append([cell.x, cell.y])
	var planned_ground_cave_rock_data: Array = []
	for cell_value in planned_ground_cave_rock_cells.keys():
		var cell: Vector2i = cell_value
		planned_ground_cave_rock_data.append([cell.x, cell.y])

	return {
		"state_version": 2,
		"balance_config_version": StartingPlanetBalance.CONFIG_VERSION,
		"power_scale_version": POWER_SCALE_VERSION,
		"player_position": [player_marker.position.x, player_marker.position.y],
		"player_velocity": [player_velocity.x, player_velocity.y],
		"current_drill_facing": [current_drill_facing.x, current_drill_facing.y],
		"fuel_seconds": fuel_seconds,
		"hull_health": hull_health,
		"heat_ratio": heat_ratio,
		"capacitor_energy": capacitor_energy,
		"shield_health": shield_health,
		"laser_fire_cooldown_remaining": laser_fire_cooldown_remaining,
		"shield_recharge_delay_remaining": shield_recharge_delay_remaining,
		"credits": credits,
		"resources": resources.duplicate(true),
		"cargo_hold_resources": cargo_hold_resources.duplicate(true),
		"lander_mining_fuel_kg": lander_mining_fuel_kg,
		"lander_rocket_fuel_tons": lander_rocket_fuel_tons,
		"starship_mining_fuel_kg": starship_mining_fuel_kg,
		"upgrade_levels": upgrade_levels.duplicate(true),
		"has_copper_drill_upgrade": has_copper_drill_upgrade,
		"has_sensor_upgrade": has_sensor_upgrade,
		"fuel_processing_active": fuel_processing_active,
		"fuel_processing_remaining_seconds": fuel_processing_remaining_seconds,
		"recent_resource_sales": recent_resource_sales.duplicate(true),
		"enemy_contact_made": enemy_contact_made,
		"first_enemy_cave_warning_shown": first_enemy_cave_warning_shown,
		"ammo_fabricator_components": ammo_fabricator_components.duplicate(true),
		"ammo_fabricator_stock": ammo_fabricator_stock.duplicate(true),
		"miner_ammo": miner_ammo.duplicate(true),
		"fabricator_unlocked": fabricator_unlocked,
		"fabricator_message_shown": fabricator_message_shown,
		"fabricator_output": fabricator_output.duplicate(true),
		"lift_stations": lift_stations.duplicate(true),
		"gps_marker_cells": gps_marker_cells.map(func(cell: Vector2i): return [cell.x, cell.y]),
		"progression_metrics": progression_metrics.duplicate(true),
		"last_treasure_processing_result": last_treasure_processing_result,
		"radial_blast_cooldown_remaining": radial_blast_cooldown_remaining,
		"directional_blast_cooldown_remaining": directional_blast_cooldown_remaining,
		"generated_row_count": generated_row_count,
		"planet_generation_rng_state": str(planet_generation_rng.state),
		"planet_core_cell": [planet_core_cell.x, planet_core_cell.y],
		"terrain_cells": terrain_cells,
		"background_cells": background_cells,
		"revealed_cells": revealed_cell_data,
		"planned_void_cells": planned_void_data,
		"planned_ground_cave_rock_cells": planned_ground_cave_rock_data,
		"planned_ground_encounters": planned_ground_encounters.duplicate(true),
		"ground_encounter_state": (
			ground_encounter_system.create_save_data()
			if ground_encounter_system != null
			else {}
		),
		"core_vault_layout_version": 1,
		"core_vault_state": core_vault_system.create_save_data() if core_vault_system != null else {},
	}


func apply_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	upgrade_levels = dictionary_with_string_keys(data.get("upgrade_levels", {}))
	migrate_legacy_upgrade_ids()
	clamp_upgrade_levels_to_current_caps()
	recalculate_stats_from_upgrade_levels()
	resources = dictionary_with_string_keys(data.get("resources", {}))
	cargo_hold_resources = dictionary_with_string_keys(data.get("cargo_hold_resources", {}))
	credits = maxi(int(data.get("credits", credits)), 0)
	fuel_seconds = clampf(float(data.get("fuel_seconds", fuel_seconds)), 0.0, max_fuel_seconds)
	hull_health = clampi(int(data.get("hull_health", hull_health)), 0, max_hull_health)
	heat_ratio = clampf(float(data.get("heat_ratio", heat_ratio)), 0.0, 1.0)
	var loaded_capacitor_energy := migrate_saved_capacitor_energy(
		float(data.get("capacitor_energy", capacitor_capacity)),
		int(data.get("power_scale_version", 1))
	)
	capacitor_energy = clampf(loaded_capacitor_energy, 0.0, capacitor_capacity)
	shield_health = clampf(float(data.get("shield_health", max_shield_health)), 0.0, max_shield_health)
	shield_powered = shield_health > 0.0 and capacitor_energy > 0.0
	laser_fire_cooldown_remaining = maxf(float(data.get("laser_fire_cooldown_remaining", 0.0)), 0.0)
	shield_recharge_delay_remaining = maxf(float(data.get("shield_recharge_delay_remaining", 0.0)), 0.0)
	lander_mining_fuel_kg = clampi(int(data.get("lander_mining_fuel_kg", lander_mining_fuel_kg)), 0, max_lander_mining_fuel_kg)
	lander_rocket_fuel_tons = clampi(int(data.get("lander_rocket_fuel_tons", lander_rocket_fuel_tons)), 0, max_lander_rocket_fuel_tons)
	starship_mining_fuel_kg = clampi(int(data.get("starship_mining_fuel_kg", starship_mining_fuel_kg)), 0, max_starship_mining_fuel_kg)
	has_copper_drill_upgrade = bool(data.get("has_copper_drill_upgrade", false))
	has_sensor_upgrade = bool(data.get("has_sensor_upgrade", false))
	player_marker.modulate = copper_drill_tint if has_copper_drill_upgrade else Color.WHITE
	fuel_processing_active = bool(data.get("fuel_processing_active", false))
	fuel_processing_remaining_seconds = maxf(float(data.get("fuel_processing_remaining_seconds", 0.0)), 0.0)
	recent_resource_sales = dictionary_with_string_keys(data.get("recent_resource_sales", {}))
	enemy_contact_made = bool(data.get("enemy_contact_made", false))
	first_enemy_cave_warning_shown = bool(data.get("first_enemy_cave_warning_shown", false))
	ammo_fabricator_components = dictionary_with_string_keys(data.get("ammo_fabricator_components", ammo_fabricator_components))
	ammo_fabricator_stock = dictionary_with_string_keys(data.get("ammo_fabricator_stock", ammo_fabricator_stock))
	miner_ammo = dictionary_with_string_keys(data.get("miner_ammo", miner_ammo))
	fabricator_unlocked = bool(data.get("fabricator_unlocked", not upgrade_levels.is_empty()))
	fabricator_message_shown = bool(data.get("fabricator_message_shown", fabricator_unlocked))
	fabricator_output = dictionary_with_string_keys(data.get("fabricator_output", {}))
	lift_stations.clear()
	for station_data in data.get("lift_stations", []):
		if station_data is Dictionary:
			lift_stations.append(station_data.duplicate(true))
	gps_marker_cells.clear()
	for marker_data in data.get("gps_marker_cells", []):
		var marker_cell := array_to_cell(marker_data)
		if marker_cell != Vector2i(-1, -1) and not gps_marker_cells.has(marker_cell):
			gps_marker_cells.append(marker_cell)
	var loaded_metrics := dictionary_with_string_keys(data.get("progression_metrics", {}))
	if not loaded_metrics.is_empty():
		for metric_name in progression_metrics:
			if loaded_metrics.has(metric_name):
				progression_metrics[metric_name] = loaded_metrics[metric_name]
	clamp_ammo_fabricator_state()
	last_treasure_processing_result = str(data.get("last_treasure_processing_result", ""))
	radial_blast_cooldown_remaining = maxf(float(data.get("radial_blast_cooldown_remaining", 0.0)), 0.0)
	directional_blast_cooldown_remaining = maxf(float(data.get("directional_blast_cooldown_remaining", 0.0)), 0.0)

	mine_tiles.clear()
	visual_mine_tiles.clear()
	background_tiles.clear()
	block_types_by_cell.clear()
	for entry in data.get("terrain_cells", []):
		if not entry is Array or entry.size() < 5:
			continue
		var cell := Vector2i(int(entry[0]), int(entry[1]))
		var block_type := int(entry[2])
		var atlas := Vector2i(int(entry[3]), int(entry[4]))
		var alternative := int(entry[5]) if entry.size() > 5 else 0
		block_types_by_cell[cell] = block_type
		visual_mine_tiles.set_cell(cell, tile_source_id, atlas, alternative)
	for entry in data.get("background_cells", []):
		if not entry is Array or entry.size() < 4:
			continue
		var cell := Vector2i(int(entry[0]), int(entry[1]))
		var atlas := Vector2i(int(entry[2]), int(entry[3]))
		var alternative := int(entry[4]) if entry.size() > 4 else 0
		background_tiles.set_cell(cell, tile_source_id, atlas, alternative)
	generated_row_count = maxi(int(data.get("generated_row_count", grid_height)), 0)
	planet_generation_rng.seed = get_active_planet_seed()
	planet_generation_rng.state = int(str(data.get("planet_generation_rng_state", planet_generation_rng.state)))
	var saved_core: Array = data.get("planet_core_cell", [-1, -1])
	planet_core_cell = Vector2i(int(saved_core[0]), int(saved_core[1])) if saved_core.size() >= 2 else Vector2i(-1, -1)
	planned_void_cells.clear()
	for entry in data.get("planned_void_cells", []):
		if entry is Array and entry.size() >= 2:
			planned_void_cells[Vector2i(int(entry[0]), int(entry[1]))] = true
	planned_ground_cave_rock_cells.clear()
	var save_has_ground_cave_rock_cells := data.has("planned_ground_cave_rock_cells")
	for entry in data.get("planned_ground_cave_rock_cells", []):
		if entry is Array and entry.size() >= 2:
			planned_ground_cave_rock_cells[Vector2i(int(entry[0]), int(entry[1]))] = true
	planned_ground_encounters.clear()
	for saved_encounter in data.get("planned_ground_encounters", []):
		if saved_encounter is Dictionary:
			planned_ground_encounters.append(saved_encounter.duplicate(true))
	if not data.has("enemy_contact_made"):
		for encounter in planned_ground_encounters:
			if bool(encounter.get("triggered", false)):
				enemy_contact_made = true
				first_enemy_cave_warning_shown = true
				break
	remove_ground_encounters_in_core_zone()
	if not save_has_ground_cave_rock_cells:
		retrofit_ground_cave_rock_shells()
	var needs_core_vault_retrofit := int(data.get("core_vault_layout_version", 0)) < 1
	plan_core_vault_layout(needs_core_vault_retrofit, has_planet_core())
	# Add deterministic caves to older saves without requiring a fresh planet.
	plan_ground_caves_through_row(generated_row_count)
	pending_ground_encounter_state = dictionary_with_string_keys(data.get("ground_encounter_state", {}))
	pending_core_vault_state = dictionary_with_string_keys(data.get("core_vault_state", {}))
	revealed_cells.clear()
	for entry in data.get("revealed_cells", []):
		if entry is Array and entry.size() >= 2:
			revealed_cells[Vector2i(int(entry[0]), int(entry[1]))] = true
	var saved_position: Array = data.get("player_position", [player_marker.position.x, player_marker.position.y])
	if saved_position.size() >= 2:
		player_marker.position = Vector2(float(saved_position[0]), float(saved_position[1]))
	var saved_velocity: Array = data.get("player_velocity", [0.0, 0.0])
	if saved_velocity.size() >= 2:
		player_velocity = Vector2(float(saved_velocity[0]), float(saved_velocity[1]))
	var saved_facing: Array = data.get("current_drill_facing", [0, 1])
	if saved_facing.size() >= 2:
		current_drill_facing = Vector2i(int(saved_facing[0]), int(saved_facing[1]))
		last_mine_direction = current_drill_facing
	is_paused = false
	is_shop_open = false
	is_game_over = false
	reset_mining_progress()
	update_revealed_cells()
	update_camera()
	update_shop_ui()
	update_hud()
	if ground_encounter_system != null:
		ground_encounter_system.sync_encounters(planned_ground_encounters)
		ground_encounter_system.apply_save_data(pending_ground_encounter_state)
		pending_ground_encounter_state.clear()
	if core_vault_system != null:
		core_vault_system.apply_save_data(pending_core_vault_state)
		pending_core_vault_state.clear()
	rebuild_lift_station_visuals()
	rebuild_gps_marker_visuals()
	queue_redraw()


func dictionary_with_string_keys(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not value is Dictionary:
		return result
	for key in value:
		result[str(key)] = value[key]
	return result


func _process(delta: float) -> void:
	update_progression_metrics(delta)
	update_fuel_processing(delta)
	update_market_pressure(delta)
	try_transfer_fabricator_output()


func show_cargo_hauler_intro_if_needed() -> void:
	if not SeedManager.should_show_cargo_hauler_intro():
		return

	SeedManager.mark_cargo_hauler_intro_shown()
	cargo_hauler_intro_page = 0
	cargo_hauler_dialog = AcceptDialog.new()
	cargo_hauler_dialog.title = "Incoming Transmission: Cargo Hauler"
	cargo_hauler_dialog.exclusive = true
	cargo_hauler_dialog.confirmed.connect(_on_cargo_hauler_intro_confirmed)
	add_child(cargo_hauler_dialog)
	show_current_cargo_hauler_intro_page()


func show_current_cargo_hauler_intro_page() -> void:
	if cargo_hauler_dialog == null:
		return
	var pages := SeedManager.get_cargo_hauler_intro_pages()
	if cargo_hauler_intro_page < 0 or cargo_hauler_intro_page >= pages.size():
		return
	cargo_hauler_dialog.dialog_text = pages[cargo_hauler_intro_page]
	match cargo_hauler_intro_page:
		0:
			cargo_hauler_dialog.get_ok_button().text = "Show Me the Controls"
		1:
			cargo_hauler_dialog.get_ok_button().text = "What's the Job?"
		_:
			cargo_hauler_dialog.get_ok_button().text = "Begin Mining"
	popup_wrapped_transmission(cargo_hauler_dialog, Vector2i(820, 500))


func _on_cargo_hauler_intro_confirmed() -> void:
	cargo_hauler_intro_page += 1
	if cargo_hauler_intro_page >= SeedManager.get_cargo_hauler_intro_pages().size():
		var finished_intro_dialog := cargo_hauler_dialog
		cargo_hauler_dialog = null
		finished_intro_dialog.tree_exited.connect(
			func(): show_shallow_scan_transmission.call_deferred(),
			CONNECT_ONE_SHOT
		)
		finished_intro_dialog.queue_free()
		return
	# AcceptDialog hides itself after confirmation, so reopen it on the next frame.
	show_current_cargo_hauler_intro_page.call_deferred()


func show_shallow_scan_transmission() -> void:
	if shallow_scan_dialog != null:
		return
	shallow_scan_dialog = AcceptDialog.new()
	shallow_scan_dialog.title = "Incoming Transmission: Shallow Scan"
	shallow_scan_dialog.dialog_text = SeedManager.get_cargo_hauler_shallow_scan_text()
	shallow_scan_dialog.exclusive = true
	shallow_scan_dialog.get_ok_button().text = "Follow the Pixie Dust"
	shallow_scan_dialog.confirmed.connect(_on_shallow_scan_confirmed)
	add_child(shallow_scan_dialog)
	popup_wrapped_transmission(shallow_scan_dialog, Vector2i(820, 420))
	if sensor_twinkle_overlay != null:
		sensor_twinkle_overlay.queue_redraw()


func _on_shallow_scan_confirmed() -> void:
	if shallow_scan_dialog == null:
		return
	shallow_scan_dialog.queue_free()
	shallow_scan_dialog = null


func popup_wrapped_transmission(dialog: AcceptDialog, preferred_size: Vector2i) -> void:
	var viewport_size := Vector2i(get_viewport().get_visible_rect().size)
	var safe_size := Vector2i(
		mini(preferred_size.x, maxi(viewport_size.x - 80, 1)),
		mini(preferred_size.y, maxi(viewport_size.y - 80, 1))
	)
	var text_label := dialog.get_label()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_label.custom_minimum_size = Vector2.ZERO
	dialog.max_size = safe_size
	dialog.popup_centered(safe_size)


func unlock_fabricator_after_first_upgrade() -> void:
	if fabricator_unlocked:
		return
	fabricator_unlocked = true
	show_fabricator_delivery_message()


func show_fabricator_delivery_message() -> void:
	if fabricator_message_shown:
		return
	fabricator_message_shown = true
	var dialog := AcceptDialog.new()
	dialog.title = "Incoming Transmission: Cargo Hauler"
	dialog.dialog_text = (
		"That first upgrade will get you started, but rough rocks and raw ore won't get you off this planet. "
		+ "I'm sending down a fabrication station. Keep it up to date—the deeper parts of this system hide the good stuff, "
		+ "and you'll need better tech to reach it.\n\n"
		+ "Check the explosives recipe, too. Those charges will be your best friend when tricky terrain stands between you "
		+ "and some juicy ore just out of reach."
	)
	dialog.get_ok_button().text = "Open Fabricator"
	dialog.confirmed.connect(show_fabricator_view)
	add_child(dialog)
	dialog.popup_centered(Vector2i(780, 430))


func show_first_enemy_cave_warning() -> void:
	if first_enemy_cave_warning_shown:
		return
	# Do not stack an exclusive cave warning over the opening or shallow-scan call.
	# Proximity is checked continuously, so it will appear once the active call ends.
	if cargo_hauler_dialog != null or shallow_scan_dialog != null or has_visible_child_window():
		return
	first_enemy_cave_warning_shown = true
	var dialog := AcceptDialog.new()
	dialog.title = "Incoming Transmission: Cargo Hauler"
	dialog.dialog_text = (
		"Ease up there, partner. That hollow ahead ain't natural, and my scanner is catching hostile movement around it.\n\n"
		+ "Looks like an altar tied to some kind of portal. If you disturb it, expect company. Keep your distance, use your laser or explosives, and watch your shields, heat, and fuel. Drop every hostile and that portal ought to collapse."
	)
	dialog.get_ok_button().text = "I'll Handle It"
	add_child(dialog)
	popup_wrapped_transmission(dialog, Vector2i(780, 430))


func has_visible_child_window() -> bool:
	for child in get_children():
		if child is Window and (child as Window).visible:
			return true
	return false


func on_first_enemy_contact() -> void:
	if enemy_contact_made:
		return
	enemy_contact_made = true
	drill_access_message = "First contact confirmed: combat, shield, life-support, and thermal upgrades unlocked."
	drill_access_message_remaining = 5.0
	if is_shop_open:
		show_miner_component_view()
	update_hud()


func initialize_planetary_infrastructure_hooks() -> void:
	# TODO: Build filling stations as placeable underground refuel points.
	planned_filling_stations = []
	# TODO: Store pipe connections from the Fuel Depot to filling stations.
	planned_pipe_connections = []
	# TODO: Validate future pipe paths with simple straight-line checks before construction.
	lift_stations = []


func configure_crisp_canvas_items() -> void:
	mine_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual_mine_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _physics_process(delta: float) -> void:
	if is_paused or is_arrival_countdown_active:
		return
	
	handle_player_movement(delta)
	update_mine_direction()
	update_ability_cooldowns(delta)
	update_capacitor_and_shield(delta)
	update_laser_turret(delta)
	drain_fuel_for_movement(delta)
	update_mining_feedback_cooldown(delta)
	drill_access_message_remaining = maxf(drill_access_message_remaining - delta, 0.0)
	if drill_access_message_remaining <= 0.0:
		drill_access_message = ""
	update_fuel_bar(delta)
	check_shop_collision()
	ensure_world_generated_near_player()
	update_lodestone_gravity(delta)
	update_camera()
	try_mine_with_movement_input(delta)
	update_player_visual(delta)
	update_revealed_cells()
	update_mining_overlays()
	if ground_encounter_system != null:
		ground_encounter_system.process_encounters(delta)
	if miner_laser_system != null:
		miner_laser_system.process_projectiles(delta)
	if developer_cave_direction_arrow != null:
		developer_cave_direction_arrow.update_arrow()
	if core_vault_system != null:
		core_vault_system.process_encounter(delta)
	queue_redraw()


func generate_mine_tiles() -> void:
	mine_tiles.clear()
	background_tiles.clear()
	visual_mine_tiles.clear()
	block_types_by_cell.clear()
	planned_void_cells.clear()
	planned_ground_cave_rock_cells.clear()
	planned_ground_encounters.clear()
	locked_core_vault_seal_cells.clear()
	revealed_cells.clear()
	planet_core_cell = Vector2i(-1, -1)
	generated_row_count = 0
	planet_generation_rng.seed = get_active_planet_seed()
	plan_core_vault_layout(false, false)
	
	generate_rows_until(grid_height)


func generate_rows_until(target_row_count: int) -> void:
	if target_row_count <= generated_row_count:
		return
	plan_ground_caves_through_row(target_row_count)
	
	for y in range(generated_row_count, target_row_count):
		for x in grid_width:
			var cell_position := Vector2i(x, y)
			
			if y < empty_top_rows:
				continue
			
			background_tiles.set_cell(
				cell_position,
				tile_source_id,
				get_dug_dirt_tile_coords(cell_position)
			)
			
			var block_type := choose_block_type_for_depth(y)
			block_type = get_shallow_starting_ore_type(cell_position, block_type)
			block_type = get_early_iron_type(cell_position, block_type)
			var force_cave_wall_rock := planned_ground_cave_rock_cells.has(cell_position)
			if planned_void_cells.has(cell_position):
				block_type = BlockType.EMPTY
			elif should_place_planet_core_at_cell(cell_position):
				block_type = BlockType.PLANETCORE
			else:
				if block_type == BlockType.ROCK and should_convert_rock_to_lodestone(y):
					block_type = BlockType.LODESTONE
				elif block_type == BlockType.DIRT and should_make_dirt_cell_void(cell_position):
					block_type = BlockType.EMPTY
				if force_cave_wall_rock:
					block_type = BlockType.ROCK
			if is_core_barrier_cell(cell_position):
				block_type = get_core_barrier_block_type(cell_position)
			block_type = get_authored_starting_deposit_type(cell_position, block_type)
			var tile_coords := get_tile_coords_for_block_type(block_type, cell_position)
			
			if block_type != BlockType.EMPTY:
				visual_mine_tiles.set_cell(
					cell_position,
					tile_source_id,
					tile_coords
				)
				block_types_by_cell[cell_position] = block_type
	
	generated_row_count = target_row_count
	if ground_encounter_system != null:
		ground_encounter_system.sync_encounters(planned_ground_encounters)
	if terrain_depth_darkening_overlay != null:
		terrain_depth_darkening_overlay.queue_redraw()


func plan_ground_caves_through_row(target_row_count: int) -> void:
	var interval_rows := maxi(roundi(float(ground_cave_interval_meters) / maxf(float(depth_meters_per_row), 1.0)), 1)
	var tolerance_rows := maxi(roundi(float(ground_cave_depth_tolerance_meters) / maxf(float(depth_meters_per_row), 1.0)), 0)
	var deepest_depth_row := maxi(target_row_count - get_first_ground_row(), 0)
	var maximum_level := floori(float(deepest_depth_row + tolerance_rows) / float(interval_rows))
	for level in range(1, maximum_level + 1):
		if level * ground_cave_interval_meters >= core_barrier_start_depth_meters:
			break
		var encounter_id := "tribal_altar_%04dm" % (level * ground_cave_interval_meters)
		if has_planned_ground_encounter(encounter_id):
			continue
		plan_ground_cave(level, encounter_id, interval_rows, tolerance_rows)


func has_planned_ground_encounter(encounter_id: String) -> bool:
	for encounter in planned_ground_encounters:
		if str(encounter.get("encounter_id", "")) == encounter_id:
			return true
	return false


func plan_ground_cave(level: int, encounter_id: String, interval_rows: int, tolerance_rows: int) -> void:
	var cave_rng := RandomNumberGenerator.new()
	cave_rng.seed = SeedManager.derive_seed(SeedManager.starting_planet_seed, encounter_id)
	var radius := maxi(ground_cave_radius_blocks, 2)
	var maximum_wall_thickness := 5
	var horizontal_margin := radius + maximum_wall_thickness
	var center_x := cave_rng.randi_range(
		mini(horizontal_margin, maxi(grid_width / 2, 1)),
		maxi(grid_width - 1 - horizontal_margin, mini(horizontal_margin, maxi(grid_width / 2, 1)))
	)
	var center_y := get_first_ground_row() + level * interval_rows + cave_rng.randi_range(-tolerance_rows, tolerance_rows)
	var cave_cells: Array = []
	for offset_y in range(-radius, radius + 1):
		for offset_x in range(-radius, radius + 1):
			var normalized_distance := (
				pow(float(offset_x) / float(radius + 1), 2.0)
				+ pow(float(offset_y) / float(radius + 1), 2.0)
			)
			var edge_variation := cave_rng.randf_range(-0.18, 0.18)
			if normalized_distance > 1.0 + edge_variation:
				continue
			var cell := Vector2i(center_x + offset_x, center_y + offset_y)
			if cell.x <= 0 or cell.x >= grid_width - 1 or cell.y < get_first_ground_row():
				continue
			if register_ground_cave_void_cell(cell):
				cave_cells.append([cell.x, cell.y])

	var altar_cell := Vector2i(center_x, center_y + mini(radius - 1, 2))
	var portal_side := -1 if cave_rng.randi() % 2 == 0 else 1
	var portal_cell := Vector2i(center_x + portal_side * mini(radius - 1, 2), center_y)
	if altar_cell == planet_core_cell:
		altar_cell.x = clampi(altar_cell.x + 1, 1, grid_width - 2)
	if portal_cell == planet_core_cell:
		portal_cell.x = clampi(portal_cell.x - portal_side, 1, grid_width - 2)
	register_ground_cave_void_cell(altar_cell)
	register_ground_cave_void_cell(portal_cell)
	var wall_thickness := get_ground_cave_wall_thickness(encounter_id)
	var wall_cells := plan_ground_cave_rock_shell(cave_cells, wall_thickness)
	planned_ground_encounters.append({
		"encounter_id": encounter_id,
		"enemy_faction": "tribal_demons",
		"depth_level": level,
		"target_depth_meters": level * ground_cave_interval_meters,
		"cave_center_cell": [center_x, center_y],
		"altar_cell": [altar_cell.x, altar_cell.y],
		"portal_cell": [portal_cell.x, portal_cell.y],
		"cave_cells": cave_cells,
		"wall_thickness": wall_thickness,
		"wall_cells": wall_cells,
		"looted": false,
		"triggered": false,
		"defeated": false,
		"defeated_count": 0,
	})


func register_ground_cave_void_cell(cell: Vector2i) -> bool:
	if cell == planet_core_cell:
		return false
	planned_void_cells[cell] = true
	if cell.y < generated_row_count:
		block_types_by_cell.erase(cell)
		visual_mine_tiles.erase_cell(cell)
	return true


func get_ground_cave_wall_thickness(encounter_id: String) -> int:
	var wall_rng := RandomNumberGenerator.new()
	wall_rng.seed = SeedManager.derive_seed(SeedManager.starting_planet_seed, encounter_id + "_rock_shell")
	return wall_rng.randi_range(2, 5)


func plan_ground_cave_rock_shell(cave_cells: Array, wall_thickness: int) -> Array:
	var shell_cells: Dictionary = {}
	for cave_cell_data in cave_cells:
		if not cave_cell_data is Array or cave_cell_data.size() < 2:
			continue
		var cave_cell := Vector2i(int(cave_cell_data[0]), int(cave_cell_data[1]))
		for offset_y in range(-wall_thickness, wall_thickness + 1):
			for offset_x in range(-wall_thickness, wall_thickness + 1):
				var shell_cell := cave_cell + Vector2i(offset_x, offset_y)
				if (
					shell_cell.x < 0
					or shell_cell.x >= grid_width
					or shell_cell.y < get_first_ground_row()
					or planned_void_cells.has(shell_cell)
				):
					continue
				shell_cells[shell_cell] = true
	var serialized_shell_cells: Array = []
	for cell_value in shell_cells.keys():
		var shell_cell: Vector2i = cell_value
		if register_ground_cave_rock_cell(shell_cell):
			serialized_shell_cells.append([shell_cell.x, shell_cell.y])
	return serialized_shell_cells


func register_ground_cave_rock_cell(cell: Vector2i) -> bool:
	if cell == planet_core_cell or planned_void_cells.has(cell):
		return false
	planned_ground_cave_rock_cells[cell] = true
	if cell.y < generated_row_count:
		block_types_by_cell[cell] = BlockType.ROCK
		visual_mine_tiles.set_cell(
			cell,
			tile_source_id,
			get_tile_coords_for_block_type(BlockType.ROCK, cell)
		)
	return true


func retrofit_ground_cave_rock_shells() -> void:
	for encounter in planned_ground_encounters:
		var encounter_id := str(encounter.get("encounter_id", ""))
		var wall_thickness := get_ground_cave_wall_thickness(encounter_id)
		encounter["wall_thickness"] = wall_thickness
		encounter["wall_cells"] = plan_ground_cave_rock_shell(
			encounter.get("cave_cells", []),
			wall_thickness
		)


func remove_ground_encounters_in_core_zone() -> void:
	for index in range(planned_ground_encounters.size() - 1, -1, -1):
		if int(planned_ground_encounters[index].get("target_depth_meters", 0)) >= core_barrier_start_depth_meters:
			planned_ground_encounters.remove_at(index)


func get_core_vault_top_row() -> int:
	return get_first_ground_row() + roundi(
		float(core_vault_start_depth_meters) / maxf(float(depth_meters_per_row), 1.0)
	)


func get_core_vault_left_column() -> int:
	return maxi((grid_width - core_vault_width_blocks) / 2, 1)


func get_core_vault_right_column() -> int:
	return mini(get_core_vault_left_column() + core_vault_width_blocks - 1, grid_width - 2)


func get_core_vault_entrance_center_cell() -> Vector2i:
	return Vector2i(grid_width / 2, get_core_vault_top_row())


func get_core_vault_portal_cells() -> Array[Vector2i]:
	var left := get_core_vault_left_column()
	var right := get_core_vault_right_column()
	var top := get_core_vault_top_row()
	return [
		Vector2i(left + 5, top + 5),
		Vector2i(right - 5, top + 5),
		Vector2i(left + 7, top + core_vault_height_blocks - 5),
		Vector2i(right - 7, top + core_vault_height_blocks - 5),
	]


func plan_core_vault_layout(retrofit_generated_terrain: bool, core_already_claimed: bool) -> void:
	var old_core_cell := planet_core_cell
	var top := get_core_vault_top_row()
	var left := get_core_vault_left_column()
	var right := get_core_vault_right_column()
	var new_core_cell := Vector2i(grid_width / 2, top + core_vault_height_blocks - 3)
	if old_core_cell != Vector2i(-1, -1) and old_core_cell != new_core_cell:
		if block_types_by_cell.get(old_core_cell, BlockType.EMPTY) == BlockType.PLANETCORE:
			block_types_by_cell.erase(old_core_cell)
			visual_mine_tiles.erase_cell(old_core_cell)
	planet_core_cell = new_core_cell

	var barrier_start_row := get_first_ground_row() + roundi(
		float(core_barrier_start_depth_meters) / maxf(float(depth_meters_per_row), 1.0)
	)
	for row in range(barrier_start_row, top):
		for column in grid_width:
			var barrier_cell := Vector2i(column, row)
			planned_void_cells.erase(barrier_cell)
			planned_ground_cave_rock_cells.erase(barrier_cell)
			if retrofit_generated_terrain and row < generated_row_count:
				var barrier_type := get_core_barrier_block_type(barrier_cell)
				block_types_by_cell[barrier_cell] = barrier_type
				visual_mine_tiles.set_cell(
					barrier_cell,
					tile_source_id,
					get_tile_coords_for_block_type(barrier_type, barrier_cell)
				)

	for row in range(top, top + core_vault_height_blocks):
		for column in range(left, right + 1):
			var vault_cell := Vector2i(column, row)
			planned_ground_cave_rock_cells.erase(vault_cell)
			if vault_cell == planet_core_cell and not core_already_claimed:
				planned_void_cells.erase(vault_cell)
				if retrofit_generated_terrain and row < generated_row_count:
					block_types_by_cell[vault_cell] = BlockType.PLANETCORE
					visual_mine_tiles.set_cell(
						vault_cell,
						tile_source_id,
						get_tile_coords_for_block_type(BlockType.PLANETCORE, vault_cell)
					)
				continue
			planned_void_cells[vault_cell] = true
			if retrofit_generated_terrain and row < generated_row_count:
				block_types_by_cell.erase(vault_cell)
				visual_mine_tiles.erase_cell(vault_cell)


func is_core_barrier_cell(cell: Vector2i) -> bool:
	var depth_meters := maxi(cell.y - get_first_ground_row(), 0) * depth_meters_per_row
	return depth_meters >= core_barrier_start_depth_meters and depth_meters < core_vault_start_depth_meters


func get_core_barrier_block_type(cell: Vector2i) -> BlockType:
	var rng := RandomNumberGenerator.new()
	rng.seed = SeedManager.derive_seed(
		SeedManager.starting_planet_seed,
		"core_barrier_%d_%d" % [cell.x, cell.y]
	)
	var roll := rng.randf()
	if roll < 0.9755:
		return BlockType.ROCK
	if roll < 0.9905:
		return BlockType.TREASURE
	if roll < 0.9965:
		return BlockType.DIAMOND
	if roll < 0.999:
		return BlockType.WARPGEMS
	return BlockType.BLACKHOLECRYSTALS


func should_place_planet_core_at_cell(cell_position: Vector2i) -> bool:
	return cell_position == planet_core_cell


func get_planet_core_test_row() -> int:
	return planet_core_cell.y if planet_core_cell != Vector2i(-1, -1) else get_core_vault_top_row() + core_vault_height_blocks - 3


func get_planet_core_future_row() -> int:
	return get_first_ground_row() + floori(float(planet_core_future_depth_meters) / float(depth_meters_per_row))


func should_convert_rock_to_lodestone(row: int) -> bool:
	var depth_meters: int = maxi(row - get_first_ground_row(), 0) * depth_meters_per_row
	if depth_meters < lodestone_start_depth_meters:
		return false
	
	return planet_generation_rng.randf() < get_lodestone_chance_for_depth(depth_meters)


func get_lodestone_chance_for_depth(depth_meters: int) -> float:
	var depth_steps_after_start: float = floorf(
		float(depth_meters - lodestone_start_depth_meters) / 500.0
	)
	return clampf(
		lodestone_base_chance + depth_steps_after_start * lodestone_chance_per_500m,
		0.0,
		lodestone_max_chance
	)


func should_make_dirt_cell_void(cell_position: Vector2i) -> bool:
	if is_core_barrier_cell(cell_position):
		return false
	if planned_ground_cave_rock_cells.has(cell_position):
		return false
	if planned_void_cells.has(cell_position):
		return true
	
	if cell_position.y < get_first_ground_row() + dirt_void_start_depth_rows:
		return false
	
	if planet_generation_rng.randf() >= dirt_void_chance:
		return false
	
	create_dirt_void_from_cell(cell_position)
	return true


func create_dirt_void_from_cell(start_cell: Vector2i) -> void:
	var target_size := planet_generation_rng.randi_range(
		maxi(dirt_void_min_size, 1),
		maxi(dirt_void_max_size, dirt_void_min_size)
	)
	var void_cells: Array[Vector2i] = [start_cell]
	var frontier: Array[Vector2i] = [start_cell]
	planned_void_cells[start_cell] = true
	
	while void_cells.size() < target_size and not frontier.is_empty():
		var source_cell: Vector2i = frontier[planet_generation_rng.randi_range(0, frontier.size() - 1)]
		var neighbor_options := get_shuffled_void_neighbor_cells(source_cell)
		var expanded := false
		
		for neighbor_cell in neighbor_options:
			if not can_add_cell_to_dirt_void(neighbor_cell):
				continue
			
			planned_void_cells[neighbor_cell] = true
			void_cells.append(neighbor_cell)
			frontier.append(neighbor_cell)
			carve_existing_dirt_void_cell(neighbor_cell)
			expanded = true
			break
		
		if not expanded:
			frontier.erase(source_cell)


func get_shuffled_void_neighbor_cells(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = [
		cell + Vector2i.RIGHT,
		cell + Vector2i.DOWN,
		cell + Vector2i.LEFT,
		cell + Vector2i.UP,
	]
	for index in range(neighbors.size() - 1, 0, -1):
		var swap_index := planet_generation_rng.randi_range(0, index)
		var swap_value := neighbors[index]
		neighbors[index] = neighbors[swap_index]
		neighbors[swap_index] = swap_value
	return neighbors


func can_add_cell_to_dirt_void(cell: Vector2i) -> bool:
	if is_core_barrier_cell(cell):
		return false
	if planned_ground_cave_rock_cells.has(cell):
		return false
	if planned_void_cells.has(cell):
		return false
	
	if cell.x < 0 or cell.x >= grid_width:
		return false
	
	if cell.y < get_first_ground_row() + dirt_void_start_depth_rows:
		return false
	
	if cell.y >= generated_row_count:
		return true
	
	return block_types_by_cell.get(cell, BlockType.EMPTY) == BlockType.DIRT


func carve_existing_dirt_void_cell(cell: Vector2i) -> void:
	if block_types_by_cell.get(cell, BlockType.EMPTY) != BlockType.DIRT:
		return
	
	block_types_by_cell.erase(cell)
	visual_mine_tiles.erase_cell(cell)


func choose_block_type_for_depth(y: int) -> BlockType:
	var depth_ratio: float = minf(float(y) / float(depth_distribution_full_row), 1.0)
	var roll := planet_generation_rng.randf()
	
	if depth_ratio < 0.30:
		var copper_bonus := 0.0143 * (clampf(copper_ore_frequency_multiplier, 0.0, 5.0) - 1.0)
		if roll < 0.84475 - copper_bonus:
			return BlockType.DIRT
		elif roll < 0.97725 - copper_bonus:
			return BlockType.ROCK
		elif roll < 0.99155:
			return BlockType.COPPER
		else:
			return BlockType.RAWFUEL
	elif depth_ratio < 0.65:
		var copper_bonus := 0.0455 * (clampf(copper_ore_frequency_multiplier, 0.0, 5.0) - 1.0)
		if roll < 0.701 - copper_bonus:
			return BlockType.DIRT
		elif roll < 0.896 - copper_bonus:
			return BlockType.ROCK
		elif roll < 0.9415:
			return BlockType.COPPER
		elif roll < 0.974:
			return BlockType.RAWFUEL
		elif roll < 0.99025:
			return BlockType.IRON
		elif roll < 0.99675:
			return BlockType.GOLD
		else:
			return BlockType.TREASURE
	else:
		var copper_bonus := 0.052 * (clampf(copper_ore_frequency_multiplier, 0.0, 5.0) - 1.0)
		if roll < 0.558 - copper_bonus:
			return BlockType.DIRT
		elif roll < 0.818 - copper_bonus:
			return BlockType.ROCK
		elif roll < 0.87:
			return BlockType.COPPER
		elif roll < 0.9155:
			return BlockType.RAWFUEL
		elif roll < 0.948:
			return BlockType.IRON
		elif roll < 0.97075:
			return BlockType.GOLD
		elif roll < 0.987:
			return BlockType.TREASURE
		elif roll < 0.9948:
			return BlockType.DIAMOND
		elif roll < 0.99805:
			return BlockType.WARPGEMS
		else:
			return BlockType.BLACKHOLECRYSTALS


func get_authored_starting_deposit_type(cell: Vector2i, generated_type: BlockType) -> BlockType:
	if SeedManager.current_system_id != SeedManager.STARTING_SYSTEM_ID:
		return generated_type
	var relative_cell := Vector2i(
		cell.x - get_lander_surface_column(),
		cell.y - get_first_ground_row()
	)
	if relative_cell in StartingPlanetBalance.GUARANTEED_STARTER_DEPOSITS["copper"]:
		return BlockType.COPPER
	if relative_cell in StartingPlanetBalance.GUARANTEED_STARTER_DEPOSITS["raw_fuel"]:
		return BlockType.RAWFUEL
	if relative_cell in StartingPlanetBalance.GUARANTEED_STARTER_DEPOSITS["iron"]:
		return BlockType.IRON
	return generated_type


func get_shallow_starting_ore_type(cell: Vector2i, generated_type: BlockType) -> BlockType:
	if SeedManager.current_system_id != SeedManager.STARTING_SYSTEM_ID:
		return generated_type
	var depth_meters := maxi(cell.y - get_first_ground_row(), 0) * depth_meters_per_row
	if depth_meters > StartingPlanetBalance.SHALLOW_STARTER_ORE_DEPTH_METERS:
		return generated_type
	if generated_type not in [BlockType.DIRT, BlockType.ROCK]:
		return generated_type
	var shallow_seed := SeedManager.derive_seed(
		SeedManager.starting_planet_seed,
		"shallow_starter_ore:%d:%d" % [cell.x, cell.y]
	)
	var shallow_rng := RandomNumberGenerator.new()
	shallow_rng.seed = shallow_seed
	var roll := shallow_rng.randf()
	if roll < StartingPlanetBalance.SHALLOW_COPPER_CHANCE:
		return BlockType.COPPER
	if roll < StartingPlanetBalance.SHALLOW_COPPER_CHANCE + StartingPlanetBalance.SHALLOW_RAW_FUEL_CHANCE:
		return BlockType.RAWFUEL
	return generated_type


func get_early_iron_type(cell: Vector2i, generated_type: BlockType) -> BlockType:
	if SeedManager.current_system_id != SeedManager.STARTING_SYSTEM_ID:
		return generated_type
	var depth_meters := maxi(cell.y - get_first_ground_row(), 0) * depth_meters_per_row
	if depth_meters > StartingPlanetBalance.EARLY_IRON_DEPTH_METERS:
		return generated_type
	if generated_type not in [BlockType.DIRT, BlockType.ROCK]:
		return generated_type
	var rng := RandomNumberGenerator.new()
	rng.seed = SeedManager.derive_seed(
		SeedManager.starting_planet_seed,
		"early_iron:%d:%d" % [cell.x, cell.y]
	)
	return BlockType.IRON if rng.randf() < StartingPlanetBalance.EARLY_IRON_CHANCE else generated_type


func get_active_planet_seed() -> int:
	if SeedManager.current_system_id == SeedManager.STARTING_SYSTEM_ID:
		return SeedManager.starting_planet_seed
	return SeedManager.get_current_system_seed()


func get_tile_coords_for_block_type(block_type: BlockType, cell_position: Vector2i) -> Vector2i:
	match block_type:
		BlockType.DIRT:
			return pick_seeded_tile_coords(dirt_tiles, Vector2i(0, 0), cell_position, "dirt")
		BlockType.ROCK:
			return pick_seeded_tile_coords(rock_tiles, Vector2i(4, 0), cell_position, "rock")
		BlockType.LODESTONE:
			return pick_seeded_tile_coords(rock_tiles, Vector2i(4, 0), cell_position, "lodestone")
		BlockType.COPPER:
			return pick_seeded_tile_coords(copper_tiles, Vector2i(4, 1), cell_position, "copper")
		BlockType.RAWFUEL:
			return pick_seeded_tile_coords(rawfuel_tiles, Vector2i(0, 1), cell_position, "raw_fuel")
		BlockType.IRON:
			return pick_seeded_tile_coords(iron_tiles, Vector2i(0, 2), cell_position, "iron")
		BlockType.GOLD:
			return pick_seeded_tile_coords(gold_tiles, Vector2i(3, 2), cell_position, "gold")
		BlockType.TREASURE:
			return pick_seeded_tile_coords(treasure_tiles, Vector2i(7, 1), cell_position, "treasure")
		BlockType.DIAMOND:
			return pick_seeded_tile_coords(diamond_tiles, Vector2i(2, 3), cell_position, "diamond")
		BlockType.WARPGEMS:
			return pick_seeded_tile_coords(warpgems_tiles, Vector2i(6, 2), cell_position, "warp_gems")
		BlockType.BLACKHOLECRYSTALS:
			return pick_seeded_tile_coords(blackholecrystal_tiles, Vector2i(0, 3), cell_position, "black_hole_crystals")
		BlockType.PLANETCORE:
			return pick_seeded_tile_coords(blackholecrystal_tiles, Vector2i(0, 3), cell_position, "planet_core")
		_:
			return pick_seeded_tile_coords(dirt_tiles, Vector2i(0, 0), cell_position, "fallback")


func get_dug_dirt_tile_coords(cell_position: Vector2i) -> Vector2i:
	return pick_seeded_tile_coords(dug_dirt_tiles, Vector2i(4, 3), cell_position, "background_dirt")


func pick_seeded_tile_coords(
	tile_options: Array[Vector2i],
	fallback: Vector2i,
	cell_position: Vector2i,
	tile_purpose: String
) -> Vector2i:
	if tile_options.is_empty():
		return fallback

	var variant_seed := SeedManager.derive_seed(
		SeedManager.starting_planet_seed,
		"%s:%d:%d" % [tile_purpose, cell_position.x, cell_position.y]
	)
	return tile_options[variant_seed % tile_options.size()]


func get_generated_planet_layout_signature(row_limit: int = -1) -> String:
	var signature: int = 5381
	var last_row := generated_row_count if row_limit < 0 else mini(row_limit, generated_row_count)
	for row in range(get_first_ground_row(), last_row):
		for column in grid_width:
			var cell := Vector2i(column, row)
			var block_type: int = int(block_types_by_cell.get(cell, BlockType.EMPTY))
			var foreground_coords := visual_mine_tiles.get_cell_atlas_coords(cell)
			var background_coords := background_tiles.get_cell_atlas_coords(cell)
			for value in [block_type, foreground_coords.x, foreground_coords.y, background_coords.x, background_coords.y]:
				signature = (signature * 33 + int(value) + 2) % 2147483647
	return str(signature)


func position_player_in_sky() -> void:
	var lander_column := get_lander_surface_column()
	var miner_column := clampi(
		lander_column + miner_spawn_offset_from_lander_tiles,
		0,
		grid_width - 1
	)
	var start_cell := Vector2i(miner_column, empty_top_rows - 2)
	player_marker.position = mine_tiles.map_to_local(start_cell)
	player_marker.scale = Vector2(player_sprite_scale, player_sprite_scale)
	player_marker.rotation = 0.0
	player_marker.region_enabled = true
	player_marker.region_rect = Rect2(0.0, 0.0, 64.0, 64.0)
	player_marker.z_index = PLAYER_Z_INDEX
	player_velocity = Vector2.ZERO


func create_surface_shop() -> void:
	var shop_texture := load(shop_lander_texture_path) as Texture2D
	var lander_column := get_lander_surface_column()
	var first_ground_cell := Vector2i(lander_column, get_first_ground_row())
	var first_ground_center := mine_tiles.map_to_local(first_ground_cell)
	var ground_top_y := first_ground_center.y - 32.0
	var lander_height := 192.0
	
	if shop_texture != null:
		lander_height = shop_texture.get_height() * shop_lander_scale
	
	var lander_ground_offset := (
		shop_lander_bottom_padding_pixels * shop_lander_scale
		+ shop_lander_ground_overlap_pixels
	)
	shop_center_position = Vector2(
		first_ground_center.x,
		ground_top_y - lander_height * 0.5 + lander_ground_offset
	)
	
	shop_button = Sprite2D.new()
	shop_button.name = "SurfaceShop"
	shop_button.z_index = 7
	shop_button.position = shop_center_position
	shop_button.texture = shop_texture
	shop_button.scale = Vector2(shop_lander_scale, shop_lander_scale)
	mine_tiles.add_child(shop_button)


func create_terrain_depth_darkening_overlay() -> void:
	terrain_depth_darkening_overlay = Node2D.new()
	terrain_depth_darkening_overlay.name = "TerrainDepthDarkeningOverlay"
	# Terrain tiles are at z-index -2/-1. Gameplay actors and infrastructure begin at 7.
	terrain_depth_darkening_overlay.z_index = 0
	terrain_depth_darkening_overlay.draw.connect(_on_terrain_depth_darkening_overlay_draw)
	add_child(terrain_depth_darkening_overlay)


func _on_terrain_depth_darkening_overlay_draw() -> void:
	if terrain_depth_darkening_overlay == null or not depth_darkening_enabled:
		return
	
	var tile_size := Vector2(64.0, 64.0)
	var row_width := tile_size.x * float(grid_width)
	for row in range(get_first_ground_row(), generated_row_count):
		var brightness := get_depth_brightness_for_row(row)
		var darkness_alpha := 1.0 - brightness
		if darkness_alpha <= 0.0:
			continue

		var first_tile_center := background_tiles.map_to_local(Vector2i(0, row))
		terrain_depth_darkening_overlay.draw_rect(
			Rect2(
				Vector2(first_tile_center.x - tile_size.x * 0.5, first_tile_center.y - tile_size.y * 0.5),
				Vector2(row_width, tile_size.y)
			),
			Color(0.0, 0.0, 0.0, darkness_alpha),
			true
		)


func get_depth_brightness_for_row(row: int) -> float:
	var depth_rows := maxi(row - get_first_ground_row(), 0)
	var raw_depth_ratio := clampf(
		float(depth_rows) / maxf(float(depth_distribution_full_row), 1.0),
		0.0,
		1.0
	)
	var gradient_start := minf(depth_gradient_start, depth_gradient_end)
	var gradient_end := maxf(depth_gradient_start, depth_gradient_end)
	var gradient_ratio := 0.0
	if gradient_end > gradient_start:
		gradient_ratio = inverse_lerp(gradient_start, gradient_end, raw_depth_ratio)
	elif raw_depth_ratio >= gradient_end:
		gradient_ratio = 1.0
	
	return clampf(
		lerpf(surface_brightness, deep_brightness, clampf(gradient_ratio, 0.0, 1.0)),
		0.0,
		1.0
	)


func sync_fuel_depot_with_upgrade_level() -> void:
	var should_have_fuel_depot := int(upgrade_levels.get("planetary_fuel_depot", 0)) > 0
	if should_have_fuel_depot:
		max_lander_rocket_fuel_tons += fuel_depot_rocket_fuel_capacity_bonus

	if should_have_fuel_depot == has_fuel_depot:
		return

	has_fuel_depot = should_have_fuel_depot
	if has_fuel_depot:
		create_fuel_depot_visuals()
		return

	if fuel_depot_sprite != null:
		fuel_depot_sprite.queue_free()
		fuel_depot_sprite = null
	if fuel_depot_pipe_sprite != null:
		fuel_depot_pipe_sprite.queue_free()
		fuel_depot_pipe_sprite = null


func create_fuel_depot_visuals() -> void:
	var lander_column := get_lander_surface_column()
	var depot_column: int = clampi(lander_column - 2, 0, grid_width - 1)
	var ground_cell := Vector2i(depot_column, get_first_ground_row())
	var ground_center := mine_tiles.map_to_local(ground_cell)
	var ground_top_y := ground_center.y - 32.0
	
	fuel_depot_sprite = Sprite2D.new()
	fuel_depot_sprite.name = "FuelDepot"
	fuel_depot_sprite.texture = FuelDepotTexture
	fuel_depot_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fuel_depot_sprite.z_index = TERRAIN_FOREGROUND_Z_INDEX
	var depot_scale: float = minf(64.0 / FuelDepotTexture.get_width(), 128.0 / FuelDepotTexture.get_height())
	fuel_depot_sprite.scale = Vector2(depot_scale, depot_scale)
	var depot_height: float = FuelDepotTexture.get_height() * depot_scale
	fuel_depot_sprite.position = Vector2(ground_center.x, ground_top_y - depot_height * 0.5 + 4.0)
	mine_tiles.add_child(fuel_depot_sprite)
	
	fuel_depot_pipe_sprite = Sprite2D.new()
	fuel_depot_pipe_sprite.name = "FuelDepotPipe"
	fuel_depot_pipe_sprite.texture = FuelPipeHorizontalTexture
	fuel_depot_pipe_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fuel_depot_pipe_sprite.z_index = TERRAIN_FOREGROUND_Z_INDEX
	var pipe_scale: float = minf(92.0 / FuelPipeHorizontalTexture.get_width(), 18.0 / FuelPipeHorizontalTexture.get_height())
	fuel_depot_pipe_sprite.scale = Vector2(pipe_scale, pipe_scale)
	fuel_depot_pipe_sprite.position = Vector2(
		(fuel_depot_sprite.position.x + shop_center_position.x) * 0.5,
		ground_top_y - 84.0
	)
	mine_tiles.add_child(fuel_depot_pipe_sprite)


func get_lander_surface_column() -> int:
	return clampi(floori(float(grid_width) / 2.0), 0, grid_width - 1)


func try_construct_lift_station(confirm_immediately: bool = false) -> bool:
	if not fabricator_unlocked:
		lift_status_message = "The Lander Fabricator must be delivered before lift construction."
		update_hud()
		return false
	if core_vault_system != null and core_vault_system.boss_active:
		lift_status_message = "Lift construction is disabled during the Core Vault lockdown."
		update_hud()
		return false
	var station_cell := get_player_cell()
	if station_cell.y <= get_first_ground_row() or station_cell.x <= 0 or station_cell.x >= grid_width - 1:
		lift_status_message = "Move underground to a three-block-wide solid foundation."
		update_hud()
		return false
	if get_lift_station_at_cell(station_cell) >= 0:
		lift_status_message = "A lift station already occupies this platform."
		update_hud()
		return false
	for x_offset in range(-1, 2):
		var foundation_cell := station_cell + Vector2i(x_offset, 1)
		if not block_types_by_cell.has(foundation_cell) or is_core_vault_seal_locked(foundation_cell):
			lift_status_message = "Lift stations require three contiguous solid foundation blocks."
			update_hud()
			return false
	var anchor_cell := get_highest_reachable_lift_anchor(station_cell)
	if anchor_cell == Vector2i(-1, -1):
		var obstruction := get_first_lift_shaft_obstruction(station_cell, get_first_ground_row() - 1)
		lift_status_message = (
			"Vertical shaft interrupted at block (%d, %d). Clear a one-block-wide route to the surface."
			% [obstruction.x, obstruction.y]
		)
		update_hud()
		return false
	var height_blocks := station_cell.y - anchor_cell.y
	var costs := StartingPlanetBalance.get_lift_cost(height_blocks)
	if not can_afford_resource_dictionary(costs):
		lift_status_message = "Lift requires %d Iron, %d Copper, and %d Basic Circuit." % [
			int(costs["Iron"]), int(costs["Copper"]), int(costs["Basic Circuit"]),
		]
		update_hud()
		return false
	if not confirm_immediately:
		var confirmation := ConfirmationDialog.new()
		confirmation.title = "Construct Lift Station"
		confirmation.dialog_text = (
			"Destination depth: %dm\nShaft height: %d blocks\nCost: %d Iron + %d Copper + %d Basic Circuit\n\n"
			+ "The one-block shaft is clear and the three-block foundation is valid."
		) % [
			maxi(station_cell.y - get_first_ground_row(), 0) * depth_meters_per_row,
			height_blocks,
			int(costs["Iron"]),
			int(costs["Copper"]),
			int(costs["Basic Circuit"]),
		]
		confirmation.get_ok_button().text = "Construct"
		confirmation.confirmed.connect(
			complete_lift_construction.bind(station_cell, anchor_cell, costs.duplicate(true))
		)
		add_child(confirmation)
		confirmation.popup_centered(Vector2i(620, 360))
		lift_status_message = "Lift plan ready—confirm construction to spend materials."
		update_hud()
		return true
	return complete_lift_construction(station_cell, anchor_cell, costs)


func complete_lift_construction(station_cell: Vector2i, anchor_cell: Vector2i, costs: Dictionary) -> bool:
	var foundation_valid := true
	for x_offset in range(-1, 2):
		foundation_valid = foundation_valid and block_types_by_cell.has(station_cell + Vector2i(x_offset, 1))
	if not foundation_valid or get_lift_station_at_cell(station_cell) >= 0 or not is_lift_shaft_clear(station_cell, anchor_cell):
		lift_status_message = "Lift construction cancelled because the route changed."
		update_hud()
		return false
	if not can_afford_resource_dictionary(costs):
		lift_status_message = "Lift construction cancelled because materials are no longer available."
		update_hud()
		return false
	pay_resource_dictionary(costs)
	var height_blocks := station_cell.y - anchor_cell.y
	lift_stations.append({
		"station": [station_cell.x, station_cell.y],
		"anchor": [anchor_cell.x, anchor_cell.y],
		"height_blocks": height_blocks,
	})
	rebuild_lift_station_visuals()
	record_progression_milestone("time_to_first_lift_activation")
	lift_status_message = "Lift connected %d blocks to the highest reachable platform." % height_blocks
	update_hud()
	return true


func get_highest_reachable_lift_anchor(station_cell: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = [Vector2i(station_cell.x, get_first_ground_row() - 1)]
	for station_data in lift_stations:
		var other_station := array_to_cell(station_data.get("station", []))
		if other_station.x == station_cell.x and other_station.y < station_cell.y:
			candidates.append(other_station)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y)
	for candidate in candidates:
		if is_lift_shaft_clear(station_cell, candidate):
			return candidate
	return Vector2i(-1, -1)


func is_lift_shaft_clear(station_cell: Vector2i, anchor_cell: Vector2i) -> bool:
	if station_cell.x != anchor_cell.x or anchor_cell.y >= station_cell.y:
		return false
	for y in range(anchor_cell.y + 1, station_cell.y):
		var shaft_cell := Vector2i(station_cell.x, y)
		if block_types_by_cell.has(shaft_cell) or is_core_vault_seal_locked(shaft_cell):
			return false
	return true


func get_first_lift_shaft_obstruction(station_cell: Vector2i, anchor_y: int) -> Vector2i:
	for y in range(station_cell.y - 1, anchor_y, -1):
		var shaft_cell := Vector2i(station_cell.x, y)
		if block_types_by_cell.has(shaft_cell) or is_core_vault_seal_locked(shaft_cell):
			return shaft_cell
	return Vector2i(station_cell.x, anchor_y)


func get_lift_station_at_cell(cell: Vector2i, tolerance: int = 0) -> int:
	for index in lift_stations.size():
		var station_cell := array_to_cell(lift_stations[index].get("station", []))
		if maxi(absi(cell.x - station_cell.x), absi(cell.y - station_cell.y)) <= tolerance:
			return index
	return -1


func try_use_nearby_lift() -> bool:
	if core_vault_system != null and core_vault_system.boss_active:
		lift_status_message = "Core Vault lockdown prevents lift travel."
		update_hud()
		return false
	var player_cell := get_player_cell()
	var station_index := get_lift_station_at_cell(player_cell, 1)
	if station_index >= 0:
		var anchor := array_to_cell(lift_stations[station_index].get("anchor", []))
		move_player_to_lift_cell(anchor)
		lift_status_message = "Lift returned to the upper platform."
		return true
	var destination_index := -1
	var deepest_y := -1
	for index in lift_stations.size():
		var anchor := array_to_cell(lift_stations[index].get("anchor", []))
		if maxi(absi(player_cell.x - anchor.x), absi(player_cell.y - anchor.y)) > 1:
			continue
		var station := array_to_cell(lift_stations[index].get("station", []))
		if station.y > deepest_y:
			deepest_y = station.y
			destination_index = index
	if destination_index < 0:
		return false
	move_player_to_lift_cell(array_to_cell(lift_stations[destination_index].get("station", [])))
	lift_status_message = "Lift descended to the deepest connected platform."
	return true


func move_player_to_lift_cell(cell: Vector2i) -> void:
	player_marker.position = mine_tiles.map_to_local(cell)
	player_velocity = Vector2.ZERO
	reset_mining_progress()
	update_revealed_cells()
	update_camera()
	update_hud()


func array_to_cell(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i(-1, -1)


func can_afford_resource_dictionary(costs: Dictionary) -> bool:
	for resource_name in costs:
		if get_total_resource_count(str(resource_name)) < int(costs[resource_name]):
			return false
	return true


func pay_resource_dictionary(costs: Dictionary) -> void:
	for resource_name in costs:
		consume_resource(str(resource_name), int(costs[resource_name]))


func rebuild_lift_station_visuals() -> void:
	for visual in lift_station_visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	lift_station_visuals.clear()
	for station_data in lift_stations:
		var station_cell := array_to_cell(station_data.get("station", []))
		var anchor_cell := array_to_cell(station_data.get("anchor", []))
		if station_cell == Vector2i(-1, -1) or anchor_cell == Vector2i(-1, -1):
			continue
		var visual := Node2D.new()
		visual.name = "LiftStation_%d_%d" % [station_cell.x, station_cell.y]
		visual.z_index = TERRAIN_FOREGROUND_Z_INDEX
		visual.draw.connect(draw_lift_station.bind(visual, station_cell, anchor_cell))
		mine_tiles.add_child(visual)
		lift_station_visuals.append(visual)


func draw_lift_station(visual: Node2D, station_cell: Vector2i, anchor_cell: Vector2i) -> void:
	var station_position := mine_tiles.map_to_local(station_cell)
	var anchor_position := mine_tiles.map_to_local(anchor_cell)
	visual.draw_line(anchor_position, station_position, Color(0.58, 0.7, 0.76, 0.8), 5.0)
	visual.draw_rect(Rect2(station_position - Vector2(92.0, 20.0), Vector2(184.0, 40.0)), Color(0.16, 0.28, 0.34, 0.96), true)
	visual.draw_rect(Rect2(station_position - Vector2(92.0, 20.0), Vector2(184.0, 40.0)), Color(0.65, 0.86, 0.92, 1.0), false, 3.0)
	visual.draw_circle(anchor_position, 11.0, Color(0.93, 0.62, 0.18, 1.0))


func place_gps_marker() -> bool:
	if is_paused or is_shop_open or is_game_over:
		return false
	var marker_count := int(resources.get("GPS Marker", 0))
	if marker_count <= 0:
		drill_access_message = "No GPS Markers loaded. Fabricate and load a marker pack at the lander."
		drill_access_message_remaining = 3.0
		update_hud()
		return false
	var marker_cell := get_player_cell()
	if gps_marker_cells.has(marker_cell):
		drill_access_message = "This shaft is already marked."
		drill_access_message_remaining = 2.0
		update_hud()
		return false
	resources["GPS Marker"] = marker_count - 1
	gps_marker_cells.append(marker_cell)
	create_gps_marker_visual(marker_cell)
	drill_access_message = "GPS shaft marker placed — follow the yellow DOWN beacon."
	drill_access_message_remaining = 3.0
	if planet_map_overlay != null:
		planet_map_overlay.queue_redraw()
	update_hud()
	return true


func load_gps_markers_into_miner(requested_amount: int = -1) -> void:
	var cargo_count := int(cargo_hold_resources.get("GPS Marker", 0))
	var requested := cargo_count if requested_amount < 0 else mini(cargo_count, maxi(requested_amount, 0))
	var amount_to_load := mini(requested, get_inventory_room())
	if amount_to_load <= 0:
		refresh_lander_view_or_shop_ui()
		return
	cargo_hold_resources["GPS Marker"] = cargo_count - amount_to_load
	resources["GPS Marker"] = int(resources.get("GPS Marker", 0)) + amount_to_load
	refresh_lander_view_or_shop_ui()
	update_hud()


func rebuild_gps_marker_visuals() -> void:
	for visual in gps_marker_visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	gps_marker_visuals.clear()
	for marker_cell in gps_marker_cells:
		create_gps_marker_visual(marker_cell)


func create_gps_marker_visual(marker_cell: Vector2i) -> void:
	var visual := Node2D.new()
	visual.name = "GPSMarker_%d_%d" % [marker_cell.x, marker_cell.y]
	visual.z_index = PLAYER_Z_INDEX + 2
	visual.draw.connect(draw_gps_marker.bind(visual, marker_cell))
	mine_tiles.add_child(visual)
	gps_marker_visuals.append(visual)


func draw_gps_marker(visual: Node2D, marker_cell: Vector2i) -> void:
	var position := mine_tiles.map_to_local(marker_cell)
	var yellow := Color(1.0, 0.82, 0.08, 1.0)
	visual.draw_line(position + Vector2(0.0, -42.0), position + Vector2(0.0, 28.0), yellow, 5.0)
	visual.draw_circle(position + Vector2(0.0, -47.0), 12.0, yellow)
	visual.draw_polyline(PackedVector2Array([
		position + Vector2(-16.0, 8.0),
		position + Vector2(0.0, 26.0),
		position + Vector2(16.0, 8.0),
	]), yellow, 6.0)
	visual.draw_string(ThemeDB.fallback_font, position + Vector2(22.0, -34.0), "DOWN", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 17, Color.WHITE)


func check_shop_collision() -> void:
	if is_shop_open or is_game_over:
		return
	
	var player_rect := get_player_rect(player_marker.position)
	var shop_rect := get_shop_rect()
	var is_touching_shop := player_rect.intersects(shop_rect)
	
	if is_shop_reentry_locked:
		if not is_touching_shop:
			is_shop_reentry_locked = false
		return
	
	if is_touching_shop:
		open_shop()


func get_shop_rect() -> Rect2:
	return Rect2(shop_center_position - shop_size * 0.5, shop_size)


func get_first_ground_row() -> int:
	return empty_top_rows


func get_player_rect(test_position: Vector2) -> Rect2:
	return Rect2(
		test_position - Vector2(player_collision_width, player_collision_height) * 0.5,
		Vector2(player_collision_width, player_collision_height)
	)


func drain_fuel_for_movement(delta: float) -> void:
	var fuel_drain_rate := get_fuel_drain_rate(
		is_actively_drilling_mineable_block(),
		is_movement_input_pressed()
	)
	
	fuel_seconds = maxf(fuel_seconds - delta * fuel_drain_rate, 0.0)
	update_hud()
	
	if fuel_seconds <= 0.0:
		trigger_death()


func get_fuel_drain_rate(is_drilling: bool, has_movement_input: bool) -> float:
	if is_drilling:
		return fuel_consumption_multiplier * mining_fuel_cost_multiplier
	if has_movement_input:
		return fuel_consumption_multiplier * driving_fuel_cost_multiplier
	return fuel_consumption_multiplier / maxf(idle_fuel_seconds_per_kg, 0.01)


func is_actively_drilling_mineable_block() -> bool:
	if not can_use_mining_drill():
		return false
	if get_held_mine_direction() == Vector2i.ZERO:
		return false
	var target_cell := get_target_mine_cell()
	if not block_types_by_cell.has(target_cell):
		return false
	return block_types_by_cell.get(target_cell, BlockType.ROCK) != BlockType.LODESTONE


func is_movement_input_pressed() -> bool:
	return (
		Input.is_key_pressed(KEY_A)
		or Input.is_key_pressed(KEY_D)
		or Input.is_key_pressed(KEY_W)
		or Input.is_key_pressed(KEY_SPACE)
		or Input.is_key_pressed(KEY_S)
		or Input.is_key_pressed(KEY_LEFT)
		or Input.is_key_pressed(KEY_RIGHT)
		or Input.is_key_pressed(KEY_UP)
		or Input.is_key_pressed(KEY_DOWN)
	)


func create_mining_camera() -> void:
	mining_camera = Camera2D.new()
	mining_camera.name = "MiningCamera"
	mining_camera.position_smoothing_enabled = false
	add_child(mining_camera)
	mining_camera.make_current()


func update_camera() -> void:
	if mining_camera == null:
		return
	
	var camera_offset := Vector2.ZERO
	if mining_effects != null and mining_effects.has_method("get_camera_offset"):
		camera_offset = mining_effects.get_camera_offset()
	
	mining_camera.global_position = (player_marker.global_position + camera_offset).round()
	starfield.global_position = (mining_camera.global_position - get_viewport_rect().size * 0.5).round()


func create_mining_effects() -> void:
	mining_effects = MiningEffectsScript.new()
	mining_effects.name = "MiningEffects"
	mining_effects.z_index = PLAYER_Z_INDEX - 1
	mine_tiles.add_child(mining_effects)


func create_ground_encounter_system() -> void:
	ground_encounter_system = GroundEncounterSystemScript.new()
	mine_tiles.add_child(ground_encounter_system)
	ground_encounter_system.setup(self)
	ground_encounter_system.sync_encounters(planned_ground_encounters)


func create_miner_laser_system() -> void:
	miner_laser_system = MinerLaserSystemScript.new()
	mine_tiles.add_child(miner_laser_system)
	miner_laser_system.setup(self)


func create_developer_cave_direction_arrow() -> void:
	developer_cave_direction_arrow = DeveloperCaveDirectionArrowScript.new()
	mine_tiles.add_child(developer_cave_direction_arrow)
	developer_cave_direction_arrow.setup(self)


func create_core_vault_system() -> void:
	core_vault_system = CoreVaultSystemScript.new()
	mine_tiles.add_child(core_vault_system)
	core_vault_system.setup(self)


func close_core_vault_ceiling() -> void:
	locked_core_vault_seal_cells.clear()
	var row := get_core_vault_top_row()
	for column in range(get_core_vault_left_column(), get_core_vault_right_column() + 1):
		var seal_cell := Vector2i(column, row)
		locked_core_vault_seal_cells[seal_cell] = true
		block_types_by_cell[seal_cell] = BlockType.ROCK
		visual_mine_tiles.set_cell(
			seal_cell,
			tile_source_id,
			get_tile_coords_for_block_type(BlockType.ROCK, seal_cell)
		)
	if core_vault_system != null and core_vault_system.seal_visual != null:
		core_vault_system.seal_visual.active = true
		core_vault_system.seal_visual.queue_redraw()


func open_core_vault_ceiling() -> void:
	for cell_value in locked_core_vault_seal_cells.keys():
		var seal_cell: Vector2i = cell_value
		block_types_by_cell.erase(seal_cell)
		visual_mine_tiles.erase_cell(seal_cell)
	locked_core_vault_seal_cells.clear()
	if core_vault_system != null and core_vault_system.seal_visual != null:
		core_vault_system.seal_visual.active = false
		core_vault_system.seal_visual.queue_redraw()


func is_core_vault_seal_locked(cell: Vector2i) -> bool:
	if locked_core_vault_seal_cells.has(cell):
		return true
	if core_vault_system == null or not core_vault_system.boss_active:
		return false
	var top := get_core_vault_top_row()
	var bottom := top + core_vault_height_blocks
	var left_boundary := get_core_vault_left_column() - 1
	var right_boundary := get_core_vault_right_column() + 1
	return (
		(cell.y >= top and cell.y <= bottom and cell.x in [left_boundary, right_boundary])
		or (cell.y == bottom and cell.x >= left_boundary and cell.x <= right_boundary)
	)


func complete_core_vault_boss_encounter() -> void:
	update_hud()


func set_developer_cave_arrow_enabled(enabled: bool) -> void:
	if developer_cave_direction_arrow != null:
		developer_cave_direction_arrow.set_arrow_enabled(enabled)
		developer_cave_direction_arrow.update_arrow()


func is_developer_cave_arrow_enabled() -> bool:
	return (
		developer_cave_direction_arrow != null
		and developer_cave_direction_arrow.arrow_enabled
	)


func update_capacitor_and_shield(delta: float) -> void:
	var recharge_blocked_time := minf(delta, shield_recharge_delay_remaining)
	if recharge_blocked_time > 0.0:
		process_shield_energy_interval(recharge_blocked_time, false)
		shield_recharge_delay_remaining = maxf(
			shield_recharge_delay_remaining - recharge_blocked_time,
			0.0
		)
	var recharge_allowed_time := maxf(delta - recharge_blocked_time, 0.0)
	if recharge_allowed_time > 0.0:
		process_shield_energy_interval(recharge_allowed_time, true)
	heat_ratio = maxf(heat_ratio - heat_cooling_per_second * delta, 0.0)


func process_shield_energy_interval(duration: float, allow_shield_recharge: bool) -> void:
	var generated_energy := maxf(engine_charge_per_second, 0.0) * duration
	var life_support_required := maxf(life_support_power_per_second, 0.0) * duration
	var upkeep_required := maxf(shield_energy_per_second, 0.0) * duration if max_shield_health > 0.0 else 0.0
	var essential_required := life_support_required + upkeep_required
	var essential_from_generation := minf(generated_energy, essential_required)
	var essential_shortfall := essential_required - essential_from_generation
	var essential_from_capacitor := minf(capacitor_energy, essential_shortfall)
	capacitor_energy -= essential_from_capacitor
	var essential_supplied := essential_from_generation + essential_from_capacitor
	var life_support_used := minf(essential_supplied, life_support_required)
	var upkeep_used := minf(maxf(essential_supplied - life_support_required, 0.0), upkeep_required)
	shield_powered = max_shield_health > 0.0 and upkeep_used + 0.0001 >= upkeep_required
	var generated_surplus := generated_energy - essential_from_generation

	var mobility_requested := (
		maxf(mobility_power_consumption_per_second, 0.0) * duration
		if is_movement_input_pressed()
		else 0.0
	)
	# Mobility is the lowest-priority load and never borrows from stored capacitor energy.
	var mobility_used := minf(generated_surplus, mobility_requested)
	generated_surplus -= mobility_used
	current_mobility_power_ratio = (
		clampf(mobility_used / mobility_requested, 0.0, 1.0)
		if mobility_requested > 0.0001
		else 1.0
	)
	var recharge_energy := 0.0
	if allow_shield_recharge and shield_health < max_shield_health and shield_hp_per_energy > 0.0:
		var missing_shield := max_shield_health - shield_health
		var recharge_energy_limit := maxf(shield_recharge_hp_per_second, 0.0) * duration / shield_hp_per_energy
		recharge_energy = minf(
			generated_surplus,
			minf(missing_shield / shield_hp_per_energy, recharge_energy_limit)
		)
		shield_health = minf(shield_health + recharge_energy * shield_hp_per_energy, max_shield_health)
		generated_surplus -= recharge_energy
	capacitor_energy = minf(capacitor_energy + generated_surplus, capacitor_capacity)
	last_power_generation = generated_energy / maxf(duration, 0.0001)
	last_power_consumption = (life_support_used + upkeep_used + mobility_used + recharge_energy) / maxf(duration, 0.0001)


func update_laser_turret(delta: float) -> void:
	laser_fire_cooldown_remaining = maxf(laser_fire_cooldown_remaining - delta, 0.0)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	if is_shop_open or is_paused or is_game_over or laser_fire_cooldown_remaining > 0.0:
		return
	var hovered_control := get_viewport().gui_get_hovered_control()
	if hovered_control is Button:
		return
	try_fire_laser_at(get_global_mouse_position())


func try_fire_laser_at(target_position: Vector2) -> bool:
	if miner_laser_system == null or capacitor_energy + 0.0001 < laser_energy_per_shot:
		return false
	var muzzle_position := player_marker.position + Vector2(0.0, -laser_muzzle_vertical_offset)
	var shot_damage := laser_damage
	if randf() < clampf(weapon_critical_chance, 0.0, 1.0):
		shot_damage *= 2.0
	if not miner_laser_system.fire(muzzle_position, target_position, shot_damage):
		return false
	capacitor_energy = maxf(capacitor_energy - laser_energy_per_shot, 0.0)
	laser_fire_cooldown_remaining = 1.0 / maxf(laser_shots_per_second, 0.01)
	shield_recharge_delay_remaining = shield_recharge_delay_seconds
	heat_ratio = minf(heat_ratio + laser_heat_per_shot, 1.0)
	update_gauge_cluster()
	return true


func collect_ground_altar_loot() -> bool:
	if get_inventory_room() <= 0:
		return false
	resources["Treasure"] = int(resources.get("Treasure", 0)) + 1
	play_blast_ore_text("Treasure", 1, BlockType.TREASURE)
	update_hud()
	return true


func apply_ground_enemy_damage(damage: int) -> void:
	apply_miner_damage(damage)


func apply_miner_damage(damage: int, bypass_shield: bool = false) -> void:
	if damage <= 0 or is_game_over:
		return
	var hull_damage := float(damage)
	if not bypass_shield and shield_powered and shield_health > 0.0:
		var absorbed := minf(shield_health, hull_damage)
		shield_health -= absorbed
		hull_damage -= absorbed
	if hull_damage > 0.0:
		var armored_damage := DamageRules.calculate_armored_damage(hull_damage, armor_rating)
		hull_health = maxi(hull_health - armored_damage, 0)
	if mining_effects != null:
		mining_effects.add_screen_shake(clampf(float(damage), 2.0, 8.0), 0.18)
	update_hud()
	if hull_health <= 0:
		trigger_death()


func apply_falling_boulder_damage(damage: int) -> void:
	apply_miner_damage(damage, true)


func create_fog_overlay() -> void:
	fog_overlay = FogOverlayScript.new()
	fog_overlay.name = "FogOverlay"
	fog_overlay.z_index = 6
	fog_overlay.mining_scene = self
	mine_tiles.add_child(fog_overlay)


func create_sensor_twinkle_overlay() -> void:
	sensor_twinkle_overlay = SensorTwinkleOverlayScript.new()
	sensor_twinkle_overlay.name = "SensorTwinkleOverlay"
	sensor_twinkle_overlay.z_index = 7
	sensor_twinkle_overlay.mining_scene = self
	mine_tiles.add_child(sensor_twinkle_overlay)


func ensure_world_generated_near_player() -> void:
	var player_cell := get_player_cell()
	var needed_rows: int = player_cell.y + generation_buffer_rows
	
	if needed_rows > generated_row_count:
		generate_rows_until(needed_rows)


func get_player_cell() -> Vector2i:
	return mine_tiles.local_to_map(player_marker.position)


func update_revealed_cells() -> void:
	var player_cell := get_player_cell()
	reveal_surface_ground_cells()
	
	for y in range(player_cell.y - reveal_radius_tiles, player_cell.y + reveal_radius_tiles + 1):
		for x in range(player_cell.x - reveal_radius_tiles, player_cell.x + reveal_radius_tiles + 1):
			var cell := Vector2i(x, y)
			
			if cell.x < 0 or cell.x >= grid_width:
				continue
			
			if cell.y < 0:
				continue
			
			revealed_cells[cell] = true
	
	if fog_overlay != null:
		fog_overlay.queue_redraw()
	if sensor_twinkle_overlay != null:
		sensor_twinkle_overlay.queue_redraw()


func reveal_surface_ground_cells() -> void:
	var first_ground_row := get_first_ground_row()
	var last_surface_row := first_ground_row + maxi(surface_revealed_ground_rows, 1) - 1
	
	for y in range(first_ground_row, last_surface_row + 1):
		for x in range(grid_width):
			revealed_cells[Vector2i(x, y)] = true


func is_cell_revealed(cell: Vector2i) -> bool:
	return revealed_cells.has(cell)


func get_sensor_level() -> int:
	return clampi(
		int(upgrade_levels.get("miner_sensor_strength", 0)),
		0,
		StartingPlanetBalance.MK1_MAX_LEVEL
	)


func get_sensor_detection_extension() -> int:
	return StartingPlanetBalance.get_detection_extension(get_sensor_level())


func get_detectable_hidden_ore_cells() -> Array[Vector2i]:
	var detected: Array[Vector2i] = get_guided_starter_ore_cells()
	var detection_extension := get_sensor_detection_extension()
	if detection_extension <= 0:
		return detected
	var player_cell := get_player_cell()
	var visible_radius := StartingPlanetBalance.get_visible_radius(get_sensor_level())
	var maximum_radius := visible_radius + detection_extension
	for y in range(player_cell.y - maximum_radius, player_cell.y + maximum_radius + 1):
		for x in range(player_cell.x - maximum_radius, player_cell.x + maximum_radius + 1):
			var cell := Vector2i(x, y)
			var distance := maxi(absi(cell.x - player_cell.x), absi(cell.y - player_cell.y))
			if distance <= visible_radius or distance > maximum_radius:
				continue
			if is_cell_revealed(cell) or not block_types_by_cell.has(cell):
				continue
			if is_ore_block_type(block_types_by_cell[cell]) and not detected.has(cell):
				detected.append(cell)
	return detected


func get_guided_starter_ore_cells() -> Array[Vector2i]:
	var guided_cells: Array[Vector2i] = []
	if SeedManager.current_system_id != SeedManager.STARTING_SYSTEM_ID:
		return guided_cells
	var expected_types := {
		"copper": BlockType.COPPER,
		"raw_fuel": BlockType.RAWFUEL,
		"iron": BlockType.IRON,
	}
	var lander_column := get_lander_surface_column()
	var ground_row := get_first_ground_row()
	for resource_id in ["copper", "raw_fuel", "iron"]:
		for relative_cell: Vector2i in StartingPlanetBalance.GUIDED_STARTER_DEPOSITS[resource_id]:
			var cell := Vector2i(lander_column + relative_cell.x, ground_row + relative_cell.y)
			if block_types_by_cell.get(cell, BlockType.EMPTY) == expected_types[resource_id]:
				guided_cells.append(cell)
	return guided_cells


func is_ore_block_type(block_type: BlockType) -> bool:
	return block_type in [
		BlockType.COPPER,
		BlockType.RAWFUEL,
		BlockType.IRON,
		BlockType.GOLD,
		BlockType.TREASURE,
		BlockType.DIAMOND,
		BlockType.WARPGEMS,
		BlockType.BLACKHOLECRYSTALS,
	]


func apply_developer_test_configuration(configuration: Dictionary) -> void:
	for upgrade_id in configuration.get("upgrade_levels", {}):
		upgrade_levels[upgrade_id] = int(configuration["upgrade_levels"][upgrade_id])
	recalculate_stats_from_upgrade_levels()

	credits = maxi(int(configuration.get("credits", credits)), 0)
	var requested_resource_counts: Dictionary = configuration.get("resource_counts", {})
	if configuration.has("raw_fuel") and not requested_resource_counts.has("Raw Fuel"):
		requested_resource_counts["Raw Fuel"] = configuration["raw_fuel"]
	for resource_name in requested_resource_counts:
		resources[resource_name] = maxi(int(requested_resource_counts[resource_name]), 0)
		cargo_hold_resources[resource_name] = 0
	lander_rocket_fuel_tons = clampi(
		int(configuration.get("rocket_fuel", lander_rocket_fuel_tons)),
		0,
		max_lander_rocket_fuel_tons
	)
	fuel_seconds = clampf(
		float(configuration.get("active_fuel", fuel_seconds)),
		0.0,
		max_fuel_seconds
	)
	teleport_player_to_test_depth(int(configuration.get("depth_meters", 0)))
	SeedManager.update_starting_escape_fuel(
		lander_rocket_fuel_tons,
		return_to_starship_required_rocket_fuel_tons
	)
	update_shop_ui()
	update_hud()


func get_developer_test_resource_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	var resource_names := get_sellable_resource_names()
	for fabricated_name in [
		"Copper Bar", "Iron Bar", "Gold Bar", "Copper Wire", "Iron Wire",
		"Silicone Wafer", "Basic Circuit", "Explosive Charge", "GPS Marker",
	]:
		if not resource_names.has(fabricated_name):
			resource_names.append(fabricated_name)
	for resource_name in resource_names:
		definitions.append({
			"id": resource_name,
			"label": resource_name,
			"minimum": 0,
			"maximum": 10000,
			"step": 1,
		})
	return definitions


func get_developer_test_presets() -> Array[Dictionary]:
	return [
		{"label": "Surface / Level 0", "depth_meters": 0, "default_upgrade_level": 0},
		{"label": "3000m / Level 0", "depth_meters": 3000, "default_upgrade_level": 0},
		{"label": "3000m / Drill 1", "depth_meters": 3000, "default_upgrade_level": 0, "upgrade_levels": {"miner_drill_efficiency": 1}},
		{"label": "3000m / Drill 3", "depth_meters": 3000, "default_upgrade_level": 0, "upgrade_levels": {"miner_drill_efficiency": 3}},
		{"label": "3000m / Drill 5", "depth_meters": 3000, "default_upgrade_level": 0, "upgrade_levels": {"miner_drill_efficiency": 5}},
	]


func get_nearest_ground_cave_to_cell(origin_cell: Vector2i) -> Dictionary:
	var nearest_encounter: Dictionary = {}
	var nearest_distance_squared := INF
	for encounter in planned_ground_encounters:
		var center_data: Array = encounter.get("cave_center_cell", [])
		if center_data.size() < 2:
			continue
		var center := Vector2i(int(center_data[0]), int(center_data[1]))
		var distance_squared := Vector2(origin_cell - center).length_squared()
		if distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_encounter = encounter
	return nearest_encounter


func ensure_developer_cave_available() -> void:
	if not planned_ground_encounters.is_empty():
		return
	var first_cave_row := (
		get_first_ground_row()
		+ roundi(float(ground_cave_interval_meters) / maxf(float(depth_meters_per_row), 1.0))
	)
	var tolerance_rows := roundi(
		float(ground_cave_depth_tolerance_meters) / maxf(float(depth_meters_per_row), 1.0)
	)
	generate_rows_until(
		first_cave_row
		+ tolerance_rows
		+ ground_cave_radius_blocks
		+ 5
		+ generation_buffer_rows
	)


func teleport_player_near_nearest_cave() -> Dictionary:
	ensure_developer_cave_available()
	var encounter := get_nearest_ground_cave_to_cell(get_player_cell())
	if encounter.is_empty():
		return {}
	var center_data: Array = encounter.get("cave_center_cell", [])
	var wall_cell_data: Array = encounter.get("wall_cells", [])
	if center_data.size() < 2 or wall_cell_data.is_empty():
		return {}
	var center := Vector2i(int(center_data[0]), int(center_data[1]))
	var toward_miner := Vector2(get_player_cell() - center)
	var preferred_direction := get_nearest_cardinal_direction(toward_miner, Vector2i.UP)
	var directions: Array[Vector2i] = [
		preferred_direction,
		Vector2i.UP,
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.DOWN,
	]
	var unique_directions: Array[Vector2i] = []
	for direction in directions:
		if not unique_directions.has(direction):
			unique_directions.append(direction)

	var selected_boundary := center
	var selected_arrival := center
	var selected_direction := Vector2i.ZERO
	for direction in unique_directions:
		var boundary := center
		var farthest_projection := -INF
		for cell_data in wall_cell_data:
			if not cell_data is Array or cell_data.size() < 2:
				continue
			var wall_cell := Vector2i(int(cell_data[0]), int(cell_data[1]))
			var projection := Vector2(wall_cell - center).dot(Vector2(direction))
			if projection > farthest_projection:
				farthest_projection = projection
				boundary = wall_cell
		var arrival := boundary + direction * maxi(developer_cave_teleport_distance_blocks, 1)
		if arrival.x < 1 or arrival.x >= grid_width - 1 or arrival.y < get_first_ground_row() + 1:
			continue
		selected_boundary = boundary
		selected_arrival = arrival
		selected_direction = direction
		break
	if selected_direction == Vector2i.ZERO:
		return {}

	generate_rows_until(selected_arrival.y + generation_buffer_rows)
	for row in range(selected_arrival.y - 1, selected_arrival.y + 1):
		for column in range(selected_arrival.x - 1, selected_arrival.x + 2):
			var pocket_cell := Vector2i(column, row)
			block_types_by_cell.erase(pocket_cell)
			visual_mine_tiles.erase_cell(pocket_cell)
	player_marker.position = mine_tiles.map_to_local(selected_arrival)
	player_velocity = Vector2.ZERO
	is_on_ground = false
	reset_mining_progress()
	reveal_developer_test_area(selected_arrival, 1)
	update_camera()
	set_developer_cave_arrow_enabled(true)
	return {
		"encounter_id": str(encounter.get("encounter_id", "")),
		"cave_center_cell": center,
		"wall_boundary_cell": selected_boundary,
		"arrival_cell": selected_arrival,
		"approach_direction": selected_direction,
	}


func teleport_player_to_test_depth(depth_meters: int) -> void:
	var safe_depth_meters := maxi(depth_meters, 0)
	if safe_depth_meters == 0:
		position_player_in_sky()
		update_revealed_cells()
		update_camera()
		return

	var target_row := get_first_ground_row() + roundi(
		float(safe_depth_meters) / maxf(float(depth_meters_per_row), 1.0)
	)
	generate_rows_until(target_row + generation_buffer_rows)
	var target_column := get_developer_arrival_column(target_row)

	# Carve only a 3x2 arrival pocket; the surrounding seeded resource field stays intact.
	for row in range(target_row - 1, target_row + 1):
		for column in range(target_column - 1, target_column + 2):
			var chamber_cell := Vector2i(column, row)
			block_types_by_cell.erase(chamber_cell)
			visual_mine_tiles.erase_cell(chamber_cell)

	var target_cell := Vector2i(target_column, target_row)
	player_marker.position = mine_tiles.map_to_local(target_cell)
	player_velocity = Vector2.ZERO
	is_on_ground = false
	reset_mining_progress()
	reveal_developer_test_area(target_cell, 6)
	update_camera()


func get_developer_arrival_column(target_row: int) -> int:
	var center_column := clampi(floori(float(grid_width) * 0.5), 1, grid_width - 2)
	for distance in range(grid_width):
		var candidates := [center_column + distance, center_column - distance]
		for candidate_value in candidates:
			var candidate := int(candidate_value)
			if candidate < 1 or candidate >= grid_width - 1:
				continue
			var preserves_cave := true
			for row in range(target_row - 1, target_row + 1):
				for column in range(candidate - 1, candidate + 2):
					var chamber_cell := Vector2i(column, row)
					if (
						planned_ground_cave_rock_cells.has(chamber_cell)
						or planned_void_cells.has(chamber_cell)
					):
						preserves_cave = false
						break
				if not preserves_cave:
					break
			if preserves_cave:
				return candidate
	return center_column


func reveal_developer_test_area(center_cell: Vector2i, radius: int) -> void:
	for row in range(center_cell.y - radius, center_cell.y + radius + 1):
		for column in range(center_cell.x - radius, center_cell.x + radius + 1):
			if column >= 0 and column < grid_width and row >= 0:
				revealed_cells[Vector2i(column, row)] = true
	if fog_overlay != null:
		fog_overlay.queue_redraw()


func handle_player_movement(delta: float) -> void:
	var horizontal_input := get_horizontal_input()
	var mobility_ratio := clampf(current_mobility_power_ratio, 0.0, 1.0)
	var target_x_velocity := horizontal_input * move_speed * mobility_ratio
	var x_change_rate := get_horizontal_change_rate(horizontal_input) * mobility_ratio
	
	player_velocity.x = move_toward(
		player_velocity.x,
		target_x_velocity,
		x_change_rate * delta
	)
	
	player_velocity.y = min(player_velocity.y + gravity * delta, max_fall_speed)
	
	if is_up_thrust_pressed():
		player_velocity.y = max(
			player_velocity.y - upward_thrust * mobility_ratio * delta,
			-max_rise_speed * mobility_ratio
		)
		is_on_ground = false
	
	move_player_on_axis(Vector2(player_velocity.x * delta, 0.0))
	is_on_ground = false
	move_player_on_axis(Vector2(0.0, player_velocity.y * delta))


func get_horizontal_change_rate(horizontal_input: float) -> float:
	if horizontal_input == 0.0:
		return ground_deceleration if is_on_ground else air_deceleration
	
	return ground_acceleration if is_on_ground else air_acceleration


func get_horizontal_input() -> float:
	var input_axis := 0.0
	
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_axis -= 1.0
	
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_axis += 1.0
	
	return input_axis


func is_up_thrust_pressed() -> bool:
	return (
		Input.is_key_pressed(KEY_W)
		or Input.is_key_pressed(KEY_UP)
		or Input.is_key_pressed(KEY_SPACE)
	)


func move_player_on_axis(motion: Vector2) -> void:
	var distance := motion.length()
	
	if distance <= 0.0:
		return
	
	var step_count := int(ceil(distance / 4.0))
	var step: Vector2 = motion / float(step_count)
	
	for i in step_count:
		var next_position := player_marker.position + step
		
		if is_player_colliding_at(next_position):
			if step.x != 0.0:
				player_velocity.x = 0.0
			if step.y != 0.0:
				if step.y > 0.0:
					is_on_ground = true
					apply_landing_impact(player_velocity.y)
				player_velocity.y = 0.0
			return
		
		player_marker.position = next_position


func get_fall_damage_for_impact_speed(impact_speed: float) -> int:
	var minimum_damage_speed := get_fall_damage_start_speed()
	if impact_speed < minimum_damage_speed:
		return 0
	var damage_ratio := inverse_lerp(minimum_damage_speed, max_fall_speed, impact_speed)
	return roundi(lerpf(
		float(minimum_fall_damage),
		float(terminal_velocity_fall_damage),
		clampf(damage_ratio, 0.0, 1.0)
	))


func get_fall_damage_start_speed() -> float:
	var safe_fall_distance := maxf(fall_damage_safe_distance_blocks, 0.0) * maxf(
		fall_damage_block_size_pixels,
		0.0
	)
	return sqrt(2.0 * maxf(gravity, 0.0) * safe_fall_distance)


func apply_landing_impact(impact_speed: float) -> void:
	var damage := get_fall_damage_for_impact_speed(impact_speed)
	if damage <= 0:
		return
	apply_miner_damage(damage, true)


func is_player_colliding_at(test_position: Vector2) -> bool:
	var half_size := Vector2(
		player_collision_width * 0.5,
		player_collision_height * 0.5
	)
	var inset := 3.0
	var test_points := [
		test_position + Vector2(-half_size.x + inset, -half_size.y + inset),
		test_position + Vector2(half_size.x - inset, -half_size.y + inset),
		test_position + Vector2(-half_size.x + inset, half_size.y - inset),
		test_position + Vector2(half_size.x - inset, half_size.y - inset),
	]
	
	for point in test_points:
		if is_solid_at_position(point):
			return true
	
	return false


func is_solid_at_position(local_position: Vector2) -> bool:
	var cell := mine_tiles.local_to_map(local_position)
	
	if cell.x < 0 or cell.x >= grid_width:
		return true
	
	if cell.y < 0:
		return false
	
	if cell.y >= generated_row_count:
		generate_rows_until(cell.y + generation_buffer_rows)
	
	return block_types_by_cell.has(cell)


func is_position_inside_mining_bounds(local_position: Vector2) -> bool:
	var cell := mine_tiles.local_to_map(local_position)
	return cell.x >= 0 and cell.x < grid_width and cell.y >= 0 and cell.y < generated_row_count


func update_mine_direction() -> void:
	var held_direction := get_held_mine_direction()
	
	if held_direction == Vector2i.ZERO:
		return
	
	last_mine_direction = held_direction
	current_drill_facing = held_direction


func get_held_mine_direction() -> Vector2i:
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		return Vector2i.DOWN
	elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		return Vector2i.LEFT
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		return Vector2i.RIGHT
	
	return Vector2i.ZERO


func get_directional_blast_direction() -> Vector2i:
	if GameSettings.mouse_directed_e_enabled:
		return get_cardinal_direction_toward_cursor()
	# Up remains a valid blast direction even though W/up is normally the miner's thrust control.
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_SPACE):
		return Vector2i.UP
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		return Vector2i.DOWN
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		return Vector2i.LEFT
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		return Vector2i.RIGHT
	return current_drill_facing if current_drill_facing != Vector2i.ZERO else Vector2i.DOWN


func get_cardinal_direction_toward_cursor() -> Vector2i:
	return get_nearest_cardinal_direction(
		get_global_mouse_position() - player_marker.global_position,
		current_drill_facing
	)


func get_nearest_cardinal_direction(offset: Vector2, fallback: Vector2i = Vector2i.DOWN) -> Vector2i:
	if offset.length_squared() <= 0.0001:
		return fallback if fallback != Vector2i.ZERO else Vector2i.DOWN
	if absf(offset.x) > absf(offset.y):
		return Vector2i.RIGHT if offset.x > 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if offset.y > 0.0 else Vector2i.UP


func get_radial_blast_target_cells() -> Array[Vector2i]:
	var target_cells: Array[Vector2i] = []
	var player_cell := get_player_cell()
	generate_rows_until(player_cell.y + 2)
	for y_offset in range(-1, 2):
		for x_offset in range(-1, 2):
			var target_cell := player_cell + Vector2i(x_offset, y_offset)
			if is_ability_mineable_cell(target_cell):
				target_cells.append(target_cell)
	return target_cells


func get_directional_blast_target_cells(direction: Vector2i = Vector2i.ZERO) -> Array[Vector2i]:
	var target_cells: Array[Vector2i] = []
	var blast_direction := direction if direction != Vector2i.ZERO else get_directional_blast_direction()
	var player_cell := get_player_cell()
	if blast_direction == Vector2i.DOWN:
		generate_rows_until(player_cell.y + 4)
	for distance in range(1, 4):
		var target_cell := player_cell + blast_direction * distance
		if is_ability_mineable_cell(target_cell):
			target_cells.append(target_cell)
	return target_cells


func is_ability_mineable_cell(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= grid_width or cell.y < 0:
		return false
	return (
		block_types_by_cell.has(cell)
		and block_types_by_cell.get(cell, BlockType.ROCK) != BlockType.LODESTONE
		and can_drill_block_type(block_types_by_cell.get(cell, BlockType.ROCK))
		and not is_core_vault_seal_locked(cell)
	)


func try_activate_radial_blast() -> void:
	if not can_activate_ability(radial_blast_cooldown_remaining, 1):
		return
	var target_cells := get_radial_blast_target_cells()
	if target_cells.is_empty():
		return
	if not consume_loaded_explosive_charge():
		return
	radial_blast_cooldown_remaining = radial_blast_cooldown_seconds
	_run_blast_ability(target_cells)
	update_ability_buttons()


func try_activate_directional_blast() -> void:
	if not can_activate_ability(directional_blast_cooldown_remaining, 1):
		return
	var target_cells := get_directional_blast_target_cells()
	if target_cells.is_empty():
		return
	if not consume_loaded_explosive_charge():
		return
	directional_blast_cooldown_remaining = directional_blast_cooldown_seconds
	_run_blast_ability(target_cells)
	update_hud()


func can_activate_ability(cooldown_remaining: float, explosive_cost: int = 1) -> bool:
	return (
		not is_paused
		and not is_shop_open
		and not is_game_over
		and not is_arrival_countdown_active
		and not is_ability_effect_active
		and cooldown_remaining <= 0.0
		and get_loaded_explosive_charges() >= explosive_cost
	)


func _run_blast_ability(target_cells: Array[Vector2i]) -> void:
	is_ability_effect_active = true
	reset_mining_progress()
	var effect_positions: Array[Vector2] = []
	for target_cell in target_cells:
		effect_positions.append(mine_tiles.map_to_local(target_cell))
	if mining_effects != null:
		mining_effects.play_ability_explosion(effect_positions, ability_effect_duration_seconds)

	var block_removal_delay := get_ability_block_removal_delay()
	await get_tree().create_timer(block_removal_delay).timeout
	if not is_inside_tree():
		return

	mine_blast_target_cells(target_cells)
	if ground_encounter_system != null:
		ground_encounter_system.damage_enemies_in_cells(target_cells)

	await get_tree().create_timer(maxf(ability_effect_duration_seconds - block_removal_delay, 0.0)).timeout
	if not is_inside_tree():
		return
	is_ability_effect_active = false
	update_ability_buttons()


func get_ability_block_removal_delay() -> float:
	var previous_removal_delay := ability_effect_duration_seconds * 0.55
	return previous_removal_delay / maxf(ability_block_removal_speed_multiplier, 0.01)


func mine_blast_target_cells(target_cells: Array[Vector2i]) -> Dictionary:
	var captured_resources: Dictionary = {}
	var captured_pickups: Array[Dictionary] = []
	for target_cell in target_cells:
		var result := mine_target_cell(target_cell, false)
		var amount := int(result.get("amount", 0))
		if amount <= 0:
			continue
		var resource_name := str(result.get("resource_name", "Ore"))
		var block_type: BlockType = result.get("block_type", BlockType.EMPTY)
		captured_pickups.append({
			"resource_name": resource_name,
			"amount": amount,
			"block_type": block_type,
		})
		captured_resources[resource_name] = int(captured_resources.get(resource_name, 0)) + amount
	for pickup_index in captured_pickups.size():
		var pickup: Dictionary = captured_pickups[pickup_index]
		var centered_index := float(pickup_index) - float(captured_pickups.size() - 1) * 0.5
		play_blast_ore_text(
			str(pickup["resource_name"]),
			int(pickup["amount"]),
			pickup["block_type"],
			centered_index * 30.0
		)
	return captured_resources


func update_ability_cooldowns(delta: float) -> void:
	radial_blast_cooldown_remaining = maxf(radial_blast_cooldown_remaining - delta, 0.0)
	directional_blast_cooldown_remaining = maxf(directional_blast_cooldown_remaining - delta, 0.0)
	update_ability_buttons()


func update_player_visual(delta: float) -> void:
	var held_direction := get_held_mine_direction()
	var visual_direction := last_mine_direction
	var is_animating := held_direction != Vector2i.ZERO or player_velocity.length() > 5.0
	
	if held_direction != Vector2i.ZERO:
		visual_direction = held_direction
	elif absf(player_velocity.x) > absf(player_velocity.y) and absf(player_velocity.x) > 5.0:
		visual_direction = Vector2i.RIGHT if player_velocity.x > 0.0 else Vector2i.LEFT
	elif absf(player_velocity.y) > 5.0:
		visual_direction = Vector2i.DOWN if player_velocity.y > 0.0 else Vector2i.UP
	current_drill_facing = visual_direction
	
	if is_animating:
		player_animation_time += delta
	
	var frame := int(floor(player_animation_time * player_animation_fps)) % maxi(player_animation_frames, 1)
	var row := 0
	player_marker.rotation = 0.0
	player_marker.flip_h = false
	player_marker.flip_v = false
	
	match visual_direction:
		Vector2i.LEFT:
			row = 1
			player_marker.flip_h = true
		Vector2i.RIGHT:
			row = 1
		Vector2i.UP:
			row = 0
			player_marker.flip_v = true
		_:
			row = 0
	
	player_marker.region_rect = Rect2(
		float(frame * 64),
		float(row * 64),
		64.0,
		64.0
	)


func try_mine_with_movement_input(delta: float) -> void:
	var held_direction := get_held_mine_direction()
	
	if held_direction == Vector2i.ZERO:
		reset_mining_progress()
		return
	if not can_use_mining_drill():
		reset_mining_progress()
		return
	
	last_mine_direction = held_direction
	
	var target_cell := get_target_mine_cell()
	
	if not block_types_by_cell.has(target_cell):
		reset_mining_progress()
		return
	
	var block_type: BlockType = block_types_by_cell.get(target_cell, BlockType.ROCK)
	if block_type == BlockType.LODESTONE:
		reset_mining_progress()
		return
	if not can_drill_block_type(block_type):
		reset_mining_progress()
		show_drill_upgrade_required(block_type)
		return
	
	if target_cell != active_mining_cell:
		start_mining_cell(target_cell)
	
	active_mining_elapsed += delta
	active_mining_damage += drill_damage_per_second * delta
	play_mining_feedback_if_ready(target_cell)
	update_hud()
	
	if active_mining_damage >= active_block_hardness:
		mine_target_cell(target_cell)
		reset_mining_progress()


func can_use_mining_drill() -> bool:
	return is_on_ground and not is_paused and not is_shop_open and not is_game_over


func start_mining_cell(target_cell: Vector2i) -> void:
	active_mining_cell = target_cell
	active_mining_damage = 0.0
	active_mining_elapsed = 0.0
	mining_feedback_cooldown = 0.0
	var block_type: BlockType = block_types_by_cell.get(target_cell, BlockType.ROCK)
	active_block_hardness = get_block_durability(block_type, target_cell.y)
	update_hud()


func reset_mining_progress() -> void:
	if active_mining_cell == Vector2i(-9999, -9999):
		return
	
	active_mining_cell = Vector2i(-9999, -9999)
	active_mining_damage = 0.0
	active_mining_elapsed = 0.0
	mining_feedback_cooldown = 0.0
	active_block_hardness = 0.0
	update_hud()


func mine_target_cell(target_cell: Vector2i, play_feedback: bool = true) -> Dictionary:
	if not block_types_by_cell.has(target_cell):
		return {}
	if is_core_vault_seal_locked(target_cell):
		return {}
	
	var block_type: BlockType = block_types_by_cell.get(target_cell, BlockType.ROCK)
	var resource_name := get_resource_name_for_block_type(block_type)
	
	if is_inventory_resource(resource_name) and get_inventory_room() <= 0:
		update_hud()
		return {}
	
	visual_mine_tiles.erase_cell(target_cell)
	block_types_by_cell.erase(target_cell)

	if should_drop_silicone(block_type):
		if get_inventory_room() > 0:
			resources["Silicone"] = int(resources.get("Silicone", 0)) + 1
			record_resource_metric("resources_earned", "Silicone", 1)
			print("Found Silicone: +1")
			if play_feedback:
				play_block_mined_feedback(target_cell, "Silicone", 1)
			update_hud()
			return {"resource_name": "Silicone", "amount": 1, "block_type": BlockType.EMPTY}
	
	if is_inventory_resource(resource_name):
		var yield_amount := get_mined_resource_yield(block_type)
		var amount_to_add: int = mini(yield_amount, get_inventory_room())
		resources[resource_name] = int(resources.get(resource_name, 0)) + amount_to_add
		record_resource_metric("resources_earned", resource_name, amount_to_add)
		print("Mined %s: +%d" % [resource_name, amount_to_add])
		if play_feedback:
			play_block_mined_feedback(target_cell, resource_name, amount_to_add, block_type)
		if block_type == BlockType.PLANETCORE and core_vault_system != null:
			record_progression_milestone("time_to_planet_core")
			core_vault_system.start_boss_encounter()
		update_hud()
		return {"resource_name": resource_name, "amount": amount_to_add, "block_type": block_type}
	else:
		if play_feedback:
			play_block_mined_feedback(target_cell, resource_name, 0)
	
	update_hud()
	return {"resource_name": resource_name, "amount": 0}


func should_drop_silicone(block_type: BlockType, chance_roll: float = -1.0) -> bool:
	if block_type != BlockType.DIRT and block_type != BlockType.ROCK:
		return false
	var roll := randf() if chance_roll < 0.0 else chance_roll
	return roll < silicone_drop_chance


func update_mining_feedback_cooldown(delta: float) -> void:
	if mining_feedback_cooldown > 0.0:
		mining_feedback_cooldown = maxf(mining_feedback_cooldown - delta, 0.0)


func play_mining_feedback_if_ready(target_cell: Vector2i) -> void:
	if mining_effects == null or mining_feedback_cooldown > 0.0:
		return
	
	var block_type: BlockType = block_types_by_cell.get(target_cell, BlockType.ROCK)
	var block_name := get_resource_name_for_block_type(block_type)
	var target_position := mine_tiles.map_to_local(target_cell)
	mining_effects.play_drill_feedback(target_position, block_name, last_mine_direction)
	mining_feedback_cooldown = mining_feedback_interval_seconds


func play_block_mined_feedback(
	target_cell: Vector2i,
	resource_name: String,
	amount: int,
	block_type: BlockType = BlockType.EMPTY
) -> void:
	if mining_effects == null:
		return
	
	var target_position := mine_tiles.map_to_local(target_cell)
	var yield_range := get_ore_yield_range(block_type)
	var roll_min := yield_range.x if is_variable_yield_ore_block(block_type) else 0
	var roll_max := yield_range.y if is_variable_yield_ore_block(block_type) else 0
	mining_effects.play_block_mined(target_position, resource_name, amount, roll_min, roll_max)


func play_blast_ore_text(
	resource_name: String,
	amount: int,
	block_type: BlockType,
	vertical_list_offset: float = 0.0
) -> void:
	if mining_effects == null or amount <= 0:
		return
	var yield_range := get_ore_yield_range(block_type)
	var roll_min := yield_range.x if is_variable_yield_ore_block(block_type) else 0
	var roll_max := yield_range.y if is_variable_yield_ore_block(block_type) else 0
	mining_effects.play_ore_pickup_text(
		get_safe_ore_pickup_text_position() + Vector2(0.0, vertical_list_offset),
		resource_name,
		amount,
		roll_min,
		roll_max
	)


func get_safe_ore_pickup_text_position() -> Vector2:
	var screen_position := get_viewport_rect().size * 0.5
	screen_position.y -= ore_pickup_text_vertical_offset_pixels
	return mine_tiles.get_canvas_transform().affine_inverse() * screen_position


func update_lodestone_gravity(delta: float) -> void:
	if not has_falling_lodestones():
		lodestone_fall_speed = 0.0
		lodestone_fall_distance = 0.0
		return
	
	lodestone_fall_speed = minf(lodestone_fall_speed + gravity * delta, max_lodestone_fall_speed)
	lodestone_fall_distance += lodestone_fall_speed * delta
	
	var tile_height := 64.0
	while lodestone_fall_distance >= tile_height:
		if not step_lodestones_down():
			lodestone_fall_speed = 0.0
			lodestone_fall_distance = 0.0
			return
		
		lodestone_fall_distance -= tile_height


func has_falling_lodestones() -> bool:
	for cell in block_types_by_cell.keys():
		var cell_position: Vector2i = cell
		if block_types_by_cell[cell_position] != BlockType.LODESTONE:
			continue
		
		if can_lodestone_fall_to(cell_position + Vector2i.DOWN):
			return true
	
	return false


func step_lodestones_down() -> bool:
	var lodestone_cells: Array[Vector2i] = []
	
	for cell in block_types_by_cell.keys():
		var cell_position: Vector2i = cell
		if block_types_by_cell[cell_position] == BlockType.LODESTONE:
			lodestone_cells.append(cell_position)
	
	lodestone_cells.sort_custom(Callable(self, "sort_cells_bottom_first"))
	var moved_any := false
	
	for cell in lodestone_cells:
		if block_types_by_cell.get(cell, BlockType.EMPTY) != BlockType.LODESTONE:
			continue
		
		var target_cell := cell + Vector2i.DOWN
		if not can_lodestone_fall_to(target_cell):
			continue
		if target_cell == get_player_cell():
			apply_falling_boulder_damage(falling_lodestone_damage)
			play_lodestone_impact_feedback(cell)
			return false
		
		move_lodestone_block(cell, target_cell)
		moved_any = true
	
	return moved_any


func sort_cells_bottom_first(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y:
		return a.x < b.x
	return a.y > b.y


func can_lodestone_fall_to(cell: Vector2i) -> bool:
	return cell.y >= get_first_ground_row() and cell.y < generated_row_count and not block_types_by_cell.has(cell)


func move_lodestone_block(from_cell: Vector2i, to_cell: Vector2i) -> void:
	block_types_by_cell.erase(from_cell)
	block_types_by_cell[to_cell] = BlockType.LODESTONE
	visual_mine_tiles.erase_cell(from_cell)
	visual_mine_tiles.set_cell(
		to_cell,
		tile_source_id,
		get_tile_coords_for_block_type(BlockType.LODESTONE, to_cell)
	)
	
	if not can_lodestone_fall_to(to_cell + Vector2i.DOWN):
		play_lodestone_impact_feedback(to_cell)


func play_lodestone_impact_feedback(cell: Vector2i) -> void:
	if mining_effects == null:
		return
	
	var target_position := mine_tiles.map_to_local(cell)
	mining_effects.play_lodestone_impact(target_position, lodestone_fall_speed)


func is_inventory_resource(resource_name: String) -> bool:
	return resource_name != "Dirt" and resource_name != "Rock" and resource_name != "Lode Stone" and resource_name != "Unknown"


func get_mined_resource_yield(block_type: BlockType) -> int:
	if is_variable_yield_ore_block(block_type):
		var yield_range := get_ore_yield_range(block_type)
		return randi_range(yield_range.x, yield_range.y)
	return 1


func get_ore_yield_range(block_type: BlockType) -> Vector2i:
	var base_range: Vector2i = ore_base_yield_ranges.get(
		block_type,
		Vector2i(ore_yield_min, ore_yield_max)
	)
	var level := maxi(int(upgrade_levels.get("miner_drill_yield", 0)), 0)
	# Odd levels raise the minimum; even levels raise the maximum.
	return Vector2i(base_range.x + ceili(float(level) / 2.0), base_range.y + floori(float(level) / 2.0))


func is_variable_yield_ore_block(block_type: BlockType) -> bool:
	return block_type in [
		BlockType.COPPER,
		BlockType.IRON,
		BlockType.GOLD,
		BlockType.DIAMOND,
		BlockType.WARPGEMS,
		BlockType.BLACKHOLECRYSTALS,
	]


func get_inventory_count() -> int:
	var count := 0
	
	for resource_name in resources.keys():
		count += int(resources[resource_name])
	
	return count


func get_inventory_room() -> int:
	return maxi(inventory_capacity - get_inventory_count(), 0)


func get_cargo_hold_count() -> int:
	var count := 0
	
	for resource_name in cargo_hold_resources.keys():
		count += int(cargo_hold_resources[resource_name])
	
	return count


func get_cargo_hold_room() -> int:
	return maxi(cargo_hold_capacity - get_cargo_hold_count(), 0)


func get_total_resource_count(resource_name: String) -> int:
	return int(resources.get(resource_name, 0)) + int(cargo_hold_resources.get(resource_name, 0))


func get_total_sellable_resource_count() -> int:
	var count := 0
	for resource_name in get_sellable_resource_names():
		if get_resource_value(resource_name) <= 0:
			continue
		count += get_total_resource_count(resource_name)
	return count


func get_lander_sellable_resource_count() -> int:
	var count := 0
	for resource_name in get_sellable_resource_names():
		if get_resource_value(resource_name) <= 0:
			continue
		count += int(cargo_hold_resources.get(resource_name, 0))
	return count


func consume_resource(resource_name: String, amount: int) -> void:
	var requested_amount := maxi(amount, 0)
	var before_count := get_total_resource_count(resource_name)
	record_resource_metric("resources_spent", resource_name, mini(requested_amount, before_count))
	var cargo_hold_count: int = int(cargo_hold_resources.get(resource_name, 0))
	var from_cargo_hold: int = mini(cargo_hold_count, amount)
	cargo_hold_resources[resource_name] = cargo_hold_count - from_cargo_hold
	amount -= from_cargo_hold
	
	if amount <= 0:
		return
	
	var cargo_count: int = int(resources.get(resource_name, 0))
	resources[resource_name] = maxi(cargo_count - amount, 0)


func get_explosive_powder() -> int:
	return int(ammo_fabricator_components.get("explosive_powder", 0))


func get_explosive_casings() -> int:
	return int(ammo_fabricator_components.get("explosive_casing", 0))


func get_fabricated_explosive_charges() -> int:
	return (
		int(ammo_fabricator_stock.get("explosive_charge", 0))
		+ int(cargo_hold_resources.get("Explosive Charge", 0))
	)


func get_loaded_explosive_charges() -> int:
	return int(miner_ammo.get("explosive_charge", 0))


func clamp_ammo_fabricator_state() -> void:
	ammo_fabricator_components["explosive_powder"] = clampi(get_explosive_powder(), 0, max_explosive_powder)
	ammo_fabricator_components["explosive_casing"] = maxi(get_explosive_casings(), 0)
	ammo_fabricator_stock["explosive_charge"] = clampi(
		int(ammo_fabricator_stock.get("explosive_charge", 0)),
		0,
		max_fabricated_explosive_charges
	)
	miner_ammo["explosive_charge"] = clampi(
		get_loaded_explosive_charges(),
		0,
		max_miner_explosive_charges
	)


func can_process_explosive_powder() -> bool:
	return (
		get_total_resource_count("Raw Fuel") > 0
		and get_explosive_powder() + explosive_powder_per_raw_fuel <= max_explosive_powder
	)


func process_explosive_powder() -> void:
	if not can_process_explosive_powder():
		refresh_lander_view_or_shop_ui()
		return
	consume_resource("Raw Fuel", 1)
	ammo_fabricator_components["explosive_powder"] = get_explosive_powder() + explosive_powder_per_raw_fuel
	refresh_lander_view_or_shop_ui()
	update_hud()


func can_fabricate_explosive_casing() -> bool:
	return get_total_resource_count("Copper") > 0


func fabricate_explosive_casing() -> void:
	if not can_fabricate_explosive_casing():
		refresh_lander_view_or_shop_ui()
		return
	consume_resource("Copper", 1)
	ammo_fabricator_components["explosive_casing"] = get_explosive_casings() + casing_per_copper
	refresh_lander_view_or_shop_ui()
	update_hud()


func can_assemble_explosive_charge() -> bool:
	return (
		get_explosive_powder() >= 1
		and get_explosive_casings() >= 1
		and get_fabricated_explosive_charges() < max_fabricated_explosive_charges
	)


func assemble_explosive_charge() -> void:
	if not can_assemble_explosive_charge():
		refresh_lander_view_or_shop_ui()
		return
	ammo_fabricator_components["explosive_powder"] = get_explosive_powder() - 1
	ammo_fabricator_components["explosive_casing"] = get_explosive_casings() - 1
	ammo_fabricator_stock["explosive_charge"] = get_fabricated_explosive_charges() + 1
	refresh_lander_view_or_shop_ui()
	update_hud()


func get_miner_explosive_charge_room() -> int:
	return maxi(max_miner_explosive_charges - get_loaded_explosive_charges(), 0)


func load_explosive_charges_into_miner(requested_amount: int = -1) -> void:
	var available := get_fabricated_explosive_charges()
	var requested := available if requested_amount < 0 else mini(available, maxi(requested_amount, 0))
	var amount_to_load := mini(requested, get_miner_explosive_charge_room())
	if amount_to_load <= 0:
		refresh_lander_view_or_shop_ui()
		return
	var cargo_charges := int(cargo_hold_resources.get("Explosive Charge", 0))
	var from_cargo := mini(cargo_charges, amount_to_load)
	cargo_hold_resources["Explosive Charge"] = cargo_charges - from_cargo
	var remaining := amount_to_load - from_cargo
	if remaining > 0:
		ammo_fabricator_stock["explosive_charge"] = maxi(
			int(ammo_fabricator_stock.get("explosive_charge", 0)) - remaining,
			0
		)
	miner_ammo["explosive_charge"] = get_loaded_explosive_charges() + amount_to_load
	refresh_lander_view_or_shop_ui()
	update_hud()


func consume_loaded_explosive_charge() -> bool:
	var loaded := get_loaded_explosive_charges()
	if loaded <= 0:
		return false
	miner_ammo["explosive_charge"] = loaded - 1
	return true


func get_resource_value(resource_name: String) -> int:
	if BAR_BASE_ORES.has(resource_name):
		var base_ore := String(BAR_BASE_ORES[resource_name])
		# One bar consumes three raw ore and sells for 1.5 times that raw total.
		return roundi(float(RESOURCE_SALE_VALUES.get(base_ore, 0)) * 3.0 * 1.5)
	return int(RESOURCE_SALE_VALUES.get(resource_name, 0))


func get_hardness_for_block_type(block_type: BlockType) -> float:
	return float(StartingPlanetBalance.MATERIAL_BASE_DURABILITY.get(
		get_material_durability_key(block_type),
		StartingPlanetBalance.MATERIAL_BASE_DURABILITY["rock"]
	))


func get_material_durability_key(block_type: BlockType) -> String:
	match block_type:
		BlockType.DIRT:
			return "dirt"
		BlockType.COPPER:
			return "copper"
		BlockType.RAWFUEL:
			return "raw_fuel"
		BlockType.IRON:
			return "iron"
		BlockType.GOLD:
			return "gold"
		BlockType.TREASURE:
			return "treasure"
		BlockType.DIAMOND:
			return "diamond"
		BlockType.WARPGEMS:
			return "warp_gems"
		BlockType.BLACKHOLECRYSTALS:
			return "black_hole_crystals"
		BlockType.PLANETCORE:
			return "planet_core"
		_:
			return "rock"


func get_depth_scaled_hardness(block_type: BlockType, row: int) -> float:
	return get_block_durability(block_type, row)


func get_block_durability(block_type: BlockType, row: int) -> float:
	var depth_meters := float(maxi(row - get_first_ground_row(), 0) * depth_meters_per_row)
	return get_hardness_for_block_type(block_type) * StartingPlanetBalance.get_depth_multiplier(
		depth_meters,
		float(core_vault_start_depth_meters)
	)


func get_required_drill_level(block_type: BlockType) -> int:
	match block_type:
		BlockType.DIAMOND:
			return 2
		BlockType.WARPGEMS:
			return 4
		BlockType.BLACKHOLECRYSTALS, BlockType.PLANETCORE:
			return 5
		_:
			return 0


func can_drill_block_type(block_type: BlockType) -> bool:
	return int(upgrade_levels.get("miner_drill_efficiency", 0)) >= get_required_drill_level(block_type)


func show_drill_upgrade_required(block_type: BlockType) -> void:
	drill_access_message = "%s requires Drill Level %d." % [
		get_resource_name_for_block_type(block_type),
		get_required_drill_level(block_type),
	]
	drill_access_message_remaining = 2.0
	update_hud()


func get_mining_balance_readout(block_type: BlockType, depth_meters: int) -> Dictionary:
	var row := get_first_ground_row() + floori(float(maxi(depth_meters, 0)) / float(depth_meters_per_row))
	var base_durability := get_hardness_for_block_type(block_type)
	var multiplier := StartingPlanetBalance.get_depth_multiplier(float(depth_meters), float(core_vault_start_depth_meters))
	var durability := get_block_durability(block_type, row)
	return {
		"base_durability": base_durability,
		"depth_multiplier": multiplier,
		"final_durability": durability,
		"drill_dps": drill_damage_per_second,
		"estimated_break_seconds": durability / maxf(drill_damage_per_second, 0.001),
	}


func get_target_mine_cell() -> Vector2i:
	var half_height := player_collision_height * 0.5
	var half_width := player_collision_width * 0.5
	var target_position := player_marker.position
	
	match last_mine_direction:
		Vector2i.LEFT:
			target_position += Vector2(-half_width - 22.0, 0.0)
		Vector2i.RIGHT:
			target_position += Vector2(half_width + 22.0, 0.0)
		_:
			target_position += Vector2(0.0, half_height + 24.0)
	
	return mine_tiles.local_to_map(target_position)


func get_resource_name_for_block_type(block_type: BlockType) -> String:
	match block_type:
		BlockType.DIRT:
			return "Dirt"
		BlockType.ROCK:
			return "Rock"
		BlockType.LODESTONE:
			return "Lode Stone"
		BlockType.COPPER:
			return "Copper"
		BlockType.RAWFUEL:
			return "Raw Fuel"
		BlockType.IRON:
			return "Iron"
		BlockType.GOLD:
			return "Gold"
		BlockType.TREASURE:
			return "Treasure"
		BlockType.DIAMOND:
			return "Diamond"
		BlockType.WARPGEMS:
			return "Warp Gems"
		BlockType.BLACKHOLECRYSTALS:
			return "Black Hole Crystals"
		BlockType.PLANETCORE:
			return "Planet Core"
		_:
			return "Unknown"


func create_mining_overlays() -> void:
	mining_blink_overlay = Polygon2D.new()
	mining_blink_overlay.name = "MiningBlinkOverlay"
	mining_blink_overlay.z_index = 8
	mining_blink_overlay.color = Color(0.82, 0.96, 1.0, 0.42)
	mining_blink_overlay.polygon = PackedVector2Array([
		Vector2(-32.0, -32.0),
		Vector2(32.0, -32.0),
		Vector2(32.0, 32.0),
		Vector2(-32.0, 32.0),
	])
	mining_blink_overlay.visible = false
	mine_tiles.add_child(mining_blink_overlay)
	
	mining_progress_overlay = Polygon2D.new()
	mining_progress_overlay.name = "MiningProgressOverlay"
	mining_progress_overlay.z_index = 9
	mining_progress_overlay.color = Color(0.2, 0.95, 1.0, 0.9)
	mining_progress_overlay.visible = false
	mine_tiles.add_child(mining_progress_overlay)


func update_mining_overlays() -> void:
	if mining_blink_overlay == null or mining_progress_overlay == null:
		return
	
	if active_mining_cell == Vector2i(-9999, -9999):
		mining_blink_overlay.visible = false
		mining_progress_overlay.visible = false
		return
	
	if not block_types_by_cell.has(active_mining_cell):
		mining_blink_overlay.visible = false
		mining_progress_overlay.visible = false
		return
	
	var active_position := mine_tiles.map_to_local(active_mining_cell)
	var blink_phase: float = fmod(active_mining_elapsed, 0.5)
	var progress_ratio: float = active_mining_damage / maxf(active_block_hardness, 0.01)
	var progress_width: float = 56.0 * clampf(progress_ratio, 0.0, 1.0)
	
	mining_blink_overlay.position = active_position
	mining_blink_overlay.visible = blink_phase < 0.16
	
	mining_progress_overlay.position = active_position
	mining_progress_overlay.polygon = PackedVector2Array([
		Vector2(-28.0, 24.0),
		Vector2(-28.0 + progress_width, 24.0),
		Vector2(-28.0 + progress_width, 28.0),
		Vector2(-28.0, 28.0),
	])
	mining_progress_overlay.visible = true


func create_shop_ui() -> void:
	initialize_upgrade_definitions()
	initialize_upgrade_stat_rules()
	capture_base_upgrade_stats()
	
	var shop_layer := CanvasLayer.new()
	shop_layer.name = "ShopUI"
	shop_layer.layer = SHOP_LAYER_INDEX
	add_child(shop_layer)
	
	shop_panel = Panel.new()
	shop_panel.name = "ShopPanel"
	shop_panel.theme = GameTheme.create_button_theme()
	shop_panel.anchor_left = 0.04
	shop_panel.anchor_right = 0.96
	shop_panel.anchor_top = 0.05
	shop_panel.anchor_bottom = 0.95
	shop_panel.offset_left = 0.0
	shop_panel.offset_right = 0.0
	shop_panel.offset_top = 0.0
	shop_panel.offset_bottom = 0.0
	shop_panel.visible = false
	shop_layer.add_child(shop_panel)
	
	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 28.0
	margin.offset_top = 24.0
	margin.offset_right = -28.0
	margin.offset_bottom = -24.0
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	shop_panel.add_child(margin)
	
	var box := VBoxContainer.new()
	box.name = "ShopBox"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	
	shop_title_label = Label.new()
	shop_title_label.text = "Surface Shop"
	shop_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title_label.add_theme_font_size_override("font_size", 30)
	box.add_child(shop_title_label)

	shop_master_tabs = HBoxContainer.new()
	shop_master_tabs.name = "MasterTabs"
	shop_master_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	shop_master_tabs.add_theme_constant_override("separation", 10)
	box.add_child(shop_master_tabs)
	add_shop_button(shop_master_tabs, "Home", Callable(self, "show_shop_main_view"))
	add_shop_button(shop_master_tabs, "Upgrades", Callable(self, "show_upgrade_category_view"))
	add_shop_button(shop_master_tabs, "Lander", Callable(self, "show_market_view"))
	var master_fabricator_button := add_shop_button(shop_master_tabs, "Fabricator", Callable(self, "show_fabricator_view"))
	master_fabricator_button.name = "MasterFabricatorTab"
	for tab in shop_master_tabs.get_children():
		if tab is Button:
			(tab as Button).custom_minimum_size = Vector2(190.0, 42.0)

	var stats_scroll := ScrollContainer.new()
	stats_scroll.name = "StatsScroll"
	stats_scroll.custom_minimum_size.y = 58.0
	stats_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	stats_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(stats_scroll)
	var stats_row := HBoxContainer.new()
	stats_row.name = "StatsWithIcons"
	stats_row.add_theme_constant_override("separation", 18)
	stats_scroll.add_child(stats_row)
	add_shop_stat_card(stats_row, "credits", "Gold", "Credits")
	add_shop_stat_card(stats_row, "hull", "Iron", "Hull")
	add_shop_stat_card(stats_row, "miner_cargo", "Treasure", "Miner")
	add_shop_stat_card(stats_row, "lander_cargo", "Copper", "Lander")
	add_shop_stat_card(stats_row, "mining_fuel", "Raw Fuel", "Mining Fuel")
	add_shop_stat_card(stats_row, "rocket_fuel", "Raw Fuel", "Rocket Fuel")
	add_shop_stat_card(stats_row, "starship_fuel", "Raw Fuel", "Ship Fuel")
	
	shop_status_label = Label.new()
	shop_status_label.add_theme_font_size_override("font_size", 18)
	shop_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_status_label.visible = false
	box.add_child(shop_status_label)
	
	shop_content = VBoxContainer.new()
	shop_content.name = "ShopContent"
	shop_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_content.add_theme_constant_override("separation", 18)
	box.add_child(shop_content)
	
	show_shop_main_view()


func add_shop_stat_card(parent: HBoxContainer, key: String, icon_resource: String, title: String) -> void:
	var card := HBoxContainer.new()
	card.custom_minimum_size = Vector2(180.0, 52.0)
	card.add_theme_constant_override("separation", 7)
	parent.add_child(card)
	card.add_child(create_resource_icon(icon_resource, Vector2(34.0, 34.0)))
	var label := Label.new()
	label.text = title
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	card.add_child(label)
	shop_stat_labels[key] = label


func create_developer_test_panel() -> void:
	developer_test_panel = DeveloperTestPanelScript.new()
	add_child(developer_test_panel)
	developer_test_panel.setup(self)


func add_shop_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 46.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func apply_individual_sell_button_style(button: Button) -> void:
	button.add_theme_stylebox_override(
		"normal",
		GameTheme.create_button_style(Color("#78B4CE"), Color("#526F82"), Color("#16242E"))
	)
	button.add_theme_stylebox_override(
		"hover",
		GameTheme.create_button_style(Color("#8CC8DE"), Color("#638196"), Color("#16242E"))
	)
	button.add_theme_stylebox_override(
		"pressed",
		GameTheme.create_button_style(Color("#5D91AA"), Color("#3D5A6D"), Color("#0B141B"))
	)


func add_shop_spacer(parent: Control) -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	return spacer


func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func create_resource_icon(resource_name: String, icon_size: Vector2 = Vector2(32.0, 32.0)) -> TextureRect:
	var icon := TextureRect.new()
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = ResourceTileTexture
	atlas_texture.region = Rect2(Vector2(get_resource_icon_tile_coords(resource_name)) * 64.0, Vector2(64.0, 64.0))
	icon.texture = atlas_texture
	icon.custom_minimum_size = icon_size
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon


func get_resource_icon_tile_coords(resource_name: String) -> Vector2i:
	match resource_name:
		"Silicone", "Silicone Wafer":
			return rock_tiles[0] if not rock_tiles.is_empty() else Vector2i(4, 0)
		"Copper", "Copper Bar", "Copper Wire":
			return copper_tiles[0] if not copper_tiles.is_empty() else Vector2i(4, 1)
		"Raw Fuel", "Explosive Charge", "GPS Marker":
			return rawfuel_tiles[0] if not rawfuel_tiles.is_empty() else Vector2i(0, 1)
		"Iron", "Iron Bar", "Iron Wire":
			return iron_tiles[0] if not iron_tiles.is_empty() else Vector2i(0, 2)
		"Gold", "Gold Bar":
			return gold_tiles[0] if not gold_tiles.is_empty() else Vector2i(3, 2)
		"Basic Circuit":
			return treasure_tiles[0] if not treasure_tiles.is_empty() else Vector2i(7, 1)
		"Treasure":
			return treasure_tiles[0] if not treasure_tiles.is_empty() else Vector2i(7, 1)
		"Diamond":
			return diamond_tiles[0] if not diamond_tiles.is_empty() else Vector2i(2, 3)
		"Warp Gems":
			return warpgems_tiles[0] if not warpgems_tiles.is_empty() else Vector2i(6, 2)
		"Black Hole Crystals":
			return blackholecrystal_tiles[0] if not blackholecrystal_tiles.is_empty() else Vector2i(0, 3)
		"Planet Core":
			return blackholecrystal_tiles[0] if not blackholecrystal_tiles.is_empty() else Vector2i(0, 3)
		_:
			return dirt_tiles[0] if not dirt_tiles.is_empty() else Vector2i(0, 0)


func clear_shop_content() -> void:
	if shop_content == null:
		return
	
	lander_cargo_hold_list = null
	repair_hull_button = null
	return_to_starship_button = null
	return_to_starship_status_label = null
	fuel_processing_status_label = null
	ammo_fabricator_status_label = null
	fabricator_available_materials_label = null
	fabricator_materials_list = null
	treasure_processing_status_label = null
	clear_children(shop_content)


func show_shop_main_view() -> void:
	clear_shop_content()
	shop_title_label.text = "Surface Shop"
	shop_back_callback = Callable(self, "close_shop")
	
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 28)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.add_child(top_row)
	
	add_shop_button(top_row, "Upgrades", Callable(self, "show_upgrade_category_view"))
	
	var fuel_action_column := VBoxContainer.new()
	fuel_action_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fuel_action_column.add_theme_constant_override("separation", 8)
	top_row.add_child(fuel_action_column)
	
	refuel_button = add_shop_button(fuel_action_column, get_refuel_button_text(), Callable(self, "_on_refuel_pressed"))
	repair_hull_button = add_shop_button(fuel_action_column, get_repair_hull_button_text(), Callable(self, "_on_repair_hull_pressed"))
	return_to_starship_status_label = Label.new()
	return_to_starship_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return_to_starship_status_label.add_theme_font_size_override("font_size", 14)
	fuel_action_column.add_child(return_to_starship_status_label)
	return_to_starship_button = add_shop_button(fuel_action_column, "Return to Starship", Callable(self, "_on_return_to_starship_pressed"))
	add_shop_button(top_row, "Lander", Callable(self, "show_market_view"))
	
	var center_box := CenterContainer.new()
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_content.add_child(center_box)
	
	var summary := Label.new()
	summary.custom_minimum_size = Vector2(520.0, 80.0)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 22)
	summary.text = "Choose a station."
	center_box.add_child(summary)
	
	add_shop_button(shop_content, "Leave Shop", Callable(self, "close_shop"))
	update_shop_ui()


func show_upgrade_category_view() -> void:
	clear_shop_content()
	shop_title_label.text = "Upgrades"
	shop_back_callback = Callable(self, "show_shop_main_view")
	
	var category_box := VBoxContainer.new()
	category_box.alignment = BoxContainer.ALIGNMENT_CENTER
	category_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	category_box.add_theme_constant_override("separation", 18)
	shop_content.add_child(category_box)
	
	for category_name in ["Miner", "Lander", "Planetary Upgrades", "Starship", "Global"]:
		if category_name != "Miner" and not is_upgrade_category_relevant(category_name):
			continue
		var callback := (
			Callable(self, "show_miner_component_view")
			if category_name == "Miner"
			else Callable(self, "show_upgrade_grid_view").bind(category_name)
		)
		var button := add_shop_button(category_box, category_name, callback)
		button.custom_minimum_size = Vector2(380.0, 62.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	add_shop_button(shop_content, "Back", Callable(self, "show_shop_main_view"))
	update_shop_ui()


func show_miner_component_view() -> void:
	clear_shop_content()
	shop_title_label.text = "MK1 Miner Components"
	shop_back_callback = Callable(self, "show_upgrade_category_view")
	var component_box := GridContainer.new()
	component_box.columns = 2
	component_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	component_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	component_box.add_theme_constant_override("h_separation", 18)
	component_box.add_theme_constant_override("v_separation", 12)
	shop_content.add_child(component_box)
	for category_name in get_miner_component_category_names():
		if not is_upgrade_category_relevant(category_name):
			continue
		add_shop_button(
			component_box,
			category_name,
			Callable(self, "show_upgrade_grid_view").bind(category_name)
		)
	add_shop_button(shop_content, "Back to Upgrades", Callable(self, "show_upgrade_category_view"))
	update_shop_ui()


func get_miner_component_category_names() -> Array[String]:
	return [
		"Drill Assembly", "Power Unit", "Mobility System", "Fuel Cell", "Cargo Capacity",
		"Thermal Management", "Life Support", "Shield Generator", "Structural Frame",
		"Capacitor Bank", "Weapon Systems", "Sensor Suite",
	]


func show_upgrade_grid_view(category_name: String) -> void:
	clear_shop_content()
	shop_title_label.text = "%s Upgrades" % category_name
	shop_back_callback = (
		Callable(self, "show_miner_component_view")
		if get_miner_component_category_names().has(category_name)
		else Callable(self, "show_upgrade_category_view")
	)
	
	var grid_center := CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_content.add_child(grid_center)
	
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 24)
	grid_center.add_child(grid)
	
	var category_upgrades: Array = upgrade_definitions.get(category_name, [])
	for definition in category_upgrades:
		if not is_upgrade_relevant(definition):
			continue
		var upgrade_id: String = String(definition["id"])
		var level: int = int(upgrade_levels.get(upgrade_id, 0))
		var max_level: int = int(definition.get("max_level", StartingPlanetBalance.MK1_MAX_LEVEL))
		var costs := get_upgrade_costs(definition, level)
		var button_text := "%s\nLvl %d/%d\n%s\n%s" % [
			String(definition["name"]),
			level,
			max_level,
			format_upgrade_effect(definition, level),
			format_upgrade_costs(costs)
		]
		var button := add_shop_button(grid, button_text, Callable(self, "_on_upgrade_pressed").bind(category_name, upgrade_id))
		button.custom_minimum_size = Vector2(260.0, 94.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 15)
		button.disabled = level >= max_level or not can_afford_upgrade(costs)
	
	var back_callback := (
		Callable(self, "show_miner_component_view")
		if get_miner_component_category_names().has(category_name)
		else Callable(self, "show_upgrade_category_view")
	)
	add_shop_button(shop_content, "Back to Upgrades", back_callback)
	update_shop_ui()


func is_upgrade_category_relevant(category_name: String) -> bool:
	for definition in upgrade_definitions.get(category_name, []):
		if is_upgrade_relevant(definition):
			return true
	return false


func is_upgrade_relevant(definition: Dictionary) -> bool:
	var upgrade_id := String(definition.get("id", ""))
	if is_enemy_contact_upgrade(upgrade_id) and not enemy_contact_made:
		return false
	if not has_purchased_any_upgrade():
		return upgrade_id == "miner_sensor_strength"
	if int(upgrade_levels.get(upgrade_id, 0)) > 0:
		return true
	for cost in definition.get("base_costs", []):
		var resource_name := String(cost.get("resource", ""))
		if resource_name == "Credits":
			continue
		if not has_discovered_upgrade_resource(resource_name):
			return false
	return true


func is_enemy_contact_upgrade(upgrade_id: String) -> bool:
	return (
		upgrade_id.begins_with("miner_thermal_")
		or upgrade_id.begins_with("miner_life_support_")
		or upgrade_id.begins_with("miner_shield_")
		or upgrade_id.begins_with("miner_weapon_")
	)


func has_purchased_any_upgrade() -> bool:
	for level in upgrade_levels.values():
		if int(level) > 0:
			return true
	return false


func has_discovered_upgrade_resource(resource_name: String) -> bool:
	if get_total_resource_count(resource_name) > 0:
		return true
	var earned: Dictionary = progression_metrics.get("resources_earned", {})
	var spent: Dictionary = progression_metrics.get("resources_spent", {})
	return int(earned.get(resource_name, 0)) > 0 or int(spent.get(resource_name, 0)) > 0


func show_market_view() -> void:
	clear_shop_content()
	shop_title_label.text = "Lander"
	shop_back_callback = Callable(self, "show_shop_main_view")
	
	var deposit_row := CenterContainer.new()
	deposit_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.add_child(deposit_row)
	
	var deposit_button := add_shop_button(deposit_row, "Deposit All", Callable(self, "_on_deposit_all_pressed"))
	deposit_button.custom_minimum_size = Vector2(320.0, 52.0)
	
	var market_columns := HBoxContainer.new()
	market_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_columns.add_theme_constant_override("separation", 14)
	shop_content.add_child(market_columns)
	
	var cargo_hold_panel := VBoxContainer.new()
	cargo_hold_panel.custom_minimum_size = Vector2(680.0, 0.0)
	cargo_hold_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cargo_hold_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cargo_hold_panel.add_theme_constant_override("separation", 8)
	market_columns.add_child(cargo_hold_panel)
	
	var cargo_hold_title := Label.new()
	cargo_hold_title.text = "Cargo Hold"
	cargo_hold_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cargo_hold_title.add_theme_font_size_override("font_size", 18)
	cargo_hold_panel.add_child(cargo_hold_title)

	if get_lander_sellable_resource_count() > 0:
		add_shop_button(
			cargo_hold_panel,
			"Sell All Cargo   +%d Credits" % get_sell_all_quote(),
			Callable(self, "_on_sell_all_pressed")
		)

	var cargo_scroll := ScrollContainer.new()
	cargo_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cargo_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cargo_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cargo_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	cargo_hold_panel.add_child(cargo_scroll)

	lander_cargo_hold_list = VBoxContainer.new()
	lander_cargo_hold_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lander_cargo_hold_list.add_theme_constant_override("separation", 6)
	cargo_scroll.add_child(lander_cargo_hold_list)
	
	var process_column := VBoxContainer.new()
	process_column.custom_minimum_size = Vector2(280.0, 0.0)
	process_column.size_flags_horizontal = Control.SIZE_SHRINK_END
	process_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	process_column.add_theme_constant_override("separation", 10)
	market_columns.add_child(process_column)
	
	var process_offset := Control.new()
	process_offset.custom_minimum_size = Vector2(0.0, 56.0)
	process_column.add_child(process_offset)
	
	var process_button := add_shop_button(process_column, get_process_raw_fuel_button_text(), Callable(self, "process_raw_fuel_from_storage"))
	process_button.disabled = not can_start_fuel_processing()
	
	fuel_processing_status_label = Label.new()
	fuel_processing_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fuel_processing_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fuel_processing_status_label.add_theme_font_size_override("font_size", 15)
	process_column.add_child(fuel_processing_status_label)

	var fabricator_button := add_shop_button(process_column, "Lander Fabricator", Callable(self, "show_fabricator_view"))
	fabricator_button.disabled = not fabricator_unlocked
	
	var treasure_process_button := add_shop_button(
		process_column,
		"Process Treasure\nRandom Upgrade +1 to +3 Levels",
		Callable(self, "process_treasure_from_storage")
	)
	treasure_process_button.disabled = not can_process_treasure()
	
	treasure_processing_status_label = Label.new()
	treasure_processing_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	treasure_processing_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	treasure_processing_status_label.add_theme_font_size_override("font_size", 15)
	treasure_processing_status_label.text = get_treasure_processing_status_text()
	process_column.add_child(treasure_processing_status_label)
	
	add_shop_button(shop_content, "Back", Callable(self, "show_shop_main_view"))
	update_shop_ui()


func show_fabricator_view() -> void:
	clear_shop_content()
	shop_title_label.text = "Lander Fabricator"
	shop_back_callback = Callable(self, "show_market_view")

	var columns := HBoxContainer.new()
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 22)
	shop_content.add_child(columns)

	var materials_scroll := ScrollContainer.new()
	materials_scroll.name = "MaterialsScroll"
	materials_scroll.custom_minimum_size = Vector2(300.0, 0.0)
	materials_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	materials_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(materials_scroll)
	var materials_box := VBoxContainer.new()
	materials_box.custom_minimum_size.x = 280.0
	materials_box.add_theme_constant_override("separation", 9)
	materials_scroll.add_child(materials_box)
	fabricator_available_materials_label = Label.new()
	fabricator_available_materials_label.name = "CombinedFabricatorMaterials"
	fabricator_available_materials_label.text = "AVAILABLE MATERIALS — MINER + LANDER"
	fabricator_available_materials_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fabricator_available_materials_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fabricator_available_materials_label.add_theme_font_size_override("font_size", 19)
	fabricator_available_materials_label.add_theme_color_override("font_color", Color.WHITE)
	fabricator_available_materials_label.add_theme_color_override("font_outline_color", Color.BLACK)
	fabricator_available_materials_label.add_theme_constant_override("outline_size", 3)
	materials_box.add_child(fabricator_available_materials_label)
	fabricator_materials_list = VBoxContainer.new()
	fabricator_materials_list.add_theme_constant_override("separation", 7)
	materials_box.add_child(fabricator_materials_list)

	var recipe_scroll := ScrollContainer.new()
	recipe_scroll.name = "RecipeScroll"
	recipe_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	recipe_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(recipe_scroll)
	var fabricator_box := VBoxContainer.new()
	fabricator_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fabricator_box.add_theme_constant_override("separation", 10)
	recipe_scroll.add_child(fabricator_box)

	ammo_fabricator_status_label = Label.new()
	ammo_fabricator_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ammo_fabricator_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ammo_fabricator_status_label.add_theme_font_size_override("font_size", 18)
	fabricator_box.add_child(ammo_fabricator_status_label)

	var smelt_all_button := add_shop_button(fabricator_box, "Smelt All Bars", Callable(self, "smelt_all_bars"))
	smelt_all_button.disabled = not can_smelt_any_bars()
	var recipe_grid := GridContainer.new()
	recipe_grid.columns = 2
	recipe_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	recipe_grid.add_theme_constant_override("h_separation", 10)
	recipe_grid.add_theme_constant_override("v_separation", 10)
	fabricator_box.add_child(recipe_grid)
	for recipe_id in StartingPlanetBalance.FABRICATOR_RECIPES:
		var recipe: Dictionary = StartingPlanetBalance.FABRICATOR_RECIPES[recipe_id]
		var recipe_button := add_shop_button(
			recipe_grid,
			get_fabricator_recipe_button_text(recipe),
			Callable(self, "fabricate_recipe").bind(str(recipe_id))
		)
		recipe_button.custom_minimum_size = Vector2(310.0, 76.0)
		recipe_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		recipe_button.add_theme_font_size_override("font_size", 17)
		recipe_button.disabled = not can_fabricate_recipe(str(recipe_id))

	var load_row := HBoxContainer.new()
	load_row.add_theme_constant_override("separation", 10)
	fabricator_box.add_child(load_row)
	var load_one := add_shop_button(load_row, "Load 1", Callable(self, "load_explosive_charges_into_miner").bind(1))
	var load_ten := add_shop_button(load_row, "Load 10", Callable(self, "load_explosive_charges_into_miner").bind(10))
	var load_all := add_shop_button(load_row, "Load All", Callable(self, "load_explosive_charges_into_miner").bind(-1))
	var cannot_load := get_fabricated_explosive_charges() <= 0 or get_miner_explosive_charge_room() <= 0
	load_one.disabled = cannot_load
	load_ten.disabled = cannot_load
	load_all.disabled = cannot_load
	var load_markers := add_shop_button(
		fabricator_box,
		"Load All GPS Markers into Miner",
		Callable(self, "load_gps_markers_into_miner").bind(-1)
	)
	load_markers.disabled = int(cargo_hold_resources.get("GPS Marker", 0)) <= 0 or get_inventory_room() <= 0

	update_fabricator_material_icons()
	update_shop_ui()


func show_ammo_fabricator_view() -> void:
	# Compatibility entry point retained for existing developer controls and saves.
	show_fabricator_view()


func get_ammo_fabricator_status_text() -> String:
	var output_text := fabricator_status_message if not fabricator_status_message.is_empty() else "Output slot empty"
	if not fabricator_output.is_empty():
		output_text = "CARGO FULL — %s x%d is waiting in the fabricator." % [
			str(fabricator_output.get("resource", "Item")),
			int(fabricator_output.get("amount", 0)),
		]
	return "%s\nFabricated Charges: %d\nMiner Loaded Charges: %d / %d" % [
		output_text,
		get_fabricated_explosive_charges(),
		get_loaded_explosive_charges(),
		max_miner_explosive_charges,
	]


func get_fabricator_available_materials_text() -> String:
	var material_names: Array[String] = []
	for recipe: Dictionary in StartingPlanetBalance.FABRICATOR_RECIPES.values():
		for resource_name_value in recipe.get("inputs", {}).keys():
			var resource_name := str(resource_name_value)
			if not material_names.has(resource_name):
				material_names.append(resource_name)
	material_names.sort()
	var material_counts: Array[String] = []
	for resource_name in material_names:
		var count := get_total_resource_count(resource_name)
		if count > 0:
			material_counts.append("%s: %d" % [resource_name, count])
	return "AVAILABLE MATERIALS — MINER + LANDER\n%s" % (
		"  |  ".join(material_counts) if not material_counts.is_empty() else "No materials available"
	)


func get_fabricator_material_names() -> Array[String]:
	var material_names: Array[String] = []
	for recipe: Dictionary in StartingPlanetBalance.FABRICATOR_RECIPES.values():
		for resource_name_value in recipe.get("inputs", {}).keys():
			var resource_name := str(resource_name_value)
			if not material_names.has(resource_name):
				material_names.append(resource_name)
	material_names.sort()
	return material_names


func update_fabricator_material_icons() -> void:
	if fabricator_materials_list == null:
		return
	clear_children(fabricator_materials_list)
	var visible_count := 0
	for resource_name in get_fabricator_material_names():
		var count := get_total_resource_count(resource_name)
		if count <= 0:
			continue
		visible_count += 1
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		fabricator_materials_list.add_child(row)
		row.add_child(create_resource_icon(resource_name, Vector2(34.0, 34.0)))
		var count_label := Label.new()
		count_label.text = "%s  x%d" % [resource_name, count]
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 18)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 3)
		row.add_child(count_label)
	if visible_count == 0:
		var empty_label := Label.new()
		empty_label.text = "No materials available"
		empty_label.add_theme_font_size_override("font_size", 18)
		fabricator_materials_list.add_child(empty_label)


func get_fabricator_recipe_button_text(recipe: Dictionary) -> String:
	var input_parts: Array[String] = []
	for resource_name in recipe.get("inputs", {}):
		input_parts.append("%d %s" % [int(recipe["inputs"][resource_name]), str(resource_name)])
	return "%s\n%s -> %d %s" % [
		str(recipe.get("name", "Recipe")),
		" + ".join(input_parts),
		int(recipe.get("amount", 1)),
		str(recipe.get("output", "Item")),
	]


func can_fabricate_recipe(recipe_id: String) -> bool:
	if not fabricator_unlocked or not fabricator_output.is_empty():
		return false
	var recipe: Dictionary = StartingPlanetBalance.FABRICATOR_RECIPES.get(recipe_id, {})
	if recipe.is_empty():
		return false
	if (
		str(recipe.get("output", "")) == "Explosive Charge"
		and get_fabricated_explosive_charges() + int(recipe.get("amount", 1))
			> max_fabricated_explosive_charges
	):
		return false
	for resource_name in recipe.get("inputs", {}):
		if get_total_resource_count(str(resource_name)) < int(recipe["inputs"][resource_name]):
			return false
	return true


func fabricate_recipe(recipe_id: String) -> void:
	if not can_fabricate_recipe(recipe_id):
		refresh_lander_view_or_shop_ui()
		return
	fabricate_recipe_once(recipe_id)
	refresh_lander_view_or_shop_ui()
	update_hud()


func fabricate_recipe_once(recipe_id: String, refresh_open_ui: bool = true) -> bool:
	if not can_fabricate_recipe(recipe_id):
		return false
	var recipe: Dictionary = StartingPlanetBalance.FABRICATOR_RECIPES[recipe_id]
	for resource_name in recipe["inputs"]:
		consume_resource(str(resource_name), int(recipe["inputs"][resource_name]))
	fabricator_output = {
		"resource": str(recipe["output"]),
		"amount": int(recipe.get("amount", 1)),
	}
	record_progression_milestone("time_to_first_fabricated_component")
	try_transfer_fabricator_output(refresh_open_ui)
	return fabricator_output.is_empty()


func can_smelt_any_bars() -> bool:
	for recipe_id in ["copper_bar", "iron_bar", "gold_bar"]:
		if can_fabricate_recipe(recipe_id):
			return true
	return false


func smelt_all_bars() -> void:
	var crafted_any := false
	for recipe_id in ["copper_bar", "iron_bar", "gold_bar"]:
		var safety_count := 0
		while can_fabricate_recipe(recipe_id) and safety_count < 10000:
			safety_count += 1
			if not fabricate_recipe_once(recipe_id, false):
				break
			crafted_any = true
	if crafted_any:
		fabricator_status_message = "All available ore smelted into stacked bars."
	refresh_lander_view_or_shop_ui()
	update_hud()


func try_transfer_fabricator_output(refresh_open_ui: bool = true) -> bool:
	if fabricator_output.is_empty():
		return false
	var amount := int(fabricator_output.get("amount", 0))
	if amount <= 0:
		fabricator_output.clear()
		return false
	if get_cargo_hold_room() < amount:
		fabricator_status_message = "CARGO FULL"
		return false
	var resource_name := str(fabricator_output.get("resource", "Item"))
	cargo_hold_resources[resource_name] = int(cargo_hold_resources.get(resource_name, 0)) + amount
	fabricator_output.clear()
	fabricator_status_message = "%s transferred to cargo." % resource_name
	if is_shop_open and refresh_open_ui:
		update_shop_ui()
	return true


func initialize_upgrade_definitions() -> void:
	upgrade_definitions = {
		"Drill Assembly": [
			make_upgrade("miner_drill_efficiency", "Drill Efficiency", [{"resource": "Copper", "amount": 3}], "Mining power increases 20% per level."),
			make_upgrade("miner_drill_yield", "Drill Yield", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 1}], "Alternately raises each ore's minimum and maximum yield per level."),
		],
		"Power Unit": [
			make_upgrade("miner_power_unit_output", "Power Output", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}], "Electrical power generation increases 20% per level."),
			make_upgrade("miner_power_unit_efficiency", "Power Efficiency", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Mining fuel use is divided by 1.20 per level."),
		],
		"Mobility System": [
			make_upgrade("miner_mobility_max_speed", "Maximum Speed", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}], "Horizontal speed increases 20% and mobility power draw increases 6% per level."),
			make_upgrade("miner_mobility_acceleration", "Acceleration", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 1}], "Directional response increases 20% and mobility power draw increases 6% per level."),
			make_upgrade("miner_mobility_vertical_climb", "Vertical Climb Speed", [{"resource": "Copper", "amount": 2}, {"resource": "Gold", "amount": 1}], "Vertical thrust/climb speed increases 20% and mobility power draw increases 6% per level."),
			make_upgrade("miner_mobility_kinetic_efficiency", "Kinetic Efficiency", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}], "Mobility power use is divided by 1.20 per level."),
		],
		"Fuel Cell": [
			make_upgrade("miner_fuel_cell_capacity", "Capacity", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}], "Mining fuel capacity increases 20% per level."),
		],
		"Cargo Capacity": [
			make_upgrade("miner_cargo_capacity", "Cargo Capacity", [{"resource": "Iron", "amount": 3}], "Miner cargo capacity increases 20% per level."),
		],
		"Thermal Management": [
			make_upgrade("miner_thermal_heat_dispersion", "Heat Dispersion", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}], "Passive heat dissipation increases 20% per level."),
		],
		"Life Support": [
			make_upgrade("miner_life_support_efficiency", "Efficiency", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 1}], "Life Support power use is divided by 1.20 per level."),
			make_upgrade("miner_life_support_tolerance", "Tolerance", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}], "Reserved for future environmental tolerance mechanics."),
		],
		"Shield Generator": [
			make_upgrade("miner_shield_capacity", "Capacity", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}], "Maximum shield HP increases 20% per level."),
			make_upgrade("miner_shield_recharge_delay", "Recharge Delay", [{"resource": "Copper", "amount": 2}, {"resource": "Gold", "amount": 1}], "Shield recharge delay is divided by 1.20 per level."),
			make_upgrade("miner_shield_recharge_rate", "Recharge Rate", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}], "Shield regeneration rate increases 20% per level."),
			make_upgrade("miner_shield_efficiency", "Efficiency", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}], "Shield power use is divided by 1.20 per level."),
		],
		"Structural Frame": [
			make_upgrade("miner_structural_integrity", "Maximum Integrity", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}, {"resource": "Credits", "amount": 10}], "Maximum hull HP increases 20% per level."),
			make_upgrade("miner_structural_armor", "Armor", [{"resource": "Iron", "amount": 3}, {"resource": "Gold", "amount": 1}], "Adds 1 plus 20% of current armor per level, rounded."),
		],
		"Capacitor Bank": [
			make_upgrade("miner_capacitor_capacity", "Capacity", [{"resource": "Copper", "amount": 3}, {"resource": "Gold", "amount": 1}], "Capacitor storage increases 20% per level."),
		],
		"Weapon Systems": [
			make_upgrade("miner_weapon_damage", "Damage", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}], "Weapon damage increases 20% per level."),
			make_upgrade("miner_weapon_efficiency", "Efficiency", [{"resource": "Copper", "amount": 2}, {"resource": "Gold", "amount": 1}], "Capacitor energy per shot is divided by 1.20 per level."),
			make_upgrade("miner_weapon_rate_of_fire", "Rate of Fire", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}], "Weapon rate of fire increases 20% per level."),
			make_upgrade("miner_weapon_critical_chance", "Critical Strike Chance", [{"resource": "Gold", "amount": 2}, {"resource": "Credits", "amount": 10}], "Critical strike chance increases 2 percentage points per level; criticals deal 200% final damage."),
		],
		"Sensor Suite": [
			make_upgrade("miner_sensor_strength", "Sensor Strength", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Five milestones alternate visibility and hidden-ore detection."),
		],
		"Lander": [
			make_upgrade("lander_cargo_capacity", "Cargo Capacity", [{"resource": "Iron", "amount": 2}, {"resource": "Credits", "amount": 10}], "Lander storage increases 20% per level."),
			make_upgrade("lander_fuel_storage_capacity", "Fuel Storage Capacity", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Lander fuel storage increases 20% per level."),
			make_upgrade("lander_ore_transfer_rate", "Ore Transfer Rate", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Ore transfer speed increases 20% per level."),
			make_upgrade("lander_fuel_plant_speed", "Fuel Plant Speed", [{"resource": "Copper", "amount": 2}, {"resource": "Raw Fuel", "amount": 1}, {"resource": "Credits", "amount": 10}], "Fuel processing speed increases 20% per level."),
			make_upgrade("lander_fuel_plant_efficiency", "Fuel Plant Efficiency", [{"resource": "Iron", "amount": 1}, {"resource": "Raw Fuel", "amount": 2}, {"resource": "Credits", "amount": 10}], "Fuel output improves 20% per level."),
			make_upgrade("lander_repair_station", "Repair Station", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}, {"resource": "Credits", "amount": 10}], "Repair strength improves 20% per level."),
			make_upgrade("lander_upgrade_station", "Upgrade Station", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}, {"resource": "Credits", "amount": 10}], "Upgrade station capability improves 20% per level."),
		],
		"Planetary Upgrades": [
			make_upgrade("planetary_fuel_depot", "Fuel Depot", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Raw Fuel", "amount": 1}, {"resource": "Credits", "amount": 10}], "Builds a +20 ton rocket fuel depot next to the lander.", 1),
		],
		"Starship": [
			make_upgrade("starship_fuel_capacity", "Fuel Capacity", [{"resource": "Copper", "amount": 2}, {"resource": "Raw Fuel", "amount": 2}, {"resource": "Credits", "amount": 10}], "Starship fuel capacity increases 20% per level."),
			make_upgrade("starship_ltl_drive_performance", "LTL Drive Performance", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "LTL drive performance increases 20% per level."),
			make_upgrade("starship_ftl_drive_performance", "FTL Drive Performance", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}, {"resource": "Credits", "amount": 10}], "FTL drive performance increases 20% per level."),
			make_upgrade("starship_sensor_range", "Sensor Range", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Starship sensor range increases 20% per level."),
			make_upgrade("starship_hull_strength", "Hull Strength", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}, {"resource": "Credits", "amount": 10}], "Starship hull strength increases 20% per level."),
			make_upgrade("starship_modification", "Modification", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}, {"resource": "Credits", "amount": 10}], "Future module panel placeholder."),
		],
		"Global": [
			make_upgrade("global_market_rates", "Market Rates", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Future sell-price bonus placeholder."),
			make_upgrade("global_mining_data", "Mining Data", [{"resource": "Copper", "amount": 1}, {"resource": "Credits", "amount": 10}], "Future asteroid intel placeholder."),
			make_upgrade("global_fleet_logistics", "Fleet Logistics", [{"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Future shared capacity placeholder."),
		],
	}


func initialize_upgrade_stat_rules() -> void:
	# Standard numeric upgrades are data-driven so new tiers/categories do not require UI changes.
	upgrade_stat_rules = {
		"miner_drill_efficiency": [stat_rule("drill_damage_per_second", StartingPlanetBalance.MK1_STAT_MULTIPLIER)],
		"miner_cargo_capacity": [stat_rule("inventory_capacity", StartingPlanetBalance.MK1_STAT_MULTIPLIER, true)],
		"miner_power_unit_output": [stat_rule("engine_charge_per_second", StartingPlanetBalance.MK1_STAT_MULTIPLIER, false, true)],
		"miner_power_unit_efficiency": [stat_rule("fuel_consumption_multiplier", StartingPlanetBalance.MK1_REDUCTION_MULTIPLIER)],
		"miner_mobility_max_speed": [
			stat_rule("move_speed", StartingPlanetBalance.MK1_STAT_MULTIPLIER),
			stat_rule("mobility_power_consumption_per_second", 1.06, false, true),
		],
		"miner_mobility_acceleration": [
			stat_rule("ground_acceleration", StartingPlanetBalance.MK1_STAT_MULTIPLIER),
			stat_rule("ground_deceleration", StartingPlanetBalance.MK1_STAT_MULTIPLIER),
			stat_rule("air_acceleration", StartingPlanetBalance.MK1_STAT_MULTIPLIER),
			stat_rule("air_deceleration", StartingPlanetBalance.MK1_STAT_MULTIPLIER),
			stat_rule("mobility_power_consumption_per_second", 1.06, false, true),
		],
		"miner_mobility_vertical_climb": [
			stat_rule("upward_thrust", StartingPlanetBalance.MK1_STAT_MULTIPLIER),
			stat_rule("max_rise_speed", StartingPlanetBalance.MK1_STAT_MULTIPLIER),
			stat_rule("mobility_power_consumption_per_second", 1.06, false, true),
		],
		"miner_mobility_kinetic_efficiency": [stat_rule("mobility_power_consumption_per_second", StartingPlanetBalance.MK1_REDUCTION_MULTIPLIER, false, true)],
		"miner_fuel_cell_capacity": [stat_rule("max_fuel_seconds", StartingPlanetBalance.MK1_STAT_MULTIPLIER)],
		"miner_thermal_heat_dispersion": [stat_rule("heat_cooling_per_second", StartingPlanetBalance.MK1_STAT_MULTIPLIER)],
		"miner_life_support_efficiency": [stat_rule("life_support_power_per_second", StartingPlanetBalance.MK1_REDUCTION_MULTIPLIER, false, true)],
		"miner_shield_capacity": [stat_rule("max_shield_health", StartingPlanetBalance.MK1_STAT_MULTIPLIER)],
		"miner_shield_recharge_delay": [stat_rule("shield_recharge_delay_seconds", StartingPlanetBalance.MK1_REDUCTION_MULTIPLIER)],
		"miner_shield_recharge_rate": [stat_rule("shield_recharge_hp_per_second", StartingPlanetBalance.MK1_STAT_MULTIPLIER)],
		"miner_shield_efficiency": [
			stat_rule("shield_energy_per_second", StartingPlanetBalance.MK1_REDUCTION_MULTIPLIER, false, true),
			stat_rule("shield_hp_per_energy", StartingPlanetBalance.MK1_STAT_MULTIPLIER),
		],
		"miner_structural_integrity": [stat_rule("max_hull_health", StartingPlanetBalance.MK1_STAT_MULTIPLIER, true)],
		"miner_capacitor_capacity": [stat_rule("capacitor_capacity", StartingPlanetBalance.MK1_STAT_MULTIPLIER, false, true)],
		"miner_weapon_damage": [stat_rule("laser_damage", StartingPlanetBalance.MK1_STAT_MULTIPLIER)],
		"miner_weapon_efficiency": [stat_rule("laser_energy_per_shot", StartingPlanetBalance.MK1_REDUCTION_MULTIPLIER, false, true)],
		"miner_weapon_rate_of_fire": [stat_rule("laser_shots_per_second", StartingPlanetBalance.MK1_STAT_MULTIPLIER)],
		"lander_fuel_storage_capacity": [
			stat_rule("max_lander_mining_fuel_kg", StartingPlanetBalance.MK1_STAT_MULTIPLIER, true),
			stat_rule("max_lander_rocket_fuel_tons", StartingPlanetBalance.MK1_STAT_MULTIPLIER, true),
		],
		"lander_cargo_capacity": [stat_rule("cargo_hold_capacity", StartingPlanetBalance.MK1_STAT_MULTIPLIER, true)],
	}


func stat_rule(
	property_name: String,
	multiplier: float,
	ceil_each_level: bool = false,
	round_each_level: bool = false
) -> Dictionary:
	return {
		"property": property_name,
		"multiplier": multiplier,
		"ceil_each_level": ceil_each_level,
		"round_each_level": round_each_level,
	}


func make_upgrade(upgrade_id: String, upgrade_name: String, base_costs: Array, description: String, max_level: int = StartingPlanetBalance.MK1_MAX_LEVEL) -> Dictionary:
	return {
		"id": upgrade_id,
		"name": upgrade_name,
		"base_costs": base_costs,
		"description": description,
		"max_level": max_level,
	}


func get_upgrade_costs(definition: Dictionary, level: int) -> Array:
	var costs: Array = []
	var upgrade_id := String(definition.get("id", ""))
	for base_cost in definition["base_costs"]:
		var resource_name := get_upgrade_cost_resource_name(
			upgrade_id,
			String(base_cost["resource"]),
			level
		)
		var base_amount: int = int(base_cost["amount"])
		var amount := base_amount + level
		if resource_name == "Credits":
			amount = base_amount * (level + 1)
		else:
			amount = (base_amount + level) * upgrade_resource_cost_scale
		costs.append({"resource": resource_name, "amount": amount})
	return costs


func get_upgrade_cost_resource_name(upgrade_id: String, resource_name: String, level: int) -> String:
	var is_first_starter_upgrade := (
		level == 0
		and upgrade_id == "miner_sensor_strength"
	)
	if is_first_starter_upgrade:
		return resource_name
	match resource_name:
		"Copper":
			return "Copper Bar"
		"Iron":
			return "Iron Bar"
		"Gold":
			return "Gold Bar"
		_:
			return resource_name


func format_upgrade_effect(definition: Dictionary, level: int) -> String:
	var max_level: int = int(definition.get("max_level", StartingPlanetBalance.MK1_MAX_LEVEL))
	if level >= max_level:
		return "Max level reached"
	var description := String(definition["description"])
	description = description.replace(" increases ", " +")
	description = description.replace(" improves ", " +")
	description = description.replace(" per level.", " / level")
	description = description.replace("Placeholder ", "")
	description = description.replace("Future ", "")
	return description


func format_upgrade_costs(costs: Array) -> String:
	var parts: Array[String] = []
	for cost in costs:
		parts.append("%d %s" % [int(cost["amount"]), String(cost["resource"])])
	return "Cost: %s" % " + ".join(parts)


func can_afford_upgrade(costs: Array) -> bool:
	for cost in costs:
		var resource_name: String = String(cost["resource"])
		var amount: int = int(cost["amount"])
		if resource_name == "Credits":
			if credits < amount:
				return false
		elif get_total_resource_count(resource_name) < amount:
			return false
	return true


func pay_upgrade_costs(costs: Array) -> void:
	for cost in costs:
		var resource_name: String = String(cost["resource"])
		var amount: int = int(cost["amount"])
		if resource_name == "Credits":
			credits -= amount
		else:
			consume_resource(resource_name, amount)


func _on_upgrade_pressed(category_name: String, upgrade_id: String) -> void:
	var definition := get_upgrade_definition(category_name, upgrade_id)
	if definition.is_empty():
		return
	
	var level: int = int(upgrade_levels.get(upgrade_id, 0))
	var max_level: int = int(definition.get("max_level", StartingPlanetBalance.MK1_MAX_LEVEL))
	if level >= max_level:
		return
	
	var costs := get_upgrade_costs(definition, level)
	if not can_afford_upgrade(costs):
		update_shop_ui()
		show_upgrade_grid_view(category_name)
		return
	
	pay_upgrade_costs(costs)
	upgrade_levels[upgrade_id] = level + 1
	apply_upgrade_effect(upgrade_id, level + 1)
	record_progression_milestone("time_to_first_upgrade")
	if upgrade_id == "miner_sensor_strength":
		record_progression_milestone("time_to_sensor_level_1")
	unlock_fabricator_after_first_upgrade()
	show_upgrade_grid_view(category_name)
	update_hud()


func get_upgrade_definition(category_name: String, upgrade_id: String) -> Dictionary:
	var category_upgrades: Array = upgrade_definitions.get(category_name, [])
	for definition in category_upgrades:
		if String(definition["id"]) == upgrade_id:
			return definition
	return {}


func find_upgrade_definition(upgrade_id: String) -> Dictionary:
	for category_name in upgrade_definitions:
		var definition := get_upgrade_definition(category_name, upgrade_id)
		if not definition.is_empty():
			return definition
	return {}


func capture_base_upgrade_stats() -> void:
	base_upgrade_stats.clear()
	for rules in upgrade_stat_rules.values():
		for rule in rules:
			var property_name: String = rule["property"]
			if not base_upgrade_stats.has(property_name):
				base_upgrade_stats[property_name] = get(property_name)
	base_upgrade_stats["reveal_radius_tiles"] = reveal_radius_tiles
	base_upgrade_stats["armor_rating"] = armor_rating
	base_upgrade_stats["weapon_critical_chance"] = weapon_critical_chance


func apply_upgrade_effect(_upgrade_id: String, _new_level: int) -> void:
	recalculate_stats_from_upgrade_levels()


func recalculate_stats_from_upgrade_levels() -> void:
	if base_upgrade_stats.is_empty():
		return

	var old_max_fuel := max_fuel_seconds
	var old_max_hull := max_hull_health
	var old_max_shield := max_shield_health
	var old_capacitor_capacity := capacitor_capacity
	for property_name in base_upgrade_stats:
		set(property_name, base_upgrade_stats[property_name])

	for upgrade_id in upgrade_stat_rules:
		var level := int(upgrade_levels.get(upgrade_id, 0))
		for rule in upgrade_stat_rules[upgrade_id]:
			apply_upgrade_stat_rule(rule, level)

	var sensor_level := get_sensor_level()
	reveal_radius_tiles = StartingPlanetBalance.get_visible_radius(sensor_level)
	armor_rating = get_compounded_armor_value(
		int(base_upgrade_stats["armor_rating"]),
		int(upgrade_levels.get("miner_structural_armor", 0))
	)
	weapon_critical_chance = clampf(
		float(base_upgrade_stats["weapon_critical_chance"])
		+ 0.02 * float(upgrade_levels.get("miner_weapon_critical_chance", 0)),
		0.0,
		1.0
	)

	sync_fuel_depot_with_upgrade_level()
	if max_fuel_seconds > old_max_fuel:
		fuel_seconds += max_fuel_seconds - old_max_fuel
	if max_hull_health > old_max_hull:
		hull_health += max_hull_health - old_max_hull
	if max_shield_health > old_max_shield:
		shield_health += max_shield_health - old_max_shield
	if capacitor_capacity > old_capacitor_capacity:
		capacitor_energy += capacitor_capacity - old_capacitor_capacity
	fuel_seconds = clampf(fuel_seconds, 0.0, max_fuel_seconds)
	hull_health = clampi(hull_health, 0, max_hull_health)
	shield_health = clampf(shield_health, 0.0, max_shield_health)
	capacitor_energy = clampf(capacitor_energy, 0.0, capacitor_capacity)
	lander_mining_fuel_kg = mini(lander_mining_fuel_kg, max_lander_mining_fuel_kg)
	lander_rocket_fuel_tons = mini(lander_rocket_fuel_tons, max_lander_rocket_fuel_tons)
	update_revealed_cells()
	rebuild_fuel_bar_segments()


func apply_upgrade_stat_rule(rule: Dictionary, level: int) -> void:
	var property_name: String = rule["property"]
	var multiplier: float = rule["multiplier"]
	if rule.get("ceil_each_level", false):
		set(property_name, get_compounded_ceil_value(int(get(property_name)), level, multiplier))
	elif rule.get("round_each_level", false):
		set(property_name, float(get_compounded_round_value(int(get(property_name)), level, multiplier)))
	else:
		set(property_name, float(get(property_name)) * pow(multiplier, level))


func get_compounded_ceil_value(base_value: int, level: int, multiplier: float) -> int:
	var result := base_value
	for _step in level:
		result = ceili(float(result) * multiplier)
	return result


func get_compounded_round_value(base_value: int, level: int, multiplier: float) -> int:
	var result := base_value
	for _step in level:
		result = roundi(float(result) * multiplier)
	return result


func get_compounded_armor_value(base_value: int, level: int) -> int:
	var result := base_value
	for _step in level:
		result = roundi(float(result) * StartingPlanetBalance.MK1_STAT_MULTIPLIER + 1.0)
	return result


func migrate_legacy_upgrade_ids() -> void:
	var legacy_ids := {
		"miner_fuel_tank": "miner_fuel_cell_capacity",
		"miner_engine_power": "miner_power_unit_output",
		"miner_engine_efficiency": "miner_power_unit_efficiency",
		"miner_hull_strength": "miner_structural_integrity",
	}
	for old_id in legacy_ids:
		if not upgrade_levels.has(old_id):
			continue
		var new_id: String = legacy_ids[old_id]
		upgrade_levels[new_id] = maxi(
			int(upgrade_levels.get(new_id, 0)),
			int(upgrade_levels.get(old_id, 0))
		)
		upgrade_levels.erase(old_id)


func clamp_upgrade_levels_to_current_caps() -> void:
	# Alpha saves preserve terrain, but obsolete ten-level progression is intentionally
	# reduced to the current component cap instead of attempting an economy refund.
	for upgrade_id in upgrade_levels.keys():
		var definition := find_upgrade_definition(str(upgrade_id))
		if definition.is_empty():
			upgrade_levels.erase(upgrade_id)
			continue
		upgrade_levels[upgrade_id] = clampi(
			int(upgrade_levels[upgrade_id]),
			0,
			int(definition.get("max_level", StartingPlanetBalance.MK1_MAX_LEVEL))
		)


func migrate_saved_capacitor_energy(saved_energy: float, saved_power_scale_version: int) -> float:
	if saved_power_scale_version < POWER_SCALE_VERSION:
		return saved_energy * LEGACY_POWER_SCALE_MULTIPLIER
	return saved_energy


func get_refuel_button_text() -> String:
	var needed_kg := get_mining_fuel_kg_needed_for_full_refuel()
	var tank_status := "Tank: %d / %d kg" % [
		get_current_miner_fuel_kg(),
		get_miner_fuel_tank_capacity_kg(),
	]
	if lander_mining_fuel_kg > 0:
		return "Refuel\n%d kg Mining Fuel\n%s" % [
			mini(needed_kg, lander_mining_fuel_kg),
			tank_status,
		]
	return "Refuel\n%d Credits\n%s" % [
		get_emergency_refuel_credit_cost(needed_kg),
		tank_status,
	]


func get_miner_fuel_tank_capacity_kg() -> int:
	return ceili(max_fuel_seconds / maxf(mining_fuel_seconds_per_kg, 0.001))


func get_current_miner_fuel_kg() -> int:
	return clampi(
		floori(fuel_seconds / maxf(mining_fuel_seconds_per_kg, 0.001)),
		0,
		get_miner_fuel_tank_capacity_kg()
	)


func get_missing_hull_health() -> int:
	return maxi(max_hull_health - hull_health, 0)


func get_full_hull_repair_credit_cost() -> int:
	return get_missing_hull_health() * maxi(hull_repair_credit_cost_per_hp, 0)


func get_repair_hull_button_text() -> String:
	var missing_health := get_missing_hull_health()
	if missing_health <= 0:
		return "Repair Ship Hull\nHull at 100 HP"
	return "Repair Ship Hull\n+%d HP / %d Credits" % [
		missing_health,
		get_full_hull_repair_credit_cost(),
	]


func can_afford_full_hull_repair() -> bool:
	return get_missing_hull_health() > 0 and credits >= get_full_hull_repair_credit_cost()


func _on_repair_hull_pressed() -> void:
	if not can_afford_full_hull_repair():
		update_shop_ui()
		return
	credits -= get_full_hull_repair_credit_cost()
	hull_health = max_hull_health
	update_shop_ui()
	update_hud()


func fill_lander_mining_fuel_from_starship() -> void:
	var lander_fuel_room: int = maxi(max_lander_mining_fuel_kg - lander_mining_fuel_kg, 0)
	var transfer_kg: int = mini(lander_fuel_room, starship_mining_fuel_kg)
	
	if transfer_kg <= 0:
		return
	
	lander_mining_fuel_kg += transfer_kg
	starship_mining_fuel_kg -= transfer_kg


func open_shop() -> void:
	is_shop_open = true
	is_paused = true
	reset_mining_progress()
	player_velocity = Vector2.ZERO
	shop_panel.visible = true
	show_shop_main_view()
	update_shop_ui()
	update_hud()


func close_shop() -> void:
	is_shop_open = false
	is_shop_reentry_locked = true
	is_paused = false
	shop_panel.visible = false
	update_hud()


func handle_shop_back() -> void:
	if not is_shop_open:
		return
	if shop_back_callback.is_valid():
		shop_back_callback.call()
	else:
		close_shop()


func update_shop_ui() -> void:
	if shop_status_label == null:
		return

	SeedManager.update_starting_escape_fuel(
		lander_rocket_fuel_tons,
		return_to_starship_required_rocket_fuel_tons
	)
	update_shop_master_tabs()
	update_shop_stat_cards()
	
	var refuel_kg := get_mining_fuel_kg_needed_for_full_refuel()
	if refuel_button != null:
		refuel_button.text = get_refuel_button_text()
		refuel_button.disabled = (
			refuel_kg <= 0
			or (lander_mining_fuel_kg <= 0 and credits < emergency_refuel_credit_cost_per_kg)
		)

	if repair_hull_button != null:
		repair_hull_button.text = get_repair_hull_button_text()
		repair_hull_button.disabled = not can_afford_full_hull_repair()
	
	if return_to_starship_status_label != null:
		return_to_starship_status_label.text = get_return_to_starship_status_text()
	
	if return_to_starship_button != null:
		return_to_starship_button.disabled = (
			lander_rocket_fuel_tons < return_to_starship_required_rocket_fuel_tons
		)
	
	if fuel_processing_status_label != null:
		fuel_processing_status_label.text = get_fuel_processing_status_text()

	if ammo_fabricator_status_label != null:
		ammo_fabricator_status_label.text = get_ammo_fabricator_status_text()
		ammo_fabricator_status_label.add_theme_color_override(
			"font_color",
			Color(1.0, 0.24, 0.18, 1.0) if not fabricator_output.is_empty() else Color(0.9, 0.95, 1.0, 1.0)
		)
	if fabricator_available_materials_label != null:
		fabricator_available_materials_label.text = get_fabricator_available_materials_text()
	update_fabricator_material_icons()
	
	if treasure_processing_status_label != null:
		treasure_processing_status_label.text = get_treasure_processing_status_text()
	
	shop_status_label.text = (
		"Credits: %d   Hull: %d / %d HP   Cargo: %d / %d   Cargo Hold: %d / %d units\nMining Fuel: %d / %d kg   Rocket Fuel: %d / %d tons   Starship Mining Fuel: %d / %d kg"
		% [
			credits,
			hull_health,
			max_hull_health,
			get_inventory_count(),
			inventory_capacity,
			get_cargo_hold_count(),
			cargo_hold_capacity,
			lander_mining_fuel_kg,
			max_lander_mining_fuel_kg,
			lander_rocket_fuel_tons,
			max_lander_rocket_fuel_tons,
			starship_mining_fuel_kg,
			max_starship_mining_fuel_kg
		]
	)
	update_lander_cargo_hold_list()


func update_shop_master_tabs() -> void:
	if shop_master_tabs == null:
		return
	for child in shop_master_tabs.get_children():
		if not child is Button:
			continue
		var button := child as Button
		if button.name == "MasterFabricatorTab":
			button.disabled = not fabricator_unlocked


func update_shop_stat_cards() -> void:
	if shop_stat_labels.is_empty():
		return
	(shop_stat_labels.get("credits") as Label).text = "Credits\n%d" % credits
	(shop_stat_labels.get("hull") as Label).text = "Hull\n%d / %d" % [hull_health, max_hull_health]
	(shop_stat_labels.get("miner_cargo") as Label).text = "Miner\n%d / %d" % [get_inventory_count(), inventory_capacity]
	(shop_stat_labels.get("lander_cargo") as Label).text = "Lander\n%d / %d" % [get_cargo_hold_count(), cargo_hold_capacity]
	(shop_stat_labels.get("mining_fuel") as Label).text = "Mining Fuel\n%d / %d kg" % [lander_mining_fuel_kg, max_lander_mining_fuel_kg]
	(shop_stat_labels.get("rocket_fuel") as Label).text = "Rocket Fuel\n%d / %d t" % [lander_rocket_fuel_tons, max_lander_rocket_fuel_tons]
	(shop_stat_labels.get("starship_fuel") as Label).text = "Ship Fuel\n%d / %d kg" % [starship_mining_fuel_kg, max_starship_mining_fuel_kg]


func get_return_to_starship_status_text() -> String:
	if SeedManager.is_starting_scenario_active():
		var objective_status := (
			"Escape fuel ready — return to the Starship"
			if can_return_to_starship()
			else "Planet Core required before departure"
			if lander_rocket_fuel_tons >= return_to_starship_required_rocket_fuel_tons
			else "Stranded — process rocket fuel to escape"
		)
		return "Rocket Fuel: %d / %d tons required\nPlanet Core: %s\n%s" % [
			lander_rocket_fuel_tons,
			return_to_starship_required_rocket_fuel_tons,
			"secured" if has_planet_core() else "still buried",
			objective_status,
		]

	return "Rocket Fuel: %d / %d tons required\nPlanet Core: %s" % [
		lander_rocket_fuel_tons,
		return_to_starship_required_rocket_fuel_tons,
		"secured" if has_planet_core() else "required",
	]


func refresh_lander_view_or_shop_ui() -> void:
	if is_shop_open and shop_title_label != null and shop_title_label.text == "Lander":
		show_market_view()
	elif is_shop_open and shop_title_label != null and shop_title_label.text == "Lander Fabricator":
		show_fabricator_view()
	else:
		update_shop_ui()


func update_lander_cargo_hold_list() -> void:
	if lander_cargo_hold_list == null:
		return
	
	clear_children(lander_cargo_hold_list)
	
	var has_resources := false
	for resource_name in get_cargo_display_resource_names(cargo_hold_resources):
		var count: int = int(cargo_hold_resources.get(resource_name, 0))
		if count <= 0:
			continue
		
		has_resources = true
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(650.0, 56.0)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		lander_cargo_hold_list.add_child(row)
		
		row.add_child(create_resource_icon(resource_name, Vector2(36.0, 36.0)))
		
		var label := Label.new()
		label.text = "%s x%d" % [resource_name, count]
		label.custom_minimum_size.x = 190.0
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		row.add_child(label)

		var price_label := Label.new()
		price_label.custom_minimum_size.x = 110.0
		price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price_label.add_theme_font_size_override("font_size", 14)
		if get_resource_value(resource_name) > 0:
			price_label.text = "%d credits each" % get_current_resource_sale_price(resource_name)
		else:
			price_label.text = "Not for sale"
		row.add_child(price_label)

		if get_resource_value(resource_name) > 0:
			add_compact_sell_button(
				row,
				"1\n+%d" % get_resource_sale_quote(resource_name, 1),
				Callable(self, "sell_resource").bind(resource_name, 1)
			)
			var ten_amount := mini(count, 10)
			add_compact_sell_button(
				row,
				"%d\n+%d" % [ten_amount, get_resource_sale_quote(resource_name, ten_amount)],
				Callable(self, "sell_resource").bind(resource_name, 10)
			)
			add_compact_sell_button(
				row,
				"All\n+%d" % get_resource_sale_quote(resource_name, count),
				Callable(self, "sell_resource").bind(resource_name, -1)
			)
	
	if not has_resources:
		var empty_label := Label.new()
		empty_label.text = "Empty"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 15)
		lander_cargo_hold_list.add_child(empty_label)


func get_resource_list_text(source: Dictionary) -> String:
	var lines: Array[String] = []
	
	for resource_name in get_cargo_display_resource_names(source):
		var count: int = int(source.get(resource_name, 0))
		if count > 0:
			lines.append("%s: %d" % [resource_name, count])
	
	if lines.is_empty():
		lines.append("Empty")
	
	return "\n".join(lines)


func get_drill_upgrade_text() -> String:
	if has_copper_drill_upgrade:
		return "Copper Drill: purchased"
	
	return "Copper Drill: 20 Credits + 5 Copper (+25% drill damage)"


func get_sensor_upgrade_text() -> String:
	if has_sensor_upgrade:
		return "Sensors: purchased"
	
	return "Sensors: 15 Credits + 1 Copper + 1 Iron (vision radius 2)"


func get_sellable_resource_names() -> Array[String]:
	return [
		"Silicone",
		"Copper",
		"Copper Bar",
		"Raw Fuel",
		"Iron",
		"Iron Bar",
		"Gold",
		"Gold Bar",
		"Treasure",
		"Diamond",
		"Warp Gems",
		"Black Hole Crystals",
		"Planet Core",
		"Silicone Wafer",
		"Explosive Charge",
	]


func get_fabricated_resource_names() -> Array[String]:
	return [
		"Copper Bar",
		"Iron Bar",
		"Gold Bar",
		"Silicone Wafer",
		"Copper Wire",
		"Iron Wire",
		"Basic Circuit",
		"Explosive Charge",
		"GPS Marker",
	]


func get_cargo_display_resource_names(source: Dictionary) -> Array[String]:
	var resource_names: Array[String] = []
	for registered_name in get_sellable_resource_names() + get_fabricated_resource_names():
		if not resource_names.has(registered_name):
			resource_names.append(registered_name)
	for resource_name_value in source.keys():
		var resource_name := str(resource_name_value)
		if not resource_names.has(resource_name):
			resource_names.append(resource_name)
	return resource_names


func add_compact_sell_button(parent: Control, text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(70.0, 48.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.pressed.connect(callback)
	parent.add_child(button)
	apply_individual_sell_button_style(button)
	return button


func sell_resource(resource_name: String, requested_amount: int = 1) -> void:
	if get_resource_value(resource_name) <= 0:
		return
	var lander_count: int = int(cargo_hold_resources.get(resource_name, 0))
	
	if lander_count <= 0:
		return

	var amount_to_sell := lander_count if requested_amount < 0 else mini(lander_count, maxi(requested_amount, 0))
	if amount_to_sell <= 0:
		return

	credits += get_resource_sale_quote(resource_name, amount_to_sell)
	record_resource_sale(resource_name, amount_to_sell)
	cargo_hold_resources[resource_name] = lander_count - amount_to_sell
	refresh_lander_view_or_shop_ui()
	update_hud()


func get_current_resource_sale_price(resource_name: String, additional_pressure: float = 0.0) -> int:
	var base_price := get_resource_value(resource_name)
	if base_price <= 0:
		return 0
	var pressure := maxf(float(recent_resource_sales.get(resource_name, 0.0)) + additional_pressure, 0.0)
	var price_ratio := maxf(
		market_minimum_price_ratio,
		1.0 / (1.0 + pressure / maxf(market_pressure_scale, 1.0))
	)
	return maxi(roundi(float(base_price) * price_ratio), 1)


func get_resource_sale_quote(resource_name: String, amount: int) -> int:
	var quote := 0
	for sold_index in maxi(amount, 0):
		quote += get_current_resource_sale_price(resource_name, float(sold_index))
	return quote


func get_sell_all_quote() -> int:
	var quote := 0
	for resource_name in get_sellable_resource_names():
		quote += get_resource_sale_quote(
			resource_name,
			int(cargo_hold_resources.get(resource_name, 0))
		)
	return quote


func record_resource_sale(resource_name: String, amount: int) -> void:
	if amount <= 0:
		return
	recent_resource_sales[resource_name] = float(recent_resource_sales.get(resource_name, 0.0)) + float(amount)


func update_market_pressure(delta: float) -> void:
	if is_shop_open:
		return
	var recovery := delta / maxf(market_pressure_recovery_seconds_per_unit, 0.001)
	if recovery <= 0.0:
		return
	for resource_name in recent_resource_sales.keys():
		var remaining := maxf(float(recent_resource_sales[resource_name]) - recovery, 0.0)
		if remaining <= 0.001:
			recent_resource_sales.erase(resource_name)
		else:
			recent_resource_sales[resource_name] = remaining


func deposit_resource(resource_name: String) -> void:
	var count: int = int(resources.get(resource_name, 0))
	
	if count <= 0:
		return
	
	var amount_to_deposit: int = mini(count, get_cargo_hold_room())
	if amount_to_deposit <= 0:
		refresh_lander_view_or_shop_ui()
		update_hud()
		return
	
	cargo_hold_resources[resource_name] = int(cargo_hold_resources.get(resource_name, 0)) + amount_to_deposit
	resources[resource_name] = count - amount_to_deposit
	refresh_lander_view_or_shop_ui()
	update_hud()


func process_raw_fuel_from_storage() -> void:
	if not can_start_fuel_processing():
		refresh_lander_view_or_shop_ui()
		return
	
	consume_resource("Raw Fuel", 1)
	fuel_processing_active = true
	fuel_processing_remaining_seconds = 0.0
	complete_fuel_processing()
	refresh_lander_view_or_shop_ui()
	update_hud()


func process_treasure_from_storage() -> void:
	if get_total_resource_count("Treasure") <= 0:
		last_treasure_processing_result = "No Treasure available to process."
		refresh_lander_view_or_shop_ui()
		return
	
	var candidates := get_available_treasure_upgrade_candidates()
	if candidates.is_empty():
		last_treasure_processing_result = "All available upgrade systems are already maxed."
		refresh_lander_view_or_shop_ui()
		return
	
	var selected_candidate: Dictionary = candidates.pick_random()
	var category_name: String = selected_candidate["category"]
	var definition: Dictionary = selected_candidate["definition"]
	var upgrade_id: String = definition["id"]
	var current_level: int = int(upgrade_levels.get(upgrade_id, 0))
	var max_level: int = int(definition.get("max_level", StartingPlanetBalance.MK1_MAX_LEVEL))
	var target_level := mini(current_level + roll_treasure_upgrade_levels(), max_level)
	
	consume_resource("Treasure", 1)
	for new_level in range(current_level + 1, target_level + 1):
		upgrade_levels[upgrade_id] = new_level
		apply_upgrade_effect(upgrade_id, new_level)
	
	last_treasure_processing_result = "%s — %s advanced from Lvl %d to Lvl %d (+%d)." % [
		category_name,
		String(definition["name"]),
		current_level,
		target_level,
		target_level - current_level,
	]
	refresh_lander_view_or_shop_ui()
	update_hud()


func roll_treasure_upgrade_levels() -> int:
	var roll := randf()
	if roll < 0.05:
		return 3
	if roll < 0.20:
		return 2
	return 1


func can_process_treasure() -> bool:
	return (
		get_total_resource_count("Treasure") > 0
		and not get_available_treasure_upgrade_candidates().is_empty()
	)


func get_available_treasure_upgrade_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for category_name in upgrade_definitions.keys():
		if (
			SeedManager.current_system_id == SeedManager.STARTING_SYSTEM_ID
			and not get_miner_component_category_names().has(String(category_name))
		):
			continue
		var category_upgrades: Array = upgrade_definitions[category_name]
		for definition in category_upgrades:
			var upgrade_id: String = definition["id"]
			var current_level: int = int(upgrade_levels.get(upgrade_id, 0))
			var max_level: int = int(definition.get("max_level", StartingPlanetBalance.MK1_MAX_LEVEL))
			if current_level < max_level:
				candidates.append({
					"category": String(category_name),
					"definition": definition,
				})
	return candidates


func get_treasure_processing_status_text() -> String:
	if not last_treasure_processing_result.is_empty():
		return last_treasure_processing_result
	if get_total_resource_count("Treasure") <= 0:
		return "Mine Treasure blocks to recover upgrade artifacts."
	if get_available_treasure_upgrade_candidates().is_empty():
		return "All available upgrade systems are already maxed."
	return "Consumes 1 Treasure: 80% +1 level, 15% +2 levels, 5% +3 levels."


func can_start_fuel_processing() -> bool:
	return (
		get_total_resource_count("Raw Fuel") > 0
		and (
			get_mining_fuel_processing_output_kg() > 0
			or get_rocket_fuel_room() >= rocket_fuel_tons_per_raw_fuel
		)
	)


func get_rocket_fuel_room() -> int:
	return maxi(max_lander_rocket_fuel_tons - lander_rocket_fuel_tons, 0)


func update_fuel_processing(_delta: float) -> void:
	if not fuel_processing_active:
		return
	# Legacy saves may contain a job that was in progress. Complete it instantly.
	complete_fuel_processing()


func complete_fuel_processing() -> void:
	fuel_processing_active = false
	fuel_processing_remaining_seconds = 0.0
	lander_mining_fuel_kg = mini(
		max_lander_mining_fuel_kg,
		lander_mining_fuel_kg + mining_fuel_kg_per_raw_fuel
	)
	lander_rocket_fuel_tons = mini(
		max_lander_rocket_fuel_tons,
		lander_rocket_fuel_tons + rocket_fuel_tons_per_raw_fuel
	)
	SeedManager.update_starting_escape_fuel(
		lander_rocket_fuel_tons,
		return_to_starship_required_rocket_fuel_tons
	)
	refresh_lander_view_or_shop_ui()
	update_hud()


func get_fuel_processing_status_text() -> String:
	if get_total_resource_count("Raw Fuel") <= 0:
		return "No raw fuel available"
	if not can_start_fuel_processing():
		return "Mining and rocket fuel storage full"
	return "Ready instantly: %d kg Mining Fuel + %d ton Rocket Fuel" % [
		get_mining_fuel_processing_output_kg(),
		mini(get_rocket_fuel_room(), rocket_fuel_tons_per_raw_fuel),
	]


func get_mining_fuel_processing_output_kg() -> int:
	return mini(
		maxi(max_lander_mining_fuel_kg - lander_mining_fuel_kg, 0),
		mining_fuel_kg_per_raw_fuel
	)


func get_process_raw_fuel_button_text() -> String:
	return "Process 1 Raw Fuel — Instant\n+%d kg Mining Fuel  |  +%d ton Rocket Fuel" % [
		get_mining_fuel_processing_output_kg(),
		mini(get_rocket_fuel_room(), rocket_fuel_tons_per_raw_fuel),
	]


func _on_return_to_starship_pressed() -> void:
	if not can_return_to_starship():
		if (
			lander_rocket_fuel_tons >= return_to_starship_required_rocket_fuel_tons
			and not has_planet_core()
		):
			show_planet_core_departure_warning()
		update_shop_ui()
		return
	
	trigger_victory()


func can_return_to_starship() -> bool:
	return lander_rocket_fuel_tons >= return_to_starship_required_rocket_fuel_tons and has_planet_core()


func show_planet_core_departure_warning() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "The Greatest Treasure"
	dialog.dialog_text = (
		"You've left the greatest treasure buried just beneath your fingertips. "
		+ "And trust me, you will need it if you want to take on the demons in the next system. "
		+ "Better keep going—just another few meters."
	)
	dialog.get_ok_button().text = "Keep Digging"
	dialog.exclusive = false
	add_child(dialog)
	popup_wrapped_transmission(dialog, Vector2i(760, 360))


func has_planet_core() -> bool:
	return get_total_resource_count("Planet Core") > 0


func _on_deposit_all_pressed() -> void:
	for resource_name in get_cargo_display_resource_names(resources):
		var count: int = int(resources.get(resource_name, 0))
		if count <= 0:
			continue
		
		var amount_to_deposit: int = mini(count, get_cargo_hold_room())
		if amount_to_deposit <= 0:
			break
		
		cargo_hold_resources[resource_name] = int(cargo_hold_resources.get(resource_name, 0)) + amount_to_deposit
		resources[resource_name] = count - amount_to_deposit
	
	refresh_lander_view_or_shop_ui()
	update_hud()


func _on_sell_all_pressed() -> void:
	for resource_name in get_sellable_resource_names():
		if get_resource_value(resource_name) <= 0:
			continue
		var lander_count: int = int(cargo_hold_resources.get(resource_name, 0))
		if lander_count <= 0:
			continue
		credits += get_resource_sale_quote(resource_name, lander_count)
		record_resource_sale(resource_name, lander_count)
		cargo_hold_resources[resource_name] = 0

	refresh_lander_view_or_shop_ui()
	update_hud()


func _on_sell_copper_pressed() -> void:
	sell_resource("Copper")


func _on_sell_raw_fuel_pressed() -> void:
	sell_resource("Raw Fuel")


func _on_sell_iron_pressed() -> void:
	sell_resource("Iron")


func _on_sell_gold_pressed() -> void:
	sell_resource("Gold")


func _on_sell_treasure_pressed() -> void:
	sell_resource("Treasure")


func _on_sell_diamond_pressed() -> void:
	sell_resource("Diamond")


func _on_sell_warp_gems_pressed() -> void:
	sell_resource("Warp Gems")


func _on_sell_black_hole_crystals_pressed() -> void:
	sell_resource("Black Hole Crystals")


func _on_refuel_pressed() -> void:
	var needed_kg := get_mining_fuel_kg_needed_for_full_refuel()
	var kg_to_use: int = mini(needed_kg, lander_mining_fuel_kg)
	
	if kg_to_use > 0:
		lander_mining_fuel_kg -= kg_to_use
	else:
		kg_to_use = mini(needed_kg, floori(float(credits) / float(emergency_refuel_credit_cost_per_kg)))
		
		if kg_to_use <= 0:
			update_shop_ui()
			return
		
		credits -= get_emergency_refuel_credit_cost(kg_to_use)
	
	fuel_seconds = minf(
		fuel_seconds + float(kg_to_use) * mining_fuel_seconds_per_kg,
		max_fuel_seconds
	)
	update_shop_ui()
	update_hud()


func get_mining_fuel_kg_needed_for_full_refuel() -> int:
	var missing_fuel: float = max_fuel_seconds - fuel_seconds
	return ceili(missing_fuel / mining_fuel_seconds_per_kg)


func get_emergency_refuel_credit_cost(fuel_kg: int) -> int:
	return fuel_kg * emergency_refuel_credit_cost_per_kg


func _on_buy_copper_drill_pressed() -> void:
	if has_copper_drill_upgrade:
		return
	
	var copper_count: int = get_total_resource_count("Copper")
	
	if credits < copper_drill_credit_cost or copper_count < copper_drill_cost:
		update_shop_ui()
		return
	
	credits -= copper_drill_credit_cost
	consume_resource("Copper", copper_drill_cost)
	drill_damage_per_second *= copper_drill_damage_multiplier
	has_copper_drill_upgrade = true
	player_marker.modulate = copper_drill_tint
	update_shop_ui()
	update_hud()


func _on_buy_sensor_upgrade_pressed() -> void:
	if has_sensor_upgrade:
		return
	
	var copper_count: int = get_total_resource_count("Copper")
	var iron_count: int = get_total_resource_count("Iron")
	
	if (
		credits < sensor_upgrade_credit_cost
		or copper_count < sensor_upgrade_copper_cost
		or iron_count < sensor_upgrade_iron_cost
	):
		update_shop_ui()
		return
	
	credits -= sensor_upgrade_credit_cost
	consume_resource("Copper", sensor_upgrade_copper_cost)
	consume_resource("Iron", sensor_upgrade_iron_cost)
	reveal_radius_tiles = upgraded_sensor_reveal_radius
	has_sensor_upgrade = true
	update_revealed_cells()
	update_shop_ui()
	update_hud()


func create_game_over_ui() -> void:
	var game_over_layer := CanvasLayer.new()
	game_over_layer.name = "GameOverUI"
	game_over_layer.layer = 30
	add_child(game_over_layer)
	var backdrop := ColorRect.new()
	backdrop.name = "GameOverBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015, 0.01, 0.018, 0.9)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.visible = false
	game_over_layer.add_child(backdrop)
	
	game_over_label = Label.new()
	game_over_label.anchor_left = 0.5
	game_over_label.anchor_right = 0.5
	game_over_label.anchor_top = 0.5
	game_over_label.anchor_bottom = 0.5
	game_over_label.offset_left = -430.0
	game_over_label.offset_right = 430.0
	game_over_label.offset_top = -70.0
	game_over_label.offset_bottom = 70.0
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_label.add_theme_font_size_override("font_size", 34)
	game_over_label.text = STANDARD_DEATH_MESSAGE
	game_over_label.visible = false
	game_over_layer.add_child(game_over_label)

	game_over_actions = VBoxContainer.new()
	game_over_actions.name = "GameOverActions"
	game_over_actions.anchor_left = 0.5
	game_over_actions.anchor_right = 0.5
	game_over_actions.anchor_top = 0.5
	game_over_actions.anchor_bottom = 0.5
	game_over_actions.offset_left = -210.0
	game_over_actions.offset_right = 210.0
	game_over_actions.offset_top = 105.0
	game_over_actions.offset_bottom = 315.0
	game_over_actions.add_theme_constant_override("separation", 14)
	game_over_actions.theme = GameTheme.create_button_theme()
	game_over_actions.visible = false
	game_over_layer.add_child(game_over_actions)
	load_last_save_button = add_shop_button(
		game_over_actions,
		"Load Last Save",
		Callable(self, "_on_game_over_load_save_pressed")
	)
	add_shop_button(game_over_actions, "New Game", Callable(self, "_on_game_over_new_game_pressed"))
	add_shop_button(game_over_actions, "Quit", Callable(self, "_on_game_over_quit_pressed"))


func create_arrival_countdown_ui() -> void:
	var countdown_layer := CanvasLayer.new()
	countdown_layer.name = "ArrivalCountdownUI"
	add_child(countdown_layer)
	
	countdown_label = Label.new()
	countdown_label.anchor_left = 0.5
	countdown_label.anchor_right = 0.5
	countdown_label.anchor_top = 0.5
	countdown_label.anchor_bottom = 0.5
	countdown_label.offset_left = -220.0
	countdown_label.offset_right = 220.0
	countdown_label.offset_top = -100.0
	countdown_label.offset_bottom = 100.0
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 92)
	countdown_label.visible = false
	countdown_layer.add_child(countdown_label)


func start_arrival_countdown() -> void:
	is_arrival_countdown_active = true
	player_velocity = Vector2.ZERO
	reset_mining_progress()
	
	if countdown_label != null:
		countdown_label.visible = true
	
	for count in range(arrival_countdown_seconds, 0, -1):
		if countdown_label != null:
			countdown_label.text = str(count)
		await get_tree().create_timer(1.0).timeout
	
	if countdown_label != null:
		countdown_label.text = "GO"
	await get_tree().create_timer(0.45).timeout
	
	if countdown_label != null:
		countdown_label.visible = false
	
	is_arrival_countdown_active = false


func trigger_death() -> void:
	if is_game_over:
		return

	is_game_over = true
	is_arrival_countdown_active = false
	is_shop_open = false
	is_paused = true
	player_velocity = Vector2.ZERO
	reset_mining_progress()

	if shop_panel != null:
		shop_panel.visible = false
	if mining_inventory_panel != null:
		mining_inventory_panel.visible = false
	if countdown_label != null:
		countdown_label.visible = false
	var backdrop := get_node_or_null("GameOverUI/GameOverBackdrop") as ColorRect
	if backdrop != null:
		backdrop.visible = true
	if game_over_label != null:
		game_over_label.text = STANDARD_DEATH_MESSAGE
		game_over_label.visible = true
		game_over_label.pivot_offset = game_over_label.size * 0.5
		game_over_label.scale = Vector2(0.35, 0.35)
		game_over_label.modulate = Color(1.0, 0.12, 0.08, 0.0)
		var entrance_tween := create_tween()
		entrance_tween.set_parallel(true)
		entrance_tween.tween_property(game_over_label, "scale", Vector2.ONE, 0.65).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		entrance_tween.tween_property(game_over_label, "modulate:a", 1.0, 0.45)
	if game_over_actions != null:
		game_over_actions.visible = true
	if load_last_save_button != null:
		load_last_save_button.disabled = not SaveManager.has_save()


func _on_game_over_load_save_pressed() -> void:
	if SaveManager.load_game():
		return
	if load_last_save_button != null:
		load_last_save_button.disabled = true
		load_last_save_button.text = "No Save Available"


func _on_game_over_new_game_pressed() -> void:
	SeedManager.start_new_run()
	get_tree().change_scene_to_file("res://Scenes/AsteroidMining.tscn")


func _on_game_over_quit_pressed() -> void:
	get_tree().quit()


func trigger_victory() -> void:
	if is_game_over:
		return
	
	is_game_over = true
	is_arrival_countdown_active = false
	is_shop_open = false
	is_paused = true
	player_velocity = Vector2.ZERO
	reset_mining_progress()
	
	if shop_panel != null:
		shop_panel.visible = false
	
	if countdown_label != null:
		countdown_label.visible = false
	
	var completed_starting_scenario := SeedManager.is_starting_scenario_active()
	if completed_starting_scenario:
		SeedManager.load_starship_escape_fuel(lander_rocket_fuel_tons)
		SeedManager.unlock_galaxy_map()

	if game_over_label != null:
		if completed_starting_scenario:
			game_over_label.text = "Escape fuel loaded.\nGalaxy route access unlocked.\nReturning to the Starship..."
		else:
			game_over_label.text = "You win!\nPlanet Core secured. Rocket fuel loaded.\nReturning to the starship..."
		game_over_label.visible = true
	
	await get_tree().create_timer(3.0).timeout
	if completed_starting_scenario:
		get_tree().change_scene_to_file("res://Scenes/StarSystemView.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/main_game_menu.tscn")


func create_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "MiningHUD"
	hud_layer.layer = HUD_LAYER_INDEX
	add_child(hud_layer)

	modular_mining_hud = MiningHudScene.instantiate() as MiningHud
	modular_mining_hud.name = "ModularMiningHUD"
	modular_mining_hud.anchor_top = 1.0
	modular_mining_hud.anchor_bottom = 1.0
	modular_mining_hud.offset_left = 8.0
	modular_mining_hud.offset_right = 8.0 + MiningHud.DISPLAY_SIZE.x
	modular_mining_hud.offset_top = -MiningHud.DISPLAY_SIZE.y - 8.0
	modular_mining_hud.offset_bottom = -8.0
	hud_layer.add_child(modular_mining_hud)
	modular_mining_hud.radial_blast_requested.connect(try_activate_radial_blast)
	modular_mining_hud.directional_blast_requested.connect(try_activate_directional_blast)
	radial_blast_button = modular_mining_hud.radial_button
	directional_blast_button = modular_mining_hud.directional_button
	radial_blast_cooldown_label = modular_mining_hud.radial_cooldown_label
	directional_blast_cooldown_label = modular_mining_hud.directional_cooldown_label
	gauge_cluster = modular_mining_hud
	gauge_fuel_needle = modular_mining_hud.fuel_needle
	gauge_heat_needle = modular_mining_hud.heat_needle
	
	hud_label = Label.new()
	hud_label.position = Vector2(24, 24)
	hud_label.add_theme_font_size_override("font_size", 30)
	hud_label.add_theme_constant_override("outline_size", 3)
	hud_layer.add_child(hud_label)

	cargo_full_notification = Label.new()
	cargo_full_notification.name = "CargoFullNotification"
	cargo_full_notification.anchor_left = 0.5
	cargo_full_notification.anchor_right = 0.5
	cargo_full_notification.offset_left = -300.0
	cargo_full_notification.offset_right = 300.0
	cargo_full_notification.offset_top = 24.0
	cargo_full_notification.offset_bottom = 96.0
	cargo_full_notification.text = "CARGO HOLD FULL\nReturn to the lander to unload"
	cargo_full_notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cargo_full_notification.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cargo_full_notification.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cargo_full_notification.add_theme_font_size_override("font_size", 35)
	cargo_full_notification.add_theme_color_override("font_color", Color(1.0, 0.08, 0.04, 1.0))
	cargo_full_notification.add_theme_color_override("font_outline_color", Color.BLACK)
	cargo_full_notification.add_theme_constant_override("outline_size", 8)
	cargo_full_notification.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cargo_full_notification.visible = false
	hud_layer.add_child(cargo_full_notification)
	
	var cargo_center := CenterContainer.new()
	cargo_center.name = "CenteredMinerCargo"
	cargo_center.anchor_top = 0.0
	cargo_center.anchor_bottom = 1.0
	cargo_center.offset_left = 18.0
	cargo_center.offset_right = 170.0
	cargo_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(cargo_center)

	hud_cargo_icons = VBoxContainer.new()
	hud_cargo_icons.name = "MinerCargoList"
	hud_cargo_icons.add_theme_constant_override("separation", 3)
	hud_cargo_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cargo_center.add_child(hud_cargo_icons)

	create_mining_inventory_menu(hud_layer)
	
	update_fuel_bar()
	update_hull_health_bar()
	update_gauge_cluster()
	update_ability_buttons()


func create_mining_inventory_menu(hud_layer: CanvasLayer) -> void:
	mining_inventory_panel = Panel.new()
	mining_inventory_panel.name = "MiningInventoryPanel"
	mining_inventory_panel.anchor_left = 0.5
	mining_inventory_panel.anchor_right = 0.5
	mining_inventory_panel.anchor_top = 0.5
	mining_inventory_panel.anchor_bottom = 0.5
	mining_inventory_panel.offset_left = -390.0
	mining_inventory_panel.offset_right = 390.0
	mining_inventory_panel.offset_top = -330.0
	mining_inventory_panel.offset_bottom = 330.0
	mining_inventory_panel.theme = GameTheme.create_button_theme()
	mining_inventory_panel.visible = false
	hud_layer.add_child(mining_inventory_panel)

	var content := VBoxContainer.new()
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.offset_left = 24.0
	content.offset_top = 20.0
	content.offset_right = -24.0
	content.offset_bottom = -20.0
	content.add_theme_constant_override("separation", 12)
	mining_inventory_panel.add_child(content)

	var title := Label.new()
	title.text = "MINER INVENTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	content.add_child(title)

	var helper := Label.new()
	helper.text = "Dump unwanted cargo one unit at a time. Dumped items cannot be recovered."
	helper.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	helper.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	helper.add_theme_font_size_override("font_size", 16)
	content.add_child(helper)

	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	content.add_child(inventory_scroll)

	mining_inventory_list = VBoxContainer.new()
	mining_inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mining_inventory_list.add_theme_constant_override("separation", 7)
	inventory_scroll.add_child(mining_inventory_list)

	var close_button := add_shop_button(content, "Close Inventory (Escape)", Callable(self, "close_mining_inventory"))
	close_button.custom_minimum_size.y = 54.0


func open_mining_inventory() -> void:
	if mining_inventory_panel == null or is_shop_open or is_game_over or is_arrival_countdown_active:
		return
	mining_inventory_previous_paused = is_paused
	is_paused = true
	update_mining_inventory_list()
	mining_inventory_panel.visible = true
	update_ability_buttons()


func close_mining_inventory() -> void:
	if mining_inventory_panel == null or not mining_inventory_panel.visible:
		return
	mining_inventory_panel.visible = false
	is_paused = mining_inventory_previous_paused
	update_ability_buttons()


func is_mining_inventory_open() -> bool:
	return mining_inventory_panel != null and mining_inventory_panel.visible


func update_mining_inventory_list() -> void:
	if mining_inventory_list == null:
		return
	clear_children(mining_inventory_list)
	var has_cargo := false
	for resource_name in get_cargo_display_resource_names(resources):
		var count := int(resources.get(resource_name, 0))
		if count <= 0:
			continue
		has_cargo = true
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(700.0, 54.0)
		row.add_theme_constant_override("separation", 10)
		mining_inventory_list.add_child(row)
		row.add_child(create_resource_icon(resource_name, Vector2(38.0, 38.0)))
		var label := Label.new()
		label.text = "%s x%d" % [resource_name, count]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		row.add_child(label)
		var dump_button := add_shop_button(
			row,
			"Dump 1",
			Callable(self, "dump_miner_resource").bind(resource_name)
		)
		dump_button.custom_minimum_size = Vector2(150.0, 48.0)
	if not has_cargo:
		var empty_label := Label.new()
		empty_label.text = "Miner cargo is empty."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		mining_inventory_list.add_child(empty_label)


func dump_miner_resource(resource_name: String) -> void:
	var count := int(resources.get(resource_name, 0))
	if count <= 0:
		return
	if count == 1:
		resources.erase(resource_name)
	else:
		resources[resource_name] = count - 1
	update_mining_inventory_list()
	update_hud()


func create_planet_map_overlay() -> void:
	var map_layer := CanvasLayer.new()
	map_layer.name = "PlanetMapUI"
	map_layer.layer = SHOP_LAYER_INDEX + 5
	add_child(map_layer)
	planet_map_overlay = PlanetMapOverlayScript.new()
	planet_map_overlay.name = "PlanetMapOverlay"
	planet_map_overlay.mining_scene = self
	planet_map_overlay.visible = false
	planet_map_overlay.close_requested.connect(close_planet_map)
	map_layer.add_child(planet_map_overlay)


func toggle_planet_map() -> void:
	if planet_map_overlay == null:
		return
	if planet_map_overlay.visible:
		close_planet_map()
		return
	if is_shop_open or is_game_over or is_arrival_countdown_active:
		return
	map_previous_paused = is_paused
	is_paused = true
	planet_map_overlay.open_at_player()
	update_ability_buttons()


func close_planet_map() -> void:
	if planet_map_overlay == null or not planet_map_overlay.visible:
		return
	planet_map_overlay.visible = false
	is_paused = map_previous_paused
	update_ability_buttons()


func create_hull_health_bar(hud_layer: CanvasLayer) -> void:
	var hull_label := Label.new()
	hull_label.text = "Hull"
	hull_label.anchor_top = 1.0
	hull_label.anchor_bottom = 1.0
	hull_label.offset_left = 24.0
	hull_label.offset_right = 78.0
	hull_label.offset_top = -322.0
	hull_label.offset_bottom = -296.0
	hull_label.add_theme_font_size_override("font_size", 18)
	hud_layer.add_child(hull_label)

	var hull_bar := Control.new()
	hull_bar.name = "HullHealthBar"
	hull_bar.anchor_top = 1.0
	hull_bar.anchor_bottom = 1.0
	hull_bar.offset_left = 82.0
	hull_bar.offset_right = 482.0
	hull_bar.offset_top = -320.0
	hull_bar.offset_bottom = -298.0
	hull_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hull_bar)

	var hull_background := ColorRect.new()
	hull_background.color = Color(0.08, 0.025, 0.025, 0.88)
	hull_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hull_bar.add_child(hull_background)

	hull_bar_fill = ColorRect.new()
	hull_bar_fill.position = Vector2(2.0, 2.0)
	hull_bar_fill.size = Vector2(396.0, 18.0)
	hull_bar.add_child(hull_bar_fill)

	hull_health_label = Label.new()
	hull_health_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hull_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hull_health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hull_health_label.add_theme_font_size_override("font_size", 14)
	hull_health_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	hull_health_label.add_theme_constant_override("shadow_offset_x", 1)
	hull_health_label.add_theme_constant_override("shadow_offset_y", 1)
	hull_bar.add_child(hull_health_label)
	update_hull_health_bar()


func update_hull_health_bar() -> void:
	if modular_mining_hud != null:
		modular_mining_hud.set_hull(hull_health, max_hull_health)
		return
	if hull_bar_fill == null or hull_health_label == null:
		return
	var health_ratio := clampf(float(hull_health) / maxf(float(max_hull_health), 1.0), 0.0, 1.0)
	hull_bar_fill.size.x = 396.0 * health_ratio
	hull_bar_fill.color = Color(0.15, 0.86, 0.34, 0.95).lerp(Color(0.95, 0.08, 0.04, 0.98), 1.0 - health_ratio)
	hull_health_label.text = "%d / %d HP" % [hull_health, max_hull_health]


func create_ability_hud(hud_layer: CanvasLayer) -> void:
	var ability_buttons := HBoxContainer.new()
	ability_buttons.name = "MiningAbilities"
	ability_buttons.anchor_left = 0.0
	ability_buttons.anchor_right = 0.0
	ability_buttons.anchor_top = 1.0
	ability_buttons.anchor_bottom = 1.0
	ability_buttons.offset_left = 112.0
	ability_buttons.offset_right = 272.0
	ability_buttons.offset_top = -292.0
	ability_buttons.offset_bottom = -187.0
	ability_buttons.add_theme_constant_override("separation", 16)
	ability_buttons.theme = GameTheme.create_button_theme()
	hud_layer.add_child(ability_buttons)

	var radial_stack := VBoxContainer.new()
	radial_stack.custom_minimum_size = Vector2(64.0, 0.0)
	radial_stack.add_theme_constant_override("separation", 1)
	ability_buttons.add_child(radial_stack)
	var radial_key_label := create_ability_key_label("Q")
	radial_stack.add_child(radial_key_label)

	radial_blast_button = Button.new()
	radial_blast_button.name = "RadialBlastButton"
	radial_blast_button.custom_minimum_size = Vector2(64.0, 64.0)
	radial_blast_button.icon = RadialBlastIcon
	radial_blast_button.expand_icon = true
	radial_blast_button.tooltip_text = "Mine every mineable block within one tile of the miner."
	radial_blast_button.pressed.connect(try_activate_radial_blast)
	apply_compact_ability_button_style(radial_blast_button)
	radial_stack.add_child(radial_blast_button)
	radial_blast_cooldown_label = create_ability_cooldown_label()
	radial_stack.add_child(radial_blast_cooldown_label)

	var directional_stack := VBoxContainer.new()
	directional_stack.custom_minimum_size = Vector2(64.0, 0.0)
	directional_stack.add_theme_constant_override("separation", 1)
	ability_buttons.add_child(directional_stack)
	var directional_key_label := create_ability_key_label("E")
	directional_stack.add_child(directional_key_label)

	directional_blast_button = Button.new()
	directional_blast_button.name = "DirectionalBlastButton"
	directional_blast_button.custom_minimum_size = Vector2(64.0, 64.0)
	directional_blast_button.icon = DirectionalBlastIcon
	directional_blast_button.expand_icon = true
	directional_blast_button.tooltip_text = "Mine the next three blocks in the drill's facing direction."
	directional_blast_button.pressed.connect(try_activate_directional_blast)
	apply_compact_ability_button_style(directional_blast_button)
	directional_stack.add_child(directional_blast_button)
	directional_blast_cooldown_label = create_ability_cooldown_label()
	directional_stack.add_child(directional_blast_cooldown_label)

	update_ability_buttons()


func create_ability_key_label(key_text: String) -> Label:
	var label := Label.new()
	label.text = key_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0, 1.0))
	return label


func create_ability_cooldown_label() -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.72, 0.84, 0.9, 1.0))
	return label


func apply_compact_ability_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", create_compact_ability_style(Color("#A9D7E8")))
	button.add_theme_stylebox_override("hover", create_compact_ability_style(Color("#D4F3FF")))
	button.add_theme_stylebox_override("pressed", create_compact_ability_style(Color("#6F9FB4")))
	button.add_theme_stylebox_override("disabled", create_compact_ability_style(Color("#52636C")))


func create_compact_ability_style(background_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = Color("#526F82")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(3.0)
	return style


func update_ability_buttons() -> void:
	if modular_mining_hud != null:
		var globally_disabled := is_paused or is_shop_open or is_game_over or is_ability_effect_active
		modular_mining_hud.set_ability_states(
			radial_blast_cooldown_remaining,
			radial_blast_cooldown_seconds,
			directional_blast_cooldown_remaining,
			directional_blast_cooldown_seconds,
			globally_disabled,
			GameSettings.mouse_directed_e_enabled,
			get_loaded_explosive_charges()
		)
		return
	if radial_blast_button == null or directional_blast_button == null:
		return
	var globally_disabled := is_paused or is_shop_open or is_game_over or is_ability_effect_active
	radial_blast_button.text = ""
	radial_blast_button.disabled = globally_disabled or radial_blast_cooldown_remaining > 0.0
	directional_blast_button.text = ""
	directional_blast_button.disabled = (
		globally_disabled
		or directional_blast_cooldown_remaining > 0.0
	)
	if radial_blast_cooldown_label != null:
		radial_blast_cooldown_label.text = format_ability_cooldown(radial_blast_cooldown_remaining)
	if directional_blast_cooldown_label != null:
		directional_blast_cooldown_label.text = format_ability_cooldown(directional_blast_cooldown_remaining)
	directional_blast_button.tooltip_text = (
		"Mouse-directed three-block blast."
		if GameSettings.mouse_directed_e_enabled
		else "Drill-facing three-block blast."
	)


func format_ability_cooldown(seconds_remaining: float) -> String:
	if seconds_remaining <= 0.0:
		return "READY"
	var whole_seconds := ceili(seconds_remaining)
	return "%d:%02d" % [floori(float(whole_seconds) / 60.0), whole_seconds % 60]


func create_gauge_cluster(hud_layer: CanvasLayer) -> void:
	gauge_cluster = Control.new()
	gauge_cluster.name = "GaugeCluster"
	gauge_cluster.anchor_left = 0.0
	gauge_cluster.anchor_right = 0.0
	gauge_cluster.anchor_top = 1.0
	gauge_cluster.anchor_bottom = 1.0
	gauge_cluster.offset_left = 0.0
	gauge_cluster.offset_right = gauge_cluster.offset_left + LEGACY_GAUGE_CLUSTER_DESIGN_SIZE.x
	gauge_cluster.offset_top = -LEGACY_GAUGE_CLUSTER_SIZE.y
	gauge_cluster.offset_bottom = gauge_cluster.offset_top + LEGACY_GAUGE_CLUSTER_DESIGN_SIZE.y
	gauge_cluster.size = LEGACY_GAUGE_CLUSTER_DESIGN_SIZE
	gauge_cluster.custom_minimum_size = LEGACY_GAUGE_CLUSTER_DESIGN_SIZE
	gauge_cluster.scale = LEGACY_GAUGE_CLUSTER_SCALE
	gauge_cluster.clip_contents = true
	gauge_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(gauge_cluster)
	
	var gauge_background := TextureRect.new()
	gauge_background.name = "GaugeClusterBackground"
	gauge_background.texture = LegacyGaugeClusterTexture
	gauge_background.anchor_right = 1.0
	gauge_background.anchor_bottom = 1.0
	gauge_background.offset_left = 0.0
	gauge_background.offset_right = 0.0
	gauge_background.offset_top = 0.0
	gauge_background.offset_bottom = 0.0
	gauge_background.custom_minimum_size = Vector2.ZERO
	gauge_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gauge_background.stretch_mode = TextureRect.STRETCH_SCALE
	gauge_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge_cluster.add_child(gauge_background)
	gauge_background.size = LEGACY_GAUGE_CLUSTER_DESIGN_SIZE
	
	gauge_fuel_needle = create_gauge_needle(Color(0.0, 0.9, 1.0, 0.92), Vector2(96.0, 166.0))
	gauge_cluster.add_child(gauge_fuel_needle)
	
	gauge_heat_needle = create_gauge_needle(Color(1.0, 0.22, 0.02, 0.92), Vector2(464.0, 166.0))
	gauge_cluster.add_child(gauge_heat_needle)
	
	gauge_depth_label = Label.new()
	gauge_depth_label.name = "DepthReadout"
	gauge_depth_label.position = Vector2(276.0, 153.0)
	gauge_depth_label.size = Vector2(86.0, 42.0)
	gauge_depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gauge_depth_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gauge_depth_label.add_theme_font_size_override("font_size", 30)
	gauge_depth_label.add_theme_color_override("font_color", Color(1.0, 0.46, 0.06, 1.0))
	gauge_depth_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	gauge_depth_label.add_theme_constant_override("shadow_offset_x", 2)
	gauge_depth_label.add_theme_constant_override("shadow_offset_y", 2)
	gauge_cluster.add_child(gauge_depth_label)


func create_gauge_needle(color: Color, gauge_center: Vector2) -> ColorRect:
	var needle := ColorRect.new()
	needle.color = color
	needle.position = gauge_center - Vector2(12.0, 3.0)
	needle.size = Vector2(100.0, 6.0)
	needle.pivot_offset = Vector2(12.0, 3.0)
	needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return needle


func rebuild_fuel_bar_segments() -> void:
	if modular_mining_hud != null:
		modular_mining_hud.set_capacitor(capacitor_energy, capacitor_capacity)
		return
	for segment in fuel_bar_segments:
		if segment != null:
			segment.queue_free()
	
	fuel_bar_segments.clear()
	
	if fuel_bar == null:
		return
	
	var segment_count: int = maxi(ceili(max_fuel_seconds / 10.0), 1)
	
	for i in range(1, segment_count):
		var segment := ColorRect.new()
		segment.name = "FuelSegment%d" % i
		segment.color = Color(0.78, 1.0, 1.0, 0.72)
		segment.size = Vector2(2.0, 18.0)
		fuel_bar.add_child(segment)
		fuel_bar_segments.append(segment)


func update_fuel_bar(delta: float = 0.0) -> void:
	if modular_mining_hud != null:
		if capacitor_energy / maxf(capacitor_capacity, 0.01) <= 0.2:
			fuel_warning_blink_time += delta
		else:
			fuel_warning_blink_time = 0.0
		modular_mining_hud.set_capacitor(capacitor_energy, capacitor_capacity)
		return
	if fuel_bar == null or fuel_bar_fill == null:
		return
	
	var segment_count: int = maxi(ceili(max_fuel_seconds / 10.0), 1)
	if fuel_bar_segments.size() != segment_count - 1:
		rebuild_fuel_bar_segments()
	
	var fuel_ratio: float = clampf(fuel_seconds / maxf(max_fuel_seconds, 0.01), 0.0, 1.0)
	var inner_width: float = maxf(fuel_bar.size.x - 4.0, 0.0)
	fuel_bar_fill.size = Vector2(inner_width * fuel_ratio, maxf(fuel_bar.size.y - 4.0, 0.0))
	
	var fill_color := Color(0.0, 0.75, 0.86, 0.95)
	
	if fuel_ratio <= fuel_warning_ratio:
		fuel_warning_blink_time += delta
		var warning_alpha: float = 0.45 + 0.5 * absf(sin(fuel_warning_blink_time * 7.5))
		fill_color = Color(1.0, 0.05, 0.03, warning_alpha)
	else:
		fuel_warning_blink_time = 0.0
	
	fuel_bar_fill.color = fill_color
	
	for i in fuel_bar_segments.size():
		var segment := fuel_bar_segments[i]
		var x_position: float = ((float(i) + 1.0) / float(segment_count)) * fuel_bar.size.x
		segment.position = Vector2(x_position - 1.0, 2.0)
		segment.size = Vector2(2.0, maxf(fuel_bar.size.y - 4.0, 0.0))


func update_hud() -> void:
	if hud_label == null:
		return
	
	update_fuel_bar()
	update_hull_health_bar()
	update_hud_cargo_icons()
	update_gauge_cluster()
	update_ability_buttons()
	update_cargo_full_notification()
	update_world_hud_text_contrast()
	
	var context_status := drill_access_message if not drill_access_message.is_empty() else lift_status_message
	hud_label.text = "Credits: %d\nCargo: %d / %d\nI: Inventory  |  M: Map  |  R: GPS Marker  |  L: Build Lift  |  F: Use Lift\n%s\nDeveloper Setup: Ctrl+T" % [
		credits,
		get_inventory_count(),
		inventory_capacity,
		context_status,
	]


func update_world_hud_text_contrast() -> void:
	var text_color := get_world_hud_text_color()
	var outline_color := Color.WHITE if text_color == Color.BLACK else Color.BLACK
	if hud_label != null:
		hud_label.add_theme_color_override("font_color", text_color)
		hud_label.add_theme_color_override("font_outline_color", outline_color)
	if hud_cargo_icons != null:
		# Cargo readouts sit directly over the world. A white face with a heavy black
		# outline remains readable across both the bright surface and deep terrain.
		apply_text_contrast_to_labels(hud_cargo_icons, Color.WHITE, Color.BLACK)


func get_world_hud_text_color() -> Color:
	# The camera follows the miner, so depth brightness is a stable approximation of
	# the terrain behind the screen-space HUD without an expensive framebuffer read.
	var backdrop_brightness := get_depth_brightness_for_row(get_player_cell().y)
	return Color.BLACK if backdrop_brightness >= 0.7 else Color.WHITE


func apply_text_contrast_to_labels(node: Node, text_color: Color, outline_color: Color) -> void:
	if node is Label:
		var label := node as Label
		label.add_theme_color_override("font_color", text_color)
		label.add_theme_color_override("font_outline_color", outline_color)
		label.add_theme_constant_override("outline_size", 3)
	for child in node.get_children():
		apply_text_contrast_to_labels(child, text_color, outline_color)


func update_cargo_full_notification() -> void:
	if cargo_full_notification == null:
		return
	cargo_full_notification.visible = get_inventory_room() <= 0


func update_hud_cargo_icons() -> void:
	if hud_cargo_icons == null:
		return
	
	clear_children(hud_cargo_icons)
	
	for resource_name in get_cargo_display_resource_names(resources):
		var count: int = int(resources.get(resource_name, 0))
		if count <= 0:
			continue
		
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 2)
		hud_cargo_icons.add_child(item)
		
		item.add_theme_constant_override("separation", 5)
		item.add_child(create_resource_icon(resource_name, Vector2(24.0, 24.0)))
		
		var count_label := Label.new()
		count_label.text = "x%d" % count
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 18)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 3)
		item.add_child(count_label)


func update_gauge_cluster() -> void:
	if modular_mining_hud != null:
		modular_mining_hud.set_capacitor(capacitor_energy, capacitor_capacity)
		modular_mining_hud.set_shield(shield_health, max_shield_health, shield_powered)
		modular_mining_hud.set_engine_levels(fuel_seconds, max_fuel_seconds, heat_ratio)
		modular_mining_hud.set_hull(hull_health, max_hull_health)
		modular_mining_hud.set_depth_meters(get_current_depth_meters())
		return
	if gauge_cluster == null:
		return
	
	var fuel_ratio: float = clampf(fuel_seconds / maxf(max_fuel_seconds, 0.01), 0.0, 1.0)
	if gauge_fuel_needle != null:
		gauge_fuel_needle.rotation = lerpf(deg_to_rad(-202.0), deg_to_rad(-42.0), fuel_ratio)
	
	if gauge_heat_needle != null:
		gauge_heat_needle.rotation = lerpf(deg_to_rad(158.0), deg_to_rad(-25.0), clampf(heat_ratio, 0.0, 1.0))
	
	if gauge_depth_label != null:
		gauge_depth_label.text = "%04d" % get_current_depth_meters()


func get_current_depth_meters() -> int:
	var player_cell := get_player_cell()
	return maxi(player_cell.y - get_first_ground_row(), 0) * depth_meters_per_row


func update_progression_metrics(delta: float) -> void:
	if is_game_over or is_arrival_countdown_active:
		return
	progression_metrics["elapsed_seconds"] = float(progression_metrics.get("elapsed_seconds", 0.0)) + delta
	if is_shop_open:
		progression_metrics["management_seconds"] = float(progression_metrics.get("management_seconds", 0.0)) + delta
	elif active_mining_cell != Vector2i(-9999, -9999):
		progression_metrics["active_drilling_seconds"] = float(progression_metrics.get("active_drilling_seconds", 0.0)) + delta
	elif miner_laser_system != null and not miner_laser_system.bolts.is_empty():
		progression_metrics["combat_seconds"] = float(progression_metrics.get("combat_seconds", 0.0)) + delta
	elif player_velocity.length_squared() > 25.0:
		progression_metrics["travel_seconds"] = float(progression_metrics.get("travel_seconds", 0.0)) + delta


func record_progression_milestone(metric_name: String) -> void:
	if float(progression_metrics.get(metric_name, -1.0)) >= 0.0:
		return
	progression_metrics[metric_name] = float(progression_metrics.get("elapsed_seconds", 0.0))


func record_resource_metric(metric_name: String, resource_name: String, amount: int) -> void:
	if amount <= 0:
		return
	var totals: Dictionary = progression_metrics.get(metric_name, {})
	totals[resource_name] = int(totals.get(resource_name, 0)) + amount
	progression_metrics[metric_name] = totals


func get_developer_progression_metrics() -> Dictionary:
	var result := progression_metrics.duplicate(true)
	var representative_break_times: Dictionary = {}
	for depth_meters in [0, 1000, 2500, 5000, 7500]:
		representative_break_times[str(depth_meters)] = get_mining_balance_readout(BlockType.DIRT, depth_meters)
	result["representative_break_times"] = representative_break_times
	return result


func _draw() -> void:
	var target_cell := get_target_mine_cell()
	var target_position := mine_tiles.map_to_local(target_cell)
	var tile_size := Vector2(64.0, 64.0)
	var target_rect := Rect2(target_position - tile_size * 0.5, tile_size)
	draw_rect(target_rect, Color(1.0, 0.9, 0.2, 0.85), false, 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over or is_arrival_countdown_active:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		var is_t_key := key_event.keycode == KEY_T or key_event.physical_keycode == KEY_T
		if key_event.pressed and not key_event.echo and key_event.ctrl_pressed and is_t_key:
			developer_test_panel.toggle()
			get_viewport().set_input_as_handled()
			return

		if key_event.pressed and not key_event.echo and not key_event.ctrl_pressed and not key_event.alt_pressed:
			var pressed_key := key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
			if pressed_key == KEY_ESCAPE:
				handle_escape_close()
				get_viewport().set_input_as_handled()
				return
			if pressed_key == KEY_I:
				if is_mining_inventory_open():
					close_mining_inventory()
				else:
					open_mining_inventory()
				get_viewport().set_input_as_handled()
				return
			if pressed_key == KEY_M:
				toggle_planet_map()
				get_viewport().set_input_as_handled()
				return
			if pressed_key == KEY_R:
				place_gps_marker()
				get_viewport().set_input_as_handled()
				return
			if pressed_key == KEY_L:
				try_construct_lift_station()
				get_viewport().set_input_as_handled()
				return
			if pressed_key == KEY_F and try_use_nearby_lift():
				get_viewport().set_input_as_handled()
				return
			if pressed_key == KEY_F and ground_encounter_system != null:
				if ground_encounter_system.try_interact():
					get_viewport().set_input_as_handled()
				return
			if pressed_key == KEY_Q:
				try_activate_radial_blast()
				get_viewport().set_input_as_handled()
				return
			if pressed_key == KEY_E:
				try_activate_directional_blast()
				get_viewport().set_input_as_handled()
				return
	
	if event.is_action_pressed(GameSettings.MENU_BACK_ACTION):
		if is_mining_inventory_open():
			close_mining_inventory()
			return
		if planet_map_overlay != null and planet_map_overlay.visible:
			close_planet_map()
			return
		if developer_test_panel != null and developer_test_panel.is_open():
			developer_test_panel.close()
			return
		if is_shop_open:
			handle_shop_back()
			return
		if is_paused and pause_menu.handle_back_request():
			return
		
		toggle_pause_menu()


func handle_escape_close() -> void:
	if is_mining_inventory_open():
		close_mining_inventory()
		return
	if planet_map_overlay != null and planet_map_overlay.visible:
		close_planet_map()
		return
	if developer_test_panel != null and developer_test_panel.is_open():
		developer_test_panel.close()
		return
	if is_shop_open:
		close_shop()
		return
	if is_paused:
		is_paused = false
		pause_menu.hide_menu()
		update_ability_buttons()
		return
	toggle_pause_menu()


func toggle_pause_menu() -> void:
	is_paused = !is_paused
	
	if is_paused:
		pause_menu.show_menu()
	else:
		pause_menu.hide_menu()
	update_ability_buttons()


func _on_resume_pressed() -> void:
	is_paused = false
	pause_menu.hide_menu()
	update_ability_buttons()


func _on_quit_pressed() -> void:
	get_tree().quit()
