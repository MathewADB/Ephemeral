extends Control

@export var lifetime := 3.0

@warning_ignore("shadowed_variable_base_class")
@onready var icon := $Panel/Icon
@onready var title := $Panel/Name
@onready var description := $Panel/Details

@warning_ignore("shadowed_variable_base_class")
func setup(name: String, desc: String, texture: Texture2D):
	title.text = "Achievement Unlocked"
	description.text = name + " : " + desc
	icon.texture = texture
	appear()

func appear():
	modulate.a = 0.0

	# start slightly above
	position.y -= 40

	var tween := create_tween()

	# slide DOWN into place
	tween.tween_property(self, "position:y", position.y + 40, 0.35)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# fade in
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.25)

	await get_tree().create_timer(lifetime).timeout

	# fade out + slight upward exit
	var fade := create_tween()
	fade.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	fade.parallel().tween_property(self, "position:y", position.y - 20, 0.25)

	fade.finished.connect(queue_free)
