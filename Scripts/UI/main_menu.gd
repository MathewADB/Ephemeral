extends Control

func _ready() -> void:
	UI.hide_ui()


func _on_exit_pressed() -> void:
	get_tree().quit()
