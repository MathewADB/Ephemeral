extends Node

# =============================================================================
# INVENTORY MANAGER — Item storage, crafting, item metadata
# Autoload name: InventoryManager
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# SIGNALS
# ─────────────────────────────────────────────────────────────────────────────

signal inventory_changed
## Emitted when a specific item's count changes. Useful for item-specific UI.
signal item_changed(item_name: String, new_amount: int)
## Emitted when crafting succeeds.
signal item_crafted(recipe_name: String)

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS — RARITY
# ─────────────────────────────────────────────────────────────────────────────

const RARITY_COLORS: Dictionary = {
	"common":    Color("#52636d"),
	"uncommon":  Color("#22783f"),
	"rare":      Color("#345f99"),
	"epic":      Color("#7d2f7e"),
	"legendary": Color("#e5a732"),
	"mythic":    Color("#b41e40"),
	"platinum":  Color("#a6c4bf"),
}

const RARITY_ORDER: Dictionary = {
	"common": 0, "uncommon": 1, "rare": 2,
	"epic": 3,   "legendary": 4, "mythic": 5, "platinum": 6,
}

# ─────────────────────────────────────────────────────────────────────────────
# ITEM REGISTRY
# ─────────────────────────────────────────────────────────────────────────────

## All known items with their icons and rarities.
## Items NOT in this dict can still be added to `items` at runtime.
const ITEM_DATA: Dictionary = {
	"Ruby Stone":    { "icon": preload("res://Sprites/Entities/Ruby Stone.png"),    "rarity": "uncommon" },
	"Ruby Gem":      { "icon": preload("res://Sprites/Entities/Ruby Gem.png"),      "rarity": "rare"     },
	"Dust":          { "icon": preload("res://Sprites/Entities/Dust.png"),           "rarity": "common"   },
	"Dust Gem":      { "icon": preload("res://Sprites/Entities/Dust Gem.png"),      "rarity": "uncommon" },
	"Stone":         { "icon": preload("res://Sprites/Entities/Stone.png"),         "rarity": "common"   },
	"Lore Fragment": { "icon": preload("res://Sprites/Entities/Lore Fragment.png"), "rarity": "epic"     },
}

const DEFAULT_ITEMS: Dictionary = {
	"Ruby Stone": 0, "Ruby Gem": 0, "Dust": 0,
	"Dust Gem": 0,   "Stone": 0,    "Lore Fragment": 0,
}

# ─────────────────────────────────────────────────────────────────────────────
# CRAFTING RECIPES
# ─────────────────────────────────────────────────────────────────────────────

## Schema:
##   name        String    — display name
##   description String    — flavour text
##   icon        Texture2D — recipe icon
##   materials   {item:int} — ingredients consumed
##   result      String    — item name produced  (defaults to recipe key)
##   amount      int       — how many are produced  (default 1)
##   time        float     — crafting duration in seconds
var crafting_recipes: Dictionary = {
	"Ruby Gem": {
		"name":        "Ruby Gem",
		"description": "A refined gem crafted from raw stones.",
		"icon":        preload("res://Sprites/Entities/Ruby Gem.png"),
		"materials":   { "Ruby Stone": 2 },
		"amount":      1,
		"time":        5.0,
	},
	"Dust Gem": {
		"name":        "Dust Gem",
		"description": "A refined gem which can activate some broken objects.",
		"icon":        preload("res://Sprites/Entities/Dust Gem.png"),
		"materials":   { "Dust": 10 },
		"amount":      1,
		"time":        10.0,
	},
}

# ─────────────────────────────────────────────────────────────────────────────
# RUNTIME STATE
# ─────────────────────────────────────────────────────────────────────────────

var items: Dictionary = DEFAULT_ITEMS.duplicate(true)

# ─────────────────────────────────────────────────────────────────────────────
# CORE — ADD / REMOVE / QUERY
# ─────────────────────────────────────────────────────────────────────────────

func add_item(item_name: String, amount := 1) -> void:
	if amount <= 0:
		return
	items[item_name] = items.get(item_name, 0) + amount
	inventory_changed.emit()
	item_changed.emit(item_name, items[item_name])

	if item_name == "Lore Fragment":
		Manager.check_lore_progress()


func remove_item(item_name: String, amount := 1) -> void:
	if amount <= 0 or not items.has(item_name):
		return

	items[item_name] = maxi(0, items[item_name] - amount)

	if items[item_name] == 0:
		items.erase(item_name)

	inventory_changed.emit()
	item_changed.emit(item_name, items.get(item_name, 0))


func has_item(item_name: String, amount := 1) -> bool:
	return items.get(item_name, 0) >= amount


func get_amount(item_name: String) -> int:
	return items.get(item_name, 0)


func clear() -> void:
	items.clear()
	inventory_changed.emit()


## Returns all items sorted by rarity (rarest first), then alphabetically.
func get_sorted_items() -> Array:
	var keys := items.keys()

	keys.sort_custom(func(a, b) -> bool:
		var ra: int = RARITY_ORDER.get(get_item_rarity(a), 0)
		var rb: int = RARITY_ORDER.get(get_item_rarity(b), 0)

		if ra != rb:
			return ra > rb

		return a < b
	)

	return keys

# ─────────────────────────────────────────────────────────────────────────────
# CRAFTING
# ─────────────────────────────────────────────────────────────────────────────

func can_craft(recipe_name: String) -> bool:
	var recipe: Dictionary = crafting_recipes.get(recipe_name, {})
	if recipe.is_empty():
		return false
	for mat in recipe["materials"]:
		if not has_item(mat, recipe["materials"][mat]):
			return false
	return true


## Consumes materials and adds the result. Returns true on success.
func craft(recipe_name: String) -> bool:
	if not can_craft(recipe_name):
		return false

	var recipe : Dictionary = crafting_recipes[recipe_name]
	for mat in recipe["materials"]:
		remove_item(mat, recipe["materials"][mat])

	var result := recipe.get("result", recipe_name) as String
	var amount := recipe.get("amount", 1)     as int
	add_item(result, amount)

	item_crafted.emit(recipe_name)
	return true

# ─────────────────────────────────────────────────────────────────────────────
# ITEM METADATA HELPERS
# ─────────────────────────────────────────────────────────────────────────────

func get_item_data(item_name: String) -> Dictionary:
	return ITEM_DATA.get(item_name, { "icon": null, "rarity": "common" })


func get_item_rarity(item_name: String) -> String:
	return get_item_data(item_name).get("rarity", "common")


func get_item_icon(item_name: String) -> Texture2D:
	return get_item_data(item_name).get("icon", null)


func get_rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)

# ─────────────────────────────────────────────────────────────────────────────
# SAVE / LOAD / RESET
# ─────────────────────────────────────────────────────────────────────────────

func get_save_data() -> Dictionary:
	return items.duplicate(true)


func load_data(data: Dictionary) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	items = data.duplicate(true)
	inventory_changed.emit()


func reset() -> void:
	items = DEFAULT_ITEMS.duplicate(true)
	inventory_changed.emit()
