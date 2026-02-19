extends Node

const SAVE_PATH := "user://save_game.json"

signal night_changed(is_night: bool)
signal level_changed(level)
signal xp_changed(current_xp, required_xp)
signal skill_points_changed(points)

var player : CharacterBody2D

var skill_points: int = 0
var level: int = 1
var current_xp: float = 0

var player_mobility := 1.0
var light_level := 0
var hide_unlocked := false
var base_extra_jumps := 0
var mining_tier := 0
var mining_speed_level := 1

var game_seconds := 0.0
var seconds_per_day := 1200.0
var start_day_progress := 0.36
var time_scale := 1.0
var _is_night := false

var activate_spawn : bool = false
var spawn_location : Vector2

signal inventory_changed

var visited_rooms: Array = []

var collected_objects : Dictionary = {}

var items : Dictionary = {
	"Ruby Stone" : 0,
	"Ruby Gem" : 0
	}

var crafting_recipes := {
	"Ruby Gem": {
		"name": "Ruby Gem",
		"description": "A refined gem crafted from raw stones",
		"icon": preload("res://Sprites/Entities/Ruby Gem.png"),
		"materials": {"Ruby Stone": 2},
		"time": 5.0
	}
}
func _ready():
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

# ===== Save
		
func reset_game():
	skill_points = 0
	level = 1
	current_xp = 0

	player_mobility = 1.0
	light_level = 0
	hide_unlocked = false
	base_extra_jumps = 0
	mining_tier = 0
	mining_speed_level = 1

	items.clear()
	items = {
		"Ruby Stone": 0,
		"Ruby Gem": 0
	}

	visited_rooms.clear()
	collected_objects.clear()

	game_seconds = start_day_progress * seconds_per_day

	save_game()
	
func save_game():
	
	var save_data = {
		"skill_points": skill_points,
		"level": level,
		"current_xp": current_xp,
		"player_mobility": player_mobility,
		"light_level": light_level,
		"hide_unlocked": hide_unlocked,
		"base_extra_jumps": base_extra_jumps,
		"mining_tier": mining_tier,
		"mining_speed_level": mining_speed_level,
		"items": items,
		"visited_rooms": visited_rooms,
		"collected_objects": collected_objects,
		"game_seconds": game_seconds
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if data == null:
		return

	skill_points = data.get("skill_points", 0)
	level = data.get("level", 1)
	current_xp = data.get("current_xp", 0)

	player_mobility = data.get("player_mobility", 1.0)
	light_level = data.get("light_level", 0)
	hide_unlocked = data.get("hide_unlocked", false)
	base_extra_jumps = data.get("base_extra_jumps", 0)
	mining_tier = data.get("mining_tier", 0)
	mining_speed_level = data.get("mining_speed_level", 1)

	items = data.get("items", {})
	visited_rooms = data.get("visited_rooms", [])
	collected_objects = data.get("collected_objects", {})
	game_seconds = data.get("game_seconds", 0)

	# Refresh UI
	skill_points_changed.emit(skill_points)
	xp_changed.emit(current_xp, get_required_xp(level))
	level_changed.emit(level)
	inventory_changed.emit()

# ===== Inventory 

func add_item(item_name : String, amount := 1):
	if not items.has(item_name):
		items[item_name] = 0

	items[item_name] += amount
	inventory_changed.emit()
	
func remove_item(item_name : String, amount := 1):
	if not items.has(item_name):
		return

	items[item_name] -= amount
	if items[item_name] <= 0:
		items.erase(item_name)

	inventory_changed.emit()
	
# ===== Leveling 

func get_required_xp(lvl: int) -> float:
	@warning_ignore("integer_division")
	return 50 * floor(pow(lvl, (1.05 + 0.25 * (lvl / (lvl + 50))))) + 50
	
signal xp_gained(amount)
func add_xp(amount: float):
	xp_gained.emit(amount) 
	
	current_xp += amount
	check_level_up()
	xp_changed.emit(current_xp, get_required_xp(level))

func check_level_up():
	while current_xp >= get_required_xp(level):
		current_xp -= get_required_xp(level)
		level += 1
		
		skill_points += 1
		skill_points_changed.emit(skill_points)
		
		level_changed.emit(level)
			
# ===== Day / Night
		
func get_day() -> int:
	return int(game_seconds / seconds_per_day)

func get_day_progress() -> float:
	return fmod(game_seconds, seconds_per_day) / seconds_per_day
	
func is_night() -> bool:
	var t := get_day_progress()
	return t < 0.25 or t > 0.75
