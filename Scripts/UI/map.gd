extends Control

@onready var map_label = $"../MapLabel"
@onready var no_map_label = $"../NoMap"

var cell_size := 18
var spacing := 5
var step := cell_size + spacing

var tile_style := StyleBoxFlat.new()

func _ready():
	tile_style.corner_radius_top_left = 3
	tile_style.corner_radius_top_right = 3
	tile_style.corner_radius_bottom_left = 3
	tile_style.corner_radius_bottom_right = 3

	tile_style.border_width_left = 1
	tile_style.border_width_right = 1
	tile_style.border_width_top = 1
	tile_style.border_width_bottom = 1
	tile_style.border_color = Color("#0F1628")

	Manager.map_updated.connect(update_map)
	update_map()


func update_map():
	if Manager.map_unlocked:
		visible = true
		map_label.visible = true
		no_map_label.visible = false
		draw_map()
	else:
		visible = false
		map_label.visible = false
		no_map_label.visible = true


func draw_map():
	for c in self.get_children():
		c.queue_free()

	for room in Manager.visited_rooms:
		if not Manager.room_positions.has(room):
			continue

		var pos = Manager.room_positions[room]

		var tile := Panel.new()
		tile.position = pos * step
		tile.size = Vector2(cell_size, cell_size)

		var style := tile_style.duplicate()
		style.bg_color = Color("#1A2236")

		var room_type = Manager.ROOM_TYPES.get(room, "normal")

		if room_type == "shop" or room_type == "hub":
			style.bg_color = Color("#41C7F4")
		elif room in Manager.visited_rooms:
			style.bg_color = Color("#2A3148")

		tile.add_theme_stylebox_override("panel", style)

		self.add_child(tile)

		# PLAYER MARKER
		if room == Manager.current_room_scene:
			_create_player_marker(tile)

func _create_player_marker(parent: Control) -> void:
	var marker := ColorRect.new()

	marker.size = Vector2(cell_size * 0.45, cell_size * 0.45)
	marker.position = Vector2(cell_size * 0.275, cell_size * 0.275)
	marker.color = Color("#E8EDF7")

	parent.add_child(marker)

	_pulse_marker(marker)
	
func _pulse_marker(marker: Control) -> void:
	while is_instance_valid(marker) and marker.is_inside_tree():
		var t1 := create_tween()
		t1.tween_property(marker, "modulate:a", 0.9, 0.6)
		await t1.finished

		if not is_instance_valid(marker) or not marker.is_inside_tree():
			break

		var t2 := create_tween()
		t2.tween_property(marker, "modulate:a", 0.4, 0.6)
		await t2.finished
