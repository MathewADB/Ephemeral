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

const ACHIEVEMENT_DATA := {
	"first_xp": {
		"name": "Getting Started",
		"description": "Gain your first XP",
		"icon": preload("res://Sprites/Icons/Achievement/getting started.png")
	},
	"level_5": {
		"name": "Growing Strong",
		"description": "Reach level 5",
		"icon": preload("res://Sprites/Icons/Achievement/growing strong.png")
	},
	"first_death": {
		"name": "First Death",
		"description": "Die for the first time",
		"icon": preload("res://Sprites/Icons/Achievement/first death.png")
	},
	"first_craft": {
		"name": "Crafting",
		"description": "Craft your first item",
		"icon": preload("res://Sprites/Icons/Achievement/first craft.png")
	},
	"death_10": {
		"name": "Getting Used To It",
		"description": "Die 10 times",
		"icon": preload("res://Sprites/Icons/Achievement/tenth death.png")
	},
	"death_50": {
		"name": "Endless Suffering",
		"description": "Die 50 times",
		"icon": preload("res://Sprites/Icons/Achievement/fifty death.png")
	},
	"craft_10": {
		"name": "Apprentice Crafter",
		"description": "Craft 10 items",
		"icon": preload("res://Sprites/Icons/Achievement/tenth craft.png")
	}
}
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

var items : Dictionary = {"Ruby Stone":0, "Ruby Gem":0, "Dust":0, "Dust Gem":0, "Stone":0, "Lore Fragment":0}
var visited_rooms: Array = []
var collected_objects : Dictionary = {}
var resource_nodes := {}

var room_positions = DEFUALT_ROOM_POSITIONS.duplicate(true)

# --- UPGRADES ---

var learned_upgrades := []

var upgrades := {
	"Mining Tier I": {"skill_cost": 1, "materials": {}, "requires": [], "effect": {"mining_tier":1}},
	"Mining Tier II": {"skill_cost": 1, "materials": {"Ruby Gem":10}, "requires":["Mining Tier I"], "effect":{"mining_tier":2}},
	"Mining Speed I": {"skill_cost":1, "materials":{"Ruby Stone":5}, "requires":["Mining Tier I"], "effect":{"mining_speed_level":2}},
	"Mining Speed II": {"skill_cost":1, "materials":{"Ruby Stone":20}, "requires":["Mining Speed I","Mining Tier II"], "effect":{"mining_speed_level":3}},
	"Mobility I": {"skill_cost":1, "materials":{}, "requires":["Double Jump"], "effect":{"player_mobility":1.05}},
	"Mobility II": {"skill_cost":1, "materials":{}, "requires":["Mobility I","Triple Jump"], "effect":{"player_mobility":1.1}},
	"Light I": {"skill_cost":1, "materials":{"Dust Gem":1}, "requires":["Pillar Interaction"], "effect":{"light_level":1}},
	"Light II": {"skill_cost":1, "materials":{}, "requires":["Light I"], "effect":{"light_level":2}},
	"Light III": {"skill_cost":1, "materials":{}, "requires":["Light II"], "effect":{"light_level":3}},
	"Hiding": {"skill_cost":1, "materials":{}, "requires":[], "effect":{"hide_unlocked":true}},
	"Double Jump": {"skill_cost":1, "materials":{"Double Jump Scroll":1}, "requires":[], "effect":{"base_extra_jumps":1}},
	"Triple Jump": {"skill_cost":1, "materials":{"Triple Jump Scroll":1}, "requires":["Double Jump"], "effect":{"base_extra_jumps":2}},
	"Pillar Interaction": {"skill_cost":1, "materials":{}, "requires":[], "effect":{"pillar_interaction":true}},
	"Map": {"skill_cost":1, "materials":{}, "requires":[], "effect":{"map_unlocked":true}}
}

var crafting_recipes := {
	"Ruby Gem": {
		"name": "Ruby Gem",
		"description": "A refined gem crafted from raw stones",
		"icon": preload("res://Sprites/Entities/Ruby Gem.png"),
		"materials": {"Ruby Stone": 2},
		"time": 5.0
	},
	"Dust Gem": {
		"name": "Dust Gem",
		"description": "A refined gem which can be used to activate some broken objects",
		"icon": preload("res://Sprites/Entities/Dust Gem.png"),
		"materials": {"Dust": 10},
		"time": 10.0
	}
}

# Achievement stats 

var death_count: int = 0
var crafted_count: int = 0

var achievements := {
	"first_xp": {"unlocked": false},
	"level_5": {"unlocked": false},
	"first_death": {"unlocked": false},
	"first_craft": {"unlocked": false},
	"death_10": {"unlocked": false},
	"death_50": {"unlocked": false},
	"craft_10": {"unlocked": false}
}

# -- ENDGAME --

var lore_goal := 3
var end_triggered := false

func check_lore_progress():
	if end_triggered:
		return

	if items.get("Lore Fragment", 0) >= lore_goal:
		trigger_end_game()
		
func trigger_end_game():
	end_triggered = true

	if player:
		player.set_physics_process(false)

	UI.show_text_popup("Something is awakening...")

	await get_tree().create_timer(2.0).timeout

	play_end_cutscene()
	
func play_end_cutscene():
	UI.fade.visible = true
	UI.fade.fade_in()

	await get_tree().create_timer(2.0).timeout
	save_game()
	UI.hide_ui()
	get_tree().change_scene_to_file("res://Scenes/Control/end_screen.tscn")

# -- Settings --

var selected_language = ""
var fullscreen: bool = false
	
func apply_settings():
	if selected_language == "":
		selected_language = "EN"

	TranslationServer.set_locale(selected_language)

	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
