extends Node2D

@onready var moonlight := $"../Moonlight"

@export var day_color := Color(1, 1, 1)
@export var night_color := Color(0.15, 0.15, 0.25)
@export var night_strength := 1.2 
@export var fade_speed := 0.02

func _process(_delta):
	var t := Manager.get_day_progress()
	var factor := day_night_curve(t) * night_strength
	self.color = day_color.lerp(night_color, factor)

	var target_energy := factor
	moonlight.energy = lerp(moonlight.energy, target_energy, fade_speed)
func day_night_curve(t: float) -> float:
	if t < 0.2:
		return 1.0
	elif t < 0.35:
		return lerp(1.0, 0.0, (t - 0.2) / 0.15)
	elif t < 0.65:
		return 0.0
	elif t < 0.8:
		return lerp(0.0, 1.0, (t - 0.65) / 0.15)
	else:
		return 1.0

	
