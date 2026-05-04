extends Node

# ================= CONSTANTS =================

const SETTINGS_PATH := "user://settings.json"

# ================= SETTINGS =================

var selected_language: String = "EN"
var fullscreen: bool = false

# Audio (true = enabled)
var music_enabled: bool = true
var sfx_enabled: bool = true
var ambient_enabled: bool = true
var ui_enabled: bool = true

# ================= SIGNALS =================

signal settings_changed

# ================= CORE =================

func apply_settings():
	# --- Language ---
	TranslationServer.set_locale(selected_language)

	# --- Fullscreen ---
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# --- Audio ---
	_set_bus("Music", music_enabled)
	_set_bus("SFX", sfx_enabled)
	_set_bus("Ambient", ambient_enabled)
	_set_bus("UI", ui_enabled)

	settings_changed.emit()

# ================= AUDIO =================

func _set_bus(bus_name: String, enabled: bool):
	var index = AudioServer.get_bus_index(bus_name)
	if index != -1:
		AudioServer.set_bus_mute(index, not enabled)

# ================= SAVE / LOAD =================

func save_settings():
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"selected_language": selected_language,
			"fullscreen": fullscreen,
			"music_enabled": music_enabled,
			"sfx_enabled": sfx_enabled,
			"ambient_enabled": ambient_enabled,
			"ui_enabled": ui_enabled
		}))
		file.close()

func load_settings():
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		return

	selected_language = data.get("selected_language", "EN")
	fullscreen = data.get("fullscreen", false)
	music_enabled = data.get("music_enabled", true)
	sfx_enabled = data.get("sfx_enabled", true)
	ambient_enabled = data.get("ambient_enabled", true)
	ui_enabled = data.get("ui_enabled", true)
