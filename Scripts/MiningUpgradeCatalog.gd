class_name MiningUpgradeCatalog
extends RefCounted


static func create_definitions() -> Dictionary:
	return {
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
		],
		"Planetary Upgrades": [
			make_upgrade("planetary_fuel_depot", "Fuel Depot", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Raw Fuel", "amount": 1}, {"resource": "Credits", "amount": 10}], "Builds a +20 ton rocket fuel depot next to the lander.", 1),
		],
	}


static func create_stat_rules() -> Dictionary:
	return {
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


static func make_upgrade(
	upgrade_id: String,
	upgrade_name: String,
	base_costs: Array,
	description: String,
	max_level: int = StartingPlanetBalance.MK1_MAX_LEVEL
) -> Dictionary:
	return {
		"id": upgrade_id,
		"name": upgrade_name,
		"base_costs": base_costs,
		"description": description,
		"max_level": max_level,
	}


static func stat_rule(
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
