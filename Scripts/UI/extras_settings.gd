extends Control

@onready var container = $Panel/ScrollContainer/GridContainer
var item_scene = preload("res://Scenes/Control/achievement_item.tscn")

var max_achievements : int = 0
var unlocked_achievements : int = 0
@warning_ignore("narrowing_conversion")
var minimum_space : int = 10.0

func _ready():
	$Panel/Close.text = tr("CLOSE")
	
	for id in AchievementManager.ACHIEVEMENTS.keys():
		minimum_space += 100
		max_achievements += 1

		if AchievementManager.unlocked.get(id, false):
			unlocked_achievements += 1

		var item = item_scene.instantiate()
		container.add_child(item)
		item.setup(id)
	
	container.set_custom_minimum_size(Vector2(0.0,minimum_space))
	$Panel/Amount.text = (str(unlocked_achievements)+"/"+str(max_achievements))
	$Panel/Deaths.text = str(Manager.death_count) + " Deaths"
	$Panel/Playtime.text = str(int(Manager.game_seconds) -432) + " Seconds"
	$Panel/Level.text = "Level : " + str(Manager.level)
	
func _on_close_pressed() -> void:
	self.visible = false
