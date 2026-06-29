extends Node2D

const FogOverlayScript := preload("res://Scripts/FogOverlay.gd")
const ResourceTileTexture := preload("res://Sprites/TileSets/MiningTilesVariantsDugDirt64.png")
const GaugeClusterTexture := preload("res://Sprites/UI/gauge_cluster_concept.png")
const GAUGE_CLUSTER_SIZE := Vector2(560.0, 320.0)

enum BlockType {
	EMPTY,
	DIRT,
	ROCK,
	COPPER,
	RAWFUEL,
	IRON,
	GOLD,
	TREASURE,
	DIAMOND,
	WARPGEMS,
	BLACKHOLECRYSTALS,
}

@onready var mine_tiles: TileMapLayer = $MineTiles
@onready var background_tiles: TileMapLayer = $BackgroundTiles
@onready var visual_mine_tiles: TileMapLayer = $VisualMineTiles
@onready var player_marker: Sprite2D = $MineTiles/PlayerMarker
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var starfield: Node2D = $Starfield

@export var tile_source_id: int = 0

@export var dirt_tiles: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
@export var rock_tiles: Array[Vector2i] = [Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)]
@export var rawfuel_tiles: Array[Vector2i] = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
@export var copper_tiles: Array[Vector2i] = [Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1)]
@export var treasure_tiles: Array[Vector2i] = [Vector2i(7, 1)]
@export var iron_tiles: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
@export var gold_tiles: Array[Vector2i] = [Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2)]
@export var warpgems_tiles: Array[Vector2i] = [Vector2i(6, 2), Vector2i(7, 2)]
@export var blackholecrystal_tiles: Array[Vector2i] = [Vector2i(0, 3), Vector2i(1, 3)]
@export var diamond_tiles: Array[Vector2i] = [Vector2i(2, 3), Vector2i(3, 3)]
@export var dug_dirt_tiles: Array[Vector2i] = [Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3)]

@export var grid_width: int = 60
@export var grid_height: int = 17
@export var empty_top_rows: int = 4
@export var generation_buffer_rows: int = 12
@export var side_fog_padding_pixels: float = 300.0
@export var depth_meters_per_row: int = 10
@export var reveal_radius_tiles: int = 1
@export var surface_revealed_ground_rows: int = 2
@export var max_fuel_seconds: float = 60.0
@export var fuel_warning_ratio: float = 0.3
@export var mining_fuel_seconds_per_kg: float = 1.0
@export var idle_fuel_seconds_per_kg: float = 10.0
@export var mining_fuel_kg_per_raw_fuel: int = 200
@export var rocket_fuel_tons_per_raw_fuel: int = 1
@export var max_lander_mining_fuel_kg: int = 200
@export var max_lander_rocket_fuel_tons: int = 20
@export var max_starship_mining_fuel_kg: int = 7000
@export var starting_starship_mining_fuel_kg: int = 1000
@export var inventory_capacity: int = 10
@export var shop_lander_texture_path: String = "res://Sprites/Vehicles/RocketLanderEdited.png"
@export var shop_lander_scale: float = 0.75
@export var shop_lander_bottom_padding_pixels: float = 14.0
@export var shop_lander_ground_overlap_pixels: float = 3.0
@export var miner_spawn_offset_from_lander_tiles: int = 2

@export var gravity: float = 900.0
@export var max_fall_speed: float = 500.0
@export var move_speed: float = 154.0
@export var ground_acceleration: float = 650.0
@export var air_acceleration: float = 450.0
@export var ground_deceleration: float = 850.0
@export var air_deceleration: float = 550.0
@export var upward_thrust: float = 1500.0
@export var max_rise_speed: float = 360.0
@export var player_collision_width: float = 42.0
@export var player_collision_height: float = 58.0
@export var player_sprite_scale: float = 1.0
@export var player_animation_frames: int = 4
@export var player_animation_fps: float = 10.0

@export var drill_damage_per_second: float = 1.0
@export var copper_drill_cost: int = 5
@export var copper_drill_damage_multiplier: float = 1.25
@export var copper_drill_tint: Color = Color("#C87533")
@export var sensor_upgrade_copper_cost: int = 1
@export var sensor_upgrade_iron_cost: int = 1
@export var upgraded_sensor_reveal_radius: int = 2
@export var copper_drill_credit_cost: int = 20
@export var sensor_upgrade_credit_cost: int = 15
@export var starting_credits: int = 100
@export var emergency_refuel_credit_cost_per_kg: int = 10
@export var arrival_countdown_seconds: int = 3
@export var dirt_hardness: float = 0.735
@export var copper_hardness: float = 1.75
@export var rawfuel_hardness: float = 1.75
@export var iron_hardness: float = 1.75
@export var gold_hardness: float = 2.1
@export var treasure_hardness: float = 2.1
@export var rock_hardness: float = 1.96
@export var diamond_hardness: float = 2.8
@export var warpgems_hardness: float = 3.5
@export var blackholecrystals_hardness: float = 3.5
@export var depth_hardness_increase_per_row: float = 0.1

var is_paused: bool = false
var is_shop_open: bool = false
var is_shop_reentry_locked: bool = false
var is_game_over: bool = false
var is_arrival_countdown_active: bool = false
var is_on_ground: bool = false
var player_velocity: Vector2 = Vector2.ZERO
var last_mine_direction: Vector2i = Vector2i.DOWN
var player_animation_time: float = 0.0
var block_types_by_cell: Dictionary = {}
var resources: Dictionary = {}
var cargo_hold_resources: Dictionary = {}
var credits: int = 100
var fuel_seconds: float = 60.0
var lander_mining_fuel_kg: int = 0
var lander_rocket_fuel_tons: int = 0
var starship_mining_fuel_kg: int = 0
var hud_label: Label
var hud_cargo_icons: VBoxContainer
var gauge_cluster: Control
var gauge_depth_label: Label
var gauge_fuel_needle: ColorRect
var gauge_heat_needle: ColorRect
var heat_ratio: float = 0.0
var fuel_bar: Control
var fuel_bar_fill: ColorRect
var fuel_bar_segments: Array[ColorRect] = []
var fuel_warning_blink_time: float = 0.0
var shop_button: Sprite2D
var shop_center_position: Vector2 = Vector2.ZERO
var shop_size: Vector2 = Vector2(192.0, 64.0)
var shop_panel: Panel
var shop_status_label: Label
var shop_content: Control
var shop_title_label: Label
var lander_cargo_hold_list: VBoxContainer
var refuel_button: Button
var upgrade_levels: Dictionary = {}
var upgrade_definitions: Dictionary = {}
var fuel_consumption_multiplier: float = 1.0
var game_over_label: Label
var countdown_label: Label
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
	configure_crisp_canvas_items()
	pause_menu.resume_requested.connect(_on_resume_pressed)
	pause_menu.quit_requested.connect(_on_quit_pressed)
	credits = starting_credits
	fuel_seconds = max_fuel_seconds
	starship_mining_fuel_kg = mini(starting_starship_mining_fuel_kg, max_starship_mining_fuel_kg)
	fill_lander_mining_fuel_from_starship()
	
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


