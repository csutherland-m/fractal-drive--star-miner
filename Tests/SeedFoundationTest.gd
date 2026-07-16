extends SceneTree

const TEST_ROW_COUNT := 120
const SeedManagerScript := preload("res://Scripts/SeedManager.gd")

var seed_manager: Node
var last_planet_core_cell := Vector2i(-1, -1)
var last_developer_setup_worked: bool = false


func _initialize() -> void:
	call_deferred("run_seed_foundation_tests")


func run_seed_foundation_tests() -> void:
	seed_manager = root.get_node_or_null("SeedManager")
	if seed_manager == null:
		seed_manager = SeedManagerScript.new()
		seed_manager.name = "SeedManager"
		root.add_child(seed_manager)

	seed_manager.start_new_run()
	var first_galaxy_snapshot := JSON.stringify(seed_manager.galaxy_systems)
	var first_seeds := [
		seed_manager.current_run_seed,
		seed_manager.galaxy_seed,
		seed_manager.starting_system_seed,
		seed_manager.starting_planet_seed,
	]
	var first_planet_signature := await generate_starting_planet_signature()
	var first_planet_core_cell := last_planet_core_cell
	var developer_setup_worked := last_developer_setup_worked
	var first_system_signature := await generate_starting_system_signature()

	seed_manager.start_new_run()
	var second_galaxy_snapshot := JSON.stringify(seed_manager.galaxy_systems)
	var second_seeds := [
		seed_manager.current_run_seed,
		seed_manager.galaxy_seed,
		seed_manager.starting_system_seed,
		seed_manager.starting_planet_seed,
	]
	var second_planet_signature := await generate_starting_planet_signature()
	var second_planet_core_cell := last_planet_core_cell
	var second_system_signature := await generate_starting_system_signature()

	var failures: Array[String] = []
	check(first_seeds == second_seeds, "Default run seeds changed between new games.", failures)
	check(first_galaxy_snapshot == second_galaxy_snapshot, "Galaxy graph changed between new games.", failures)
	check(first_planet_signature == second_planet_signature, "Starting planet layout changed between new games.", failures)
	check(first_planet_core_cell == second_planet_core_cell, "Planet Core location changed between new games.", failures)
	check(first_planet_core_cell != Vector2i(-1, -1), "Planet Core was not generated in the test range.", failures)
	check(first_system_signature == second_system_signature, "Starting local-system layout changed between new games.", failures)
	check(developer_setup_worked, "Ctrl+T developer setup, depth teleport, or upgrade reassignment failed.", failures)
	seed_manager.start_new_run("STAR_MINER_ALTERNATE_TEST_SEED")
	check(
		JSON.stringify(seed_manager.galaxy_systems) != first_galaxy_snapshot,
		"A different run seed did not change the galaxy.",
		failures
	)
	seed_manager.start_new_run()
	check(seed_manager.galaxy_systems.size() == SeedManagerScript.MAX_GALAXY_SYSTEMS, "Galaxy does not contain 64 systems.", failures)
	check(seed_manager.get_available_next_systems().size() == 3, "Starting system does not expose three route choices.", failures)
	check(galaxy_contains_demon_system(), "Galaxy does not contain a flagged Demon system.", failures)

	var first_destination: Dictionary = seed_manager.get_available_next_systems()[0]
	check(seed_manager.select_next_system(first_destination["system_id"]), "Valid forward route selection failed.", failures)
	check(seed_manager.selected_system_path.size() == 2, "Selected path was not committed.", failures)
	check(not seed_manager.select_next_system(SeedManagerScript.STARTING_SYSTEM_ID), "Backward route selection was incorrectly allowed.", failures)

	seed_manager.start_new_run()
	check(seed_manager.starship_escape_fuel_tons == 0, "Starting Starship escape fuel was not zero.", failures)
	check(seed_manager.should_show_cargo_hauler_intro(), "Cargo hauler intro was not available at run start.", failures)
	seed_manager.mark_cargo_hauler_intro_shown()
	check(not seed_manager.should_show_cargo_hauler_intro(), "Cargo hauler intro was not limited to one display.", failures)
	seed_manager.enter_starting_planet()
	seed_manager.update_starting_escape_fuel(20, 20)
	check(
		seed_manager.starting_scenario_state == SeedManagerScript.StartingScenarioState.READY_TO_LEAVE_STARTING_PLANET,
		"Starting scenario did not become ready when escape fuel was met.",
		failures
	)
	seed_manager.load_starship_escape_fuel(20)
	check(seed_manager.starship_escape_fuel_tons == 20, "Processed escape fuel was not loaded onto the Starship.", failures)
	seed_manager.unlock_galaxy_map()
	check(
		seed_manager.starting_scenario_state == SeedManagerScript.StartingScenarioState.GALAXY_MAP_UNLOCKED,
		"Galaxy map state did not unlock.",
		failures
	)
	var unlocked_status := await get_star_system_status_text()
	check(
		unlocked_status.contains("Available next systems"),
		"Unlocked route placeholder did not list next systems. Actual text: %s" % unlocked_status,
		failures
	)

	if failures.is_empty():
		print(
			"Seed foundation tests passed. planet_signature=%s galaxy_systems=%d"
			% [first_planet_signature, seed_manager.galaxy_systems.size()]
		)
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func generate_starting_planet_signature() -> String:
	var mining_scene := load("res://Scenes/AsteroidMining.tscn") as PackedScene
	var mining_instance := mining_scene.instantiate()
	root.add_child(mining_instance)
	mining_instance.generate_rows_until(TEST_ROW_COUNT)
	var signature: String = mining_instance.get_generated_planet_layout_signature(TEST_ROW_COUNT)
	last_planet_core_cell = mining_instance.planet_core_cell
	var developer_event := InputEventKey.new()
	developer_event.keycode = KEY_T
	developer_event.ctrl_pressed = true
	developer_event.pressed = true
	mining_instance._unhandled_input(developer_event)
	var panel_opened: bool = mining_instance.developer_test_panel.is_open()
	var expected_upgrade_count := 0
	for category_upgrades in mining_instance.upgrade_definitions.values():
		expected_upgrade_count += category_upgrades.size()
	var registries_populated_panel: bool = (
		mining_instance.developer_test_panel.resource_inputs.size()
		== mining_instance.get_developer_test_resource_definitions().size()
		and mining_instance.developer_test_panel.upgrade_inputs.size() == expected_upgrade_count
	)
	var level_five_setup := {"miner_drill_efficiency": 5}
	mining_instance.apply_developer_test_configuration({
		"depth_meters": 3000,
		"credits": 500,
		"resource_counts": {"Raw Fuel": 10, "Diamond": 7},
		"rocket_fuel": 0,
		"active_fuel": 60.0,
		"upgrade_levels": level_five_setup,
	})
	var level_five_drill: float = mining_instance.drill_damage_per_second
	mining_instance.apply_developer_test_configuration({
		"depth_meters": 3000,
		"active_fuel": 60.0,
		"upgrade_levels": {"miner_drill_efficiency": 1},
	})
	var base_drill: float = mining_instance.base_upgrade_stats["drill_damage_per_second"]
	var upgrade_reassigned: bool = (
		is_equal_approx(level_five_drill, base_drill * pow(1.1, 5))
		and is_equal_approx(mining_instance.drill_damage_per_second, base_drill * 1.1)
	)
	var teleported: bool = mining_instance.get_current_depth_meters() == 3000
	mining_instance._unhandled_input(developer_event)
	last_developer_setup_worked = (
		panel_opened
		and registries_populated_panel
		and teleported
		and upgrade_reassigned
		and mining_instance.get_total_resource_count("Diamond") == 7
		and not mining_instance.developer_test_panel.is_open()
	)
	mining_instance.queue_free()
	await process_frame
	return signature


