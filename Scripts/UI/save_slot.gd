extends HBoxContainer

@export var slot_id: int

@onready var play_button = $Play
@onready var delete_button = $Delete


func _ready():
	add_to_group("save_slots")
	get_tree().call_group("save_slots", "refresh")

# ================= UI =================

func refresh():
	var exists = SaveManager.slot_exists(slot_id)

	if exists:
		var meta = SaveManager.get_slot_meta(slot_id)

		var level = meta.get("level", 1)
		var playtime = meta.get("playtime", 0)

		play_button.text = "Slot %d - Lv.%d - %ds" % [slot_id + 1, level, playtime - 432] 
		delete_button.disabled = false
	else:
		play_button.text = "Slot %d - New Game" % (slot_id + 1)
		delete_button.disabled = true


# ================= ACTIONS =================

func _on_play_pressed() -> void:
	#UI.show_ui()
	if SaveManager.slot_exists(slot_id):
		Manager.load_game(slot_id)
	else:
		Manager.current_slot = slot_id
		Manager.reset_game(false)
	
	var main_menu = get_parent().get_parent().get_parent().get_parent()

	main_menu.start_game()
	
	#get_tree().change_scene_to_file(Manager.current_room_scene)


func _on_delete_pressed() -> void:
	AudioManager.play_sfx("confirm")

	SaveManager.delete_save(slot_id)

	if Manager.current_slot == slot_id:
		Manager.current_slot = -1

	refresh()
