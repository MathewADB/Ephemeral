extends Control

@onready var grid = $Panel/ScrollContainer/GridContainer
@onready var detail_icon = $Panel/InfoPanel/PanelContainer/Icon
@onready var detail_name = $Panel/InfoPanel/Name
@onready var detail_desc = $Panel/InfoPanel/Details

@onready var amount_label = $Panel/Amount

var item_scene = preload("res://Scenes/Control/achievement_item.tscn")

var max_achievements := 0


func _ready():
	build_grid()
	refresh()


# ================= GRID =================

func build_grid():
	for child in grid.get_children():
		child.queue_free()
	
	var ids = AchievementManager.ACHIEVEMENTS.keys()
	max_achievements = ids.size()
	$Panel/ProgressBar.max_value = ids.size()

	for id in ids:
		var item = item_scene.instantiate()
		grid.add_child(item)
		
		item.setup(id)
		item.pressed.connect(show_details)


# ================= DETAILS =================

func show_details(id: String):
	var data = AchievementManager.ACHIEVEMENTS[id]
	var unlocked = AchievementManager.unlocked.get(id, false)

	detail_icon.texture = data["icon"]
	detail_name.text = data["name"]

	if unlocked:
		detail_desc.text = data["description"]
	else:
		detail_desc.text = "???"


# ================= REFRESH =================

func refresh():
	var unlocked_count := 0

	for id in AchievementManager.ACHIEVEMENTS.keys():
		if AchievementManager.unlocked.get(id, false):
			unlocked_count += 1

	amount_label.text = str(unlocked_count) + "/" + str(max_achievements)
	$Panel/ProgressBar.value = unlocked_count

func _on_close_pressed() -> void:
	self.visible = false
