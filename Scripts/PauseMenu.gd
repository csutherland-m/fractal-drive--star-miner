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
@onready var settings_back_button: Button = $MenuRoot/CenterBox/SettingsPanel/SettingsBox/BackButton


func _ready() -> void:
	pause_panel.theme = GameTheme.create_button_theme()
	settings_panel.theme = pause_panel.theme
	make_pause_panel_transparent()
	
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	mouse_directed_e_toggle.toggled.connect(_on_mouse_directed_e_toggled)
	settings_back_button.pressed.connect(_on_settings_back_pressed)
	
	hide_menu()


func show_menu() -> void:
	visible = true
	pause_panel.visible = true
	settings_panel.visible = false


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
	var current_scene := get_tree().current_scene
	var success := SaveManager.save_game(current_scene)
	save_status_label.text = SaveManager.last_status_message
	save_status_label.add_theme_color_override(
		"font_color",
		Color(0.45, 1.0, 0.62, 1.0) if success else Color(1.0, 0.38, 0.3, 1.0)
	)


func _on_settings_pressed() -> void:
	mouse_directed_e_toggle.set_pressed_no_signal(GameSettings.mouse_directed_e_enabled)
	pause_panel.visible = false
	settings_panel.visible = true


func _on_settings_back_pressed() -> void:
	settings_panel.visible = false
	pause_panel.visible = true


func _on_mouse_directed_e_toggled(enabled: bool) -> void:
	GameSettings.set_mouse_directed_e_enabled(enabled)


func make_pause_panel_transparent() -> void:
	var transparent_style := StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	pause_panel.add_theme_stylebox_override("panel", transparent_style)
