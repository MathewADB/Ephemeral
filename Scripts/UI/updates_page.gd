extends Control

func _ready() -> void:
	$Panel/Close.text = tr("CLOSE")
	
func _on_close_pressed() -> void:
	self.visible = false
