extends StaticBody2D

@export var door_id : String
@export var required_count := 3

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

var activated_count := 0
var opened := false

func _ready():
	restore_state()
	
func restore_state():
	opened = false
	activated_count = 0
	
	for key in Manager.collected_objects.keys():
		if key.begins_with(door_id + "_pillar_"):
			activated_count += 1

	if Manager.collected_objects.has(door_id + "_opened"):
		open(false)
		return

	if activated_count >= required_count:
		open(true)
		
func register_pillar():
	restore_state()

func open(give_reward: bool):
	if opened:
		return
		
	opened = true
	
	collision.disabled = true
	sprite.frame = 1
	
	Manager.collected_objects[door_id + "_opened"] = true
	
	if give_reward:
		Manager.add_xp(50)
	
	Manager.save_game()
