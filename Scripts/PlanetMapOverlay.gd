class_name PlanetMapOverlay
extends Control

signal close_requested

const MIN_CELL_SIZE := 2.0
const MAX_CELL_SIZE := 28.0
const PAN_SPEED := 620.0

var mining_scene: Node
var cell_size: float = 7.0
var map_center_cell := Vector2.ZERO
var dragging := false
var last_mouse_position := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func open_at_player() -> void:
	if mining_scene == null:
		return
	map_center_cell = Vector2(mining_scene.get_player_cell())
	visible = true
	grab_focus()
	queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		map_center_cell += direction * PAN_SPEED * delta / cell_size
		clamp_map_center()
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_event.pressed:
			zoom_at(mouse_event.position, 1.2)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_event.pressed:
			zoom_at(mouse_event.position, 1.0 / 1.2)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_LEFT:
			dragging = mouse_event.pressed
			last_mouse_position = mouse_event.position
			accept_event()
	elif event is InputEventMouseMotion and dragging:
		var motion := event as InputEventMouseMotion
		map_center_cell -= motion.relative / cell_size
		last_mouse_position = motion.position
		clamp_map_center()
		queue_redraw()
		accept_event()
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var pressed_key := key_event.keycode if key_event.keycode != 0 else key_event.physical_keycode
			if pressed_key == KEY_M or event.is_action_pressed(GameSettings.MENU_BACK_ACTION):
				close_requested.emit()
				accept_event()


func zoom_at(screen_position: Vector2, multiplier: float) -> void:
	var old_cell_size := cell_size
	cell_size = clampf(cell_size * multiplier, MIN_CELL_SIZE, MAX_CELL_SIZE)
	if is_equal_approx(old_cell_size, cell_size):
		return
	var viewport_center := size * 0.5
	var cell_under_cursor := map_center_cell + (screen_position - viewport_center) / old_cell_size
	map_center_cell = cell_under_cursor - (screen_position - viewport_center) / cell_size
	clamp_map_center()
	queue_redraw()


func clamp_map_center() -> void:
	if mining_scene == null:
		return
	map_center_cell.x = clampf(map_center_cell.x, 0.0, float(mining_scene.grid_width - 1))
	map_center_cell.y = clampf(map_center_cell.y, 0.0, float(maxi(mining_scene.generated_row_count - 1, 0)))


func _draw() -> void:
	if mining_scene == null or not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.025, 0.04, 0.88), true)
	var viewport_center := size * 0.5
	var half_cells := size / maxf(cell_size, 0.001) * 0.5
	var min_x := maxi(floori(map_center_cell.x - half_cells.x) - 1, 0)
	var max_x := mini(ceili(map_center_cell.x + half_cells.x) + 1, mining_scene.grid_width - 1)
	var min_y := maxi(floori(map_center_cell.y - half_cells.y) - 1, 0)
	var max_y := mini(ceili(map_center_cell.y + half_cells.y) + 1, mining_scene.generated_row_count - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var cell := Vector2i(x, y)
			if not mining_scene.revealed_cells.has(cell):
				continue
			var screen_position := viewport_center + (Vector2(cell) - map_center_cell) * cell_size
			var color := get_cell_color(cell)
			draw_rect(Rect2(screen_position - Vector2.ONE * cell_size * 0.5, Vector2.ONE * maxf(cell_size - 0.5, 1.0)), color, true)
	for marker_cell in mining_scene.gps_marker_cells:
		var marker_position := viewport_center + (Vector2(marker_cell) - map_center_cell) * cell_size
		if not Rect2(Vector2.ZERO, size).grow(20.0).has_point(marker_position):
			continue
		draw_circle(marker_position, clampf(cell_size, 5.0, 11.0), Color(1.0, 0.82, 0.08, 1.0))
		draw_line(marker_position, marker_position + Vector2(0.0, clampf(cell_size * 2.0, 12.0, 24.0)), Color(1.0, 0.82, 0.08, 1.0), 3.0)
	var player_position := viewport_center + (Vector2(mining_scene.get_player_cell()) - map_center_cell) * cell_size
	draw_circle(player_position, clampf(cell_size * 0.8, 5.0, 13.0), Color(0.2, 1.0, 0.95, 1.0))
	draw_circle(player_position, clampf(cell_size * 0.8, 5.0, 13.0), Color.WHITE, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 42.0), "PLANET MAP  |  M / Esc: close  |  Drag or arrows: pan  |  Wheel: zoom", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(28.0, 72.0), "Cyan: miner     Yellow: GPS shaft marker     Only explored terrain is shown", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(0.75, 0.9, 1.0))


func get_cell_color(cell: Vector2i) -> Color:
	if not mining_scene.block_types_by_cell.has(cell):
		return Color(0.12, 0.17, 0.22, 0.95)
	match int(mining_scene.block_types_by_cell[cell]):
		mining_scene.BlockType.DIRT:
			return Color(0.42, 0.27, 0.15, 1.0)
		mining_scene.BlockType.ROCK:
			return Color(0.38, 0.41, 0.45, 1.0)
		mining_scene.BlockType.LODESTONE:
			return Color(0.18, 0.2, 0.23, 1.0)
		mining_scene.BlockType.COPPER:
			return Color(0.88, 0.43, 0.16, 1.0)
		mining_scene.BlockType.RAWFUEL:
			return Color(0.2, 0.88, 0.44, 1.0)
		mining_scene.BlockType.IRON:
			return Color(0.76, 0.82, 0.88, 1.0)
		mining_scene.BlockType.GOLD:
			return Color(1.0, 0.78, 0.12, 1.0)
		mining_scene.BlockType.TREASURE:
			return Color(0.82, 0.26, 0.9, 1.0)
		mining_scene.BlockType.DIAMOND:
			return Color(0.35, 0.9, 1.0, 1.0)
		mining_scene.BlockType.WARPGEMS:
			return Color(0.5, 0.25, 1.0, 1.0)
		mining_scene.BlockType.BLACKHOLECRYSTALS:
			return Color(0.9, 0.2, 0.55, 1.0)
		mining_scene.BlockType.PLANETCORE:
			return Color.WHITE
		_:
			return Color(0.25, 0.28, 0.32, 1.0)
