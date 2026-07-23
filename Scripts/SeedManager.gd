extends Node

const DEFAULT_SEED_TEXT := "STAR_MINER_DEFAULT_SEED_001"
const MAX_GALAXY_SYSTEMS := 64
const FINAL_PATH_DEPTH := 7
const STARTING_SYSTEM_ID := "outer_00"
const FIXED_STARTING_PLANET_SEED := 1_704_205_327
const TUTORIAL_SCHEMA_VERSION := 1
const STORY_UNSELECTED := "unselected"
const STORY_RAGS_TO_RICHES := "rags_to_riches"
const STORY_PROVE_DADDY_WRONG := "prove_daddy_wrong"
const STORY_LONE_MINER := "lone_miner"
const TUTORIAL_NOT_STARTED := "not_started"
const TUTORIAL_ACTIVE := "active"
const TUTORIAL_SKIPPED := "skipped"
const TUTORIAL_COMPLETED := "completed"
const STEP_FIRST_CONTACT := "first_contact"
const STEP_FIRST_MINING_OBJECTIVE := "first_mining_objective"
const STEP_CARE_PACKAGE := "care_package"
const STEP_RETURN_TO_LANDER := "return_to_lander"
const STEP_UI_REFUEL := "ui_refuel"
const STEP_UI_REPAIR_INFO := "ui_repair_info"
const STEP_UI_RESOURCES := "ui_resources"
const STEP_UI_SUBSPACE_NET := "ui_subspace_net"
const STEP_UI_LANDER_TAB := "ui_lander_tab"
const STEP_LANDER_BASICS_COMPLETE := "lander_basics_complete"

enum StartingScenarioState {
	STARTING_STRANDED,
	MINING_FOR_ESCAPE_FUEL,
	READY_TO_LEAVE_STARTING_PLANET,
	GALAXY_MAP_UNLOCKED,
}

var run_seed_text: String = DEFAULT_SEED_TEXT
var current_run_seed: int = 0
var galaxy_seed: int = 0
var starting_system_seed: int = 0
var starting_planet_seed: int = 0

var starting_scenario_state: StartingScenarioState = StartingScenarioState.STARTING_STRANDED
var cargo_hauler_intro_shown: bool = false
var starship_escape_fuel_tons: int = 0
var galaxy_systems: Array[Dictionary] = []
var galaxy_systems_by_id: Dictionary = {}
var selected_system_path: Array[String] = []
var current_system_id: String = STARTING_SYSTEM_ID
var tutorial_schema_version: int = TUTORIAL_SCHEMA_VERSION
var player_story_id: String = STORY_UNSELECTED
var tutorial_state: String = TUTORIAL_NOT_STARTED
var tutorial_step_id: String = STEP_FIRST_CONTACT
var tutorial_dialogue_node_id: String = "FC_001"
var completed_tutorial_step_ids: Array[String] = []


func _ready() -> void:
	start_new_run()


func start_new_run(seed_text: String = DEFAULT_SEED_TEXT) -> void:
	run_seed_text = seed_text if not seed_text.is_empty() else DEFAULT_SEED_TEXT
	current_run_seed = stable_seed_from_text(run_seed_text)
	galaxy_seed = derive_seed(current_run_seed, "galaxy")
	starting_system_seed = derive_seed(current_run_seed, "starting_system")
	# The tutorial planet is deliberately identical in every run so its opening
	# resources and progression can be balanced without a bad-seed failure.
	starting_planet_seed = FIXED_STARTING_PLANET_SEED
	starting_scenario_state = StartingScenarioState.STARTING_STRANDED
	cargo_hauler_intro_shown = false
	starship_escape_fuel_tons = 0
	current_system_id = STARTING_SYSTEM_ID
	selected_system_path = [STARTING_SYSTEM_ID]
	tutorial_schema_version = TUTORIAL_SCHEMA_VERSION
	player_story_id = STORY_UNSELECTED
	tutorial_state = TUTORIAL_NOT_STARTED
	tutorial_step_id = STEP_FIRST_CONTACT
	tutorial_dialogue_node_id = "FC_001"
	completed_tutorial_step_ids.clear()
	generate_galaxy_structure()


