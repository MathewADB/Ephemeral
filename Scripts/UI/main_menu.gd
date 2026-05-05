extends Control

var debug_hour := -1

func _ready() -> void:
	
	$ProfileSelector.visible = false
	$MenuSettings.visible = false
	$ExtrasSettings.visible = false
	$VersionPage.visible = false
	
	update_background_by_time()

	if SettingsManager.fullscreen: 
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	TranslationServer.set_locale(SettingsManager.selected_language)
	
	refresh_texts()
	
	UI.hide_ui()
	UI.fade_out()
		
#defualt 00000d86
func update_background_by_time():
	var hour : int

	if debug_hour != -1:
		hour = debug_hour
	else:
		hour = Time.get_datetime_dict_from_system().hour

	var dark := Color(0.0, 0.0, 0.051, 1.0)
	var color : Color

	if hour >= 6 and hour < 10:
		color = dark
		color.a = 0.25

	elif hour >= 10 and hour < 17:
		color = dark
		color.a = 0.35

	elif hour >= 17 and hour < 20:
		color = dark
		color.a = 0.55
	else:
		color = dark
		color.a = 0.75

	$Background/BackGroundNight.color = color
	
func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_credit_pressed() -> void:
	AudioManager.play_sfx("confirm")
	get_tree().change_scene_to_file("res://Scenes/Control/end_screen.tscn")

func _on_new_game_pressed() -> void:
	AudioManager.play_sfx("confirm")
	$ProfileSelector.visible = true

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("confirm")
	$MenuSettings.visible = true

func _on_language_pressed() -> void:
	AudioManager.play_sfx("confirm")

	if SettingsManager.selected_language == "EN":
		SettingsManager.selected_language = "DE"
	else:
		SettingsManager.selected_language = "EN"

	SettingsManager.apply_settings()
	SettingsManager.save_settings() 

	refresh_texts()
			
func refresh_texts():
	$MenuButtons/Play.text = tr("PLAY")
	$MenuButtons/Settings.text = tr("SETTINGS")
	$MenuButtons/Extras.text = tr("EXTRAS")
	$MenuButtons/Credit.text = tr("CREDITS")
	$MenuButtons/Exit.text = tr("EXIT")
	
	$Labels/Language.text = SettingsManager.selected_language
	$Labels/Update.text = tr("ALPHA_VERSION")

	$Labels/Version.text = "v%s %s" % [
		ProjectSettings.get_setting("application/config/version"),
		tr("ALPHA_VERSION")
	]
	
func _on_extras_pressed() -> void:
	AudioManager.play_sfx("confirm")
	$ExtrasSettings.visible = true
	$ExtrasSettings.refresh()
	
func _on_version_pressed() -> void:
	AudioManager.play_sfx("confirm")
	$VersionPage.visible = true

func _on_close_pressed() -> void:
	$ProfileSelector.visible = false

func animate_to_day():
	var bg = $Background/BackGroundNight
	
	var target_color := Color(0.0, 0.0, 0.039, 0.2)

	var tween := get_tree().create_tween()
	tween.tween_property(bg, "color", target_color, 2.5) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	
func start_game() :
	$MenuButtons.visible = false
	$Social.visible = false
	$Labels.visible = false
	$ProfileSelector.visible = false
	animate_to_day()
	$AnimationPlayer.play("wake_up")
	await get_tree().create_timer(3.2).timeout 
	UI.fade_in()
	await get_tree().create_timer(0.5).timeout 
	UI.show_ui()
	get_tree().change_scene_to_file(Manager.current_room_scene)
	UI.fade_out()
