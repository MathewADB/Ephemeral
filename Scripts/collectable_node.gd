extends Sprite2D
class_name InfiniteCollectable

@onready var resource_bar = $ProgressBar

@export var unique_id : String

@export var max_count : int = 5
@export var regen_time : float = 60.0
@export var mine_time : float = 1.0
@export var collectable_name : String
@export var tier : int
@export var xp : int

var count : int
var progress := 0.0

func _ready():
	if Manager.resource_nodes.has(unique_id):
		Manager.update_resource(unique_id, max_count, regen_time)
		count = Manager.resource_nodes[unique_id]["count"]
	else:
		count = max_count
		Manager.set_resource(unique_id, count)

	resource_bar.max_value = max_count
	update_visual()
	update_bar()

func mine(amount: int):
	count -= amount
	count = max(count, 0)

	Manager.set_resource(unique_id, count)

	update_visual()
	update_bar()
	
func update_visual():
	if count <= 0:
		modulate = Color(0.4, 0.4, 0.4) # empty (dark)
	else:
		modulate = Color(1, 1, 1) # full
	
func update_bar():
	if resource_bar:
		resource_bar.value = count
	
