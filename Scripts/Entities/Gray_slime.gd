extends Entity

@export var patrol_speed := 40.0
@export var chase_speed := 160.0
@export var attack_range := 14.0
@export var detection_memory_time := 3.0  # How long slime remembers player after losing sight
@export var alert_distance := 200.0       # Maximum distance before slime gives up chase

@onready var vision_shape: CollisionPolygon2D = $VisionRange/CollisionPolygon2D
@onready var wall_ray: RayCast2D = $WallCast
@onready var ground_ray: RayCast2D = $PlatformCast
@onready var sprite: Sprite2D = $BodySprite

enum State { PATROL, ALERT, CHASE, ATTACK, RETURN }

var state: State = State.PATROL
var player: CharacterBody2D = null
var player_in_vision := false
var player_in_attack_range := false

var attack_cooldown := 0.0
var attack_cooldown_max := 1.2    # Time between attacks
var memory_timer := 0.0           # Counts down after losing sight
var last_known_pos := Vector2.ZERO
var home_pos := Vector2.ZERO      # Where slime started, to return to after losing player

func _ready():
	direction = Vector2.RIGHT
	home_pos = global_position
	_update_rays()

func _physics_process(delta):
	_apply_gravity(delta)
	attack_cooldown -= delta

	match state:
		State.PATROL:
			_patrol()
		State.ALERT:
			_alert(delta)
		State.CHASE:
			_chase(delta)
		State.ATTACK:
			_attack_state()
		State.RETURN:
			_return_home()

	move_and_slide()
	sprite.flip_h = velocity.x > 0

# ----------- STATES -----------

func _patrol():
	if wall_ray.is_colliding() or not ground_ray.is_colliding():
		direction.x *= -1
		_update_rays()
	velocity.x = direction.x * patrol_speed

func _alert(delta):
	# Slime noticed something — pause briefly then start chasing
	velocity.x = move_toward(velocity.x, 0, 300 * delta)
	memory_timer -= delta
	if memory_timer <= 0:
		if player_in_vision and player and not player.is_hidden:
			state = State.CHASE
		else:
			state = State.PATROL

@warning_ignore("unused_parameter")
func _chase(delta):
	if not player or player.is_hidden:
		memory_timer = detection_memory_time
		state = State.ALERT
		return

	last_known_pos = player.global_position

	if global_position.distance_to(last_known_pos) > alert_distance:
		state = State.RETURN
		return

	var dx = last_known_pos.x - global_position.x
	direction.x = sign(dx)
	_update_rays()

	if player_in_attack_range:
		state = State.ATTACK
	elif wall_ray.is_colliding() or not ground_ray.is_colliding():
		state = State.RETURN
	else:
		velocity.x = direction.x * chase_speed

func _attack_state():
	velocity.x = 0
	if not player_in_attack_range:
		state = State.CHASE
		return
	if player and not player.is_hidden and attack_cooldown <= 0:
		if player.can_take_damage:
			player.take_damage(damage)
		attack_cooldown = attack_cooldown_max

func _return_home():
	var dx = home_pos.x - global_position.x
	if abs(dx) < 5:
		velocity.x = 0
		state = State.PATROL
		direction = Vector2.RIGHT
		_update_rays()
	else:
		direction.x = sign(dx)
		_update_rays()
		velocity.x = direction.x * patrol_speed

# ----------- DETECTION -----------

func _on_vision_range_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return
	if body.is_hidden:
		return
	player = body
	player_in_vision = true
	# Enter ALERT
	last_known_pos = player.global_position
	memory_timer = 0.3
	state = State.ALERT

func _on_vision_range_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_vision = false

func _on_attack_range_body_entered(body: Node2D) -> void:
	if not body.has_method("take_damage"):
		return
	if body.is_hidden:
		return
	player = body
	player_in_attack_range = true
	if state == State.CHASE or state == State.ALERT:
		state = State.ATTACK

func _on_attack_range_body_exited(body: Node2D) -> void:
	if body == player:
		player_in_attack_range = false

# ----------- HELPERS -----------

func _update_rays():
	vision_shape.scale.x = abs(vision_shape.scale.x) * sign(direction.x)
	wall_ray.target_position.x = abs(wall_ray.target_position.x) * sign(direction.x)
	ground_ray.target_position.x = abs(ground_ray.target_position.x) * sign(direction.x)

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