func configure_crisp_canvas_items() -> void:
	mine_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	visual_mine_tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _physics_process(delta: float) -> void:
	if is_paused or is_arrival_countdown_active:
		return
	
	handle_player_movement(delta)
	drain_fuel_for_movement(delta)
	update_fuel_bar(delta)
	check_shop_collision()
	ensure_world_generated_near_player()
	update_camera()
	update_mine_direction()
	try_mine_with_movement_input(delta)
	update_player_visual(delta)
	update_revealed_cells()
	update_mining_overlays()
	queue_redraw()


func generate_mine_tiles() -> void:
	mine_tiles.clear()
	background_tiles.clear()
	visual_mine_tiles.clear()
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
			
			background_tiles.set_cell(
				cell_position,
				tile_source_id,
				get_dug_dirt_tile_coords()
			)
			
			var block_type := choose_block_type_for_depth(y)
			var tile_coords := get_tile_coords_for_block_type(block_type)
			
			if block_type != BlockType.EMPTY:
				visual_mine_tiles.set_cell(
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
		elif roll < 0.965:
			return BlockType.ROCK
		elif roll < 0.987:
			return BlockType.COPPER
		else:
			return BlockType.RAWFUEL
	elif depth_ratio < 0.65:
		if roll < 0.45:
			return BlockType.DIRT
		elif roll < 0.84:
			return BlockType.ROCK
		elif roll < 0.91:
			return BlockType.COPPER
		elif roll < 0.96:
			return BlockType.RAWFUEL
		elif roll < 0.985:
			return BlockType.IRON
		elif roll < 0.995:
			return BlockType.GOLD
		else:
			return BlockType.TREASURE
	else:
		if roll < 0.20:
			return BlockType.DIRT
		elif roll < 0.72:
			return BlockType.ROCK
		elif roll < 0.80:
			return BlockType.COPPER
		elif roll < 0.87:
			return BlockType.RAWFUEL
		elif roll < 0.92:
			return BlockType.IRON
		elif roll < 0.955:
			return BlockType.GOLD
		elif roll < 0.98:
			return BlockType.TREASURE
		elif roll < 0.992:
			return BlockType.DIAMOND
		elif roll < 0.997:
			return BlockType.WARPGEMS
		else:
			return BlockType.BLACKHOLECRYSTALS


func get_tile_coords_for_block_type(block_type: BlockType) -> Vector2i:
	match block_type:
		BlockType.DIRT:
			return pick_tile_coords(dirt_tiles, Vector2i(0, 0))
		BlockType.ROCK:
			return pick_tile_coords(rock_tiles, Vector2i(4, 0))
		BlockType.COPPER:
			return pick_tile_coords(copper_tiles, Vector2i(4, 1))
		BlockType.RAWFUEL:
			return pick_tile_coords(rawfuel_tiles, Vector2i(0, 1))
		BlockType.IRON:
			return pick_tile_coords(iron_tiles, Vector2i(0, 2))
		BlockType.GOLD:
			return pick_tile_coords(gold_tiles, Vector2i(3, 2))
		BlockType.TREASURE:
			return pick_tile_coords(treasure_tiles, Vector2i(7, 1))
		BlockType.DIAMOND:
			return pick_tile_coords(diamond_tiles, Vector2i(2, 3))
		BlockType.WARPGEMS:
			return pick_tile_coords(warpgems_tiles, Vector2i(6, 2))
		BlockType.BLACKHOLECRYSTALS:
			return pick_tile_coords(blackholecrystal_tiles, Vector2i(0, 3))
		_:
			return pick_tile_coords(dirt_tiles, Vector2i(0, 0))


func get_dug_dirt_tile_coords() -> Vector2i:
	return pick_tile_coords(dug_dirt_tiles, Vector2i(4, 3))


func pick_tile_coords(tile_options: Array[Vector2i], fallback: Vector2i) -> Vector2i:
	if tile_options.is_empty():
		return fallback
	
	return tile_options.pick_random()


func position_player_in_sky() -> void:
	var lander_column := get_lander_surface_column()
	var miner_column := clampi(
		lander_column + miner_spawn_offset_from_lander_tiles,
		0,
		grid_width - 1
	)
	var start_cell := Vector2i(miner_column, empty_top_rows - 2)
	player_marker.position = mine_tiles.map_to_local(start_cell)
	player_marker.scale = Vector2(player_sprite_scale, player_sprite_scale)
	player_marker.rotation = 0.0
	player_marker.region_enabled = true
	player_marker.region_rect = Rect2(0.0, 0.0, 64.0, 64.0)
	player_marker.z_index = 10
	player_velocity = Vector2.ZERO


func create_surface_shop() -> void:
	var shop_texture := load(shop_lander_texture_path) as Texture2D
	var lander_column := get_lander_surface_column()
	var first_ground_cell := Vector2i(lander_column, get_first_ground_row())
	var first_ground_center := mine_tiles.map_to_local(first_ground_cell)
	var ground_top_y := first_ground_center.y - 32.0
	var lander_height := 192.0
	
	if shop_texture != null:
		lander_height = shop_texture.get_height() * shop_lander_scale
	
	var lander_ground_offset := (
		shop_lander_bottom_padding_pixels * shop_lander_scale
		+ shop_lander_ground_overlap_pixels
	)
	shop_center_position = Vector2(
		first_ground_center.x,
		ground_top_y - lander_height * 0.5 + lander_ground_offset
	)
	
	shop_button = Sprite2D.new()
	shop_button.name = "SurfaceShop"
	shop_button.z_index = 7
	shop_button.position = shop_center_position
	shop_button.texture = shop_texture
	shop_button.scale = Vector2(shop_lander_scale, shop_lander_scale)
	mine_tiles.add_child(shop_button)


func get_lander_surface_column() -> int:
	return clampi(floori(float(grid_width) / 2.0), 0, grid_width - 1)


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


func get_first_ground_row() -> int:
	return empty_top_rows


func get_player_rect(test_position: Vector2) -> Rect2:
	return Rect2(
		test_position - Vector2(player_collision_width, player_collision_height) * 0.5,
		Vector2(player_collision_width, player_collision_height)
	)


func drain_fuel_for_movement(delta: float) -> void:
	var fuel_drain_rate := fuel_consumption_multiplier
	
	if not is_movement_input_pressed():
		fuel_drain_rate = 1.0 / maxf(idle_fuel_seconds_per_kg, 0.01)
	
	fuel_seconds = maxf(fuel_seconds - delta * fuel_drain_rate, 0.0)
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
	mining_camera.position_smoothing_enabled = false
	add_child(mining_camera)
	mining_camera.make_current()


func update_camera() -> void:
	if mining_camera == null:
		return
	
	mining_camera.global_position = player_marker.global_position.round()
	starfield.global_position = (mining_camera.global_position - get_viewport_rect().size * 0.5).round()


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
	reveal_surface_ground_cells()
	
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


func reveal_surface_ground_cells() -> void:
	var first_ground_row := get_first_ground_row()
	var last_surface_row := first_ground_row + maxi(surface_revealed_ground_rows, 1) - 1
	
	for y in range(first_ground_row, last_surface_row + 1):
		for x in range(grid_width):
			revealed_cells[Vector2i(x, y)] = true


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
	
	return block_types_by_cell.has(cell)


func update_mine_direction() -> void:
	var held_direction := get_held_mine_direction()
	
	if held_direction == Vector2i.ZERO:
		return
	
	last_mine_direction = held_direction


func get_held_mine_direction() -> Vector2i:
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		return Vector2i.DOWN
	elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		return Vector2i.LEFT
	elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		return Vector2i.RIGHT
	
	return Vector2i.ZERO


func update_player_visual(delta: float) -> void:
	var held_direction := get_held_mine_direction()
	var visual_direction := last_mine_direction
	var is_animating := held_direction != Vector2i.ZERO or player_velocity.length() > 5.0
	
	if held_direction != Vector2i.ZERO:
		visual_direction = held_direction
	elif absf(player_velocity.x) > absf(player_velocity.y) and absf(player_velocity.x) > 5.0:
		visual_direction = Vector2i.RIGHT if player_velocity.x > 0.0 else Vector2i.LEFT
	elif absf(player_velocity.y) > 5.0:
		visual_direction = Vector2i.DOWN if player_velocity.y > 0.0 else Vector2i.UP
	
	if is_animating:
		player_animation_time += delta
	
	var frame := int(floor(player_animation_time * player_animation_fps)) % maxi(player_animation_frames, 1)
	var row := 0
	player_marker.rotation = 0.0
	player_marker.flip_h = false
	player_marker.flip_v = false
	
	match visual_direction:
		Vector2i.LEFT:
			row = 1
			player_marker.flip_h = true
		Vector2i.RIGHT:
			row = 1
		Vector2i.UP:
			row = 0
			player_marker.flip_v = true
		_:
			row = 0
	
	player_marker.region_rect = Rect2(
		float(frame * 64),
		float(row * 64),
		64.0,
		64.0
	)


func try_mine_with_movement_input(delta: float) -> void:
	var held_direction := get_held_mine_direction()
	
	if held_direction == Vector2i.ZERO:
		reset_mining_progress()
		return
	
	last_mine_direction = held_direction
	
	var target_cell := get_target_mine_cell()
	
	if not block_types_by_cell.has(target_cell):
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
	active_block_hardness = get_depth_scaled_hardness(block_type, target_cell.y)
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
	if not block_types_by_cell.has(target_cell):
		return
	
	var block_type: BlockType = block_types_by_cell.get(target_cell, BlockType.ROCK)
	var resource_name := get_resource_name_for_block_type(block_type)
	
	if is_inventory_resource(resource_name) and get_inventory_count() >= inventory_capacity:
		update_hud()
		return
	
	visual_mine_tiles.erase_cell(target_cell)
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


func get_cargo_hold_count() -> int:
	var count := 0
	
	for resource_name in cargo_hold_resources.keys():
		count += int(cargo_hold_resources[resource_name])
	
	return count


func get_total_resource_count(resource_name: String) -> int:
	return int(resources.get(resource_name, 0)) + int(cargo_hold_resources.get(resource_name, 0))


func get_total_sellable_resource_count() -> int:
	var count := 0
	for resource_name in get_sellable_resource_names():
		count += get_total_resource_count(resource_name)
	return count


func consume_resource(resource_name: String, amount: int) -> void:
	var cargo_hold_count: int = int(cargo_hold_resources.get(resource_name, 0))
	var from_cargo_hold: int = mini(cargo_hold_count, amount)
	cargo_hold_resources[resource_name] = cargo_hold_count - from_cargo_hold
	amount -= from_cargo_hold
	
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
		"Raw Fuel":
			return 4
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
		BlockType.RAWFUEL:
			return rawfuel_hardness
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


func get_depth_scaled_hardness(block_type: BlockType, row: int) -> float:
	var depth_rows: int = maxi(row - get_first_ground_row(), 0)
	var depth_multiplier: float = 1.0 + float(depth_rows) * depth_hardness_increase_per_row
	return get_hardness_for_block_type(block_type) * depth_multiplier


func get_target_mine_cell() -> Vector2i:
	var half_height := player_collision_height * 0.5
	var half_width := player_collision_width * 0.5
	var target_position := player_marker.position
	
	match last_mine_direction:
		Vector2i.LEFT:
			target_position += Vector2(-half_width - 22.0, 0.0)
		Vector2i.RIGHT:
			target_position += Vector2(half_width + 22.0, 0.0)
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
		BlockType.RAWFUEL:
			return "Raw Fuel"
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
	
	if not block_types_by_cell.has(active_mining_cell):
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
	initialize_upgrade_definitions()
	
	var shop_layer := CanvasLayer.new()
	shop_layer.name = "ShopUI"
	add_child(shop_layer)
	
	shop_panel = Panel.new()
	shop_panel.name = "ShopPanel"
	shop_panel.theme = GameTheme.create_button_theme()
	shop_panel.anchor_left = 0.04
	shop_panel.anchor_right = 0.96
	shop_panel.anchor_top = 0.05
	shop_panel.anchor_bottom = 0.95
	shop_panel.offset_left = 0.0
	shop_panel.offset_right = 0.0
	shop_panel.offset_top = 0.0
	shop_panel.offset_bottom = 0.0
	shop_panel.visible = false
	shop_layer.add_child(shop_panel)
	
	var margin := MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.offset_left = 28.0
	margin.offset_top = 24.0
	margin.offset_right = -28.0
	margin.offset_bottom = -24.0
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	shop_panel.add_child(margin)
	
	var box := VBoxContainer.new()
	box.name = "ShopBox"
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)
	
	shop_title_label = Label.new()
	shop_title_label.text = "Surface Shop"
	shop_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_title_label.add_theme_font_size_override("font_size", 30)
	box.add_child(shop_title_label)
	
	shop_status_label = Label.new()
	shop_status_label.add_theme_font_size_override("font_size", 16)
	shop_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(shop_status_label)
	
	shop_content = VBoxContainer.new()
	shop_content.name = "ShopContent"
	shop_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_content.add_theme_constant_override("separation", 18)
	box.add_child(shop_content)
	
	show_shop_main_view()


