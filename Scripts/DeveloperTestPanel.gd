extends CanvasLayer

var mining_scene: Node
var panel: Panel
var depth_input: SpinBox
var credits_input: SpinBox
var rocket_fuel_input: SpinBox
var active_fuel_input: SpinBox
var resource_inputs: Dictionary = {}
var upgrade_inputs: Dictionary = {}
var status_label: Label
var cave_arrow_toggle: CheckButton
var metrics_label: Label
var was_paused: bool = false


func setup(target_mining_scene: Node) -> void:
	mining_scene = target_mining_scene
	layer = 30
	name = "DeveloperTestPanel"
	build_panel()


func build_panel() -> void:
	panel = Panel.new()
	panel.theme = GameTheme.create_button_theme()
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.05
	panel.anchor_bottom = 0.95
	panel.visible = false
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 12)
	margin.add_child(root_box)

	var title := Label.new()
	title.text = "Developer Test Setup (Ctrl+T)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	root_box.add_child(title)

	var quick_row := GridContainer.new()
	quick_row.columns = 5
	quick_row.add_theme_constant_override("h_separation", 10)
	quick_row.add_theme_constant_override("v_separation", 8)
	root_box.add_child(quick_row)
	for preset in mining_scene.get_developer_test_presets():
		add_button(quick_row, preset["label"], Callable(self, "load_preset").bind(preset))

	var state_grid := GridContainer.new()
	state_grid.columns = 4
	state_grid.add_theme_constant_override("h_separation", 14)
	state_grid.add_theme_constant_override("v_separation", 8)
	root_box.add_child(state_grid)
	depth_input = add_number_field(state_grid, "Target Depth (m)", 0, 20000, 10)
	credits_input = add_number_field(state_grid, "Credits", 0, 1000000, 10)
	rocket_fuel_input = add_number_field(state_grid, "Lander Rocket Fuel", 0, 10000, 1)
	active_fuel_input = add_number_field(state_grid, "Active Miner Fuel", 0, 100000, 1)
	for resource_definition in mining_scene.get_developer_test_resource_definitions():
		var resource_name: String = resource_definition["id"]
		resource_inputs[resource_name] = add_number_field(
			state_grid,
			resource_definition.get("label", resource_name),
			resource_definition.get("minimum", 0),
			resource_definition.get("maximum", 10000),
			resource_definition.get("step", 1)
		)

	var upgrades_title := Label.new()
	upgrades_title.text = "Direct Upgrade Levels"
	upgrades_title.add_theme_font_size_override("font_size", 20)
	root_box.add_child(upgrades_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(scroll)

	var upgrade_grid := GridContainer.new()
	upgrade_grid.columns = 3
	upgrade_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_grid.add_theme_constant_override("h_separation", 18)
	upgrade_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(upgrade_grid)

	for category_name in mining_scene.upgrade_definitions.keys():
		for definition in mining_scene.upgrade_definitions[category_name]:
			var category_label := Label.new()
			category_label.text = category_name
			upgrade_grid.add_child(category_label)

			var upgrade_label := Label.new()
			upgrade_label.text = definition["name"]
			upgrade_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			upgrade_grid.add_child(upgrade_label)

			var level_input := SpinBox.new()
			level_input.min_value = 0
			level_input.max_value = definition.get("max_level", 10)
			level_input.step = 1
			level_input.custom_minimum_size = Vector2(110, 38)
			upgrade_grid.add_child(level_input)
			upgrade_inputs[definition["id"]] = level_input

	var cave_tools_row := HBoxContainer.new()
	cave_tools_row.add_theme_constant_override("separation", 12)
	root_box.add_child(cave_tools_row)
	add_button(
		cave_tools_row,
		"Teleport 6 Blocks from Nearest Cave",
		Callable(self, "teleport_near_nearest_cave")
	)
	cave_arrow_toggle = CheckButton.new()
	cave_arrow_toggle.text = "Show Nearest Cave Arrow"
	cave_arrow_toggle.custom_minimum_size = Vector2(240.0, 42.0)
	cave_arrow_toggle.toggled.connect(Callable(self, "set_cave_arrow_enabled"))
	cave_tools_row.add_child(cave_arrow_toggle)

	metrics_label = Label.new()
	metrics_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	metrics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	metrics_label.add_theme_font_size_override("font_size", 13)
	root_box.add_child(metrics_label)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.text = "Changes apply to the current test run only."
	root_box.add_child(status_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 12)
	root_box.add_child(action_row)
	add_button(action_row, "Apply Setup + Teleport", Callable(self, "apply_current_setup"))
	add_button(action_row, "Close", Callable(self, "close"))


func add_number_field(parent: GridContainer, label_text: String, minimum: float, maximum: float, step_value: float) -> SpinBox:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)
	var input := SpinBox.new()
	input.min_value = minimum
	input.max_value = maximum
	input.step = step_value
	input.custom_minimum_size = Vector2(170, 38)
	parent.add_child(input)
	return input


