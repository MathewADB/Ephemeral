extends Node

# ================= CONFIG =================

const SAVE_PATH_TEMPLATE := "user://save_slot_%d.json"
const MAX_SLOTS := 4

# ================= SIGNALS =================

signal save_finished(slot)
signal load_finished(slot, data)

# ================= INTERNAL =================

func _get_path(slot: int) -> String:
	return SAVE_PATH_TEMPLATE % slot


# ================= SAVE =================

func save(slot: int, data: Dictionary) -> void:
	var path = _get_path(slot)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to save slot %d" % slot)
		return
	
	file.store_string(JSON.stringify(data))
	file.close()

	save_finished.emit(slot)


# ================= LOAD =================

func load(slot: int) -> Dictionary:
	var path = _get_path(slot)

	if not FileAccess.file_exists(path):
		return {}
	
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save slot %d" % slot)
		return {}
	
	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)

	if typeof(data) != TYPE_DICTIONARY:
		push_error("Save slot %d corrupted" % slot)
		return {}

	load_finished.emit(slot, data)
	return data


# ================= DELETE =================

func delete_save(slot: int) -> void:
	var path = _get_path(slot)

	if FileAccess.file_exists(path):
		var dir := DirAccess.open("user://")
		if dir:
			dir.remove(path.get_file())


# ================= UTILS =================

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_get_path(slot))


func get_all_slots() -> Array:
	var result := []
	for i in range(MAX_SLOTS):
		result.append(slot_exists(i))
	return result


func get_slot_meta(slot: int) -> Dictionary:
	var data = self.load(slot)
	if data.is_empty():
		return {}

	return data.get("meta", {})
