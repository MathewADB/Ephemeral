extends CanvasLayer

# =============================================================================
# UI MANAGER — All in-game HUD, overlays, popups, and crafting UI
# Autoload name: UI
# Scene structure required — see SCENE STRUCTURE note at the bottom of file.
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────────────────────

# ── HUD ─────────────────────────────────────────────────────────────────────
@onready var _bars_hud:      Control            = $"BarsHUD"
@onready var _level_bar:     TextureProgressBar = $Level/LevelBar
@onready var _level_label:   Label              = $"Level/LevelLabel"
@onready var _autosave_icon: Sprite2D           = $"AutosaveIcon"
@onready var _mining_bar:    ProgressBar        = $Mining/Miningbar
@onready var _popup_root:    Control            = $"Popup"

# ── Day / Night (three nodes expected by TimeManager) ───────────────────────
@onready var _sun_moon:    Sprite2D  = $DayNight/SunMoon
@onready var _clock_label: Label     = $"DayNight/ClockLabel"

# ── Fade overlay ─────────────────────────────────────────────────────────────
@onready var _fade:        ColorRect = $"Fade"
@onready var _damage_fade: ColorRect = $DamageFade

# ── Panels ───────────────────────────────────────────────────────────────────
@onready var _dead_panel:      Control = $"DeadPanel"
@onready var _player_panel:    Control = $"PlayerPanel"
@onready var _crafting_panel:  Control = $"CraftingPanel"
@onready var _crafting_list:   VBoxContainer  = $"CraftingPanel/ItemList"
@onready var _craft_button:    Button         = $"CraftingPanel/CraftButton"
@onready var _craft_progress:  ProgressBar    = $"CraftingPanel/ProgressBar"
@onready var _icon_rect:       TextureRect    = $"CraftingPanel/Icon"
@onready var _name_label:      Label          = $"CraftingPanel/Name"
@onready var _desc_label:      Label          = $"CraftingPanel/Description"
@onready var _cost_label:      Label          = $"CraftingPanel/Cost"

# ─────────────────────────────────────────────────────────────────────────────
# PRELOADED SCENES
# ─────────────────────────────────────────────────────────────────────────────

const ITEM_POPUP_SCENE        := preload("res://Scenes/Control/item_popup.tscn")
const XP_POPUP_SCENE          := preload("res://Scenes/Control/experience_popup.tscn")
const TEXT_POPUP_SCENE        := preload("res://Scenes/Control/text_popup.tscn")
const ACHIEVEMENT_POPUP_SCENE := preload("res://Scenes/Control/achievement_popup.tscn")

# ─────────────────────────────────────────────────────────────────────────────
# CONFIG
# ─────────────────────────────────────────────────────────────────────────────

## Vertical offset (in pixels) of item collect popups from screen centre.
@export var popup_offset := Vector2(0, 80)

# ─────────────────────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────────────────────

var _selected_recipe: String = ""
var _crafting: bool = false
var _autosave_tween: Tween = null
var _fade_tween:     Tween = null

# ─────────────────────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Hand day/night nodes to TimeManager
	TimeManager.setup(_sun_moon, _clock_label)

	# Initial state
	_dead_panel.visible     = false
	_crafting_panel.visible = false
	_player_panel.visible   = true
	_fade.visible           = false
	_mining_bar.visible     = false

	# Connect game signals
	Manager.night_changed.connect(_on_night_changed)
	Manager.xp_changed.connect(_on_xp_changed)
	Manager.level_changed.connect(_on_level_changed)
	Manager.xp_gained.connect(show_xp_popup)
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	InventoryManager.inventory_changed.connect(_on_inventory_changed)

	# Sync initial HUD values
	_on_xp_changed(Manager.current_xp, Manager.get_required_xp(Manager.level))
	_on_level_changed(Manager.level)
	_on_night_changed(Manager.is_night())

	# Build crafting recipe list
	_build_crafting_list()

# ─────────────────────────────────────────────────────────────────────────────
# SIGNAL HANDLERS
# ─────────────────────────────────────────────────────────────────────────────

@warning_ignore("unused_parameter")
func _on_night_changed(night: bool) -> void:
	# The SunMoon sprite is updated by TimeManager every frame via _update_ui.
	# This handler is kept for any additional night-transition effects.
	pass


