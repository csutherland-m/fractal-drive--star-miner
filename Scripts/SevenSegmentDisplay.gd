class_name SevenSegmentDisplay
extends Control

@export var digit_count: int = 5
@export var lit_color := Color(1.0, 0.46, 0.055, 1.0)
@export var unlit_color := Color(0.19, 0.075, 0.02, 0.46)
@export var background_color := Color(0.012, 0.016, 0.017, 0.97)

var displayed_value: int = 0

const DIGIT_SEGMENTS := {
	"0": [0, 1, 2, 3, 4, 5],
	"1": [1, 2],
	"2": [0, 1, 6, 4, 3],
	"3": [0, 1, 6, 2, 3],
	"4": [5, 6, 1, 2],
	"5": [0, 5, 6, 2, 3],
	"6": [0, 5, 6, 4, 2, 3],
	"7": [0, 1, 2],
	"8": [0, 1, 2, 3, 4, 5, 6],
	"9": [0, 1, 2, 3, 5, 6],
}


func set_value(new_value: int) -> void:
	var clamped_value := maxi(new_value, 0)
	if displayed_value == clamped_value:
		return
	displayed_value = clamped_value
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), background_color)
	var digits := str(displayed_value).pad_zeros(digit_count)
	if digits.length() > digit_count:
		digits = digits.right(digit_count)
	var meter_width := maxf(size.x - 18.0, 1.0)
	var spacing := 2.0
	var digit_width := (meter_width - spacing * float(digit_count - 1)) / float(digit_count)
	for index in digit_count:
		var origin := Vector2(float(index) * (digit_width + spacing), 2.0)
		draw_digit(digits[index], Rect2(origin, Vector2(digit_width, maxf(size.y - 4.0, 1.0))))
	draw_meter_suffix(Vector2(size.x - 15.0, size.y - 7.0))


func draw_digit(character: String, rect: Rect2) -> void:
	var thickness := maxf(minf(rect.size.x, rect.size.y) * 0.13, 1.5)
	var half_height := rect.size.y * 0.5
	var segments := [
		Rect2(rect.position + Vector2(thickness, 0.0), Vector2(rect.size.x - thickness * 2.0, thickness)),
		Rect2(rect.position + Vector2(rect.size.x - thickness, thickness), Vector2(thickness, half_height - thickness)),
		Rect2(rect.position + Vector2(rect.size.x - thickness, half_height), Vector2(thickness, half_height - thickness)),
		Rect2(rect.position + Vector2(thickness, rect.size.y - thickness), Vector2(rect.size.x - thickness * 2.0, thickness)),
		Rect2(rect.position + Vector2(0.0, half_height), Vector2(thickness, half_height - thickness)),
		Rect2(rect.position + Vector2(0.0, thickness), Vector2(thickness, half_height - thickness)),
		Rect2(rect.position + Vector2(thickness, half_height - thickness * 0.5), Vector2(rect.size.x - thickness * 2.0, thickness)),
	]
	var active_segments: Array = DIGIT_SEGMENTS.get(character, [])
	for segment_index in segments.size():
		draw_rect(segments[segment_index], lit_color if active_segments.has(segment_index) else unlit_color)


func draw_meter_suffix(origin: Vector2) -> void:
	var color := lit_color.darkened(0.12)
	draw_line(origin + Vector2(0.0, -8.0), origin, color, 2.0)
	draw_line(origin + Vector2(0.0, -8.0), origin + Vector2(4.0, -5.0), color, 2.0)
	draw_line(origin + Vector2(4.0, -5.0), origin + Vector2(8.0, -8.0), color, 2.0)
	draw_line(origin + Vector2(8.0, -8.0), origin + Vector2(8.0, 0.0), color, 2.0)
