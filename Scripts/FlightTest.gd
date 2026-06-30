extends Node2D

@onready var player_ship: Area2D = $PlayerShip
@onready var ship_sprite: Sprite2D = $PlayerShip/ShipSprite
@onready var starfield: Node2D = $Starfield
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var asteroid_spawner: Node2D = $AsteroidSpawner

@export var max_speed: float = 160.0
@export var acceleration_rate: float = 60.0
@export var strafe_acceleration_rate: float = 45.0
@export var deceleration_rate: float = 35.0
@export var rotation_speed: float = 8.0
@export var starship_side_texture_path: String = "res://Sprites/Vehicles/StarShipSideEdited.png"
@export var lander_texture_path: String = "res://Sprites/Vehicles/RocketLanderEdited.png"
@export var engine_flame_length: float = 62.0
@export var engine_flame_width: float = 34.0
@export var asteroid_approach_scene_path: String = "res://Scenes/AsteroidMining.tscn"
@export var orbit_clearance: float = 170.0
@export var orbit_arc_radians: float = 0.65
@export var orbit_duration: float = 1.85
@export var cutscene_rotation_blend: float = 0.08
@export var lander_launch_scale: float = 0.18
@export var solar_system_scroll_multiplier: float = 0.35
@export var zoomed_out_ship_scale: float = 0.22

var ship_velocity: Vector2 = Vector2.ZERO
var is_paused: bool = false
var starship_side_texture: Texture2D
var lander_texture: Texture2D
var engine_flame: Polygon2D
var inner_engine_flame: Polygon2D
var flame_time: float = 0.0
var is_ship_sprite_mirrored: bool = false
var is_landing_sequence_active: bool = false
var cutscene_asteroid_position: Vector2 = Vector2.ZERO
var cutscene_orbit_radius: float = 0.0
var cutscene_orbit_start: Vector2 = Vector2.ZERO
var solar_system_layer: Node2D
var solar_system_scroll_offset: Vector2 = Vector2.ZERO
var asteroid_belt_points: Array[Vector2] = []

func _ready() -> void:
	pause_menu.resume_requested.connect(_on_resume_pressed)
	pause_menu.quit_requested.connect(_on_quit_pressed)
	starship_side_texture = load(starship_side_texture_path) as Texture2D
	lander_texture = load(lander_texture_path) as Texture2D
	ship_sprite.texture = starship_side_texture
	player_ship.scale = Vector2(zoomed_out_ship_scale, zoomed_out_ship_scale)
	create_solar_system_layer()
	create_engine_flame()
	update_ship_visual(Vector2.RIGHT, 1.0)

func _process(delta: float) -> void:
	if is_paused or is_landing_sequence_active:
		return
	
	var input_direction := get_input_direction()
	var strafe_input := get_strafe_input()
	
	if input_direction != Vector2.ZERO:
		accelerate_ship(input_direction, delta)
	
	if strafe_input != 0.0:
		strafe_ship(strafe_input, delta)
	
	if input_direction == Vector2.ZERO and strafe_input == 0.0:
		decelerate_ship(delta)
	else:
		ship_velocity = ship_velocity.limit_length(max_speed)
	
	if ship_velocity.length() > 1.0:
		update_ship_visual(ship_velocity.normalized(), delta)
	
	update_engine_flame(input_direction != Vector2.ZERO or strafe_input != 0.0, delta)
	update_solar_system_layer(delta)
	starfield.star_drift_speed = -ship_velocity
	asteroid_spawner.space_scroll_speed = -ship_velocity


func create_solar_system_layer() -> void:
	solar_system_layer = Node2D.new()
	solar_system_layer.name = "SolarSystemLayer"
	solar_system_layer.z_index = -80
	solar_system_layer.draw.connect(_on_solar_system_layer_draw)
	add_child(solar_system_layer)
	
	asteroid_belt_points.clear()
	for i in 180:
		var angle := (float(i) / 180.0) * TAU + randf_range(-0.018, 0.018)
		var radius := randf_range(660.0, 780.0)
		asteroid_belt_points.append(Vector2(cos(angle), sin(angle)) * radius)


