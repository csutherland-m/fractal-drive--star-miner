class_name DeveloperCaveDirectionArrow
extends Node2D

var mining_scene: Node
var arrow_enabled: bool = false


func setup(scene: Node) -> void:
	mining_scene = scene
	name = "DeveloperCaveDirectionArrow"
	z_index = 13
	visible = false


func set_arrow_enabled(enabled: bool) -> void:
	arrow_enabled = enabled
	visible = enabled
	queue_redraw()


func update_arrow() -> void:
	if not arrow_enabled or mining_scene == null or mining_scene.player_marker == null:
		visible = false
		return
	var encounter: Dictionary = mining_scene.get_nearest_ground_cave_to_cell(
		mining_scene.get_player_cell()
	)
	if encounter.is_empty():
		visible = false
		return
	var center_data: Array = encounter.get("cave_center_cell", [])
	if center_data.size() < 2:
		visible = false
		return
	var target_position: Vector2 = mining_scene.mine_tiles.map_to_local(
		Vector2i(int(center_data[0]), int(center_data[1]))
	)
	var direction: Vector2 = mining_scene.player_marker.position.direction_to(target_position)
	if direction.is_zero_approx():
		visible = false
		return
	visible = true
	position = mining_scene.player_marker.position + Vector2(0.0, -82.0)
	rotation = direction.angle()
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(-18.0, 0.0), Vector2(25.0, 0.0), Color(0.05, 0.02, 0.0, 0.8), 12.0)
	draw_line(Vector2(-18.0, 0.0), Vector2(25.0, 0.0), Color(1.0, 0.76, 0.08, 1.0), 6.0)
	draw_colored_polygon(
		PackedVector2Array([Vector2(38.0, 0.0), Vector2(19.0, -14.0), Vector2(19.0, 14.0)]),
		Color(1.0, 0.48, 0.02, 1.0)
	)
