extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_container: Node = $SFXPlayers

const SFX_POOL_SIZE := 8
var sfx_players: Array[AudioStreamPlayer] = []

var sounds := {
	"unlock": preload("res://Audio/SFX/UI_Confirm.wav"),
	"back": preload("res://Audio/SFX/UI_Back.wav"),
	"confirm": preload("res://Audio/slime/jump_01.wav"),
}

func _ready():
	_create_sfx_pool()
	
func _create_sfx_pool():
	for i in SFX_POOL_SIZE:
		var p = AudioStreamPlayer.new()
		sfx_container.add_child(p)
		sfx_players.append(p)
		
@warning_ignore("shadowed_variable_base_class")
func play_sfx(name: String):
	if not sounds.has(name):
		push_warning("Sound not found: " + name)
		return

	var stream: AudioStream = sounds[name]

	for player in sfx_players:
		if not player.playing:
			player.stream = stream
			player.stop()
			player.play()
			return
