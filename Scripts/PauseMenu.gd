extends CanvasLayer
class_name PauseMenu

signal resume_requested
signal quit_requested

@onready var pause_panel: Panel = $MenuRoot/CenterBox/PausePanel
@onready var resume_button: Button = $MenuRoot/CenterBox/PausePanel/ButtonBox/ResumeButton
@onready var quit_button: Button = $MenuRoot/CenterBox/PausePanel/ButtonBox/QuitButton


func _ready() -> void:
	pause_panel.theme = GameTheme.create_button_theme()
	make_pause_panel_transparent()
	
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	hide_menu()


func show_menu() -> void:
	visible = true


func hide_menu() -> void:
	visible = false


func _on_resume_pressed() -> void:
	resume_requested.emit()


func _on_quit_pressed() -> void:
	quit_requested.emit()


func make_pause_panel_transparent() -> void:
	var transparent_style := StyleBoxFlat.new()
	transparent_style.bg_color = Color(0, 0, 0, 0)
	pause_panel.add_theme_stylebox_override("panel", transparent_style)
