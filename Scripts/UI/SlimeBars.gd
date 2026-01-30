extends Control

@onready var healthbar = $HealthBar

func update_health(health,max_health):
	healthbar.update_bar(health,max_health)
