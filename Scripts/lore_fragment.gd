extends Collectable

var player : CharacterBody2D = null

@export var lore_text : String

func _on_detection_body_entered(body: Node2D) -> void:
	UI.show_text_popup(lore_text)
	player = body
	player.mineable = self
	
@warning_ignore("unused_parameter")
func _on_detection_body_exited(body: Node2D) -> void:
	player.mineable = null
	player = null
