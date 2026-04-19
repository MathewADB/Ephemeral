extends Entity

@onready var self_light = $SelfLight
@onready var sprite = $BodySprite
@onready var animation = $AnimationPlayer
@onready var invun = $"Invun Timer"
@onready var tutorial_timer =$"Tutorial Timer"

@export var camera : Camera2D
@export var level_limit_r := 100000
@export var level_limit_l := 100000
@export var fall_multiplier := 1.3
@export var low_jump_cut := 0.6
@export var coyote_time := 0.1
@export var jump_buffer_time := 0.1
@export var tilemap: TileMapLayer
@export var tutorial : bool
@export var fall_damage_threshold := 700.0
@export var fall_damage_divisor := 5.0

var max_fall_speed_reached := 0.0
var was_on_floor := false
var currently_on_floor := false

var mining := false
var mineable
var save_location : Vector2
var jump_buffer := 0.0
var coyote := 0.0
var jump_released := false
var base_extra_jumps := 0
var current_extra_jumps := 0
var hide_unlocked := false
var can_hide := false
var hiding := false
var is_hidden := false
var can_take_damage := true
var last_speed_multiplier := 1.0
var light_level := 0
var speed_level := 1.0
var mining_tier := 0
var mining_speed := 1
var lock_animation := false
var ignore_fall_damage = false
var default_camera_offset_y := -18.0
var look_down_offset := 36.0
var camera_lerp_speed := 8.0 

func _ready() -> void:
	camera.offset.y = default_camera_offset_y
	gravity = 850
	current_health = Manager.loaded_health
	set_stats()
	Manager.player = self
	camera.limit_right = level_limit_r
	camera.limit_left = -level_limit_l		
	if tutorial == true :
		ignore_fall_damage = true
		save_location = self.position
		
	if Manager.activate_spawn :
		global_position = Manager.spawn_location
		Manager.activate_spawn = false
		

	tutorial_timer.start()
	await get_tree().create_timer(0.2).timeout
	ignore_fall_damage = false
	
func set_stats():
	mining_speed = Manager.mining_speed_level
	mining_tier = Manager.mining_tier
	speed_level = Manager.player_mobility
	light_level = Manager.light_level
	hide_unlocked = Manager.hide_unlocked
	base_extra_jumps = Manager.base_extra_jumps
	current_extra_jumps = base_extra_jumps
	UI.bars.update_health(current_health,max_health)
	
func _physics_process(delta):
	handle_mining(delta)
	if !hiding and !mining:
		handle_timers(delta)
		handle_horizontal(delta)
		handle_vertical(delta)
		move_and_slide()
		
		if not is_on_floor() and velocity.y > 0:
			max_fall_speed_reached = max(max_fall_speed_reached, velocity.y)
			
	currently_on_floor = is_on_floor()
	if currently_on_floor and not was_on_floor:
		_check_fall_damage()

	was_on_floor = currently_on_floor
	handle_camera_look(delta)
	
	if light_level != 0 :
		handle_light()
	if hide_unlocked :
		handle_hiding()
	
	if is_on_floor():
		current_extra_jumps = base_extra_jumps
		jump_released = false
		
	update_animation()
	
func _check_fall_damage():
	
	if ignore_fall_damage:
		max_fall_speed_reached = 0.0
		return
		
	if max_fall_speed_reached > fall_damage_threshold:
		var excess = max_fall_speed_reached - fall_damage_threshold
		var fdamage = int(excess / fall_damage_divisor)

		if fdamage > 0 and can_take_damage:
			take_damage(fdamage)

	max_fall_speed_reached = 0.0
	
func handle_mining(delta):

	if mineable == null or mining_tier < mineable.tier:
		stop_mining()
		return

	if mineable is InfiniteCollectable and mineable.count <= 0:
		stop_mining()
		return

	if Input.is_action_pressed("interact") and is_on_floor():

		mining = true
		velocity = Vector2.ZERO

		mineable.progress += delta * mining_speed

		UI.set_progress(mineable.progress / mineable.mine_time)

		if mineable.progress >= mineable.mine_time:

			mineable.progress = 0
			if mineable is InfiniteCollectable:
				mineable.mine(1)
			else:
				mineable.count -= 1
			
			if mineable.xp > 0 :
				Manager.add_xp(mineable.xp)

			Manager.add_item(mineable.collectable_name, 1)
			UI.show_item_popup(mineable, 1)

			if mineable is InfiniteCollectable:
				if mineable.count <= 0:
					stop_mining()
			else:
				if mineable.count <= 0:
					Manager.collected_objects[mineable.unique_id] = true
					mineable.queue_free()
					stop_mining()


	else:
		stop_mining()
			
