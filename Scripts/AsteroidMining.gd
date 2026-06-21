extends Node2D

const FogOverlayScript := preload("res://Scripts/FogOverlay.gd")

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
@export var generation_buffer_rows: int = 12
@export var reveal_radius_tiles: int = 1
@export var max_fuel_seconds: float = 60.0
@export var inventory_capacity: int = 10

@export var gravity: float = 900.0
@export var max_fall_speed: float = 500.0
@export var move_speed: float = 154.0
@export var ground_acceleration: float = 650.0
@export var air_acceleration: float = 450.0
@export var ground_deceleration: float = 850.0
@export var air_deceleration: float = 550.0
@export var ship_rotation_speed: float = 8.0
@export var upward_thrust: float = 1500.0
@export var max_rise_speed: float = 360.0
@export var player_collision_width: float = 42.0
@export var player_collision_height: float = 58.0
@export var player_sprite_scale: float = 0.39

@export var drill_damage_per_second: float = 1.0
@export var copper_drill_cost: int = 5
@export var copper_drill_damage_multiplier: float = 1.25
@export var copper_drill_tint: Color = Color("#C87533")
@export var sensor_upgrade_copper_cost: int = 1
@export var sensor_upgrade_iron_cost: int = 1
@export var upgraded_sensor_reveal_radius: int = 2
@export var copper_drill_coin_cost: int = 20
@export var sensor_upgrade_coin_cost: int = 15
@export var starting_gold: int = 100
@export var refuel_gold_cost_per_10_seconds: int = 2
@export var dirt_hardness: float = 0.735
@export var copper_hardness: float = 1.75
@export var iron_hardness: float = 1.75
@export var gold_hardness: float = 2.1
@export var treasure_hardness: float = 2.1
@export var rock_hardness: float = 1.96
@export var diamond_hardness: float = 2.8
@export var warpgems_hardness: float = 3.5
@export var blackholecrystals_hardness: float = 3.5

var is_paused: bool = false
var is_shop_open: bool = false
var is_shop_reentry_locked: bool = false
var is_game_over: bool = false
var is_on_ground: bool = false
var player_velocity: Vector2 = Vector2.ZERO
var last_mine_direction: Vector2i = Vector2i.DOWN
var target_player_rotation: float = 0.0
var block_types_by_cell: Dictionary = {}
var resources: Dictionary = {}
var warehouse_resources: Dictionary = {}
var coins: int = 100
var fuel_seconds: float = 60.0
var hud_label: Label
var fuel_bar: ProgressBar
var shop_button: Polygon2D
var shop_center_position: Vector2 = Vector2.ZERO
var shop_size: Vector2 = Vector2(192.0, 64.0)
var shop_panel: Panel
var shop_status_label: Label
var refuel_button: Button
var game_over_label: Label
var mining_camera: Camera2D
var fog_overlay: Node2D
var mining_blink_overlay: Polygon2D
var mining_progress_overlay: Polygon2D
var revealed_cells: Dictionary = {}
var active_mining_cell: Vector2i = Vector2i(-9999, -9999)
var active_mining_damage: float = 0.0
var active_mining_elapsed: float = 0.0
var active_block_hardness: float = 0.0
var has_copper_drill_upgrade: bool = false
var has_sensor_upgrade: bool = false
var generated_row_count: int = 0


func _ready() -> void:
	pause_menu.resume_requested.connect(_on_resume_pressed)
	pause_menu.quit_requested.connect(_on_quit_pressed)
	coins = starting_gold
	fuel_seconds = max_fuel_seconds
	
	generate_mine_tiles()
	position_player_in_sky()
	create_surface_shop()
	create_mining_camera()
	create_fog_overlay()
	create_mining_overlays()
	create_shop_ui()
	create_game_over_ui()
	create_hud()
	update_revealed_cells()
	update_camera()
	update_hud()


func _physics_process(delta: float) -> void:
	if is_paused:
		return
	
	handle_player_movement(delta)
	drain_fuel_for_movement(delta)
	check_shop_collision()
	ensure_world_generated_near_player()
	update_camera()
	update_mine_direction()
	rotate_player_toward_target(delta)
	try_mine_with_movement_input(delta)
	update_revealed_cells()
	update_mining_overlays()
	queue_redraw()


func generate_mine_tiles() -> void:
	mine_tiles.clear()
	block_types_by_cell.clear()
	revealed_cells.clear()
	generated_row_count = 0
	randomize()
	
	generate_rows_until(grid_height)


