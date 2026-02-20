extends Area2D

@export var Room_Name : String
@export var Room : String
@export var spawn_location : Vector2
@export var give_exp := false 

@warning_ignore("unused_parameter")
func _on_body_entered(body: Node2D) -> void:
	Manager.activate_spawn = true
	Manager.spawn_location = spawn_location
	Manager.current_room_scene = Room 
	
	UI.fade.visible = true
	UI.fade.fade_in()

	if not Manager.visited_rooms.has(Room):
		Manager.visited_rooms.append(Room)
		if give_exp :
			Manager.add_xp(200)
		UI.show_text_popup(Room_Name)

	get_tree().call_deferred("change_scene_to_file", Room)

	UI.fade.fade_out()
