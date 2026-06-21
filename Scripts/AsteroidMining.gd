extends Node2D

enum BlockType {
	EMPTY,
	DIRT,
	ROCK,
	COPPER,
	IRON,
	GOLD,
	TREASURE,
	DIAMOND,
	WARPGEMS,
	BLACKHOLECRYSTALS,
}

@onready var mine_tiles: TileMapLayer = $MineTiles
@onready var player_marker: Sprite2D = $MineTiles/PlayerMarker
@onready var pause_menu: PauseMenu = $PauseMenu

@export var tile_source_id: int = 0

@export var dirt_tile: Vector2i = Vector2i(0, 0)
@export var treasure_tile: Vector2i = Vector2i(1, 0)
@export var rock_tile: Vector2i = Vector2i(2, 0)
@export var copper_tile: Vector2i = Vector2i(0, 1)
@export var iron_tile: Vector2i = Vector2i(1, 1)
@export var gold_tile: Vector2i = Vector2i(2, 1)
@export var warpgems_tile: Vector2i = Vector2i(0, 2)
@export var blackholecrystal_tile: Vector2i = Vector2i(1, 2)
@export var diamond_tile: Vector2i = Vector2i(2, 2)

@export var grid_width: int = 30
@export var grid_height: int = 17
@export var empty_top_rows: int = 4

@export var gravity: float = 900.0
@export var max_fall_speed: float = 500.0
@export var move_speed: float = 220.0
@export var ground_acceleration: float = 1800.0
@export var air_acceleration: float = 900.0
@export var upward_thrust: float = 1500.0
@export var max_rise_speed: float = 360.0
@export var player_collision_width: float = 42.0
@export var player_collision_height: float = 58.0

@export var drill_damage_per_second: float = 1.0
@export var dirt_hardness: float = 1.5
@export var copper_hardness: float = 2.5
@export var iron_hardness: float = 2.5
@export var gold_hardness: float = 3.0
@export var treasure_hardness: float = 3.0
@export var rock_hardness: float = 4.0
@export var diamond_hardness: float = 4.0
@export var warpgems_hardness: float = 5.0
@export var blackholecrystals_hardness: float = 5.0

var is_paused: bool = false
var is_on_ground: bool = false
var player_velocity: Vector2 = Vector2.ZERO
var last_mine_direction: Vector2i = Vector2i.DOWN
var block_types_by_cell: Dictionary = {}
var resources: Dictionary = {}
var hud_label: Label
var active_mining_cell: Vector2i = Vector2i(-9999, -9999)
var active_mining_damage: float = 0.0
var active_mining_elapsed: float = 0.0
var active_block_hardness: float = 0.0


func _ready() -> void:
	pause_menu.resume_requested.connect(_on_resume_pressed)
	pause_menu.quit_requested.connect(_on_quit_pressed)
	
	generate_mine_tiles()
	position_player_in_sky()
	create_hud()
	update_hud()


func _physics_process(delta: float) -> void:
	if is_paused:
		return
	
	handle_player_movement(delta)
	update_mine_direction()
	try_mine_with_movement_input(delta)
	queue_redraw()


func generate_mine_tiles() -> void:
	mine_tiles.clear()
	block_types_by_cell.clear()
	randomize()
	
	for y in grid_height:
		for x in grid_width:
			var cell_position := Vector2i(x, y)
			
			if y < empty_top_rows:
				continue
			
			var block_type := choose_block_type_for_depth(y)
			var tile_coords := get_tile_coords_for_block_type(block_type)
			
			if block_type != BlockType.EMPTY:
				mine_tiles.set_cell(
					cell_position,
					tile_source_id,
					tile_coords
				)
				block_types_by_cell[cell_position] = block_type


