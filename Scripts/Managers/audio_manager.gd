extends Node

# =============================================================================
# AUDIO MANAGER — SFX pool, music playback, crossfade
# Autoload name: AudioManager
# Scene structure required:
#   AudioManager
#   ├── MusicPlayer  (AudioStreamPlayer, bus = "Music")
#   └── SFXPlayers   (Node — pool containers are added here at runtime)
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────

## Number of simultaneous SFX channels.
const SFX_POOL_SIZE := 8

# ─────────────────────────────────────────────────────────────────────────────
# NODE REFERENCES
# ─────────────────────────────────────────────────────────────────────────────

@onready var _music_player: AudioStreamPlayer = $MusicPlayer
@onready var _sfx_root:     Node              = $SFXPlayers

# ─────────────────────────────────────────────────────────────────────────────
# SOUND REGISTRY
# ─────────────────────────────────────────────────────────────────────────────

## SFX keyed by name. Add new sounds here.
const SFX: Dictionary = {
	"unlock":  preload("res://Audio/SFX/UI_Confirm.wav"),
	"back":    preload("res://Audio/SFX/UI_Back.wav"),
	"confirm": preload("res://Audio/slime/jump_01.wav"),
}

## Music tracks keyed by name.
const MUSIC: Dictionary = {
	# "main_menu": preload("res://Audio/Music/MainMenu.ogg"),
	# "gameplay":  preload("res://Audio/Music/Gameplay.ogg"),
}

# ─────────────────────────────────────────────────────────────────────────────
# STATE
# ─────────────────────────────────────────────────────────────────────────────

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_tween: Tween = null
var _current_track: String = ""

# ─────────────────────────────────────────────────────────────────────────────
# READY
# ─────────────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_music_player.bus = "Music"
	_build_sfx_pool()

# ─────────────────────────────────────────────────────────────────────────────
# SFX
# ─────────────────────────────────────────────────────────────────────────────

## Play a sound by its key in the SFX dictionary.
## `pitch_variance` randomly offsets pitch by ±half this value for variety.
func play_sfx(sound_name: String, pitch_variance := 0.0) -> void:
	var stream: AudioStream = SFX.get(sound_name, null)
	if stream == null:
		push_warning("AudioManager: SFX '%s' not found." % sound_name)
		return

	var player := _get_free_sfx_player()
	if player == null:
		return  # All channels busy — silently drop

	player.stream       = stream
	player.pitch_scale  = 1.0 + randf_range(-pitch_variance * 0.5, pitch_variance * 0.5)
	player.play()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return null   # No free channel


func _build_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		_sfx_root.add_child(p)
		_sfx_players.append(p)

# ─────────────────────────────────────────────────────────────────────────────
# MUSIC
# ─────────────────────────────────────────────────────────────────────────────

## Play a music track by its key in the MUSIC dictionary.
## Crossfades smoothly from any currently playing track.
func play_music(track_name: String, fade_time := 1.0) -> void:
	if track_name == _current_track:
		return

	var stream: AudioStream = MUSIC.get(track_name, null)
	if stream == null:
		push_warning("AudioManager: Music track '%s' not found." % track_name)
		return

	_current_track = track_name
	_crossfade_music(stream, fade_time)


func stop_music(fade_time := 1.0) -> void:
	if not _music_player.playing:
		return
	_current_track = ""
	if fade_time <= 0.0:
		_music_player.stop()
		return
	_kill_music_tween()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_time)
	_music_tween.tween_callback(_music_player.stop)


func _crossfade_music(stream: AudioStream, fade_time: float) -> void:
	_kill_music_tween()
	_music_tween = create_tween()

	if _music_player.playing and fade_time > 0.0:
		# Fade out existing track
		_music_tween.tween_property(_music_player, "volume_db", -80.0, fade_time * 0.5)
		_music_tween.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = -80.0
			_music_player.play()
		)
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_time * 0.5)
	else:
		_music_player.stream = stream
		_music_player.volume_db = -80.0
		_music_player.play()
		_music_tween.tween_property(_music_player, "volume_db", 0.0, fade_time)


func _kill_music_tween() -> void:
	if _music_tween and _music_tween.is_running():
		_music_tween.kill()
