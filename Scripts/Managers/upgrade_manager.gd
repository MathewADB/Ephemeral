extends Node

# =============================================================================
# UPGRADE MANAGER — Skill tree: learning, requirements, stat application
# Autoload name: UpgradeManager
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────────────────────

signal upgrades_changed
signal upgrade_learned(upgrade_name: String)
## Emitted when learn() is attempted but fails (for UI feedback).
signal upgrade_failed(upgrade_name: String, reason: String)

# ─────────────────────────────────────────────────────────────────────────────
# UPGRADE REGISTRY
# ─────────────────────────────────────────────────────────────────────────────
#
# Each entry:
#   skill_cost  int               — skill points consumed
#   materials   {item: amount}    — items consumed on learn
#   requires    [upgrade_name]    — prerequisites (ALL must be learned)
#   effect      {stat: value}     — stats set on Manager when applied
#   description String (optional) — shown in skill-tree UI
#   category    String (optional) — for grouping in UI
#
const UPGRADES: Dictionary = {
	# ── Mining ──────────────────────────────────────────────────────────────
	"Mining Tier I": {
		"skill_cost": 1, "materials": {},
		"requires": [], "effect": { "mining_tier": 1 },
		"description": "Allows mining standard ores.", "category": "mining",
	},
	"Mining Tier II": {
		"skill_cost": 1, "materials": { "Ruby Gem": 10 },
		"requires": ["Mining Tier I"], "effect": { "mining_tier": 2 },
		"description": "Allows mining harder ore veins.", "category": "mining",
	},
	"Mining Speed I": {
		"skill_cost": 1, "materials": { "Ruby Stone": 5 },
		"requires": ["Mining Tier I"], "effect": { "mining_speed_level": 2 },
		"description": "Increases mining speed.", "category": "mining",
	},
	"Mining Speed II": {
		"skill_cost": 1, "materials": { "Ruby Stone": 20 },
		"requires": ["Mining Speed I", "Mining Tier II"],
		"effect": { "mining_speed_level": 3 },
		"description": "Further increases mining speed.", "category": "mining",
	},
	# ── Movement ─────────────────────────────────────────────────────────────
	"Double Jump": {
		"skill_cost": 1, "materials": { "Double Jump Scroll": 1 },
		"requires": [], "effect": { "base_extra_jumps": 1 },
		"description": "Grants a second jump in the air.", "category": "movement",
	},
	"Triple Jump": {
		"skill_cost": 1, "materials": { "Triple Jump Scroll": 1 },
		"requires": ["Double Jump"], "effect": { "base_extra_jumps": 2 },
		"description": "Grants a third jump in the air.", "category": "movement",
	},
	"Mobility I": {
		"skill_cost": 1, "materials": {},
		"requires": ["Double Jump"], "effect": { "player_mobility": 1.05 },
		"description": "Slightly increases movement speed.", "category": "movement",
	},
	"Mobility II": {
		"skill_cost": 1, "materials": {},
		"requires": ["Mobility I", "Triple Jump"], "effect": { "player_mobility": 1.1 },
		"description": "Noticeably increases movement speed.", "category": "movement",
	},
	# ── Utility ──────────────────────────────────────────────────────────────
	"Light I": {
		"skill_cost": 1, "materials": { "Dust Gem": 1 },
		"requires": ["Pillar Interaction"], "effect": { "light_level": 1 },
		"description": "Emits a faint glow in the dark.", "category": "utility",
	},
	"Light II": {
		"skill_cost": 1, "materials": {},
		"requires": ["Light I"], "effect": { "light_level": 2 },
		"description": "Increases light radius.", "category": "utility",
	},
	"Light III": {
		"skill_cost": 1, "materials": {},
		"requires": ["Light II"], "effect": { "light_level": 3 },
		"description": "Maximises light radius.", "category": "utility",
	},
	"Hiding": {
		"skill_cost": 1, "materials": {},
		"requires": [], "effect": { "hide_unlocked": true },
		"description": "Allows the player to hide from enemies.", "category": "utility",
	},
	"Pillar Interaction": {
		"skill_cost": 1, "materials": {},
		"requires": [], "effect": { "pillar_interaction": true },
		"description": "Unlocks interaction with ancient pillars.", "category": "utility",
	},
	"Map": {
		"skill_cost": 1, "materials": {},
		"requires": [], "effect": { "map_unlocked": true },
		"description": "Unlocks the world map.", "category": "utility",
	},
}

