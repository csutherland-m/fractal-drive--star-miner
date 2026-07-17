class_name GroundEncounterSystem
extends Node2D

class AltarPlaceholder extends Node2D:
	var opened: bool = false

	func _draw() -> void:
		var stone := Color("#5F5662") if not opened else Color("#37323B")
		draw_polygon(
			PackedVector2Array([Vector2(-30, 24), Vector2(-24, -4), Vector2(24, -4), Vector2(30, 24)]),
			PackedColorArray([stone])
		)
		draw_rect(Rect2(-34, 20, 68, 14), stone.darkened(0.18))
		draw_rect(Rect2(-20, -14, 40, 12), stone.lightened(0.12))
		if not opened:
			draw_polygon(
				PackedVector2Array([Vector2(0, -34), Vector2(12, -20), Vector2(0, -8), Vector2(-12, -20)]),
				PackedColorArray([Color("#B9FF42")])
			)
			draw_circle(Vector2(0, -20), 18.0, Color(0.45, 1.0, 0.18, 0.16))


class PortalPlaceholder extends Node2D:
	var active: bool = false
	var pulse: float = 0.0

	func _process(delta: float) -> void:
		if active:
			pulse += delta
			queue_redraw()

	func _draw() -> void:
		if not active:
			return
		var points := get_ellipse_points(28.0, 52.0, 1.0)
		draw_colored_polygon(points, Color(0.28, 0.02, 0.42, 0.82))
		var glow_scale := 1.0 + sin(pulse * 4.0) * 0.08
		draw_polyline(get_ellipse_points(34.0, 58.0, glow_scale), Color("#73FF42"), 7.0)
		draw_polyline(get_ellipse_points(29.0, 52.0, glow_scale), Color("#A52CFF"), 5.0)

	func get_ellipse_points(radius_x: float, radius_y: float, scale_value: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for index in 41:
			var angle := TAU * float(index) / 40.0
			points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y) * scale_value)
		return points


class TribalDemonPlaceholder extends Node2D:
	var demon_id: String = ""
	var encounter_id: String = ""
	var health: float = 3.0
	var attack_remaining: float = 0.0
	var move_speed_multiplier: float = 1.0
	var attack_cooldown_multiplier: float = 1.0
	var dart_damage: int = 5

	func _draw() -> void:
		# Blue Godot-style placeholder face with simple tribal demon horns/paint.
		draw_circle(Vector2.ZERO, 23.0, Color("#478CBF"))
		draw_polygon(
			PackedVector2Array([Vector2(-19, -14), Vector2(-34, -30), Vector2(-27, 2)]),
			PackedColorArray([Color("#D8F1FF")])
		)
		draw_polygon(
			PackedVector2Array([Vector2(19, -14), Vector2(34, -30), Vector2(27, 2)]),
			PackedColorArray([Color("#D8F1FF")])
		)
		draw_circle(Vector2(-8, -4), 4.0, Color("#B9FF42"))
		draw_circle(Vector2(8, -4), 4.0, Color("#B9FF42"))
		draw_line(Vector2(-12, 10), Vector2(12, 10), Color("#17212B"), 4.0)
		draw_line(Vector2(0, -20), Vector2(0, 18), Color("#A52CFF"), 3.0)
		draw_line(Vector2(-18, 2), Vector2(-7, 6), Color("#FF6842"), 3.0)
		draw_line(Vector2(18, 2), Vector2(7, 6), Color("#FF6842"), 3.0)


class BlowDartPlaceholder extends Node2D:
	var velocity: Vector2 = Vector2.ZERO
	var lifetime: float = 4.0
	var damage: int = 5

	func _draw() -> void:
		draw_line(Vector2(-13, 0), Vector2(10, 0), Color("#D8C08A"), 3.0)
		draw_polygon(
			PackedVector2Array([Vector2(10, 0), Vector2(4, -4), Vector2(4, 4)]),
			PackedColorArray([Color("#79FF3B")])
		)


@export var altar_interaction_distance: float = 74.0
@export var demon_count_per_altar: int = 3
@export var demon_spawn_interval: float = 0.8
@export var demon_move_speed: float = 72.0
@export var demon_attack_range: float = 520.0
@export var demon_attack_cooldown: float = 2.2
@export var blow_dart_speed: float = 340.0
@export var blow_dart_damage: int = 5

var mining_scene: Node
var encounter_definitions: Array[Dictionary] = []
var altar_nodes: Dictionary = {}
var portal_nodes: Dictionary = {}
var runtime_by_encounter: Dictionary = {}
var demons: Array[TribalDemonPlaceholder] = []
var darts: Array[BlowDartPlaceholder] = []
var next_demon_serial: int = 0
var interaction_label: Label
var nearest_interaction_id: String = ""