func stop_mining():
	mining = false

	if mineable:
		mineable.progress = 0

	UI.hide_progress()
	
func freeze_camera(value:bool):
	if value == true :
		camera.position_smoothing_speed = 0.0
	else :
		camera.position_smoothing_speed = 5.0
		
		
func get_speed_multiplier() -> float:
	if not tilemap:
		return 1.0

	if is_on_floor():
		var cell = tilemap.local_to_map(tilemap.to_local(global_position))
		cell.y += 1
		var data = tilemap.get_cell_tile_data(cell)
		if data and data.has_custom_data("speed_multiplier"):
			last_speed_multiplier = float(data.get_custom_data("speed_multiplier"))
		else:
			last_speed_multiplier = 1.0
		return last_speed_multiplier
	else:
		return last_speed_multiplier
	
func handle_horizontal(delta):
	
	direction.x = Input.get_axis("left", "right")
	
	if velocity.x != 0:
		sprite.flip_h = velocity.x > 0
		if sprite.flip_h == true :
			last_direction = Vector2.LEFT
		else :
			last_direction = Vector2.RIGHT
			
	var target_speed = direction.x * max_speed * get_speed_multiplier() * speed_level
	velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)

#var xpadded = 0
func handle_timers(delta):
	if Input.is_action_just_pressed("jump"):
		#xpadded += 100
		#Manager.add_xp(100)
		#print(str(xpadded))
		#print(Manager.level)
		jump_buffer = jump_buffer_time
	else:
		jump_buffer = max(0, jump_buffer - delta)

	if is_on_floor():
		coyote = coyote_time
		jump_released = false
	else:
		coyote = max(0, coyote - delta)

	if Input.is_action_just_released("jump"):
		jump_released = true

func handle_vertical(delta):
	if jump_buffer > 0:
		var used_jump = false

		if coyote > 0:
			velocity.y = jump_force
			coyote = 0
			used_jump = true

		elif not is_on_floor() and current_extra_jumps > 0 :
			velocity.y = jump_force
			current_extra_jumps -= 1
			used_jump = true
			
		if used_jump:
			jump_buffer = 0
			jump_released = false
			return

	if velocity.y < 0 and !jump_released: 
		velocity.y += gravity * delta
		
	else: 
		velocity.y += gravity * fall_multiplier * delta

func handle_light() :
	if Input.is_action_just_pressed("light"):
		if light_level == 2 :
			self_light.energy = 0.7
		if light_level == 3 :
			self_light.energy = 1
		self_light.visible = !self_light.visible
		
func handle_hiding():
	if lock_animation:
		return
		
	if Input.is_action_pressed("hide") and !hiding and !is_hidden and is_on_floor():
		hiding = true
		lock_animation = true
		animation.play("hide")
		await animation.animation_finished
		is_hidden = true
		lock_animation = false
		
	elif Input.is_action_just_released("hide") and hiding :
		hiding = false
		lock_animation = true
		animation.play("show") 
		await animation.animation_finished
		is_hidden = false
		lock_animation = false
	
func handle_camera_look(delta):
	var target_offset = default_camera_offset_y
	
	if Input.is_action_pressed("look_down"):
		target_offset += look_down_offset
	
	camera.offset.y = lerp(camera.offset.y, target_offset, camera_lerp_speed * delta)
	
func take_damage(amount):
	current_health = max(current_health - amount,0)
	if current_health == 0 :
		die()
	if current_health > max_health :
		current_health = max_health
	UI.bars.update_health(current_health,max_health)
	can_take_damage = false
	invun.start()
	
func _on_invun_timer_timeout() -> void:
	can_take_damage = true

func _on_save_location_timeout() -> void:
	if self.is_on_floor() :
		save_location = position
	tutorial_timer.start()

func die():
	take_damage(-100)
	Manager.loaded_health = max_health
	if tutorial:
		self.global_position = save_location
		current_health = max_health
		return

	if Manager.current_room_scene != Manager.spawn_room_scene:
		Manager.activate_spawn = true
		call_deferred("_deferred_respawn")
		return

	self.global_position = Manager.spawn_location
	current_health = max_health
	
func _deferred_respawn():
	get_tree().change_scene_to_file(Manager.spawn_room_scene)
	
# ===== animation

func update_animation():
	if lock_animation:
		return	
	
	if hiding:
		return
		
	if mining:
		animation.play("mine")
		return
	
	if not is_on_floor():
		if velocity.y < 0:
			animation.play("jump")
		else:
			animation.play("fall")
	else:
		if abs(velocity.x) > 5:
			animation.play("walk")
			pass
		else:
			animation.play("idle")
