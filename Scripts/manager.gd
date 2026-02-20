extends Node

# --- CONSTANTS ---
const DEFAULT_ROOM_SCENE := "res://Scenes/Locations/Mushroom Biome/Tutorial.tscn"
const SAVE_PATH := "user://save_game.json"
const BASE_STATS := {
	"player_mobility": 1.0,
	"light_level": 0,
	"hide_unlocked": false,
	"base_extra_jumps": 0,
	"mining_tier": 0,
	"mining_speed_level": 1
}

# --- SIGNALS ---
signal night_changed(is_night: bool)
signal level_changed(level)
signal xp_changed(current_xp, required_xp)
signal skill_points_changed(points)
signal inventory_changed
signal upgrades_changed

# --- PLAYER & TIME ---

var player : CharacterBody2D
var game_seconds := 0.0
var seconds_per_day := 1200.0
var start_day_progress := 0.36
var time_scale := 1.0
var _is_night := false

var activate_spawn : bool = false
var spawn_location : Vector2 = Vector2.ZERO
var current_room_scene : String = DEFAULT_ROOM_SCENE

# --- LEVELING ---

var skill_points: int = 0
var level: int = 1
var current_xp: float = 0

# --- PLAYER STATS (calculated from upgrades) ---

var player_mobility := BASE_STATS["player_mobility"]
var light_level := BASE_STATS["light_level"]
var hide_unlocked := BASE_STATS["hide_unlocked"]
var base_extra_jumps := BASE_STATS["base_extra_jumps"]
var mining_tier := BASE_STATS["mining_tier"]
var mining_speed_level := BASE_STATS["mining_speed_level"]

# --- INVENTORY & COLLECTION ---

var items : Dictionary = {"Ruby Stone":0, "Ruby Gem":0}
var visited_rooms: Array = []
var collected_objects : Dictionary = {}

# --- UPGRADES ---

var learned_upgrades := []

var upgrades := {
	"Mining Tier I": {"skill_cost": 1, "materials": {}, "requires": [], "effect": {"mining_tier":1}},
	"Mining Tier II": {"skill_cost": 1, "materials": {"Ruby Gem":10}, "requires":["Mining Tier I"], "effect":{"mining_tier":2}},
	"Mining Speed I": {"skill_cost":1, "materials":{"Ruby Stone":5}, "requires":[], "effect":{"mining_speed_level":2}},
	"Mining Speed II": {"skill_cost":1, "materials":{"Ruby Stone":20}, "requires":["Mining Speed I"], "effect":{"mining_speed_level":3}},
	"Mobility I": {"skill_cost":1, "materials":{}, "requires":[], "effect":{"player_mobility":1.05}},
	"Mobility II": {"skill_cost":1, "materials":{}, "requires":["Mobility I"], "effect":{"player_mobility":1.1}},
	"Light I": {"skill_cost":1, "materials":{}, "requires":[], "effect":{"light_level":1}},
	"Light II": {"skill_cost":1, "materials":{}, "requires":["Light I"], "effect":{"light_level":2}},
	"Light III": {"skill_cost":1, "materials":{}, "requires":["Light II"], "effect":{"light_level":3}},
	"Hiding": {"skill_cost":1, "materials":{}, "requires":[], "effect":{"hide_unlocked":true}},
	"Double Jump": {"skill_cost":0, "materials":{"Double Jump Scroll":1}, "requires":[], "effect":{"base_extra_jumps":1}},
	"Triple Jump": {"skill_cost":0, "materials":{"Triple Jump Scroll":1}, "requires":["Double Jump"], "effect":{"base_extra_jumps":2}}
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

# ================= SAVE/LOAD =================
		
func save_game():
	var save_data = {
		"skill_points": skill_points,
		"level": level,
		"current_xp": current_xp,
		"items": items,
		"visited_rooms": visited_rooms,
		"collected_objects": collected_objects,
		"game_seconds": game_seconds,
		"learned_upgrades": learned_upgrades,
		"current_room_scene": current_room_scene,
		"spawn_location": spawn_location
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
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	learned_upgrades = data.get("learned_upgrades", [])
	skill_points = data.get("skill_points",0)
	level = data.get("level",1)
	current_xp = data.get("current_xp",0)
	items = data.get("items",{})
	visited_rooms = data.get("visited_rooms",[])
	collected_objects = data.get("collected_objects",{})
	game_seconds = data.get("game_seconds",0)
	current_room_scene = data.get("current_room_scene","res://Scenes/Locations/Mushroom Biome/Tutorial.tscn")

	var saved_pos = data.get("spawn_location",[0,0])
	if typeof(saved_pos) == TYPE_ARRAY and saved_pos.size() == 2:
		spawn_location = Vector2(saved_pos[0], saved_pos[1])
	else:
		spawn_location = Vector2.ZERO
	apply_learned_upgrades()

	# Refresh signals
	skill_points_changed.emit(skill_points)
	xp_changed.emit(current_xp, get_required_xp(level))
	level_changed.emit(level)
	inventory_changed.emit()
	upgrades_changed.emit()

func reset_game():
	skill_points = 0
	level = 1
	current_xp = 0
	items = {"Ruby Stone":0, "Ruby Gem":0}
	visited_rooms.clear()
	collected_objects.clear()
	game_seconds = start_day_progress * seconds_per_day
	current_room_scene = DEFAULT_ROOM_SCENE
	learned_upgrades.clear()
	apply_learned_upgrades()
	save_game()
	upgrades_changed.emit()
	skill_points_changed.emit(skill_points)
	xp_changed.emit(current_xp, get_required_xp(level))
	level_changed.emit(level)
	inventory_changed.emit()
	
# ================= LEVELING =================

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

# ================= UPGRADES =================

func can_learn_upgrade(upgrade_name: String) -> bool:
	if upgrade_name == null:
		return false
	if upgrade_name in learned_upgrades:
		return false
		
	var u = upgrades.get(upgrade_name, null)
	if u == null:
		return false

	if skill_points < u.skill_cost:
		return false

	for mat in u.materials.keys():
		if items.get(mat, 0) < u.materials[mat]:
			return false

	for req in u.requires:
		if req not in learned_upgrades:
			return false

	return true

func learn_upgrade(upgrade_name: String) -> void:
	if not can_learn_upgrade(upgrade_name):
		return

	var u = upgrades[upgrade_name]

	skill_points -= u.skill_cost
	skill_points_changed.emit(skill_points)

	for mat in u.materials.keys():
		remove_item(mat, u.materials[mat])

	if upgrade_name not in learned_upgrades:
		learned_upgrades.append(upgrade_name)

	apply_learned_upgrades()

	save_game()
	upgrades_changed.emit()

func apply_learned_upgrades():
	for key in BASE_STATS.keys():
		self.set(key, BASE_STATS[key])

	for upgrade_name in learned_upgrades:
		var u = upgrades.get(upgrade_name, null)
		if u == null:
			continue
		var effect = u.get("effect", {})
		for stat in effect.keys():
			self.set(stat, effect[stat])

	if player:
		player.set_stats()
	
# ================= INVENTORY =================

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
		
# ================= DAY/NIGHT =================
		
func get_day() -> int:
	return int(game_seconds / seconds_per_day)

func get_day_progress() -> float:
	return fmod(game_seconds, seconds_per_day) / seconds_per_day
	
func is_night() -> bool:
	var t := get_day_progress()
	return t < 0.25 or t > 0.75
