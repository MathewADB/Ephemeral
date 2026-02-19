extends HBoxContainer

@onready var icon := $Icon
@onready var label := $Amount

func setup(texture : Texture2D, amount : int):
	icon.texture = texture
	label.text = str(amount)