func generate_rows_until(target_row_count: int) -> void:
	if target_row_count <= generated_row_count:
		return
	
	for y in range(generated_row_count, target_row_count):
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
	
	generated_row_count = target_row_count


func choose_block_type_for_depth(y: int) -> BlockType:
	var depth_ratio: float = minf(float(y) / 80.0, 1.0)
	var roll := randf()
	
	if depth_ratio < 0.30:
		if roll < 0.70:
			return BlockType.DIRT
		elif roll < 0.98:
			return BlockType.ROCK
		else:
			return BlockType.COPPER
	elif depth_ratio < 0.65:
		if roll < 0.45:
			return BlockType.DIRT
		elif roll < 0.86:
			return BlockType.ROCK
		elif roll < 0.93:
			return BlockType.COPPER
		elif roll < 0.97:
			return BlockType.IRON
		elif roll < 0.99:
			return BlockType.GOLD
		else:
			return BlockType.TREASURE
	else:
		if roll < 0.20:
			return BlockType.DIRT
		elif roll < 0.75:
			return BlockType.ROCK
		elif roll < 0.83:
			return BlockType.COPPER
		elif roll < 0.89:
			return BlockType.IRON
		elif roll < 0.93:
			return BlockType.GOLD
		elif roll < 0.96:
			return BlockType.TREASURE
		elif roll < 0.98:
			return BlockType.DIAMOND
		elif roll < 0.992:
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
	var start_cell := Vector2i(floori(float(grid_width) / 2.0), empty_top_rows - 2)
	player_marker.position = mine_tiles.map_to_local(start_cell)
	player_marker.scale = Vector2(player_sprite_scale, player_sprite_scale)
	target_player_rotation = get_rotation_for_mine_direction(Vector2i.DOWN)
	player_marker.rotation = target_player_rotation
	player_marker.z_index = 10
	player_velocity = Vector2.ZERO


func create_surface_shop() -> void:
	var shop_cell := Vector2i(floori(float(grid_width) / 2.0), empty_top_rows - 3)
	shop_center_position = mine_tiles.map_to_local(shop_cell)
	
	shop_button = Polygon2D.new()
	shop_button.name = "SurfaceShop"
	shop_button.z_index = 7
	shop_button.color = Color("#777777")
	shop_button.position = shop_center_position
	shop_button.polygon = PackedVector2Array([
		Vector2(-shop_size.x * 0.5, -shop_size.y * 0.5),
		Vector2(shop_size.x * 0.5, -shop_size.y * 0.5),
		Vector2(shop_size.x * 0.5, shop_size.y * 0.5),
		Vector2(-shop_size.x * 0.5, shop_size.y * 0.5),
	])
	mine_tiles.add_child(shop_button)


func check_shop_collision() -> void:
	if is_shop_open or is_game_over:
		return
	
	var player_rect := get_player_rect(player_marker.position)
	var shop_rect := get_shop_rect()
	var is_touching_shop := player_rect.intersects(shop_rect)
	
	if is_shop_reentry_locked:
		if not is_touching_shop:
			is_shop_reentry_locked = false
		return
	
	if is_touching_shop:
		open_shop()


func get_shop_rect() -> Rect2:
	return Rect2(shop_center_position - shop_size * 0.5, shop_size)


func get_player_rect(test_position: Vector2) -> Rect2:
	return Rect2(
		test_position - Vector2(player_collision_width, player_collision_height) * 0.5,
		Vector2(player_collision_width, player_collision_height)
	)


func drain_fuel_for_movement(delta: float) -> void:
	if not is_movement_input_pressed():
		return
	
	fuel_seconds = maxf(fuel_seconds - delta, 0.0)
	update_hud()
	
	if fuel_seconds <= 0.0:
		trigger_game_over()


func is_movement_input_pressed() -> bool:
	return (
		Input.is_key_pressed(KEY_A)
		or Input.is_key_pressed(KEY_D)
		or Input.is_key_pressed(KEY_W)
		or Input.is_key_pressed(KEY_S)
		or Input.is_key_pressed(KEY_LEFT)
		or Input.is_key_pressed(KEY_RIGHT)
		or Input.is_key_pressed(KEY_UP)
		or Input.is_key_pressed(KEY_DOWN)
	)