func add_shop_button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 46.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func apply_individual_sell_button_style(button: Button) -> void:
	button.add_theme_stylebox_override(
		"normal",
		GameTheme.create_button_style(Color("#78B4CE"), Color("#526F82"), Color("#16242E"))
	)
	button.add_theme_stylebox_override(
		"hover",
		GameTheme.create_button_style(Color("#8CC8DE"), Color("#638196"), Color("#16242E"))
	)
	button.add_theme_stylebox_override(
		"pressed",
		GameTheme.create_button_style(Color("#5D91AA"), Color("#3D5A6D"), Color("#0B141B"))
	)


func add_shop_spacer(parent: Control) -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(spacer)
	return spacer


func clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func create_resource_icon(resource_name: String, icon_size: Vector2 = Vector2(32.0, 32.0)) -> TextureRect:
	var icon := TextureRect.new()
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = ResourceTileTexture
	atlas_texture.region = Rect2(Vector2(get_resource_icon_tile_coords(resource_name)) * 64.0, Vector2(64.0, 64.0))
	icon.texture = atlas_texture
	icon.custom_minimum_size = icon_size
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon


func get_resource_icon_tile_coords(resource_name: String) -> Vector2i:
	match resource_name:
		"Copper":
			return copper_tiles[0] if not copper_tiles.is_empty() else Vector2i(4, 1)
		"Raw Fuel":
			return rawfuel_tiles[0] if not rawfuel_tiles.is_empty() else Vector2i(0, 1)
		"Iron":
			return iron_tiles[0] if not iron_tiles.is_empty() else Vector2i(0, 2)
		"Gold":
			return gold_tiles[0] if not gold_tiles.is_empty() else Vector2i(3, 2)
		"Treasure":
			return treasure_tiles[0] if not treasure_tiles.is_empty() else Vector2i(7, 1)
		"Diamond":
			return diamond_tiles[0] if not diamond_tiles.is_empty() else Vector2i(2, 3)
		"Warp Gems":
			return warpgems_tiles[0] if not warpgems_tiles.is_empty() else Vector2i(6, 2)
		"Black Hole Crystals":
			return blackholecrystal_tiles[0] if not blackholecrystal_tiles.is_empty() else Vector2i(0, 3)
		_:
			return dirt_tiles[0] if not dirt_tiles.is_empty() else Vector2i(0, 0)