func choose_block_type_for_depth(y: int) -> BlockType:
	var depth_ratio := float(y) / float(grid_height)
	var roll := randf()
	
	if depth_ratio < 0.30:
		if roll < 0.70:
			return BlockType.DIRT
		elif roll < 0.95:
			return BlockType.ROCK
		else:
			return BlockType.COPPER
	elif depth_ratio < 0.65:
		if roll < 0.45:
			return BlockType.ROCK
		elif roll < 0.70:
			return BlockType.COPPER
		elif roll < 0.90:
			return BlockType.IRON
		elif roll < 0.98:
			return BlockType.GOLD
		else:
			return BlockType.TREASURE
	else:
		if roll < 0.30:
			return BlockType.ROCK
		elif roll < 0.50:
			return BlockType.IRON
		elif roll < 0.75:
			return BlockType.GOLD
		elif roll < 0.88:
			return BlockType.DIAMOND
		elif roll < 0.96:
			return BlockType.TREASURE
		elif roll < 0.99:
			return BlockType.WARPGEMS
		else:
			return BlockType.BLACKHOLECRYSTALS


func get_tile_coords_for_block_type(block_type: BlockType) -> Vector2i:
	match block_type:
		BlockType.DIRT:
			return dirt_tile
		BlockType.ROCK:
			return rock_tile
		BlockType.COPPER:
			return copper_tile
		BlockType.IRON:
			return iron_tile
		BlockType.GOLD:
			return gold_tile
		BlockType.TREASURE:
			return treasure_tile
		BlockType.DIAMOND:
			return diamond_tile
		BlockType.WARPGEMS:
			return warpgems_tile
		BlockType.BLACKHOLECRYSTALS:
			return blackholecrystal_tile
		_:
			return dirt_tile


func position_player_in_sky() -> void:
	var start_cell := Vector2i(grid_width / 2, empty_top_rows - 2)
	player_marker.position = mine_tiles.map_to_local(start_cell)
	player_marker.rotation = get_rotation_for_mine_direction(Vector2i.DOWN)
	player_marker.z_index = 10
	player_velocity = Vector2.ZERO


func handle_player_movement(delta: float) -> void:
	var horizontal_input := get_horizontal_input()
	var acceleration := ground_acceleration if is_on_ground else air_acceleration
	var target_x_velocity := horizontal_input * move_speed
	
	player_velocity.x = move_toward(
		player_velocity.x,
		target_x_velocity,
		acceleration * delta
	)
	
	player_velocity.y = min(player_velocity.y + gravity * delta, max_fall_speed)
	
	if is_up_thrust_pressed():
		player_velocity.y = max(
			player_velocity.y - upward_thrust * delta,
			-max_rise_speed
		)
		is_on_ground = false
	
	move_player_on_axis(Vector2(player_velocity.x * delta, 0.0))
	is_on_ground = false
	move_player_on_axis(Vector2(0.0, player_velocity.y * delta))


func get_horizontal_input() -> float:
	var input_axis := 0.0
	
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_axis -= 1.0
	
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_axis += 1.0
	
	return input_axis


func is_up_thrust_pressed() -> bool:
	return Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)


func move_player_on_axis(motion: Vector2) -> void:
	var distance := motion.length()
	
	if distance <= 0.0:
		return
	
	var step_count := int(ceil(distance / 4.0))
	var step := motion / float(step_count)
	
	for i in step_count:
		var next_position := player_marker.position + step
		
		if is_player_colliding_at(next_position):
			if step.x != 0.0:
				player_velocity.x = 0.0
			if step.y != 0.0:
				if step.y > 0.0:
					is_on_ground = true
				player_velocity.y = 0.0
			return
		
		player_marker.position = next_position


func is_player_colliding_at(test_position: Vector2) -> bool:
	var half_size := Vector2(
		player_collision_width * 0.5,
		player_collision_height * 0.5
	)
	var inset := 3.0
	var test_points := [
		test_position + Vector2(-half_size.x + inset, -half_size.y + inset),
		test_position + Vector2(half_size.x - inset, -half_size.y + inset),
		test_position + Vector2(-half_size.x + inset, half_size.y - inset),
		test_position + Vector2(half_size.x - inset, half_size.y - inset),
	]
	
	for point in test_points:
		if is_solid_at_position(point):
			return true
	
	return false


