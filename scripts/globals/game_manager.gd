extends Node

# Game manager handles tree play/pause logic and gameplay music

@onready var music_bus_id: int = AudioServer.get_bus_index("Music")

var can_pause := false
signal pause_state_changed(is_paused: bool)
signal stop_level

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

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
