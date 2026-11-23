extends Node3D

@export var level_manager : LevelManager
@export var tutorial : CanvasLayer

const MAIN_MENU_SCENE = preload("res://scenes/main_menu.tscn")
var pause_menu_overlay: Node = null

@export_group("References")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.pause_state_changed.connect(_on_pause_state_changed)
	GameManager.stop_level.connect(_on_stop_level_requested)
	tutorial.hide()

		
func _on_pause_state_changed(is_paused: bool) -> void:
	if is_paused:
		_close_tutorial()
		create_pause_menu()
	else:
		remove_pause_menu()

func create_pause_menu() -> void:
	if is_instance_valid(pause_menu_overlay):
		return
	pause_menu_overlay = MAIN_MENU_SCENE.instantiate()
	add_child(pause_menu_overlay)
	pause_menu_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	level_manager.set_simulation_paused(true)

func remove_pause_menu() -> void:
	if is_instance_valid(pause_menu_overlay):
		pause_menu_overlay.queue_free()
		pause_menu_overlay = null
	level_manager.set_simulation_paused(false)

func _on_stop_level_requested() -> void:
	remove_pause_menu()
	level_manager.go_to_level_select()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	# Don't toggle tutorial if paused not actively playing
	if get_tree().paused or not level_manager.is_playing or level_manager.level_select_ui.visible:
		return

	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		if tutorial.visible:
			_close_tutorial()
		else:
			tutorial.show()
			level_manager.set_simulation_paused(true)
		get_viewport().set_input_as_handled()

func _close_tutorial() -> void:
	if not tutorial.visible:
		return
	tutorial.hide()
	level_manager.set_simulation_paused(false)
