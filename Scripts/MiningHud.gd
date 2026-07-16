class_name MiningHud
extends Control

signal radial_blast_requested
signal directional_blast_requested

const HousingTexture := preload("res://Sprites/UI/mining_hud_housing.png")
const SegmentedMeterScript := preload("res://Scripts/HudSegmentedMeter.gd")
const SevenSegmentDisplayScript := preload("res://Scripts/SevenSegmentDisplay.gd")

const DESIGN_SIZE := Vector2(768.0, 512.0)
const DISPLAY_SCALE := Vector2(0.72, 0.72)
const DISPLAY_SIZE := Vector2(DESIGN_SIZE.x * DISPLAY_SCALE.x, DESIGN_SIZE.y * DISPLAY_SCALE.y)
const GAUGE_CENTER := Vector2(418.0, 260.0)
const BUTTON_Q_RECT := Rect2(127.0, 286.0, 94.0, 98.0)
const BUTTON_E_RECT := Rect2(577.0, 292.0, 88.0, 92.0)

var design_root: Control
var fuel_meter: HudSegmentedMeter
var heat_meter: HudSegmentedMeter
var hull_meter: HudSegmentedMeter
var q_cooldown_meter: HudSegmentedMeter
var e_cooldown_meter: HudSegmentedMeter
var depth_display: SevenSegmentDisplay
var fuel_needle: ColorRect
var fuel_value_label: Label
var heat_value_label: Label
var hull_value_label: Label
var radial_button: Button
var directional_button: Button
var radial_cooldown_label: Label
var directional_cooldown_label: Label
var q_button_overlay: ColorRect
var e_button_overlay: ColorRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	custom_minimum_size = DISPLAY_SIZE
	build_hud()


