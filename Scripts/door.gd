extends Area2D


@export var Room : String
@export var spawn_location : Vector2

@warning_ignore("unused_parameter")
func _on_body_entered(body: Node2D) -> void:
	Manager.activate_spawn = true
	Manager.spawn_location = spawn_location
	get_tree().call_deferred("change_scene_to_file",Room)
