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


var interacting := false

func _process(delta):
	if activated:
		return

	interacting = player_inside and Manager.pillar_interaction and Input.is_action_pressed("interact")

	if interacting:
		progress_bar.visible = true
		progress += fill_speed * delta
	else:
		progress -= drain_speed * delta

	progress = clamp(progress, 0, 100)
	progress_bar.value = progress

	if progress >= 100:
		activate()

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
