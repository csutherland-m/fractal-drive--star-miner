extends CanvasLayer
class_name TutorialOverlay

signal continue_requested
signal choice_selected(choice_id: String)

const HIGHLIGHT_COLOR := Color(1.0, 0.84, 0.08, 1.0)

var root: Control
var full_blocker: ColorRect
var hole_blockers: Array[ColorRect] = []
var highlight_panels: Array[Panel] = []
var dialogue_panel: Panel
var speaker_label: Label
var dialogue_label: Label
var choice_box: VBoxContainer
var continue_button: Button
var action_panel: Panel
var action_speaker_label: Label
var action_label: Label
var objective_panel: Panel
var objective_label: Label
var active_target: Control
var highlighted_targets: Array[Control] = []


func _ready() -> void:
	layer = 40
	build_overlay()
	clear_interaction()
	set_objective("")


func build_overlay() -> void:
	root = Control.new()
	root.name = "TutorialRoot"
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	full_blocker = ColorRect.new()
	full_blocker.name = "FullInputBlocker"
	full_blocker.anchor_right = 1.0
	full_blocker.anchor_bottom = 1.0
	full_blocker.color = Color(0.01, 0.02, 0.03, 0.72)
	full_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(full_blocker)

	for blocker_name in ["TopBlocker", "BottomBlocker", "LeftBlocker", "RightBlocker"]:
		var blocker := ColorRect.new()
		blocker.name = blocker_name
		blocker.color = Color(0.01, 0.02, 0.03, 0.66)
		blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		root.add_child(blocker)
		hole_blockers.append(blocker)

	objective_panel = Panel.new()
	objective_panel.name = "TutorialObjective"
	objective_panel.anchor_left = 0.5
	objective_panel.anchor_right = 0.5
	objective_panel.offset_left = -410.0
	objective_panel.offset_right = 410.0
	objective_panel.offset_top = 20.0
	objective_panel.offset_bottom = 102.0
	objective_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_panel.add_theme_stylebox_override("panel", create_panel_style(Color(0.05, 0.09, 0.12, 0.94), HIGHLIGHT_COLOR, 3))
	root.add_child(objective_panel)
	objective_label = Label.new()
	objective_label.anchor_right = 1.0
	objective_label.anchor_bottom = 1.0
	objective_label.offset_left = 18.0
	objective_label.offset_top = 10.0
	objective_label.offset_right = -18.0
	objective_label.offset_bottom = -10.0
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.add_theme_font_size_override("font_size", 20)
	objective_label.add_theme_color_override("font_color", Color.WHITE)
	objective_label.add_theme_color_override("font_outline_color", Color.BLACK)
	objective_label.add_theme_constant_override("outline_size", 4)
	objective_panel.add_child(objective_label)

	dialogue_panel = Panel.new()
	dialogue_panel.name = "TutorialDialogue"
	dialogue_panel.anchor_left = 0.14
	dialogue_panel.anchor_right = 0.86
	dialogue_panel.anchor_top = 0.27
	dialogue_panel.anchor_bottom = 0.94
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_panel.theme = GameTheme.create_button_theme()
	dialogue_panel.add_theme_stylebox_override("panel", create_panel_style(Color(0.035, 0.065, 0.085, 0.98), HIGHLIGHT_COLOR, 4))
	root.add_child(dialogue_panel)
	var dialogue_box := VBoxContainer.new()
	dialogue_box.anchor_right = 1.0
	dialogue_box.anchor_bottom = 1.0
	dialogue_box.offset_left = 28.0
	dialogue_box.offset_top = 20.0
	dialogue_box.offset_right = -28.0
	dialogue_box.offset_bottom = -20.0
	dialogue_box.add_theme_constant_override("separation", 14)
	dialogue_panel.add_child(dialogue_box)
	speaker_label = create_speaker_label()
	dialogue_box.add_child(speaker_label)
	dialogue_label = create_dialogue_label()
	dialogue_box.add_child(dialogue_label)
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 9)
	dialogue_box.add_child(choice_box)
	continue_button = Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size.y = 52.0
	continue_button.pressed.connect(func(): continue_requested.emit())
	dialogue_box.add_child(continue_button)

	action_panel = Panel.new()
	action_panel.name = "TutorialActionPrompt"
	action_panel.anchor_left = 0.18
	action_panel.anchor_right = 0.82
	action_panel.anchor_top = 0.76
	action_panel.anchor_bottom = 0.95
	action_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	action_panel.add_theme_stylebox_override("panel", create_panel_style(Color(0.035, 0.065, 0.085, 0.97), HIGHLIGHT_COLOR, 4))
	root.add_child(action_panel)
	var action_box := VBoxContainer.new()
	action_box.anchor_right = 1.0
	action_box.anchor_bottom = 1.0
	action_box.offset_left = 26.0
	action_box.offset_top = 16.0
	action_box.offset_right = -26.0
	action_box.offset_bottom = -16.0
	action_box.add_theme_constant_override("separation", 8)
	action_panel.add_child(action_box)
	action_speaker_label = create_speaker_label()
	action_box.add_child(action_speaker_label)
	action_label = create_dialogue_label()
	action_label.add_theme_font_size_override("font_size", 19)
	action_box.add_child(action_label)


