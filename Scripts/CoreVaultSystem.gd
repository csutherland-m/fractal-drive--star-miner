class_name CoreVaultSystem
extends Node2D


class CoreAltarPlaceholder extends Node2D:
	var core_claimed: bool = false

	func _draw() -> void:
		# Oversized basalt altar with glowing placeholder demon-tech conduits.
		draw_colored_polygon(
			PackedVector2Array([
				Vector2(-150.0, 70.0), Vector2(-118.0, 4.0), Vector2(-72.0, -18.0),
				Vector2(72.0, -18.0), Vector2(118.0, 4.0), Vector2(150.0, 70.0),
			]),
			Color("#211B2C")
		)
		draw_rect(Rect2(-170.0, 62.0, 340.0, 38.0), Color("#0F1118"))
		for x in [-118.0, -76.0, 76.0, 118.0]:
			draw_line(Vector2(x, 55.0), Vector2(x * 0.58, -46.0), Color("#73FF42"), 8.0)
			draw_circle(Vector2(x * 0.58, -46.0), 9.0, Color("#A52CFF"))
		draw_arc(Vector2.ZERO, 92.0, PI, TAU, 32, Color("#A52CFF"), 8.0)
		draw_arc(Vector2.ZERO, 70.0, PI, TAU, 32, Color("#73FF42"), 5.0)
		if not core_claimed:
			draw_circle(Vector2(0.0, -58.0), 42.0, Color(0.48, 0.08, 0.82, 0.2))


class BossPortalPlaceholder extends Node2D:
	var active: bool = false
	var pulse: float = 0.0

	func _process(delta: float) -> void:
		if active:
			pulse += delta
			queue_redraw()

	func _draw() -> void:
		if not active:
			return
		var scale_value := 1.0 + sin(pulse * 5.0) * 0.09
		var points := PackedVector2Array()
		for index in 41:
			var angle := TAU * float(index) / 40.0
			points.append(Vector2(cos(angle) * 34.0, sin(angle) * 58.0) * scale_value)
		draw_colored_polygon(points, Color(0.3, 0.0, 0.46, 0.86))
		draw_polyline(points, Color("#73FF42"), 7.0)


class SealPlaceholder extends Node2D:
	var active: bool = false
	var seal_width: float = 0.0

	func _draw() -> void:
		if not active:
			return
		draw_rect(Rect2(-seal_width * 0.5, -24.0, seal_width, 48.0), Color(0.1, 0.02, 0.14, 0.82))
		for x in range(floori(-seal_width * 0.5), ceili(seal_width * 0.5), 48):
			draw_line(Vector2(x, -22.0), Vector2(x + 24.0, 22.0), Color("#A52CFF"), 5.0)
			draw_line(Vector2(x + 24.0, 22.0), Vector2(x + 48.0, -22.0), Color("#73FF42"), 5.0)


const BOSS_ENCOUNTER_ID := "planet_core_vault_boss"

@export var wave_enemy_counts: Array[int] = [3, 5, 7, 9, 12]
@export var wave_enemy_health: Array[int] = [3, 4, 5, 6, 8]
@export var wave_move_multipliers: Array[float] = [1.0, 1.08, 1.16, 1.25, 1.35]
@export var wave_attack_cooldown_multipliers: Array[float] = [1.0, 0.92, 0.84, 0.76, 0.68]
@export var wave_dart_damage: Array[int] = [5, 6, 7, 8, 10]
@export var spawn_interval: float = 0.42
@export var between_wave_delay: float = 2.0

var mining_scene: Node
var altar: CoreAltarPlaceholder
var portals: Array[BossPortalPlaceholder] = []
var seal_visual: SealPlaceholder
var status_label: Label
var boss_started: bool = false
var boss_active: bool = false
var boss_completed: bool = false
var current_wave: int = 0
var pending_spawns: int = 0
var spawn_remaining: float = 0.0
var waiting_for_next_wave: bool = false
var wave_transition_remaining: float = 0.0
var next_portal_index: int = 0


func setup(scene: Node) -> void:
	mining_scene = scene
	name = "CoreVaultSystem"
	z_index = 5
	create_world_visuals()
	create_status_ui()


func create_world_visuals() -> void:
	altar = CoreAltarPlaceholder.new()
	altar.name = "PlanetCoreGrandAltar"
	altar.position = mining_scene.mine_tiles.map_to_local(mining_scene.planet_core_cell)
	add_child(altar)
	for portal_cell in mining_scene.get_core_vault_portal_cells():
		var portal := BossPortalPlaceholder.new()
		portal.position = mining_scene.mine_tiles.map_to_local(portal_cell)
		add_child(portal)
		portals.append(portal)
	seal_visual = SealPlaceholder.new()
	seal_visual.name = "CoreVaultCeilingSeal"
	seal_visual.position = mining_scene.mine_tiles.map_to_local(mining_scene.get_core_vault_entrance_center_cell())
	seal_visual.seal_width = float(mining_scene.core_vault_width_blocks) * 64.0
	add_child(seal_visual)