func setup(target_mining_scene: Node) -> void:
	mining_scene = target_mining_scene
	name = "GroundEncounterSystem"
	# Encounters stay below fog (z 6) and above terrain, while the miner remains at z 10.
	z_index = 5
	create_interaction_prompt()


func create_interaction_prompt() -> void:
	var prompt_layer := CanvasLayer.new()
	prompt_layer.name = "GroundEncounterPrompt"
	prompt_layer.layer = 8
	mining_scene.add_child(prompt_layer)
	interaction_label = Label.new()
	interaction_label.anchor_left = 0.5
	interaction_label.anchor_right = 0.5
	interaction_label.anchor_top = 1.0
	interaction_label.anchor_bottom = 1.0
	interaction_label.offset_left = -260.0
	interaction_label.offset_right = 260.0
	interaction_label.offset_top = -210.0
	interaction_label.offset_bottom = -168.0
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_label.add_theme_font_size_override("font_size", 20)
	interaction_label.add_theme_color_override("font_color", Color("#D8FF8A"))
	interaction_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	interaction_label.add_theme_constant_override("shadow_offset_x", 2)
	interaction_label.add_theme_constant_override("shadow_offset_y", 2)
	interaction_label.visible = false
	prompt_layer.add_child(interaction_label)


func sync_encounters(new_definitions: Array[Dictionary]) -> void:
	encounter_definitions = new_definitions
	for encounter in encounter_definitions:
		var encounter_id := str(encounter.get("encounter_id", ""))
		if encounter_id.is_empty():
			continue
		if not altar_nodes.has(encounter_id):
			create_encounter_visuals(encounter)
		update_encounter_visuals(encounter)


func create_encounter_visuals(encounter: Dictionary) -> void:
	var encounter_id := str(encounter["encounter_id"])
	var altar := AltarPlaceholder.new()
	altar.name = "Altar_%s" % encounter_id
	altar.position = mining_scene.mine_tiles.map_to_local(array_to_cell(encounter.get("altar_cell", [0, 0])))
	add_child(altar)
	altar_nodes[encounter_id] = altar

	var portal := PortalPlaceholder.new()
	portal.name = "Portal_%s" % encounter_id
	portal.position = mining_scene.mine_tiles.map_to_local(array_to_cell(encounter.get("portal_cell", [0, 0])))
	add_child(portal)
	portal_nodes[encounter_id] = portal
	runtime_by_encounter[encounter_id] = {
		"pending_spawns": 0,
		"spawn_remaining": 0.0,
	}


func update_encounter_visuals(encounter: Dictionary) -> void:
	var encounter_id := str(encounter.get("encounter_id", ""))
	var altar: AltarPlaceholder = altar_nodes.get(encounter_id)
	var portal: PortalPlaceholder = portal_nodes.get(encounter_id)
	if altar != null:
		altar.opened = bool(encounter.get("looted", false))
		altar.visible = true
		altar.queue_redraw()
	if portal != null:
		portal.active = bool(encounter.get("triggered", false))
		portal.queue_redraw()


func process_encounters(delta: float) -> void:
	if mining_scene == null:
		return
	update_interaction_prompt()
	update_spawning(delta)
	update_demons(delta)
	update_darts(delta)


func update_interaction_prompt() -> void:
	nearest_interaction_id = ""
	var closest_distance := altar_interaction_distance
	for encounter in encounter_definitions:
		if bool(encounter.get("looted", false)):
			continue
		var encounter_id := str(encounter.get("encounter_id", ""))
		var altar: AltarPlaceholder = altar_nodes.get(encounter_id)
		if altar == null:
			continue
		var distance := altar.position.distance_to(mining_scene.player_marker.position)
		if distance <= closest_distance:
			closest_distance = distance
			nearest_interaction_id = encounter_id
	interaction_label.visible = not nearest_interaction_id.is_empty()
	if interaction_label.visible:
		interaction_label.text = "Press F to loot the demon altar"