func stable_seed_from_text(seed_text: String) -> int:
	# A small deterministic DJB2-style hash avoids platform-dependent random seeds.
	var hash_value: int = 5381
	for index in seed_text.length():
		hash_value = (hash_value * 33 + seed_text.unicode_at(index)) % 2147483647
	return maxi(hash_value, 1)


func derive_seed(base_seed: int, purpose: String) -> int:
	return stable_seed_from_text("%d:%s" % [base_seed, purpose])


func generate_galaxy_structure() -> void:
	galaxy_systems.clear()
	galaxy_systems_by_id.clear()
	var systems_by_depth: Dictionary = {}
	var galaxy_rng := RandomNumberGenerator.new()
	galaxy_rng.seed = galaxy_seed

	add_galaxy_system(
		create_system_data(STARTING_SYSTEM_ID, "Quiet Reach", starting_system_seed, 0, false, galaxy_rng),
		systems_by_depth
	)

	# One tutorial system plus nine systems at each of seven later depths = 64 systems.
	for path_depth in range(1, FINAL_PATH_DEPTH + 1):
		for system_index in 9:
			var system_id := "depth_%02d_system_%02d" % [path_depth, system_index]
			var is_demon_system := (
				path_depth >= 6
				and (galaxy_rng.randf() < get_demon_system_chance(path_depth) or (path_depth == 7 and system_index == 0))
			)
			add_galaxy_system(
				create_system_data(
					system_id,
					create_system_display_name(path_depth, system_index, galaxy_rng),
					galaxy_rng.randi_range(1, 2147483646),
					path_depth,
					is_demon_system,
					galaxy_rng
				),
				systems_by_depth
			)

	connect_galaxy_depths(systems_by_depth, galaxy_rng)


func add_galaxy_system(system_data: Dictionary, systems_by_depth: Dictionary) -> void:
	galaxy_systems.append(system_data)
	galaxy_systems_by_id[system_data["system_id"]] = system_data
	var path_depth: int = system_data["path_depth"]
	if not systems_by_depth.has(path_depth):
		systems_by_depth[path_depth] = []
	var depth_system_ids: Array = systems_by_depth[path_depth]
	depth_system_ids.append(system_data["system_id"])


func create_system_data(
	system_id: String,
	display_name: String,
	system_seed: int,
	path_depth: int,
	is_demon_system: bool,
	galaxy_rng: RandomNumberGenerator
) -> Dictionary:
	return {
		"system_id": system_id,
		"display_name": display_name,
		"system_seed": system_seed,
		"path_depth": path_depth,
		"difficulty_tier": get_difficulty_for_path_depth(path_depth),
		"available_resources": get_resources_for_path_depth(path_depth, galaxy_rng),
		"is_demon_system": is_demon_system,
		"connected_system_ids": [],
	}


func create_system_display_name(path_depth: int, system_index: int, galaxy_rng: RandomNumberGenerator) -> String:
	var prefixes: Array[String] = ["Outer", "Pale", "Broken", "Iron", "Veiled", "Ember", "Demon", "Abyssal"]
	var suffixes: Array[String] = ["Reach", "Crossing", "Haven", "Drift", "Crown", "Gate", "Expanse", "March", "Spur"]
	var prefix := prefixes[mini(path_depth, prefixes.size() - 1)]
	var suffix := suffixes[galaxy_rng.randi_range(0, suffixes.size() - 1)]
	return "%s %s %02d" % [prefix, suffix, system_index + 1]


func connect_galaxy_depths(systems_by_depth: Dictionary, galaxy_rng: RandomNumberGenerator) -> void:
	for path_depth in range(FINAL_PATH_DEPTH):
		var current_ids: Array = systems_by_depth.get(path_depth, [])
		var next_ids: Array = systems_by_depth.get(path_depth + 1, [])
		if next_ids.is_empty():
			continue

		for current_index in current_ids.size():
			var connection_count := 3 if path_depth == 0 else 2
			var first_target_index := (
				current_index * 2 + galaxy_rng.randi_range(0, next_ids.size() - 1)
			) % next_ids.size()
			var connections: Array[String] = []
			for connection_offset in connection_count:
				var target_id: String = next_ids[(first_target_index + connection_offset) % next_ids.size()]
				if not connections.has(target_id):
					connections.append(target_id)
			galaxy_systems_by_id[current_ids[current_index]]["connected_system_ids"] = connections


