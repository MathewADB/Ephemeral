extends Node2D

@export var bird_scene : PackedScene
@export var spawn_chance := 0.3  # 30% chance

func _ready():
	# Randomly spawn bird
	if randf() <= spawn_chance:
		var bird = bird_scene.instantiate()
		get_parent().call_deferred("add_child", bird)
		bird.global_position = global_position
	
	# Remove spawner immediately, no leftover cost
	queue_free()