func create_speaker_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", HIGHLIGHT_COLOR)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	return label


func create_dialogue_label() -> Label:
	var label := Label.new()
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	return label


func create_panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0, 0, 0, 0.75)
	style.shadow_size = 8
	return style


func show_dialogue(
	speaker: String,
	text: String,
	continue_text: String = "Continue",
	choices: Array = [],
	targets: Array[Control] = []
) -> void:
	visible = true
	full_blocker.visible = true
	set_hole_blockers_visible(false)
	dialogue_panel.visible = true
	action_panel.visible = false
	active_target = null
	highlighted_targets = targets
	speaker_label.text = speaker
	dialogue_label.text = text
	clear_children(choice_box)
	continue_button.visible = choices.is_empty()
	continue_button.text = continue_text
	for choice_value in choices:
		if not choice_value is Dictionary:
			continue
		var choice: Dictionary = choice_value
		var button := Button.new()
		button.text = str(choice.get("text", "Continue"))
		button.custom_minimum_size.y = 52.0
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.pressed.connect(
			func(): choice_selected.emit(str(choice.get("id", "")))
		)
		choice_box.add_child(button)
	refresh_highlights()
	if continue_button.visible:
		continue_button.grab_focus()
	elif choice_box.get_child_count() > 0:
		(choice_box.get_child(0) as Button).grab_focus()


func show_action_prompt(
	speaker: String,
	text: String,
	target: Control,
	targets: Array[Control] = []
) -> void:
	visible = true
	full_blocker.visible = false
	set_hole_blockers_visible(true)
	dialogue_panel.visible = false
	action_panel.visible = true
	active_target = target
	highlighted_targets = targets.duplicate()
	if target != null and not highlighted_targets.has(target):
		highlighted_targets.push_front(target)
	action_speaker_label.text = speaker
	action_label.text = text
	refresh_action_hole()
	refresh_highlights()
	if is_instance_valid(active_target):
		active_target.grab_focus()


func clear_interaction() -> void:
	active_target = null
	highlighted_targets.clear()
	if full_blocker != null:
		full_blocker.visible = false
	set_hole_blockers_visible(false)
	if dialogue_panel != null:
		dialogue_panel.visible = false
	if action_panel != null:
		action_panel.visible = false
	clear_highlights()
	update_visibility()


func set_objective(text: String) -> void:
	if objective_panel == null:
		return
	objective_label.text = text
	objective_panel.visible = not text.is_empty()
	update_visibility()


func update_visibility() -> void:
	visible = (
		(objective_panel != null and objective_panel.visible)
		or (dialogue_panel != null and dialogue_panel.visible)
		or (action_panel != null and action_panel.visible)
	)


func _process(_delta: float) -> void:
	if not visible:
		return
	if action_panel.visible:
		refresh_action_hole()
	refresh_highlights()


func refresh_action_hole() -> void:
	if not is_instance_valid(active_target) or not active_target.is_visible_in_tree():
		set_hole_blockers_visible(false)
		return
	set_hole_blockers_visible(true)
	var viewport_size := get_viewport().get_visible_rect().size
	var target_rect := active_target.get_global_rect().grow(8.0)
	target_rect.position.x = clampf(target_rect.position.x, 0.0, viewport_size.x)
	target_rect.position.y = clampf(target_rect.position.y, 0.0, viewport_size.y)
	target_rect.size.x = clampf(target_rect.size.x, 0.0, viewport_size.x - target_rect.position.x)
	target_rect.size.y = clampf(target_rect.size.y, 0.0, viewport_size.y - target_rect.position.y)
	set_rect(hole_blockers[0], Rect2(0.0, 0.0, viewport_size.x, target_rect.position.y))
	set_rect(hole_blockers[1], Rect2(0.0, target_rect.end.y, viewport_size.x, maxf(viewport_size.y - target_rect.end.y, 0.0)))
	set_rect(hole_blockers[2], Rect2(0.0, target_rect.position.y, target_rect.position.x, target_rect.size.y))
	set_rect(hole_blockers[3], Rect2(target_rect.end.x, target_rect.position.y, maxf(viewport_size.x - target_rect.end.x, 0.0), target_rect.size.y))


func refresh_highlights() -> void:
	while highlight_panels.size() < highlighted_targets.size():
		var panel := Panel.new()
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override("panel", create_panel_style(Color(1.0, 0.84, 0.08, 0.04), HIGHLIGHT_COLOR, 6))
		root.add_child(panel)
		highlight_panels.append(panel)
	for index in highlight_panels.size():
		var panel := highlight_panels[index]
		if index >= highlighted_targets.size() or not is_instance_valid(highlighted_targets[index]):
			panel.visible = false
			continue
		var target := highlighted_targets[index]
		panel.visible = target.is_visible_in_tree()
		if panel.visible:
			set_rect(panel, target.get_global_rect().grow(7.0))


func clear_highlights() -> void:
	for panel in highlight_panels:
		panel.visible = false


func set_hole_blockers_visible(blockers_visible: bool) -> void:
	for blocker in hole_blockers:
		blocker.visible = blockers_visible


func set_rect(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