# -- Functions --

func _ready():
	game_seconds = start_day_progress * seconds_per_day
	_is_night = is_night()
	night_changed.emit(_is_night)
	load_game()
	apply_settings()
	
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
		"settings": {
			"selected_language": selected_language,
			"fullscreen": fullscreen
		},
		"skill_points": skill_points,
		"level": level,
		"current_xp": current_xp,
		"items": items,
		"visited_rooms": visited_rooms,
		"room_positions": room_positions,
		"collected_objects": collected_objects,
		"game_seconds": game_seconds,
		"learned_upgrades": learned_upgrades,
		"current_room_scene": current_room_scene,
		"spawn_location": spawn_location,
		"spawn_room_scene": spawn_room_scene,
		"achievements": achievements,
		"death_count": death_count,
		"crafted_count": crafted_count,
		"end_triggered": end_triggered,
		"player_current_health": player.current_health if player else 100
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
	
	var settings = data.get("settings", {})

	selected_language = settings.get("selected_language", "EN")
	fullscreen = settings.get("fullscreen", false)

	end_triggered = data.get("end_triggered", false)
	var loaded_achievements = data.get("achievements", {})

	for id in achievements.keys():
		if loaded_achievements.has(id):
			achievements[id]["unlocked"] = loaded_achievements[id].get("unlocked", false)
	death_count = data.get("death_count", 0)
	crafted_count = data.get("crafted_count", 0)
	learned_upgrades = data.get("learned_upgrades", [])
	skill_points = data.get("skill_points",0)
	level = data.get("level",1)
	current_xp = data.get("current_xp",0)
	items = data.get("items",{})
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
	# --- CORE PROGRESSION ---
	skill_points = 0
	level = 1
	current_xp = 0
	
	# --- PLAYER STATE ---
	loaded_health = 100
	death_count = 0
	crafted_count = 0
	
	# --- INVENTORY ---
	items = {
		"Ruby Stone":0, 
		"Ruby Gem":0, 
		"Dust":0, 
		"Dust Gem":0, 
		"Stone":0, 
		"Lore Fragment":0
	}
	
	# --- WORLD STATE ---
	visited_rooms.clear()
	room_positions = DEFUALT_ROOM_POSITIONS.duplicate(true)
	collected_objects.clear()
	resource_nodes.clear()
	
	# --- TIME ---
	game_seconds = start_day_progress * seconds_per_day
	
	# --- POSITION / SCENE ---
	current_room_scene = DEFAULT_ROOM_SCENE
	spawn_room_scene = DEFAULT_SPAWN_ROOM
	spawn_location = DEFAULT_SPAWN_POSITION
	respawn_room_scene = DEFAULT_SPAWN_ROOM
	respawn_location = DEFAULT_SPAWN_POSITION
	
	# --- UPGRADES ---
	learned_upgrades.clear()
	apply_learned_upgrades()
	
	# --- ACHIEVEMENTS RESET ---
	for key in achievements.keys():
		achievements[key]["unlocked"] = false
	
	# --- ENDGAME RESET ---
	end_triggered = false
	
	# --- SAVE ---
	if should_save:
		save_game()
	
	# --- SIGNALS ---
	upgrades_changed.emit()
	skill_points_changed.emit(skill_points)
	xp_changed.emit(current_xp, get_required_xp(level))
	level_changed.emit(level)
	inventory_changed.emit()
	map_updated.emit()

func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		var dir := DirAccess.open("user://")
		if dir:
			dir.remove("save_game.json")
			print("Save deleted")
		else:
			print("Failed to open user:// directory")
			
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
		
# =============== ACHIEVEMENTS =============

func unlock_achievement(id: String):
	if not achievements.has(id):
		return
	
	if achievements[id]["unlocked"]:
		return
	
	achievements[id]["unlocked"] = true
	
	print("Unlocked:", ACHIEVEMENT_DATA[id]["name"])
	
	var data = ACHIEVEMENT_DATA[id]
	
	UI.show_achievement_popup(
		data["name"],
		data["description"],
		data["icon"]
	)
	
	save_game()
	
func add_achievement_progress(id: String, amount := 1):
	if not achievements.has(id):
		return
	
	var ach = achievements[id]
	
	if ach.get("unlocked", false):
		return
	
	ach["progress"] += amount
	
	if ach["progress"] >= ach["goal"]:
		unlock_achievement(id)
		
func register_death():
	death_count += 1
	
	if death_count == 1:
		unlock_achievement("first_death")
	elif death_count == 10:
		unlock_achievement("death_10")
	elif death_count == 50:
		unlock_achievement("death_50")
	
	save_game()
	
func register_craft(amount := 1):
	crafted_count += amount
	
	unlock_achievement("first_craft")
	if crafted_count >= 10:
		unlock_achievement("craft_10")
	
	save_game()
	
# ================= LEVELING =================

func get_required_xp(lvl: int) -> float:
	@warning_ignore("integer_division")
	return 50 * floor(pow(lvl, (1.05 + 0.25 * (lvl / (lvl + 50))))) + 50
	
signal xp_gained(amount)

func add_xp(amount: float):
	xp_gained.emit(amount) 
	
	unlock_achievement("first_xp")
	
	current_xp += amount
	check_level_up()
	xp_changed.emit(current_xp, get_required_xp(level))

func check_level_up():
	while current_xp >= get_required_xp(level):
		current_xp -= get_required_xp(level)
		level += 1
		
		if level >= 5:
			unlock_achievement("level_5")
	
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
	if upgrade_name == "Map":
		
		map_updated.emit()
		
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
	
	if item_name == "Lore Fragment":
		check_lore_progress()
		
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
