extends Node

# =============================================================================
# MANAGER — Central game state & coordinator autoload
# Autoload name: Manager
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────

const DEFAULT_ROOM_SCENE   := "res://Scenes/Locations/Mushroom Biome/Tutorial.tscn"
const DEFAULT_SPAWN_ROOM   := "res://Scenes/Locations/Mushroom Biome/Home.tscn"
const DEFAULT_SPAWN_POSITION := Vector2(618, 497)

const BASE_STATS := {
	"player_mobility":    1.0,
	"light_level":        0,
	"hide_unlocked":      false,
	"base_extra_jumps":   0,
	"mining_tier":        0,
	"mining_speed_level": 1,
	"pillar_interaction": false,
	"map_unlocked":       false,
}

const DEFAULT_ROOM_POSITIONS: Dictionary = {
	"res://Scenes/Locations/Mushroom Biome/Tutorial.tscn"  : Vector2(9999, 9999),
	"res://Scenes/Locations/Mushroom Biome/Tutorial2.tscn" : Vector2(1, 0),
	"res://Scenes/Locations/Mushroom Biome/shop.tscn"      : Vector2(2, 0),
	"res://Scenes/Locations/Mushroom Biome/Home.tscn"      : Vector2(2, 1),
	"res://Scenes/Locations/Mushroom Biome/The Plain.tscn" : Vector2(3, 1),
}

const ROOM_TYPES: Dictionary = {
	"res://Scenes/Locations/Mushroom Biome/Tutorial.tscn"  : "tutorial",
	"res://Scenes/Locations/Mushroom Biome/Tutorial2.tscn" : "tutorial",
	"res://Scenes/Locations/Mushroom Biome/shop.tscn"      : "shop",
	"res://Scenes/Locations/Mushroom Biome/Home.tscn"      : "hub",
	"res://Scenes/Locations/Mushroom Biome/The Plain.tscn" : "mushroom",
}

# ─────────────────────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────────────────────

signal night_changed(is_night: bool)
signal level_changed(level: int)
signal xp_changed(current_xp: float, required_xp: float)
signal xp_gained(amount: float)
signal skill_points_changed(points: int)
signal inventory_changed
signal upgrades_changed
signal map_updated
signal death_count_changed(count: int)
@warning_ignore("unused_signal")
signal game_paused(paused: bool)

# ─────────────────────────────────────────────────────────────────────────────
# AUTOSAVE
# ─────────────────────────────────────────────────────────────────────────────

var autosave_interval: float = 300.0
var _autosave_timer:   float = 0.0
var current_slot:      int   = 0

# ─────────────────────────────────────────────────────────────────────────────
# PLAYER REFERENCE & SPAWN
# ─────────────────────────────────────────────────────────────────────────────

var player: CharacterBody2D = null

var activate_spawn:    bool    = false
var current_room_scene: String = DEFAULT_ROOM_SCENE
var spawn_room_scene:   String = DEFAULT_SPAWN_ROOM
var spawn_location:     Vector2 = DEFAULT_SPAWN_POSITION
var respawn_room_scene: String  = DEFAULT_SPAWN_ROOM
var respawn_location:   Vector2 = DEFAULT_SPAWN_POSITION
var loaded_health:      int     = 100

# ─────────────────────────────────────────────────────────────────────────────
# PLAYER STATS  (reset to BASE_STATS on new game / upgrade recalculation)
# ─────────────────────────────────────────────────────────────────────────────

var player_mobility:    float = BASE_STATS["player_mobility"]
var light_level:        int   = BASE_STATS["light_level"]
var hide_unlocked:      bool  = BASE_STATS["hide_unlocked"]
var base_extra_jumps:   int   = BASE_STATS["base_extra_jumps"]
var mining_tier:        int   = BASE_STATS["mining_tier"]
var mining_speed_level: int   = BASE_STATS["mining_speed_level"]
var pillar_interaction: bool  = BASE_STATS["pillar_interaction"]
var map_unlocked:       bool  = BASE_STATS["map_unlocked"]

# ─────────────────────────────────────────────────────────────────────────────
# LEVELING
# ─────────────────────────────────────────────────────────────────────────────

var level:        int   = 1
var current_xp:   float = 0.0
var skill_points: int   = 0

# ─────────────────────────────────────────────────────────────────────────────
# WORLD STATE
# ─────────────────────────────────────────────────────────────────────────────

var visited_rooms:     Array      = []
var collected_objects: Dictionary = {}
var resource_nodes:    Dictionary = {}
var room_positions:    Dictionary = DEFAULT_ROOM_POSITIONS.duplicate(true)

# ─────────────────────────────────────────────────────────────────────────────
# PROGRESS / END GAME
# ─────────────────────────────────────────────────────────────────────────────

