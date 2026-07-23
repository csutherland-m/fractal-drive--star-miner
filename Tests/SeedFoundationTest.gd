extends SceneTree

const TEST_ROW_COUNT := 120
const EXPECTED_DEFAULT_PLANET_SIGNATURE := "144209399"
const SeedManagerScript := preload("res://Scripts/SeedManager.gd")
const SaveManagerScript := preload("res://Scripts/SaveManager.gd")

var seed_manager: Node
var save_manager: Node
var last_planet_core_cell := Vector2i(-1, -1)
var last_developer_setup_worked: bool = false
var last_mining_abilities_worked: bool = false
var last_save_roundtrip_worked: bool = false
var last_star_save_roundtrip_worked: bool = false
var last_core_vault_worked: bool = false


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
	var core_vault_worked := last_core_vault_worked
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
	check(save_manager.SLOT_COUNT == 3, "Save manager does not expose three playtest slots.", failures)
	check(
		save_manager.get_save_path(1) != save_manager.get_save_path(2)
		and save_manager.get_save_path(2) != save_manager.get_save_path(3),
		"Save slots do not use independent files.",
		failures
	)
	var main_menu_scene := load("res://Scenes/main_game_menu.tscn") as PackedScene
	var main_menu_instance := main_menu_scene.instantiate()
	root.add_child(main_menu_instance)
	check(
		main_menu_instance.slot_buttons.size() == 3
		and main_menu_instance.continue_button.text.contains("Slot"),
		"Main menu does not expose selectable three-slot New Game and Continue controls.",
		failures
	)
	main_menu_instance.queue_free()
	check(first_seeds == second_seeds, "Default run seeds changed between new games.", failures)
	check(first_galaxy_snapshot == second_galaxy_snapshot, "Galaxy graph changed between new games.", failures)
	check(first_planet_signature == second_planet_signature, "Starting planet layout changed between new games.", failures)
	check(first_planet_signature == EXPECTED_DEFAULT_PLANET_SIGNATURE, "Starting planet layout differs from the approved baseline.", failures)
	check(first_planet_core_cell == second_planet_core_cell, "Planet Core location changed between new games.", failures)
	check(first_planet_core_cell != Vector2i(-1, -1), "Planet Core was not generated in the test range.", failures)
	check(first_system_signature == second_system_signature, "Starting local-system layout changed between new games.", failures)
	check(last_star_save_roundtrip_worked, "Star-system save state restoration failed.", failures)
	check(developer_setup_worked, "Ctrl+T developer setup, depth teleport, or upgrade reassignment failed.", failures)
	check(mining_abilities_worked, "Q/E mining ability targeting, tuning, or blast inventory capture failed.", failures)
	check(save_roundtrip_worked, "Versioned mining save payload or terrain/state restoration failed.", failures)
	check(core_vault_worked, "Core barrier, vault altar, or five-wave lockdown encounter failed.", failures)
	seed_manager.start_new_run("STAR_MINER_ALTERNATE_TEST_SEED")
	check(
		JSON.stringify(seed_manager.galaxy_systems) != first_galaxy_snapshot,
		"A different run seed did not change the galaxy.",
		failures
	)
	check(
		seed_manager.starting_planet_seed == first_seeds[3],
		"The authored starting planet changed with the galaxy run seed.",
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
	check(seed_manager.should_start_first_contact(), "First Contact was not available at run start.", failures)
	var first_contact_opening: Dictionary = TutorialContent.get_first_contact_node("FC_001")
	var story_choice: Dictionary = TutorialContent.get_first_contact_node("FC_CHOICE_STORY")
	check(
		str(first_contact_opening.get("text", "")).contains("bullfrog")
		and story_choice.get("choices", []).size() == 3,
		"First Contact dialogue or story choices are incomplete.",
		failures
	)
	seed_manager.set_player_story(SeedManagerScript.STORY_RAGS_TO_RICHES)
	seed_manager.begin_guided_tutorial()
	check(
		seed_manager.tutorial_state == SeedManagerScript.TUTORIAL_ACTIVE
		and seed_manager.tutorial_step_id == SeedManagerScript.STEP_FIRST_MINING_OBJECTIVE,
		"Accepting First Contact did not begin the guided mining objective.",
		failures
	)
	seed_manager.skip_tutorial()
	seed_manager.skip_tutorial()
	check(
		seed_manager.tutorial_state == SeedManagerScript.TUTORIAL_SKIPPED
		and seed_manager.is_starting_upgrade_interface_unlocked(),
		"Tutorial skip was not idempotent or did not unlock the starting interface.",
		failures
	)
	var rejected_old_save: Dictionary = save_manager.validate_save_data({
		"save_version": SaveManagerScript.SAVE_VERSION - 1,
		"generator_version": SaveManagerScript.GENERATOR_VERSION,
		"run_state": {},
		"scene_state": {},
	})
	var accepted_current_save: Dictionary = save_manager.validate_save_data({
		"save_version": SaveManagerScript.SAVE_VERSION,
		"generator_version": SaveManagerScript.GENERATOR_VERSION,
		"run_state": {},
		"scene_state": {},
	})
	check(
		rejected_old_save.is_empty()
		and int(accepted_current_save.get("save_version", 0)) == SaveManagerScript.SAVE_VERSION,
		"Save validation did not reject the intentionally incompatible schema.",
		failures
	)
	seed_manager.start_new_run()
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
	await process_frame
	var onboarding_dialog_worked: bool = (
		mining_instance.tutorial_overlay != null
		and mining_instance.tutorial_overlay.dialogue_panel.visible
		and mining_instance.tutorial_overlay.dialogue_label.text.contains("bullfrog")
		and mining_instance.tutorial_overlay.dialogue_label.autowrap_mode
			== TextServer.AUTOWRAP_WORD_SMART
	)
	mining_instance._on_tutorial_continue_requested()
	mining_instance._on_tutorial_continue_requested()
	onboarding_dialog_worked = onboarding_dialog_worked and mining_instance.tutorial_overlay.choice_box.get_child_count() == 3
	mining_instance._on_tutorial_choice_selected("story_rags_to_riches")
	mining_instance._on_tutorial_continue_requested()
	mining_instance._on_tutorial_choice_selected("accept_tutorial")
	mining_instance._on_tutorial_continue_requested()
	mining_instance._on_tutorial_continue_requested()
	onboarding_dialog_worked = (
		onboarding_dialog_worked
		and seed_manager.player_story_id == SeedManagerScript.STORY_RAGS_TO_RICHES
		and seed_manager.tutorial_state == SeedManagerScript.TUTORIAL_ACTIVE
		and seed_manager.tutorial_step_id == SeedManagerScript.STEP_FIRST_MINING_OBJECTIVE
		and not mining_instance.is_paused
	)
	mining_instance.resources["Copper"] = 100
	mining_instance.resources["Iron"] = 100
	mining_instance.check_care_package_trigger()
	onboarding_dialog_worked = onboarding_dialog_worked and seed_manager.tutorial_step_id == SeedManagerScript.STEP_CARE_PACKAGE
	mining_instance._on_tutorial_continue_requested()
	onboarding_dialog_worked = (
		onboarding_dialog_worked
		and mining_instance.fabricator_unlocked
		and seed_manager.tutorial_step_id == SeedManagerScript.STEP_RETURN_TO_LANDER
		and not mining_instance.is_paused
	)
	mining_instance.open_shop()
	mining_instance.show_current_ui_tutorial_step()
	onboarding_dialog_worked = (
		onboarding_dialog_worked
		and seed_manager.tutorial_step_id == SeedManagerScript.STEP_UI_REFUEL
		and not mining_instance.refuel_button.disabled
		and mining_instance.repair_hull_button.disabled
	)
	mining_instance._on_refuel_pressed()
	mining_instance.show_current_ui_tutorial_step()
	mining_instance._on_tutorial_continue_requested()
	mining_instance.show_current_ui_tutorial_step()
	mining_instance._on_tutorial_continue_requested()
	mining_instance.show_current_ui_tutorial_step()
	mining_instance._on_tutorial_continue_requested()
	mining_instance.show_current_ui_tutorial_step()
	onboarding_dialog_worked = (
		onboarding_dialog_worked
		and seed_manager.tutorial_step_id == SeedManagerScript.STEP_UI_LANDER_TAB
		and mining_instance.get_tutorial_target("navigation.lander") != null
	)
	mining_instance.open_lander_tutorial_target()
	onboarding_dialog_worked = (
		onboarding_dialog_worked
		and seed_manager.tutorial_state == SeedManagerScript.TUTORIAL_ACTIVE
		and seed_manager.tutorial_step_id == SeedManagerScript.STEP_LANDER_BASICS_COMPLETE
		and mining_instance.tutorial_allowed_action_id.is_empty()
	)
	mining_instance.apply_tutorial_skip()
	mining_instance.apply_tutorial_skip()
	onboarding_dialog_worked = (
		onboarding_dialog_worked
		and not mining_instance.tutorial_overlay.dialogue_panel.visible
		and mining_instance.fabricator_unlocked
		and seed_manager.tutorial_state == SeedManagerScript.TUTORIAL_SKIPPED
		and mining_instance.is_upgrade_relevant(mining_instance.find_upgrade_definition("miner_drill_efficiency"))
		and not mining_instance.is_upgrade_relevant(mining_instance.find_upgrade_definition("miner_weapon_damage"))
	)
	# Continue the broader balance suite in the guided endpoint state so its
	# relevance checks still exercise progressive disclosure rather than skip mode.
	seed_manager.tutorial_state = SeedManagerScript.TUTORIAL_ACTIVE
	seed_manager.tutorial_step_id = SeedManagerScript.STEP_LANDER_BASICS_COMPLETE
	mining_instance.close_shop()
	mining_instance.resources.clear()
	mining_instance.generate_rows_until(TEST_ROW_COUNT)
	var signature: String = mining_instance.get_generated_planet_layout_signature(TEST_ROW_COUNT)
	mining_instance.generate_rows_until(
		mining_instance.get_core_vault_top_row() + mining_instance.core_vault_height_blocks + 2
	)
	last_planet_core_cell = mining_instance.planet_core_cell
	var lander_column: int = mining_instance.get_lander_surface_column()
	var ground_row: int = mining_instance.get_first_ground_row()
	var shallow_copper_count := 0
	var shallow_iron_count := 0
	var shallow_bottom_row := ground_row + floori(
		float(StartingPlanetBalance.SHALLOW_STARTER_ORE_DEPTH_METERS)
		/ float(mining_instance.depth_meters_per_row)
	)
	for row in range(ground_row, shallow_bottom_row + 1):
		for column in mining_instance.grid_width:
			var shallow_type: int = mining_instance.block_types_by_cell.get(Vector2i(column, row), -1)
			if shallow_type == mining_instance.BlockType.COPPER:
				shallow_copper_count += 1
			elif shallow_type == mining_instance.BlockType.IRON:
				shallow_iron_count += 1
	var guided_starter_cells: Array[Vector2i] = mining_instance.get_guided_starter_ore_cells()
	var first_thousand_iron_count := 0
	var first_thousand_bottom := ground_row + floori(
		float(StartingPlanetBalance.EARLY_IRON_DEPTH_METERS) / float(mining_instance.depth_meters_per_row)
	)
	for row in range(ground_row, first_thousand_bottom + 1):
		for column in mining_instance.grid_width:
			if mining_instance.block_types_by_cell.get(Vector2i(column, row), -1) == mining_instance.BlockType.IRON:
				first_thousand_iron_count += 1
	var guided_cells_are_shallow := guided_starter_cells.all(
		func(cell: Vector2i): return cell.y >= ground_row and cell.y < ground_row + 5
	)
	var lodestone_tracking_matches := true
	for cell in mining_instance.block_types_by_cell:
		var is_lodestone: bool = mining_instance.block_types_by_cell[cell] == mining_instance.BlockType.LODESTONE
		lodestone_tracking_matches = lodestone_tracking_matches and is_lodestone == mining_instance.lodestone_cells.has(cell)
	for cell in mining_instance.lodestone_cells:
		lodestone_tracking_matches = (
			lodestone_tracking_matches
			and mining_instance.block_types_by_cell.get(cell, mining_instance.BlockType.EMPTY)
				== mining_instance.BlockType.LODESTONE
		)
	var alpha_systems_worked: bool = (
		onboarding_dialog_worked
		and lodestone_tracking_matches
		and guided_starter_cells.size() == 9
		and guided_cells_are_shallow
		and is_equal_approx(StartingPlanetBalance.SHALLOW_COPPER_CHANCE, 0.002145)
		and is_equal_approx(StartingPlanetBalance.SHALLOW_RAW_FUEL_CHANCE, 0.0012675)
		and is_equal_approx(StartingPlanetBalance.EARLY_IRON_CHANCE, 0.01625 * 1.25)
		and shallow_copper_count >= 15
		and shallow_iron_count > 3
		and first_thousand_iron_count > shallow_iron_count
		and mining_instance.block_types_by_cell.get(Vector2i(lander_column - 3, ground_row + 2), -1)
			== mining_instance.BlockType.COPPER
		and mining_instance.block_types_by_cell.get(Vector2i(lander_column + 3, ground_row + 2), -1)
			== mining_instance.BlockType.RAWFUEL
		and mining_instance.block_types_by_cell.get(Vector2i(lander_column - 6, ground_row + 3), -1)
			== mining_instance.BlockType.IRON
	)
	var surface_balance: Dictionary = mining_instance.get_mining_balance_readout(mining_instance.BlockType.DIRT, 0)
	var thousand_balance: Dictionary = mining_instance.get_mining_balance_readout(mining_instance.BlockType.DIRT, 1000)
	var core_balance: Dictionary = mining_instance.get_mining_balance_readout(mining_instance.BlockType.DIRT, 7500)
	alpha_systems_worked = (
		alpha_systems_worked
		and is_equal_approx(float(surface_balance["depth_multiplier"]), 1.0)
		and is_equal_approx(float(thousand_balance["depth_multiplier"]), 1.16)
		and is_equal_approx(float(core_balance["depth_multiplier"]), 2.2)
		and not mining_instance.create_save_data().has("active_mining_damage")
	)
	var core_barrier_valid := true
	var valuable_barrier_blocks := 0
	var barrier_start_row: int = mining_instance.get_first_ground_row() + 700
	for row in range(barrier_start_row, mining_instance.get_core_vault_top_row()):
		for column in mining_instance.grid_width:
			var barrier_cell := Vector2i(column, row)
			var barrier_type: int = mining_instance.block_types_by_cell.get(barrier_cell, -1)
			core_barrier_valid = core_barrier_valid and barrier_type in [
				mining_instance.BlockType.ROCK,
				mining_instance.BlockType.TREASURE,
				mining_instance.BlockType.DIAMOND,
				mining_instance.BlockType.WARPGEMS,
				mining_instance.BlockType.BLACKHOLECRYSTALS,
			]
			if barrier_type != mining_instance.BlockType.ROCK:
				valuable_barrier_blocks += 1
	var core_vault_layout_valid: bool = (
		core_barrier_valid
		and valuable_barrier_blocks > 0
		and mining_instance.get_current_depth_meters() < mining_instance.core_vault_start_depth_meters
		and mining_instance.planet_core_cell.y > mining_instance.get_core_vault_top_row()
		and mining_instance.block_types_by_cell.get(mining_instance.planet_core_cell, -1) == mining_instance.BlockType.PLANETCORE
		and mining_instance.core_vault_system != null
		and mining_instance.core_vault_system.altar != null
		and mining_instance.core_vault_system.portals.size() == 4
	)
	for row in range(
		mining_instance.get_core_vault_top_row(),
		mining_instance.get_core_vault_top_row() + mining_instance.core_vault_height_blocks
	):
		for column in range(
			mining_instance.get_core_vault_left_column(),
			mining_instance.get_core_vault_right_column() + 1
		):
			var vault_cell := Vector2i(column, row)
			if vault_cell != mining_instance.planet_core_cell:
				core_vault_layout_valid = core_vault_layout_valid and not mining_instance.block_types_by_cell.has(vault_cell)
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
		is_equal_approx(level_five_drill, base_drill * pow(1.2, 5))
		and is_equal_approx(mining_instance.drill_damage_per_second, base_drill * 1.2)
	)
	var teleported: bool = mining_instance.get_current_depth_meters() == 3000
	var ground_caves_valid: bool = mining_instance.planned_ground_encounters.size() >= 3
	for encounter in mining_instance.planned_ground_encounters:
		var center_data: Array = encounter.get("cave_center_cell", [0, 0])
		var center_depth: int = (int(center_data[1]) - mining_instance.get_first_ground_row()) * mining_instance.depth_meters_per_row
		ground_caves_valid = (
			ground_caves_valid
			and absi(center_depth - int(encounter.get("target_depth_meters", 0))) <= 100
			and encounter.get("cave_cells", []).size() >= 25
			and encounter.get("cave_cells", []).size() <= 49
			and int(encounter.get("wall_thickness", 0)) >= 2
			and int(encounter.get("wall_thickness", 0)) <= 5
			and not encounter.get("wall_cells", []).is_empty()
		)
		for cave_cell_data in encounter.get("cave_cells", []):
			var cave_cell := Vector2i(int(cave_cell_data[0]), int(cave_cell_data[1]))
			if cave_cell.y < mining_instance.generated_row_count:
				ground_caves_valid = ground_caves_valid and not mining_instance.block_types_by_cell.has(cave_cell)
		for wall_cell_data in encounter.get("wall_cells", []):
			var wall_cell := Vector2i(int(wall_cell_data[0]), int(wall_cell_data[1]))
			if wall_cell.y < mining_instance.generated_row_count:
				ground_caves_valid = (
					ground_caves_valid
					and mining_instance.block_types_by_cell.get(wall_cell, -1) == mining_instance.BlockType.ROCK
				)
	var cave_teleport_result: Dictionary = mining_instance.teleport_player_near_nearest_cave()
	var cave_arrival: Vector2i = cave_teleport_result.get("arrival_cell", Vector2i.ZERO)
	var cave_boundary: Vector2i = cave_teleport_result.get("wall_boundary_cell", Vector2i.ZERO)
	mining_instance.developer_cave_direction_arrow.update_arrow()
	var developer_cave_navigation_worked: bool = (
		not cave_teleport_result.is_empty()
		and mining_instance.get_player_cell() == cave_arrival
		and absi(cave_arrival.x - cave_boundary.x) + absi(cave_arrival.y - cave_boundary.y) == 6
		and mining_instance.is_developer_cave_arrow_enabled()
		and mining_instance.developer_cave_direction_arrow.visible
		and mining_instance.developer_test_panel.cave_arrow_toggle != null
	)

	var first_ground_encounter: Dictionary = mining_instance.planned_ground_encounters[0]
	var altar_data: Array = first_ground_encounter["altar_cell"]
	mining_instance.player_marker.position = mining_instance.mine_tiles.map_to_local(
		Vector2i(int(altar_data[0]), int(altar_data[1]))
	)
	var treasure_before_altar: int = int(mining_instance.resources.get("Treasure", 0))
	mining_instance.ground_encounter_system.update_interaction_prompt()
	var altar_interaction_worked: bool = mining_instance.ground_encounter_system.try_interact()
	mining_instance.ground_encounter_system.process_encounters(0.01)
	var demon_spawn_worked: bool = mining_instance.ground_encounter_system.demons.size() == 1
	var dart_damage_worked := false
	var laser_hit_demon := false
	var blast_defeated_demon := false
	if demon_spawn_worked:
		var spawned_demon = mining_instance.ground_encounter_system.demons[0]
		spawned_demon.attack_remaining = 0.0
		mining_instance.ground_encounter_system.update_demons(0.01)
		if not mining_instance.ground_encounter_system.darts.is_empty():
			var hull_before_dart: int = mining_instance.hull_health
			var shield_before_dart: float = mining_instance.shield_health
			mining_instance.ground_encounter_system.darts[0].position = mining_instance.player_marker.position
			mining_instance.ground_encounter_system.update_darts(0.0)
			dart_damage_worked = (
				mining_instance.hull_health == hull_before_dart
				and is_equal_approx(mining_instance.shield_health, shield_before_dart - 5.0)
			)
		var demon_health_before_laser: int = spawned_demon.health
		mining_instance.miner_laser_system.fire(
			spawned_demon.position - Vector2(40.0, 0.0),
			spawned_demon.position + Vector2(40.0, 0.0)
		)
		mining_instance.miner_laser_system.process_projectiles(0.03)
		laser_hit_demon = spawned_demon.health == demon_health_before_laser - 1
		var demon_cell: Vector2i = mining_instance.mine_tiles.local_to_map(spawned_demon.position)
		var demon_blast_cells: Array[Vector2i] = [demon_cell]
		blast_defeated_demon = mining_instance.ground_encounter_system.damage_enemies_in_cells(demon_blast_cells, 3) == 1
	var ground_enemy_foundation_worked: bool = (
		ground_caves_valid
		and altar_interaction_worked
		and bool(first_ground_encounter.get("looted", false))
		and bool(first_ground_encounter.get("triggered", false))
		and int(mining_instance.resources.get("Treasure", 0)) == treasure_before_altar + 1
		and mining_instance.ground_encounter_system.portal_nodes[first_ground_encounter["encounter_id"]].active
		and demon_spawn_worked
		and dart_damage_worked
		and laser_hit_demon
		and blast_defeated_demon
	)
	mining_instance.ground_encounter_system.mark_demon_defeated(first_ground_encounter["encounter_id"])
	mining_instance.ground_encounter_system.mark_demon_defeated(first_ground_encounter["encounter_id"])
	var portal_closed_after_cave_defeat: bool = (
		bool(first_ground_encounter.get("defeated", false))
		and not mining_instance.ground_encounter_system.portal_nodes[first_ground_encounter["encounter_id"]].active
		and mining_instance.enemy_contact_made
	)
	mining_instance.capacitor_energy = 1000.0
	mining_instance.shield_health = mining_instance.max_shield_health
	mining_instance.update_capacitor_and_shield(1.0)
	var shielded_recharge_worked := is_equal_approx(mining_instance.capacitor_energy, 1350.0)
	var energy_before_shot: float = mining_instance.capacitor_energy
	var laser_shot_worked: bool = mining_instance.try_fire_laser_at(
		mining_instance.player_marker.position + Vector2(500.0, -100.0)
	)
	var laser_energy_worked := (
		laser_shot_worked
		and is_equal_approx(mining_instance.capacitor_energy, energy_before_shot - 200.0)
		and is_equal_approx(mining_instance.laser_fire_cooldown_remaining, 1.0 / 3.0)
	)
	var hull_before_bypass: int = mining_instance.hull_health
	var shield_before_bypass: float = mining_instance.shield_health
	mining_instance.apply_miner_damage(4, true)
	var shield_bypass_worked: bool = (
		mining_instance.hull_health == hull_before_bypass - 4
		and is_equal_approx(mining_instance.shield_health, shield_before_bypass)
	)
	mining_instance.capacitor_energy = 500.0
	mining_instance.shield_health = 90.0
	mining_instance.shield_recharge_delay_remaining = 2.0
	mining_instance.update_capacitor_and_shield(2.0)
	var delayed_capacitor_energy: float = mining_instance.capacitor_energy
	var delayed_shield_health: float = mining_instance.shield_health
	mining_instance.update_capacitor_and_shield(1.0)
	var shield_repair_delay_worked: bool = (
		is_equal_approx(delayed_capacitor_energy, 1200.0)
		and is_equal_approx(delayed_shield_health, 90.0)
		and is_equal_approx(mining_instance.shield_recharge_delay_remaining, 0.0)
		and is_equal_approx(mining_instance.capacitor_energy, delayed_capacitor_energy + 50.0)
		and is_equal_approx(mining_instance.shield_health, 96.0)
	)
	var mk_one_upgrade_ids := [
		"miner_drill_yield", "miner_power_unit_output", "miner_power_unit_efficiency",
		"miner_mobility_max_speed", "miner_mobility_acceleration",
		"miner_mobility_vertical_climb", "miner_mobility_kinetic_efficiency",
		"miner_fuel_cell_capacity", "miner_thermal_heat_dispersion",
		"miner_life_support_efficiency",
		"miner_shield_capacity", "miner_shield_recharge_delay",
		"miner_shield_recharge_rate", "miner_shield_efficiency",
		"miner_structural_integrity", "miner_structural_armor",
		"miner_capacitor_capacity", "miner_weapon_damage", "miner_weapon_efficiency",
		"miner_weapon_rate_of_fire", "miner_weapon_critical_chance",
	]
	var all_mk_one_ids_defined := true
	for upgrade_id in mk_one_upgrade_ids:
		all_mk_one_ids_defined = all_mk_one_ids_defined and not mining_instance.find_upgrade_definition(upgrade_id).is_empty()
	mining_instance.upgrade_levels = {}
	for upgrade_id in mk_one_upgrade_ids:
		mining_instance.upgrade_levels[upgrade_id] = 2
	mining_instance.recalculate_stats_from_upgrade_levels()
	var copper_yield_range: Vector2i = mining_instance.get_ore_yield_range(mining_instance.BlockType.COPPER)
	var gold_yield_range: Vector2i = mining_instance.get_ore_yield_range(mining_instance.BlockType.GOLD)
	var mk_one_upgrades_worked: bool = (
		all_mk_one_ids_defined
		and copper_yield_range == Vector2i(3, 10)
			and gold_yield_range == Vector2i(2, 7)
			and is_equal_approx(mining_instance.engine_charge_per_second, 864.0)
			and int(mining_instance.find_upgrade_definition("miner_power_unit_output").get("max_level", 0)) == 5
			and is_equal_approx(mining_instance.fuel_consumption_multiplier, pow(1.0 / 1.2, 2))
		and is_equal_approx(mining_instance.move_speed, float(mining_instance.base_upgrade_stats["move_speed"]) * pow(1.2, 2))
		and is_equal_approx(mining_instance.mobility_power_consumption_per_second, 198.0)
		and mining_instance.armor_rating == 2
		and DamageRules.calculate_armored_damage(10.0, 3) == 7
		and DamageRules.calculate_armored_damage(2.0, 99) == 1
		and is_equal_approx(mining_instance.laser_damage, pow(1.2, 2))
		and is_equal_approx(mining_instance.weapon_critical_chance, 0.04)
	)
	for category_upgrades in mining_instance.upgrade_definitions.values():
		for definition in category_upgrades:
			if str(definition.get("id", "")) == "planetary_fuel_depot":
				continue
			alpha_systems_worked = alpha_systems_worked and int(definition.get("max_level", 0)) == 5
	alpha_systems_worked = (
		alpha_systems_worked
		and mining_instance.get_miner_component_category_names().has("Sensor Suite")
		and not mining_instance.get_miner_component_category_names().has("Retained Miner Upgrades")
		and mining_instance.upgrade_definitions.has("Sensor Suite")
	)
	var drill_upgrade: Dictionary = mining_instance.find_upgrade_definition("miner_drill_efficiency")
	var sensor_upgrade: Dictionary = mining_instance.find_upgrade_definition("miner_sensor_strength")
	var drill_yield_upgrade: Dictionary = mining_instance.find_upgrade_definition("miner_drill_yield")
	var upgrade_bar_recipes_valid := true
	for category_upgrades in mining_instance.upgrade_definitions.values():
		for definition in category_upgrades:
			var upgrade_id: String = str(definition.get("id", ""))
			for level in [0, 1]:
				var permits_raw_starter_ore: bool = (
					level == 0
					and upgrade_id == "miner_sensor_strength"
				)
				for cost in mining_instance.get_upgrade_costs(definition, level):
					if str(cost.get("resource", "")) in ["Copper", "Iron", "Gold"]:
						upgrade_bar_recipes_valid = upgrade_bar_recipes_valid and permits_raw_starter_ore
	alpha_systems_worked = (
		alpha_systems_worked
		and upgrade_bar_recipes_valid
		and mining_instance.format_upgrade_costs(mining_instance.get_upgrade_costs(drill_upgrade, 0)).contains("Copper Bar")
		and mining_instance.format_upgrade_costs(mining_instance.get_upgrade_costs(drill_upgrade, 1)).contains("Copper Bar")
		and mining_instance.format_upgrade_costs(mining_instance.get_upgrade_costs(sensor_upgrade, 0)).contains("Copper")
		and not mining_instance.format_upgrade_costs(mining_instance.get_upgrade_costs(sensor_upgrade, 0)).contains("Copper Bar")
		and mining_instance.format_upgrade_costs(mining_instance.get_upgrade_costs(sensor_upgrade, 1)).contains("Copper Bar")
		and mining_instance.format_upgrade_costs(mining_instance.get_upgrade_costs(sensor_upgrade, 1)).contains("Iron Bar")
		and mining_instance.format_upgrade_costs(mining_instance.get_upgrade_costs(drill_yield_upgrade, 0)).contains("Copper Bar")
		and mining_instance.format_upgrade_costs(mining_instance.get_upgrade_costs(drill_yield_upgrade, 0)).contains("Iron Bar")
	)
	var saved_resources_for_relevance: Dictionary = mining_instance.resources.duplicate(true)
	var saved_lander_for_relevance: Dictionary = mining_instance.cargo_hold_resources.duplicate(true)
	var saved_metrics_for_relevance: Dictionary = mining_instance.progression_metrics.duplicate(true)
	var saved_levels_for_relevance: Dictionary = mining_instance.upgrade_levels.duplicate(true)
	var saved_enemy_contact: bool = mining_instance.enemy_contact_made
	var gold_upgrade: Dictionary = mining_instance.find_upgrade_definition("miner_mobility_vertical_climb")
	var thermal_upgrade: Dictionary = mining_instance.find_upgrade_definition("miner_thermal_heat_dispersion")
	mining_instance.resources.clear()
	mining_instance.cargo_hold_resources.clear()
	mining_instance.progression_metrics["resources_earned"] = {}
	mining_instance.progression_metrics["resources_spent"] = {}
	mining_instance.upgrade_levels.clear()
	mining_instance.enemy_contact_made = false
	var sensor_only_first_upgrade: bool = (
		mining_instance.is_upgrade_relevant(sensor_upgrade)
		and not mining_instance.is_upgrade_relevant(drill_upgrade)
		and not mining_instance.is_upgrade_relevant(thermal_upgrade)
	)
	mining_instance.upgrade_levels["miner_mobility_vertical_climb"] = 0
	var hidden_before_relevant: bool = not mining_instance.is_upgrade_relevant(gold_upgrade)
	mining_instance.resources["Copper"] = 1
	mining_instance.resources["Iron"] = 1
	mining_instance.resources["Gold"] = 1
	mining_instance.upgrade_levels["miner_sensor_strength"] = 1
	var shown_after_relevant: bool = mining_instance.is_upgrade_relevant(gold_upgrade)
	var combat_systems_hidden_before_contact: bool = not mining_instance.is_upgrade_relevant(thermal_upgrade)
	mining_instance.enemy_contact_made = true
	var combat_systems_shown_after_contact: bool = mining_instance.is_upgrade_relevant(thermal_upgrade)
	mining_instance.resources = saved_resources_for_relevance
	mining_instance.cargo_hold_resources = saved_lander_for_relevance
	mining_instance.progression_metrics = saved_metrics_for_relevance
	mining_instance.upgrade_levels = saved_levels_for_relevance
	mining_instance.enemy_contact_made = saved_enemy_contact
	alpha_systems_worked = (
		alpha_systems_worked
		and sensor_only_first_upgrade
		and hidden_before_relevant
		and shown_after_relevant
		and combat_systems_hidden_before_contact
		and combat_systems_shown_after_contact
	)
	mining_instance.player_marker.position = mining_instance.mine_tiles.map_to_local(Vector2i(20, ground_row + 20))
	mining_instance.revealed_cells.clear()
	mining_instance.upgrade_levels = {"miner_sensor_strength": 2, "miner_drill_efficiency": 1}
	mining_instance.recalculate_stats_from_upgrade_levels()
	var sensor_center: Vector2i = mining_instance.get_player_cell()
	var sensor_one_cell: Vector2i = sensor_center + Vector2i(3, 0)
	var sensor_too_far_cell: Vector2i = sensor_center + Vector2i(4, 0)
	mining_instance.block_types_by_cell[sensor_one_cell] = mining_instance.BlockType.COPPER
	mining_instance.block_types_by_cell[sensor_too_far_cell] = mining_instance.BlockType.COPPER
	var level_two_detections: Array[Vector2i] = mining_instance.get_detectable_hidden_ore_cells()
	mining_instance.upgrade_levels["miner_sensor_strength"] = 4
	mining_instance.recalculate_stats_from_upgrade_levels()
	var sensor_two_cell: Vector2i = sensor_center + Vector2i(5, 0)
	mining_instance.block_types_by_cell[sensor_two_cell] = mining_instance.BlockType.IRON
	var level_four_detections: Array[Vector2i] = mining_instance.get_detectable_hidden_ore_cells()
	alpha_systems_worked = (
		alpha_systems_worked
		and level_two_detections.has(sensor_one_cell)
		and not level_two_detections.has(sensor_too_far_cell)
		and level_four_detections.has(sensor_two_cell)
		and not mining_instance.can_drill_block_type(mining_instance.BlockType.DIAMOND)
	)
	mining_instance.upgrade_levels["miner_drill_efficiency"] = 2
	alpha_systems_worked = alpha_systems_worked and mining_instance.can_drill_block_type(mining_instance.BlockType.DIAMOND)
	mining_instance.upgrade_levels = {"miner_drill_efficiency": 1}
	mining_instance.recalculate_stats_from_upgrade_levels()
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
	var blast_inventory_capture_worked: bool = (
		captured_copper > 0
		and int(mining_instance.resources.get("Copper", 0)) - copper_before == captured_copper
	)
	var silicone_drop_rules_worked: bool = (
		mining_instance.should_drop_silicone(mining_instance.BlockType.DIRT, 0.049)
		and mining_instance.should_drop_silicone(mining_instance.BlockType.ROCK, 0.0)
		and not mining_instance.should_drop_silicone(mining_instance.BlockType.DIRT, 0.05)
		and not mining_instance.should_drop_silicone(mining_instance.BlockType.COPPER, 0.0)
		and is_equal_approx(mining_instance.silicone_drop_chance, 0.05)
	)
	var silicone_before: int = int(mining_instance.resources.get("Silicone", 0))
	var dirt_silicone_cell := player_cell + Vector2i(4, 0)
	var rock_silicone_cell := player_cell + Vector2i(5, 0)
	mining_instance.block_types_by_cell[dirt_silicone_cell] = mining_instance.BlockType.DIRT
	mining_instance.block_types_by_cell[rock_silicone_cell] = mining_instance.BlockType.ROCK
	mining_instance.silicone_drop_chance = 1.0
	var dirt_silicone_result: Dictionary = mining_instance.mine_target_cell(dirt_silicone_cell, false)
	var rock_silicone_result: Dictionary = mining_instance.mine_target_cell(rock_silicone_cell, false)
	mining_instance.silicone_drop_chance = 0.05
	silicone_drop_rules_worked = (
		silicone_drop_rules_worked
		and dirt_silicone_result.get("resource_name", "") == "Silicone"
		and rock_silicone_result.get("resource_name", "") == "Silicone"
		and int(mining_instance.resources.get("Silicone", 0)) == silicone_before + 2
	)
	var miner_copper_before_sale: int = int(mining_instance.resources.get("Copper", 0))
	var doubled_sale_values_worked: bool = (
		mining_instance.get_resource_value("Silicone") == 4
		and mining_instance.get_resource_value("Copper") == 6
		and mining_instance.get_resource_value("Iron") == 10
		and mining_instance.get_resource_value("Gold") == 18
		and mining_instance.get_resource_value("Raw Fuel") == 8
		and mining_instance.get_resource_value("Treasure") == 24
		and mining_instance.get_resource_value("Diamond") == 36
		and mining_instance.get_resource_value("Warp Gems") == 60
		and mining_instance.get_resource_value("Black Hole Crystals") == 90
		and mining_instance.get_resource_value("Copper Bar") == 27
		and mining_instance.get_resource_value("Iron Bar") == 45
		and mining_instance.get_resource_value("Gold Bar") == 81
		and mining_instance.get_resource_value("Silicone Wafer") == 6
		and mining_instance.get_resource_value("Explosive Charge") == 5
		and mining_instance.get_sellable_resource_names().has("Copper Bar")
		and mining_instance.get_sellable_resource_names().has("Iron Bar")
		and mining_instance.get_sellable_resource_names().has("Gold Bar")
		and mining_instance.get_sellable_resource_names().has("Silicone Wafer")
		and mining_instance.get_sellable_resource_names().has("Explosive Charge")
	)
	mining_instance.recent_resource_sales.clear()
	mining_instance.cargo_hold_resources["Copper"] = 12
	var credits_before_sale: int = mining_instance.credits
	var expected_copper_sale: int = mining_instance.get_resource_sale_quote("Copper", 12)
	mining_instance.sell_resource("Copper", 1)
	mining_instance.sell_resource("Copper", 10)
	mining_instance.sell_resource("Copper", -1)
	var tiered_lander_sale_worked: bool = (
		int(mining_instance.cargo_hold_resources.get("Copper", 0)) == 0
		and int(mining_instance.resources.get("Copper", 0)) == miner_copper_before_sale
		and mining_instance.credits == credits_before_sale + expected_copper_sale
		and mining_instance.get_current_resource_sale_price("Copper") < mining_instance.get_resource_value("Copper")
	)
	var depressed_copper_price: int = mining_instance.get_current_resource_sale_price("Copper")
	mining_instance.is_shop_open = false
	mining_instance.update_market_pressure(mining_instance.market_pressure_recovery_seconds_per_unit * 20.0)
	var market_price_recovery_worked: bool = (
		mining_instance.get_current_resource_sale_price("Copper") > depressed_copper_price
	)
	mining_instance.cargo_hold_resources["Copper"] = 2
	mining_instance.cargo_hold_resources["Iron"] = 3
	var miner_iron_before_sell_all: int = int(mining_instance.resources.get("Iron", 0))
	var credits_before_sell_all: int = mining_instance.credits
	var expected_sell_all_quote: int = mining_instance.get_sell_all_quote()
	mining_instance._on_sell_all_pressed()
	var lander_sell_all_worked: bool = (
		int(mining_instance.cargo_hold_resources.get("Copper", 0)) == 0
		and int(mining_instance.cargo_hold_resources.get("Iron", 0)) == 0
		and int(mining_instance.resources.get("Iron", 0)) == miner_iron_before_sell_all
		and mining_instance.credits == credits_before_sell_all + expected_sell_all_quote
	)
	mining_instance.cargo_hold_resources.clear()
	mining_instance.resources.clear()
	mining_instance.resources["Raw Fuel"] = 1
	mining_instance.lander_mining_fuel_kg = 0
	mining_instance.lander_rocket_fuel_tons = 0
	var expected_processed_fuel_kg: int = mining_instance.get_mining_fuel_processing_output_kg()
	var fuel_button_shows_kg: bool = mining_instance.get_process_raw_fuel_button_text().contains(
		"+%d kg Mining Fuel" % expected_processed_fuel_kg
	)
	mining_instance.process_raw_fuel_from_storage()
	var instant_fuel_processing_worked: bool = (
		fuel_button_shows_kg
			and expected_processed_fuel_kg > 0
			and mining_instance.lander_mining_fuel_kg == expected_processed_fuel_kg
			and mining_instance.lander_rocket_fuel_tons == mining_instance.rocket_fuel_tons_per_raw_fuel
		)
	mining_instance.ammo_fabricator_components = {"explosive_powder": 0, "explosive_casing": 0}
	mining_instance.ammo_fabricator_stock = {"explosive_charge": 0}
	mining_instance.miner_ammo = {"explosive_charge": 0}
	mining_instance.cargo_hold_resources["Raw Fuel"] = 1
	mining_instance.resources["Raw Fuel"] = 4
	mining_instance.process_explosive_powder()
	var cargo_first_powder_worked: bool = (
		mining_instance.get_explosive_powder() == 10
		and int(mining_instance.cargo_hold_resources.get("Raw Fuel", 0)) == 0
		and int(mining_instance.resources.get("Raw Fuel", 0)) == 4
	)
	mining_instance.cargo_hold_resources["Copper"] = 1
	mining_instance.resources["Copper"] = 4
	mining_instance.fabricate_explosive_casing()
	mining_instance.fabricate_explosive_casing()
	var casing_storage_order_worked: bool = (
		mining_instance.get_explosive_casings() == 2
		and int(mining_instance.cargo_hold_resources.get("Copper", 0)) == 0
		and int(mining_instance.resources.get("Copper", 0)) == 3
	)
	mining_instance.assemble_explosive_charge()
	mining_instance.assemble_explosive_charge()
	var inventory_count_before_loading_explosives: int = mining_instance.get_inventory_count()
	mining_instance.load_explosive_charges_into_miner(-1)
	var fabrication_loop_worked: bool = (
		cargo_first_powder_worked
		and casing_storage_order_worked
		and mining_instance.get_explosive_powder() == 8
		and mining_instance.get_explosive_casings() == 0
		and mining_instance.get_fabricated_explosive_charges() == 0
		and mining_instance.get_loaded_explosive_charges() == 2
		and mining_instance.get_inventory_count() == inventory_count_before_loading_explosives
		and mining_instance.consume_loaded_explosive_charge()
		and mining_instance.get_loaded_explosive_charges() == 1
	)
	mining_instance.fabricator_unlocked = true
	mining_instance.fabricator_output.clear()
	mining_instance.cargo_hold_resources.clear()
	var silicone_wafer_recipe: Dictionary = StartingPlanetBalance.FABRICATOR_RECIPES["silicone_wafer"]
	var circuit_recipe: Dictionary = StartingPlanetBalance.FABRICATOR_RECIPES["basic_circuit"]
	var gps_recipe: Dictionary = StartingPlanetBalance.FABRICATOR_RECIPES["gps_marker"]
	var fabrication_recipe_expansion_worked: bool = (
		int(silicone_wafer_recipe["inputs"]["Silicone"]) == 1
		and int(silicone_wafer_recipe["amount"]) == 2
		and int(circuit_recipe["inputs"]["Silicone Wafer"]) == 1
		and int(gps_recipe["inputs"]["Iron Bar"]) == 1
		and int(gps_recipe["inputs"]["Basic Circuit"]) == 1
		and int(gps_recipe["amount"]) == 5
		and mining_instance.get_cargo_display_resource_names({"Copper Bar": 1}).count("Copper Bar") == 1
	)
	var first_planet_treasure_candidates: Array[Dictionary] = mining_instance.get_available_treasure_upgrade_candidates()
	var first_planet_treasure_targets_miner_only := not first_planet_treasure_candidates.is_empty()
	for candidate in first_planet_treasure_candidates:
		first_planet_treasure_targets_miner_only = (
			first_planet_treasure_targets_miner_only
			and mining_instance.get_miner_component_category_names().has(str(candidate.get("category", "")))
		)
	mining_instance.resources.clear()
	mining_instance.resources["GPS Marker"] = 1
	mining_instance.gps_marker_cells.clear()
	mining_instance.is_paused = false
	mining_instance.is_shop_open = false
	mining_instance.is_game_over = false
	var placed_gps_cell: Vector2i = mining_instance.get_player_cell()
	var gps_marker_worked: bool = (
		mining_instance.place_gps_marker()
		and mining_instance.gps_marker_cells.has(placed_gps_cell)
		and int(mining_instance.resources.get("GPS Marker", 0)) == 0
		and mining_instance.gps_marker_visuals.size() == 1
	)
	mining_instance.resources.clear()
	mining_instance.resources["Copper"] = 6
	mining_instance.resources["Iron"] = 3
	mining_instance.resources["Gold"] = 3
	mining_instance.smelt_all_bars()
	fabrication_recipe_expansion_worked = (
		fabrication_recipe_expansion_worked
		and int(mining_instance.cargo_hold_resources.get("Copper Bar", 0)) == 2
		and int(mining_instance.cargo_hold_resources.get("Iron Bar", 0)) == 1
		and int(mining_instance.cargo_hold_resources.get("Gold Bar", 0)) == 1
	)
	mining_instance.cargo_hold_resources.clear()
	mining_instance.resources.clear()
	mining_instance.resources["Raw Fuel"] = 1
	mining_instance.resources["Copper Bar"] = 2
	mining_instance.resources["Iron Wire"] = 1
	var explosive_recipe: Dictionary = StartingPlanetBalance.FABRICATOR_RECIPES["explosive_charge"]
	mining_instance.fabricate_recipe("explosive_charge")
	var ten_charge_recipe_worked: bool = (
		int(explosive_recipe["inputs"]["Raw Fuel"]) == 1
		and int(explosive_recipe["inputs"]["Copper Bar"]) == 2
		and int(explosive_recipe["inputs"]["Iron Wire"]) == 1
		and int(explosive_recipe["amount"]) == 10
		and mining_instance.get_fabricator_recipe_button_text(explosive_recipe).contains(
			"1 Raw Fuel + 2 Copper Bar + 1 Iron Wire -> 10 Explosive Charge"
		)
		and int(mining_instance.cargo_hold_resources.get("Explosive Charge", 0)) == 10
		and int(mining_instance.resources.get("Raw Fuel", 0)) == 0
		and int(mining_instance.resources.get("Copper Bar", 0)) == 0
		and int(mining_instance.resources.get("Iron Wire", 0)) == 0
	)
	mining_instance.is_shop_open = true
	mining_instance.show_ammo_fabricator_view()
	var fabricator_ui_worked: bool = (
		mining_instance.shop_title_label.text == "Lander Fabricator"
		and mining_instance.ammo_fabricator_status_label.text.contains("Miner Loaded Charges")
		and mining_instance.fabricator_available_materials_label != null
		and mining_instance.fabricator_available_materials_label.text.contains("MINER + LANDER")
		and not mining_instance.fabricator_available_materials_label.text.contains("Copper: 0")
		and tree_has_button_text(mining_instance.shop_content, "Load All")
		and tree_has_button_text(mining_instance.shop_content, "Smelt All Bars")
		and mining_instance.fabricator_materials_list != null
		and mining_instance.shop_master_tabs != null
		and tree_has_button_text(mining_instance.shop_master_tabs, "Home")
		and tree_has_button_text(mining_instance.shop_master_tabs, "Upgrades")
		and tree_has_button_text(mining_instance.shop_master_tabs, "Lander")
		and tree_has_button_text(mining_instance.shop_master_tabs, "Fabricator")
	)
	mining_instance.handle_shop_back()
	var menu_back_navigation_worked: bool = (
		mining_instance.shop_title_label.text == "Lander"
		and InputMap.has_action(&"menu_back")
		and mining_instance.pause_menu.menu_back_binding_button != null
	)
	mining_instance.fabricator_output.clear()
	mining_instance.cargo_hold_resources.clear()
	mining_instance.resources["Copper"] = 3
	mining_instance.cargo_hold_resources["Test Cargo"] = mining_instance.cargo_hold_capacity
	mining_instance.fabricate_recipe("copper_bar")
	var full_cargo_holds_output: bool = (
		not mining_instance.fabricator_output.is_empty()
		and mining_instance.get_ammo_fabricator_status_text().contains("CARGO FULL")
	)
	mining_instance.cargo_hold_resources.erase("Test Cargo")
	var output_transferred: bool = mining_instance.try_transfer_fabricator_output()
	mining_instance.show_market_view()
	var fabricated_cargo_visible: bool = (
		tree_has_label_text(mining_instance.lander_cargo_hold_list, "Copper Bar x1")
		and mining_instance.get_resource_icon_tile_coords("Copper Bar")
			== mining_instance.get_resource_icon_tile_coords("Copper")
		and mining_instance.get_cargo_hold_count() >= 1
	)
	var copper_bar_market_label := find_label_by_text(mining_instance.lander_cargo_hold_list, "Copper Bar x1")
	var market_layout_worked: bool = (
		mining_instance.lander_cargo_hold_list.get_parent() is ScrollContainer
		and copper_bar_market_label != null
		and tree_has_button_text(copper_bar_market_label.get_parent(), "1\n+27")
	)
	var saved_miner_resources: Dictionary = mining_instance.resources.duplicate(true)
	mining_instance.developer_test_panel.close()
	mining_instance.handle_escape_close()
	var escape_closes_whole_menu: bool = not mining_instance.is_shop_open
	mining_instance.resources.clear()
	mining_instance.resources["Copper"] = 2
	mining_instance.open_mining_inventory()
	var mining_inventory_opened: bool = (
		mining_instance.is_mining_inventory_open()
		and mining_instance.is_paused
		and tree_has_label_text(mining_instance.mining_inventory_list, "Copper x2")
		and tree_has_button_text(mining_instance.mining_inventory_list, "Dump 1")
	)
	mining_instance.dump_miner_resource("Copper")
	var mining_inventory_dumped_one: bool = int(mining_instance.resources.get("Copper", 0)) == 1
	mining_instance.close_mining_inventory()
	var mining_inventory_worked: bool = (
		mining_inventory_opened
		and mining_inventory_dumped_one
		and not mining_instance.is_mining_inventory_open()
	)
	mining_instance.developer_test_panel.open()
	mining_instance.resources.clear()
	mining_instance.resources["Test Cargo"] = mining_instance.inventory_capacity
	mining_instance.update_hud()
	var miner_cargo_full_notified: bool = (
		mining_instance.cargo_full_notification != null
		and mining_instance.cargo_full_notification.visible
		and mining_instance.cargo_full_notification.text.contains("CARGO HOLD FULL")
	)
	mining_instance.resources.clear()
	mining_instance.update_hud()
	miner_cargo_full_notified = (
		miner_cargo_full_notified
		and not mining_instance.cargo_full_notification.visible
	)
	mining_instance.resources = saved_miner_resources
	alpha_systems_worked = (
		alpha_systems_worked
		and fabrication_recipe_expansion_worked
		and first_planet_treasure_targets_miner_only
		and full_cargo_holds_output
		and output_transferred
		and fabricated_cargo_visible
		and market_layout_worked
		and escape_closes_whole_menu
		and mining_inventory_worked
		and miner_cargo_full_notified
		and mining_instance.fabricator_output.is_empty()
		and int(mining_instance.cargo_hold_resources.get("Copper Bar", 0)) == 1
	)
	var lift_cell := Vector2i(10, ground_row + 12)
	for shaft_y in range(ground_row, lift_cell.y):
		mining_instance.block_types_by_cell.erase(Vector2i(lift_cell.x, shaft_y))
		mining_instance.visual_mine_tiles.erase_cell(Vector2i(lift_cell.x, shaft_y))
	for foundation_offset in range(-1, 2):
		mining_instance.block_types_by_cell[lift_cell + Vector2i(foundation_offset, 1)] = mining_instance.BlockType.ROCK
	mining_instance.player_marker.position = mining_instance.mine_tiles.map_to_local(lift_cell)
	mining_instance.resources["Iron"] = 100
	mining_instance.resources["Copper"] = 100
	mining_instance.resources["Basic Circuit"] = 1
	var lift_cost: Dictionary = mining_instance.StartingPlanetBalance.get_lift_cost(13)
	var lift_built: bool = mining_instance.try_construct_lift_station(true)
	var lift_reached_anchor: bool = lift_built and mining_instance.try_use_nearby_lift()
	var anchor_cell: Vector2i = mining_instance.get_player_cell()
	var lift_returned: bool = lift_reached_anchor and mining_instance.try_use_nearby_lift()
	alpha_systems_worked = (
		alpha_systems_worked
		and int(lift_cost["Iron"]) == 4
		and int(lift_cost["Copper"]) == 5
		and mining_instance.lift_stations.size() == 1
		and anchor_cell == Vector2i(lift_cell.x, ground_row - 1)
		and lift_returned
		and mining_instance.get_player_cell() == lift_cell
	)
	mining_instance.resources.clear()
	mining_instance.cargo_hold_resources.clear()
	mining_instance.resources["Diamond"] = 7
	mining_instance.show_shop_main_view()
	mining_instance.is_shop_open = false
	mining_instance.hull_health = 73
	mining_instance.credits = 30
	var saved_active_fuel: float = mining_instance.fuel_seconds
	var saved_max_fuel: float = mining_instance.max_fuel_seconds
	var saved_lander_mining_fuel: int = mining_instance.lander_mining_fuel_kg
	mining_instance.max_fuel_seconds = 60.0
	mining_instance.fuel_seconds = 25.0
	mining_instance.lander_mining_fuel_kg = 20
	var refuel_capacity_visible: bool = (
		mining_instance.get_refuel_button_text().contains("Tank: 25 / 60 kg")
		and mining_instance.get_miner_fuel_tank_capacity_kg() == 60
		and mining_instance.get_current_miner_fuel_kg() == 25
	)
	mining_instance.lander_mining_fuel_kg = 0
	refuel_capacity_visible = (
		refuel_capacity_visible
		and mining_instance.get_refuel_button_text().contains("Tank: 25 / 60 kg")
	)
	mining_instance.fuel_seconds = saved_active_fuel
	mining_instance.max_fuel_seconds = saved_max_fuel
	mining_instance.lander_mining_fuel_kg = saved_lander_mining_fuel
	var repair_cost_correct: bool = mining_instance.get_full_hull_repair_credit_cost() == 27
	var repair_button_order_correct: bool = (
		mining_instance.refuel_button.get_index() < mining_instance.repair_hull_button.get_index()
		and mining_instance.repair_hull_button.get_index() < mining_instance.return_to_starship_button.get_index()
	)
	mining_instance._on_repair_hull_pressed()
	var hull_repair_worked: bool = mining_instance.hull_health == 100 and mining_instance.credits == 3
	var saved_rocket_fuel_before_warning: int = mining_instance.lander_rocket_fuel_tons
	mining_instance.lander_rocket_fuel_tons = mining_instance.return_to_starship_required_rocket_fuel_tons
	mining_instance._on_return_to_starship_pressed()
	var departure_warning: AcceptDialog = null
	for child in mining_instance.get_children():
		if child is AcceptDialog and (child as AcceptDialog).title == "The Greatest Treasure":
			departure_warning = child as AcceptDialog
			break
	var early_departure_warning_worked: bool = (
		not mining_instance.can_return_to_starship()
		and departure_warning != null
		and departure_warning.dialog_text.contains("greatest treasure")
		and departure_warning.dialog_text.contains("demons")
	)
	if departure_warning != null:
		departure_warning.queue_free()
	mining_instance.lander_rocket_fuel_tons = saved_rocket_fuel_before_warning
	var core_pickup_result: Dictionary = mining_instance.mine_target_cell(mining_instance.planet_core_cell, false)
	var core_boss_started: bool = (
		core_pickup_result.get("resource_name", "") == "Planet Core"
		and mining_instance.core_vault_system.boss_active
		and mining_instance.core_vault_system.current_wave == 1
		and mining_instance.locked_core_vault_seal_cells.size() == mining_instance.core_vault_width_blocks
	)
	var progressive_waves_valid := true
	for wave_number in range(1, 6):
		while mining_instance.core_vault_system.pending_spawns > 0:
			mining_instance.core_vault_system.process_encounter(1.0)
		var expected_count: int = mining_instance.core_vault_system.wave_enemy_counts[wave_number - 1]
		progressive_waves_valid = (
			progressive_waves_valid
			and mining_instance.ground_encounter_system.count_active_demons("planet_core_vault_boss") == expected_count
		)
		for demon in mining_instance.ground_encounter_system.demons:
			if is_instance_valid(demon) and demon.encounter_id == "planet_core_vault_boss":
				progressive_waves_valid = (
					progressive_waves_valid
					and demon.health == mining_instance.core_vault_system.wave_enemy_health[wave_number - 1]
					and demon.dart_damage == mining_instance.core_vault_system.wave_dart_damage[wave_number - 1]
				)
				break
		for demon in mining_instance.ground_encounter_system.demons.duplicate():
			if is_instance_valid(demon) and demon.encounter_id == "planet_core_vault_boss":
				mining_instance.ground_encounter_system.damage_enemy_at_position(demon.position, 999)
		mining_instance.core_vault_system.process_encounter(0.0)
		mining_instance.core_vault_system.process_encounter(
			mining_instance.core_vault_system.between_wave_delay + 0.1
		)
	var core_boss_completed: bool = (
		mining_instance.core_vault_system.boss_completed
		and not mining_instance.core_vault_system.boss_active
		and mining_instance.locked_core_vault_seal_cells.is_empty()
		and mining_instance.has_planet_core()
	)
	last_core_vault_worked = (
		core_vault_layout_valid
		and core_boss_started
		and progressive_waves_valid
		and core_boss_completed
	)
	var mining_hud: MiningHud = mining_instance.modular_mining_hud
	var saved_hud_resources: Dictionary = mining_instance.resources.duplicate(true)
	mining_instance.resources.clear()
	mining_instance.resources["Copper"] = 1
	mining_instance.update_hud()
	var cargo_count_label := find_label_by_text(mining_instance.hud_cargo_icons, "x1")
	var mining_cargo_contrast_worked: bool = (
		cargo_count_label != null
		and cargo_count_label.get_theme_font_size("font_size") >= 18
		and cargo_count_label.get_theme_color("font_color") == Color.WHITE
		and cargo_count_label.get_theme_color("font_outline_color") == Color.BLACK
		and cargo_count_label.get_theme_constant("outline_size") >= 3
	)
	mining_instance.resources = saved_hud_resources
	mining_instance.update_hud()
	mining_instance.is_shop_open = false
	mining_instance.is_paused = false
	var initial_map_cell_size: float = mining_instance.planet_map_overlay.cell_size
	mining_instance.toggle_planet_map()
	await process_frame
	var map_opened: bool = mining_instance.planet_map_overlay.visible and mining_instance.is_paused
	mining_instance.planet_map_overlay.zoom_at(Vector2(300.0, 300.0), 1.2)
	var map_zoomed: bool = mining_instance.planet_map_overlay.cell_size > initial_map_cell_size
	mining_instance.close_planet_map()
	var planet_map_worked: bool = map_opened and map_zoomed and not mining_instance.planet_map_overlay.visible and not mining_instance.is_paused
	mining_instance.is_on_ground = false
	var airborne_drill_blocked: bool = not mining_instance.can_use_mining_drill()
	mining_instance.is_on_ground = true
	var grounded_drill_allowed: bool = mining_instance.can_use_mining_drill()
	var grounded_drilling_worked: bool = airborne_drill_blocked and grounded_drill_allowed
	mining_instance.trigger_death()
	var death_menu_worked: bool = (
		mining_instance.is_game_over
		and mining_instance.is_paused
		and mining_instance.game_over_actions.visible
		and tree_has_button_text(mining_instance.game_over_actions, "Load Slot %d" % save_manager.active_slot)
		and tree_has_button_text(mining_instance.game_over_actions, "New Game")
		and tree_has_button_text(mining_instance.game_over_actions, "Quit")
	)
	mining_instance.is_game_over = false
	mining_instance.is_paused = false
	mining_instance.game_over_actions.visible = false
	mining_instance.game_over_label.visible = false
	mining_hud.set_engine_levels(25.0, 100.0, 0.74)
	var fuel_warning_activated: bool = mining_hud.hud_warning_active
	mining_hud._process(0.0625)
	var warning_visibly_pulsed: bool = mining_hud.warning_overlay.color.a > 0.0
	mining_hud.set_engine_levels(26.0, 100.0, 0.75)
	var heat_warning_activated: bool = mining_hud.hud_warning_active
	mining_hud.set_engine_levels(26.0, 100.0, 0.74)
	var hud_warning_worked: bool = (
		fuel_warning_activated
		and warning_visibly_pulsed
		and heat_warning_activated
		and not mining_hud.hud_warning_active
		and is_zero_approx(mining_hud.warning_overlay.color.a)
	)
	mining_instance.resources["Copper"] = int(mining_instance.resources.get("Copper", 0)) + 1
	mining_instance.update_hud_cargo_icons()
	var cargo_nodes_before: Array[Node] = []
	for cargo_node in mining_instance.hud_cargo_icons.get_children():
		cargo_nodes_before.append(cargo_node)
	mining_instance.update_hud_cargo_icons()
	var cargo_nodes_stable: bool = cargo_nodes_before.size() == mining_instance.hud_cargo_icons.get_child_count()
	for index in cargo_nodes_before.size():
		cargo_nodes_stable = (
			cargo_nodes_stable
			and cargo_nodes_before[index] == mining_instance.hud_cargo_icons.get_child(index)
		)
	last_mining_abilities_worked = (
		radial_targets.size() == 9
		and directional_targets_correct
		and mining_instance.get_nearest_cardinal_direction(Vector2(90.0, 20.0)) == Vector2i.RIGHT
		and mining_instance.get_nearest_cardinal_direction(Vector2(-90.0, 20.0)) == Vector2i.LEFT
		and mining_instance.get_nearest_cardinal_direction(Vector2(20.0, -90.0)) == Vector2i.UP
		and mining_instance.get_nearest_cardinal_direction(Vector2(20.0, 90.0)) == Vector2i.DOWN
		and is_equal_approx(mining_instance.radial_blast_cooldown_seconds, 5.0)
		and is_equal_approx(mining_instance.directional_blast_cooldown_seconds, 5.0)
		and mining_instance.explosive_powder_per_raw_fuel == 10
		and mining_instance.max_explosive_powder == 100
		and mining_instance.max_fabricated_explosive_charges == 20
		and mining_instance.max_miner_explosive_charges == 10
		and fabrication_loop_worked
		and ten_charge_recipe_worked
		and fabricator_ui_worked
		and menu_back_navigation_worked
		and instant_fuel_processing_worked
		and gps_marker_worked
		and market_price_recovery_worked
		and grounded_drilling_worked
		and death_menu_worked
		and early_departure_warning_worked
		and mining_cargo_contrast_worked
		and planet_map_worked
		and mining_instance.shop_stat_labels.size() == 7
		and (mining_instance.shop_stat_labels["credits"] as Label).get_theme_font_size("font_size") >= 18
		and ground_enemy_foundation_worked
		and portal_closed_after_cave_defeat
		and developer_cave_navigation_worked
		and is_equal_approx(
			mining_instance.get_ability_block_removal_delay(),
			mining_instance.ability_effect_duration_seconds * 0.55 / 1.5
		)
		and is_equal_approx(mining_instance.ore_pickup_text_vertical_offset_pixels, 200.0)
		and blast_inventory_capture_worked
		and silicone_drop_rules_worked
		and tiered_lander_sale_worked
		and lander_sell_all_worked
		and doubled_sale_values_worked
		and mining_instance.pause_menu.settings_button != null
		and mining_instance.pause_menu.mouse_directed_e_toggle != null
		and mining_instance.modular_mining_hud != null
		and mining_instance.modular_mining_hud.name == "ModularMiningHUD"
		and mining_instance.modular_mining_hud.depth_display != null
		and mining_instance.modular_mining_hud.warning_overlay != null
		and hud_warning_worked
		and cargo_nodes_stable
		and mining_instance.modular_mining_hud.design_root.get_node("Housing").size == MiningHud.DESIGN_SIZE
		and mining_instance.modular_mining_hud.size.x <= MiningHud.DISPLAY_SIZE.x + 0.1
		and mining_instance.modular_mining_hud.size.y <= MiningHud.DISPLAY_SIZE.y + 0.1
		and mining_instance.modular_mining_hud.radial_button == mining_instance.radial_blast_button
		and mining_instance.modular_mining_hud.directional_button == mining_instance.directional_blast_button
		and mining_instance.get_node("MiningHUD").find_child("FuelBar", true, false) == null
		and mining_instance.get_node("MiningHUD").find_child("HullHealthBar", true, false) == null
		and mining_instance.get_node("MiningHUD").find_child("MiningAbilities", true, false) == null
		and mining_instance.max_hull_health == 100
		and is_equal_approx(mining_instance.capacitor_capacity, 2000.0)
		and is_equal_approx(mining_instance.engine_charge_per_second, 600.0)
		and is_equal_approx(mining_instance.life_support_power_per_second, 50.0)
		and is_equal_approx(mining_instance.mobility_power_consumption_per_second, 200.0)
		and is_equal_approx(mining_instance.shield_energy_per_second, 200.0)
		and is_equal_approx(mining_instance.laser_energy_per_shot, 200.0)
		and is_equal_approx(mining_instance.laser_shots_per_second, 3.0)
		and is_equal_approx(mining_instance.max_shield_health, 100.0)
		and is_equal_approx(mining_instance.shield_recharge_delay_seconds, 2.0)
		and is_equal_approx(mining_instance.shield_hp_per_energy, 0.02)
		and shielded_recharge_worked
		and laser_energy_worked
		and shield_bypass_worked
		and shield_repair_delay_worked
		and mk_one_upgrades_worked
		and mining_instance.modular_mining_hud.heat_needle != null
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
		and refuel_capacity_visible
		and repair_button_order_correct
		and hull_repair_worked
		and mining_instance.game_over_label.text == mining_instance.STANDARD_DEATH_MESSAGE
	)
	var saved_layout_signature: String = mining_instance.get_generated_planet_layout_signature(mining_instance.generated_row_count)
	var saved_credits: int = mining_instance.credits
	var saved_player_cell: Vector2i = mining_instance.get_player_cell()
	var saved_explosive_powder: int = mining_instance.get_explosive_powder()
	var saved_loaded_explosives: int = mining_instance.get_loaded_explosive_charges()
	var saved_capacitor_energy: float = mining_instance.capacitor_energy
	var saved_shield_health: float = mining_instance.shield_health
	var saved_core_boss_completed: bool = mining_instance.core_vault_system.boss_completed
	mining_instance.shield_recharge_delay_remaining = 1.25
	var saved_shield_recharge_delay: float = mining_instance.shield_recharge_delay_remaining
	var saved_ground_encounter_triggered: bool = bool(mining_instance.planned_ground_encounters[0].get("triggered", false))
	mining_instance.ground_encounter_system.process_encounters(1.0)
	var saved_active_demon_count: int = mining_instance.ground_encounter_system.demons.size()
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
		and mining_instance.get_explosive_powder() == saved_explosive_powder
		and mining_instance.get_loaded_explosive_charges() == saved_loaded_explosives
		and is_equal_approx(mining_instance.capacitor_energy, saved_capacitor_energy)
		and is_equal_approx(mining_instance.shield_health, saved_shield_health)
		and mining_instance.core_vault_system.boss_completed == saved_core_boss_completed
		and is_equal_approx(mining_instance.shield_recharge_delay_remaining, saved_shield_recharge_delay)
		and bool(mining_instance.planned_ground_encounters[0].get("triggered", false)) == saved_ground_encounter_triggered
		and mining_instance.ground_encounter_system.demons.size() == saved_active_demon_count
		and mining_instance.get_generated_planet_layout_signature(mining_instance.generated_row_count) == saved_layout_signature
		and mining_instance.lift_stations.size() == 1
		and float(mining_instance.progression_metrics.get("time_to_first_lift_activation", -1.0)) >= 0.0
		and mining_instance.sensor_twinkle_overlay != null
	)
	mining_instance._unhandled_input(developer_event)
	last_developer_setup_worked = (
		panel_opened
		and registries_populated_panel
		and teleported
		and upgrade_reassigned
		and fuel_rates_correct
		and alpha_systems_worked
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


func tree_has_button_text(root_node: Node, button_text: String) -> bool:
	if root_node is Button and (root_node as Button).text == button_text:
		return true
	for child in root_node.get_children():
		if tree_has_button_text(child, button_text):
			return true
	return false


func tree_has_label_text(root_node: Node, label_text: String) -> bool:
	if root_node is Label and root_node.text == label_text:
		return true
	for child in root_node.get_children():
		if tree_has_label_text(child, label_text):
			return true
	return false


func find_label_by_text(root_node: Node, label_text: String) -> Label:
	if root_node is Label and (root_node as Label).text == label_text:
		return root_node as Label
	for child in root_node.get_children():
		var result := find_label_by_text(child, label_text)
		if result != null:
			return result
	return null