func update_solar_system_layer(delta: float) -> void:
	if solar_system_layer == null:
		return
	
	solar_system_scroll_offset -= ship_velocity * delta * solar_system_scroll_multiplier
	solar_system_layer.queue_redraw()


func _on_solar_system_layer_draw() -> void:
	if solar_system_layer == null:
		return
	
	var screen_center := get_viewport_rect().size * 0.5
	var system_center := screen_center + solar_system_scroll_offset
	
	draw_orbit(system_center, 210.0)
	draw_orbit(system_center, 360.0)
	draw_orbit(system_center, 520.0)
	draw_orbit(system_center, 1020.0)
	draw_asteroid_belt(system_center)
	
	solar_system_layer.draw_circle(system_center, 56.0, Color("#FFD76A"))
	solar_system_layer.draw_circle(system_center, 34.0, Color("#FFF1A3"))
	draw_planet(system_center + Vector2(210.0, -18.0), 18.0, Color("#4FB2FF"), Color("#1E5F9B"))
	draw_planet(system_center + Vector2(-110.0, 342.0), 26.0, Color("#C46B38"), Color("#6F321F"))
	draw_planet(system_center + Vector2(-492.0, -168.0), 34.0, Color("#6FD08C"), Color("#275D43"))
	draw_gas_giant(system_center + Vector2(750.0, 690.0))


func draw_orbit(center: Vector2, radius: float) -> void:
	solar_system_layer.draw_arc(center, radius, 0.0, TAU, 160, Color(0.3, 0.45, 0.58, 0.22), 1.5)


func draw_planet(position: Vector2, radius: float, color: Color, shadow_color: Color) -> void:
	solar_system_layer.draw_circle(position, radius, color)
	solar_system_layer.draw_circle(position + Vector2(radius * 0.28, radius * 0.18), radius * 0.68, color_with_alpha(shadow_color, 0.5))


func color_with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


func draw_gas_giant(position: Vector2) -> void:
	var radius := 72.0
	solar_system_layer.draw_circle(position, radius, Color("#D8B06C"))
	solar_system_layer.draw_rect(Rect2(position + Vector2(-radius, -30.0), Vector2(radius * 2.0, 12.0)), Color("#A86F46"))
	solar_system_layer.draw_rect(Rect2(position + Vector2(-radius, -5.0), Vector2(radius * 2.0, 10.0)), Color("#F0D59A"))
	solar_system_layer.draw_rect(Rect2(position + Vector2(-radius, 22.0), Vector2(radius * 2.0, 14.0)), Color("#9F6440"))
	solar_system_layer.draw_arc(position, radius * 1.45, -0.2, PI + 0.2, 120, Color(0.82, 0.76, 0.62, 0.55), 4.0)


func draw_asteroid_belt(center: Vector2) -> void:
	for point in asteroid_belt_points:
		var asteroid_position := center + point
		var size := 1.5 + fmod(absf(point.x + point.y), 3.0)
		solar_system_layer.draw_circle(asteroid_position, size, Color("#7A716A"))


func begin_mining_approach(asteroid: Area2D) -> void:
	if is_landing_sequence_active:
		return
	
	is_landing_sequence_active = true
	ship_velocity = Vector2.ZERO
	starfield.star_drift_speed = Vector2.ZERO
	asteroid_spawner.space_scroll_speed = Vector2.ZERO
	asteroid_spawner.set_process(false)
	asteroid.set_process(false)
	update_engine_flame(false, 0.0)
	
	await play_mining_approach_cutscene(asteroid)
	get_tree().change_scene_to_file(asteroid_approach_scene_path)