func clear_shop_content() -> void:
	if shop_content == null:
		return
	
	lander_cargo_hold_list = null
	clear_children(shop_content)


func show_shop_main_view() -> void:
	clear_shop_content()
	shop_title_label.text = "Surface Shop"
	
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 28)
	top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.add_child(top_row)
	
	add_shop_button(top_row, "Upgrades", Callable(self, "show_upgrade_category_view"))
	refuel_button = add_shop_button(top_row, get_refuel_button_text(), Callable(self, "_on_refuel_pressed"))
	add_shop_button(top_row, "Lander", Callable(self, "show_market_view"))
	
	var center_box := CenterContainer.new()
	center_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_content.add_child(center_box)
	
	var summary := Label.new()
	summary.custom_minimum_size = Vector2(520.0, 80.0)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_font_size_override("font_size", 22)
	summary.text = "Choose a station."
	center_box.add_child(summary)
	
	add_shop_button(shop_content, "Leave Shop", Callable(self, "close_shop"))
	update_shop_ui()


func show_upgrade_category_view() -> void:
	clear_shop_content()
	shop_title_label.text = "Upgrades"
	
	var category_box := VBoxContainer.new()
	category_box.alignment = BoxContainer.ALIGNMENT_CENTER
	category_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	category_box.add_theme_constant_override("separation", 18)
	shop_content.add_child(category_box)
	
	for category_name in ["Miner", "Lander", "Starship", "Global"]:
		var button := add_shop_button(category_box, category_name, Callable(self, "show_upgrade_grid_view").bind(category_name))
		button.custom_minimum_size = Vector2(380.0, 62.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	add_shop_button(shop_content, "Back", Callable(self, "show_shop_main_view"))
	update_shop_ui()


func show_upgrade_grid_view(category_name: String) -> void:
	clear_shop_content()
	shop_title_label.text = "%s Upgrades" % category_name
	
	var grid_center := CenterContainer.new()
	grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_content.add_child(grid_center)
	
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 32)
	grid.add_theme_constant_override("v_separation", 24)
	grid_center.add_child(grid)
	
	var category_upgrades: Array = upgrade_definitions.get(category_name, [])
	for definition in category_upgrades:
		var upgrade_id: String = String(definition["id"])
		var level: int = int(upgrade_levels.get(upgrade_id, 0))
		var costs := get_upgrade_costs(definition, level)
		var button_text := "%s\nLvl %d/10\n%s\n%s" % [
			String(definition["name"]),
			level,
			format_upgrade_effect(definition, level),
			format_upgrade_costs(costs)
		]
		var button := add_shop_button(grid, button_text, Callable(self, "_on_upgrade_pressed").bind(category_name, upgrade_id))
		button.custom_minimum_size = Vector2(260.0, 94.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 15)
		button.disabled = level >= 10 or not can_afford_upgrade(costs)
	
	add_shop_button(shop_content, "Back to Upgrades", Callable(self, "show_upgrade_category_view"))
	update_shop_ui()


func show_market_view() -> void:
	clear_shop_content()
	shop_title_label.text = "Lander"
	
	var deposit_row := CenterContainer.new()
	deposit_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_content.add_child(deposit_row)
	
	var deposit_button := add_shop_button(deposit_row, "Deposit All", Callable(self, "_on_deposit_all_pressed"))
	deposit_button.custom_minimum_size = Vector2(320.0, 52.0)
	
	var market_columns := HBoxContainer.new()
	market_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_columns.add_theme_constant_override("separation", 14)
	shop_content.add_child(market_columns)
	
	var cargo_hold_panel := VBoxContainer.new()
	cargo_hold_panel.custom_minimum_size = Vector2(220.0, 0.0)
	cargo_hold_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cargo_hold_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cargo_hold_panel.add_theme_constant_override("separation", 8)
	market_columns.add_child(cargo_hold_panel)
	
	var cargo_hold_title := Label.new()
	cargo_hold_title.text = "Cargo Hold"
	cargo_hold_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cargo_hold_title.add_theme_font_size_override("font_size", 18)
	cargo_hold_panel.add_child(cargo_hold_title)
	
	lander_cargo_hold_list = VBoxContainer.new()
	lander_cargo_hold_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lander_cargo_hold_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lander_cargo_hold_list.add_theme_constant_override("separation", 6)
	cargo_hold_panel.add_child(lander_cargo_hold_list)
	
	var sell_column := VBoxContainer.new()
	sell_column.custom_minimum_size = Vector2(280.0, 0.0)
	sell_column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sell_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sell_column.add_theme_constant_override("separation", 10)
	market_columns.add_child(sell_column)
	
	if get_total_sellable_resource_count() > 0:
		add_shop_button(sell_column, "Sell All", Callable(self, "_on_sell_all_pressed"))
		
		for resource_name in get_sellable_resource_names():
			if get_total_resource_count(resource_name) <= 0:
				continue
			
			var button := add_shop_button(
				sell_column,
				"Sell %s" % resource_name,
				Callable(self, "sell_resource").bind(resource_name)
			)
			apply_individual_sell_button_style(button)
	else:
		var empty_sell_label := Label.new()
		empty_sell_label.text = "No resources to sell"
		empty_sell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_sell_label.add_theme_font_size_override("font_size", 16)
		sell_column.add_child(empty_sell_label)
	
	var middle_space := Control.new()
	middle_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_columns.add_child(middle_space)
	
	var process_column := VBoxContainer.new()
	process_column.custom_minimum_size = Vector2(280.0, 0.0)
	process_column.size_flags_horizontal = Control.SIZE_SHRINK_END
	process_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	process_column.add_theme_constant_override("separation", 10)
	market_columns.add_child(process_column)
	
	var process_offset := Control.new()
	process_offset.custom_minimum_size = Vector2(0.0, 56.0)
	process_column.add_child(process_offset)
	
	add_shop_button(process_column, "Process Raw Fuel", Callable(self, "process_raw_fuel_from_storage"))
	
	add_shop_button(shop_content, "Back", Callable(self, "show_shop_main_view"))
	update_shop_ui()


