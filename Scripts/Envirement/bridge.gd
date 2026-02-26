extends Node2D

@onready var sprite = $Sprite2D
@onready var area = $CollisionShape2D

@export var unique_id : String        # unique for saving
@export var stone_required := 10
@export var dustgem_required := 5
@export var exp_stage2 := 50
@export var exp_stage3 := 50

@export var upgrade_time := 30.0  # seconds

var upgrading := false
var upgrade_timer := 0.0
var upgrade_target_stage := 0

var stage := 0       # 0=broken, 1=repaired, 2=fancy
var player_inside := false

func _ready():
	restore_state()

func restore_state():
	stage = Manager.collected_objects.get(unique_id + "_stage", 0)
	upgrading = Manager.collected_objects.get(unique_id + "_upgrading", false)
	upgrade_timer = Manager.collected_objects.get(unique_id + "_upgrade_timer", 0.0)
	upgrade_target_stage = Manager.collected_objects.get(unique_id + "_upgrade_target_stage", stage)
	update_sprite()

func update_sprite():
	sprite.frame = stage
	area.disabled = stage == 0
		
@warning_ignore("unused_parameter")
func _process(delta):
	if upgrading:
		upgrade_timer += delta
		sprite.modulate = Color(1,1,1,0.5 + 0.5*(upgrade_timer/upgrade_time))
		Manager.collected_objects[unique_id + "_upgrading"] = true
		Manager.collected_objects[unique_id + "_upgrade_timer"] = upgrade_timer
		Manager.collected_objects[unique_id + "_upgrade_target_stage"] = upgrade_target_stage
		Manager.save_game()
		
		if upgrade_timer >= upgrade_time:
			finish_upgrade()
		return

	if not player_inside:
		return

	if Input.is_action_just_pressed("interact"):
		interact()

func interact():
	if upgrading:
		return

	match stage:
		0:
			if Manager.items.get("Stone",0) >= stone_required:
				Manager.remove_item("Stone", stone_required)
				start_upgrade(1)
			else:
				print("Not enough Stone!")
		1:
			if Manager.items.get("Dust Gem",0) >= dustgem_required:
				Manager.remove_item("Dust Gem", dustgem_required)
				start_upgrade(2)
			else:
				print("Not enough Dust Gem!")
		2:
			print("Bridge is already fancy!")

func start_upgrade(target_stage):
	upgrading = true
	upgrade_timer = 0.0
	upgrade_target_stage = target_stage
	sprite.modulate = Color(1,1,1,0.5)  # optional: semi-transparent while upgrading
	print("Upgrade started to stage ", target_stage)

func finish_upgrade():
	stage = upgrade_target_stage
	upgrading = false
	upgrade_timer = 0.0
	sprite.modulate = Color(1,1,1,1)
	Manager.add_xp(exp_stage2 if stage == 1 else exp_stage3)
	Manager.collected_objects[unique_id + "_stage"] = stage
	Manager.collected_objects.erase(unique_id + "_upgrading")
	Manager.collected_objects.erase(unique_id + "_upgrade_timer")
	Manager.collected_objects.erase(unique_id + "_upgrade_target_stage")
	
	Manager.save_game()
	update_sprite()
	print("Upgrade finished! Stage is now ", stage)

# ===== Area signals =====

@warning_ignore("unused_parameter")
func _on_area_2d_body_entered(body: Node2D) -> void:
	player_inside = true

@warning_ignore("unused_parameter")
func _on_area_2d_body_exited(body: Node2D) -> void:
	player_inside = false
