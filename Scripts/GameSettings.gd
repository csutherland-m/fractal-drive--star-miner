extends Node

signal setting_changed(setting_id: StringName, value: Variant)

const SETTINGS_PATH := "user://game_settings.cfg"
const SETTINGS_SECTION := "gameplay"
const MOUSE_DIRECTED_E_SETTING := &"mouse_directed_e_enabled"
const MENU_BACK_KEY_SETTING := &"menu_back_keycode"
const MENU_BACK_BINDING_VERSION_SETTING := &"menu_back_binding_version"
const MENU_BACK_ACTION := &"menu_back"
const MENU_BACK_BINDING_VERSION := 2

var mouse_directed_e_enabled: bool = false
var menu_back_keycode: Key = KEY_PAUSE


func _ready() -> void:
	load_settings()
	apply_menu_back_input()


func set_mouse_directed_e_enabled(enabled: bool) -> void:
	if mouse_directed_e_enabled == enabled:
		return
	mouse_directed_e_enabled = enabled
	save_settings()
	setting_changed.emit(MOUSE_DIRECTED_E_SETTING, enabled)


func set_menu_back_keycode(keycode: Key) -> void:
	if keycode == KEY_NONE:
		return
	menu_back_keycode = keycode
	apply_menu_back_input()
	save_settings()
	setting_changed.emit(MENU_BACK_KEY_SETTING, int(keycode))


func apply_menu_back_input() -> void:
	if not InputMap.has_action(MENU_BACK_ACTION):
		InputMap.add_action(MENU_BACK_ACTION)
	InputMap.action_erase_events(MENU_BACK_ACTION)
	var event := InputEventKey.new()
	event.physical_keycode = menu_back_keycode
	InputMap.action_add_event(MENU_BACK_ACTION, event)


func get_menu_back_key_text() -> String:
	return OS.get_keycode_string(menu_back_keycode)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	mouse_directed_e_enabled = bool(
		config.get_value(SETTINGS_SECTION, str(MOUSE_DIRECTED_E_SETTING), false)
	)
	menu_back_keycode = int(
		config.get_value(SETTINGS_SECTION, str(MENU_BACK_KEY_SETTING), int(KEY_PAUSE))
	) as Key
	var binding_version := int(
		config.get_value(SETTINGS_SECTION, str(MENU_BACK_BINDING_VERSION_SETTING), 1)
	)
	# Escape used to be the default. Migrate that old default so Escape can now
	# consistently close the entire interface while Pause/Break steps back once.
	if binding_version < MENU_BACK_BINDING_VERSION and menu_back_keycode == KEY_ESCAPE:
		menu_back_keycode = KEY_PAUSE
		save_settings()


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(
		SETTINGS_SECTION,
		str(MOUSE_DIRECTED_E_SETTING),
		mouse_directed_e_enabled
	)
	config.set_value(
		SETTINGS_SECTION,
		str(MENU_BACK_KEY_SETTING),
		int(menu_back_keycode)
	)
	config.set_value(
		SETTINGS_SECTION,
		str(MENU_BACK_BINDING_VERSION_SETTING),
		MENU_BACK_BINDING_VERSION
	)
	var save_error := config.save(SETTINGS_PATH)
	if save_error != OK:
		push_warning("Could not save game settings: error %d" % save_error)
