extends TabContainer

const TAB_ACTIONS := {
	"inventory": "Inventory",
	"map":       "Map",
	"stats":     "Stats",
	"quest":     "Quest",
	"upgrades":  "Upgrades"
}

func _ready() -> void:
	visible = false
	$"../Q".visible = false
	$"../E".visible = false
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	focus_mode   = Control.FOCUS_ALL


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return

	# ─── Q / E cycling ────────────────────────────────────────
	if visible:
		match event.keycode:
			KEY_Q:
				_cycle_tab(-1)
				_mark_handled(event)
				return
			KEY_E:
				_cycle_tab(1)
				_mark_handled(event)
				return

	# ─── Direct tab hotkeys ───────────────────────────────────
	for action_name in TAB_ACTIONS:
		if Input.is_action_just_pressed(action_name):
			_toggle_or_switch(TAB_ACTIONS[action_name])
			_mark_handled(event)
			return

	# ─── Pause / Settings ─────────────────────────────────────
	if Input.is_action_just_pressed("pause"):
		if visible:
			close_menu()
		else:
			open_tab("Settings")
		_mark_handled(event)


# ──────────────────────────────────────────────────────────────
# Tab switching logic
# ──────────────────────────────────────────────────────────────

func _toggle_or_switch(tab_name: String) -> void:
	var idx := _get_tab_index(tab_name)
	if idx < 0:
		return

	if not visible:
		current_tab = idx
		visible = true
		_show_background()
		get_tree().paused = true
		_focus_current_content()
	else:
		if current_tab == idx:
			close_menu()
		else:
			current_tab = idx
			_focus_current_content()


func open_tab(tab_name: String) -> void:
	var idx := _get_tab_index(tab_name)
	if idx >= 0:
		current_tab = idx
	
	visible = true
	_show_background()
	get_tree().paused = true
	_focus_current_content()


func close_menu() -> void:
	visible = false
	_hide_background()
	get_tree().paused = false


func _cycle_tab(direction: int) -> void:
	var count := get_tab_count()
	if count <= 1:
		return

	var next := current_tab + direction
	
	# Wrap around
	if next < 0:
		next = count - 1
	elif next >= count:
		next = 0
	
	current_tab = next
	_focus_current_content()


# ──────────────────────────────────────────────────────────────
# Focus helpers
# ──────────────────────────────────────────────────────────────

func _focus_current_content() -> void:
	await get_tree().process_frame
	
	var content := get_current_tab_control()
	if not content:
		return
	
	if content.focus_mode != FOCUS_NONE:
		content.grab_focus()
		return
	
	var target := _find_first_focusable(content)
	if target:
		target.grab_focus()


func _find_first_focusable(node: Node) -> Control:
	if node is Control and node.focus_mode != FOCUS_NONE:
		return node
	
	for child in node.get_children():
		var found := _find_first_focusable(child)
		if found:
			return found
	
	return null


# ──────────────────────────────────────────────────────────────
# Small utilities
# ──────────────────────────────────────────────────────────────

func _get_tab_index(tab_title: String) -> int:
	var search := tab_title.to_lower()
	for i in get_tab_count():
		if get_tab_title(i).to_lower() == search:
			return i
	return -1


func _show_background() -> void:
	$"../Q".visible = true
	$"../E".visible = true

func _hide_background() -> void:
	$"../Q".visible = false
	$"../E".visible = false

func _mark_handled(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
	accept_event()