func initialize_upgrade_definitions() -> void:
	upgrade_definitions = {
		"Miner": [
			make_upgrade("miner_drill_efficiency", "Drill Efficiency", [{"resource": "Copper", "amount": 3}], "Drills mine 10% faster per level."),
			make_upgrade("miner_cargo_capacity", "Cargo Capacity", [{"resource": "Iron", "amount": 3}], "Miner cargo capacity increases 10% per level."),
			make_upgrade("miner_fuel_tank", "Fuel Tank", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}], "Miner fuel capacity increases 10% per level."),
			make_upgrade("miner_engine_power", "Engine Power", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}], "Vehicle speed increases 5% per level."),
			make_upgrade("miner_engine_efficiency", "Engine Efficiency", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Movement fuel use improves 10% per level."),
			make_upgrade("miner_hull_strength", "Hull Strength", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}, {"resource": "Credits", "amount": 10}], "Placeholder hull durability bonus."),
			make_upgrade("miner_sensor_strength", "Sensor Strength", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Mining reveal radius improves over time."),
		],
		"Lander": [
			make_upgrade("lander_cargo_capacity", "Cargo Capacity", [{"resource": "Iron", "amount": 2}, {"resource": "Credits", "amount": 10}], "Lander storage increases 10% per level."),
			make_upgrade("lander_fuel_storage_capacity", "Fuel Storage Capacity", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Lander fuel storage increases 10% per level."),
			make_upgrade("lander_ore_transfer_rate", "Ore Transfer Rate", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Ore transfer speed increases 10% per level."),
			make_upgrade("lander_fuel_plant_speed", "Fuel Plant Speed", [{"resource": "Copper", "amount": 2}, {"resource": "Raw Fuel", "amount": 1}, {"resource": "Credits", "amount": 10}], "Fuel processing speed increases 10% per level."),
			make_upgrade("lander_fuel_plant_efficiency", "Fuel Plant Efficiency", [{"resource": "Iron", "amount": 1}, {"resource": "Raw Fuel", "amount": 2}, {"resource": "Credits", "amount": 10}], "Fuel output improves 10% per level."),
			make_upgrade("lander_repair_station", "Repair Station", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}, {"resource": "Credits", "amount": 10}], "Repair strength improves 10% per level."),
			make_upgrade("lander_upgrade_station", "Upgrade Station", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}, {"resource": "Credits", "amount": 10}], "Upgrade station capability improves 10% per level."),
		],
		"Starship": [
			make_upgrade("starship_fuel_capacity", "Fuel Capacity", [{"resource": "Copper", "amount": 2}, {"resource": "Raw Fuel", "amount": 2}, {"resource": "Credits", "amount": 10}], "Starship fuel capacity increases 10% per level."),
			make_upgrade("starship_ltl_drive_performance", "LTL Drive Performance", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "LTL drive performance increases 10% per level."),
			make_upgrade("starship_ftl_drive_performance", "FTL Drive Performance", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}, {"resource": "Credits", "amount": 10}], "FTL drive performance increases 10% per level."),
			make_upgrade("starship_sensor_range", "Sensor Range", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Starship sensor range increases 10% per level."),
			make_upgrade("starship_hull_strength", "Hull Strength", [{"resource": "Iron", "amount": 2}, {"resource": "Gold", "amount": 1}, {"resource": "Credits", "amount": 10}], "Starship hull strength increases 10% per level."),
			make_upgrade("starship_modification", "Modification", [{"resource": "Copper", "amount": 2}, {"resource": "Iron", "amount": 2}, {"resource": "Credits", "amount": 10}], "Future module panel placeholder."),
		],
		"Global": [
			make_upgrade("global_market_rates", "Market Rates", [{"resource": "Copper", "amount": 1}, {"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Future sell-price bonus placeholder."),
			make_upgrade("global_mining_data", "Mining Data", [{"resource": "Copper", "amount": 1}, {"resource": "Credits", "amount": 10}], "Future asteroid intel placeholder."),
			make_upgrade("global_fleet_logistics", "Fleet Logistics", [{"resource": "Iron", "amount": 1}, {"resource": "Credits", "amount": 10}], "Future shared capacity placeholder."),
		],
	}


func make_upgrade(upgrade_id: String, upgrade_name: String, base_costs: Array, description: String) -> Dictionary:
	return {
		"id": upgrade_id,
		"name": upgrade_name,
		"base_costs": base_costs,
		"description": description,
	}


func get_upgrade_costs(definition: Dictionary, level: int) -> Array:
	var costs: Array = []
	for base_cost in definition["base_costs"]:
		var resource_name: String = String(base_cost["resource"])
		var base_amount: int = int(base_cost["amount"])
		var amount := base_amount + level
		if resource_name == "Credits":
			amount = base_amount * (level + 1)
		costs.append({"resource": resource_name, "amount": amount})
	return costs


func format_upgrade_effect(definition: Dictionary, level: int) -> String:
	if level >= 10:
		return "Max level reached"
	var description := String(definition["description"])
	description = description.replace(" increases ", " +")
	description = description.replace(" improves ", " +")
	description = description.replace(" per level.", " / level")
	description = description.replace("Placeholder ", "")
	description = description.replace("Future ", "")
	return description


func format_upgrade_costs(costs: Array) -> String:
	var parts: Array[String] = []
	for cost in costs:
		parts.append("%d %s" % [int(cost["amount"]), String(cost["resource"])])
	return "Cost: %s" % " + ".join(parts)


func can_afford_upgrade(costs: Array) -> bool:
	for cost in costs:
		var resource_name: String = String(cost["resource"])
		var amount: int = int(cost["amount"])
		if resource_name == "Credits":
			if credits < amount:
				return false
		elif get_total_resource_count(resource_name) < amount:
			return false
	return true


func pay_upgrade_costs(costs: Array) -> void:
	for cost in costs:
		var resource_name: String = String(cost["resource"])
		var amount: int = int(cost["amount"])
		if resource_name == "Credits":
			credits -= amount
		else:
			consume_resource(resource_name, amount)


func _on_upgrade_pressed(category_name: String, upgrade_id: String) -> void:
	var definition := get_upgrade_definition(category_name, upgrade_id)
	if definition.is_empty():
		return
	
	var level: int = int(upgrade_levels.get(upgrade_id, 0))
	if level >= 10:
		return
	
	var costs := get_upgrade_costs(definition, level)
	if not can_afford_upgrade(costs):
		update_shop_ui()
		show_upgrade_grid_view(category_name)
		return
	
	pay_upgrade_costs(costs)
	upgrade_levels[upgrade_id] = level + 1
	apply_upgrade_effect(upgrade_id, level + 1)
	show_upgrade_grid_view(category_name)
	update_hud()


func get_upgrade_definition(category_name: String, upgrade_id: String) -> Dictionary:
	var category_upgrades: Array = upgrade_definitions.get(category_name, [])
	for definition in category_upgrades:
		if String(definition["id"]) == upgrade_id:
			return definition
	return {}


func apply_upgrade_effect(upgrade_id: String, new_level: int) -> void:
	match upgrade_id:
		"miner_drill_efficiency":
			drill_damage_per_second *= 1.1
		"miner_cargo_capacity":
			inventory_capacity = ceili(float(inventory_capacity) * 1.1)
		"miner_fuel_tank":
			var old_max_fuel := max_fuel_seconds
			max_fuel_seconds *= 1.1
			fuel_seconds += max_fuel_seconds - old_max_fuel
		"miner_engine_power":
			move_speed *= 1.05
			ground_acceleration *= 1.05
			air_acceleration *= 1.05
		"miner_engine_efficiency":
			fuel_consumption_multiplier *= 0.9
		"miner_sensor_strength":
			reveal_radius_tiles = maxi(reveal_radius_tiles, 1 + ceili(float(new_level) / 2.0))
			update_revealed_cells()
		"lander_fuel_storage_capacity":
			max_lander_mining_fuel_kg = ceili(float(max_lander_mining_fuel_kg) * 1.1)
			max_lander_rocket_fuel_tons = ceili(float(max_lander_rocket_fuel_tons) * 1.1)


func get_refuel_button_text() -> String:
	var needed_kg := get_mining_fuel_kg_needed_for_full_refuel()
	if lander_mining_fuel_kg > 0:
		return "Refuel\n%d kg Mining Fuel" % mini(needed_kg, lander_mining_fuel_kg)
	return "Refuel\n%d Credits" % get_emergency_refuel_credit_cost(needed_kg)


func fill_lander_mining_fuel_from_starship() -> void:
	var lander_fuel_room: int = maxi(max_lander_mining_fuel_kg - lander_mining_fuel_kg, 0)
	var transfer_kg: int = mini(lander_fuel_room, starship_mining_fuel_kg)
	
	if transfer_kg <= 0:
		return
	
	lander_mining_fuel_kg += transfer_kg
	starship_mining_fuel_kg -= transfer_kg


func open_shop() -> void:
	is_shop_open = true
	is_paused = true
	reset_mining_progress()
	player_velocity = Vector2.ZERO
	shop_panel.visible = true
	show_shop_main_view()
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
	
	var refuel_kg := get_mining_fuel_kg_needed_for_full_refuel()
	if refuel_button != null:
		refuel_button.text = get_refuel_button_text()
		refuel_button.disabled = (
			refuel_kg <= 0
			or (lander_mining_fuel_kg <= 0 and credits < emergency_refuel_credit_cost_per_kg)
		)
	
	shop_status_label.text = (
		"Credits: %d   Cargo: %d / %d   Cargo Hold: %d items\nMining Fuel: %d / %d kg   Rocket Fuel: %d / %d tons   Starship Mining Fuel: %d / %d kg"
		% [
			credits,
			get_inventory_count(),
			inventory_capacity,
			get_cargo_hold_count(),
			lander_mining_fuel_kg,
			max_lander_mining_fuel_kg,
			lander_rocket_fuel_tons,
			max_lander_rocket_fuel_tons,
			starship_mining_fuel_kg,
			max_starship_mining_fuel_kg
		]
	)
	update_lander_cargo_hold_list()


func refresh_lander_view_or_shop_ui() -> void:
	if is_shop_open and shop_title_label != null and shop_title_label.text == "Lander":
		show_market_view()
	else:
		update_shop_ui()


func update_lander_cargo_hold_list() -> void:
	if lander_cargo_hold_list == null:
		return
	
	clear_children(lander_cargo_hold_list)
	
	var has_resources := false
	for resource_name in get_sellable_resource_names():
		var count: int = int(cargo_hold_resources.get(resource_name, 0))
		if count <= 0:
			continue
		
		has_resources = true
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 8)
		lander_cargo_hold_list.add_child(row)
		
		row.add_child(create_resource_icon(resource_name, Vector2(28.0, 28.0)))
		
		var label := Label.new()
		label.text = "%s x%d" % [resource_name, count]
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 15)
		row.add_child(label)
	
	if not has_resources:
		var empty_label := Label.new()
		empty_label.text = "Empty"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 15)
		lander_cargo_hold_list.add_child(empty_label)


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
	
	return "Copper Drill: 20 Credits + 5 Copper (+25% drill damage)"


