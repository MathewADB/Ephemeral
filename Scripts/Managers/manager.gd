extends Node

# --- CONSTANTS ---
const SETTINGS_PATH := "user://settings.json"
const DEFAULT_ROOM_SCENE := "res://Scenes/Locations/Mushroom Biome/Tutorial.tscn"
const SAVE_PATH := "user://save_game.json"
const BASE_STATS := {
	"player_mobility": 1.0,
	"light_level": 0,
	"hide_unlocked": false,
	"base_extra_jumps": 0,
	"mining_tier": 0,
	"mining_speed_level": 1,
	"pillar_interaction": false,
	"map_unlocked": false
}
const DEFUALT_ROOM_POSITIONS : Dictionary = {
	"res://Scenes/Locations/Mushroom Biome/Tutorial.tscn" : Vector2(9999,9999),
	"res://Scenes/Locations/Mushroom Biome/Tutorial2.tscn" : Vector2(1,0),
	"res://Scenes/Locations/Mushroom Biome/shop.tscn" : Vector2(2,0),
	"res://Scenes/Locations/Mushroom Biome/Home.tscn" : Vector2(2,1),
	"res://Scenes/Locations/Mushroom Biome/The Plain.tscn" : Vector2(3,1)
}
const ROOM_TYPES : Dictionary = {
	"res://Scenes/Locations/Mushroom Biome/Tutorial.tscn" : "tutorial",
	"res://Scenes/Locations/Mushroom Biome/Tutorial2.tscn" : "tutorial",
	"res://Scenes/Locations/Mushroom Biome/shop.tscn" : "shop",
	"res://Scenes/Locations/Mushroom Biome/Home.tscn" : "hub",
	"res://Scenes/Locations/Mushroom Biome/The Plain.tscn" : "mushroom"
}
const DEFAULT_SPAWN_ROOM := "res://Scenes/Locations/Mushroom Biome/Home.tscn"
const DEFAULT_SPAWN_POSITION := Vector2(618,497)

# --- SIGNALS ---

signal night_changed(is_night: bool)
signal level_changed(level)
signal xp_changed(current_xp, required_xp)
signal skill_points_changed(points)
signal inventory_changed
signal upgrades_changed
signal map_updated

# --- AUTOSAVE ---

var autosave_interval: float = 300.0
var autosave_timer: float = 0.0
var current_slot: int = 0

# --- PLAYER & TIME ---

var player : CharacterBody2D
var game_seconds := 0.0
var seconds_per_day := 1200.0
var start_day_progress := 0.36
var time_scale := 1.0
var _is_night := false

var loaded_health = 100

var activate_spawn : bool = false
var respawn_room_scene : String = DEFAULT_SPAWN_ROOM
var respawn_location : Vector2 = DEFAULT_SPAWN_POSITION
var current_room_scene : String = DEFAULT_ROOM_SCENE
var spawn_room_scene : String = DEFAULT_SPAWN_ROOM
var spawn_location : Vector2 = DEFAULT_SPAWN_POSITION

# --- LEVELING ---

var skill_points: int = 0
var level: int = 1
var current_xp: float = 0

# --- PLAYER STATS ---

var player_mobility := BASE_STATS["player_mobility"]
var light_level := BASE_STATS["light_level"]
var hide_unlocked := BASE_STATS["hide_unlocked"]
var base_extra_jumps := BASE_STATS["base_extra_jumps"]
var mining_tier := BASE_STATS["mining_tier"]
var mining_speed_level := BASE_STATS["mining_speed_level"]
var pillar_interaction := BASE_STATS["pillar_interaction"]
var map_unlocked := BASE_STATS["map_unlocked"]

# --- INVENTORY & COLLECTION ---

var visited_rooms: Array = []
var collected_objects : Dictionary = {}
var resource_nodes := {}

var room_positions = DEFUALT_ROOM_POSITIONS.duplicate(true)

# --- PROGRESS ---

var death_count: int = 0

