extends Sprite2D
class_name Collectable

@export var unique_id : String

@export var count : int
@export var mine_time : float
@export var collectable_name : String
@export var tier : int
@export var xp : int

var progress := 0.0

func _ready():
	if Manager.collected_objects.has(unique_id):
		queue_free()