func create_status_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CoreVaultBossHUD"
	layer.layer = 9
	mining_scene.add_child(layer)
	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_right = 0.5
	status_label.offset_left = -310.0
	status_label.offset_right = 310.0
	status_label.offset_top = 92.0
	status_label.offset_bottom = 144.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 24)
	status_label.add_theme_color_override("font_color", Color("#D8FF8A"))
	status_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	status_label.add_theme_constant_override("shadow_offset_x", 2)
	status_label.add_theme_constant_override("shadow_offset_y", 2)
	status_label.visible = false
	layer.add_child(status_label)


func start_boss_encounter() -> void:
	if boss_started or boss_completed:
		return
	boss_started = true
	boss_active = true
	altar.core_claimed = true
	altar.queue_redraw()
	mining_scene.close_core_vault_ceiling()
	set_portals_active(true)
	begin_next_wave()


func begin_next_wave() -> void:
	current_wave += 1
	if current_wave > wave_enemy_counts.size():
		complete_boss_encounter()
		return
	pending_spawns = wave_enemy_counts[current_wave - 1]
	spawn_remaining = 0.0
	waiting_for_next_wave = false
	wave_transition_remaining = 0.0
	update_status()


func process_encounter(delta: float) -> void:
	if not boss_active:
		return
	if pending_spawns > 0:
		spawn_remaining = maxf(spawn_remaining - delta, 0.0)
		if spawn_remaining <= 0.0:
			spawn_one_demon()
			pending_spawns -= 1
			spawn_remaining = spawn_interval
		update_status()
		return
	if mining_scene.ground_encounter_system.count_active_demons(BOSS_ENCOUNTER_ID) > 0:
		update_status()
		return
	if not waiting_for_next_wave:
		waiting_for_next_wave = true
		wave_transition_remaining = between_wave_delay
	wave_transition_remaining = maxf(wave_transition_remaining - delta, 0.0)
	if wave_transition_remaining <= 0.0:
		if current_wave >= wave_enemy_counts.size():
			complete_boss_encounter()
		else:
			begin_next_wave()
	update_status()


func spawn_one_demon() -> void:
	if portals.is_empty():
		return
	var wave_index := clampi(current_wave - 1, 0, wave_enemy_counts.size() - 1)
	var portal := portals[next_portal_index % portals.size()]
	next_portal_index += 1
	mining_scene.ground_encounter_system.spawn_boss_demon(
		BOSS_ENCOUNTER_ID,
		portal.position,
		wave_enemy_health[wave_index],
		wave_move_multipliers[wave_index],
		wave_attack_cooldown_multipliers[wave_index],
		wave_dart_damage[wave_index]
	)


func complete_boss_encounter() -> void:
	boss_active = false
	boss_completed = true
	pending_spawns = 0
	waiting_for_next_wave = false
	set_portals_active(false)
	mining_scene.open_core_vault_ceiling()
	status_label.text = "CORE VAULT SECURED — CEILING UNSEALED"
	status_label.visible = true
	mining_scene.complete_core_vault_boss_encounter()


func set_portals_active(active: bool) -> void:
	for portal in portals:
		portal.active = active
		portal.queue_redraw()
	if seal_visual != null:
		seal_visual.active = boss_active and not boss_completed
		seal_visual.queue_redraw()


func update_status() -> void:
	if status_label == null:
		return
	status_label.visible = boss_active
	if not boss_active:
		return
	var alive: int = mining_scene.ground_encounter_system.count_active_demons(BOSS_ENCOUNTER_ID)
	status_label.text = "CORE VAULT LOCKDOWN — WAVE %d / %d — %d REMAIN" % [
		current_wave,
		wave_enemy_counts.size(),
		alive + pending_spawns,
	]


func create_save_data() -> Dictionary:
	return {
		"boss_started": boss_started,
		"boss_active": boss_active,
		"boss_completed": boss_completed,
		"current_wave": current_wave,
		"pending_spawns": pending_spawns,
		"spawn_remaining": spawn_remaining,
		"waiting_for_next_wave": waiting_for_next_wave,
		"wave_transition_remaining": wave_transition_remaining,
		"next_portal_index": next_portal_index,
	}


func apply_save_data(data: Dictionary) -> void:
	boss_started = bool(data.get("boss_started", false))
	boss_active = bool(data.get("boss_active", false))
	boss_completed = bool(data.get("boss_completed", false))
	current_wave = int(data.get("current_wave", 0))
	pending_spawns = int(data.get("pending_spawns", 0))
	spawn_remaining = float(data.get("spawn_remaining", 0.0))
	waiting_for_next_wave = bool(data.get("waiting_for_next_wave", false))
	wave_transition_remaining = float(data.get("wave_transition_remaining", 0.0))
	next_portal_index = int(data.get("next_portal_index", 0))
	altar.core_claimed = boss_started or boss_completed
	altar.queue_redraw()
	if boss_active:
		mining_scene.close_core_vault_ceiling()
	elif boss_completed:
		mining_scene.open_core_vault_ceiling()
	set_portals_active(boss_active)
	update_status()
