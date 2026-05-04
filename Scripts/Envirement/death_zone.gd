extends Area2D

@export var tutorial : bool

func _on_body_entered(body: Node2D) -> void:
	body.freeze_camera(true)
	body.ignore_fall_damage = true
	await get_tree().create_timer(0.5).timeout
	body.position = body.save_location
	body.freeze_camera(false)
	await get_tree().create_timer(0.2).timeout
	body.ignore_fall_damage = false

	
