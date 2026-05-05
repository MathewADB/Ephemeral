extends Panel

@onready var icon := $Container/Icon
@onready var label := $Container/Amount
@onready var item_name := $Container/Name

@warning_ignore("shadowed_variable_base_class")
func setup(name: String, texture: Texture2D, amount: int, rarity: String):
	item_name.text = name
	icon.texture = texture
	label.text = str(amount)

	var color := InventoryManager.get_rarity_color(rarity)
	self.self_modulate = color
