extends AnimatableBody2D

@onready var break_timer = $BreakTimer
@onready var respawn_timer = $RespawnTimer
@onready var collision = $CollisionShape2D
@onready var sprite = $Sprite2D

@export var night_only := true

var start_position : Vector2
var triggered := false
var tween : Tween

func _ready():
	start_position = global_position
	
	if night_only:
		if Manager.is_night():
			_enable_platform(true)
		else:
			_enable_platform(false)
		Manager.night_changed.connect(_on_night_changed)
		
@warning_ignore("unused_parameter")
func _on_area_2d_body_entered(body: Node2D) -> void:
	if triggered or (night_only and not Manager.is_night()):
		return

	triggered = true
	break_timer.start()

func _on_break_timer_timeout() -> void:
	if night_only and not Manager.is_night():
		return
	
	tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	collision.disabled = true
	respawn_timer.start()

func _on_respawn_timer_timeout() -> void:
	if night_only and not Manager.is_night():
		_enable_platform(false)
		triggered = false
		return
	
	global_position = start_position
	
	sprite.modulate.a = 0.0
	collision.disabled = false
	
	tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.4)
	await tween.finished
	
	triggered = false

func _on_night_changed(is_night: bool) -> void:
	if is_night:
		_enable_platform(true)
	else:
		_enable_platform(false)

func _enable_platform(active: bool) -> void:
	if active:
		tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.4)
		await tween.finished
		collision.disabled = false
		triggered = false
	else:
		sprite.modulate.a = 0.0
		collision.disabled = true
		break_timer.stop()
		respawn_timer.stop()
