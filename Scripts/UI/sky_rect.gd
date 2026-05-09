extends CanvasModulate


# Called when the node enters the scene tree for the first time.
func _ready():
	TimeManager.register_world_modulate(self)
	TimeManager._background = $"../CanvasLayer/Sky"
