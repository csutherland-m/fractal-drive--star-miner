extends Node2D

@onready var animated_background: AnimatedSprite2D = $AnimatedSprite2D
@onready var play_button: Button = $MenuUI/MenuRoot/CenterContainer/ButtonBox/PlayButton
@onready var continue_button: Button = $MenuUI/MenuRoot/CenterContainer/ButtonBox/ContinueButton
@onready var quit_button: Button = $MenuUI/MenuRoot/CenterContainer/ButtonBox/QuitButton
@onready var save_status_label: Label = $MenuUI/MenuRoot/CenterContainer/ButtonBox/SaveStatusLabel
@onready var menu_root: Control = $MenuUI/MenuRoot
@onready var slot_details_label: Label = $MenuUI/MenuRoot/CenterContainer/ButtonBox/SlotDetailsLabel
@onready var slot_buttons: Array[Button] = [
	$MenuUI/MenuRoot/CenterContainer/ButtonBox/SlotButtons/Slot1Button,
	$MenuUI/MenuRoot/CenterContainer/ButtonBox/SlotButtons/Slot2Button,
	$MenuUI/MenuRoot/CenterContainer/ButtonBox/SlotButtons/Slot3Button,
]
@onready var restart_confirmation: ConfirmationDialog = $MenuUI/RestartConfirmation

var selected_slot: int = 1

func _ready() -> void:
	menu_root.theme = GameTheme.create_button_theme()
	
	animated_background.stop()
	animated_background.frame = 0
	
	play_button.pressed.connect(_on_play_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	restart_confirmation.confirmed.connect(_start_new_game_in_selected_slot)
	for index in slot_buttons.size():
		var button := slot_buttons[index]
		button.toggle_mode = true
		button.pressed.connect(_on_slot_selected.bind(index + 1))
	selected_slot = SaveManager.active_slot
	refresh_save_slots()


func _on_play_pressed() -> void:
	if SaveManager.has_save(selected_slot):
		restart_confirmation.dialog_text = (
			"Slot %d already contains a saved game. This will erase it and begin a new run."
			% selected_slot
		)
		restart_confirmation.popup_centered(Vector2i(540, 220))
		return
	_start_new_game_in_selected_slot()


func _start_new_game_in_selected_slot() -> void:
	if SaveManager.has_save(selected_slot) and not SaveManager.delete_save(selected_slot):
		save_status_label.text = SaveManager.last_status_message
		return
	SaveManager.set_active_slot(selected_slot)
	SeedManager.start_new_run()
	get_tree().change_scene_to_file("res://Scenes/AsteroidMining.tscn")


func _on_continue_pressed() -> void:
	if SaveManager.load_game(selected_slot):
		return
	save_status_label.text = SaveManager.last_status_message
	refresh_save_slots()


func _on_slot_selected(slot: int) -> void:
	selected_slot = slot
	SaveManager.set_active_slot(slot)
	refresh_save_slots()


func refresh_save_slots() -> void:
	for index in slot_buttons.size():
		var slot := index + 1
		var metadata := SaveManager.get_slot_metadata(slot)
		var button := slot_buttons[index]
		button.set_pressed_no_signal(slot == selected_slot)
		button.text = "Slot %d\n%s" % [slot, "Saved" if bool(metadata["occupied"]) else "Empty"]
	var selected_metadata := SaveManager.get_slot_metadata(selected_slot)
	var occupied := bool(selected_metadata["occupied"])
	continue_button.disabled = not occupied
	continue_button.text = "Continue Slot %d" % selected_slot
	play_button.text = ("Restart Slot %d" if occupied else "New Game in Slot %d") % selected_slot
	if occupied:
		var tutorial_state := str(selected_metadata.get("tutorial_state", "legacy")).replace("_", " ").capitalize()
		slot_details_label.text = "%s\nTutorial: %s" % [selected_metadata["label"], tutorial_state]
	else:
		slot_details_label.text = "Slot %d is empty and ready for a new game." % selected_slot


func _on_quit_pressed() -> void:
	get_tree().quit()
	