# ─────────────────────────────────────────────────────────────────────────────
# RUNTIME STATE
# ─────────────────────────────────────────────────────────────────────────────

var learned_upgrades: Array[String] = []

# ─────────────────────────────────────────────────────────────────────────────
# QUERIES
# ─────────────────────────────────────────────────────────────────────────────

func is_learned(upgrade_name: String) -> bool:
	return upgrade_name in learned_upgrades


func can_learn(upgrade_name: String) -> bool:
	if upgrade_name == "":
		return false
	if is_learned(upgrade_name):
		return false

	var u: Dictionary = UPGRADES.get(upgrade_name, {})
	if u.is_empty():
		return false

	if Manager.skill_points < u["skill_cost"]:
		return false

	for mat in u["materials"]:
		if not InventoryManager.has_item(mat, u["materials"][mat]):
			return false

	for req in u["requires"]:
		if not is_learned(req):
			return false

	return true


## Returns a human-readable reason why `upgrade_name` cannot be learned,
## or "" if it can. Useful for tooltips.
func get_blocked_reason(upgrade_name: String) -> String:
	if is_learned(upgrade_name):
		return "Already learned."

	var u: Dictionary = UPGRADES.get(upgrade_name, {})
	if u.is_empty():
		return "Unknown upgrade."

	if Manager.skill_points < u["skill_cost"]:
		return "Not enough skill points (%d required)." % u["skill_cost"]

	for mat in u["materials"]:
		if not InventoryManager.has_item(mat, u["materials"][mat]):
			return "Missing: %s ×%d" % [mat, u["materials"][mat]]

	for req in u["requires"]:
		if not is_learned(req):
			return "Requires: %s" % req

	return ""


## Returns all upgrades that are available to learn right now.
func get_available_upgrades() -> Array[String]:
	var result: Array[String] = []
	@warning_ignore("shadowed_variable_base_class")
	for name in UPGRADES:
		if can_learn(name):
			result.append(name)
	return result

# ─────────────────────────────────────────────────────────────────────────────
# LEARN
# ─────────────────────────────────────────────────────────────────────────────

func learn(upgrade_name: String) -> bool:
	if not can_learn(upgrade_name):
		upgrade_failed.emit(upgrade_name, get_blocked_reason(upgrade_name))
		return false

	var u: Dictionary = UPGRADES[upgrade_name]

	Manager.skill_points -= u["skill_cost"]
	Manager.skill_points_changed.emit(Manager.skill_points)

	for mat in u["materials"]:
		InventoryManager.remove_item(mat, u["materials"][mat])

	learned_upgrades.append(upgrade_name)

	apply_effects()
	upgrade_learned.emit(upgrade_name)
	upgrades_changed.emit()

	Manager.save_game()
	return true

# ─────────────────────────────────────────────────────────────────────────────
# APPLY EFFECTS
# ─────────────────────────────────────────────────────────────────────────────

## Resets all stats to BASE_STATS then re-applies every learned upgrade.
## Called after load, reset, or learning a new upgrade.
func apply_effects() -> void:
	# Reset
	for key in Manager.BASE_STATS:
		Manager.set(key, Manager.BASE_STATS[key])

	# Apply in learn order (preserves last-write-wins for conflicting stats)
	@warning_ignore("shadowed_variable_base_class")
	for name in learned_upgrades:
		var u: Dictionary = UPGRADES[name]
		if u.is_empty():
			continue
		for stat in u["effect"]:
			Manager.set(stat, u["effect"][stat])

	if Manager.player:
		Manager.player.set_stats()
	Manager.emit_signal("map_updated")