var lore_goal := 3
var end_triggered := false

func check_lore_progress():
	if end_triggered:
		return

	if InventoryManager.get_amount("Lore Fragment") >= lore_goal:
		trigger_end_game()
		
func trigger_end_game():
	end_triggered = true

	if player:
		player.set_physics_process(false)

	UI.show_text_popup("Something is awakening...")
	await get_tree().create_timer(2.0).timeout
	play_end_cutscene()

func play_end_cutscene():
	UI.fade_in()

	await get_tree().create_timer(2.0).timeout
	save_game()
	UI.hide_ui()
	get_tree().change_scene_to_file("res://Scenes/Control/end_screen.tscn")

# -- Functions --

func _ready():
	SettingsManager.load_settings()
	SettingsManager.apply_settings()
	InventoryManager.inventory_changed.connect(func():
		inventory_changed.emit())
	game_seconds = start_day_progress * seconds_per_day
	_is_night = is_night()
	night_changed.emit(_is_night)
	
func _process(delta):
	game_seconds += delta * time_scale
	#print(game_seconds - 432)
	var now_night := is_night()
	if now_night != _is_night:
		_is_night = now_night
		night_changed.emit(_is_night)
	
	autosave_timer += delta
	if autosave_timer >= autosave_interval:
		autosave_timer = 0.0
		save_game()
		UI.show_autosave_icon()
		
# ================= SAVE/LOAD =================
		
func save_game():
	var save_data = {
		"meta": {
			"level": level,
			"playtime": int(game_seconds),
			"last_played": Time.get_unix_time_from_system()
		},
		"data": {
			"skill_points": skill_points,
			"level": level,
			"current_xp": current_xp,
			"items": InventoryManager.get_save_data(),
			"achievement_progress": AchievementManager.get_progress_data(),
			"visited_rooms": visited_rooms,
			"room_positions": room_positions,
			"collected_objects": collected_objects,
			"game_seconds": game_seconds,
			"learned_upgrades": UpgradeManager.learned_upgrades,
			"current_room_scene": current_room_scene,
			"spawn_location": spawn_location,
			"spawn_room_scene": spawn_room_scene,
			"death_count": death_count,
			"end_triggered": end_triggered,
			"player_current_health": player.current_health if player else 100
		}
	}

	SaveManager.save(current_slot, save_data)

func load_game(slot: int):
	current_slot = slot

	var wrapper = SaveManager.load(slot)
	if wrapper.is_empty():
		return
	
	var data = wrapper.get("data", {})
		
	if typeof(data) != TYPE_DICTIONARY:
		return

	end_triggered = data.get("end_triggered", false)
	AchievementManager.load_progress_data(
	data.get("achievement_progress", {})
)

	death_count = data.get("death_count", 0)
	UpgradeManager.learned_upgrades = data.get("learned_upgrades", [])
	UpgradeManager.apply_effects()
	skill_points = data.get("skill_points",0)
	level = data.get("level",1)
	current_xp = data.get("current_xp",0)
	InventoryManager.load_data(data.get("items", {}))
	visited_rooms = data.get("visited_rooms",[])
	
	var loaded_room_positions = data.get("room_positions", {})
	room_positions = {}
	for room_path in loaded_room_positions:
		var pos_data = loaded_room_positions[room_path]
		if typeof(pos_data) == TYPE_ARRAY and pos_data.size() == 2:
			room_positions[room_path] = Vector2(pos_data[0], pos_data[1])
			
	for room_path in DEFUALT_ROOM_POSITIONS:
		if room_path not in room_positions:
			room_positions[room_path] = DEFUALT_ROOM_POSITIONS[room_path]
			
	collected_objects = data.get("collected_objects",{})
	game_seconds = data.get("game_seconds",0)
	current_room_scene = data.get("current_room_scene","res://Scenes/Locations/Mushroom Biome/Tutorial.tscn")
	loaded_health = data.get("player_current_health", 100)

	var saved_pos = data.get("spawn_location",[0,0])
	if typeof(saved_pos) == TYPE_ARRAY and saved_pos.size() == 2:
		spawn_location = Vector2(saved_pos[0], saved_pos[1])
	else:
		spawn_location = Vector2.ZERO
		
	if current_room_scene not in visited_rooms:
		visited_rooms.append(current_room_scene)
	spawn_room_scene = data.get("spawn_room_scene", DEFAULT_SPAWN_ROOM)
	
	apply_learned_upgrades()

	skill_points_changed.emit(skill_points)
	xp_changed.emit(current_xp, get_required_xp(level))
	level_changed.emit(level)
	inventory_changed.emit()
	upgrades_changed.emit()
	map_updated.emit()
	
