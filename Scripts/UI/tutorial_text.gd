extends Control

@export var hint_text: String = "Press Jump"

@export var fade_time := 0.25

@onready var label: RichTextLabel = $Text

var tween: Tween

func _ready() -> void:
	label.text = hint_text
	label.modulate.a = 0.0

func fade_in():
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, fade_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)


func fade_out():
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, fade_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
		
@warning_ignore("unused_parameter")
func _on_detector_body_entered(body: Node2D) -> void:
	fade_in()

@warning_ignore("unused_parameter")
func _on_detector_body_exited(body: Node2D) -> void:
	fade_out()