func get_sensor_upgrade_text() -> String:
	if has_sensor_upgrade:
		return "Sensors: purchased"
	
	return "Sensors: 15 Credits + 1 Copper + 1 Iron (vision radius 2)"


func get_sellable_resource_names() -> Array[String]:
	return [
		"Copper",
		"Raw Fuel",
		"Iron",
		"Gold",
		"Treasure",
		"Diamond",
		"Warp Gems",
		"Black Hole Crystals",
	]


func sell_resource(resource_name: String) -> void:
	var count: int = get_total_resource_count(resource_name)
	
	if count <= 0:
		return
	
	credits += count * get_resource_value(resource_name)
	resources[resource_name] = 0
	cargo_hold_resources[resource_name] = 0
	refresh_lander_view_or_shop_ui()
	update_hud()


func deposit_resource(resource_name: String) -> void:
	var count: int = int(resources.get(resource_name, 0))
	
	if count <= 0:
		return
	
	cargo_hold_resources[resource_name] = int(cargo_hold_resources.get(resource_name, 0)) + count
	resources[resource_name] = 0
	refresh_lander_view_or_shop_ui()
	update_hud()


func process_raw_fuel_from_storage() -> void:
	var raw_fuel_count: int = get_total_resource_count("Raw Fuel")
	
	if raw_fuel_count <= 0:
		return
	
	var mining_fuel_room: int = maxi(max_lander_mining_fuel_kg - lander_mining_fuel_kg, 0)
	var rocket_fuel_room: int = maxi(max_lander_rocket_fuel_tons - lander_rocket_fuel_tons, 0)
	if mining_fuel_room <= 0 or rocket_fuel_room <= 0:
		refresh_lander_view_or_shop_ui()
		return
	
	var raw_fuel_limited_by_mining_tank: int = ceili(float(mining_fuel_room) / float(mining_fuel_kg_per_raw_fuel))
	var raw_fuel_limited_by_rocket_tank: int = floori(float(rocket_fuel_room) / float(rocket_fuel_tons_per_raw_fuel))
	var raw_fuel_to_process: int = mini(
		raw_fuel_count,
		mini(raw_fuel_limited_by_mining_tank, raw_fuel_limited_by_rocket_tank)
	)
	var raw_fuel_to_store: int = raw_fuel_count - raw_fuel_to_process
	
	resources["Raw Fuel"] = 0
	cargo_hold_resources["Raw Fuel"] = 0
	
	if raw_fuel_to_process > 0:
		lander_mining_fuel_kg = mini(
			max_lander_mining_fuel_kg,
			lander_mining_fuel_kg + raw_fuel_to_process * mining_fuel_kg_per_raw_fuel
		)
		lander_rocket_fuel_tons += raw_fuel_to_process * rocket_fuel_tons_per_raw_fuel
	
	if raw_fuel_to_store > 0:
		cargo_hold_resources["Raw Fuel"] = raw_fuel_to_store
	
	refresh_lander_view_or_shop_ui()
	update_hud()


