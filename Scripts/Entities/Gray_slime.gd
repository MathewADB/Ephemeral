extends Entity

@export var patrol_speed := 40.0
@export var chase_speed := 160.0
@export var attack_range := 14.0

@onready var vision_shape : CollisionPolygon2D = $VisionRange/CollisionPolygon2D
@onready var wall_ray: RayCast2D = $WallCast
@onready var ground_ray: RayCast2D = $PlatformCast
@onready var sprite: Sprite2D = $BodySprite

var can_attack = false
var player: CharacterBody2D = null
var attack_timer := 0.0

func _ready():
	direction = Vector2.RIGHT
	_update_rays()

func _physics_process(delta):
	_apply_gravity(delta)
	attack_timer -= delta
	if player and can_attack :
		_try_attack()
	if player:
		_chase()
	else:
		_patrol()

	move_and_slide()
	sprite.flip_h = direction.x > 0

# ---------------- PATROL ----------------

func _patrol():
	if wall_ray.is_colliding() or not ground_ray.is_colliding():
		direction.x *= -1
		_update_rays()

	velocity.x = direction.x * patrol_speed

# ---------------- CHASE ----------------

func _chase():
	var dx = player.global_position.x - global_position.x
	
	direction.x = sign(dx)
	_update_rays()
	
	if abs(dx) <= attack_range:
		velocity.x = 0
		_try_attack()
	else:
		velocity.x = direction.x * chase_speed

func _try_attack():
	if player.can_take_damage:
		player.take_damage(damage)

# ---------------- DETECTION ----------------

func _on_enter(body):
	player = body

func _on_exit(body):
	if body == player:
		player = null

# ---------------- HELPERS ----------------

func _update_rays():
	vision_shape.scale.x = abs(vision_shape.scale.x) * sign(direction.x)
	wall_ray.target_position.x = abs(wall_ray.target_position.x) * sign(direction.x)
	ground_ray.target_position.x = abs(ground_ray.target_position.x) * sign(direction.x)

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

func _on_attack_range_body_entered(body: Node2D) -> void:
	player = body
	if player.is_hidden == false :
		can_attack = true
	else :
		player = null
	
@warning_ignore("unused_parameter")
func _on_attack_range_body_exited(body: Node2D) -> void:
	can_attack = false

func _on_vision_range_body_entered(body: Node2D) -> void:
	player = body
	if player.is_hidden == true :
		player = null

@warning_ignore("unused_parameter")
func _on_vision_range_body_exited(body: Node2D) -> void:
	pass