func play_mining_approach_cutscene(asteroid: Area2D) -> void:
	var asteroid_position := asteroid.global_position
	var start_angle := (player_ship.global_position - asteroid_position).angle()
	var orbit_radius: float = maxf(float(asteroid.get("radius")) + orbit_clearance, orbit_clearance)
	var orbit_start := asteroid_position + Vector2.RIGHT.rotated(start_angle) * orbit_radius
	cutscene_asteroid_position = asteroid_position
	cutscene_orbit_radius = orbit_radius
	cutscene_orbit_start = orbit_start

	var approach_tween := create_tween()
	approach_tween.set_parallel(true)
	approach_tween.tween_property(player_ship, "global_position", orbit_start, 0.75).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	approach_tween.tween_method(Callable(self, "update_cutscene_approach_visual"), 0.0, 1.0, 0.75)
	await approach_tween.finished
	
	var orbit_end_angle := start_angle + orbit_arc_radians
	var orbit_tween := create_tween()
	orbit_tween.tween_method(Callable(self, "update_cutscene_orbit_position"), start_angle, orbit_end_angle, orbit_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await orbit_tween.finished
	await launch_lander_to_asteroid(asteroid)


func update_cutscene_approach_visual(_progress: float) -> void:
	var direction := (cutscene_orbit_start - player_ship.global_position).normalized()
	
	if direction != Vector2.ZERO:
		update_cutscene_ship_visual(direction)


func update_cutscene_orbit_position(angle: float) -> void:
	var previous_position := player_ship.global_position
	player_ship.global_position = cutscene_asteroid_position + Vector2.RIGHT.rotated(angle) * cutscene_orbit_radius
	var travel_direction := player_ship.global_position - previous_position
	
	if travel_direction.length() > 0.1:
		update_cutscene_ship_visual(travel_direction.normalized())


func update_cutscene_ship_visual(direction: Vector2) -> void:
	ship_sprite.texture = starship_side_texture
	var should_mirror := direction.x < 0.0
	var target_angle := get_upright_travel_angle(direction)
	
	if should_mirror != is_ship_sprite_mirrored:
		is_ship_sprite_mirrored = should_mirror
		ship_sprite.flip_h = should_mirror
		player_ship.rotation = target_angle
		return
	
	ship_sprite.flip_h = should_mirror
	player_ship.rotation = lerp_angle(player_ship.rotation, target_angle, cutscene_rotation_blend)


func launch_lander_to_asteroid(asteroid: Area2D) -> void:
	var lander := Sprite2D.new()
	lander.name = "CutsceneLander"
	lander.texture = lander_texture
	lander.global_position = player_ship.global_position
	lander.scale = Vector2(lander_launch_scale, lander_launch_scale)
	lander.z_index = 30
	add_child(lander)
	
	var target_position := asteroid.global_position
	var lander_tween := create_tween()
	lander_tween.set_parallel(true)
	lander_tween.tween_property(lander, "global_position", target_position, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	lander_tween.tween_property(lander, "scale", Vector2(0.03, 0.03), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	lander_tween.tween_property(lander, "modulate:a", 0.0, 0.25).set_delay(0.65)
	await lander_tween.finished
	lander.queue_free()
	
func get_input_direction() -> Vector2:
	var direction := Vector2.ZERO
	
	if Input.is_key_pressed(KEY_W):
		direction.y -= 1
	
	if Input.is_key_pressed(KEY_S):
		direction.y += 1
	
	if Input.is_key_pressed(KEY_A):
		direction.x -= 1
	
	if Input.is_key_pressed(KEY_D):
		direction.x += 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()
	
	return direction


func get_strafe_input() -> float:
	var input := 0.0
	
	if Input.is_key_pressed(KEY_Q):
		input -= 1.0
	
	if Input.is_key_pressed(KEY_E):
		input += 1.0
	
	return input
	
func accelerate_ship(direction: Vector2, delta: float) -> void:
	ship_velocity += direction * acceleration_rate * delta
	ship_velocity = ship_velocity.limit_length(max_speed)


func strafe_ship(input: float, delta: float) -> void:
	var strafe_direction := Vector2.RIGHT.rotated(player_ship.rotation + (PI * 0.5))
	ship_velocity += strafe_direction * input * strafe_acceleration_rate * delta
	
func decelerate_ship(delta: float) -> void:
	if ship_velocity.length() > 0:
		var slowdown_amount := deceleration_rate * delta
		ship_velocity = ship_velocity.move_toward(Vector2.ZERO, slowdown_amount)


func update_ship_visual(direction: Vector2, delta: float) -> void:
	ship_sprite.texture = starship_side_texture
	var should_mirror := direction.x < 0.0
	var target_angle := get_upright_travel_angle(direction)
	
	if should_mirror != is_ship_sprite_mirrored:
		is_ship_sprite_mirrored = should_mirror
		ship_sprite.flip_h = should_mirror
		player_ship.rotation = target_angle
		return
	
	ship_sprite.flip_h = should_mirror
	rotate_ship_toward(target_angle, delta)


func get_upright_travel_angle(direction: Vector2) -> float:
	if direction.x < 0.0:
		return direction.angle() - PI
	
	return direction.angle()


func create_engine_flame() -> void:
	engine_flame = Polygon2D.new()
	engine_flame.name = "EngineFlame"
	engine_flame.z_index = -2
	engine_flame.color = Color(1.0, 0.34, 0.08, 0.82)
	engine_flame.visible = false
	player_ship.add_child(engine_flame)
	
	inner_engine_flame = Polygon2D.new()
	inner_engine_flame.name = "InnerEngineFlame"
	inner_engine_flame.z_index = -1
	inner_engine_flame.color = Color(1.0, 0.92, 0.28, 0.9)
	inner_engine_flame.visible = false
	player_ship.add_child(inner_engine_flame)


func update_engine_flame(is_thrusting: bool, delta: float) -> void:
	if engine_flame == null or inner_engine_flame == null:
		return
	
	engine_flame.visible = is_thrusting
	inner_engine_flame.visible = is_thrusting
	
	if not is_thrusting:
		return
	
	flame_time += delta
	var flicker := 0.75 + 0.25 * sin(flame_time * 34.0)
	var ship_half_width := 128.0
	
	if starship_side_texture != null:
		ship_half_width = float(starship_side_texture.get_width()) * 0.5
	
	var flame_direction := -1.0
	var nozzle_x := -ship_half_width + 4.0
	
	if ship_sprite.flip_h:
		flame_direction = 1.0
		nozzle_x = ship_half_width - 4.0
	
	var flame_tip_x := nozzle_x + engine_flame_length * flicker * flame_direction
	var half_width := engine_flame_width * (0.75 + 0.2 * sin(flame_time * 21.0))
	
	engine_flame.polygon = PackedVector2Array([
		Vector2(nozzle_x, -half_width),
		Vector2(flame_tip_x, 0.0),
		Vector2(nozzle_x, half_width),
	])
	
	inner_engine_flame.polygon = PackedVector2Array([
		Vector2(nozzle_x + 2.0 * flame_direction, -half_width * 0.45),
		Vector2(flame_tip_x - engine_flame_length * 0.35 * flame_direction, 0.0),
		Vector2(nozzle_x + 2.0 * flame_direction, half_width * 0.45),
	])


func rotate_ship_toward(target_angle: float, delta: float) -> void:
	player_ship.rotation = lerp_angle(
		player_ship.rotation,
		target_angle,
		rotation_speed * delta
	)
	
func _unhandled_input(event: InputEvent) -> void:
	if is_landing_sequence_active:
		return
	
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()

func toggle_pause_menu() -> void:
	is_paused = !is_paused
	
	if is_paused:
		ship_velocity = Vector2.ZERO
		starfield.star_drift_speed = Vector2.ZERO
		update_engine_flame(false, 0.0)
		pause_menu.show_menu()
	else:
		pause_menu.hide_menu()


func _on_resume_pressed() -> void:
	is_paused = false
	pause_menu.hide_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()
