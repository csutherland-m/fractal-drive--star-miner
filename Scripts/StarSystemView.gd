extends Node2D

const CombatResolverScript := preload("res://Scripts/CombatResolver.gd")
const IceWorldTexture := preload("res://Sprites/Planets/Placeholders/ice_world.png")
const LavaWorldTexture := preload("res://Sprites/Planets/Placeholders/lava_world.png")
const RingedGasGiantTexture := preload("res://Sprites/Planets/Placeholders/ringed_gas_giant.png")
const RockyWorldTexture := preload("res://Sprites/Planets/Placeholders/rocky_world.png")
const ORBIT_SPEED_MULTIPLIER := 0.1

@onready var player_ship: Area2D = $PlayerShip
@onready var ship_sprite: Sprite2D = $PlayerShip/ShipSprite
@onready var starfield: Node2D = $Starfield
@onready var pause_menu: PauseMenu = $PauseMenu

@export var planet_mining_scene_path: String = "res://Scenes/AsteroidMining.tscn"
@export var starship_side_texture_path: String = "res://Sprites/Vehicles/StarShipSideEdited.png"
@export var zoomed_out_ship_scale: float = 0.18
@export var travel_seconds: float = 2.2
@export var orbit_line_width: float = 2.0
@export var asteroid_belt_inner_radius: float = 650.0
@export var asteroid_belt_outer_radius: float = 780.0
@export var asteroid_belt_point_count: int = 220
@export var intentional_enemy_count: int = 3
@export var enemy_icon_radius: float = 18.0
@export var player_outer_orbit_padding: float = 130.0
@export var player_orbit_speed: float = 0.18
@export var asteroid_belt_orbit_speed: float = 0.025
@export var ship_transfer_speed: float = 360.0
@export var min_transfer_seconds: float = 1.2
@export var max_transfer_seconds: float = 4.5
@export var intercept_freeze_seconds: float = 0.45

var is_paused: bool = false
var is_traveling: bool = false
var is_combat_open: bool = false
var orbits_paused: bool = false
var has_surprise_encounter_triggered: bool = false
var travel_elapsed: float = 0.0
var travel_duration: float = 2.2
var travel_start: Vector2 = Vector2.ZERO
var travel_control: Vector2 = Vector2.ZERO
var travel_end: Vector2 = Vector2.ZERO
var travel_destination_type: String = ""
var travel_destination_name: String = ""
var travel_target_enemy_index: int = -1
var system_center: Vector2 = Vector2.ZERO
var planets: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var asteroid_belt_points: Array[Vector2] = []
var asteroid_belt_angle: float = 0.0
var selected_route: Line2D
var engine_flame: Polygon2D
var inner_engine_flame: Polygon2D
var status_label: Label
var title_label: Label
var combat_panel: Panel
var combat_title_label: Label
var combat_stats_label: Label
var combat_log_label: Label
var combat_round_button: Button
var combat_auto_button: Button
var combat_close_button: Button
var flame_time: float = 0.0
var starship_side_texture: Texture2D
var player_combatant: Dictionary = {}
var active_enemy: Dictionary = {}
var active_enemy_index: int = -1
var combat_round: int = 0
var combat_log_lines: Array[String] = []
var player_orbit_radius: float = 0.0
var player_orbit_angle: float = 0.0


func _ready() -> void:
	randomize()
	pause_menu.resume_requested.connect(_on_resume_pressed)
	pause_menu.quit_requested.connect(_on_quit_pressed)
	starship_side_texture = load(starship_side_texture_path) as Texture2D
	ship_sprite.texture = starship_side_texture
	player_ship.scale = Vector2(zoomed_out_ship_scale, zoomed_out_ship_scale)
	system_center = get_viewport_rect().size * 0.5
	initialize_player_orbit()
	player_combatant = CombatResolverScript.create_player_ship()
	create_planets()
	create_asteroid_belt()
	create_enemies()
	create_route_line()
	create_engine_flame()
	create_ui()
	update_ship_visual(Vector2.RIGHT)
	queue_redraw()


func _process(delta: float) -> void:
	if is_paused or is_combat_open:
		return
	
	if not orbits_paused:
		update_planets(delta)
		update_enemies(delta)
		update_asteroid_belt(delta)
	
	if is_traveling:
		update_travel(delta)
	elif not orbits_paused:
		update_player_orbit(delta)
	
	queue_redraw()


