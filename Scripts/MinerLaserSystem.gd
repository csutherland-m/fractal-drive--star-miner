class_name MinerLaserSystem
extends Node2D


class LaserBolt extends Node2D:
	var velocity: Vector2 = Vector2.ZERO
	var damage: float = 1.0

	func _draw() -> void:
		draw_line(Vector2(-16.0, 0.0), Vector2(10.0, 0.0), Color(0.08, 0.9, 1.0, 0.22), 10.0)
		draw_line(Vector2(-16.0, 0.0), Vector2(10.0, 0.0), Color(0.25, 1.0, 1.0, 0.9), 4.0)
		draw_circle(Vector2(10.0, 0.0), 3.0, Color.WHITE)


@export var projectile_speed: float = 1400.0
@export var collision_step_pixels: float = 10.0

var mining_scene: Node
var bolts: Array[LaserBolt] = []


func setup(scene: Node) -> void:
	mining_scene = scene
	name = "MinerLaserSystem"
	z_index = 9


func fire(start_position: Vector2, target_position: Vector2, damage: float = 1.0) -> bool:
	var direction := start_position.direction_to(target_position)
	if direction.is_zero_approx():
		return false
	var bolt := LaserBolt.new()
	bolt.position = start_position
	bolt.rotation = direction.angle()
	bolt.velocity = direction * projectile_speed
	bolt.damage = maxf(damage, 0.0)
	add_child(bolt)
	bolts.append(bolt)
	return true


func process_projectiles(delta: float) -> void:
	for index in range(bolts.size() - 1, -1, -1):
		var bolt := bolts[index]
		if not is_instance_valid(bolt):
			bolts.remove_at(index)
			continue
		var motion := bolt.velocity * delta
		var step_count := maxi(ceili(motion.length() / maxf(collision_step_pixels, 1.0)), 1)
		var step := motion / float(step_count)
		var should_remove := false
		for _step_index in step_count:
			var next_position := bolt.position + step
			if not mining_scene.is_position_inside_mining_bounds(next_position):
				should_remove = true
				break
			if (
				mining_scene.ground_encounter_system != null
				and mining_scene.ground_encounter_system.damage_enemy_at_position(next_position, bolt.damage)
			):
				should_remove = true
				break
			if mining_scene.is_solid_at_position(next_position):
				should_remove = true
				break
			bolt.position = next_position
		if should_remove:
			remove_bolt_at(index)


func remove_bolt_at(index: int) -> void:
	var bolt := bolts[index]
	bolts.remove_at(index)
	if is_instance_valid(bolt):
		bolt.queue_free()


func clear_projectiles() -> void:
	for bolt in bolts:
		if is_instance_valid(bolt):
			bolt.queue_free()
	bolts.clear()