func create_mining_camera() -> void:
	mining_camera = Camera2D.new()
	mining_camera.name = "MiningCamera"
	mining_camera.position_smoothing_enabled = true
	mining_camera.position_smoothing_speed = 8.0
	add_child(mining_camera)
	mining_camera.make_current()


func update_camera() -> void:
	if mining_camera == null:
		return
	
	mining_camera.global_position = player_marker.global_position


func create_fog_overlay() -> void:
	fog_overlay = FogOverlayScript.new()
	fog_overlay.name = "FogOverlay"
	fog_overlay.z_index = 6
	fog_overlay.mining_scene = self
	mine_tiles.add_child(fog_overlay)


func ensure_world_generated_near_player() -> void:
	var player_cell := get_player_cell()
	var needed_rows: int = player_cell.y + generation_buffer_rows
	
	if needed_rows > generated_row_count:
		generate_rows_until(needed_rows)


func get_player_cell() -> Vector2i:
	return mine_tiles.local_to_map(player_marker.position)


func update_revealed_cells() -> void:
	var player_cell := get_player_cell()
	
	for y in range(player_cell.y - reveal_radius_tiles, player_cell.y + reveal_radius_tiles + 1):
		for x in range(player_cell.x - reveal_radius_tiles, player_cell.x + reveal_radius_tiles + 1):
			var cell := Vector2i(x, y)
			
			if cell.x < 0 or cell.x >= grid_width:
				continue
			
			if cell.y < 0:
				continue
			
			revealed_cells[cell] = true
	
	if fog_overlay != null:
		fog_overlay.queue_redraw()


func is_cell_revealed(cell: Vector2i) -> bool:
	return revealed_cells.has(cell)


