extends Control

@onready var container = $Panel/ScrollContainer/GridContainer
var item_scene = preload("res://Scenes/Control/achievement_item.tscn")

var max_achievements : int = 0

func _ready():
	$Panel/Close.text = tr("CLOSE")

	for id in AchievementManager.ACHIEVEMENTS.keys():
		max_achievements += 1

		var item = item_scene.instantiate()
		container.add_child(item)
		item.setup(id)
		
	
	$Panel/ProgressBar.max_value = max_achievements
	refresh()

# ================= REFRESH =================

func refresh():
	var unlocked_count := 0

	for id in AchievementManager.ACHIEVEMENTS.keys():
		if AchievementManager.unlocked.get(id, false):
			unlocked_count += 1

	$Panel/Amount.text = str(unlocked_count) + "/" + str(max_achievements)
	$Panel/ProgressBar.value = unlocked_count
	
# ================= UI =================

func _on_close_pressed() -> void:
	self.visible = false
