extends Node2D

@onready var animated_background: AnimatedSprite2D = $AnimatedSprite2D
@onready var play_button: Button = $MenuUI/MenuRoot/CenterContainer/ButtonBox/PlayButton
@onready var continue_button: Button = $MenuUI/MenuRoot/CenterContainer/ButtonBox/ContinueButton
@onready var quit_button: Button = $MenuUI/MenuRoot/CenterContainer/ButtonBox/QuitButton
@onready var save_status_label: Label = $MenuUI/MenuRoot/CenterContainer/ButtonBox/SaveStatusLabel
@onready var menu_root: Control = $MenuUI/MenuRoot

func _ready() -> void:
	menu_root.theme = GameTheme.create_button_theme()
	
	animated_background.stop()
	animated_background.frame = 0
	
	play_button.pressed.connect(_on_play_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	continue_button.disabled = not SaveManager.has_save()


func _on_play_pressed() -> void:
	SeedManager.start_new_run()
	get_tree().change_scene_to_file("res://Scenes/AsteroidMining.tscn")


func _on_continue_pressed() -> void:
	if SaveManager.load_game():
		return
	save_status_label.text = SaveManager.last_status_message


func _on_quit_pressed() -> void:
	get_tree().quit()
	