func build_hud() -> void:
	design_root = Control.new()
	design_root.name = "DesignRoot"
	design_root.size = DESIGN_SIZE
	design_root.scale = DISPLAY_SCALE
	design_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(design_root)

	fuel_meter = create_meter(Rect2(65.0, 128.0, 246.0, 65.0), Color(0.0, 0.78, 0.88, 0.98), 10.0)
	heat_meter = create_meter(Rect2(139.0, 225.0, 114.0, 29.0), Color(1.0, 0.31, 0.025, 0.96), 10.0)
	hull_meter = create_meter(Rect2(557.0, 194.0, 152.0, 55.0), Color(0.18, 0.86, 0.34, 0.98), 100.0)
	q_cooldown_meter = create_meter(Rect2(104.0, 400.0, 126.0, 26.0), Color(0.95, 0.65, 0.12, 0.98), 100000.0)
	e_cooldown_meter = create_meter(Rect2(535.0, 400.0, 128.0, 26.0), Color(0.95, 0.65, 0.12, 0.98), 100000.0)

	var analog_face := ColorRect.new()
	analog_face.name = "FuelGaugeFace"
	analog_face.position = Vector2(320.0, 162.0)
	analog_face.size = Vector2(196.0, 196.0)
	analog_face.color = Color(0.012, 0.022, 0.025, 0.98)
	analog_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(analog_face)

	var housing := TextureRect.new()
	housing.name = "Housing"
	housing.texture = HousingTexture
	housing.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	housing.stretch_mode = TextureRect.STRETCH_SCALE
	housing.custom_minimum_size = Vector2.ZERO
	housing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(housing)
	housing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	add_window_label("FUEL", Rect2(70.0, 130.0, 70.0, 22.0), Color(0.36, 0.93, 1.0, 1.0), 15)
	fuel_value_label = add_window_label("0 / 0 KG", Rect2(139.0, 129.0, 165.0, 23.0), Color(0.82, 0.97, 1.0, 1.0), 14)
	add_window_label("HEAT", Rect2(142.0, 225.0, 47.0, 26.0), Color(1.0, 0.48, 0.12, 1.0), 11)
	heat_value_label = add_window_label("0%", Rect2(190.0, 225.0, 58.0, 26.0), Color(1.0, 0.68, 0.25, 1.0), 11)
	add_window_label("HULL", Rect2(563.0, 197.0, 55.0, 22.0), Color(0.66, 1.0, 0.72, 1.0), 13)
	hull_value_label = add_window_label("0 / 0", Rect2(616.0, 197.0, 88.0, 22.0), Color(0.84, 1.0, 0.86, 1.0), 12)

	add_analog_gauge_marks()
	fuel_needle = ColorRect.new()
	fuel_needle.name = "FuelNeedle"
	fuel_needle.color = Color(0.0, 0.9, 1.0, 0.98)
	fuel_needle.position = GAUGE_CENTER - Vector2(8.0, 2.5)
	fuel_needle.size = Vector2(83.0, 5.0)
	fuel_needle.pivot_offset = Vector2(8.0, 2.5)
	fuel_needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(fuel_needle)

	var fuel_pivot := ColorRect.new()
	fuel_pivot.position = GAUGE_CENTER - Vector2(7.0, 7.0)
	fuel_pivot.size = Vector2(14.0, 14.0)
	fuel_pivot.color = Color(0.78, 0.84, 0.82, 1.0)
	fuel_pivot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(fuel_pivot)

	var depth_title := add_window_label("DEPTH", Rect2(350.0, 292.0, 136.0, 18.0), Color(1.0, 0.57, 0.12, 1.0), 11)
	depth_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_display = SevenSegmentDisplayScript.new()
	depth_display.name = "DepthSevenSegmentDisplay"
	depth_display.position = Vector2(349.0, 311.0)
	depth_display.size = Vector2(139.0, 35.0)
	depth_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(depth_display)

	q_button_overlay = create_button_overlay(BUTTON_Q_RECT)
	e_button_overlay = create_button_overlay(BUTTON_E_RECT)
	radial_button = create_ability_button("RadialBlastButton", BUTTON_Q_RECT, "Q: mine every mineable block within one tile of the miner.")
	directional_button = create_ability_button("DirectionalBlastButton", BUTTON_E_RECT, "E: mine three blocks in the selected cardinal direction.")
	radial_button.pressed.connect(func(): radial_blast_requested.emit())
	directional_button.pressed.connect(func(): directional_blast_requested.emit())
	radial_cooldown_label = create_cooldown_label(Rect2(105.0, 400.0, 124.0, 26.0))
	directional_cooldown_label = create_cooldown_label(Rect2(536.0, 400.0, 126.0, 26.0))


func create_meter(rect: Rect2, color: Color, units_per_tick: float) -> HudSegmentedMeter:
	var meter: HudSegmentedMeter = SegmentedMeterScript.new()
	meter.position = rect.position
	meter.size = rect.size
	meter.fill_color = color
	meter.base_units_per_tick = units_per_tick
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(meter)
	return meter


