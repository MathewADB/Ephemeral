extends Entity

@export var patrol_speed := 40
@export var chase_speed := 160
@export var stop_distance := 6.0

@onready var vision_ray: RayCast2D = $ViewRange
@onready var wall_ray: RayCast2D = $WallCast
@onready var ground_ray: RayCast2D = $PlatformCast
@onready var sprite: Sprite2D = $BodySprite
@onready var spair_timer : Timer = $Spair

var enemy_in := false
var enemy : CharacterBody2D

var player_in_sight := false
var player : CharacterBody2D

var spotted := false

func _ready() -> void:
	Manager.night_changed.connect(time_change)
	direction = Vector2.LEFT

	vision_ray.enabled = true
	wall_ray.enabled = true
	ground_ray.enabled = true

	vision_ray.add_exception(self)
	wall_ray.add_exception(self)
	ground_ray.add_exception(self)

	_update_rays()

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	_check_vision()

	if player_in_sight and player:
		_chase_player()
	else:
		_patrol()

	move_and_slide()
	_update_visuals()
	_handle_attack()

func time_change(is_night):
	if is_night:
		patrol_speed = 20
		chase_speed = 200
		damage = 20
	else:
		patrol_speed = 40
		chase_speed = 160
		damage = 10

# -------------------- GRAVITY & VISUALS --------------------
func _apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		
func _update_visuals():
	sprite.flip_h = direction.x > 0

# -------------------- PATROL & CHASE --------------------
func _patrol():
	_update_rays()
	
	if wall_ray.is_colliding() or not ground_ray.is_colliding():
		_turn_around()
	
	velocity.x = direction.x * patrol_speed

func _chase_player():
	var dx := player.global_position.x - global_position.x

	if abs(dx) <= stop_distance:
		velocity.x = 0
		return

	var new_direction = sign(dx)

	if new_direction != 0 and direction.x != new_direction:
		direction.x = new_direction
		_update_rays()
	
	velocity.x = direction.x * chase_speed

func _turn_around():
	direction.x *= -1
	_update_rays()

# -------------------- RAYS --------------------
func _update_rays():
	wall_ray.target_position.x = abs(wall_ray.target_position.x) * sign(direction.x)
	ground_ray.target_position.x = abs(ground_ray.target_position.x) * sign(direction.x)
	vision_ray.target_position.x = abs(vision_ray.target_position.x) * sign(direction.x)
	
	wall_ray.force_raycast_update()
	ground_ray.force_raycast_update()
	vision_ray.force_raycast_update()
	
func _check_vision():
	vision_ray.force_raycast_update()

	if vision_ray.is_colliding():
		var hit = vision_ray.get_collider()

		if hit.name == "Player" and not hit.is_hidden:
			player_in_sight = true
			spotted = true
			player = hit
			
			if not spair_timer.is_stopped():
				spair_timer.stop()
			return
			
	if player_in_sight and spair_timer.is_stopped():
		spair_timer.start()

# -------------------- ATTACK --------------------
func _handle_attack():
	if enemy_in and enemy:
		if enemy.can_take_damage:
			if not enemy.is_hidden or spotted:
				enemy.take_damage(damage)
				spotted = true
				player = enemy
				if !player_in_sight :
					_turn_around()
func _on_hitbox_body_entered(body: Node2D) -> void:
	enemy_in = true
	enemy = body

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body == enemy:
		enemy_in = false
		enemy = null

func _on_spair_timeout() -> void:
	player_in_sight = false
	spotted = false
	player = null
	_update_rays()
