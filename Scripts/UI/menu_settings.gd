extends Control


func _ready() -> void:
	$Panel/Close.text = tr("CLOSE")
	$Panel/Reset.text = tr("RESET_GAME")
	$Panel/Fullscreen.text = tr("FULLSCREEN")
	$Panel/Settings.text = tr("SETTINGS")


func _on_fullscreen_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Manager.fullscreen = true

func _on_reset_pressed() -> void:
	Manager.delete_save()
	Manager.reset_game(false)

func _on_close_pressed() -> void:
	self.visible = false
