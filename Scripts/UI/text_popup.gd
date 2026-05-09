extends Control

@onready var label := $Label

@export var lifetime := 5
																									  
func setup(text: String, font_size :int = 48, font_color: Color = Color(0.0, 0.0, 0.0, 1.0)):
	label.text = ("\n" + text)
	label.add_theme_color_override("font_color",font_color)
	label.add_theme_font_size_override("font_size",font_size)
	appear()

func appear():
	var tween := create_tween()
	tween.set_parallel()

	tween.tween_property(self, "modulate:a", 1.0, 0.15)

	await get_tree().create_timer(lifetime).timeout

	var fade_tween := create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.25)
	fade_tween.finished.connect(queue_free)
