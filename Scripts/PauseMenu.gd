extends CanvasLayer
class_name PauseMenu

signal resume_requested
signal quit_requested

@onready var pause_panel: Panel = $MenuRoot/CenterBox/PausePanel
@onready var resume_button: Button = $MenuRoot/CenterBox/PausePanel/ButtonBox/ResumeButton
@onready var save_button: Button = $MenuRoot/CenterBox/PausePanel/ButtonBox/SaveButton
@onready var settings_button: Button = $MenuRoot/CenterBox/PausePanel/ButtonBox/SettingsButton
@onready var quit_button: Button = $MenuRoot/CenterBox/PausePanel/ButtonBox/QuitButton
@onready var save_status_label: Label = $MenuRoot/CenterBox/PausePanel/ButtonBox/SaveStatusLabel
@onready var settings_panel: Panel = $MenuRoot/CenterBox/SettingsPanel
@onready var mouse_directed_e_toggle: CheckButton = $MenuRoot/CenterBox/SettingsPanel/SettingsBox/MouseDirectedEToggle
@onready var menu_back_binding_button: Button = $MenuRoot/CenterBox/SettingsPanel/SettingsBox/MenuBackBindingButton
@onready var settings_back_button: Button = $MenuRoot/CenterBox/SettingsPanel/SettingsBox/BackButton
@onready var save_slot_buttons: Array[Button] = [
	$MenuRoot/CenterBox/PausePanel/ButtonBox/SaveSlotButtons/Slot1Button,
	$MenuRoot/CenterBox/PausePanel/ButtonBox/SaveSlotButtons/Slot2Button,
	$MenuRoot/CenterBox/PausePanel/ButtonBox/SaveSlotButtons/Slot3Button,
]
@onready var overwrite_confirmation: ConfirmationDialog = $OverwriteConfirmation

var waiting_for_menu_back_key: bool = false
var selected_save_slot: int = 1


func _ready() -> void:
	pause_panel.theme = GameTheme.create_button_theme()
	settings_panel.theme = pause_panel.theme
	make_pause_panel_transparent()
	
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	mouse_directed_e_toggle.toggled.connect(_on_mouse_directed_e_toggled)
	menu_back_binding_button.pressed.connect(_on_menu_back_binding_pressed)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	overwrite_confirmation.confirmed.connect(_save_to_selected_slot)
	for index in save_slot_buttons.size():
		var button := save_slot_buttons[index]
		button.toggle_mode = true
		button.pressed.connect(_on_save_slot_selected.bind(index + 1))
	
	hide_menu()


func show_menu() -> void:
	visible = true
	pause_panel.visible = true
	settings_panel.visible = false
	selected_save_slot = SaveManager.active_slot
	refresh_save_slot_controls()


func hide_menu() -> void:
	visible = false


func is_settings_open() -> bool:
	return visible and settings_panel.visible


func handle_back_request() -> bool:
	if not is_settings_open():
		return false
	_on_settings_back_pressed()
	return true


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()


func _on_save_pressed() -> void:
	if SaveManager.has_save(selected_save_slot) and selected_save_slot != SaveManager.active_slot:
		overwrite_confirmation.dialog_text = (
			"Slot %d contains another saved game. Replace it with the current run?"
			% selected_save_slot
		)
		overwrite_confirmation.popup_centered(Vector2i(520, 210))
		return
	_save_to_selected_slot()


func _save_to_selected_slot() -> void:
	var current_scene := get_tree().current_scene
	var success := SaveManager.save_game(current_scene, selected_save_slot)
	save_status_label.text = SaveManager.last_status_message
	save_status_label.add_theme_color_override(
		"font_color",
		Color(0.45, 1.0, 0.62, 1.0) if success else Color(1.0, 0.38, 0.3, 1.0)
	)
	refresh_save_slot_controls()


func _on_save_slot_selected(slot: int) -> void:
	selected_save_slot = slot
	refresh_save_slot_controls()


func refresh_save_slot_controls() -> void:
	for index in save_slot_buttons.size():
		var slot := index + 1
		var occupied := SaveManager.has_save(slot)
		var button := save_slot_buttons[index]
		button.set_pressed_no_signal(slot == selected_save_slot)
		button.text = "%d\n%s" % [slot, "Saved" if occupied else "Empty"]
	save_button.text = "Save Game to Slot %d" % selected_save_slot


func _on_settings_pressed() -> void:
	mouse_directed_e_toggle.set_pressed_no_signal(GameSettings.mouse_directed_e_enabled)
	refresh_menu_back_binding_text()
	pause_panel.visible = false
	settings_panel.visible = true


func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
	pause_panel.visible = true


func _on_mouse_directed_e_toggled(enabled: bool) -> void:
	GameSettings.set_mouse_directed_e_enabled(enabled)


func _on_menu_back_binding_pressed() -> void:
	waiting_for_menu_back_key = true
	menu_back_binding_button.text = "Press a key for Menu Back..."


func _input(event: InputEvent) -> void:
	if not waiting_for_menu_back_key or not visible:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var selected_key := (
				key_event.physical_keycode
				if key_event.physical_keycode != KEY_NONE
				else key_event.keycode
			) as Key
			GameSettings.set_menu_back_keycode(selected_key)
			waiting_for_menu_back_key = false
			refresh_menu_back_binding_text()
			get_viewport().set_input_as_handled()


func refresh_menu_back_binding_text() -> void:
	menu_back_binding_button.text = "Menu Back Key: %s" % GameSettings.get_menu_back_key_text()


func make_pause_panel_transparent() -> void:
	var transparent_style := StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	pause_panel.add_theme_stylebox_override("panel", transparent_style)
