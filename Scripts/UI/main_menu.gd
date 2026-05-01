extends Control

@onready var fade : ColorRect = $Fade

var debug_hour := -1

func _ready() -> void:
	
	$ProfileSelector.visible = false
	$MenuSettings.visible = false
	$ExtrasSettings.visible = false
	$VersionPage.visible = false
	
	update_background_by_time()

	if Manager.fullscreen == true :
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	TranslationServer.set_locale(Manager.selected_language)
	
	refresh_texts()
	
	UI.hide_ui()
	fade.modulate = Color(0.0, 0.0, 0.0, 1.0)
	fade_out()
		
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
	
func fade_out():
	var tween := get_tree().create_tween()
	tween.tween_property(fade, "modulate:a", 0, 0.5)
	
func fade_in():
	var tween := get_tree().create_tween()
	tween.tween_property(fade, "modulate:a", 1, 0.5)
	
func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_credit_pressed() -> void:
	AudioManager.play_sfx("confirm")
	get_tree().change_scene_to_file("res://Scenes/Control/end_screen.tscn")

func _on_new_game_pressed() -> void:
	AudioManager.play_sfx("confirm")
	$ProfileSelector.visible = true

func start_game() -> void:
	fade_in()
	await get_tree().create_timer(0.5).timeout
	UI.show_ui()
	get_tree().change_scene_to_file(Manager.current_room_scene)

func _on_settings_pressed() -> void:
	AudioManager.play_sfx("confirm")
	$MenuSettings.visible = true

func _on_language_pressed() -> void:
	AudioManager.play_sfx("confirm")

	if Manager.selected_language == "EN":
		Manager.selected_language = "DE"
	else:
		Manager.selected_language = "EN"

	Manager.apply_settings()
	Manager.save_settings() 

	refresh_texts()
			
func refresh_texts():
	$MenuButtons/Play.text = tr("PLAY")
	$MenuButtons/Settings.text = tr("SETTINGS")
	$MenuButtons/Extras.text = tr("EXTRAS")
	$MenuButtons/Credit.text = tr("CREDITS")
	$MenuButtons/Exit.text = tr("EXIT")
	
	$Labels/Language.text = Manager.selected_language
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