func try_interact() -> bool:
	update_interaction_prompt()
	if nearest_interaction_id.is_empty():
		return false
	for encounter in encounter_definitions:
		if str(encounter.get("encounter_id", "")) != nearest_interaction_id:
			continue
		if not mining_scene.collect_ground_altar_loot():
			interaction_label.visible = true
			interaction_label.text = "Miner cargo full - make room for the altar artifact"
			return true
		encounter["looted"] = true
		encounter["triggered"] = true
		var runtime: Dictionary = runtime_by_encounter.get(nearest_interaction_id, {})
		runtime["pending_spawns"] = demon_count_per_altar
		runtime["spawn_remaining"] = 0.0
		runtime_by_encounter[nearest_interaction_id] = runtime
		update_encounter_visuals(encounter)
		nearest_interaction_id = ""
		interaction_label.visible = false
		return true
	return false


func update_spawning(delta: float) -> void:
	for encounter in encounter_definitions:
		var encounter_id := str(encounter.get("encounter_id", ""))
		var runtime: Dictionary = runtime_by_encounter.get(encounter_id, {})
		var pending := int(runtime.get("pending_spawns", 0))
		if pending <= 0:
			continue
		var remaining := maxf(float(runtime.get("spawn_remaining", 0.0)) - delta, 0.0)
		if remaining > 0.0:
			runtime["spawn_remaining"] = remaining
			runtime_by_encounter[encounter_id] = runtime
			continue
		spawn_demon(encounter_id)
		runtime["pending_spawns"] = pending - 1
		runtime["spawn_remaining"] = demon_spawn_interval
		runtime_by_encounter[encounter_id] = runtime


func spawn_demon(encounter_id: String) -> void:
	var portal: PortalPlaceholder = portal_nodes.get(encounter_id)
	if portal == null:
		return
	spawn_configured_demon(encounter_id, portal.position, 3, 1.0, 1.0, blow_dart_damage)


func spawn_boss_demon(
	encounter_id: String,
	spawn_position: Vector2,
	health: float,
	move_speed_multiplier: float,
	attack_cooldown_multiplier: float,
	dart_damage: int
) -> void:
	spawn_configured_demon(
		encounter_id,
		spawn_position,
		health,
		move_speed_multiplier,
		attack_cooldown_multiplier,
		dart_damage
	)


func spawn_configured_demon(
	encounter_id: String,
	spawn_position: Vector2,
	health: float,
	move_speed_multiplier: float,
	attack_cooldown_multiplier: float,
	dart_damage: int
) -> void:
	var demon := TribalDemonPlaceholder.new()
	demon.demon_id = "demon_%05d" % next_demon_serial
	next_demon_serial += 1
	demon.encounter_id = encounter_id
	demon.position = spawn_position
	demon.health = maxf(health, 1.0)
	demon.move_speed_multiplier = maxf(move_speed_multiplier, 0.1)
	demon.attack_cooldown_multiplier = maxf(attack_cooldown_multiplier, 0.1)
	demon.dart_damage = maxi(dart_damage, 1)
	demon.attack_remaining = 0.6 + float(demons.size()) * 0.2
	add_child(demon)
	demons.append(demon)


func update_demons(delta: float) -> void:
	for demon in demons:
		if not is_instance_valid(demon):
			continue
		var player_position: Vector2 = mining_scene.player_marker.position
		var to_player := player_position - demon.position
		var distance := to_player.length()
		if distance > 150.0 and distance < demon_attack_range * 1.4:
			var proposed := demon.position + to_player.normalized() * demon_move_speed * demon.move_speed_multiplier * delta
			if not mining_scene.is_solid_at_position(proposed):
				demon.position = proposed
		demon.attack_remaining = maxf(demon.attack_remaining - delta, 0.0)
		if distance <= demon_attack_range and demon.attack_remaining <= 0.0 and has_clear_line(demon.position, player_position):
			spawn_blow_dart(demon.position, player_position, demon.dart_damage)
			demon.attack_remaining = demon_attack_cooldown * demon.attack_cooldown_multiplier


func has_clear_line(start: Vector2, finish: Vector2) -> bool:
	var distance := start.distance_to(finish)
	var steps := maxi(ceili(distance / 24.0), 1)
	for index in range(1, steps):
		var point := start.lerp(finish, float(index) / float(steps))
		if mining_scene.is_solid_at_position(point):
			return false
	return true


func spawn_blow_dart(start: Vector2, target: Vector2, damage: int = 5) -> void:
	var direction := start.direction_to(target)
	var dart := BlowDartPlaceholder.new()
	dart.position = start
	dart.velocity = direction * blow_dart_speed
	dart.damage = maxi(damage, 1)
	dart.rotation = direction.angle()
	add_child(dart)
	darts.append(dart)


