extends Control


func _ready() -> void:
	UI.visible = false

func _on_exit_pressed() -> void:
	Manager.save_game()
	get_tree().change_scene_to_file("res://Scenes/Control/main_menu.tscn")
