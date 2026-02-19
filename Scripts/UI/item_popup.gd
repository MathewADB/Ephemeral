extends Control

@onready var icon := $Container/ItemIcon
@onready var label := $Container/ItemText

var float_distance := 24
var lifetime := 1.2

func setup(collectable : Collectable, amount := 1):
	icon.texture = collectable.texture
	label.text = "+%d" % [amount]

	appear()

func appear():
	var start_pos := position
	var end_pos := start_pos + Vector2(0, -float_distance)

	var tween := create_tween()
	tween.set_parallel()

	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	tween.tween_property(self, "position", end_pos, lifetime)

	tween.chain()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)

	tween.finished.connect(queue_free)
