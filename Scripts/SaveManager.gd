extends Node

signal save_completed(success: bool, message: String)

const SAVE_VERSION := 2
const GENERATOR_VERSION := 2
const SLOT_COUNT := 3
const LEGACY_SAVE_PATH := "user://star_miner_save.json"
# Compatibility alias for code or test tools that still inspect the old path.
const SAVE_PATH := LEGACY_SAVE_PATH

var pending_scene_path: String = ""
var pending_scene_state: Dictionary = {}
var last_status_message: String = ""
var active_slot: int = 1


func _ready() -> void:
	migrate_legacy_save_to_slot_one()


func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT


func get_save_path(slot: int) -> String:
	return "user://star_miner_save_slot_%d.json" % clampi(slot, 1, SLOT_COUNT)


func set_active_slot(slot: int) -> bool:
	if not is_valid_slot(slot):
		last_status_message = "Invalid save slot: %d." % slot
		return false
	active_slot = slot
	return true


func has_save(slot: int = active_slot) -> bool:
	return is_valid_slot(slot) and FileAccess.file_exists(get_save_path(slot))


func has_any_save() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if has_save(slot):
			return true
	return false


func delete_save(slot: int) -> bool:
	if not is_valid_slot(slot):
		last_status_message = "Invalid save slot: %d." % slot
		return false
	if not has_save(slot):
		return true
	var error := DirAccess.remove_absolute(ProjectSettings.globalize_path(get_save_path(slot)))
	if error != OK:
		last_status_message = "Could not clear Slot %d (error %d)." % [slot, error]
		return false
	last_status_message = "Slot %d cleared." % slot
	return true


func save_game(scene_node: Node, slot: int = active_slot) -> bool:
	if not set_active_slot(slot):
		return finish_save(false, last_status_message)
	if scene_node == null or not scene_node.has_method("create_save_data"):
		return finish_save(false, "Slot %d: this scene does not support saving yet." % slot)
	var scene_path := scene_node.scene_file_path
	if scene_path.is_empty():
		return finish_save(false, "Could not identify the current scene.")

	var payload := create_save_payload(scene_path, scene_node.create_save_data())
	var file := FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		return finish_save(false, "Could not open the save file (error %d)." % FileAccess.get_open_error())
	file.store_string(JSON.stringify(payload))
	file.close()
	return finish_save(true, "Game saved to Slot %d." % slot)


func create_save_payload(scene_path: String, scene_state: Dictionary) -> Dictionary:
	var seed_manager := get_seed_manager()
	var run_state: Dictionary = {}
	if seed_manager != null and seed_manager.has_method("create_save_data"):
		run_state = seed_manager.create_save_data()
	return {
		"save_version": SAVE_VERSION,
		"generator_version": GENERATOR_VERSION,
		"saved_unix_time": int(Time.get_unix_time_from_system()),
		"scene_path": scene_path,
		"run_state": run_state.duplicate(true),
		"scene_state": scene_state.duplicate(true),
	}


func load_game(slot: int = active_slot) -> bool:
	if not is_valid_slot(slot):
		last_status_message = "Invalid save slot: %d." % slot
		return false
	var payload := read_save_payload(slot)
	if payload.is_empty():
		return false
	if not apply_save_payload(payload):
		return false
	active_slot = slot
	get_tree().change_scene_to_file(pending_scene_path)
	return true


func read_save_payload(slot: int = active_slot) -> Dictionary:
	if not has_save(slot):
		last_status_message = "Slot %d is empty." % slot
		return {}
	var file := FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file == null:
		last_status_message = "Could not open Slot %d." % slot
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		last_status_message = "The save file is invalid."
		return {}
	return migrate_save_data(parsed)