func reset_game(should_save := true):

	skill_points = 0
	level = 1
	current_xp = 0
	
	loaded_health = 100
	death_count = 0
	
	InventoryManager.reset()
	
	visited_rooms.clear()
	room_positions = DEFUALT_ROOM_POSITIONS.duplicate(true)
	collected_objects.clear()
	resource_nodes.clear()
	
	game_seconds = start_day_progress * seconds_per_day
	
	current_room_scene = DEFAULT_ROOM_SCENE
	spawn_room_scene = DEFAULT_SPAWN_ROOM
	spawn_location = DEFAULT_SPAWN_POSITION
	respawn_room_scene = DEFAULT_SPAWN_ROOM
	respawn_location = DEFAULT_SPAWN_POSITION
	
	UpgradeManager.learned_upgrades.clear()
	UpgradeManager.apply_effects()
	
	end_triggered = false
	
	if should_save:
		save_game()
	
	# --- SIGNALS ---
	upgrades_changed.emit()
	skill_points_changed.emit(skill_points)
	xp_changed.emit(current_xp, get_required_xp(level))
	level_changed.emit(level)
	inventory_changed.emit()
	map_updated.emit()
	
	# ================= NODES ==================

func update_resource(unique_id: String, max_count: int, regen_time: float):
	if not resource_nodes.has(unique_id):
		return
	
	var data = resource_nodes[unique_id]
	var time_passed = game_seconds - data["last_time"]
	
	if time_passed <= 0:
		return
	
	var regen_amount = int(time_passed / regen_time)
	
	if regen_amount > 0:
		data["count"] = min(max_count, data["count"] + regen_amount)
		data["last_time"] = game_seconds
		
func set_resource(unique_id: String, count: int):
	if not resource_nodes.has(unique_id):
		resource_nodes[unique_id] = {
			"count": count,
			"last_time": game_seconds
		}
	else:
		resource_nodes[unique_id]["count"] = count
		resource_nodes[unique_id]["last_time"] = game_seconds
		
# ================= LEVELING =================

func get_required_xp(lvl: int) -> float:
	@warning_ignore("integer_division")
	return 50 * floor(pow(lvl, (1.05 + 0.25 * (lvl / (lvl + 50))))) + 50
	
signal xp_gained(amount)

func add_xp(amount: float):
	xp_gained.emit(amount) 
	
	AchievementManager.register_xp()
	
	current_xp += amount
	check_level_up()
	xp_changed.emit(current_xp, get_required_xp(level))

func check_level_up():
	while current_xp >= get_required_xp(level):
		current_xp -= get_required_xp(level)
		level += 1
		
		AchievementManager.register_level(level)
	
		skill_points += 1
		skill_points_changed.emit(skill_points)
		
		level_changed.emit(level)

# ================= UPGRADES =================

func apply_learned_upgrades():
	UpgradeManager.apply_effects()
		
# ================= DAY/NIGHT =================
		
func get_day() -> int:
	return int(game_seconds / seconds_per_day)

func get_day_progress() -> float:
	return fmod(game_seconds, seconds_per_day) / seconds_per_day
	
func is_night() -> bool:
	var t := get_day_progress()
	return t < 0.25 or t > 0.75
