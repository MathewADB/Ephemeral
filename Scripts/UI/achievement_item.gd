extends Control

@onready var icon = $Icon
@onready var name_label = $Name
@onready var desc_label = $Description

func setup(id: String):
	var data = AchievementManager.ACHIEVEMENTS[id]
	var unlocked = AchievementManager.unlocked.get(id, false)

	name_label.text = data["name"]

	icon.texture = data["icon"]

	if unlocked:
		icon.modulate = Color(1, 1, 1)
		desc_label.text = data["description"]
	else:
		icon.modulate = Color(0.3, 0.3, 0.3)
		desc_label.text = "???"
