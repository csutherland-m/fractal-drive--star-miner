extends Node2D

var mining_scene


func _draw() -> void:
	if mining_scene == null:
		return
	
	var camera: Camera2D = get_viewport().get_camera_2d()
	
	if camera == null:
		return
	
	var mine_tiles: TileMapLayer = mining_scene.mine_tiles
	var viewport_size: Vector2 = get_viewport_rect().size / camera.zoom
	var camera_center: Vector2 = camera.get_screen_center_position()
	var top_left: Vector2 = camera_center - viewport_size * 0.5
	var bottom_right: Vector2 = camera_center + viewport_size * 0.5
	var min_cell: Vector2i = mine_tiles.local_to_map(top_left) - Vector2i(2, 2)
	var max_cell: Vector2i = mine_tiles.local_to_map(bottom_right) + Vector2i(2, 2)
	var tile_size := Vector2(64.0, 64.0)
	var first_tile_center: Vector2 = mine_tiles.map_to_local(Vector2i(0, 0))
	var last_tile_center: Vector2 = mine_tiles.map_to_local(Vector2i(mining_scene.grid_width - 1, 0))
	var left_world_edge: float = first_tile_center.x - tile_size.x * 0.5
	var right_world_edge: float = last_tile_center.x + tile_size.x * 0.5
	var side_padding: float = mining_scene.side_fog_padding_pixels
	var first_row: int = maxi(mining_scene.get_first_ground_row(), min_cell.y)
	var last_row: int = mini(max_cell.y, mining_scene.generated_row_count - 1)
	var first_column: int = maxi(0, min_cell.x)
	var last_column: int = mini(mining_scene.grid_width - 1, max_cell.x)
	
	draw_rect(
		Rect2(
			Vector2(left_world_edge - side_padding, top_left.y),
			Vector2(side_padding, bottom_right.y - top_left.y)
		),
		Color.BLACK,
		true
	)
	draw_rect(
		Rect2(
			Vector2(right_world_edge, top_left.y),
			Vector2(side_padding, bottom_right.y - top_left.y)
		),
		Color.BLACK,
		true
	)
	
	for y in range(first_row, last_row + 1):
		for x in range(first_column, last_column + 1):
			var cell := Vector2i(x, y)
			
			if mining_scene.is_cell_revealed(cell):
				continue
			
			var cell_position: Vector2 = mine_tiles.map_to_local(cell)
			var fog_rect := Rect2(cell_position - tile_size * 0.5, tile_size)
			draw_rect(fog_rect, Color.BLACK, true)
