extends Node

# SIGNALS

signal achievement_unlocked(id: String, data: Dictionary)
signal achievement_progress(id: String, progress: int, goal: int)

# DATA

const ACHIEVEMENTS := {
	"first_xp": {
		"name": "Getting Started",
		"description": "Gain your first XP",
		"icon": preload("res://Sprites/Icons/Achievement/Level 1.png")
	},
	"level_5": {
		"name": "Growing Strong",
		"description": "Reach level 5",
		"icon": preload("res://Sprites/Icons/Achievement/Level 5.png")
	},
	"first_death": {
		"name": "First Death",
		"description": "Die for the first time",
		"icon": preload("res://Sprites/Icons/Achievement/Death 1.png")
	},
	"death_10": {
		"name": "Getting Used To It",
		"description": "Die 10 times",
		"icon": preload("res://Sprites/Icons/Achievement/Death 10.png"),
		"goal": 10
	},
	"death_50": {
		"name": "Endless Suffering",
		"description": "Die 50 times",
		"icon": preload("res://Sprites/Icons/Achievement/Death 50.png"),
		"goal": 50
	},
	"first_craft": {
		"name": "Crafting",
		"description": "Craft your first item",
		"icon": preload("res://Sprites/Icons/Achievement/Craft 1.png")
	},
	"craft_10": {
		"name": "Apprentice Crafter",
		"description": "Craft 10 items",
		"icon": preload("res://Sprites/Icons/Achievement/Craft 10.png"),
		"goal": 10
	}
}

# RUNTIME STATE

var unlocked := {}
var progress := {}

# CORE API

func unlock(id: String) -> void:
	if not ACHIEVEMENTS.has(id):
		return
	
	if unlocked.get(id, false):
		return
	
	unlocked[id] = true
	
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
	unlock("first_craft")


func register_xp():
	unlock("first_xp")


func register_level(level: int):
	if level >= 5:
		unlock("level_5")


# SAVE / LOAD

func get_save_data() -> Dictionary:
	return {
		"unlocked": unlocked,
		"progress": progress
	}
	
func load_data(data: Dictionary) -> void:
	unlocked = data.get("unlocked", {})
	progress = data.get("progress", {})

func reset():
	unlocked.clear()
	progress.clear()