func handle_player_movement(delta: float) -> void:
	var horizontal_input := get_horizontal_input()
	var target_x_velocity := horizontal_input * move_speed
	var x_change_rate := get_horizontal_change_rate(horizontal_input)
	
	player_velocity.x = move_toward(
		player_velocity.x,
		target_x_velocity,
		x_change_rate * delta
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


func get_horizontal_change_rate(horizontal_input: float) -> float:
	if horizontal_input == 0.0:
		return ground_deceleration if is_on_ground else air_deceleration
	
	return ground_acceleration if is_on_ground else air_acceleration


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
	var step: Vector2 = motion / float(step_count)
	
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
	
	if cell.y < 0:
		return false
	
	if cell.y >= generated_row_count:
		generate_rows_until(cell.y + generation_buffer_rows)
	
	return mine_tiles.get_cell_source_id(cell) != -1


func update_mine_direction() -> void:
	var held_direction := get_held_mine_direction()
	
	if held_direction == Vector2i.ZERO:
		return
	
	last_mine_direction = held_direction
	target_player_rotation = get_rotation_for_mine_direction(last_mine_direction)


func rotate_player_toward_target(delta: float) -> void:
	player_marker.rotation = lerp_angle(
		player_marker.rotation,
		target_player_rotation,
		ship_rotation_speed * delta
	)


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
	target_player_rotation = get_rotation_for_mine_direction(last_mine_direction)
	
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
	
	if is_inventory_resource(resource_name) and get_inventory_count() >= inventory_capacity:
		update_hud()
		return
	
	mine_tiles.erase_cell(target_cell)
	block_types_by_cell.erase(target_cell)
	
	if is_inventory_resource(resource_name):
		resources[resource_name] = int(resources.get(resource_name, 0)) + 1
	
	update_hud()


func is_inventory_resource(resource_name: String) -> bool:
	return resource_name != "Dirt" and resource_name != "Rock" and resource_name != "Unknown"


func get_inventory_count() -> int:
	var count := 0
	
	for resource_name in resources.keys():
		count += int(resources[resource_name])
	
	return count


func get_warehouse_count() -> int:
	var count := 0
	
	for resource_name in warehouse_resources.keys():
		count += int(warehouse_resources[resource_name])
	
	return count


func get_total_resource_count(resource_name: String) -> int:
	return int(resources.get(resource_name, 0)) + int(warehouse_resources.get(resource_name, 0))


func consume_resource(resource_name: String, amount: int) -> void:
	var warehouse_count: int = int(warehouse_resources.get(resource_name, 0))
	var from_warehouse: int = mini(warehouse_count, amount)
	warehouse_resources[resource_name] = warehouse_count - from_warehouse
	amount -= from_warehouse
	
	if amount <= 0:
		return
	
	var cargo_count: int = int(resources.get(resource_name, 0))
	resources[resource_name] = maxi(cargo_count - amount, 0)


func get_resource_value(resource_name: String) -> int:
	match resource_name:
		"Copper":
			return 3
		"Iron":
			return 5
		"Gold":
			return 9
		"Treasure":
			return 12
		"Diamond":
			return 18
		"Warp Gems":
			return 30
		"Black Hole Crystals":
			return 45
		_:
			return 0


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


func create_mining_overlays() -> void:
	mining_blink_overlay = Polygon2D.new()
	mining_blink_overlay.name = "MiningBlinkOverlay"
	mining_blink_overlay.z_index = 8
	mining_blink_overlay.color = Color(0.82, 0.96, 1.0, 0.42)
	mining_blink_overlay.polygon = PackedVector2Array([
		Vector2(-32.0, -32.0),
		Vector2(32.0, -32.0),
		Vector2(32.0, 32.0),
		Vector2(-32.0, 32.0),
	])
	mining_blink_overlay.visible = false
	mine_tiles.add_child(mining_blink_overlay)
	
	mining_progress_overlay = Polygon2D.new()
	mining_progress_overlay.name = "MiningProgressOverlay"
	mining_progress_overlay.z_index = 9
	mining_progress_overlay.color = Color(0.2, 0.95, 1.0, 0.9)
	mining_progress_overlay.visible = false
	mine_tiles.add_child(mining_progress_overlay)


func update_mining_overlays() -> void:
	if mining_blink_overlay == null or mining_progress_overlay == null:
		return
	
	if active_mining_cell == Vector2i(-9999, -9999):
		mining_blink_overlay.visible = false
		mining_progress_overlay.visible = false
		return
	
	if mine_tiles.get_cell_source_id(active_mining_cell) == -1:
		mining_blink_overlay.visible = false
		mining_progress_overlay.visible = false
		return
	
	var active_position := mine_tiles.map_to_local(active_mining_cell)
	var blink_phase: float = fmod(active_mining_elapsed, 0.5)
	var progress_ratio: float = active_mining_damage / maxf(active_block_hardness, 0.01)
	var progress_width: float = 56.0 * clampf(progress_ratio, 0.0, 1.0)
	
	mining_blink_overlay.position = active_position
	mining_blink_overlay.visible = blink_phase < 0.16
	
	mining_progress_overlay.position = active_position
	mining_progress_overlay.polygon = PackedVector2Array([
		Vector2(-28.0, 24.0),
		Vector2(-28.0 + progress_width, 24.0),
		Vector2(-28.0 + progress_width, 28.0),
		Vector2(-28.0, 28.0),
	])
	mining_progress_overlay.visible = true


func create_shop_ui() -> void:
	var shop_layer := CanvasLayer.new()
	shop_layer.name = "ShopUI"
	add_child(shop_layer)
	
	shop_panel = Panel.new()
	shop_panel.name = "ShopPanel"
	shop_panel.anchor_left = 0.5
	shop_panel.anchor_right = 0.5
	shop_panel.anchor_top = 0.5
	shop_panel.anchor_bottom = 0.5
	shop_panel.offset_left = -330.0
	shop_panel.offset_right = 330.0
	shop_panel.offset_top = -335.0
	shop_panel.offset_bottom = 335.0
	shop_panel.visible = false
	shop_layer.add_child(shop_panel)
	
	var scroll := ScrollContainer.new()
	scroll.name = "ShopScroll"
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 24.0
	scroll.offset_top = 20.0
	scroll.offset_right = -24.0
	scroll.offset_bottom = -20.0
	shop_panel.add_child(scroll)
	
	var box := VBoxContainer.new()
	box.name = "ShopBox"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	
	var title := Label.new()
	title.text = "Surface Shop"
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	
	shop_status_label = Label.new()
	shop_status_label.add_theme_font_size_override("font_size", 16)
	shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(shop_status_label)
	
	add_shop_button(box, "Store All Cargo", Callable(self, "_on_deposit_all_pressed"))
	add_shop_button(box, "Withdraw All That Fits", Callable(self, "_on_withdraw_all_pressed"))
	add_shop_button(box, "Sell All Cargo", Callable(self, "_on_sell_all_pressed"))
	add_shop_button(box, "Sell Copper", Callable(self, "_on_sell_copper_pressed"))
	add_shop_button(box, "Sell Iron", Callable(self, "_on_sell_iron_pressed"))
	add_shop_button(box, "Sell Gold", Callable(self, "_on_sell_gold_pressed"))
	add_shop_button(box, "Sell Treasure", Callable(self, "_on_sell_treasure_pressed"))
	add_shop_button(box, "Sell Diamond", Callable(self, "_on_sell_diamond_pressed"))
	add_shop_button(box, "Sell Warp Gems", Callable(self, "_on_sell_warp_gems_pressed"))
	add_shop_button(box, "Sell Black Hole Crystals", Callable(self, "_on_sell_black_hole_crystals_pressed"))
	add_shop_button(box, "Store Copper", Callable(self, "deposit_resource").bind("Copper"))
	add_shop_button(box, "Store Iron", Callable(self, "deposit_resource").bind("Iron"))
	add_shop_button(box, "Store Gold", Callable(self, "deposit_resource").bind("Gold"))
	add_shop_button(box, "Withdraw Copper", Callable(self, "withdraw_resource").bind("Copper"))
	add_shop_button(box, "Withdraw Iron", Callable(self, "withdraw_resource").bind("Iron"))
	add_shop_button(box, "Withdraw Gold", Callable(self, "withdraw_resource").bind("Gold"))
	refuel_button = add_shop_button(box, "Refuel Fully: 2 Gold per 10s", Callable(self, "_on_refuel_pressed"))
	add_shop_button(box, "Buy Copper Drill: 20 Gold + 5 Copper", Callable(self, "_on_buy_copper_drill_pressed"))
	add_shop_button(box, "Buy Sensors: 15 Gold + 1 Copper + 1 Iron", Callable(self, "_on_buy_sensor_upgrade_pressed"))
	add_shop_button(box, "Leave Shop", Callable(self, "close_shop"))


func add_shop_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 28.0)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func open_shop() -> void:
	is_shop_open = true
	is_paused = true
	reset_mining_progress()
	player_velocity = Vector2.ZERO
	shop_panel.visible = true
	update_shop_ui()
	update_hud()