func _on_xp_changed(current: float, required: float) -> void:
	# Handle level-up bar wrap: if the new value is less than what's displayed
	# animate a fill → reset → refill to communicate the rollover clearly.
	if current < _level_bar.value and _level_bar.value > 0.0:
		var t := create_tween()
		t.tween_property(_level_bar, "value", _level_bar.max_value, 0.3)
		t.tween_callback(func():
			_level_bar.max_value = required
			_level_bar.value     = 0.0)
		t.tween_property(_level_bar, "value", current, 0.4) \
		 .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		_level_bar.max_value = required
		create_tween() \
			.tween_property(_level_bar, "value", current, 0.5) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_level_changed(new_level: int) -> void:
	_level_label.text = str(new_level)
	var t := create_tween()
	t.tween_property(_level_label, "scale", Vector2(1.3, 1.3), 0.1)
	t.tween_property(_level_label, "scale", Vector2.ONE,       0.15)


func _on_inventory_changed() -> void:
	if _selected_recipe != "":
		_craft_button.disabled = not InventoryManager.can_craft(_selected_recipe)


func _on_achievement_unlocked(id: String, data: Dictionary) -> void:
	show_achievement_popup(id, data)

# ─────────────────────────────────────────────────────────────────────────────
# HUD VISIBILITY
# ─────────────────────────────────────────────────────────────────────────────

## Groups that should be hidden during cutscenes / end screen.
func hide_ui() -> void:
	for node in [_bars_hud, _level_bar.get_parent(), _mining_bar.get_parent(),
				  _popup_root, _sun_moon.get_parent()]:
		if node:
			node.visible = false


func show_ui() -> void:
	for node in [_bars_hud, _level_bar.get_parent(), _mining_bar.get_parent(),
				  _popup_root, _sun_moon.get_parent()]:
		if node:
			node.visible = true

# ─────────────────────────────────────────────────────────────────────────────
# MINING BAR
# ─────────────────────────────────────────────────────────────────────────────

func set_mining_progress(value: float) -> void:
	_mining_bar.visible = true
	_mining_bar.value   = clampf(value, 0.0, 1.0) * 100.0


func hide_mining_progress() -> void:
	_mining_bar.visible = false

# ─────────────────────────────────────────────────────────────────────────────
# PANELS
# ─────────────────────────────────────────────────────────────────────────────

func show_dead() -> void:
	_dead_panel.visible = true
	$DeadPanel/Panel/Respawn.grab_focus()


func hide_dead() -> void:
	_dead_panel.visible = false

# ─────────────────────────────────────────────────────────────────────────────
# AUTOSAVE ICON
# ─────────────────────────────────────────────────────────────────────────────

func show_autosave_icon() -> void:
	if _autosave_icon == null:
		return

	if _autosave_tween and _autosave_tween.is_running():
		_autosave_tween.kill()

	_autosave_icon.visible    = true
	_autosave_icon.modulate.a = 0.0
	_autosave_tween = create_tween()

	_autosave_tween.tween_property(_autosave_icon, "modulate:a", 1.0, 0.3)
	for _i in range(3):
		_autosave_tween.tween_property(_autosave_icon, "modulate:a", 0.2, 0.2)
		_autosave_tween.tween_property(_autosave_icon, "modulate:a", 1.0, 0.2)
	_autosave_tween.tween_property(_autosave_icon, "modulate:a", 0.0, 0.4)
	_autosave_tween.tween_callback(func(): _autosave_icon.visible = false)

# ─────────────────────────────────────────────────────────────────────────────
# FADE OVERLAY
# ─────────────────────────────────────────────────────────────────────────────

var _damage_tween: Tween

func _kill_damage_tween():
	if _damage_tween and _damage_tween.is_running():
		_damage_tween.kill()
		
func show_damage_vignette(intensity := 1.0) -> void:
	_kill_damage_tween()

	_damage_fade.visible = true
	_damage_fade.modulate = Color(1, 0, 0, 0)

	_damage_tween = create_tween()

	_damage_tween.tween_property(
		_damage_fade,
		"modulate:a",
		0.35 * intensity,
		0.08
	)

	_damage_tween.tween_interval(0.05)

	_damage_tween.tween_property(
		_damage_fade,
		"modulate:a",
		0.0,
		0.6
	)

	_damage_tween.tween_callback(func():
		_damage_fade.visible = false
	)
	
func fade_in(duration := 0.5) -> void:
	_kill_fade_tween()
	_fade.visible    = true
	_fade.modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade, "modulate:a", 1.0, duration)
	await _fade_tween.finished


func fade_out(duration := 0.5) -> void:
	_kill_fade_tween()
	_fade.visible    = true
	_fade.modulate.a = 1.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(_fade, "modulate:a", 0.0, duration)
	await _fade_tween.finished
	_fade.visible = false