func _on_deposit_all_pressed() -> void:
	for resource_name in get_sellable_resource_names():
		var count: int = int(resources.get(resource_name, 0))
		if count <= 0:
			continue
		
		cargo_hold_resources[resource_name] = int(cargo_hold_resources.get(resource_name, 0)) + count
		resources[resource_name] = 0
	
	refresh_lander_view_or_shop_ui()
	update_hud()


func _on_sell_all_pressed() -> void:
	for resource_name in get_sellable_resource_names():
		var count: int = get_total_resource_count(resource_name)
		if count > 0:
			credits += count * get_resource_value(resource_name)
			resources[resource_name] = 0
			cargo_hold_resources[resource_name] = 0
	
	refresh_lander_view_or_shop_ui()
	update_hud()


func _on_sell_copper_pressed() -> void:
	sell_resource("Copper")


func _on_sell_raw_fuel_pressed() -> void:
	sell_resource("Raw Fuel")


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
	var needed_kg := get_mining_fuel_kg_needed_for_full_refuel()
	var kg_to_use: int = mini(needed_kg, lander_mining_fuel_kg)
	
	if kg_to_use > 0:
		lander_mining_fuel_kg -= kg_to_use
	else:
		kg_to_use = mini(needed_kg, floori(float(credits) / float(emergency_refuel_credit_cost_per_kg)))
		
		if kg_to_use <= 0:
			update_shop_ui()
			return
		
		credits -= get_emergency_refuel_credit_cost(kg_to_use)
	
	fuel_seconds = minf(
		fuel_seconds + float(kg_to_use) * mining_fuel_seconds_per_kg,
		max_fuel_seconds
	)
	update_shop_ui()
	update_hud()


func get_mining_fuel_kg_needed_for_full_refuel() -> int:
	var missing_fuel: float = max_fuel_seconds - fuel_seconds
	return ceili(missing_fuel / mining_fuel_seconds_per_kg)


func get_emergency_refuel_credit_cost(fuel_kg: int) -> int:
	return fuel_kg * emergency_refuel_credit_cost_per_kg


func _on_buy_copper_drill_pressed() -> void:
	if has_copper_drill_upgrade:
		return
	
	var copper_count: int = get_total_resource_count("Copper")
	
	if credits < copper_drill_credit_cost or copper_count < copper_drill_cost:
		update_shop_ui()
		return
	
	credits -= copper_drill_credit_cost
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
		credits < sensor_upgrade_credit_cost
		or copper_count < sensor_upgrade_copper_cost
		or iron_count < sensor_upgrade_iron_cost
	):
		update_shop_ui()
		return
	
	credits -= sensor_upgrade_credit_cost
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


func create_arrival_countdown_ui() -> void:
	var countdown_layer := CanvasLayer.new()
	countdown_layer.name = "ArrivalCountdownUI"
	add_child(countdown_layer)
	
	countdown_label = Label.new()
	countdown_label.anchor_left = 0.5
	countdown_label.anchor_right = 0.5
	countdown_label.anchor_top = 0.5
	countdown_label.anchor_bottom = 0.5
	countdown_label.offset_left = -220.0
	countdown_label.offset_right = 220.0
	countdown_label.offset_top = -100.0
	countdown_label.offset_bottom = 100.0
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown_label.add_theme_font_size_override("font_size", 92)
	countdown_label.visible = false
	countdown_layer.add_child(countdown_label)


func start_arrival_countdown() -> void:
	is_arrival_countdown_active = true
	player_velocity = Vector2.ZERO
	reset_mining_progress()
	
	if countdown_label != null:
		countdown_label.visible = true
	
	for count in range(arrival_countdown_seconds, 0, -1):
		if countdown_label != null:
			countdown_label.text = str(count)
		await get_tree().create_timer(1.0).timeout
	
	if countdown_label != null:
		countdown_label.text = "GO"
	await get_tree().create_timer(0.45).timeout
	
	if countdown_label != null:
		countdown_label.visible = false
	
	is_arrival_countdown_active = false


func trigger_game_over() -> void:
	if is_game_over:
		return
	
	is_game_over = true
	is_arrival_countdown_active = false
	is_shop_open = false
	is_paused = true
	player_velocity = Vector2.ZERO
	reset_mining_progress()
	
	if shop_panel != null:
		shop_panel.visible = false
	
	if countdown_label != null:
		countdown_label.visible = false
	
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
	
	fuel_bar = Control.new()
	fuel_bar.name = "FuelBar"
	fuel_bar.anchor_left = 0.0
	fuel_bar.anchor_right = 1.0
	fuel_bar.offset_left = 82.0
	fuel_bar.offset_right = -24.0
	fuel_bar.offset_top = 12.0
	fuel_bar.offset_bottom = 34.0
	fuel_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(fuel_bar)
	
	var fuel_bar_background := ColorRect.new()
	fuel_bar_background.name = "FuelBarBackground"
	fuel_bar_background.color = Color(0.02, 0.05, 0.06, 0.82)
	fuel_bar_background.anchor_right = 1.0
	fuel_bar_background.anchor_bottom = 1.0
	fuel_bar.add_child(fuel_bar_background)
	
	fuel_bar_fill = ColorRect.new()
	fuel_bar_fill.name = "FuelBarFill"
	fuel_bar_fill.color = Color(0.0, 0.75, 0.86, 0.95)
	fuel_bar_fill.offset_left = 2.0
	fuel_bar_fill.offset_top = 2.0
	fuel_bar_fill.offset_bottom = -2.0
	fuel_bar.add_child(fuel_bar_fill)
	rebuild_fuel_bar_segments()
	
	hud_label = Label.new()
	hud_label.position = Vector2(24, 52)
	hud_label.add_theme_font_size_override("font_size", 24)
	hud_layer.add_child(hud_label)
	
	hud_cargo_icons = VBoxContainer.new()
	hud_cargo_icons.position = Vector2(24.0, 122.0)
	hud_cargo_icons.add_theme_constant_override("separation", 6)
	hud_layer.add_child(hud_cargo_icons)
	
	create_gauge_cluster(hud_layer)