func close_shop() -> void:
	is_shop_open = false
	is_shop_reentry_locked = true
	is_paused = false
	shop_panel.visible = false
	update_hud()


func update_shop_ui() -> void:
	if shop_status_label == null:
		return
	
	var refuel_cost := get_full_refuel_cost()
	if refuel_button != null:
		refuel_button.disabled = refuel_cost <= 0 or coins < refuel_cost
	
	shop_status_label.text = (
		"Gold Coins: %d\nFuel: %.1f / %.1fs\nRefuel Cost: %d Gold\nCargo: %d / %d\nWarehouse: %d items\n\nCargo:\n%s\n\nWarehouse:\n%s\n\nUpgrades:\n%s\n%s"
		% [
			coins,
			fuel_seconds,
			max_fuel_seconds,
			refuel_cost,
			get_inventory_count(),
			inventory_capacity,
			get_warehouse_count(),
			get_resource_list_text(resources),
			get_resource_list_text(warehouse_resources),
			get_drill_upgrade_text(),
			get_sensor_upgrade_text()
		]
	)


func get_resource_list_text(source: Dictionary) -> String:
	var lines: Array[String] = []
	
	for resource_name in get_sellable_resource_names():
		var count: int = int(source.get(resource_name, 0))
		if count > 0:
			lines.append("%s: %d" % [resource_name, count])
	
	if lines.is_empty():
		lines.append("Empty")
	
	return "\n".join(lines)


func get_drill_upgrade_text() -> String:
	if has_copper_drill_upgrade:
		return "Copper Drill: purchased"
	
	return "Copper Drill: 20 Gold + 5 Copper (+25% drill damage)"


func get_sensor_upgrade_text() -> String:
	if has_sensor_upgrade:
		return "Sensors: purchased"
	
	return "Sensors: 15 Gold + 1 Copper + 1 Iron (vision radius 2)"


func get_sellable_resource_names() -> Array[String]:
	return [
		"Copper",
		"Iron",
		"Gold",
		"Treasure",
		"Diamond",
		"Warp Gems",
		"Black Hole Crystals",
	]


func sell_resource(resource_name: String) -> void:
	var count: int = int(resources.get(resource_name, 0))
	
	if count <= 0:
		return
	
	coins += count * get_resource_value(resource_name)
	resources[resource_name] = 0
	update_shop_ui()
	update_hud()


