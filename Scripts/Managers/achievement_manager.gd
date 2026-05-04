extends Node

# SIGNALS

signal achievement_unlocked(id: String, data: Dictionary)
signal achievement_progress(id: String, progress: int, goal: int)

# DATA

const GLOBAL_SAVE_PATH := "user://achievements_global.json"

const RARITY_COLORS = {
	"common": Color("#52636d"),
	"uncommon": Color("22783f"),
	"rare": Color("#345f99"),
	"epic": Color("#7d2f7e"),
	"legendary": Color("#e5a732"),
	"mythic": Color("b41e40"),
	"platinum": Color("a6c4bf")
}

const RARITY_ORDER := {
	"common": 0,
	"uncommon": 1,
	"rare": 2,
	"epic": 3,
	"legendary": 4,
	"mythic": 5,
	"platinum": 6
}

const ACHIEVEMENTS := {
	"first_xp": {
		"name": "Getting Started",
		"description": "Gain your first XP",
		"rarity": "common",
		"icon": preload("res://Sprites/Icons/Achievement/Level 1.png")
	},
	"level_5": {
		"name": "Growing Strong",
		"description": "Reach level 5",
		"rarity": "uncommon",
		"icon": preload("res://Sprites/Icons/Achievement/Level 5.png")
	},
	"first_death": {
		"name": "First Death",
		"description": "Die for the first time",
		"rarity": "common",
		"icon": preload("res://Sprites/Icons/Achievement/Death 1.png")
	},
	"death_10": {
		"name": "Getting Used To It",
		"description": "Die 10 times",
		"rarity": "common",
		"icon": preload("res://Sprites/Icons/Achievement/Death 10.png"),
		"goal": 10
	},
	"death_50": {
		"name": "Endless Suffering",
		"description": "Die 50 times",
		"rarity": "uncommon",
		"icon": preload("res://Sprites/Icons/Achievement/Death 50.png"),
		"goal": 50
	},
	"first_craft": {
		"name": "Crafting",
		"description": "Craft your first item",
		"rarity": "common",
		"icon": preload("res://Sprites/Icons/Achievement/Craft 1.png")
	},
	"craft_10": {
		"name": "Apprentice Crafter",
		"description": "Craft 10 items",
		"rarity": "uncommon",
		"icon": preload("res://Sprites/Icons/Achievement/Craft 10.png"),
		"goal": 10
	},
	"craft_25": {
		"name": "Expert Crafter",
		"description": "Craft 25 items",
		"rarity": "rare",
		"icon": preload("res://Sprites/Icons/Achievement/Craft 25.png"),
		"goal": 25
	}
}

# RUNTIME STATE

var unlocked := {}
var progress := {}

func _ready():
	load_global()
	
# CORE API

func unlock(id: String) -> void:
	if not ACHIEVEMENTS.has(id):
		return
	
	if unlocked.get(id, false):
		return
	
	unlocked[id] = true
	AudioManager.play_sfx("unlock")
	
	save_global() 
	
	achievement_unlocked.emit(id, ACHIEVEMENTS[id])


func add_progress(id: String, amount := 1) -> void:
	if not ACHIEVEMENTS.has(id):
		return
	
	if unlocked.get(id, false):
		return
	
	var goal = ACHIEVEMENTS[id].get("goal", null)
	if goal == null:
		return
	
	progress[id] = progress.get(id, 0) + amount
	
	achievement_progress.emit(id, progress[id], goal)
	
	if progress[id] >= goal:
		unlock(id)


# HELPERS

func register_death():
	add_progress("death_10", 1)
	add_progress("death_50", 1)
	unlock("first_death")


func register_craft(amount := 1):
	add_progress("craft_10", amount)
	add_progress("craft_25", amount)
	unlock("first_craft")


func register_xp():
	unlock("first_xp")


func register_level(level: int):
	if level >= 5:
		unlock("level_5")


# SAVE / LOAD

func get_progress_data() -> Dictionary:
	return {
		"progress": progress
	}
	
func load_progress_data(data: Dictionary) -> void:
	progress = data.get("progress", {})
	
func load_data(data: Dictionary) -> void:
	unlocked = data.get("unlocked", {})
	progress = data.get("progress", {})

func save_global():
	var file := FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"unlocked": unlocked
		}))
		file.close()


func load_global():
	if not FileAccess.file_exists(GLOBAL_SAVE_PATH):
		return
	
	var file := FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) == TYPE_DICTIONARY:
		unlocked = data.get("unlocked", {})
		
func reset():
	unlocked.clear()
	progress.clear()
