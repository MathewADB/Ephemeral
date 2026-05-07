extends Node

# =============================================================================
# SAVE MANAGER — File I/O for save slots, with backup & version checking
# Autoload name: SaveManager
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────

const SAVE_PATH_TEMPLATE   := "user://save_slot_%d.json"
const BACKUP_PATH_TEMPLATE := "user://save_slot_%d.bak.json"
const MAX_SLOTS            := 4

## Increment this when the save format changes to allow migration logic.
const SAVE_VERSION         := 1

# ─────────────────────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────────────────────

signal save_started(slot: int)
signal save_finished(slot: int)
signal load_finished(slot: int)
signal save_failed(slot: int, reason: String)
signal load_failed(slot: int, reason: String)

# ─────────────────────────────────────────────────────────────────────────────
# SAVE
# ─────────────────────────────────────────────────────────────────────────────

## Saves `data` to `slot`.  Creates a .bak backup of the previous save first.
func save(slot: int, data: Dictionary) -> void:
	assert(slot >= 0 and slot < MAX_SLOTS, "Invalid save slot: %d" % slot)

	save_started.emit(slot)

	var path := _get_path(slot)

	# Rotate existing save to backup before overwriting
	if FileAccess.file_exists(path):
		_copy_file(path, _get_backup_path(slot))

	# Stamp version
	data["_version"] = SAVE_VERSION

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var msg := "Cannot open '%s' for writing (error %d)" % [path, FileAccess.get_open_error()]
		push_error(msg)
		save_failed.emit(slot, msg)
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	save_finished.emit(slot)


# ─────────────────────────────────────────────────────────────────────────────
# LOAD
# ─────────────────────────────────────────────────────────────────────────────

## Loads and returns the save dictionary for `slot`, or an empty dict on failure.
## Automatically tries the .bak backup if the primary file is corrupted.
func load(slot: int) -> Dictionary:
	assert(slot >= 0 and slot < MAX_SLOTS, "Invalid save slot: %d" % slot)

	var data := _read_json(_get_path(slot))
	if data.is_empty():
		# Primary corrupt — try backup
		push_warning("SaveManager: Primary save slot %d missing/corrupt, trying backup." % slot)
		data = _read_json(_get_backup_path(slot))
		if data.is_empty():
			var msg := "Both save and backup for slot %d are empty/corrupt." % slot
			push_error(msg)
			load_failed.emit(slot, msg)
			return {}

	# Future: call _migrate(data) here if data["_version"] < SAVE_VERSION
	load_finished.emit(slot)
	return data


# ─────────────────────────────────────────────────────────────────────────────
# DELETE
# ─────────────────────────────────────────────────────────────────────────────

## Deletes the primary save and backup for `slot`.
func delete_save(slot: int) -> void:
	assert(slot >= 0 and slot < MAX_SLOTS, "Invalid save slot: %d" % slot)
	_delete_file(_get_path(slot))
	_delete_file(_get_backup_path(slot))

# ─────────────────────────────────────────────────────────────────────────────
# QUERIES
# ─────────────────────────────────────────────────────────────────────────────

func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(_get_path(slot))


## Returns an array of booleans, one per slot — true if a save exists.
func get_all_slots() -> Array[bool]:
	var result: Array[bool] = []
	for i in MAX_SLOTS:
		result.append(slot_exists(i))
	return result


## Returns the "meta" block from a save (level, playtime, last_played),
## without loading the full save. Returns {} if no save exists.
func get_slot_meta(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var data := _read_json(_get_path(slot))
	return data.get("meta", {})

# ─────────────────────────────────────────────────────────────────────────────
# PRIVATE HELPERS
# ─────────────────────────────────────────────────────────────────────────────

func _get_path(slot: int) -> String:
	return SAVE_PATH_TEMPLATE % slot


func _get_backup_path(slot: int) -> String:
	return BACKUP_PATH_TEMPLATE % slot


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("SaveManager: Cannot read '%s'." % path)
		return {}

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("SaveManager: '%s' is not a valid JSON object." % path)
		return {}

	return parsed


func _copy_file(src: String, dst: String) -> void:
	var src_file := FileAccess.open(src, FileAccess.READ)
	if src_file == null:
		return
	var content := src_file.get_as_text()
	src_file.close()

	var dst_file := FileAccess.open(dst, FileAccess.WRITE)
	if dst_file == null:
		return
	dst_file.store_string(content)
	dst_file.close()


func _delete_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var dir := DirAccess.open("user://")
	if dir:
		dir.remove(path.get_file())