func initialize_player_orbit() -> void:
	player_orbit_radius = asteroid_belt_outer_radius + player_outer_orbit_padding
	player_orbit_angle = PI * 0.5
	player_ship.global_position = get_position_on_orbit(player_orbit_radius, player_orbit_angle)
	update_ship_visual(get_orbit_tangent(player_orbit_angle))


func create_planets() -> void:
	var selected_templates: Array[Dictionary] = [
		get_planet_template("rocky"),
		get_planet_template("gas_giant"),
	]
	var random_templates: Array[Dictionary] = [
		get_planet_template("ice"),
		get_planet_template("lava"),
		get_planet_template("rocky"),
		get_planet_template("gas_giant"),
	]
	var extra_planet_count := randi_range(2, 3)
	
	for i in extra_planet_count:
		selected_templates.append(random_templates.pick_random())
	
	selected_templates.shuffle()
	planets.clear()
	
	for i in selected_templates.size():
		planets.append(create_planet_from_template(selected_templates[i], i))


func get_planet_template(planet_type: String) -> Dictionary:
	match planet_type:
		"gas_giant":
			return {
				"name_options": ["Aurelia", "Goliath", "Caelus"],
				"type": "Gas Giant",
				"texture": RingedGasGiantTexture,
				"radius": 78.0,
				"draw_size": Vector2(190.0, 190.0),
			}
		"ice":
			return {
				"name_options": ["Borealis", "Frostmere", "Kryos"],
				"type": "Ice World",
				"texture": IceWorldTexture,
				"radius": 38.0,
				"draw_size": Vector2(86.0, 86.0),
			}
		"lava":
			return {
				"name_options": ["Cinder", "Ashfall", "Pyra"],
				"type": "Lava World",
				"texture": LavaWorldTexture,
				"radius": 42.0,
				"draw_size": Vector2(92.0, 92.0),
			}
		_:
			return {
				"name_options": ["Rusk", "Kepler", "Brindle"],
				"type": "Rocky Planet",
				"texture": RockyWorldTexture,
				"radius": 36.0,
				"draw_size": Vector2(80.0, 80.0),
			}


func create_planet_from_template(template: Dictionary, orbit_index: int) -> Dictionary:
	var orbit_radius := 210.0 + float(orbit_index) * 155.0
	var orbit_speed := maxf(0.08, 0.4 - float(orbit_index) * 0.065)
	var start_angle := randf_range(0.0, TAU)
	var name_options: Array = template["name_options"]
	return create_planet(
		name_options.pick_random(),
		template["type"],
		template["texture"],
		template["draw_size"],
		orbit_radius,
		orbit_speed,
		start_angle,
		template["radius"]
	)


func create_planet(
	planet_name: String,
	planet_type: String,
	texture: Texture2D,
	draw_size: Vector2,
	orbit_radius: float,
	orbit_speed: float,
	start_angle: float,
	radius: float
) -> Dictionary:
	return {
		"name": planet_name,
		"type": planet_type,
		"texture": texture,
		"draw_size": draw_size,
		"orbit_radius": orbit_radius,
		"orbit_speed": orbit_speed,
		"angle": start_angle,
		"radius": radius,
		"position": system_center + Vector2.RIGHT.rotated(start_angle) * orbit_radius,
	}


func create_asteroid_belt() -> void:
	asteroid_belt_points.clear()
	for i in asteroid_belt_point_count:
		var angle := (float(i) / float(asteroid_belt_point_count)) * TAU + randf_range(-0.018, 0.018)
		var radius := randf_range(asteroid_belt_inner_radius, asteroid_belt_outer_radius)
		asteroid_belt_points.append(Vector2.RIGHT.rotated(angle) * radius)


func create_enemies() -> void:
	enemies.clear()
	for i in intentional_enemy_count:
		var orbit_radius := 280.0 + float(i) * 180.0
		var angle := 0.8 + float(i) * 1.9
		enemies.append({
			"name": "Raider %d" % (i + 1),
			"orbit_radius": orbit_radius,
			"orbit_speed": 0.13 + float(i) * 0.035,
			"angle": angle,
			"position": system_center + Vector2.RIGHT.rotated(angle) * orbit_radius,
			"defeated": false,
			"is_surprise": false,
		})


