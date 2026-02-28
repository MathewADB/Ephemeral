extends AnimatableBody2D

@onready var break_timer = $BreakTimer
@onready var respawn_timer = $RespawnTimer
@onready var collision = $CollisionShape2D
@onready var sprite = $Sprite2D

var start_position : Vector2
var triggered := false

func _ready():
	start_position = global_position

@warning_ignore("unused_parameter")
func _on_area_2d_body_entered(body: Node2D) -> void:
	if triggered:
		return

	triggered = true
	break_timer.start()

func _on_break_timer_timeout() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2) # fade to invisible
	
	await tween.finished
	
	collision.disabled = true
	respawn_timer.start()

func _on_respawn_timer_timeout() -> void:
	global_position = start_position
	
	var tween = create_tween()
	sprite.modulate.a = 0.0
	collision.disabled = false
	
	tween.tween_property(sprite, "modulate:a", 1.0, 0.4)
	
	await tween.finished
	
	triggered = false
