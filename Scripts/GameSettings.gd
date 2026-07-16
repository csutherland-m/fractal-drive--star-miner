extends Node

signal setting_changed(setting_id: StringName, value: Variant)

const SETTINGS_PATH := "user://game_settings.cfg"
const SETTINGS_SECTION := "gameplay"
const MOUSE_DIRECTED_E_SETTING := &"mouse_directed_e_enabled"

var mouse_directed_e_enabled: bool = false


func _ready() -> void:
	load_settings()


func set_mouse_directed_e_enabled(enabled: bool) -> void:
	if mouse_directed_e_enabled == enabled:
		return
	mouse_directed_e_enabled = enabled
	save_settings()
	setting_changed.emit(MOUSE_DIRECTED_E_SETTING, enabled)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	mouse_directed_e_enabled = bool(
		config.get_value(SETTINGS_SECTION, str(MOUSE_DIRECTED_E_SETTING), false)
	)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(
		SETTINGS_SECTION,
		str(MOUSE_DIRECTED_E_SETTING),
		mouse_directed_e_enabled
	)
	var save_error := config.save(SETTINGS_PATH)
	if save_error != OK:
		push_warning("Could not save game settings: error %d" % save_error)