func generate_starting_system_signature() -> String:
	var star_system_scene := load("res://Scenes/StarSystemView.tscn") as PackedScene
	var star_system_instance := star_system_scene.instantiate()
	root.add_child(star_system_instance)
	var signature_data: Array = []
	for planet in star_system_instance.planets:
		signature_data.append([
			planet["name"],
			planet["type"],
			planet["orbit_radius"],
			planet["angle"],
		])
	for point_index in mini(16, star_system_instance.asteroid_belt_points.size()):
		signature_data.append(star_system_instance.asteroid_belt_points[point_index])
	for enemy in star_system_instance.enemies:
		signature_data.append([
			enemy["movement_type"],
			enemy["host_planet_index"],
			enemy["orbit_radius"],
			enemy["angle"],
		])
	star_system_instance.queue_free()
	await process_frame
	return JSON.stringify(signature_data)


func get_star_system_status_text() -> String:
	var star_system_scene := load("res://Scenes/StarSystemView.tscn") as PackedScene
	var star_system_instance := star_system_scene.instantiate()
	root.add_child(star_system_instance)
	var status_text: String = star_system_instance.status_label.text
	star_system_instance.queue_free()
	await process_frame
	return status_text


func galaxy_contains_demon_system() -> bool:
	for system_data in seed_manager.galaxy_systems:
		if system_data["is_demon_system"]:
			return true
	return false


func check(condition: bool, failure_message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(failure_message)