func get_difficulty_for_path_depth(path_depth: int) -> int:
	return clampi(path_depth + 1, 1, FINAL_PATH_DEPTH + 1)


func get_resources_for_path_depth(path_depth: int, galaxy_rng: RandomNumberGenerator) -> Array[String]:
	var resources: Array[String] = ["iron", "copper", "carbon", "silicon"]
	if path_depth >= 2:
		resources.append("gold")
	if path_depth >= 4:
		resources.append("diamond")
	if path_depth >= 5:
		resources.append("warp_gems")
	if path_depth >= 6:
		resources.append("black_hole_crystals")
	if path_depth > 0 and galaxy_rng.randf() < 0.35:
		resources.append("treasure")
	return resources


func get_demon_system_chance(path_depth: int) -> float:
	if path_depth < 6:
		return 0.0
	return 0.35 if path_depth == 6 else 0.7


func get_current_system() -> Dictionary:
	return galaxy_systems_by_id.get(current_system_id, {})


func get_current_system_seed() -> int:
	var current_system := get_current_system()
	return int(current_system.get("system_seed", starting_system_seed))


func get_available_next_systems() -> Array[Dictionary]:
	var available_systems: Array[Dictionary] = []
	var current_system := get_current_system()
	for connected_id in current_system.get("connected_system_ids", []):
		if galaxy_systems_by_id.has(connected_id):
			available_systems.append(galaxy_systems_by_id[connected_id])
	return available_systems


func select_next_system(system_id: String) -> bool:
	var current_system := get_current_system()
	var connected_ids: Array = current_system.get("connected_system_ids", [])
	if not connected_ids.has(system_id) or not galaxy_systems_by_id.has(system_id):
		return false

	current_system_id = system_id
	selected_system_path.append(system_id)
	return true


func print_available_next_systems() -> void:
	var current_system := get_current_system()
	print("Available systems after %s:" % current_system.get("display_name", current_system_id))
	for system_data in get_available_next_systems():
		print(
			"- %s [%s], depth %d, difficulty %d, demon=%s"
			% [
				system_data["display_name"],
				system_data["system_id"],
				system_data["path_depth"],
				system_data["difficulty_tier"],
				str(system_data["is_demon_system"]),
			]
		)


func enter_starting_planet() -> void:
	if starting_scenario_state == StartingScenarioState.STARTING_STRANDED:
		starting_scenario_state = StartingScenarioState.MINING_FOR_ESCAPE_FUEL


func update_starting_escape_fuel(current_rocket_fuel: int, required_rocket_fuel: int) -> void:
	if starting_scenario_state == StartingScenarioState.GALAXY_MAP_UNLOCKED:
		return
	if current_rocket_fuel >= required_rocket_fuel:
		starting_scenario_state = StartingScenarioState.READY_TO_LEAVE_STARTING_PLANET
	elif starting_scenario_state != StartingScenarioState.STARTING_STRANDED:
		starting_scenario_state = StartingScenarioState.MINING_FOR_ESCAPE_FUEL


func unlock_galaxy_map() -> void:
	starting_scenario_state = StartingScenarioState.GALAXY_MAP_UNLOCKED


func load_starship_escape_fuel(fuel_tons: int) -> void:
	starship_escape_fuel_tons = maxi(fuel_tons, 0)


func is_starting_scenario_active() -> bool:
	return starting_scenario_state != StartingScenarioState.GALAXY_MAP_UNLOCKED


func should_show_cargo_hauler_intro() -> bool:
	return is_starting_scenario_active() and not cargo_hauler_intro_shown


func mark_cargo_hauler_intro_shown() -> void:
	cargo_hauler_intro_shown = true


func set_player_story(story_id: String) -> void:
	if story_id in [STORY_RAGS_TO_RICHES, STORY_PROVE_DADDY_WRONG, STORY_LONE_MINER]:
		player_story_id = story_id


func set_tutorial_dialogue_node(node_id: String) -> void:
	tutorial_dialogue_node_id = node_id