func deposit_resource(resource_name: String) -> void:
	var count: int = int(resources.get(resource_name, 0))
	
	if count <= 0:
		return
	
	warehouse_resources[resource_name] = int(warehouse_resources.get(resource_name, 0)) + count
	resources[resource_name] = 0
	update_shop_ui()
	update_hud()


func withdraw_resource(resource_name: String) -> void:
	var stored_count: int = int(warehouse_resources.get(resource_name, 0))
	var cargo_room: int = inventory_capacity - get_inventory_count()
	var amount: int = mini(stored_count, cargo_room)
	
	if amount <= 0:
		return
	
	warehouse_resources[resource_name] = stored_count - amount
	resources[resource_name] = int(resources.get(resource_name, 0)) + amount
	update_shop_ui()
	update_hud()


func _on_deposit_all_pressed() -> void:
	for resource_name in get_sellable_resource_names():
		deposit_resource(resource_name)
	
	update_shop_ui()
	update_hud()


func _on_withdraw_all_pressed() -> void:
	for resource_name in get_sellable_resource_names():
		withdraw_resource(resource_name)
	
	update_shop_ui()
	update_hud()


func _on_sell_all_pressed() -> void:
	for resource_name in get_sellable_resource_names():
		var count: int = int(resources.get(resource_name, 0))
		coins += count * get_resource_value(resource_name)
		resources[resource_name] = 0
	
	update_shop_ui()
	update_hud()


func _on_sell_copper_pressed() -> void:
	sell_resource("Copper")


func _on_sell_iron_pressed() -> void:
	sell_resource("Iron")


func _on_sell_gold_pressed() -> void:
	sell_resource("Gold")


func _on_sell_treasure_pressed() -> void:
	sell_resource("Treasure")


func _on_sell_diamond_pressed() -> void:
	sell_resource("Diamond")


func _on_sell_warp_gems_pressed() -> void:
	sell_resource("Warp Gems")


func _on_sell_black_hole_crystals_pressed() -> void:
	sell_resource("Black Hole Crystals")


func _on_refuel_pressed() -> void:
	var refuel_cost: int = get_full_refuel_cost()
	
	if refuel_cost <= 0 or coins < refuel_cost:
		update_shop_ui()
		return
	
	coins -= refuel_cost
	fuel_seconds = max_fuel_seconds
	update_shop_ui()
	update_hud()


func get_full_refuel_cost() -> int:
	var missing_fuel: float = max_fuel_seconds - fuel_seconds
	var ten_second_chunks: int = ceili(missing_fuel / 10.0)
	return ten_second_chunks * refuel_gold_cost_per_10_seconds


func _on_buy_copper_drill_pressed() -> void:
	if has_copper_drill_upgrade:
		return
	
	var copper_count: int = get_total_resource_count("Copper")
	
	if coins < copper_drill_coin_cost or copper_count < copper_drill_cost:
		update_shop_ui()
		return
	
	coins -= copper_drill_coin_cost
	consume_resource("Copper", copper_drill_cost)
	drill_damage_per_second *= copper_drill_damage_multiplier
	has_copper_drill_upgrade = true
	player_marker.modulate = copper_drill_tint
	update_shop_ui()
	update_hud()


func _on_buy_sensor_upgrade_pressed() -> void:
	if has_sensor_upgrade:
		return
	
	var copper_count: int = get_total_resource_count("Copper")
	var iron_count: int = get_total_resource_count("Iron")
	
	if (
		coins < sensor_upgrade_coin_cost
		or copper_count < sensor_upgrade_copper_cost
		or iron_count < sensor_upgrade_iron_cost
	):
		update_shop_ui()
		return
	
	coins -= sensor_upgrade_coin_cost
	consume_resource("Copper", sensor_upgrade_copper_cost)
	consume_resource("Iron", sensor_upgrade_iron_cost)
	reveal_radius_tiles = upgraded_sensor_reveal_radius
	has_sensor_upgrade = true
	update_revealed_cells()
	update_shop_ui()
	update_hud()


