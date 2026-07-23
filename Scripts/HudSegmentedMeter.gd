class_name HudSegmentedMeter
extends Control

@export var background_color := Color(0.015, 0.025, 0.028, 0.96)
@export var empty_color := Color(0.07, 0.09, 0.095, 0.98)
@export var fill_color := Color(0.0, 0.78, 0.88, 0.98)
@export var tick_color := Color(0.78, 0.92, 0.94, 0.82)
@export var base_units_per_tick: float = 10.0
@export var maximum_visible_segments: int = 20
@export var inset_pixels: float = 3.0

var current_value: float = 0.0
var maximum_value: float = 1.0


func set_values(new_current: float, new_maximum: float) -> void:
	var clamped_current := maxf(new_current, 0.0)
	var clamped_maximum := maxf(new_maximum, 0.001)
	if is_equal_approx(current_value, clamped_current) and is_equal_approx(maximum_value, clamped_maximum):
		return
	current_value = clamped_current
	maximum_value = clamped_maximum
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), background_color)
	var inner := Rect2(
		Vector2(inset_pixels, inset_pixels),
		Vector2(maxf(size.x - inset_pixels * 2.0, 0.0), maxf(size.y - inset_pixels * 2.0, 0.0))
	)
	draw_rect(inner, empty_color)
	var ratio := clampf(current_value / maximum_value, 0.0, 1.0)
	var filled := inner
	filled.size.x *= ratio
	draw_rect(filled, fill_color)

	var tick_increment := get_visible_tick_increment()
	var tick_value := tick_increment
	while tick_value < maximum_value:
		var tick_ratio := tick_value / maximum_value
		var x := inner.position.x + inner.size.x * tick_ratio
		draw_line(
			Vector2(x, inner.position.y),
			Vector2(x, inner.end.y),
			tick_color,
			2.0
		)
		tick_value += tick_increment


func get_visible_tick_increment() -> float:
	var increment := maxf(base_units_per_tick, 0.001)
	while ceili(maximum_value / increment) > maxi(maximum_visible_segments, 1):
		increment *= 10.0
	return increment
