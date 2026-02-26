extends Node2D

@onready var anim := $AnimationPlayer

@warning_ignore("unused_parameter")
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not anim.is_playing():
		anim.play("bend")
