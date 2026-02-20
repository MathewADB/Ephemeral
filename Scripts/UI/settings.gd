extends Control

func _on_quit_pressed() -> void:
	Manager.save_game()
	$"..".close_menu()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Control/main_menu.tscn")
