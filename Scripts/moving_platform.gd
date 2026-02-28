extends AnimatableBody2D

@export var distance := 200.0
@export var speed := 1.0
@export var move_horizontal := true

var start_position : Vector2
var time := 0.0

func _ready():
	start_position = global_position

func _physics_process(delta):
	time += delta * speed
	
	var offset = sin(time) * distance
	
	if move_horizontal:
		global_position.x = start_position.x + offset
	else:
		global_position.y = start_position.y + offset
