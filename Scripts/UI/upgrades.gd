extends Control

@onready var PointsLabel = $SkillPoints
@onready var upgrade_buttons = $Buttons.get_children()
@onready var info_name = $InfoPanel/UpgradeName
@onready var info_desc = $InfoPanel/UpgradeInfo
@onready var info_cost = $InfoPanel/UpgradeCost
@onready var learn_button = $InfoPanel/Learn

var selected_button: TextureButton = null
var selected_upgrade_name: String 

func _ready() -> void:
	Manager.skill_points_changed.connect(update_skill_points)
	Manager.upgrades_changed.connect(refresh_upgrade_buttons)
	update_skill_points(Manager.skill_points)

	# Make sure upgrade_buttons contains only TextureButtons
	upgrade_buttons = upgrade_buttons.filter(func(b): return b is TextureButton)

	var upgrade_names = Manager.upgrades.keys()
	for i in range(upgrade_buttons.size()):
		var btn = upgrade_buttons[i] as TextureButton
		if i < upgrade_names.size():
			btn.set_meta("upgrade_name", upgrade_names[i])
		else:
			btn.set_meta("upgrade_name", "")  # safe empty string
		btn.pressed.connect(Callable(self, "_on_upgrade_button_pressed").bind(btn))

	# Learn button
	var learn_callable = Callable(self, "_on_learn_pressed")
	if learn_button.is_connected("pressed", learn_callable):
		learn_button.pressed.disconnect(learn_callable)
	learn_button.pressed.connect(learn_callable)

	refresh_upgrade_buttons()


func update_skill_points(points: int) -> void:
	PointsLabel.text = "Skill Points: %d" % points
	refresh_upgrade_buttons()


func _on_upgrade_button_pressed(btn: TextureButton) -> void:
	# Reset previous selected button's color
	if selected_button and selected_button != btn:
		var prev_key = selected_button.get_meta("upgrade_name")
		if prev_key in Manager.learned_upgrades:
			selected_button.modulate = Color(1,1,1,1)  # learned = normal white
		elif Manager.can_learn_upgrade(prev_key):
			selected_button.modulate = Color(1,1,1,1)  # can learn = bright
		else:
			selected_button.modulate = Color(0.4,0.4,0.4,1)  # locked = gray

	selected_button = btn
	selected_upgrade_name = btn.get_meta("upgrade_name")
	if selected_upgrade_name == null or selected_upgrade_name == "":
		return

	# Highlight current selection
	btn.modulate = Color(0.8, 0.9, 1.0, 1)  # light blue tint for selected

	var u = Manager.upgrades[selected_upgrade_name]

	# Use key as display name
	info_name.text = selected_upgrade_name
	info_desc.text = u.get("description", "")

	var cost_text = ""
	if u.get("skill_cost", 0) > 0:
		cost_text += "Skill Points: %d\n" % u["skill_cost"]

	for mat in u.get("materials", {}).keys():
		cost_text += "%s: %d\n" % [mat, u["materials"][mat]]

	if u.get("requires", []).size() > 0:
		cost_text += "Requires: %s" % ", ".join(u["requires"])

	info_cost.text = cost_text

	learn_button.disabled = not Manager.can_learn_upgrade(selected_upgrade_name)

func _on_learn_pressed() -> void:
	if selected_upgrade_name and Manager.can_learn_upgrade(selected_upgrade_name):
		Manager.learn_upgrade(selected_upgrade_name)
		refresh_upgrade_buttons()

func refresh_upgrade_buttons() -> void:
	for btn in upgrade_buttons:
		if not btn.has_meta("upgrade_name"):
			continue
		var key = btn.get_meta("upgrade_name")
		if key == "" or key == null:
			btn.disabled = true
			btn.modulate = Color(0.2, 0.2, 0.2, 1)
			continue

		var learned = key in Manager.learned_upgrades
		var can_learn = Manager.can_learn_upgrade(key)

		if learned:
			btn.disabled = true
			btn.modulate = Color(1, 1, 1, 1)
		elif can_learn:
			btn.disabled = false
			btn.modulate = Color(1, 1, 1, 1)
		else:
			btn.disabled = false  # keep interactable
			btn.modulate = Color(0.4, 0.4, 0.4, 1)
