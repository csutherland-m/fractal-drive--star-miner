extends Node2D

@onready var player_ship: Area2D = $PlayerShip
@onready var ship_sprite: Sprite2D = $PlayerShip/ShipSprite
@onready var starfield: Node2D = $Starfield
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var asteroid_spawner: Node2D = $AsteroidSpawner

@export var max_speed: float = 160.0
@export var acceleration_rate: float = 60.0
@export var deceleration_rate: float = 35.0
@export var rotation_speed: float = 8.0

var ship_velocity: Vector2 = Vector2.ZERO
var is_paused: bool = false

func _ready() -> void:
	pause_menu.resume_requested.connect(_on_resume_pressed)
	pause_menu.quit_requested.connect(_on_quit_pressed)

func _process(delta: float) -> void:
	if is_paused:
		return
	
	var input_direction := get_input_direction()
	
	if input_direction != Vector2.ZERO:
		accelerate_ship(input_direction, delta)
		rotate_ship_toward(input_direction, delta)
	else:
		decelerate_ship(delta)
	
	starfield.star_drift_speed = -ship_velocity
	asteroid_spawner.space_scroll_speed = -ship_velocity
	
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
	
func accelerate_ship(direction: Vector2, delta: float) -> void:
	ship_velocity += direction * acceleration_rate * delta
	ship_velocity = ship_velocity.limit_length(max_speed)
	
func decelerate_ship(delta: float) -> void:
	if ship_velocity.length() > 0:
		var slowdown_amount := deceleration_rate * delta
		ship_velocity = ship_velocity.move_toward(Vector2.ZERO, slowdown_amount)
		
func rotate_ship_toward(direction: Vector2, delta: float) -> void:
	var target_angle := direction.angle() - deg_to_rad(90)
	
	player_ship.rotation = lerp_angle(
		player_ship.rotation,
		target_angle,
		rotation_speed * delta
	)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()

func toggle_pause_menu() -> void:
	is_paused = !is_paused
	
	if is_paused:
		ship_velocity = Vector2.ZERO
		starfield.star_drift_speed = Vector2.ZERO
		pause_menu.show_menu()
	else:
		pause_menu.hide_menu()


func _on_resume_pressed() -> void:
	is_paused = false
	pause_menu.hide_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()