func add_button(parent: Control, button_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func toggle() -> void:
	if panel.visible:
		close()
	else:
		open()


func is_open() -> bool:
	return panel.visible


func open() -> void:
	if mining_scene.is_shop_open:
		mining_scene.close_shop()
	was_paused = mining_scene.is_paused
	mining_scene.is_paused = true
	refresh_from_scene()
	panel.visible = true


func close() -> void:
	panel.visible = false
	mining_scene.is_paused = was_paused


func refresh_from_scene() -> void:
	depth_input.value = mining_scene.get_current_depth_meters()
	credits_input.value = mining_scene.credits
	rocket_fuel_input.value = mining_scene.lander_rocket_fuel_tons
	active_fuel_input.value = mining_scene.fuel_seconds
	for resource_name in resource_inputs:
		resource_inputs[resource_name].value = mining_scene.get_total_resource_count(resource_name)
	for upgrade_id in upgrade_inputs:
		upgrade_inputs[upgrade_id].value = mining_scene.upgrade_levels.get(upgrade_id, 0)
	if cave_arrow_toggle != null:
		cave_arrow_toggle.set_pressed_no_signal(mining_scene.is_developer_cave_arrow_enabled())
	refresh_metrics()


func refresh_metrics() -> void:
	if metrics_label == null or not mining_scene.has_method("get_developer_progression_metrics"):
		return
	var metrics: Dictionary = mining_scene.get_developer_progression_metrics()
	var current_balance: Dictionary = mining_scene.get_mining_balance_readout(
		mining_scene.BlockType.DIRT,
		mining_scene.get_current_depth_meters()
	)
	metrics_label.text = (
		"PACING  elapsed %.1fm | drill %.1fm | travel %.1fm | combat %.1fm | manage %.1fm\n"
		+ "Milestones: upgrade %s | sensor %s | fabricated %s | lift %s | core %s\n"
		+ "Current Dirt: base %.3f × depth %.3f = %.3f durability | DPS %.3f | %.3fs break"
	) % [
		float(metrics.get("elapsed_seconds", 0.0)) / 60.0,
		float(metrics.get("active_drilling_seconds", 0.0)) / 60.0,
		float(metrics.get("travel_seconds", 0.0)) / 60.0,
		float(metrics.get("combat_seconds", 0.0)) / 60.0,
		float(metrics.get("management_seconds", 0.0)) / 60.0,
		format_milestone(metrics.get("time_to_first_upgrade", -1.0)),
		format_milestone(metrics.get("time_to_sensor_level_1", -1.0)),
		format_milestone(metrics.get("time_to_first_fabricated_component", -1.0)),
		format_milestone(metrics.get("time_to_first_lift_activation", -1.0)),
		format_milestone(metrics.get("time_to_planet_core", -1.0)),
		float(current_balance.get("base_durability", 0.0)),
		float(current_balance.get("depth_multiplier", 0.0)),
		float(current_balance.get("final_durability", 0.0)),
		float(current_balance.get("drill_dps", 0.0)),
		float(current_balance.get("estimated_break_seconds", 0.0)),
	]


func format_milestone(value: Variant) -> String:
	var seconds := float(value)
	return "--" if seconds < 0.0 else "%.1fm" % (seconds / 60.0)


func load_preset(preset: Dictionary) -> void:
	depth_input.value = preset.get("depth_meters", 0)
	var default_level := int(preset.get("default_upgrade_level", 0))
	for level_input in upgrade_inputs.values():
		level_input.value = default_level
	for upgrade_id in preset.get("upgrade_levels", {}):
		if upgrade_inputs.has(upgrade_id):
			upgrade_inputs[upgrade_id].value = preset["upgrade_levels"][upgrade_id]
	active_fuel_input.value = mining_scene.max_fuel_seconds
	status_label.text = "Preset loaded. Press Apply Setup + Teleport."


func apply_current_setup() -> void:
	var requested_levels: Dictionary = {}
	for upgrade_id in upgrade_inputs:
		requested_levels[upgrade_id] = int(upgrade_inputs[upgrade_id].value)

	var requested_resources: Dictionary = {}
	for resource_name in resource_inputs:
		requested_resources[resource_name] = int(resource_inputs[resource_name].value)

	mining_scene.apply_developer_test_configuration({
		"depth_meters": int(depth_input.value),
		"credits": int(credits_input.value),
		"resource_counts": requested_resources,
		"rocket_fuel": int(rocket_fuel_input.value),
		"active_fuel": float(active_fuel_input.value),
		"upgrade_levels": requested_levels,
	})
	status_label.text = "Applied test setup at %dm. Close with Ctrl+T when ready." % int(depth_input.value)


func teleport_near_nearest_cave() -> void:
	var result: Dictionary = mining_scene.teleport_player_near_nearest_cave()
	if result.is_empty():
		status_label.text = "No cave could be generated for the current test world."
		return
	cave_arrow_toggle.set_pressed_no_signal(true)
	depth_input.value = mining_scene.get_current_depth_meters()
	status_label.text = "Teleported 6 blocks from %s. Cave arrow enabled." % result["encounter_id"]


func set_cave_arrow_enabled(enabled: bool) -> void:
	mining_scene.set_developer_cave_arrow_enabled(enabled)
	status_label.text = "Nearest cave arrow %s." % ("enabled" if enabled else "disabled")
