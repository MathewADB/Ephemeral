extends Node

signal inventory_changed

# --- DATA ---

const RARITY_COLORS := {
	"common": Color("#52636d"),
	"uncommon": Color("#22783f"),
	"rare": Color("#345f99"),
	"epic": Color("#7d2f7e"),
	"legendary": Color("#e5a732"),
	"mythic": Color("#b41e40"),
	"platinum": Color("#a6c4bf")
}

const DEFAULT_ITEMS = {
	"Ruby Stone": 0,
	"Ruby Gem": 0,
	"Dust": 0,
	"Dust Gem": 0,
	"Stone": 0,
	"Lore Fragment": 0
}

var items: Dictionary = {
	"Ruby Stone": 0,
	"Ruby Gem": 0,
	"Dust": 0,
	"Dust Gem": 0,
	"Stone": 0,
	"Lore Fragment": 0
}

var crafting_recipes := {
	"Ruby Gem": {
		"name": "Ruby Gem",
		"description": "A refined gem crafted from raw stones",
		"icon": preload("res://Sprites/Entities/Ruby Gem.png"),
		"materials": {"Ruby Stone": 2},
		"time": 5.0
	},
	"Dust Gem": {
		"name": "Dust Gem",
		"description": "A refined gem which can be used to activate some broken objects",
		"icon": preload("res://Sprites/Entities/Dust Gem.png"),
		"materials": {"Dust": 10},
		"time": 10.0
	}
}

const ITEM_DATA := {
	"Ruby Stone": {
		"icon": preload("res://Sprites/Entities/Ruby Stone.png"),
		"rarity": "uncommon"
	},
	"Ruby Gem": {
		"icon": preload("res://Sprites/Entities/Ruby Gem.png"),
		"rarity": "rare"
	},
	"Dust": {
		"icon": preload("res://Sprites/Entities/Dust.png"),
		"rarity": "common"
	},
	"Dust Gem": {
		"icon": preload("res://Sprites/Entities/Dust Gem.png"),
		"rarity": "uncommon"
	},
	"Stone": {
		"icon": preload("res://Sprites/Entities/Stone.png"),
		"rarity": "common"
	},
	"Lore Fragment": {
		"icon": preload("res://Sprites/Entities/Lore Fragment.png"),
		"rarity": "epic"
	}
}

# --- CORE FUNCTIONS ---
	
func add_item(item_name: String, amount := 1):
	if not items.has(item_name):
		items[item_name] = 0
	
	items[item_name] += amount
	inventory_changed.emit()

	if item_name == "Lore Fragment":
		Manager.check_lore_progress()


func remove_item(item_name: String, amount := 1):
	if not items.has(item_name):
		return

	items[item_name] -= amount

	if items[item_name] <= 0:
		items.erase(item_name)

	inventory_changed.emit()


func has_item(item_name: String, amount := 1) -> bool:
	return items.get(item_name, 0) >= amount


func get_amount(item_name: String) -> int:
	return items.get(item_name, 0)


func clear():
	items.clear()
	inventory_changed.emit()


# --- CRAFTING ---

func can_craft(recipe_name: String) -> bool:
	var recipe = crafting_recipes.get(recipe_name, null)
	if recipe == null:
		return false

	for mat in recipe.materials:
		if not has_item(mat, recipe.materials[mat]):
			return false

	return true


func craft(recipe_name: String) -> bool:
	if not can_craft(recipe_name):
		return false

	var recipe = crafting_recipes[recipe_name]

	# remove materials
	for mat in recipe.materials:
		remove_item(mat, recipe.materials[mat])

	# add result
	add_item(recipe_name, 1)

	return true


# --- SAVE / LOAD SUPPORT ---

func get_save_data() -> Dictionary:
	return items.duplicate(true)


func load_data(data: Dictionary):
	if typeof(data) != TYPE_DICTIONARY:
		return
	
	items = data.duplicate(true)
	inventory_changed.emit()

func reset():
	items = DEFAULT_ITEMS.duplicate(true)
	inventory_changed.emit()
	
# Helper

func get_item_data(item_name: String) -> Dictionary:
	return ITEM_DATA.get(item_name, {
		"icon": null,
		"rarity": "common"
	})

func get_item_rarity(item_name: String) -> String:
	return get_item_data(item_name).get("rarity", "common")

func get_item_icon(item_name: String) -> Texture2D:
	return get_item_data(item_name).get("icon", null)

func get_rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)
	
