extends Node

signal save_completed(success: bool, message: String)

const SAVE_VERSION := 1
const GENERATOR_VERSION := 1
const SAVE_PATH := "user://star_miner_save.json"

var pending_scene_path: String = ""
var pending_scene_state: Dictionary = {}
var last_status_message: String = ""


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(scene_node: Node) -> bool:
	if scene_node == null or not scene_node.has_method("create_save_data"):
		return finish_save(false, "This scene does not support saving yet.")
	var scene_path := scene_node.scene_file_path
	if scene_path.is_empty():
		return finish_save(false, "Could not identify the current scene.")

	var payload := create_save_payload(scene_path, scene_node.create_save_data())
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return finish_save(false, "Could not open the save file (error %d)." % FileAccess.get_open_error())
	file.store_string(JSON.stringify(payload))
	file.close()
	return finish_save(true, "Game saved.")


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


func load_game() -> bool:
	var payload := read_save_payload()
	if payload.is_empty():
		return false
	if not apply_save_payload(payload):
		return false
	get_tree().change_scene_to_file(pending_scene_path)
	return true


func read_save_payload() -> Dictionary:
	if not has_save():
		last_status_message = "No saved game found."
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		last_status_message = "Could not open the save file."
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		last_status_message = "The save file is invalid."
		return {}
	return migrate_save_data(parsed)


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
	# Future migrations are applied sequentially here before SAVE_VERSION increases.
	return payload.duplicate(true)


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