func is_solid_at_position(local_position: Vector2) -> bool:
	var cell := mine_tiles.local_to_map(local_position)
	
	if cell.x < 0 or cell.x >= grid_width:
		return true
	
	if cell.y >= grid_height:
		return true
	
	if cell.y < 0:
		return false
	
	return mine_tiles.get_cell_source_id(cell) != -1


func update_mine_direction() -> void:
	var held_direction := get_held_mine_direction()
	
	if held_direction == Vector2i.ZERO:
		return
	
	last_mine_direction = held_direction
	player_marker.rotation = get_rotation_for_mine_direction(last_mine_direction)


func get_held_mine_direction() -> Vector2i:
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		return Vector2i.DOWN
	elif Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		return Vector2i.UP
	elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		return Vector2i.LEFT
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		return Vector2i.RIGHT
	
	return Vector2i.ZERO


func get_rotation_for_mine_direction(direction: Vector2i) -> float:
	match direction:
		Vector2i.LEFT:
			return deg_to_rad(90.0)
		Vector2i.RIGHT:
			return deg_to_rad(-90.0)
		Vector2i.UP:
			return deg_to_rad(180.0)
		_:
			return 0.0


func try_mine_with_movement_input(delta: float) -> void:
	var held_direction := get_held_mine_direction()
	
	if held_direction == Vector2i.ZERO:
		reset_mining_progress()
		return
	
	last_mine_direction = held_direction
	player_marker.rotation = get_rotation_for_mine_direction(last_mine_direction)
	
	var target_cell := get_target_mine_cell()
	
	if mine_tiles.get_cell_source_id(target_cell) == -1:
		reset_mining_progress()
		return
	
	if target_cell != active_mining_cell:
		start_mining_cell(target_cell)
	
	active_mining_elapsed += delta
	active_mining_damage += drill_damage_per_second * delta
	update_hud()
	
	if active_mining_damage >= active_block_hardness:
		mine_target_cell(target_cell)
		reset_mining_progress()


func start_mining_cell(target_cell: Vector2i) -> void:
	active_mining_cell = target_cell
	active_mining_damage = 0.0
	active_mining_elapsed = 0.0
	var block_type: BlockType = block_types_by_cell.get(target_cell, BlockType.ROCK)
	active_block_hardness = get_hardness_for_block_type(block_type)
	update_hud()


func reset_mining_progress() -> void:
	if active_mining_cell == Vector2i(-9999, -9999):
		return
	
	active_mining_cell = Vector2i(-9999, -9999)
	active_mining_damage = 0.0
	active_mining_elapsed = 0.0
	active_block_hardness = 0.0
	update_hud()


func mine_target_cell(target_cell: Vector2i) -> void:
	if mine_tiles.get_cell_source_id(target_cell) == -1:
		return
	
	var block_type: BlockType = block_types_by_cell.get(target_cell, BlockType.ROCK)
	var resource_name := get_resource_name_for_block_type(block_type)
	
	mine_tiles.erase_cell(target_cell)
	block_types_by_cell.erase(target_cell)
	resources[resource_name] = resources.get(resource_name, 0) + 1
	update_hud()


func get_hardness_for_block_type(block_type: BlockType) -> float:
	match block_type:
		BlockType.DIRT:
			return dirt_hardness
		BlockType.COPPER:
			return copper_hardness
		BlockType.IRON:
			return iron_hardness
		BlockType.GOLD:
			return gold_hardness
		BlockType.TREASURE:
			return treasure_hardness
		BlockType.ROCK:
			return rock_hardness
		BlockType.DIAMOND:
			return diamond_hardness
		BlockType.WARPGEMS:
			return warpgems_hardness
		BlockType.BLACKHOLECRYSTALS:
			return blackholecrystals_hardness
		_:
			return rock_hardness