func create_game_over_ui() -> void:
	var game_over_layer := CanvasLayer.new()
	game_over_layer.name = "GameOverUI"
	add_child(game_over_layer)
	
	game_over_label = Label.new()
	game_over_label.anchor_left = 0.5
	game_over_label.anchor_right = 0.5
	game_over_label.anchor_top = 0.5
	game_over_label.anchor_bottom = 0.5
	game_over_label.offset_left = -430.0
	game_over_label.offset_right = 430.0
	game_over_label.offset_top = -70.0
	game_over_label.offset_bottom = 70.0
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_label.add_theme_font_size_override("font_size", 34)
	game_over_label.text = "You lose! You're a fuckin Looser, Bruhhhh"
	game_over_label.visible = false
	game_over_layer.add_child(game_over_label)


func trigger_game_over() -> void:
	if is_game_over:
		return
	
	is_game_over = true
	is_shop_open = false
	is_paused = true
	player_velocity = Vector2.ZERO
	reset_mining_progress()
	
	if shop_panel != null:
		shop_panel.visible = false
	
	if game_over_label != null:
		game_over_label.visible = true
	
	await get_tree().create_timer(2.5).timeout
	get_tree().change_scene_to_file("res://Scenes/main_game_menu.tscn")


func create_hud() -> void:
	var hud_layer := CanvasLayer.new()
	hud_layer.name = "MiningHUD"
	add_child(hud_layer)
	
	var fuel_bar_label := Label.new()
	fuel_bar_label.text = "Fuel"
	fuel_bar_label.position = Vector2(24.0, 14.0)
	fuel_bar_label.add_theme_font_size_override("font_size", 18)
	hud_layer.add_child(fuel_bar_label)
	
	fuel_bar = ProgressBar.new()
	fuel_bar.name = "FuelBar"
	fuel_bar.anchor_left = 0.0
	fuel_bar.anchor_right = 1.0
	fuel_bar.offset_left = 82.0
	fuel_bar.offset_right = -24.0
	fuel_bar.offset_top = 12.0
	fuel_bar.offset_bottom = 34.0
	fuel_bar.min_value = 0.0
	fuel_bar.max_value = max_fuel_seconds
	fuel_bar.value = fuel_seconds
	fuel_bar.show_percentage = false
	hud_layer.add_child(fuel_bar)
	
	hud_label = Label.new()
	hud_label.position = Vector2(24, 52)
	hud_label.add_theme_font_size_override("font_size", 24)
	hud_layer.add_child(hud_label)


func update_hud() -> void:
	if hud_label == null:
		return
	
	if fuel_bar != null:
		fuel_bar.max_value = max_fuel_seconds
		fuel_bar.value = clampf(fuel_seconds, 0.0, max_fuel_seconds)
	
	var resource_lines: Array[String] = []
	
	for resource_name in get_sellable_resource_names():
		var count: int = int(resources.get(resource_name, 0))
		if count > 0:
			resource_lines.append("%s: %d" % [resource_name, count])
	
	if resource_lines.is_empty():
		resource_lines.append("No ore in cargo")
	
	var mining_status := "Mining: idle"
	
	if active_mining_cell != Vector2i(-9999, -9999):
		var block_type: BlockType = block_types_by_cell.get(active_mining_cell, BlockType.ROCK)
		var block_name := get_resource_name_for_block_type(block_type)
		var estimated_time_remaining: float = (
			active_block_hardness - active_mining_damage
		) / maxf(drill_damage_per_second, 0.01)
		mining_status = "Mining %s: %.1f / %.1f HP (%.1fs left)" % [
			block_name,
			minf(active_mining_damage, active_block_hardness),
			active_block_hardness,
			maxf(estimated_time_remaining, 0.0)
		]
	
	var shop_status := "Find the gray shop box at the surface to sell, refuel, and upgrade."
	if is_shop_open:
		shop_status = "Shop open"
	
	hud_label.text = "Fuel: %.1fs / %.1fs\nGold Coins: %d\nCargo: %d / %d\n%s\n%s\n\n%s" % [
		fuel_seconds,
		max_fuel_seconds,
		coins,
		get_inventory_count(),
		inventory_capacity,
		shop_status,
		mining_status,
		"\n".join(resource_lines)
	]


func _draw() -> void:
	var target_cell := get_target_mine_cell()
	var target_position := mine_tiles.map_to_local(target_cell)
	var tile_size := Vector2(64.0, 64.0)
	var target_rect := Rect2(target_position - tile_size * 0.5, tile_size)
	draw_rect(target_rect, Color(1.0, 0.9, 0.2, 0.85), false, 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		return
	
	if event.is_action_pressed("ui_cancel"):
		if is_shop_open:
			close_shop()
			return
		
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
