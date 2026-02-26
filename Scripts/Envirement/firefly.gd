extends Node2D

@export var night_only := true
@export var fade_duration := 60.0

@onready var glow: Light2D = $Glow

var tween : Tween
var max_light_energy := 1.0

func _ready():
	if night_only:
		modulate.a = 0.0
		glow.energy = 0.0
		Manager.night_changed.connect(_on_night_changed)

func _on_night_changed(is_night: bool) -> void:
	if tween:
		tween.kill()

	tween = create_tween()

	if is_night:
		tween.tween_property(self, "modulate:a", 1.0, fade_duration)
		tween.parallel().tween_property(glow, "energy", max_light_energy, fade_duration)
	else:
		tween.tween_property(self, "modulate:a", 0.0, fade_duration)
		tween.parallel().tween_property(glow, "energy", 0.0, fade_duration)
