extends Node

# Game manager handles tree play/pause logic and gameplay music

enum Sfx { ALARM, UI_SELECT, WAVE_COMPLETE, FADE_IN }

const SFX_STREAMS := {
	Sfx.ALARM: preload("res://assets/sound_fx/sound_fx/alarm.wav"),
	Sfx.UI_SELECT: preload("res://assets/sound_fx/sound_fx/ui_select.wav"),
	Sfx.WAVE_COMPLETE: preload("res://assets/sound_fx/sound_fx/wave_complete.wav"),
	Sfx.FADE_IN: preload("res://assets/sound_fx/sound_fx/fade_in.wav"),
}

const SFX_BUS := &"SFX"
const SFX_POOL_SIZE := 8

@onready var music_bus_id: int = AudioServer.get_bus_index("Music")

var can_pause := false
signal pause_state_changed(is_paused: bool)
signal stop_level

var _sfx_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_sfx_pool()
	get_tree().node_added.connect(_on_node_added)
	_connect_existing_buttons.call_deferred(get_tree().root)

func _unhandled_input(event: InputEvent) -> void:
	if not can_pause:
		return
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	var new_pause: bool = not get_tree().paused
	get_tree().paused = new_pause
	AudioServer.set_bus_mute(music_bus_id, new_pause)
	pause_state_changed.emit(new_pause)

func stop_level_request() -> void:
	set_game_state_active(false)
	pause_state_changed.emit(false)
	stop_level.emit()

func set_game_state_active(active: bool) -> void:
	can_pause = active
	get_tree().paused = false
	AudioServer.set_bus_mute(music_bus_id, not active)

func play_sfx(sfx: Sfx, volume_db := 0.0, pitch_scale := 1.0) -> void:
	var player := _get_free_sfx_player()
	player.stream = SFX_STREAMS[sfx]
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

func _setup_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = SFX_BUS
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		_sfx_players.append(player)

func _get_free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player
	var oldest := _sfx_players[0]
	for player in _sfx_players:
		if player.get_playback_position() > oldest.get_playback_position():
			oldest = player
	return oldest

func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.pressed.is_connected(_on_ui_button_pressed):
		node.pressed.connect(_on_ui_button_pressed)

func _connect_existing_buttons(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_connect_existing_buttons(child)

func _on_ui_button_pressed() -> void:
	play_sfx(Sfx.UI_SELECT)