func add_window_label(text_value: String, rect: Rect2, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(label)
	return label


func add_analog_gauge_marks() -> void:
	var title := add_window_label("MINER FUEL", Rect2(366.0, 176.0, 105.0, 22.0), Color(0.43, 0.94, 1.0, 1.0), 13)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for index in 11:
		var ratio := float(index) / 10.0
		var angle := lerpf(deg_to_rad(-210.0), deg_to_rad(30.0), ratio)
		var mark := ColorRect.new()
		mark.color = Color(0.45, 0.8, 0.82, 0.82)
		mark.position = GAUGE_CENTER + Vector2.from_angle(angle) * 82.0 - Vector2(1.5, 5.0)
		mark.size = Vector2(3.0, 10.0)
		mark.pivot_offset = Vector2(1.5, 5.0)
		mark.rotation = angle + PI * 0.5
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		design_root.add_child(mark)


func create_button_overlay(rect: Rect2) -> ColorRect:
	var overlay := ColorRect.new()
	overlay.position = rect.position
	overlay.size = rect.size
	overlay.color = Color(1.0, 0.82, 0.38, 0.16)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design_root.add_child(overlay)
	return overlay


func create_ability_button(node_name: String, rect: Rect2, tooltip: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.position = rect.position
	button.size = rect.size
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1.0, 1.0, 1.0, 0.0)
		style.border_color = Color(1.0, 0.78, 0.28, 0.42) if state == "hover" else Color.TRANSPARENT
		style.set_border_width_all(3 if state == "hover" else 0)
		style.set_corner_radius_all(7)
		button.add_theme_stylebox_override(state, style)
	design_root.add_child(button)
	return button


func create_cooldown_label(rect: Rect2) -> Label:
	var label := add_window_label("READY", rect, Color(1.0, 0.86, 0.5, 1.0), 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func set_fuel(current_fuel: float, maximum_fuel: float, warning_ratio: float) -> void:
	if fuel_meter == null:
		return
	fuel_meter.set_values(current_fuel, maximum_fuel)
	var ratio := clampf(current_fuel / maxf(maximum_fuel, 0.001), 0.0, 1.0)
	fuel_meter.fill_color = Color(1.0, 0.08, 0.035, 0.98) if ratio <= warning_ratio else Color(0.0, 0.78, 0.88, 0.98)
	fuel_value_label.text = "%d / %d KG" % [roundi(current_fuel), ceili(maximum_fuel)]
	fuel_needle.rotation = lerpf(deg_to_rad(-210.0), deg_to_rad(30.0), ratio)


func set_heat(new_heat_ratio: float) -> void:
	if heat_meter == null:
		return
	var clamped_ratio := clampf(new_heat_ratio, 0.0, 1.0)
	heat_meter.set_values(clamped_ratio * 100.0, 100.0)
	heat_meter.modulate = Color(0.34, 0.34, 0.34, 0.8) if clamped_ratio <= 0.0 else Color.WHITE
	heat_value_label.text = "%d%%" % roundi(clamped_ratio * 100.0)


func set_hull(current_hull: float, maximum_hull: float) -> void:
	if hull_meter == null:
		return
	var ratio := clampf(current_hull / maxf(maximum_hull, 0.001), 0.0, 1.0)
	hull_meter.fill_color = Color(0.18, 0.86, 0.34, 0.98).lerp(Color(0.96, 0.08, 0.035, 0.98), 1.0 - ratio)
	hull_meter.set_values(current_hull, maximum_hull)
	hull_value_label.text = "%d / %d" % [roundi(current_hull), ceili(maximum_hull)]


func set_depth_meters(depth_meters: int) -> void:
	if depth_display != null:
		depth_display.set_value(depth_meters)


func set_ability_states(
	q_remaining: float,
	q_total: float,
	e_remaining: float,
	e_total: float,
	globally_disabled: bool,
	mouse_directed_e: bool
) -> void:
	set_one_ability_state(radial_button, q_button_overlay, q_cooldown_meter, radial_cooldown_label, q_remaining, q_total, globally_disabled)
	set_one_ability_state(directional_button, e_button_overlay, e_cooldown_meter, directional_cooldown_label, e_remaining, e_total, globally_disabled)
	directional_button.tooltip_text = (
		"E: mouse-directed three-block blast."
		if mouse_directed_e
		else "E: drill-facing three-block blast."
	)


func set_one_ability_state(
	button: Button,
	overlay: ColorRect,
	meter: HudSegmentedMeter,
	label: Label,
	remaining: float,
	total: float,
	globally_disabled: bool
) -> void:
	var on_cooldown := remaining > 0.0
	button.disabled = globally_disabled or on_cooldown
	overlay.color = Color(0.0, 0.0, 0.0, 0.64) if button.disabled else Color(1.0, 0.82, 0.38, 0.18)
	var progress := 1.0 - clampf(remaining / maxf(total, 0.001), 0.0, 1.0)
	meter.set_values(progress, 1.0)
	label.text = format_cooldown(remaining)
	label.modulate = Color(0.64, 0.66, 0.66, 1.0) if globally_disabled else Color.WHITE


func format_cooldown(seconds_remaining: float) -> String:
	if seconds_remaining <= 0.0:
		return "READY"
	var whole_seconds := ceili(seconds_remaining)
	return "%d:%02d" % [floori(float(whole_seconds) / 60.0), whole_seconds % 60]
