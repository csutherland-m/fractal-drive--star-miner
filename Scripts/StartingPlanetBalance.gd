class_name StartingPlanetBalance
extends RefCounted

const CONFIG_VERSION := 6
const FIXED_PLANET_SEED := 1_704_205_327
const CORE_DEPTH_METERS := 7500.0
const CORE_DEPTH_DURABILITY_BONUS := 1.2
const MK1_MAX_LEVEL := 5
const MK1_STAT_MULTIPLIER := 1.2
const MK1_REDUCTION_MULTIPLIER := 1.0 / MK1_STAT_MULTIPLIER
const MK1_RESOURCE_COST_SCALE := 2
const BASE_DRILL_DPS := 2.0

const SENSOR_VISIBLE_RADIUS_BY_LEVEL := [1, 2, 2, 3, 3, 4]
const SENSOR_DETECTION_EXTENSION_BY_LEVEL := [0, 0, 1, 1, 2, 2]
const SHALLOW_STARTER_ORE_DEPTH_METERS := 300
# The normal shallow table already contains 1.43% Copper and 0.845% Raw Fuel.
# These small conversion chances lift each by approximately 15% without creating
# another rich-start layer on top of the nine authored tutorial blocks.
const SHALLOW_COPPER_CHANCE := 0.002145
const SHALLOW_RAW_FUEL_CHANCE := 0.0012675
const EARLY_IRON_DEPTH_METERS := 1000
const EARLY_IRON_CHANCE := 0.0203125

const MATERIAL_BASE_DURABILITY := {
	"dirt": 0.735,
	"copper": 1.75,
	"raw_fuel": 1.75,
	"iron": 1.75,
	"gold": 2.1,
	"treasure": 2.1,
	"rock": 1.96,
	"diamond": 2.8,
	"warp_gems": 3.5,
	"black_hole_crystals": 3.5,
	"planet_core": 3.5,
}

# These authored deposits are the one deliberate exception to normal ore-depth rules.
# They keep the tutorial economy deterministic without changing later planets.
const GUARANTEED_STARTER_DEPOSITS := {
	"copper": [Vector2i(-3, 2), Vector2i(-2, 2), Vector2i(-2, 3)],
	"raw_fuel": [Vector2i(3, 2), Vector2i(4, 2), Vector2i(4, 3)],
	"iron": [Vector2i(-6, 3), Vector2i(-5, 3), Vector2i(-4, 3)],
}

const GUIDED_STARTER_DEPOSITS := {
	"copper": [Vector2i(-3, 2), Vector2i(-2, 2), Vector2i(-2, 3)],
	"raw_fuel": [Vector2i(3, 2), Vector2i(4, 2), Vector2i(4, 3)],
	"iron": [Vector2i(-6, 3), Vector2i(-5, 3), Vector2i(-4, 3)],
}

const FABRICATOR_RECIPES := {
	"copper_bar": {
		"name": "Copper Bar",
		"inputs": {"Copper": 3},
		"output": "Copper Bar",
		"amount": 1,
	},
	"iron_bar": {
		"name": "Iron Bar",
		"inputs": {"Iron": 3},
		"output": "Iron Bar",
		"amount": 1,
	},
	"gold_bar": {
		"name": "Gold Bar",
		"inputs": {"Gold": 3},
		"output": "Gold Bar",
		"amount": 1,
	},
	"silicone_wafer": {
		"name": "Silicone Wafer",
		"inputs": {"Silicone": 1},
		"output": "Silicone Wafer",
		"amount": 2,
	},
	"copper_wire": {
		"name": "Copper Wire",
		"inputs": {"Copper Bar": 1},
		"output": "Copper Wire",
		"amount": 2,
	},
	"iron_wire": {
		"name": "Iron Wire",
		"inputs": {"Iron Bar": 1},
		"output": "Iron Wire",
		"amount": 2,
	},
	"basic_circuit": {
		"name": "Basic Circuit",
		"inputs": {"Copper Wire": 1, "Iron Wire": 1, "Gold Bar": 1, "Silicone Wafer": 1},
		"output": "Basic Circuit",
		"amount": 1,
	},
	"gps_marker": {
		"name": "GPS Marker Pack",
		"inputs": {"Iron Bar": 1, "Basic Circuit": 1},
		"output": "GPS Marker",
		"amount": 5,
	},
	"explosive_charge": {
		"name": "Explosive Charge",
		"inputs": {"Raw Fuel": 1, "Copper Bar": 2, "Iron Wire": 1},
		"output": "Explosive Charge",
		"amount": 10,
	},
}

const LIFT_BLOCKS_PER_IRON := 4
const LIFT_BLOCKS_PER_COPPER := 3
const LIFT_CIRCUITS_PER_STATION := 1


static func get_depth_multiplier(depth_meters: float, core_depth_meters: float = CORE_DEPTH_METERS) -> float:
	var depth_ratio := clampf(depth_meters / maxf(core_depth_meters, 1.0), 0.0, 1.0)
	return 1.0 + CORE_DEPTH_DURABILITY_BONUS * depth_ratio


static func get_visible_radius(sensor_level: int) -> int:
	return SENSOR_VISIBLE_RADIUS_BY_LEVEL[clampi(sensor_level, 0, MK1_MAX_LEVEL)]


static func get_detection_extension(sensor_level: int) -> int:
	return SENSOR_DETECTION_EXTENSION_BY_LEVEL[clampi(sensor_level, 0, MK1_MAX_LEVEL)]


static func get_lift_cost(height_blocks: int) -> Dictionary:
	var safe_height := maxi(height_blocks, 0)
	return {
		"Iron": ceili(float(safe_height) / float(LIFT_BLOCKS_PER_IRON)),
		"Copper": ceili(float(safe_height) / float(LIFT_BLOCKS_PER_COPPER)),
		"Basic Circuit": LIFT_CIRCUITS_PER_STATION,
	}
