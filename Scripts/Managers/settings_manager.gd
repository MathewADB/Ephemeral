extends Node

# =============================================================================
# SETTINGS MANAGER — Persistent user preferences
# Autoload name: SettingsManager
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────

const SETTINGS_PATH := "user://settings.json"

## Add any new audio bus names here; they are automatically muted/unmuted.
const AUDIO_BUSES := ["Music", "SFX", "Ambient", "UI"]

# ─────────────────────────────────────────────────────────────────────────────
# SETTINGS
# ─────────────────────────────────────────────────────────────────────────────

var selected_language: String = "EN"
var fullscreen:        bool   = false

## Per-bus enabled flags. Access via `music_enabled`, `sfx_enabled`, etc.
var music_enabled:   bool = true
var sfx_enabled:     bool = true
var ambient_enabled: bool = true
var ui_enabled:      bool = true

## Master volume per bus (0.0 – 1.0).  Default 1.0 = full volume.
var music_volume:   float = 1.0
var sfx_volume:     float = 1.0
var ambient_volume: float = 1.0
var ui_volume:      float = 1.0

# ─────────────────────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────────────────────

signal settings_changed

# ─────────────────────────────────────────────────────────────────────────────
# APPLY
# ─────────────────────────────────────────────────────────────────────────────

func apply_settings() -> void:
	TranslationServer.set_locale(selected_language)

	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN \
		if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

	_apply_bus("Music",   music_enabled,   music_volume)
	_apply_bus("SFX",     sfx_enabled,     sfx_volume)
	_apply_bus("Ambient", ambient_enabled, ambient_volume)
	_apply_bus("UI",      ui_enabled,      ui_volume)

	settings_changed.emit()


## Toggle a single setting and immediately apply + save.
func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply_settings()
	save_settings()


func set_bus_enabled(bus: String, value: bool) -> void:
	match bus:
		"Music":   music_enabled   = value
		"SFX":     sfx_enabled     = value
		"Ambient": ambient_enabled = value
		"UI":      ui_enabled      = value
	_apply_bus(bus, value, _get_bus_volume(bus))
	settings_changed.emit()
	save_settings()


func set_bus_volume(bus: String, value: float) -> void:
	match bus:
		"Music":   music_volume   = value
		"SFX":     sfx_volume     = value
		"Ambient": ambient_volume = value
		"UI":      ui_volume      = value
	_apply_bus(bus, _get_bus_enabled(bus), value)
	settings_changed.emit()
	save_settings()


func set_language(lang: String) -> void:
	selected_language = lang
	TranslationServer.set_locale(lang)
	settings_changed.emit()
	save_settings()

# ─────────────────────────────────────────────────────────────────────────────
# SAVE / LOAD
# ─────────────────────────────────────────────────────────────────────────────

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SettingsManager: Cannot write settings file.")
		return

	file.store_string(JSON.stringify({
		"selected_language": selected_language,
		"fullscreen":        fullscreen,
		"music_enabled":     music_enabled,
		"sfx_enabled":       sfx_enabled,
		"ambient_enabled":   ambient_enabled,
		"ui_enabled":        ui_enabled,
		"music_volume":      music_volume,
		"sfx_volume":        sfx_volume,
		"ambient_volume":    ambient_volume,
		"ui_volume":         ui_volume,
	}, "\t"))
	file.close()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return

	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY:
		push_warning("SettingsManager: Settings file corrupt, using defaults.")
		return

	selected_language = data.get("selected_language", "EN")
	fullscreen        = data.get("fullscreen",        false)
	music_enabled     = data.get("music_enabled",     true)
	sfx_enabled       = data.get("sfx_enabled",       true)
	ambient_enabled   = data.get("ambient_enabled",   true)
	ui_enabled        = data.get("ui_enabled",        true)
	music_volume      = data.get("music_volume",      1.0)
	sfx_volume        = data.get("sfx_volume",        1.0)
	ambient_volume    = data.get("ambient_volume",    1.0)
	ui_volume         = data.get("ui_volume",         1.0)

# ─────────────────────────────────────────────────────────────────────────────
# PRIVATE HELPERS
# ─────────────────────────────────────────────────────────────────────────────

func _apply_bus(bus_name: String, enabled: bool, volume: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		push_warning("SettingsManager: Audio bus '%s' not found." % bus_name)
		return
	AudioServer.set_bus_mute(idx, not enabled)
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(volume, 0.0, 1.0)))


func _get_bus_enabled(bus: String) -> bool:
	match bus:
		"Music":   return music_enabled
		"SFX":     return sfx_enabled
		"Ambient": return ambient_enabled
		"UI":      return ui_enabled
	return true


func _get_bus_volume(bus: String) -> float:
	match bus:
		"Music":   return music_volume
		"SFX":     return sfx_volume
		"Ambient": return ambient_volume
		"UI":      return ui_volume
	return 1.0
