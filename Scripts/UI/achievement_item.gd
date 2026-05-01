extends Control

signal pressed(id: String)

@onready var icon = $Icon
@onready var border = $PanelBorder

var achievement_id: String


func setup(id: String):
	achievement_id = id
	
	var data = AchievementManager.ACHIEVEMENTS[id]
	var unlocked = AchievementManager.unlocked.get(id, false)
	var rarity = data.get("rarity", "common")
	border.modulate = AchievementManager.RARITY_COLORS[rarity] if unlocked else Color(0.3,0.3,0.3)
	icon.texture = data["icon"]
	
	if unlocked:
		$ColorRect.color = Color(1.0, 1.0, 1.0, 1.0)
	else:
		$ColorRect.color = Color(0.3, 0.3, 0.3)


func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		pressed.emit(achievement_id)
