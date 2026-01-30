extends Node

signal night_changed(is_night: bool)

var game_seconds := 0.0
var seconds_per_day := 1200.0
var start_day_progress := 0.36
var time_scale := 1.0
var _is_night := false

var activate_spawn : bool = false
var spawn_location : Vector2

var items = {"Ruby Stone": 0}

func _ready():
	game_seconds = start_day_progress * seconds_per_day
	_is_night = is_night()
	night_changed.emit(_is_night)

func _process(delta):
	game_seconds += delta * time_scale

	var now_night := is_night()
	if now_night != _is_night:
		_is_night = now_night
		night_changed.emit(_is_night)

func get_day() -> int:
	return int(game_seconds / seconds_per_day)

func get_day_progress() -> float:
	return fmod(game_seconds, seconds_per_day) / seconds_per_day

func is_night() -> bool:
	var t := get_day_progress()
	return t < 0.25 or t > 0.75