func get_target_mine_cell() -> Vector2i:
	var half_height := player_collision_height * 0.5
	var half_width := player_collision_width * 0.5
	var target_position := player_marker.position
	
	match last_mine_direction:
		Vector2i.LEFT:
			target_position += Vector2(-half_width - 22.0, 0.0)
		Vector2i.RIGHT:
			target_position += Vector2(half_width + 22.0, 0.0)
		Vector2i.UP:
			target_position += Vector2(0.0, -half_height - 24.0)
		_:
			target_position += Vector2(0.0, half_height + 24.0)
	
	return mine_tiles.local_to_map(target_position)


func get_resource_name_for_block_type(block_type: BlockType) -> String:
	match block_type:
		BlockType.DIRT:
			return "Dirt"
		BlockType.ROCK:
			return "Rock"
		BlockType.COPPER:
			return "Copper"
		BlockType.IRON:
			return "Iron"
		BlockType.GOLD:
			return "Gold"
		BlockType.TREASURE:
			return "Treasure"
		BlockType.DIAMOND:
			return "Diamond"
		BlockType.WARPGEMS:
			return "Warp Gems"
		BlockType.BLACKHOLECRYSTALS:
			return "Black Hole Crystals"
		_:
			return "Unknown"


func create_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "MiningHUD"
	add_child(hud_layer)
	
	hud_label = Label.new()
	hud_label.position = Vector2(24, 24)
	hud_label.add_theme_font_size_override("font_size", 24)
	hud_layer.add_child(hud_label)


func update_hud() -> void:
	if hud_label == null:
		return
	
	var resource_lines: Array[String] = []
	
	for resource_name in resources.keys():
		resource_lines.append("%s: %d" % [resource_name, resources[resource_name]])
	
	resource_lines.sort()
	
	if resource_lines.is_empty():
		resource_lines.append("No resources yet")
	
	var mining_status := "Mining: idle"
	
	if active_mining_cell != Vector2i(-9999, -9999):
		var block_type: BlockType = block_types_by_cell.get(active_mining_cell, BlockType.ROCK)
		var block_name := get_resource_name_for_block_type(block_type)
		var estimated_time_remaining := (
			active_block_hardness - active_mining_damage
		) / max(drill_damage_per_second, 0.01)
		mining_status = "Mining %s: %.1f / %.1f HP (%.1fs left)" % [
			block_name,
			min(active_mining_damage, active_block_hardness),
			active_block_hardness,
			max(estimated_time_remaining, 0.0)
		]
	
	hud_label.text = "Mining Test\nA/D or Arrows: Move\nW/Up: Thrust\nHold movement toward a block to mine\n%s\n\n%s" % [
		mining_status,
		"\n".join(resource_lines)
	]


func _draw() -> void:
	var target_cell := get_target_mine_cell()
	var target_position := mine_tiles.map_to_local(target_cell)
	var tile_size := Vector2(64.0, 64.0)
	var target_rect := Rect2(target_position - tile_size * 0.5, tile_size)
	draw_rect(target_rect, Color(1.0, 0.9, 0.2, 0.85), false, 3.0)
	
	if active_mining_cell == Vector2i(-9999, -9999):
		return
	
	if mine_tiles.get_cell_source_id(active_mining_cell) == -1:
		return
	
	var active_position := mine_tiles.map_to_local(active_mining_cell)
	var active_rect := Rect2(active_position - tile_size * 0.5, tile_size)
	var blink_phase := fmod(active_mining_elapsed, 1.0)
	
	if blink_phase < 0.18:
		draw_rect(active_rect, Color(1.0, 1.0, 1.0, 0.35), true)
	
	var progress_ratio := active_mining_damage / max(active_block_hardness, 0.01)
	var progress_rect := Rect2(
		active_rect.position + Vector2(4.0, active_rect.size.y - 8.0),
		Vector2((active_rect.size.x - 8.0) * clamp(progress_ratio, 0.0, 1.0), 4.0)
	)
	draw_rect(progress_rect, Color(0.2, 0.95, 1.0, 0.9), true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()


func toggle_pause_menu() -> void:
	is_paused = !is_paused
	
	if is_paused:
		pause_menu.show_menu()
	else:
		pause_menu.hide_menu()


func _on_resume_pressed() -> void:
	is_paused = false
	pause_menu.hide_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()
