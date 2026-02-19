extends Control

@onready var label := $Label

@export var lifetime := 5

func setup(text: String):
	label.text = text
	appear()

func appear():
	var tween := create_tween()
	tween.set_parallel()

	tween.tween_property(self, "modulate:a", 1.0, 0.15)

	await get_tree().create_timer(lifetime).timeout

	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	fade_tween.finished.connect(queue_free)