func create_gauge_cluster(hud_layer: CanvasLayer) -> void:
	gauge_cluster = Control.new()
	gauge_cluster.name = "GaugeCluster"
	gauge_cluster.anchor_left = 0.5
	gauge_cluster.anchor_right = 0.5
	gauge_cluster.anchor_top = 1.0
	gauge_cluster.anchor_bottom = 1.0
	gauge_cluster.offset_left = -GAUGE_CLUSTER_SIZE.x * 0.5
	gauge_cluster.offset_right = GAUGE_CLUSTER_SIZE.x * 0.5
	gauge_cluster.offset_top = -GAUGE_CLUSTER_SIZE.y - 14.0
	gauge_cluster.offset_bottom = -14.0
	gauge_cluster.size = GAUGE_CLUSTER_SIZE
	gauge_cluster.custom_minimum_size = GAUGE_CLUSTER_SIZE
	gauge_cluster.clip_contents = true
	gauge_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(gauge_cluster)
	
	var gauge_background := TextureRect.new()
	gauge_background.name = "GaugeClusterBackground"
	gauge_background.texture = GaugeClusterTexture
	gauge_background.anchor_right = 1.0
	gauge_background.anchor_bottom = 1.0
	gauge_background.offset_left = 0.0
	gauge_background.offset_right = 0.0
	gauge_background.offset_top = 0.0
	gauge_background.offset_bottom = 0.0
	gauge_background.custom_minimum_size = Vector2.ZERO
	gauge_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gauge_background.stretch_mode = TextureRect.STRETCH_SCALE
	gauge_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gauge_cluster.add_child(gauge_background)
	gauge_background.size = GAUGE_CLUSTER_SIZE
	
	gauge_fuel_needle = create_gauge_needle(Color(0.0, 0.9, 1.0, 0.92), Vector2(96.0, 166.0))
	gauge_cluster.add_child(gauge_fuel_needle)
	
	gauge_heat_needle = create_gauge_needle(Color(1.0, 0.22, 0.02, 0.92), Vector2(464.0, 166.0))
	gauge_cluster.add_child(gauge_heat_needle)
	
	gauge_depth_label = Label.new()
	gauge_depth_label.name = "DepthReadout"
	gauge_depth_label.position = Vector2(276.0, 153.0)
	gauge_depth_label.size = Vector2(86.0, 42.0)
	gauge_depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gauge_depth_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gauge_depth_label.add_theme_font_size_override("font_size", 30)
	gauge_depth_label.add_theme_color_override("font_color", Color(1.0, 0.46, 0.06, 1.0))
	gauge_depth_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	gauge_depth_label.add_theme_constant_override("shadow_offset_x", 2)
	gauge_depth_label.add_theme_constant_override("shadow_offset_y", 2)
	gauge_cluster.add_child(gauge_depth_label)


func create_gauge_needle(color: Color, gauge_center: Vector2) -> ColorRect:
	var needle := ColorRect.new()
	needle.color = color
	needle.position = gauge_center - Vector2(12.0, 3.0)
	needle.size = Vector2(100.0, 6.0)
	needle.pivot_offset = Vector2(12.0, 3.0)
	needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return needle


func rebuild_fuel_bar_segments() -> void:
	for segment in fuel_bar_segments:
		if segment != null:
			segment.queue_free()
	
	fuel_bar_segments.clear()
	
	if fuel_bar == null:
		return
	
	var segment_count: int = maxi(ceili(max_fuel_seconds / 10.0), 1)
	
	for i in range(1, segment_count):
		var segment := ColorRect.new()
		segment.name = "FuelSegment%d" % i
		segment.color = Color(0.78, 1.0, 1.0, 0.72)
		segment.size = Vector2(2.0, 18.0)
		fuel_bar.add_child(segment)
		fuel_bar_segments.append(segment)


func update_fuel_bar(delta: float = 0.0) -> void:
	if fuel_bar == null or fuel_bar_fill == null:
		return
	
	var segment_count: int = maxi(ceili(max_fuel_seconds / 10.0), 1)
	if fuel_bar_segments.size() != segment_count - 1:
		rebuild_fuel_bar_segments()
	
	var fuel_ratio: float = clampf(fuel_seconds / maxf(max_fuel_seconds, 0.01), 0.0, 1.0)
	var inner_width: float = maxf(fuel_bar.size.x - 4.0, 0.0)
	fuel_bar_fill.size = Vector2(inner_width * fuel_ratio, maxf(fuel_bar.size.y - 4.0, 0.0))
	
	var fill_color := Color(0.0, 0.75, 0.86, 0.95)
	
	if fuel_ratio <= fuel_warning_ratio:
		fuel_warning_blink_time += delta
		var warning_alpha: float = 0.45 + 0.5 * absf(sin(fuel_warning_blink_time * 7.5))
		fill_color = Color(1.0, 0.05, 0.03, warning_alpha)
	else:
		fuel_warning_blink_time = 0.0
	
	fuel_bar_fill.color = fill_color
	
	for i in fuel_bar_segments.size():
		var segment := fuel_bar_segments[i]
		var x_position: float = ((float(i) + 1.0) / float(segment_count)) * fuel_bar.size.x
		segment.position = Vector2(x_position - 1.0, 2.0)
		segment.size = Vector2(2.0, maxf(fuel_bar.size.y - 4.0, 0.0))


func update_hud() -> void:
	if hud_label == null:
		return
	
	update_fuel_bar()
	update_hud_cargo_icons()
	update_gauge_cluster()
	
	hud_label.text = "Credits: %d\nCargo: %d / %d" % [
		credits,
		get_inventory_count(),
		inventory_capacity
	]


func update_hud_cargo_icons() -> void:
	if hud_cargo_icons == null:
		return
	
	clear_children(hud_cargo_icons)
	
	for resource_name in get_sellable_resource_names():
		var count: int = int(resources.get(resource_name, 0))
		if count <= 0:
			continue
		
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 4)
		hud_cargo_icons.add_child(item)
		
		item.add_child(create_resource_icon(resource_name, Vector2(30.0, 30.0)))
		
		var count_label := Label.new()
		count_label.text = "x%d" % count
		count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 16)
		item.add_child(count_label)


func update_gauge_cluster() -> void:
	if gauge_cluster == null:
		return
	
	var fuel_ratio: float = clampf(fuel_seconds / maxf(max_fuel_seconds, 0.01), 0.0, 1.0)
	if gauge_fuel_needle != null:
		gauge_fuel_needle.rotation = lerpf(deg_to_rad(-202.0), deg_to_rad(-42.0), fuel_ratio)
	
	if gauge_heat_needle != null:
		gauge_heat_needle.rotation = lerpf(deg_to_rad(158.0), deg_to_rad(-25.0), clampf(heat_ratio, 0.0, 1.0))
	
	if gauge_depth_label != null:
		gauge_depth_label.text = "%04d" % get_current_depth_meters()


func get_current_depth_meters() -> int:
	var player_cell := get_player_cell()
	return maxi(player_cell.y - get_first_ground_row(), 0) * depth_meters_per_row


func _draw() -> void:
	var target_cell := get_target_mine_cell()
	var target_position := mine_tiles.map_to_local(target_cell)
	var tile_size := Vector2(64.0, 64.0)
	var target_rect := Rect2(target_position - tile_size * 0.5, tile_size)
	draw_rect(target_rect, Color(1.0, 0.9, 0.2, 0.85), false, 3.0)


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over or is_arrival_countdown_active:
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
