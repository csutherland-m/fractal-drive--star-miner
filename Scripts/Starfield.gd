extends Node2D

@export var star_count: int = 350
@export var cluster_count: int = 8
@export var cluster_spread: float = 120.0
@export var random_star_ratio: float = 0.35

@export var min_star_size: float = 1.0
@export var max_star_size: float = 2.5

@export var blink_speed_min: float = 0.5
@export var blink_speed_max: float = 2.5
@export var blink_strength: float = 0.35

@export var star_drift_speed: Vector2 = Vector2(-5, 0)
@export var redraws_per_second: float = 30.0

@export var edge_respawn_margin: float = 20.0



var stars: Array = []
var cluster_centers: Array[Vector2] = []
var time_passed: float = 0.0
var redraw_timer: float = 0.0


func _ready() -> void:
	randomize()
	generate_starfield()


func _process(delta: float) -> void:
	time_passed += delta
	
	for star in stars:
		star.position += star_drift_speed * star.depth * delta
		wrap_star(star)
	
	redraw_timer += delta
	if redraws_per_second <= 0.0:
		return
	
	var redraw_interval := 1.0 / redraws_per_second
	if redraw_timer >= redraw_interval:
		redraw_timer = 0.0
		queue_redraw()


func generate_starfield() -> void:
	stars.clear()
	cluster_centers.clear()
	
	var screen_size := get_viewport_rect().size
	var safe_min_star_size := maxf(0.25, min_star_size)
	var safe_max_star_size := clampf(max_star_size, safe_min_star_size, 3.0)
	
	for i in cluster_count:
		cluster_centers.append(Vector2(
			randf_range(0, screen_size.x),
			randf_range(0, screen_size.y)
		))
	
	for i in star_count:
		var use_random_position := randf() < random_star_ratio
		
		var star_position: Vector2
		
		if use_random_position or cluster_centers.is_empty():
			star_position = Vector2(
				randf_range(0, screen_size.x),
				randf_range(0, screen_size.y)
			)
		else:
			var center: Vector2 = cluster_centers.pick_random()
			star_position = center + Vector2(
				randf_range(-cluster_spread, cluster_spread),
				randf_range(-cluster_spread, cluster_spread)
			)
		
		var color_choice := randf()
		var star_color: Color
		
		if color_choice < 0.70:
			star_color = Color(1.0, 1.0, 1.0)
		elif color_choice < 0.85:
			star_color = Color(0.75, 0.85, 1.0) # blue-white
		elif color_choice < 0.95:
			star_color = Color(1.0, 0.9, 0.65) # warm yellow-white
		else:
			star_color = Color(1.0, 0.65, 0.55) # faint red-orange
		
		var depth := randf_range(0.3, 0.5)
		
		var star = {
			"position": star_position,
			"size": clampf(randf_range(safe_min_star_size, safe_max_star_size) * depth, 0.35, 2.5),
			"depth": depth,
			"base_color": star_color,
			"base_brightness": randf_range(0.45, 1.0),
			"blink_speed": randf_range(blink_speed_min, blink_speed_max),
			"blink_offset": randf_range(0.0, TAU)

		}
		
		stars.append(star)


func wrap_star(star: Dictionary) -> void:
	var screen_size := get_viewport_rect().size
	var margin: float = 20.0
	
	if star.position.x < -margin:
		star.position.x = screen_size.x + margin
		star.position.y = randf_range(0, screen_size.y)
	
	elif star.position.x > screen_size.x + margin:
		star.position.x = -margin
		star.position.y = randf_range(0, screen_size.y)
	
	if star.position.y < -margin:
		star.position.y = screen_size.y + margin
		star.position.x = randf_range(0, screen_size.x)
	
	elif star.position.y > screen_size.y + margin:
		star.position.y = -margin
		star.position.x = randf_range(0, screen_size.x)


func _draw() -> void:
	draw_rect(get_viewport_rect(), Color.BLACK, true)
	
	for star in stars:
		var blink := sin(time_passed * star.blink_speed + star.blink_offset)
		var brightness = star.base_brightness + blink * blink_strength
		brightness = clamp(brightness, 0.1, 1.0)
		
		var final_color: Color = star.base_color * brightness
		final_color.a = brightness
		
		draw_circle(star.position, minf(star.size, 2.5), final_color)