func create_route_line() -> void:
	selected_route = Line2D.new()
	selected_route.name = "SelectedRoute"
	selected_route.width = 3.0
	selected_route.default_color = Color(0.2, 0.85, 1.0, 0.7)
	selected_route.z_index = 6
	add_child(selected_route)


func create_engine_flame() -> void:
	engine_flame = Polygon2D.new()
	engine_flame.name = "EngineFlame"
	engine_flame.z_index = -2
	engine_flame.color = Color(1.0, 0.34, 0.08, 0.82)
	engine_flame.visible = false
	player_ship.add_child(engine_flame)
	
	inner_engine_flame = Polygon2D.new()
	inner_engine_flame.name = "InnerEngineFlame"
	inner_engine_flame.z_index = -1
	inner_engine_flame.color = Color(1.0, 0.92, 0.28, 0.9)
	inner_engine_flame.visible = false
	player_ship.add_child(inner_engine_flame)


func create_ui() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "StarSystemUI"
	add_child(ui_layer)
	
	title_label = Label.new()
	title_label.text = "Star System View"
	title_label.position = Vector2(28.0, 22.0)
	title_label.add_theme_font_size_override("font_size", 30)
	ui_layer.add_child(title_label)
	
	status_label = Label.new()
	status_label.text = "Click a planet to descend, a raider to transfer into combat, or the belt to plot a future run."
	status_label.position = Vector2(28.0, 66.0)
	status_label.add_theme_font_size_override("font_size", 18)
	ui_layer.add_child(status_label)
	
	create_combat_panel(ui_layer)


func create_combat_panel(ui_layer: CanvasLayer) -> void:
	combat_panel = Panel.new()
	combat_panel.visible = false
	combat_panel.anchor_left = 0.5
	combat_panel.anchor_right = 0.5
	combat_panel.anchor_top = 0.5
	combat_panel.anchor_bottom = 0.5
	combat_panel.offset_left = -430.0
	combat_panel.offset_right = 430.0
	combat_panel.offset_top = -280.0
	combat_panel.offset_bottom = 280.0
	ui_layer.add_child(combat_panel)
	
	var content := VBoxContainer.new()
	content.anchor_right = 1.0
	content.anchor_bottom = 1.0
	content.offset_left = 24.0
	content.offset_right = -24.0
	content.offset_top = 22.0
	content.offset_bottom = -22.0
	content.add_theme_constant_override("separation", 12)
	combat_panel.add_child(content)
	
	combat_title_label = Label.new()
	combat_title_label.add_theme_font_size_override("font_size", 28)
	content.add_child(combat_title_label)
	
	combat_stats_label = Label.new()
	combat_stats_label.add_theme_font_size_override("font_size", 18)
	content.add_child(combat_stats_label)
	
	combat_log_label = Label.new()
	combat_log_label.custom_minimum_size = Vector2(0.0, 300.0)
	combat_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_log_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	combat_log_label.add_theme_font_size_override("font_size", 17)
	content.add_child(combat_log_label)
	
	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	content.add_child(button_row)
	
	combat_round_button = Button.new()
	combat_round_button.text = "Resolve Round"
	combat_round_button.pressed.connect(resolve_active_combat_round)
	button_row.add_child(combat_round_button)
	
	combat_auto_button = Button.new()
	combat_auto_button.text = "Auto Resolve"
	combat_auto_button.pressed.connect(auto_resolve_active_combat)
	button_row.add_child(combat_auto_button)
	
	combat_close_button = Button.new()
	combat_close_button.text = "Close"
	combat_close_button.disabled = true
	combat_close_button.pressed.connect(close_combat_panel)
	button_row.add_child(combat_close_button)


func update_planets(delta: float) -> void:
	for planet in planets:
		planet["angle"] += planet["orbit_speed"] * ORBIT_SPEED_MULTIPLIER * delta
		planet["position"] = get_position_on_orbit(planet["orbit_radius"], planet["angle"])


func update_enemies(delta: float) -> void:
	for enemy in enemies:
		if enemy["defeated"]:
			continue
		
		enemy["angle"] += enemy["orbit_speed"] * ORBIT_SPEED_MULTIPLIER * delta
		enemy["position"] = get_position_on_orbit(enemy["orbit_radius"], enemy["angle"])


func update_asteroid_belt(delta: float) -> void:
	asteroid_belt_angle += asteroid_belt_orbit_speed * ORBIT_SPEED_MULTIPLIER * delta


