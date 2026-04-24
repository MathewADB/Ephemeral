extends Control

@onready var icon = $Icon
@onready var name_label = $Name
@onready var desc_label = $Description

func setup(id: String):
	var data = Manager.ACHIEVEMENT_DATA[id]
	var state = Manager.achievements[id]

	name_label.text = data["name"]

	if state["unlocked"]:
		icon.texture = data["icon"]
		icon.modulate = Color(1,1,1)
		desc_label.text = data["description"]
	else:
		icon.texture = data["icon"]
		icon.modulate = Color(0.3,0.3,0.3)
		desc_label.text = "???"
