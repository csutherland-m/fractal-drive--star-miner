extends Area2D

@export var damage: int = 10
@export var drift_velocity: Vector2 = Vector2.ZERO
@export var spin_speed: float = 0.5
@export var radius: float = 12.0
@export var is_mineable: bool = false

var color: Color = Color("#777777")
var space_scroll_speed: Vector2 = Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	add_child(collision)


func _process(delta: float) -> void:
	position += (space_scroll_speed + drift_velocity) * delta
	rotation += spin_speed * delta
	
	delete_if_far_offscreen()
	queue_redraw()

func delete_if_far_offscreen() -> void:
	var screen_size := get_viewport_rect().size
	var margin: float = 500.0
	
	if position.x < -margin:
		queue_free()
	elif position.x > screen_size.x + margin:
		queue_free()
	elif position.y < -margin:
		queue_free()
	elif position.y > screen_size.y + margin:
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius * 0.7, 0, PI * 1.4, 12, Color("#4A4A4A"), 2.0)


func _on_body_entered(body: Node) -> void:
	pass


func _on_area_entered(area: Area2D) -> void:
	if area.name == "PlayerShip":
		if is_mineable:
			print("Landed on asteroid. Returning to main menu.")
			get_tree().change_scene_to_file("res://Scenes/AsteroidMining.tscn")
		else:
			print("Ship hit debris for %d damage." % damage)
			queue_free()