func update_player_orbit(delta: float) -> void:
	player_orbit_angle += player_orbit_speed * ORBIT_SPEED_MULTIPLIER * delta
	player_ship.global_position = get_position_on_orbit(player_orbit_radius, player_orbit_angle)
	update_ship_visual(get_orbit_tangent(player_orbit_angle))


func get_position_on_orbit(orbit_radius: float, orbit_angle: float) -> Vector2:
	return system_center + Vector2.RIGHT.rotated(orbit_angle) * orbit_radius


func get_orbit_tangent(orbit_angle: float) -> Vector2:
	return Vector2.RIGHT.rotated(orbit_angle + PI * 0.5)


func update_travel(delta: float) -> void:
	travel_elapsed = minf(travel_elapsed + delta, travel_duration)
	var t := smoothstep(0.0, 1.0, travel_elapsed / travel_duration)
	var previous_position := player_ship.global_position
	player_ship.global_position = get_quadratic_bezier_point(t)
	var tangent := player_ship.global_position - previous_position
	
	if tangent.length() > 0.1:
		update_ship_visual(tangent.normalized())
	
	update_engine_flame(true, delta)
	
	if travel_elapsed >= travel_duration:
		complete_travel()


func get_quadratic_bezier_point(t: float) -> Vector2:
	var a := travel_start.lerp(travel_control, t)
	var b := travel_control.lerp(travel_end, t)
	return a.lerp(b, t)


func begin_travel_to(destination_type: String, destination_name: String, destination_position: Vector2) -> void:
	if is_traveling:
		return
	
	if should_trigger_surprise_encounter():
		open_combat_with_surprise_enemy()
		return
	
	begin_transfer(destination_type, destination_name, destination_position)


func begin_transfer(destination_type: String, destination_name: String, destination_position: Vector2) -> void:
	is_traveling = true
	travel_elapsed = 0.0
	travel_start = player_ship.global_position
	travel_end = destination_position
	travel_duration = get_transfer_duration(travel_start, travel_end)
	travel_destination_type = destination_type
	travel_destination_name = destination_name
	travel_control = get_orbitalish_control_point(travel_start, travel_end)
	status_label.text = "Traveling to %s..." % destination_name
	draw_route_preview()


func get_transfer_duration(start_position: Vector2, end_position: Vector2) -> float:
	var raw_seconds := start_position.distance_to(end_position) / maxf(ship_transfer_speed, 1.0)
	return clampf(raw_seconds, min_transfer_seconds, max_transfer_seconds)


func begin_planet_intercept(planet: Dictionary) -> void:
	if is_traveling:
		return
	
	if should_trigger_surprise_encounter():
		open_combat_with_surprise_enemy()
		return
	
	var intercept_position := predict_future_orbit_position(planet, player_ship.global_position)
	begin_transfer("planet", planet["name"], intercept_position)


func predict_future_orbit_position(target: Dictionary, start_position: Vector2) -> Vector2:
	var predicted_position: Vector2 = target["position"]
	var estimated_time := get_transfer_duration(start_position, predicted_position)
	
	for i in 3:
		var future_angle: float = target["angle"] + target["orbit_speed"] * ORBIT_SPEED_MULTIPLIER * estimated_time
		predicted_position = get_position_on_orbit(target["orbit_radius"], future_angle)
		estimated_time = get_transfer_duration(start_position, predicted_position)
	
	return predicted_position


