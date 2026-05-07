extends Node

# =============================================================================
# ACHIEVEMENT MANAGER — Persistent achievements, progress tracking
# Autoload name: AchievementManager
# Global unlocks persist across save slots via a separate file.
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────────────────────

signal achievement_unlocked(id: String, data: Dictionary)
signal achievement_progress_updated(id: String, current: int, goal: int)

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────

const GLOBAL_SAVE_PATH := "user://achievements_global.json"

const RARITY_COLORS: Dictionary = {
	"common":    Color("#52636d"),
	"uncommon":  Color("#22783f"),
	"rare":      Color("#345f99"),
	"epic":      Color("#7d2f7e"),
	"legendary": Color("#e5a732"),
	"mythic":    Color("#b41e40"),
	"platinum":  Color("#a6c4bf"),
}

const RARITY_ORDER: Dictionary = {
	"common": 0, "uncommon": 1, "rare": 2,
	"epic": 3,   "legendary": 4, "mythic": 5, "platinum": 6,
}

# ─────────────────────────────────────────────────────────────────────────────
# ACHIEVEMENT REGISTRY
# ─────────────────────────────────────────────────────────────────────────────
#
# Each entry:
#   name        String    — display name
#   description String    — shown in achievement list
#   rarity      String    — see RARITY_COLORS
#   icon        Texture2D — shown in popup / list
#   goal        int       — optional; progress achievements only
#   hidden      bool      — optional; hide name/desc until unlocked
#
const ACHIEVEMENTS: Dictionary = {
	# ── XP / Leveling ────────────────────────────────────────────────────────
	"first_xp": {
		"name": "Getting Started", "rarity": "common",
		"description": "Gain your first XP.",
		"icon": preload("res://Sprites/Icons/Achievement/Level 1.png"),
	},
	"level_5": {
		"name": "Growing Strong", "rarity": "uncommon",
		"description": "Reach level 5.",
		"icon": preload("res://Sprites/Icons/Achievement/Level 5.png"),
	},
	"level_10": {
		"name": "Seasoned", "rarity": "rare",
		"description": "Reach level 10.",
		"icon": preload("res://Sprites/Icons/Achievement/Level 10.png"),
	},
	# ── Death ────────────────────────────────────────────────────────────────
	"first_death": {
		"name": "First Death", "rarity": "common",
		"description": "Die for the first time.",
		"icon": preload("res://Sprites/Icons/Achievement/Death 1.png"),
	},
	"death_10": {
		"name": "Getting Used To It", "rarity": "common",
		"description": "Die 10 times.", "goal": 10,
		"icon": preload("res://Sprites/Icons/Achievement/Death 10.png"),
	},
	"death_50": {
		"name": "Endless Suffering", "rarity": "uncommon",
		"description": "Die 50 times.", "goal": 50,
		"icon": preload("res://Sprites/Icons/Achievement/Death 50.png"),
	},
	# ── Crafting ─────────────────────────────────────────────────────────────
	"first_craft": {
		"name": "Crafting", "rarity": "common",
		"description": "Craft your first item.",
		"icon": preload("res://Sprites/Icons/Achievement/Craft 1.png"),
	},
	"craft_10": {
		"name": "Apprentice Crafter", "rarity": "uncommon",
		"description": "Craft 10 items.", "goal": 10,
		"icon": preload("res://Sprites/Icons/Achievement/Craft 10.png"),
	},
	"craft_25": {
		"name": "Expert Crafter", "rarity": "rare",
		"description": "Craft 25 items.", "goal": 25,
		"icon": preload("res://Sprites/Icons/Achievement/Craft 25.png"),
	},
	# ── Exploration ──────────────────────────────────────────────────────────
	"first_room": {
		"name": "Wanderer", "rarity": "common",
		"description": "Visit your first new area.",
		"icon": preload("res://Sprites/Icons/Achievement/Room 1.png"),
	},
}

# ─────────────────────────────────────────────────────────────────────────────
# RUNTIME STATE
# ─────────────────────────────────────────────────────────────────────────────

var unlocked: Dictionary = {}

var progress: Dictionary = {}

# ─────────────────────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	load_global()

# ─────────────────────────────────────────────────────────────────────────────
# CORE API
# ─────────────────────────────────────────────────────────────────────────────

func unlock(id: String) -> void:
	if not ACHIEVEMENTS.has(id):
		push_warning("AchievementManager: Unknown achievement id '%s'." % id)
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

	var goal: Variant = ACHIEVEMENTS[id].get("goal", null)
	if goal == null:
		push_warning("AchievementManager: '%s' has no goal; use unlock() instead." % id)
		return

	progress[id] = progress.get(id, 0) + amount
	achievement_progress_updated.emit(id, progress[id], goal)

	if progress[id] >= goal:
		unlock(id)


func get_progress(id: String) -> int:
	return progress.get(id, 0)


func is_unlocked(id: String) -> bool:
	return unlocked.get(id, false)

# ─────────────────────────────────────────────────────────────────────────────
# GAME EVENT HELPERS
# ─────────────────────────────────────────────────────────────────────────────

func register_death() -> void:
	unlock("first_death")
	add_progress("death_10", 1)
	add_progress("death_50", 1)


func register_craft(amount := 1) -> void:
	unlock("first_craft")
	add_progress("craft_10", amount)
	add_progress("craft_25", amount)


func register_xp() -> void:
	unlock("first_xp")


func register_level(level: int) -> void:
	if level >= 5:
		unlock("level_5")
	if level >= 10:
		unlock("level_10")


func register_room_visit() -> void:
	unlock("first_room")

# ─────────────────────────────────────────────────────────────────────────────
# SAVE / LOAD
# ─────────────────────────────────────────────────────────────────────────────

## Per-slot progress (unlocks are global and saved separately).
func get_progress_data() -> Dictionary:
	return { "progress": progress.duplicate(true) }


func load_progress_data(data: Dictionary) -> void:
	progress = data.get("progress", {}).duplicate(true)


## Global save — only stores `unlocked` dict.
func save_global() -> void:
	var file := FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("AchievementManager: Cannot write global save.")
		return
	file.store_string(JSON.stringify({ "unlocked": unlocked }, "\t"))
	file.close()


func load_global() -> void:
	if not FileAccess.file_exists(GLOBAL_SAVE_PATH):
		return
	var file := FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(data) == TYPE_DICTIONARY:
		unlocked = data.get("unlocked", {})


func reset() -> void:
	unlocked.clear()
	progress.clear()

# ─────────────────────────────────────────────────────────────────────────────
# UTILITY
# ─────────────────────────────────────────────────────────────────────────────

func get_sorted_achievements() -> Array[String]:
	var ids: Array[String] = []

	for id in ACHIEVEMENTS:
		ids.append(id)

	ids.sort_custom(func(a, b):
		var ra: int = RARITY_ORDER.get(ACHIEVEMENTS[a].get("rarity", "common"), 0)
		var rb: int = RARITY_ORDER.get(ACHIEVEMENTS[b].get("rarity", "common"), 0)
		return ra > rb
	)

	return ids
