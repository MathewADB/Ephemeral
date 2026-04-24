extends Control


func _ready() -> void:
	$Panel/Container/Data.text = tr("DATA")
	$Panel/Container/General.text = tr("GENERAL")
	$Panel/Close.text = tr("CLOSE")
	$Panel/Container/Reset.text = tr("RESET_GAME")
	$Panel/Container/Fullscreen.text = tr("FULLSCREEN")
	$Panel/Settings.text = tr("SETTINGS")
	
	$Panel/Container/Audio.text = tr("AUDIO")
	$Panel/Container/Music.text = tr("MUSIC")
	$Panel/Container/SFX.text = tr("SFX")
	$Panel/Container/Ambient.text = tr("AMBIENCE")
	$Panel/Container/UI.text = tr("UI")

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on :
		Manager.fullscreen = true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else :
		Manager.fullscreen = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_reset_pressed() -> void:
	Manager.delete_save()
	Manager.reset_game(false)

func _on_close_pressed() -> void:
	self.visible = false


func _on_music_toggled(toggled_on: bool) -> void:
	if toggled_on :
		Music.stream_paused = false
		
	else :
		Music.stream_paused = true
