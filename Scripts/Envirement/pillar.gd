extends Area2D

@export var unique_id : String
@export var door : Node
@export var fill_speed := 120.0
@export var drain_speed := 80.0

@onready var progress_bar = $TextureProgressBar
@onready var sprite = $Sprite2D

var progress := 0.0
var activated := false
var player_inside := false


func _ready():
	progress_bar.visible = false
	
	if Manager.collected_objects.has(unique_id):
		activate()


func _process(delta):
	if activated:
		return
	
	if not player_inside:
		progress = max(progress - drain_speed * delta, 0)
		progress_bar.value = progress
		if progress <= 0:
			progress_bar.visible = false
		return
	
	if not Manager.pillar_interaction:
		return
	
	if Input.is_action_just_pressed("interact"):
		progress_bar.visible = true
		progress += fill_speed * delta * 8
		progress_bar.value = progress
		
		if progress >= 100:
			activate()
	else:
		progress = max(progress - drain_speed * delta, 0)
		progress_bar.value = progress
		if progress <= 0:
			progress_bar.visible = false


func activate():
	if activated:
		return
		
	activated = true
	progress_bar.visible = false
	sprite.frame = 0
	
	Manager.collected_objects[unique_id] = true
	Manager.save_game()

	door.register_pillar()


func _on_body_entered(body):
	if body is CharacterBody2D:
		player_inside = true


func _on_body_exited(body):
	if body is CharacterBody2D:
		player_inside = false