var death_count:    int  = 0
var end_triggered:  bool = false
var lore_goal:      int  = 3

## Time-of-day offset when a new game starts (0-1, where 0.36 ≈ early morning)
var start_day_progress := 0.36

## Cached night state so we only emit night_changed on actual transitions.
var _is_night: bool = false

# ─────────────────────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SettingsManager.load_settings()
	SettingsManager.apply_settings()

	# Re-broadcast InventoryManager's own signal through Manager so the rest
	# of the codebase can listen on a single bus.
	InventoryManager.inventory_changed.connect(inventory_changed.emit)

	TimeManager.game_seconds = TimeManager.seconds_per_day * start_day_progress
	_is_night = TimeManager.is_night()
	night_changed.emit(_is_night)

# ─────────────────────────────────────────────────────────────────────────────
# PROCESS — night detection + autosave tick
# ─────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	# Night transition
	var now_night := TimeManager.is_night()
	if now_night != _is_night:
		_is_night = now_night
		night_changed.emit(_is_night)

	# Autosave
	_autosave_timer += delta
	if _autosave_timer >= autosave_interval:
		_autosave_timer = 0.0
		save_game()
		UI.show_autosave_icon()

## Convenience wrapper so other scripts can call Manager.is_night() directly.
func is_night() -> bool:
	return TimeManager.is_night()

# ─────────────────────────────────────────────────────────────────────────────
# SAVE / LOAD
# ─────────────────────────────────────────────────────────────────────────────

func save_game() -> void:
	var save_data := {
		"meta": {
			"level":       level,
			"playtime":    int(TimeManager.game_seconds),
			"last_played": Time.get_unix_time_from_system(),
		},
		"data": {
			"skill_points":          skill_points,
			"level":                 level,
			"current_xp":            current_xp,
			"items":                 InventoryManager.get_save_data(),
			"achievement_progress":  AchievementManager.get_progress_data(),
			"visited_rooms":         visited_rooms,
			"room_positions":        _serialize_room_positions(),
			"collected_objects":     collected_objects,
			"game_seconds":          TimeManager.game_seconds,
			"learned_upgrades":      UpgradeManager.learned_upgrades,
			"current_room_scene":    current_room_scene,
			"spawn_location":        [spawn_location.x, spawn_location.y],
			"spawn_room_scene":      spawn_room_scene,
			"death_count":           death_count,
			"end_triggered":         end_triggered,
			"player_current_health": player.current_health if player else 100,
		},
	}

	SaveManager.save(current_slot, save_data)


func load_game(slot: int) -> void:
	current_slot = slot

	var wrapper := SaveManager.load(slot)
	if wrapper.is_empty():
		return

	var data: Dictionary = wrapper.get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		return

	# ── Core state ──────────────────────────────────────────────
	end_triggered  = data.get("end_triggered", false)
	death_count    = data.get("death_count",   0)
	skill_points   = data.get("skill_points",  0)
	level          = data.get("level",         1)
	current_xp     = data.get("current_xp",   0.0)
	loaded_health  = data.get("player_current_health", 100)

	# ── Sub-systems ──────────────────────────────────────────────
	AchievementManager.load_progress_data(data.get("achievement_progress", {}))
	InventoryManager.load_data(data.get("items", {}))

	UpgradeManager.learned_upgrades.clear()
	UpgradeManager.learned_upgrades.append_array(
		data.get("learned_upgrades", [])
)	
	UpgradeManager.apply_effects()

	# ── World ────────────────────────────────────────────────────
	visited_rooms     = data.get("visited_rooms",     [])
	collected_objects = data.get("collected_objects", {})

	room_positions = _deserialize_room_positions(data.get("room_positions", {}))
	# Fill any missing rooms with defaults
	for path in DEFAULT_ROOM_POSITIONS:
		room_positions.get_or_add(path, DEFAULT_ROOM_POSITIONS[path])

	# ── Time ─────────────────────────────────────────────────────
	TimeManager.game_seconds = data.get("game_seconds", 0.0)

	# ── Scene / spawn ────────────────────────────────────────────
	current_room_scene = data.get("current_room_scene", DEFAULT_ROOM_SCENE)
	spawn_room_scene   = data.get("spawn_room_scene",   DEFAULT_SPAWN_ROOM)

	var saved_pos = data.get("spawn_location", [0, 0])
	if typeof(saved_pos) == TYPE_ARRAY and saved_pos.size() == 2:
		spawn_location = Vector2(saved_pos[0], saved_pos[1])
	else:
		spawn_location = DEFAULT_SPAWN_POSITION

	if current_room_scene not in visited_rooms:
		visited_rooms.append(current_room_scene)

	# ── Broadcast refresh signals ────────────────────────────────
	_emit_all_refresh_signals()


