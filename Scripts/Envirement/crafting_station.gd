extends Area2D

var player_in_range := false

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false

@warning_ignore("unused_parameter")
func _process(delta):
	if player_in_range and Input.is_action_just_pressed("interact") :
		UI.open_crafting()
