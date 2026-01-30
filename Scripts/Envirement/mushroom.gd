extends Area2D

@export var jump_force := 500

func _on_body_entered(body: Node2D) -> void:
	if body.velocity.y > 0:
		body.velocity.y = -jump_force