func _kill_fade_tween() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

# ─────────────────────────────────────────────────────────────────────────────
# POPUPS
# ─────────────────────────────────────────────────────────────────────────────

func show_item_popup(collectable: Variant, amount := 1) -> void:
	var popup = ITEM_POPUP_SCENE.instantiate()
	_popup_root.add_child(popup)
	popup.position = get_viewport().get_visible_rect().size * 0.5 + popup_offset
	popup.setup(collectable, amount)


func show_xp_popup(amount: float) -> void:
	var popup = XP_POPUP_SCENE.instantiate()
	_popup_root.add_child(popup)
	popup.anchor_left   = 1.0
	popup.anchor_right  = 1.0
	popup.anchor_top    = 0.0
	popup.anchor_bottom = 0.0
	popup.offset_left   = -160.0
	popup.offset_top    = 160.0
	popup.setup(amount)


func show_text_popup(text: String, offset_top := 200.0) -> void:
	var popup = TEXT_POPUP_SCENE.instantiate()
	_popup_root.add_child(popup)
	popup.offset_top = offset_top
	popup.setup(text,48,Color(0.85, 0.95, 1.0))

@warning_ignore("unused_parameter")
func show_top_text_popup(text: String, text_size: int = 48, offset_top := 10.0) -> void:
	var popup = TEXT_POPUP_SCENE.instantiate()
	_popup_root.add_child(popup)
	popup.offset_top = offset_top
	popup.setup(text,text_size,Color(1.0, 1.0, 1.0, 1.0))

func show_achievement_popup(_id: String, data: Dictionary) -> void:
	var popup = ACHIEVEMENT_POPUP_SCENE.instantiate()
	_popup_root.add_child(popup)
	popup.anchor_left   = 0.5
	popup.anchor_right  = 0.5
	popup.anchor_top    = 0.0
	popup.anchor_bottom = 0.0
	popup.offset_top    = 40.0
	popup.setup(
		data.get("name",        ""),
		data.get("description", ""),
		data.get("icon",        null),
	)

# ─────────────────────────────────────────────────────────────────────────────
# CRAFTING PANEL
# ─────────────────────────────────────────────────────────────────────────────

func _build_crafting_list() -> void:
	# Clear any previous buttons (useful if recipes can change at runtime)
	for child in _crafting_list.get_children():
		child.queue_free()

	var theme_res = load("res://Style/MainTheme.tres")

	for recipe_name in InventoryManager.crafting_recipes.keys():
		var btn := Button.new()
		btn.theme = theme_res
		btn.text  = recipe_name
		btn.pressed.connect(_on_recipe_selected.bind(recipe_name))
		_crafting_list.add_child(btn)


func open_crafting() -> void:
	_crafting_panel.visible = true
	get_tree().paused = true


func close_crafting() -> void:
	_crafting_panel.visible = false
	get_tree().paused = false


func _on_recipe_selected(recipe_name: String) -> void:
	_selected_recipe = recipe_name
	var recipe: Dictionary = InventoryManager.crafting_recipes[recipe_name]

	_name_label.text  = recipe_name
	_desc_label.text  = recipe.get("description", "")
	_icon_rect.texture = recipe.get("icon", null)

	var cost_lines := PackedStringArray()
	for mat in recipe["materials"]:
		cost_lines.append("%s ×%d" % [mat, recipe["materials"][mat]])
	_cost_label.text = "\n".join(cost_lines)

	_craft_button.disabled = not InventoryManager.can_craft(recipe_name)


func _on_craft_button_pressed() -> void:
	if _crafting or _selected_recipe == "":
		return
	if not InventoryManager.can_craft(_selected_recipe):
		return

	var recipe: Dictionary = InventoryManager.crafting_recipes[_selected_recipe]
	_start_crafting(_selected_recipe, recipe["time"])


func _start_crafting(recipe_name: String, time: float) -> void:
	_crafting              = true
	_craft_button.disabled = true
	_craft_progress.value  = 0.0

	var tween := create_tween()
	tween.tween_property(_craft_progress, "value", 100.0, time)
	await tween.finished

	InventoryManager.craft(recipe_name)
	AchievementManager.register_craft(1)

	_crafting              = false
	_craft_button.disabled = not InventoryManager.can_craft(recipe_name)
	_craft_progress.value  = 0.0


func _on_close_button_pressed() -> void:
	close_crafting()