func begin_enemy_orbit_transfer(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	
	var enemy := enemies[enemy_index]
	if enemy["defeated"]:
		return
	
	travel_target_enemy_index = enemy_index
	active_enemy = enemy
	active_enemy["combatant"] = CombatResolverScript.create_enemy_ship(active_enemy["name"], false)
	active_enemy_index = enemy_index
	var intercept_position := predict_future_orbit_position(enemy, player_ship.global_position)
	begin_transfer("enemy", enemy["name"], intercept_position)


func get_orbitalish_control_point(start_position: Vector2, end_position: Vector2) -> Vector2:
	var midpoint := start_position.lerp(end_position, 0.5)
	var route_direction := (end_position - start_position).normalized()
	var perpendicular := Vector2(-route_direction.y, route_direction.x)
	var away_from_star := (midpoint - system_center).normalized()
	
	if perpendicular.dot(away_from_star) < 0.0:
		perpendicular *= -1.0
	
	var curve_strength := clampf(start_position.distance_to(end_position) * 0.32, 120.0, 320.0)
	return midpoint + perpendicular * curve_strength


func draw_route_preview() -> void:
	selected_route.clear_points()
	for i in 28:
		var t := float(i) / 27.0
		selected_route.add_point(get_quadratic_bezier_point(t))


func complete_travel() -> void:
	is_traveling = false
	update_engine_flame(false, 0.0)
	selected_route.clear_points()
	player_orbit_radius = player_ship.global_position.distance_to(system_center)
	player_orbit_angle = (player_ship.global_position - system_center).angle()
	
	if travel_destination_type == "planet":
		complete_planet_intercept()
		return
	
	if travel_destination_type == "enemy":
		status_label.text = "Player transferred to enemy orbit. Combat encounter ready."
		open_combat_panel("Combat Encounter")
		return
	
	status_label.text = "Asteroid belt approach plotted. Belt flight scene is the next build target."


func complete_planet_intercept() -> void:
	orbits_paused = true
	status_label.text = "%s intercept complete. Preparing landing..." % travel_destination_name
	await get_tree().create_timer(intercept_freeze_seconds).timeout
	get_tree().change_scene_to_file(planet_mining_scene_path)


func should_trigger_surprise_encounter() -> bool:
	if has_surprise_encounter_triggered:
		return false
	
	has_surprise_encounter_triggered = true
	return true


func open_combat_with_surprise_enemy() -> void:
	var enemy_position := player_ship.global_position + Vector2(84.0, -72.0)
	active_enemy = {
		"name": "Hidden Corsair",
		"position": enemy_position,
		"defeated": false,
		"is_surprise": true,
		"combatant": CombatResolverScript.create_enemy_ship("Hidden Corsair", true),
	}
	active_enemy_index = -1
	open_combat_panel("Surprise Encounter")


func open_combat_with_enemy(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	
	var enemy := enemies[enemy_index]
	if enemy["defeated"]:
		return
	
	begin_enemy_orbit_transfer(enemy_index)


func open_combat_panel(panel_title: String) -> void:
	is_combat_open = true
	is_traveling = false
	update_engine_flame(false, 0.0)
	selected_route.clear_points()
	combat_round = 0
	combat_log_lines.clear()
	combat_log_lines.append("%s: %s engaged." % [panel_title, active_enemy["name"]])
	combat_panel.visible = true
	combat_round_button.disabled = false
	combat_auto_button.disabled = false
	combat_close_button.disabled = true
	refresh_combat_panel()


func resolve_active_combat_round() -> void:
	if not is_combat_open or active_enemy.is_empty():
		return
	
	var enemy_combatant: Dictionary = active_enemy["combatant"]
	if int(player_combatant["hull"]) <= 0 or int(enemy_combatant["hull"]) <= 0:
		finish_combat_if_needed()
		return
	
	combat_round += 1
	combat_log_lines.append("Round %d" % combat_round)
	var player_result := CombatResolverScript.resolve_round(player_combatant, enemy_combatant)
	combat_log_lines.append(format_combat_result(player_result))
	
	if int(enemy_combatant["hull"]) > 0:
		var enemy_result := CombatResolverScript.resolve_round(enemy_combatant, player_combatant)
		combat_log_lines.append(format_combat_result(enemy_result))
	
	trim_combat_log()
	finish_combat_if_needed()
	refresh_combat_panel()


func auto_resolve_active_combat() -> void:
	var safety_counter := 0
	while is_combat_open and not is_combat_finished() and safety_counter < 30:
		resolve_active_combat_round()
		safety_counter += 1


func is_combat_finished() -> bool:
	if active_enemy.is_empty() or not active_enemy.has("combatant"):
		return true
	
	var enemy_combatant: Dictionary = active_enemy["combatant"]
	return int(player_combatant["hull"]) <= 0 or int(enemy_combatant["hull"]) <= 0


func finish_combat_if_needed() -> void:
	if not is_combat_finished():
		return
	
	var enemy_combatant: Dictionary = active_enemy["combatant"]
	combat_round_button.disabled = true
	combat_auto_button.disabled = true
	combat_close_button.disabled = false
	
	if int(player_combatant["hull"]) <= 0:
		player_combatant["hull"] = 1
		combat_log_lines.append("Critical defeat. Emergency systems hold the ship at 1 hull for playtesting.")
		status_label.text = "Ship barely survived on emergency power."
		return
	
	combat_log_lines.append("%s destroyed." % active_enemy["name"])
	status_label.text = "%s defeated. Hull remaining: %d / %d" % [
		active_enemy["name"],
		int(player_combatant["hull"]),
		int(player_combatant["max_hull"]),
	]
	
	if active_enemy_index >= 0:
		enemies[active_enemy_index]["defeated"] = true
	

func close_combat_panel() -> void:
	if not is_combat_finished():
		return
	
	is_combat_open = false
	combat_panel.visible = false
	active_enemy = {}
	active_enemy_index = -1
	queue_redraw()


func refresh_combat_panel() -> void:
	if active_enemy.is_empty() or not active_enemy.has("combatant"):
		return
	
	var enemy_combatant: Dictionary = active_enemy["combatant"]
	combat_title_label.text = "%s vs %s" % [player_combatant["name"], enemy_combatant["name"]]
	combat_stats_label.text = "%s\n%s\nPlayer Armor + Shields: %d\nEnemy Armor + Shields: %d" % [
		CombatResolverScript.get_hull_text(player_combatant),
		CombatResolverScript.get_hull_text(enemy_combatant),
		int(player_combatant["armor"]) + int(player_combatant["shields"]),
		int(enemy_combatant["armor"]) + int(enemy_combatant["shields"]),
	]
	combat_log_label.text = "\n".join(combat_log_lines)


func format_combat_result(result: Dictionary) -> String:
	return "%s fires %s: %d raw - %d blocked = %d damage. %s hull: %d" % [
		result["attacker"],
		result["weapon"],
		int(result["raw_damage"]),
		int(result["mitigation"]),
		int(result["final_damage"]),
		result["defender"],
		int(result["defender_hull"]),
	]


func trim_combat_log() -> void:
	while combat_log_lines.size() > 14:
		combat_log_lines.pop_front()


func update_ship_visual(direction: Vector2) -> void:
	ship_sprite.flip_h = direction.x < 0.0
	if ship_sprite.flip_h:
		player_ship.rotation = direction.angle() - PI
	else:
		player_ship.rotation = direction.angle()


func update_engine_flame(is_thrusting: bool, delta: float) -> void:
	if engine_flame == null or inner_engine_flame == null:
		return
	
	engine_flame.visible = is_thrusting
	inner_engine_flame.visible = is_thrusting
	
	if not is_thrusting:
		return
	
	flame_time += delta
	var flicker := 0.78 + 0.22 * sin(flame_time * 34.0)
	var ship_half_width := 128.0
	if starship_side_texture != null:
		ship_half_width = float(starship_side_texture.get_width()) * 0.5
	
	var flame_direction := -1.0
	var nozzle_x := -ship_half_width + 4.0
	if ship_sprite.flip_h:
		flame_direction = 1.0
		nozzle_x = ship_half_width - 4.0
	
	var flame_tip_x := nozzle_x + 70.0 * flicker * flame_direction
	var half_width := 34.0 * (0.75 + 0.2 * sin(flame_time * 21.0))
	engine_flame.polygon = PackedVector2Array([
		Vector2(nozzle_x, -half_width),
		Vector2(flame_tip_x, 0.0),
		Vector2(nozzle_x, half_width),
	])
	inner_engine_flame.polygon = PackedVector2Array([
		Vector2(nozzle_x + 2.0 * flame_direction, -half_width * 0.45),
		Vector2(flame_tip_x - 24.0 * flame_direction, 0.0),
		Vector2(nozzle_x + 2.0 * flame_direction, half_width * 0.45),
	])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_combat_open and is_combat_finished():
			close_combat_panel()
			return
		
		toggle_pause_menu()
		return
	
	if is_paused or is_traveling or is_combat_open or orbits_paused:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_click(get_global_mouse_position())


func handle_click(click_position: Vector2) -> void:
	for i in enemies.size():
		var enemy := enemies[i]
		if enemy["defeated"]:
			continue
		
		if click_position.distance_to(enemy["position"]) <= enemy_icon_radius + 12.0:
			begin_enemy_orbit_transfer(i)
			return
	
	for planet in planets:
		if click_position.distance_to(planet["position"]) <= planet["radius"] + 16.0:
			begin_planet_intercept(planet)
			return
	
	var distance_from_star := click_position.distance_to(system_center)
	if distance_from_star >= asteroid_belt_inner_radius and distance_from_star <= asteroid_belt_outer_radius:
		begin_travel_to("asteroid_belt", "Asteroid Belt", click_position)


func toggle_pause_menu() -> void:
	is_paused = !is_paused
	
	if is_paused:
		update_engine_flame(false, 0.0)
		pause_menu.show_menu()
	else:
		pause_menu.hide_menu()


func _on_resume_pressed() -> void:
	is_paused = false
	pause_menu.hide_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _draw() -> void:
	draw_orbits()
	draw_star()
	draw_asteroid_belt()
	draw_planets()
	draw_enemies()


func draw_orbits() -> void:
	for planet in planets:
		draw_arc(system_center, planet["orbit_radius"], 0.0, TAU, 180, Color(0.32, 0.48, 0.58, 0.28), orbit_line_width)
	
	draw_arc(
		system_center,
		(asteroid_belt_inner_radius + asteroid_belt_outer_radius) * 0.5,
		0.0,
		TAU,
		220,
		Color(0.48, 0.45, 0.42, 0.18),
		asteroid_belt_outer_radius - asteroid_belt_inner_radius
	)


func draw_star() -> void:
	draw_circle(system_center, 58.0, Color("#FFD76A"))
	draw_circle(system_center, 34.0, Color("#FFF1A3"))


func draw_asteroid_belt() -> void:
	for point in asteroid_belt_points:
		var asteroid_position := system_center + point.rotated(asteroid_belt_angle)
		var size := 1.5 + fmod(absf(point.x + point.y), 3.0)
		draw_circle(asteroid_position, size, Color("#7A716A"))


func draw_planets() -> void:
	for planet in planets:
		var planet_position: Vector2 = planet["position"]
		var planet_radius: float = planet["radius"]
		var planet_texture: Texture2D = planet["texture"]
		var planet_draw_size: Vector2 = planet["draw_size"]
		var draw_rect := Rect2(planet_position - planet_draw_size * 0.5, planet_draw_size)
		
		if planet_texture != null:
			draw_texture_rect(planet_texture, draw_rect, false)
		else:
			draw_circle(planet_position, planet_radius, Color("#7C8D92"))


func draw_enemies() -> void:
	for enemy in enemies:
		if enemy["defeated"]:
			continue
		
		draw_enemy_icon(enemy["position"], Color("#F04F47"), Color("#641B20"))
	
	if is_combat_open and active_enemy_index < 0 and not active_enemy.is_empty():
		draw_enemy_icon(active_enemy["position"], Color("#FFB13B"), Color("#6A3000"))


func draw_enemy_icon(position: Vector2, color: Color, shadow_color: Color) -> void:
	var r := enemy_icon_radius
	var outer_color := Color(color.r, color.g, color.b, 0.92)
	var inner_color := Color(1.0, 0.55, 0.16, 0.95)
	var dim_color := Color(shadow_color.r, shadow_color.g, shadow_color.b, 0.75)
	
	draw_arc(position, r * 1.15, deg_to_rad(18.0), deg_to_rad(102.0), 12, outer_color, 2.5)
	draw_arc(position, r * 1.15, deg_to_rad(138.0), deg_to_rad(222.0), 12, outer_color, 2.5)
	draw_arc(position, r * 1.15, deg_to_rad(258.0), deg_to_rad(342.0), 12, outer_color, 2.5)
	
	draw_polyline(PackedVector2Array([
		position + Vector2(0.0, -r * 0.88),
		position + Vector2(r * 0.72, 0.0),
		position + Vector2(0.0, r * 0.88),
		position + Vector2(-r * 0.72, 0.0),
		position + Vector2(0.0, -r * 0.88),
	]), outer_color, 2.0)
	
	draw_line(position + Vector2(-r * 1.45, 0.0), position + Vector2(-r * 0.82, 0.0), inner_color, 2.0)
	draw_line(position + Vector2(r * 0.82, 0.0), position + Vector2(r * 1.45, 0.0), inner_color, 2.0)
	draw_line(position + Vector2(0.0, -r * 1.45), position + Vector2(0.0, -r * 0.82), inner_color, 2.0)
	draw_line(position + Vector2(0.0, r * 0.82), position + Vector2(0.0, r * 1.45), inner_color, 2.0)
	
	draw_circle(position, r * 0.2, dim_color)
