extends Area2D

@export var jump_force := 475

func _on_body_entered(body: Node2D) -> void:
	if body.velocity.y > 0:
		$AnimationPlayer.play("jump")
		body.jump_released = false
		body.velocity.y = -jump_force
		body.velocity.x *= 1.1
		await $AnimationPlayer.animation_finished
		$AnimationPlayer.play("idle")
