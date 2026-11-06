extends Control

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"
const OPTIONS_MENU_SCENE_PATH := "res://scenes/ui/options_menu.tscn"
const MAIN_GAME_SCENE_PATH := "res://scenes/main.tscn"

@export_group("References")
@export var play_button: Button
@export var options_button: Button
@export var quit_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	play_button.pressed.connect(_on_play_button_pressed)
	options_button.pressed.connect(_on_options_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

	var is_paused := get_tree().paused
	play_button.text = "RESUME" if is_paused else "PLAY"
	quit_button.text = "MENU" if is_paused else "QUIT"

func _on_play_button_pressed() -> void:
	# If paused resume
	if get_tree().paused:
		GameManager.toggle_pause()
	
	# If not load a new game
	else:
		GameManager.start_new_game()
		await SceneManager.change_scene(MAIN_GAME_SCENE_PATH, SceneManager.TransitionType.FADE)

func _on_options_button_pressed() -> void:
	await SceneManager.change_scene(OPTIONS_MENU_SCENE_PATH, SceneManager.TransitionType.FADE)

func _on_quit_button_pressed() -> void:
	# If paused return to main menu
	if get_tree().paused:
		GameManager.exit_to_main_menu()
		await SceneManager.change_scene(MAIN_MENU_SCENE_PATH, SceneManager.TransitionType.FADE)
	else:
		get_tree().quit()
