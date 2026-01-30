extends Area2D

@onready var checktime := $Timer
@export var damage := 20
var enemy : CharacterBody2D

func _on_body_entered(body: Node2D) -> void:
	enemy = body
	enemy.take_damage(damage)
	checktime.start()
	
@warning_ignore("unused_parameter")
func _on_body_exited(body: Node2D) -> void:
	enemy = null

func _on_timer_timeout() -> void:
	if enemy  :
		enemy.take_damage(damage)
		checktime.start()
