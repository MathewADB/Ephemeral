extends Control

@onready var list := $ItemList
var row_scene := preload("res://Scenes/Control/inventory_item_row.tscn")

func _ready():
	InventoryManager.inventory_changed.connect(update_inventory)
	update_inventory()

func update_inventory():
	for child in list.get_children():
		child.queue_free()

	for item_name in InventoryManager.items.keys():
		var amount : int = InventoryManager.items[item_name]
		if amount <= 0:
			continue

		var row = row_scene.instantiate()
		list.add_child(row)

		var icon := get_icon_for_item(item_name)
		row.setup(icon, amount)

	visible = InventoryManager.items.size() > 0

func get_icon_for_item(item_name : String) -> Texture2D:
	match item_name:
		"Ruby Stone":
			return preload("res://Sprites/Entities/Ruby Stone.png")
		"Ruby Gem":
			return preload("res://Sprites/Entities/Ruby Gem.png")
		"Lore Fragment":
			return preload("res://Sprites/Entities/Lore Fragment.png")
		"Dust":
			return preload("res://Sprites/Entities/Dust.png")
		"Dust Gem":
			return preload("res://Sprites/Entities/Dust Gem.png")
		"Stone":
			return preload("res://Sprites/Entities/Stone.png")
		_:
			return null
