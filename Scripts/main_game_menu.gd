extends Node2D

@onready var animated_background: AnimatedSprite2D = $AnimatedSprite2D
@onready var play_button: Button = $MenuUI/MenuRoot/CenterContainer/ButtonBox/PlayButton
@onready var quit_button: Button = $MenuUI/MenuRoot/CenterContainer/ButtonBox/QuitButton
@onready var menu_root: Control = $MenuUI/MenuRoot

func _ready() -> void:
	menu_root.theme = GameTheme.create_button_theme()
	
	animated_background.stop()
	animated_background.frame = 0
	
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/FlightTest.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
	
