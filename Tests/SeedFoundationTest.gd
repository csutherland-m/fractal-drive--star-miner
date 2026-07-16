extends SceneTree

const TEST_ROW_COUNT := 120
const SeedManagerScript := preload("res://Scripts/SeedManager.gd")
const SaveManagerScript := preload("res://Scripts/SaveManager.gd")

var seed_manager: Node
var save_manager: Node
var last_planet_core_cell := Vector2i(-1, -1)
var last_developer_setup_worked: bool = false
var last_mining_abilities_worked: bool = false
var last_save_roundtrip_worked: bool = false
var last_star_save_roundtrip_worked: bool = false


func _initialize() -> void:
	call_deferred("run_seed_foundation_tests")


func run_seed_foundation_tests() -> void:
	seed_manager = root.get_node_or_null("SeedManager")
	if seed_manager == null:
		seed_manager = SeedManagerScript.new()
		seed_manager.name = "SeedManager"
		root.add_child(seed_manager)
	save_manager = root.get_node_or_null("SaveManager")
	if save_manager == null:
		save_manager = SaveManagerScript.new()
		save_manager.name = "SaveManager"
		root.add_child(save_manager)

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
	var mining_abilities_worked := last_mining_abilities_worked
	var save_roundtrip_worked := last_save_roundtrip_worked
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
	check(last_star_save_roundtrip_worked, "Star-system save state restoration failed.", failures)
	check(developer_setup_worked, "Ctrl+T developer setup, depth teleport, or upgrade reassignment failed.", failures)
	check(mining_abilities_worked, "Q/E mining ability targeting, tuning, or blast inventory capture failed.", failures)
	check(save_roundtrip_worked, "Versioned mining save payload or terrain/state restoration failed.", failures)
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
	var fuel_rates_correct: bool = (
		is_equal_approx(mining_instance.get_fuel_drain_rate(false, true), 0.70)
		and is_equal_approx(mining_instance.get_fuel_drain_rate(true, true), 1.10)
	)
	var player_cell: Vector2i = mining_instance.get_player_cell()
	for y_offset in range(-3, 4):
		for x_offset in range(-3, 4):
			var test_cell := player_cell + Vector2i(x_offset, y_offset)
			if test_cell.x >= 0 and test_cell.x < mining_instance.grid_width and test_cell.y >= 0:
				mining_instance.block_types_by_cell[test_cell] = mining_instance.BlockType.DIRT
	var radial_targets: Array[Vector2i] = mining_instance.get_radial_blast_target_cells()
	var directions := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var directional_targets_correct := true
	for direction in directions:
		var direction_targets: Array[Vector2i] = mining_instance.get_directional_blast_target_cells(direction)
		directional_targets_correct = directional_targets_correct and direction_targets.size() == 3
	var blast_cells: Array[Vector2i] = []
	for distance in range(1, 4):
		var ore_cell := player_cell + Vector2i.RIGHT * distance
		mining_instance.block_types_by_cell[ore_cell] = mining_instance.BlockType.COPPER
		blast_cells.append(ore_cell)
	var copper_before: int = int(mining_instance.resources.get("Copper", 0))
	var captured_resources: Dictionary = mining_instance.mine_blast_target_cells(blast_cells)
	var captured_copper: int = int(captured_resources.get("Copper", 0))
	var miner_copper_before_sale: int = int(mining_instance.resources.get("Copper", 0))
	mining_instance.cargo_hold_resources["Copper"] = 12
	var credits_before_sale: int = mining_instance.credits
	mining_instance.sell_resource("Copper", 1)
	mining_instance.sell_resource("Copper", 10)
	mining_instance.sell_resource("Copper", -1)
	var tiered_lander_sale_worked: bool = (
		int(mining_instance.cargo_hold_resources.get("Copper", 0)) == 0
		and int(mining_instance.resources.get("Copper", 0)) == miner_copper_before_sale
		and mining_instance.credits == credits_before_sale + 12 * mining_instance.get_resource_value("Copper")
	)
	mining_instance.cargo_hold_resources["Copper"] = 2
	mining_instance.cargo_hold_resources["Iron"] = 3
	var miner_iron_before_sell_all: int = int(mining_instance.resources.get("Iron", 0))
	var credits_before_sell_all: int = mining_instance.credits
	mining_instance._on_sell_all_pressed()
	var lander_sell_all_worked: bool = (
		int(mining_instance.cargo_hold_resources.get("Copper", 0)) == 0
		and int(mining_instance.cargo_hold_resources.get("Iron", 0)) == 0
		and int(mining_instance.resources.get("Iron", 0)) == miner_iron_before_sell_all
		and mining_instance.credits == credits_before_sell_all
			+ 2 * mining_instance.get_resource_value("Copper")
			+ 3 * mining_instance.get_resource_value("Iron")
	)
	mining_instance.hull_health = 73
	mining_instance.credits = 30
	var repair_cost_correct: bool = mining_instance.get_full_hull_repair_credit_cost() == 27
	var repair_button_order_correct: bool = (
		mining_instance.refuel_button.get_index() < mining_instance.repair_hull_button.get_index()
		and mining_instance.repair_hull_button.get_index() < mining_instance.return_to_starship_button.get_index()
	)
	mining_instance._on_repair_hull_pressed()
	var hull_repair_worked: bool = mining_instance.hull_health == 100 and mining_instance.credits == 3
	last_mining_abilities_worked = (
		radial_targets.size() == 9
		and directional_targets_correct
		and mining_instance.get_nearest_cardinal_direction(Vector2(90.0, 20.0)) == Vector2i.RIGHT
		and mining_instance.get_nearest_cardinal_direction(Vector2(-90.0, 20.0)) == Vector2i.LEFT
		and mining_instance.get_nearest_cardinal_direction(Vector2(20.0, -90.0)) == Vector2i.UP
		and mining_instance.get_nearest_cardinal_direction(Vector2(20.0, 90.0)) == Vector2i.DOWN
		and is_equal_approx(mining_instance.radial_blast_cooldown_seconds, 60.0)
		and is_equal_approx(mining_instance.directional_blast_cooldown_seconds, 60.0)
		and is_equal_approx(
			mining_instance.get_ability_block_removal_delay(),
			mining_instance.ability_effect_duration_seconds * 0.55 / 1.5
		)
		and is_equal_approx(mining_instance.ore_pickup_text_vertical_offset_pixels, 200.0)
		and captured_copper > 0
		and int(mining_instance.resources.get("Copper", 0)) - copper_before == captured_copper
		and tiered_lander_sale_worked
		and lander_sell_all_worked
		and mining_instance.pause_menu.settings_button != null
		and mining_instance.pause_menu.mouse_directed_e_toggle != null
		and mining_instance.modular_mining_hud != null
		and mining_instance.modular_mining_hud.name == "ModularMiningHUD"
		and mining_instance.modular_mining_hud.depth_display != null
		and mining_instance.modular_mining_hud.design_root.get_node("Housing").size == MiningHud.DESIGN_SIZE
		and mining_instance.modular_mining_hud.size.x <= MiningHud.DISPLAY_SIZE.x + 0.1
		and mining_instance.modular_mining_hud.size.y <= MiningHud.DISPLAY_SIZE.y + 0.1
		and mining_instance.modular_mining_hud.radial_button == mining_instance.radial_blast_button
		and mining_instance.modular_mining_hud.directional_button == mining_instance.directional_blast_button
		and mining_instance.get_node("MiningHUD").find_child("FuelBar", true, false) == null
		and mining_instance.get_node("MiningHUD").find_child("HullHealthBar", true, false) == null
		and mining_instance.get_node("MiningHUD").find_child("MiningAbilities", true, false) == null
		and mining_instance.max_hull_health == 100
		and is_equal_approx(
			mining_instance.get_fall_damage_start_speed(),
			sqrt(2.0 * mining_instance.gravity * 3.0 * 64.0)
		)
		and mining_instance.get_fall_damage_for_impact_speed(mining_instance.get_fall_damage_start_speed() - 0.1) == 0
		and mining_instance.get_fall_damage_for_impact_speed(mining_instance.get_fall_damage_start_speed()) == 10
		and mining_instance.get_fall_damage_for_impact_speed(mining_instance.max_fall_speed) == 99
		and mining_instance.get_fall_damage_for_impact_speed(750.0) > 10
		and mining_instance.get_fall_damage_for_impact_speed(750.0) < 99
		and is_equal_approx(mining_instance.copper_ore_frequency_multiplier, 1.5)
		and mining_instance.mining_effects.get_ore_text_font_size(2, 2, 10) == mining_instance.mining_effects.floating_text_font_size
		and mining_instance.mining_effects.get_ore_text_font_size(10, 2, 10) == mining_instance.mining_effects.maximum_roll_font_size
		and mining_instance.mining_effects.get_ore_text_font_size(6, 2, 10) > mining_instance.mining_effects.floating_text_font_size
		and mining_instance.mining_effects.get_ore_text_font_size(6, 2, 10) < mining_instance.mining_effects.maximum_roll_font_size
		and repair_cost_correct
		and repair_button_order_correct
		and hull_repair_worked
		and mining_instance.game_over_label.text == mining_instance.STANDARD_DEATH_MESSAGE
	)
	var saved_layout_signature: String = mining_instance.get_generated_planet_layout_signature(mining_instance.generated_row_count)
	var saved_credits: int = mining_instance.credits
	var saved_player_cell: Vector2i = mining_instance.get_player_cell()
	var save_payload: Dictionary = save_manager.create_save_payload(
		mining_instance.scene_file_path,
		mining_instance.create_save_data()
	)
	var parsed_save = JSON.parse_string(JSON.stringify(save_payload))
	mining_instance.credits = 0
	mining_instance.block_types_by_cell.clear()
	if parsed_save is Dictionary:
		mining_instance.apply_save_data(parsed_save.get("scene_state", {}))
	last_save_roundtrip_worked = (
		parsed_save is Dictionary
		and int(parsed_save.get("save_version", 0)) == SaveManagerScript.SAVE_VERSION
		and int(parsed_save.get("generator_version", 0)) == SaveManagerScript.GENERATOR_VERSION
		and mining_instance.credits == saved_credits
		and mining_instance.get_player_cell() == saved_player_cell
		and mining_instance.get_generated_planet_layout_signature(mining_instance.generated_row_count) == saved_layout_signature
	)
	mining_instance._unhandled_input(developer_event)
	last_developer_setup_worked = (
		panel_opened
		and registries_populated_panel
		and teleported
		and upgrade_reassigned
		and fuel_rates_correct
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
	star_system_instance.player_combatant["hull"] = 8765
	star_system_instance.enemies[0]["defeated"] = true
	var saved_state: Dictionary = star_system_instance.create_save_data()
	star_system_instance.player_combatant["hull"] = 1
	star_system_instance.enemies[0]["defeated"] = false
	star_system_instance.apply_save_data(JSON.parse_string(JSON.stringify(saved_state)))
	last_star_save_roundtrip_worked = (
		int(star_system_instance.player_combatant.get("hull", 0)) == 8765
		and bool(star_system_instance.enemies[0].get("defeated", false))
	)
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
