extends Node

signal upgrades_changed
signal upgrade_learned(name)

# --- DATA ---

var learned_upgrades: Array = []

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

# --- CORE LOGIC ---

func can_learn(upgrade_name: String) -> bool:
	if upgrade_name == "" or upgrade_name == null:
		return false
		
	if upgrade_name in learned_upgrades:
		return false
		
	var u = upgrades.get(upgrade_name, null)
	if u == null:
		return false

	if Manager.skill_points < u.skill_cost:
		return false

	for mat in u.materials.keys():
		if not InventoryManager.has_item(mat, u.materials[mat]):
			return false

	for req in u.requires:
		if req not in learned_upgrades:
			return false

	return true


func learn(upgrade_name: String) -> bool:
	if not can_learn(upgrade_name):
		return false

	var u = upgrades[upgrade_name]

	# Spend skill points
	Manager.skill_points -= u.skill_cost
	Manager.skill_points_changed.emit(Manager.skill_points)

	# Remove materials
	for mat in u.materials.keys():
		InventoryManager.remove_item(mat, u.materials[mat])

	# Add upgrade
	if upgrade_name not in learned_upgrades:
		learned_upgrades.append(upgrade_name)

	apply_effects()

	upgrade_learned.emit(upgrade_name)
	upgrades_changed.emit()

	Manager.save_game()

	return true


# --- APPLY EFFECTS ---

func apply_effects():
	# Reset stats first
	for key in Manager.BASE_STATS.keys():
		Manager.set(key, Manager.BASE_STATS[key])

	# Apply all upgrades
	for upgrade_name in learned_upgrades:
		var u = upgrades.get(upgrade_name, null)
		if u == null:
			continue

		var effect = u.get("effect", {})
		for stat in effect.keys():
			Manager.set(stat, effect[stat])

	if Manager.player:
		Manager.player.set_stats()