func set_tutorial_step(step_id: String, mark_previous_complete: bool = true) -> void:
	if mark_previous_complete and not tutorial_step_id.is_empty() and not completed_tutorial_step_ids.has(tutorial_step_id):
		completed_tutorial_step_ids.append(tutorial_step_id)
	tutorial_step_id = step_id
	tutorial_dialogue_node_id = ""


func begin_guided_tutorial() -> void:
	tutorial_state = TUTORIAL_ACTIVE
	set_tutorial_step(STEP_FIRST_MINING_OBJECTIVE)
	cargo_hauler_intro_shown = true


func skip_tutorial() -> void:
	if tutorial_state == TUTORIAL_SKIPPED:
		return
	if not tutorial_step_id.is_empty() and not completed_tutorial_step_ids.has(tutorial_step_id):
		completed_tutorial_step_ids.append(tutorial_step_id)
	tutorial_state = TUTORIAL_SKIPPED
	tutorial_step_id = ""
	tutorial_dialogue_node_id = ""
	cargo_hauler_intro_shown = true


func is_tutorial_parked_or_finished() -> bool:
	return (
		tutorial_state in [TUTORIAL_SKIPPED, TUTORIAL_COMPLETED]
		or tutorial_step_id == STEP_LANDER_BASICS_COMPLETE
	)


func is_starting_upgrade_interface_unlocked() -> bool:
	return is_tutorial_parked_or_finished()


func should_start_first_contact() -> bool:
	return (
		is_starting_scenario_active()
		and tutorial_state == TUTORIAL_NOT_STARTED
		and tutorial_step_id == STEP_FIRST_CONTACT
	)


func get_cargo_hauler_intro_pages() -> Array[String]:
	return [
		(
			"Howdy, greenhorn. Welcome to Quiet Reach.\n\n"
			+ "I'm the cargo hauler assigned to this patch of nowhere. I'll keep an eye on your operation "
			+ "and send down equipment when you've proved you know which end of the drill goes in the dirt."
		),
		(
			"You must be new to this whole mining thing, so here's how you handle that rig:\n\n"
			+ "A / D or Left / Right: drive and drill sideways\n"
			+ "S or Down: drill downward\n"
			+ "W, Up, or Space: fire your upward thrusters\n"
			+ "Left Mouse: fire the mining laser\n"
			+ "Q: radial explosive blast    E: directional explosive blast\n"
			+ "F: interact or ride a lift    L: plan a lift after fabrication unlocks\n"
			+ "I: open miner inventory and dump unwanted cargo one unit at a time\n"
			+ "R: place a fabricated GPS shaft marker\n"
			+ "M: open the explored planet map; drag or use arrows to pan, mouse wheel to zoom\n"
			+ "Esc: close the whole menu or overlay\n"
			+ "Pause / Break: go back one menu (rebind it in Settings)"
		),
		(
			"Now here's the job, yahoo: you're gonna want to get down there, find some fuel and ore, "
			+ "and haul it back up to the surface. Use what you bring home to upgrade your gear, fabricate "
			+ "better parts, and push that shaft deeper.\n\n"
			+ "Once you get down a bit farther, I'll check back in and show you a few tricks for getting real rich. "
			+ "For now, keep one eye on your fuel gauge and the other on your cargo hold. A full hold means "
			+ "it's time to haul your riches home, and an empty fuel tank means game over—stuck down there to die "
			+ "alone in the depths of an alien world. Don't let a shiny rock talk you into a one-way trip."
		),
	]


func get_cargo_hauler_intro_text() -> String:
	# Compatibility helper for callers that still expect one combined message.
	return "\n\n".join(get_cargo_hauler_intro_pages())


func get_cargo_hauler_shallow_scan_text() -> String:
	return (
		"Shallow scan coming through, greenhorn. I've tagged your first three copper, iron, and raw-fuel "
		+ "blocks with pixie dust to get you pointed toward payday.\n\n"
		+ "There's a richer spread of copper and iron in the first 300 meters, too. Follow the sparkle, "
		+ "mind your fuel and cargo, and bring the haul back to the surface."
	)


func get_starting_scenario_state_name() -> String:
	return StartingScenarioState.keys()[starting_scenario_state]


