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
	
	$Panel/Container/Fullscreen.button_pressed = SettingsManager.fullscreen

	$Panel/Container/Music.button_pressed = SettingsManager.music_enabled
	$Panel/Container/SFX.button_pressed = SettingsManager.sfx_enabled
	$Panel/Container/Ambient.button_pressed = SettingsManager.ambient_enabled
	$Panel/Container/UI.button_pressed = SettingsManager.ui_enabled

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	SettingsManager.fullscreen = toggled_on
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
	
func _on_reset_pressed() -> void:

	for i in range(SaveManager.MAX_SLOTS):
		SaveManager.delete_save(i)

	AchievementManager.unlocked.clear()
	AchievementManager.progress.clear()

	var dir := DirAccess.open("user://")
	if dir:
		dir.remove("achievements_global.json")
		dir.remove("settings.json")

	Manager.reset_game(false)

	get_tree().reload_current_scene()
	
func _on_close_pressed() -> void:
	self.visible = false

func _on_music_toggled(toggled_on: bool) -> void:
	SettingsManager.music_enabled = toggled_on
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_sfx_toggled(toggled_on: bool) -> void:
	SettingsManager.sfx_enabled = toggled_on
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_ambient_toggled(toggled_on: bool) -> void:
	SettingsManager.ambient_enabled = toggled_on
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

func _on_ui_toggled(toggled_on: bool) -> void:
	SettingsManager.ui_enabled = toggled_on
	SettingsManager.apply_settings()
	SettingsManager.save_settings()
