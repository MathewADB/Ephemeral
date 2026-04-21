extends CanvasLayer

@export var popup_offset := Vector2(0, 80)
@onready var moonlight = $Moonlight
@onready var autosaveicon = $AutosaveIcon
@onready var level_bar = $Level/LevelBar
@onready var level_label = $Level/LevelLabel
@onready var fade = $Fade
@onready var miningbar = $Mining/Miningbar
@onready var time_icon = $TimeIconSmall
@onready var bars = $"Bars HUD"
@onready var crafting_panel = $"Crafting Panel"
@onready var crafting_list = $"Crafting Panel/ItemList"
@onready var craft_button = $"Crafting Panel/CraftButton"
@onready var craft_progress = $"Crafting Panel/ProgressBar"
@onready var icon_rect = $"Crafting Panel/Icon"
@onready var name_label = $"Crafting Panel/Name"
@onready var desc_label = $"Crafting Panel/Description"
@onready var cost_label = $"Crafting Panel/Cost"

var selected_recipe = null
var crafting := false

var popup_scene := preload("res://Scenes/Control/item_popup.tscn")
var popup_index := 0

var xp_popup_scene := preload("res://Scenes/Control/experience_popup.tscn")
var text_popup_scene = preload("res://Scenes/Control/text_popup.tscn")

var current_tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	crafting_panel.visible = false
	$"Player Panel".visible = true
	set_time(Manager.is_night())
	Manager.night_changed.connect(set_time)
	Manager.xp_changed.connect(update_bar)
	Manager.level_changed.connect(update_level)
	Manager.xp_gained.connect(show_xp_popup)
	update_bar(Manager.current_xp, Manager.get_required_xp(Manager.level))
	update_level(Manager.level)
	
	for recipe_name in Manager.crafting_recipes.keys():
		var btn = Button.new()
		btn.theme = load("res://Style/MainTheme.tres")
		btn.text = recipe_name
		btn.pressed.connect(_on_recipe_selected.bind(recipe_name))
		crafting_list.add_child(btn)

# ===== Autosave 

func show_autosave_icon():
	if autosaveicon == null:
		return
	
	# Stop previous tween if running
	if current_tween and current_tween.is_running():
		current_tween.kill()

	autosaveicon.visible = true
	autosaveicon.modulate.a = 0.0

	current_tween = create_tween()

	# Fade in
	current_tween.tween_property(autosaveicon, "modulate:a", 1.0, 0.3)

	# Blink 3 times
	for i in range(3):
		current_tween.tween_property(autosaveicon, "modulate:a", 0.2, 0.2)
		current_tween.tween_property(autosaveicon, "modulate:a", 1.0, 0.2)

	# Fade out
	current_tween.tween_property(autosaveicon, "modulate:a", 0.0, 0.4)

	# Hide after finishing
	current_tween.tween_callback(func():
		autosaveicon.visible = false
	)
# ===== Crafting
	
func hide_ui():
	self.visible = false
	
func show_ui():
	self.visible = true
	
func _on_recipe_selected(recipe_name: String) -> void:
	selected_recipe = recipe_name
	var recipe = Manager.crafting_recipes[recipe_name]
	
	name_label.text = recipe_name
	desc_label.text = recipe.get("description", "")
	icon_rect.texture = recipe.get("icon", null)
	
	var cost_text := ""
	for mat in recipe["materials"]:
		cost_text += mat + " x" + str(recipe["materials"][mat]) + "\n"

	cost_label.text = cost_text

	craft_button.disabled = not can_craft(recipe_name)
	
func can_craft(recipe_name: String) -> bool:
	var recipe = Manager.crafting_recipes[recipe_name]
	
	for mat in recipe["materials"]:
		if not Manager.items.has(mat) or Manager.items[mat] < recipe["materials"][mat]:
			return false
	
	return true
	
func _on_craft_button_pressed() -> void:
	if crafting or selected_recipe == null:
		return
		
	if not can_craft(selected_recipe):
		return
		
	var recipe = Manager.crafting_recipes[selected_recipe]
	
	# remove materials
	for mat in recipe["materials"]:
		Manager.remove_item(mat, recipe["materials"][mat])
	
	start_crafting(selected_recipe, recipe["time"])
	
func start_crafting(recipe_name: String, time: float):
	crafting = true
	craft_button.disabled = true
	craft_progress.value = 0
	
	var tween = create_tween()
	tween.tween_property(craft_progress, "value", 100, time)
	
	await tween.finished
	
	Manager.add_item(recipe_name, 1)
	Manager.register_craft(1)
	
	crafting = false
	craft_button.disabled = false
	craft_progress.value = 0
	
func _on_close_button_pressed() -> void:
	close_crafting()
	
func open_crafting():
	crafting_panel.visible = true
	get_tree().paused = true

func close_crafting():
	crafting_panel.visible = false
	get_tree().paused = false
	
# ===== XP Bar

func update_bar(current_xp, required_xp):		
	if current_xp < level_bar.value:
		var tween = create_tween()
		tween.tween_property(level_bar, "value", level_bar.max_value, 0.4)
		tween.tween_callback(func():
			level_bar.max_value = required_xp
			level_bar.value = 0
		)
		tween.tween_property(level_bar, "value", current_xp, 0.4)
	else:
		level_bar.max_value = required_xp
		create_tween().tween_property(
			level_bar,
			"value",
			current_xp,
			0.5
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func update_level(new_level):
	level_label.text = str(new_level)

	var tween = create_tween()
	tween.tween_property(level_label, "scale", Vector2(1.2,1.2), 0.1)
	tween.tween_property(level_label, "scale", Vector2(1,1), 0.1)
	
func set_time(is_night:bool):
	if is_night :
		time_icon.frame = 0 
	else :
		time_icon.frame = 1

func show_item_popup(collectable, amount := 1):
	var popup = popup_scene.instantiate()
	$Popup.add_child(popup)

	var center := get_viewport().get_visible_rect().size * 0.5
	popup.position = center + popup_offset

	popup.setup(collectable, amount)
	
func show_xp_popup(amount: int):
	var popup = xp_popup_scene.instantiate()
	$Popup.add_child(popup)

	popup.anchor_left = 1
	popup.anchor_right = 1
	popup.anchor_top = 0
	popup.anchor_bottom = 0

	popup.offset_left = -160 
	popup.offset_top = 160   

	popup.setup(amount)
	
# ===== Text Popup =====
func show_text_popup(text: String):
	var popup = text_popup_scene.instantiate()
	$Popup.add_child(popup)
	popup.setup(text)
	
	popup.offset_top = 160   

			
func set_progress(value):
	miningbar.visible = true
	miningbar.value = value * 100

func hide_progress():
	miningbar.visible = false
