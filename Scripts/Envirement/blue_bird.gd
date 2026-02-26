extends Node2D

@export var flee_speed := 200.0
@export var upward_bias := 0.3

var fleeing := false
var direction := Vector2.ZERO

@onready var sprite := $Sprite2D
@onready var anim := $AnimationPlayer

func _ready():
	anim.play("idle")
	if randi() % 2 == 0:
		sprite.flip_h = true

func _on_area_2d_body_entered(body):
	if body.name != "Player":
		return
	if fleeing:
		return
		
	fleeing = true
	anim.play("fly")
	
	direction = (position - body.position).normalized()
	direction.y -= upward_bias
	direction = direction.normalized()

func _process(delta):
	if fleeing:
		position += direction * flee_speed * delta
		
		if direction.x != 0:
			sprite.flip_h = direction.x > 0

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if fleeing:
		queue_free()
