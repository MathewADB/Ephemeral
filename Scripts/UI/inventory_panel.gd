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
		var amount: int = InventoryManager.items[item_name]
		if amount <= 0:
			continue

		var row = row_scene.instantiate()
		list.add_child(row)

		var icon = InventoryManager.get_item_icon(item_name)
		var rarity = InventoryManager.get_item_rarity(item_name)

		row.setup(item_name, icon, amount, rarity)

	visible = InventoryManager.items.size() > 0
