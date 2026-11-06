extends Node

# Game manager handles tree play/pause logic and gameplay music

@onready var music_bus_id: int = AudioServer.get_bus_index("Music")

var is_in_game := false 
signal pause_state_changed(is_paused: bool)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if not is_in_game:
		return
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	if not get_tree().paused:
		AudioServer.set_bus_mute(music_bus_id, true)
		get_tree().paused = true
		pause_state_changed.emit(true)
	else:
		get_tree().paused = false
		AudioServer.set_bus_mute(music_bus_id, false)
		pause_state_changed.emit(false)

func start_new_game() -> void:
	is_in_game = true
	AudioServer.set_bus_mute(music_bus_id, false)

func exit_to_main_menu() -> void:
	is_in_game = false
	get_tree().paused = false
	AudioServer.set_bus_mute(music_bus_id, true)
