extends Node2D

var mining_scene
var animation_time: float = 0.0


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func _draw() -> void:
	if mining_scene == null:
		return
	var cells: Array[Vector2i] = mining_scene.get_detectable_hidden_ore_cells()
	for cell in cells:
		draw_twinkle(cell)


func draw_twinkle(cell: Vector2i) -> void:
	var center: Vector2 = mining_scene.mine_tiles.map_to_local(cell)
	var cell_phase := float(abs(cell.x * 73 + cell.y * 151) % 997) * 0.017
	for particle_index in 7:
		var phase := animation_time * (0.65 + float(particle_index) * 0.035) + cell_phase + float(particle_index) * 1.31
		var x_offset := sin(phase * 1.17) * (10.0 + float((particle_index * 7) % 15))
		var y_offset := cos(phase * 0.83) * (9.0 + float((particle_index * 11) % 16))
		var soft_pulse := 0.32 + 0.18 * (0.5 + 0.5 * sin(phase * 0.71))
		var radius := 1.2 + float(particle_index % 3) * 0.55
		draw_circle(center + Vector2(x_offset, y_offset), radius, Color(0.92, 0.88, 0.66, soft_pulse))
