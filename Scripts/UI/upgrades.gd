extends Control

@onready var PointsLabel = $SkillPoints
@onready var upgrade_buttons = $Buttons.get_children()
@onready var info_name = $InfoPanel/UpgradeName
@onready var info_desc = $InfoPanel/UpgradeInfo
@onready var info_cost = $InfoPanel/UpgradeCost
@onready var learn_button = $InfoPanel/Learn

var selected_button: BaseButton = null
var selected_upgrade = null

var upgrades := {
	
	"Mining Tier I":{
		"name": "Mining Tier I",
		"info": "Allows Mining Tier I Collectables",
		"skill_cost": 1,
		"materials": {},
		"requires": [],
		"learned": false
	},
	"Mining Tier II":{
		"name": "Mining Tier II",
		"info": "Allows Mining Tier I Collectables",
		"skill_cost": 1,
		"materials": {"Ruby Gem": 10},
		"requires": ["Mining Tier I"],
		"learned": false
	},
	"Mining Speed I": {
		"name": "Mining Speed I",
		"info": "Increases mining speed",
		"skill_cost": 1,
		"materials": {"Ruby Stone": 5}, 
		"requires": [],
		"learned": false
	},
	"Mining Speed II": {
		"name": "Mining Speed II",
		"info": "Greatly increases mining speed",
		"skill_cost": 1,
		"materials": {"Ruby Stone": 20},
		"requires": ["Mining Speed I"],
		"learned": false
	},
	"Mobility I":{
		"name": "Mobility I",
		"info": "Makes you move a bit faster",
		"skill_cost": 1,
		"materials": {},
		"requires": [],
		"learned": false
	},
	"Mobility II":{
		"name": "Mobility II",
		"info": "Makes you move faster",
		"skill_cost": 1,
		"materials": {},
		"requires": ["Mobility I"],
		"learned": false
	},
	"Light I":{
		"name": "Light I",
		"info": "By pressing B You can cast a small light",
		"skill_cost": 1,
		"materials": {},
		"requires": [],
		"learned": false
	},
	"Light II":{
		"name": "Light II",
		"info": "By pressing B You can cast a medium light",
		"skill_cost": 1,
		"materials": {},
		"requires": ["Light I"],
		"learned": false
	},
	"Light III":{
		"name": "Light III",
		"info": "By pressing B You can cast a huge light",
		"skill_cost": 1,
		"materials": {},
		"requires": ["Light II"],
		"learned": false
	},
	"Hiding":{
		"name": "Hiding",
		"info": "Allows you to hide in your hat by pressing C",
		"skill_cost": 1,
		"materials": {},
		"requires": [],
		"learned": false
	},
	"Double Jump":{
		"name": "Double Jump",
		"info": "Allows you to jump mid air",
		"skill_cost": 0,
		"materials": {"Double Jump Scroll":1},
		"requires": [],
		"learned": false
	},
	"Triple Jump":{
		"name": "Triple Jump",
		"info": "Allows you to jump twice mid air",
		"skill_cost": 0,
		"materials": {"Triple Jump Scroll":1},
		"requires": ["Double Jump"],
		"learned": false
	}
	}

func _ready() -> void:
	Manager.skill_points_changed.connect(update_skill_points)
	update_skill_points(Manager.skill_points)

	for i in range(upgrade_buttons.size()):
		var btn = upgrade_buttons[i]
		btn.pressed.connect(Callable(self, "_on_upgrade_button_pressed").bind(i))

	var learn_callable = Callable(self, "_on_learn_pressed")
	if learn_button.is_connected("pressed", learn_callable):
		learn_button.disconnect("pressed", learn_callable)
	learn_button.connect("pressed", learn_callable)

	refresh_upgrade_buttons()

