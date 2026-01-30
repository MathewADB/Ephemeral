extends CanvasLayer

@onready var miningbar = $Mining/Miningbar
@onready var time_icon = $TimeIconSmall
@onready var bars = $"Bars HUD"

func _ready() -> void:
	set_time(Manager.is_night())
	Manager.night_changed.connect(set_time)

func set_time(is_night:bool):
	if is_night :
		time_icon.frame = 0 
	else :
		time_icon.frame = 1

func set_progress(value):
	miningbar.visible = true
	miningbar.value = value * 100

func hide_progress():
	miningbar.visible = false
