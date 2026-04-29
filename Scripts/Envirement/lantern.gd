extends Area2D

@export var unique_id : String
@export var dust_gem_cost : int = 1

@onready var sprite = $Sprite2D

var is_lit := false
var player_in := false

func _ready():
	if Manager.collected_objects.has(unique_id):
		set_lit(true)

@warning_ignore("unused_parameter")
func _process(delta):
	if is_lit:
		return
	
	if not player_in:
		return
	
	if Input.is_action_just_pressed("interact"):
		try_light()

func set_lit(state: bool):
	is_lit = state
	sprite.frame = int(is_lit)

func try_light():
	if is_lit:
		return

	if not InventoryManager.has_item("Dust Gem", dust_gem_cost):
		return

	InventoryManager.remove_item("Dust Gem", dust_gem_cost)

	Manager.collected_objects[unique_id] = true
	Manager.save_game()
	Manager.add_xp(50)

	set_lit(true)

@warning_ignore("unused_parameter")
func _on_body_entered(body: Node2D) -> void:
	player_in = true

@warning_ignore("unused_parameter")
func _on_body_exited(body: Node2D) -> void:
	player_in = false