func _on_upgrade_button_pressed(index: int) -> void:
	var key = upgrades.keys()[index]
	selected_upgrade = upgrades[key]

	info_name.text = selected_upgrade["name"]
	info_desc.text = selected_upgrade["info"]

	var cost_text = ""
	if selected_upgrade["skill_cost"] > 0:
		cost_text += "Skill Points: " + str(selected_upgrade["skill_cost"]) + "\n"
	if selected_upgrade["materials"].size() > 0:
		for mat in selected_upgrade["materials"]:
			cost_text += mat + ": " + str(selected_upgrade["materials"][mat]) + "\n"
	if selected_upgrade["requires"].size() > 0:
		cost_text += "Requires: " + ", ".join(selected_upgrade["requires"])
	
	info_cost.text = cost_text

	learn_button.disabled = not can_learn_upgrade(selected_upgrade)

	# --- Update selected button color ---
	if selected_button:
		# Reset previous button color
		var prev_key = upgrades.keys()[upgrade_buttons.find(selected_button)]
		if upgrades[prev_key].get("learned", false):
			selected_button.modulate = Color(1,1,1,1)
		elif not can_learn_upgrade(upgrades[prev_key]):
			selected_button.modulate = Color(0,0,0,1)
		else:
			selected_button.modulate = Color(1,1,1,1)

	selected_button = upgrade_buttons[index]
	selected_button.modulate = Color(0.728, 0.877, 0.97, 1.0)  # Highlight color
	
func update_skill_points(points: int) -> void:
	PointsLabel.text = "Skill Points: " + str(points)


# ===== Upgrade Logic =====
func can_learn_upgrade(upgrade: Dictionary) -> bool:
	
	if upgrade.get("learned", false):
		return false

	if Manager.skill_points < upgrade["skill_cost"]:
		return false

	for mat in upgrade["materials"]:
		if not Manager.items.has(mat) or Manager.items[mat] < upgrade["materials"][mat]:
			return false

	for req in upgrade["requires"]:
		if not upgrades[req].get("learned", false):
			return false

	return true


func _on_learn_pressed() -> void:
	if selected_upgrade == null:
		return
	if not can_learn_upgrade(selected_upgrade):
		return

	Manager.skill_points -= selected_upgrade["skill_cost"]
	Manager.skill_points_changed.emit(Manager.skill_points)

	for mat in selected_upgrade["materials"]:
		Manager.remove_item(mat, selected_upgrade["materials"][mat])

	selected_upgrade["learned"] = true

	apply_upgrade_effect(selected_upgrade)
	if Manager.player :
		Manager.player.set_stats()
		
	_on_upgrade_button_pressed(upgrades.keys().find(selected_upgrade["name"]))
	refresh_upgrade_buttons()


# ===== Gray out learned buttons =====
func refresh_upgrade_buttons() -> void:
	for i in range(upgrade_buttons.size()):
		var key = upgrades.keys()[i]
		var btn = upgrade_buttons[i]

		if upgrades[key].get("learned", false):
			btn.disabled = true
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0) 
		elif not can_learn_upgrade(upgrades[key]):
			btn.disabled = true
			btn.modulate = Color(0.0, 0.0, 0.0, 1.0) 
		else:
			btn.disabled = false
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0) 

# ===== Upgrade Effects =====
func apply_upgrade_effect(upgrade: Dictionary) -> void:
	match upgrade["name"]:
		"Mining Speed I":
			Manager.mining_speed_level = 2
		"Mining Speed II":
			Manager.mining_speed_level = 3
		"Double Jump":
			Manager.base_extra_jumps = 1
		"Triple Jump":
			Manager.base_extra_jumps = 2
		"Mining Tier I":
			Manager.mining_tier = 1
		"Mining Tier II":
			Manager.mining_tier = 2
		"Mobility I":
			Manager.player_mobility = 1.05
		"Mobility II":
			Manager.player_mobility = 1.1
		"Light I":
			Manager.light_level = 1
		"Light II":
			Manager.light_level = 2
		"Light III":
			Manager.light_level = 3
		"Hiding":
			Manager.hide_unlocked = true
		_:
			pass
