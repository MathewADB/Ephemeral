extends Node

# ================= CONFIG =================

const SAVE_PATH := "user://save_game.json"

# ================= SIGNALS =================

signal save_finished
signal load_finished(data)

# ================= SAVE =================

func save(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing")
		return
	
	file.store_string(JSON.stringify(data))
	file.close()
	
	save_finished.emit()


# ================= LOAD =================

func load() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading")
		return {}
	
	var content := file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save file corrupted")
		return {}
	
	load_finished.emit(data)
	return data


# ================= DELETE =================

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			dir.remove("save_game.json")
		else:
			push_error("Failed to access user directory")


# ================= UTILS =================

func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
