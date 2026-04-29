extends Button

@export var slot_id: int

func _ready():
	update_ui()

func update_ui():
	if SaveManager.slot_exists(slot_id):
		var meta = SaveManager.get_slot_meta(slot_id)

		var level = meta.get("level", 1)
		var playtime = meta.get("playtime", 0)

		text = "Slot %d - Lv.%d - %ds" % [slot_id + 1, level, playtime]
	else:
		text = "Slot %d - New Game" % (slot_id + 1)


func _pressed():
	if SaveManager.slot_exists(slot_id):
		Manager.load_game(slot_id)
	else:
		Manager.current_slot = slot_id
		Manager.reset_game(false)

	get_tree().change_scene_to_file(Manager.current_room_scene)