func get_slot_metadata(slot: int) -> Dictionary:
	var metadata := {
		"slot": slot,
		"occupied": false,
		"label": "Slot %d — Empty" % slot,
		"saved_unix_time": 0,
		"tutorial_state": "",
		"story_id": "",
		"scene_path": "",
	}
	if not has_save(slot):
		return metadata
	var file := FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file == null:
		metadata["label"] = "Slot %d — Unreadable" % slot
		return metadata
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		metadata["label"] = "Slot %d — Invalid Save" % slot
		return metadata
	var payload: Dictionary = parsed
	var run_state: Dictionary = payload.get("run_state", {}) if payload.get("run_state", {}) is Dictionary else {}
	var saved_time := int(payload.get("saved_unix_time", 0))
	metadata["occupied"] = true
	metadata["saved_unix_time"] = saved_time
	metadata["tutorial_state"] = str(run_state.get("tutorial_state", "legacy"))
	metadata["story_id"] = str(run_state.get("player_story_id", "unselected"))
	metadata["scene_path"] = str(payload.get("scene_path", ""))
	metadata["label"] = "Slot %d — %s" % [slot, format_saved_time(saved_time)]
	return metadata


func format_saved_time(unix_time: int) -> String:
	if unix_time <= 0:
		return "Saved Game"
	var date := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d/%04d  %02d:%02d" % [
		int(date.get("month", 0)),
		int(date.get("day", 0)),
		int(date.get("year", 0)),
		int(date.get("hour", 0)),
		int(date.get("minute", 0)),
	]


func migrate_legacy_save_to_slot_one() -> void:
	if has_save(1) or not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	var source := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if source == null:
		return
	var contents := source.get_as_text()
	source.close()
	var destination := FileAccess.open(get_save_path(1), FileAccess.WRITE)
	if destination == null:
		return
	destination.store_string(contents)
	destination.close()
	# The copy is now safely in Slot 1; remove the legacy source so clearing or
	# restarting Slot 1 later cannot resurrect an obsolete save.
	if FileAccess.file_exists(get_save_path(1)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))


func apply_save_payload(payload: Dictionary) -> bool:
	var migrated := migrate_save_data(payload)
	if migrated.is_empty():
		return false
	var scene_path := str(migrated.get("scene_path", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		last_status_message = "The saved scene is unavailable."
		return false
	var run_state: Variant = migrated.get("run_state", {})
	var scene_state: Variant = migrated.get("scene_state", {})
	if not run_state is Dictionary or not scene_state is Dictionary:
		last_status_message = "The save file contains invalid state data."
		return false
	var seed_manager := get_seed_manager()
	if seed_manager == null or not seed_manager.has_method("apply_save_data"):
		last_status_message = "The run state manager is unavailable."
		return false
	seed_manager.apply_save_data(run_state)
	pending_scene_path = scene_path
	pending_scene_state = scene_state.duplicate(true)
	last_status_message = "Save loaded."
	return true


func migrate_save_data(payload: Dictionary) -> Dictionary:
	var version := int(payload.get("save_version", 0))
	if version <= 0 or version > SAVE_VERSION:
		last_status_message = "Unsupported save version: %d." % version
		return {}
	var migrated := payload.duplicate(true)
	if version == 1:
		var run_state: Dictionary = migrated.get("run_state", {}).duplicate(true)
		run_state["tutorial_schema_version"] = 1
		run_state["player_story_id"] = "unselected"
		run_state["tutorial_state"] = "skipped"
		run_state["tutorial_step_id"] = ""
		run_state["tutorial_dialogue_node_id"] = ""
		run_state["completed_tutorial_step_ids"] = []
		migrated["run_state"] = run_state
		migrated["save_version"] = 2
	return migrated


func consume_pending_scene_state(scene_path: String) -> Dictionary:
	if pending_scene_path != scene_path:
		return {}
	var state := pending_scene_state.duplicate(true)
	pending_scene_path = ""
	pending_scene_state.clear()
	return state


func finish_save(success: bool, message: String) -> bool:
	last_status_message = message
	save_completed.emit(success, message)
	return success


func get_seed_manager() -> Node:
	return get_node_or_null("/root/SeedManager")
