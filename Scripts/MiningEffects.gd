extends Node2D

@export var dust_particle_texture: Texture2D
@export var spark_particle_texture: Texture2D
@export var impact_particle_texture: Texture2D
@export var floating_text_font_size: int = 18
@export var shake_decay: float = 18.0
@export var impact_shake_cooldown_seconds: float = 0.12

var shake_time: float = 0.0
var shake_duration: float = 0.0
var shake_strength: float = 0.0
var impact_shake_cooldown: float = 0.0
var particle_texture_cache: Dictionary = {}


func _ready() -> void:
	z_index = 9


func _process(delta: float) -> void:
	if shake_time > 0.0:
		shake_time = maxf(shake_time - delta, 0.0)
		shake_strength = move_toward(shake_strength, 0.0, shake_decay * delta)
	
	if impact_shake_cooldown > 0.0:
		impact_shake_cooldown = maxf(impact_shake_cooldown - delta, 0.0)


func get_camera_offset() -> Vector2:
	if shake_time <= 0.0 or shake_duration <= 0.0:
		return Vector2.ZERO
	
	var falloff := shake_time / shake_duration
	var strength := shake_strength * falloff
	return Vector2(randf_range(-strength, strength), randf_range(-strength, strength)).round()


func add_screen_shake(strength: float, duration: float) -> void:
	shake_strength = maxf(shake_strength, strength)
	shake_duration = maxf(duration, 0.01)
	shake_time = maxf(shake_time, shake_duration)


func play_drill_feedback(local_position: Vector2, block_name: String, direction: Vector2i) -> void:
	var dust_color := get_dust_color(block_name)
	spawn_particles(
		local_position,
		get_particle_texture("dust", dust_particle_texture, Color(0.78, 0.64, 0.48, 1.0)),
		dust_color,
		10,
		0.32,
		Vector2(-float(direction.x), -0.65 if direction.y >= 0 else 0.65),
		95.0,
		170.0,
		95.0,
		0.55,
		1.1
	)
	
	if should_emit_sparks(block_name):
		spawn_particles(
			local_position,
			get_particle_texture("spark", spark_particle_texture, Color(1.0, 0.82, 0.2, 1.0)),
			Color(1.0, 0.72, 0.18, 1.0),
			5,
			0.18,
			Vector2(-float(direction.x), -0.35 if direction.y >= 0 else 0.35),
			160.0,
			260.0,
			20.0,
			0.35,
			0.75
		)


func play_block_mined(local_position: Vector2, resource_name: String, amount: int) -> void:
	spawn_particles(
		local_position,
		get_particle_texture("dust", dust_particle_texture, Color(0.78, 0.64, 0.48, 1.0)),
		get_dust_color(resource_name),
		18,
		0.42,
		Vector2.UP,
		120.0,
		230.0,
		140.0,
		0.7,
		1.45
	)
	
	if amount > 0:
		spawn_floating_text(local_position + Vector2(0.0, -26.0), "+%d %s" % [amount, resource_name])


func play_lodestone_impact(local_position: Vector2, fall_speed: float) -> void:
	spawn_particles(
		local_position + Vector2(0.0, 22.0),
		get_particle_texture("impact", impact_particle_texture, Color(0.7, 0.72, 0.68, 1.0)),
		Color(0.48, 0.44, 0.38, 0.95),
		26,
		0.55,
		Vector2.UP,
		130.0,
		310.0,
		190.0,
		0.9,
		1.8
	)
	
	if impact_shake_cooldown <= 0.0:
		var strength := clampf(fall_speed / 80.0, 4.0, 13.0)
		add_screen_shake(strength, 0.22)
		impact_shake_cooldown = impact_shake_cooldown_seconds


func spawn_particles(
	local_position: Vector2,
	texture: Texture2D,
	color: Color,
	amount: int,
	lifetime: float,
	direction: Vector2,
	velocity_min: float,
	velocity_max: float,
	gravity_amount: float,
	scale_min: float,
	scale_max: float
) -> void:
	var particles := CPUParticles2D.new()
	particles.position = local_position
	particles.texture = texture
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.randomness = 0.75
	particles.local_coords = false
	particles.direction = direction.normalized() if direction != Vector2.ZERO else Vector2.UP
	particles.spread = 70.0
	particles.gravity = Vector2(0.0, gravity_amount)
	particles.initial_velocity_min = velocity_min
	particles.initial_velocity_max = velocity_max
	particles.scale_amount_min = scale_min
	particles.scale_amount_max = scale_max
	particles.color = color
	add_child(particles)
	particles.emitting = true
	
	var cleanup_timer := get_tree().create_timer(lifetime + 0.35)
	cleanup_timer.timeout.connect(particles.queue_free)


func spawn_floating_text(local_position: Vector2, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = local_position
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", floating_text_font_size)
	label.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.z_index = 12
	add_child(label)
	
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", local_position + Vector2(0.0, -36.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(label.queue_free)


func get_dust_color(block_name: String) -> Color:
	match block_name:
		"Copper":
			return Color(0.78, 0.38, 0.18, 0.9)
		"Raw Fuel":
			return Color(0.22, 0.18, 0.14, 0.92)
		"Iron", "Rock", "Lode Stone":
			return Color(0.5, 0.5, 0.46, 0.9)
		"Gold", "Treasure":
			return Color(0.88, 0.66, 0.24, 0.9)
		"Diamond", "Warp Gems", "Black Hole Crystals", "Planet Core":
			return Color(0.52, 0.78, 0.98, 0.9)
		_:
			return Color(0.55, 0.38, 0.22, 0.9)


func should_emit_sparks(block_name: String) -> bool:
	return block_name != "Dirt" and block_name != "Raw Fuel"


func get_particle_texture(cache_key: String, override_texture: Texture2D, color: Color) -> Texture2D:
	if override_texture != null:
		return override_texture
	
	if particle_texture_cache.has(cache_key):
		return particle_texture_cache[cache_key]
	
	var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	for y in range(8):
		for x in range(8):
			var distance := Vector2(float(x) - 3.5, float(y) - 3.5).length()
			var alpha := clampf(1.0 - distance / 4.0, 0.0, 1.0)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, color.a * alpha))
	
	var texture := ImageTexture.create_from_image(image)
	particle_texture_cache[cache_key] = texture
	return texture
