extends Node

# =============================================================================
# TIME MANAGER — Game clock, day/night cycle, smooth lighting
# Autoload name: TimeManager
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────

## Fraction of the day at which dawn begins (0 = midnight, 0.25 = 6 am)
const DAWN_START  := 0.22
## Fraction of the day at which dusk begins
const DUSK_START  := 0.72

# ─────────────────────────────────────────────────────────────────────────────
# SETTINGS
# ─────────────────────────────────────────────────────────────────────────────

## Real seconds per in-game day (1200 s = 20 real minutes).
var seconds_per_day: float = 1200.0

## How many in-game seconds pass per real second.
var time_scale: float = 1.0

## Set to false to freeze time (e.g. inside menus or cutscenes).
var time_running: bool = true

# ─────────────────────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────────────────────

var game_seconds: float = 0.0

# ─────────────────────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────────────────────

## Emitted every frame while time is running.
signal time_updated
## Emitted once at the start of each new in-game day.
signal new_day(day: int)

# ─────────────────────────────────────────────────────────────────────────────
# INTERNAL
# ─────────────────────────────────────────────────────────────────────────────

## The day index from the last frame — used to detect day rollovers.
var _last_day: int = -1

# ─────────────────────────────────────────────────────────────────────────────
# PROCESS
# ─────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not time_running:
		return

	game_seconds += delta * time_scale
	time_updated.emit()

	# Detect new-day rollover
	var current_day := get_day()
	if current_day != _last_day:
		_last_day = current_day
		new_day.emit(current_day)

# ─────────────────────────────────────────────────────────────────────────────
# CORE QUERIES
# ─────────────────────────────────────────────────────────────────────────────

## Progress through the current day as a 0–1 value.
## 0 = start of day (midnight), 0.5 = noon, 1 = next midnight.
func get_day_progress() -> float:
	return fmod(game_seconds, seconds_per_day) / seconds_per_day


## Current in-game day number (0-indexed).
func get_day() -> int:
	return int(game_seconds / seconds_per_day)


## Human-readable time string, e.g. "06:30".
func get_time_string() -> String:
	var t     := get_day_progress()
	var total := int(t * 24.0 * 60.0)          # total minutes in the day
	@warning_ignore("integer_division")
	var hours := total / 60
	var mins  := total % 60
	return "%02d:%02d" % [hours, mins]

# ─────────────────────────────────────────────────────────────────────────────
# LIGHTING HELPERS
# ─────────────────────────────────────────────────────────────────────────────

## Returns 0.0 (full day) → 1.0 (full night) using a smooth sine curve.
## Replaces the old formula with clearer dawn/dusk fade zones.
func get_night_amount() -> float:
	var t := get_day_progress()

	# Remap t so dawn/dusk fall at the configured fractions, then apply cosine.
	# Values outside [DAWN_START, DUSK_START] are night; inside are day.
	var cycle := cos((t - DAWN_START) / (DUSK_START - DAWN_START) * PI)
	# cycle goes from -1 (start of dawn) → +1 (midday) → -1 (end of dusk)
	var daylight := (cycle + 1.0) * 0.5   # remap to 0..1
	return 1.0 - pow(daylight, 1.3)        # slight darkening curve at dusk/dawn


func is_night() -> bool:
	return get_night_amount() > 0.5


## Colour suitable for a sky or directional light modulate.
## dawn_color / day_color / dusk_color / night_color can be overridden.
var dawn_color  := Color(0.941, 0.702, 0.584, 1.0)
var day_color   := Color(1.0, 0.98, 0.961, 0.0)
var dusk_color  := Color(0.808, 0.549, 0.51, 1.0)
var night_color := Color(0.0, 0.0, 0.098, 1.0)

func get_sky_color() -> Color:
	var t := get_day_progress()

	if t < DAWN_START:
		# Night → dawn transition in the last portion of darkness
		var fade := t / DAWN_START
		return night_color.lerp(dawn_color, fade)
	elif t < 0.35:
		# Dawn → day
		var fade := (t - DAWN_START) / (0.35 - DAWN_START)
		return dawn_color.lerp(day_color, fade)
	elif t < DUSK_START:
		# Full day
		return day_color
	elif t < 0.82:
		# Day → dusk
		var fade := (t - DUSK_START) / (0.82 - DUSK_START)
		return day_color.lerp(dusk_color, fade)
	else:
		# Dusk → night
		var fade := (t - 0.82) / (1.0 - 0.82)
		return dusk_color.lerp(night_color, fade)

# ─────────────────────────────────────────────────────────────────────────────
# UI SETUP  (called from UIManager._ready)
# ─────────────────────────────────────────────────────────────────────────────

## Stores a reference to the three day/night UI nodes owned by UIManager.
## Expected node types:
##   sky_rect    — ColorRect  (full-screen sky tint / background)
##   sun_moon    — Sprite2D   (animated sun/moon icon, frame 0 = moon, 1 = sun)
##   clock_label — Label      (optional, shows HH:MM)
var _world_modulate: CanvasModulate = null
var _background: ColorRect
var _sun_moon:    Sprite2D   = null
var _clock_label: Label      = null

func setup(
	sun_moon: Sprite2D,
	clock_label: Label = null
) -> void:
	_sun_moon = sun_moon
	_clock_label = clock_label

	time_updated.connect(_update_ui)

func register_world_modulate(modulate: CanvasModulate) -> void:
	_world_modulate = modulate

	if _world_modulate:
		_world_modulate.color = get_world_light_color()
		
var day_light   := Color(1.0, 1.0, 1.0)
var dusk_light  := Color(0.7, 0.75, 0.9)
var night_light := Color(0.2, 0.25, 0.35)

func get_world_light_color() -> Color:
	var night := get_night_amount()

	if night < 0.5:
		return day_light.lerp(dusk_light, night * 2.0)

	return dusk_light.lerp(
		night_light,
		(night - 0.5) * 2.0
	)

var sky_day   := Color("#99ccff")
var sky_night := Color("#1b263b")

func get_background_color() -> Color:
	var night := get_night_amount()

	# Smoothly darken the sky while keeping the same hue family
	return sky_day.lerp(sky_night, night)
		
	
func _update_ui() -> void:
	if _world_modulate:
		_world_modulate.color = get_world_light_color()
	
	if _background:
		_background.color = get_background_color()
		
	if _sun_moon:
		# Frame 0 = moon, Frame 1 = sun
		_sun_moon.frame = 0 if is_night() else 1

		# Rotate the sun/moon across the sky (0° at dawn, 180° at dusk)
		var t := get_day_progress()
		_sun_moon.rotation = t * TAU

	if _clock_label:
		_clock_label.text = get_time_string()