func create_save_data() -> Dictionary:
	return {
		"run_seed_text": run_seed_text,
		"current_run_seed": current_run_seed,
		"galaxy_seed": galaxy_seed,
		"starting_system_seed": starting_system_seed,
		"starting_planet_seed": starting_planet_seed,
		"starting_scenario_state": int(starting_scenario_state),
		"cargo_hauler_intro_shown": cargo_hauler_intro_shown,
		"starship_escape_fuel_tons": starship_escape_fuel_tons,
		"galaxy_systems": galaxy_systems.duplicate(true),
		"selected_system_path": selected_system_path.duplicate(),
		"current_system_id": current_system_id,
		"tutorial_schema_version": tutorial_schema_version,
		"player_story_id": player_story_id,
		"tutorial_state": tutorial_state,
		"tutorial_step_id": tutorial_step_id,
		"tutorial_dialogue_node_id": tutorial_dialogue_node_id,
		"completed_tutorial_step_ids": completed_tutorial_step_ids.duplicate(),
	}


func apply_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	run_seed_text = str(data.get("run_seed_text", DEFAULT_SEED_TEXT))
	current_run_seed = int(data.get("current_run_seed", stable_seed_from_text(run_seed_text)))
	galaxy_seed = int(data.get("galaxy_seed", derive_seed(current_run_seed, "galaxy")))
	starting_system_seed = int(data.get("starting_system_seed", derive_seed(current_run_seed, "starting_system")))
	starting_planet_seed = FIXED_STARTING_PLANET_SEED
	starting_scenario_state = clampi(
		int(data.get("starting_scenario_state", StartingScenarioState.STARTING_STRANDED)),
		StartingScenarioState.STARTING_STRANDED,
		StartingScenarioState.GALAXY_MAP_UNLOCKED
	) as StartingScenarioState
	cargo_hauler_intro_shown = bool(data.get("cargo_hauler_intro_shown", false))
	starship_escape_fuel_tons = maxi(int(data.get("starship_escape_fuel_tons", 0)), 0)
	galaxy_systems.clear()
	galaxy_systems_by_id.clear()
	for saved_system in data.get("galaxy_systems", []):
		if not saved_system is Dictionary:
			continue
		var system_data: Dictionary = saved_system.duplicate(true)
		galaxy_systems.append(system_data)
		galaxy_systems_by_id[str(system_data.get("system_id", ""))] = system_data
	if galaxy_systems.is_empty():
		generate_galaxy_structure()
	selected_system_path.clear()
	for system_id in data.get("selected_system_path", [STARTING_SYSTEM_ID]):
		selected_system_path.append(str(system_id))
	if selected_system_path.is_empty():
		selected_system_path.append(STARTING_SYSTEM_ID)
	current_system_id = str(data.get("current_system_id", selected_system_path[-1]))
	if data.has("tutorial_schema_version"):
		tutorial_schema_version = int(data.get("tutorial_schema_version", TUTORIAL_SCHEMA_VERSION))
		player_story_id = str(data.get("player_story_id", STORY_UNSELECTED))
		tutorial_state = str(data.get("tutorial_state", TUTORIAL_NOT_STARTED))
		if not tutorial_state in [TUTORIAL_NOT_STARTED, TUTORIAL_ACTIVE, TUTORIAL_SKIPPED, TUTORIAL_COMPLETED]:
			tutorial_state = TUTORIAL_SKIPPED
		tutorial_step_id = str(data.get("tutorial_step_id", ""))
		tutorial_dialogue_node_id = str(data.get("tutorial_dialogue_node_id", ""))
		completed_tutorial_step_ids.clear()
		for step_id in data.get("completed_tutorial_step_ids", []):
			var saved_step_id := str(step_id)
			if not completed_tutorial_step_ids.has(saved_step_id):
				completed_tutorial_step_ids.append(saved_step_id)
	else:
		# Existing playtest saves predate this tutorial. Preserve their progression
		# and never force the new opening or its UI locks on top of an active run.
		tutorial_schema_version = TUTORIAL_SCHEMA_VERSION
		player_story_id = STORY_UNSELECTED
		tutorial_state = TUTORIAL_SKIPPED
		tutorial_step_id = ""
		tutorial_dialogue_node_id = ""
		completed_tutorial_step_ids.clear()
