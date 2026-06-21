extends Node2D

@export var small_debris_count: int = 15
@export var large_asteroid_count: int = 5

@export var spawn_padding: float = 120.0
@export var small_min_radius: float = 6.0
@export var small_max_radius: float = 14.0
@export var large_min_radius: float = 180.0
@export var large_max_radius: float = 300.0

@export var debris_min_speed: float = 10.0
@export var debris_max_speed: float = 35.0
@export var asteroid_scroll_multiplier: float = 1.0

@export var spawn_interval: float = 0.5
@export var max_small_debris: int = 8
@export var max_large_asteroids: int = 1

@export var large_asteroid_spawn_chance: float = 1.0
@export var offscreen_spawn_margin: float = 120.0

var spawn_timer: float = 0.0

var space_scroll_speed: Vector2 = Vector2.ZERO

var debris_script := preload("res://Scripts/SpaceDebris.gd")

func _process(delta: float) -> void:
	for child in get_children():
		child.space_scroll_speed = space_scroll_speed * asteroid_scroll_multiplier
	
	if space_scroll_speed.length() <= 1.0:
		return
	
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_asteroid_while_flying()


func spawn_asteroid_while_flying() -> void:
	var small_count := get_active_count(false)
	var large_count := get_active_count(true)
	
	if large_count < max_large_asteroids and randf() < large_asteroid_spawn_chance:
		spawn_large_asteroid()
		return
	
	if small_count < max_small_debris:
		spawn_small_debris()

func get_active_count(mineable: bool) -> int:
	var count := 0
	
	for child in get_children():
		if child.is_mineable == mineable:
			count += 1
	
	return count


func _ready() -> void:
	randomize()


func spawn_field() -> void:
	for i in small_debris_count:
		spawn_small_debris()
	
	for i in large_asteroid_count:
		spawn_large_asteroid()


func spawn_small_debris() -> void:
	var debris := Area2D.new()
	debris.set_script(debris_script)
	
	debris.radius = randf_range(small_min_radius, small_max_radius)
	debris.damage = randi_range(5, 15)
	debris.is_mineable = false
	debris.color = Color("#6A6A6A")
	debris.position = get_random_screen_position(debris.radius)
	debris.drift_velocity = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(debris_min_speed, debris_max_speed)
	debris.spin_speed = randf_range(-0.1, 0.1)
	
	add_child(debris)


func spawn_large_asteroid() -> void:
	var asteroid := Area2D.new()
	asteroid.set_script(debris_script)
	
	asteroid.radius = randf_range(large_min_radius, large_max_radius)
	asteroid.damage = 0
	asteroid.is_mineable = true
	asteroid.color = Color("#8A6F52")
	asteroid.position = get_random_screen_position(asteroid.radius)
	asteroid.drift_velocity = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(1.0, 1.1)
	asteroid.spin_speed = randf_range(-0.1, 0.1)
	
	add_child(asteroid)


func get_random_screen_position(spawn_radius: float) -> Vector2:
	var screen_size := get_viewport_rect().size
	var direction := space_scroll_speed.normalized()
	var edge_clearance := offscreen_spawn_margin + spawn_radius
	
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	
	var spawn_position := Vector2.ZERO
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			spawn_position.x = -edge_clearance
		else:
			spawn_position.x = screen_size.x + edge_clearance
		
		spawn_position.y = randf_range(0, screen_size.y)
	else:
		if direction.y > 0:
			spawn_position.y = -edge_clearance
		else:
			spawn_position.y = screen_size.y + edge_clearance
		
		spawn_position.x = randf_range(0, screen_size.x)
	
	return spawn_position
