extends Control

@onready var container = $Panel/ScrollContainer/GridContainer
var item_scene = preload("res://Scenes/Control/achievement_item.tscn")

func _ready():
	$Panel/Close.text = tr("CLOSE")
	for id in Manager.ACHIEVEMENT_DATA.keys():
		var item = item_scene.instantiate()
		container.add_child(item)
		item.setup(id)


func _on_close_pressed() -> void:
	self.visible = false