func reset_game(should_save := true) -> void:
	skill_points  = 0
	level         = 1
	current_xp    = 0.0
	loaded_health = 100
	death_count   = 0
	end_triggered = false

	InventoryManager.reset()

	visited_rooms.clear()
	collected_objects.clear()
	resource_nodes.clear()
	room_positions = DEFAULT_ROOM_POSITIONS.duplicate(true)

	TimeManager.game_seconds = start_day_progress * TimeManager.seconds_per_day

	current_room_scene  = DEFAULT_ROOM_SCENE
	spawn_room_scene    = DEFAULT_SPAWN_ROOM
	spawn_location      = DEFAULT_SPAWN_POSITION
	respawn_room_scene  = DEFAULT_SPAWN_ROOM
	respawn_location    = DEFAULT_SPAWN_POSITION

	UpgradeManager.learned_upgrades.clear()
	UpgradeManager.apply_effects()

	if should_save:
		save_game()

	_emit_all_refresh_signals()

# ─────────────────────────────────────────────────────────────────────────────
# LEVELING
# ─────────────────────────────────────────────────────────────────────────────

## XP required to advance from `lvl` to `lvl + 1`.
func get_required_xp(lvl: int) -> float:
	@warning_ignore("integer_division")
	return 50.0 * floor(pow(lvl, (1.05 + 0.25 * (lvl / (lvl + 50))))) + 50.0


func add_xp(amount: float) -> void:
	xp_gained.emit(amount)
	AchievementManager.register_xp()

	current_xp += amount
	_check_level_up()
	xp_changed.emit(current_xp, get_required_xp(level))


func _check_level_up() -> void:
	while current_xp >= get_required_xp(level):
		current_xp -= get_required_xp(level)
		level      += 1
		skill_points += 1

		AchievementManager.register_level(level)
		level_changed.emit(level)
		skill_points_changed.emit(skill_points)

# ─────────────────────────────────────────────────────────────────────────────
# DEATH
# ─────────────────────────────────────────────────────────────────────────────

func register_death() -> void:
	death_count += 1
	AchievementManager.register_death()
	death_count_changed.emit(death_count)

# ─────────────────────────────────────────────────────────────────────────────
# RESOURCE NODES
# ─────────────────────────────────────────────────────────────────────────────

func set_resource(unique_id: String, count: int) -> void:
	resource_nodes[unique_id] = {
		"count":     count,
		"last_time": TimeManager.game_seconds,
	}


func update_resource(unique_id: String, max_count: int, regen_time: float) -> void:
	if not resource_nodes.has(unique_id):
		return

	var data: Dictionary = resource_nodes[unique_id]

	var elapsed: float = TimeManager.game_seconds - data["last_time"]
	if elapsed <= 0.0:
		return

	var regen_amount := int(elapsed / regen_time)
	if regen_amount > 0:
		data["count"] = mini(max_count, data["count"] + regen_amount)
		data["last_time"] = TimeManager.game_seconds
# ─────────────────────────────────────────────────────────────────────────────
# END GAME
# ─────────────────────────────────────────────────────────────────────────────

func check_lore_progress() -> void:
	if end_triggered:
		return
	if InventoryManager.get_amount("Lore Fragment") >= lore_goal:
		_trigger_end_game()


func _trigger_end_game() -> void:
	end_triggered = true

	if player:
		player.set_physics_process(false)

	UI.show_text_popup("Something is awakening...")
	await get_tree().create_timer(2.0).timeout
	_play_end_cutscene()


func _play_end_cutscene() -> void:
	await UI.fade_in()
	save_game()
	UI.hide_ui()
	get_tree().change_scene_to_file("res://Scenes/Control/end_screen.tscn")

# ─────────────────────────────────────────────────────────────────────────────
# HELPERS — internal
# ─────────────────────────────────────────────────────────────────────────────

## Serialise Vector2 room positions to JSON-safe arrays.
func _serialize_room_positions() -> Dictionary:
	var out := {}
	for path in room_positions:
		var v: Vector2 = room_positions[path]
		out[path] = [v.x, v.y]
	return out


## Deserialise JSON arrays back to Vector2 room positions.
func _deserialize_room_positions(raw: Dictionary) -> Dictionary:
	var out := {}
	for path in raw:
		var v = raw[path]
		if typeof(v) == TYPE_ARRAY and v.size() == 2:
			out[path] = Vector2(v[0], v[1])
	return out


func _emit_all_refresh_signals() -> void:
	skill_points_changed.emit(skill_points)
	xp_changed.emit(current_xp, get_required_xp(level))
	level_changed.emit(level)
	inventory_changed.emit()
	upgrades_changed.emit()
	map_updated.emit()
	death_count_changed.emit(death_count)
