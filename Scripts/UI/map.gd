extends Control

@onready var map_label = $"../MapLabel"
@onready var no_map_label = $"../NoMap"

var cell_size := 20
var spacing := 4
var step := cell_size + spacing

func _ready():
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
	get_tree().call_group("map_cells", "queue_free")

	for room in Manager.visited_rooms:
		if not Manager.room_positions.has(room):
			continue

		var pos = Manager.room_positions[room]

		var panel = ColorRect.new()
		panel.position = pos * step
		panel.custom_minimum_size = Vector2(cell_size, cell_size)
		panel.color = Color(0.151, 0.151, 0.151, 1.0)  # black border
		panel.add_to_group("map_cells")
		add_child(panel)

		var inner = ColorRect.new()
		inner.custom_minimum_size = Vector2(cell_size - 4, cell_size - 4)
		inner.position = Vector2(2,2)

		var room_type = Manager.ROOM_TYPES.get(room, "mushroom")
		match room_type:
			"tutorial":
				inner.color = Color(0.6, 0.85, 1.0) # joyful sky blue
			"shop":
				inner.color = Color(0.4, 0.75, 0.95) # cheerful cyan
			"hub":
				inner.color = Color(0.5, 0.65, 0.85) # gentle blue-gray
			"mushroom":
				inner.color = Color(0.75, 0.55, 0.9) # playful purple
			_:
				inner.color = Color(0.8, 0.8, 0.8) # light gray

		panel.add_child(inner)

		if room == Manager.current_room_scene:
			var marker = ColorRect.new()
			var inner_size = cell_size - 4
			marker.custom_minimum_size = Vector2(inner_size * 0.5, inner_size * 0.5)
			marker.color = Color.WHITE
			marker.position = Vector2(inner_size * 0.25, inner_size * 0.25)
			inner.add_child(marker)
			marker.add_to_group("map_cells")
