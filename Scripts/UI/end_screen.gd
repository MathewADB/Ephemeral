extends Control


func _ready() -> void:
	UI.visible = false
	$Exit.text = tr("CLOSE")
	$CurseCured.text = tr("ENDING_TEXT")
	if Manager.end_triggered == true :
		$AnimationPlayer.play("ending")
	else :
		$AnimationPlayer.play("credits")

func _on_exit_pressed() -> void:
	Manager.save_game()
	get_tree().change_scene_to_file("res://Scenes/Control/main_menu.tscn")