func update_darts(delta: float) -> void:
	for index in range(darts.size() - 1, -1, -1):
		var dart := darts[index]
		if not is_instance_valid(dart):
			darts.remove_at(index)
			continue
		dart.lifetime -= delta
		var next_position := dart.position + dart.velocity * delta
		if dart.lifetime <= 0.0 or mining_scene.is_solid_at_position(next_position):
			remove_dart_at(index)
			continue
		dart.position = next_position
		if dart.position.distance_to(mining_scene.player_marker.position) <= 30.0:
			mining_scene.apply_ground_enemy_damage(dart.damage)
			remove_dart_at(index)


func remove_dart_at(index: int) -> void:
	var dart := darts[index]
	darts.remove_at(index)
	if is_instance_valid(dart):
		dart.queue_free()


func damage_enemies_in_cells(target_cells: Array[Vector2i], damage: int = 3) -> int:
	var defeated := 0
	for index in range(demons.size() - 1, -1, -1):
		var demon := demons[index]
		if not is_instance_valid(demon):
			demons.remove_at(index)
			continue
		var demon_cell: Vector2i = mining_scene.mine_tiles.local_to_map(demon.position)
		if not target_cells.has(demon_cell):
			continue
		demon.health -= damage
		if demon.health <= 0:
			mark_demon_defeated(demon.encounter_id)
			demons.remove_at(index)
			demon.queue_free()
			defeated += 1
	return defeated


func damage_enemy_at_position(hit_position: Vector2, damage: float = 1.0, hit_radius: float = 27.0) -> bool:
	for index in range(demons.size() - 1, -1, -1):
		var demon := demons[index]
		if not is_instance_valid(demon):
			demons.remove_at(index)
			continue
		if demon.position.distance_to(hit_position) > hit_radius:
			continue
		demon.health -= damage
		if demon.health <= 0:
			mark_demon_defeated(demon.encounter_id)
			demons.remove_at(index)
			demon.queue_free()
		return true
	return false


func mark_demon_defeated(encounter_id: String) -> void:
	for encounter in encounter_definitions:
		if str(encounter.get("encounter_id", "")) == encounter_id:
			encounter["defeated_count"] = int(encounter.get("defeated_count", 0)) + 1
			return


func count_active_demons(encounter_id: String) -> int:
	var active_count := 0
	for demon in demons:
		if is_instance_valid(demon) and demon.encounter_id == encounter_id:
			active_count += 1
	return active_count


func create_save_data() -> Dictionary:
	var demon_data: Array = []
	for demon in demons:
		if not is_instance_valid(demon):
			continue
		demon_data.append({
			"demon_id": demon.demon_id,
			"encounter_id": demon.encounter_id,
			"position": [demon.position.x, demon.position.y],
			"health": demon.health,
			"attack_remaining": demon.attack_remaining,
			"move_speed_multiplier": demon.move_speed_multiplier,
			"attack_cooldown_multiplier": demon.attack_cooldown_multiplier,
			"dart_damage": demon.dart_damage,
		})
	return {
		"runtime_by_encounter": runtime_by_encounter.duplicate(true),
		"demons": demon_data,
		"next_demon_serial": next_demon_serial,
	}


func apply_save_data(data: Dictionary) -> void:
	for demon in demons:
		if is_instance_valid(demon):
			demon.queue_free()
	demons.clear()
	for dart in darts:
		if is_instance_valid(dart):
			dart.queue_free()
	darts.clear()
	runtime_by_encounter = data.get("runtime_by_encounter", runtime_by_encounter).duplicate(true)
	next_demon_serial = int(data.get("next_demon_serial", 0))
	for saved_demon in data.get("demons", []):
		if not saved_demon is Dictionary:
			continue
		var demon := TribalDemonPlaceholder.new()
		demon.demon_id = str(saved_demon.get("demon_id", ""))
		demon.encounter_id = str(saved_demon.get("encounter_id", ""))
		var position_data: Array = saved_demon.get("position", [0.0, 0.0])
		demon.position = Vector2(float(position_data[0]), float(position_data[1]))
		demon.health = float(saved_demon.get("health", 3.0))
		demon.attack_remaining = float(saved_demon.get("attack_remaining", 0.0))
		demon.move_speed_multiplier = float(saved_demon.get("move_speed_multiplier", 1.0))
		demon.attack_cooldown_multiplier = float(saved_demon.get("attack_cooldown_multiplier", 1.0))
		demon.dart_damage = int(saved_demon.get("dart_damage", blow_dart_damage))
		add_child(demon)
		demons.append(demon)


func array_to_cell(value: Variant) -> Vector2i:
	if value is Array and value.size() >= 2:
		return Vector2i(int(value[0]), int(value[1]))
	return Vector2i.ZERO
