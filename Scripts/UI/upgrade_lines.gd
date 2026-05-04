extends Node2D

@export var root_icon_path: NodePath
@onready var root_icon = get_node(root_icon_path)

@export var upgrade_panel_path: NodePath
@onready var panel = get_node(upgrade_panel_path)

var pulses := []
var pulse_timer := 0.0
var lines := []

func _process(delta: float) -> void:
	pulse_timer += delta

	if pulse_timer > 0.8:
		pulse_timer = 0.0
		_spawn_pulses()

	# update pulses
	for p in pulses:
		p["t"] += delta * p["speed"]

		var pos = p["from"].lerp(p["to"], p["t"])

		p["trail"].append(pos)

		if p["trail"].size() > 14:
			p["trail"].pop_front()

	pulses = pulses.filter(func(p): return p["t"] <= 1.0)

	queue_redraw()


func _draw() -> void:
	lines.clear()
	if panel == null:
		return

	var buttons = panel.upgrade_buttons
	var upgrades = UpgradeManager.upgrades
	var learned = UpgradeManager.learned_upgrades

	@warning_ignore("shadowed_variable")
	var root_pos = root_icon.get_global_rect().get_center()

	# -------------------------
	# DRAW CONNECTIONS
	# -------------------------
	for btn in buttons:
		if not btn.has_meta("upgrade_name"):
			continue

		var to_key = btn.get_meta("upgrade_name")
		if to_key == "":
			continue

		var u = upgrades.get(to_key, {})
		var requires = u.get("requires", [])

		var to_pos = btn.get_global_rect().get_center()

		# ROOT CONNECTION
		if requires.is_empty():
			lines.append({"from": root_pos, "to": to_pos, "active": false})

			draw_line(to_local(root_pos), to_local(to_pos), Color.WHITE, 16.0)
			draw_line(to_local(root_pos), to_local(to_pos), Color.WHITE.darkened(0.3), 8.0)
			continue

		# NORMAL CONNECTIONS
		for req in requires:
			var from_btn = panel.get_button_by_name(req)
			if from_btn == null:
				continue

			var from_pos = from_btn.get_global_rect().get_center()
			var active = req in learned

			lines.append({"from": from_pos, "to": to_pos, "active": active})

			var color := Color(0.25, 0.25, 0.25)

			if active:
				color = Color.WHITE

			draw_line(to_local(from_pos), to_local(to_pos), color, 16.0)
			draw_line(to_local(from_pos), to_local(to_pos), color.darkened(0.3), 8.0)

	# -------------------------
	# TRAILS
	# -------------------------
	for p in pulses:
		var trail = p["trail"]

		for i in range(trail.size()):
			var t = float(i) / max(1.0, trail.size() - 1)

			var pos = to_local(trail[i])

			var size = lerp(10.0, 2.0, t)
			var alpha = t * 0.6

			draw_circle(pos, size, Color(0.6, 0.8, 1.0, alpha))

	# -------------------------
	# PULSES
	# -------------------------
	for p in pulses:
		var pos = p["from"].lerp(p["to"], p["t"])
		var local_pos = to_local(pos)

		draw_circle(local_pos, 6.0, Color.WHITE)
		draw_circle(local_pos, 10.0, Color(0.848, 0.923, 1.0, 0.4))


func _spawn_pulses() -> void:
	if panel == null:
		return

	var buttons = panel.upgrade_buttons
	var upgrades = UpgradeManager.upgrades
	var learned = UpgradeManager.learned_upgrades

	for btn in buttons:
		if not btn.has_meta("upgrade_name"):
			continue

		var to_key = btn.get_meta("upgrade_name")
		if to_key == "":
			continue

		var u = upgrades.get(to_key, {})
		var requires = u.get("requires", [])

		var to_pos = btn.get_global_rect().get_center()

		# ROOT → unlearned nodes
		if requires.is_empty():
			if not learned.has(to_key):
				_add_pulse(root_pos(), to_pos)
			continue

		# learned dependency pulses
		for req in requires:
			if learned.has(req):
				var from_btn = panel.get_button_by_name(req)
				if from_btn == null:
					continue

				var from_pos = from_btn.get_global_rect().get_center()
				_add_pulse(from_pos, to_pos)


func _add_pulse(from_pos: Vector2, to_pos: Vector2) -> void:
	pulses.append({
		"from": from_pos,
		"to": to_pos,
		"t": 0.0,
		"speed": 1.2 + randf() * 0.5,
		"trail": []
	})


func root_pos() -> Vector2:
	return root_icon.get_global_rect().get_center()
