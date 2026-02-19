extends ColorRect

@export var fade_time: float = 0.5

func fade_in() -> void:
	modulate.a = 0
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)

func fade_out() -> void:
	modulate.a = 1.0
	var tween := get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
