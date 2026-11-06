extends Node2D

const MAIN_MENU_SCENE = preload("res://scenes/main_menu.tscn")
var pause_menu_overlay: Node = null

@export_group("References")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.pause_state_changed.connect(_on_pause_state_changed)
	if get_tree().paused:
		create_pause_menu()
		
func _on_pause_state_changed(is_paused: bool) -> void:
	if is_paused:
		create_pause_menu()
	else:
		remove_pause_menu()

func create_pause_menu() -> void:
	if is_instance_valid(pause_menu_overlay):
		return
	pause_menu_overlay = MAIN_MENU_SCENE.instantiate()
	add_child(pause_menu_overlay)
	pause_menu_overlay.process_mode = Node.PROCESS_MODE_ALWAYS

func remove_pause_menu() -> void:
	if is_instance_valid(pause_menu_overlay):
		pause_menu_overlay.queue_free()
		pause_menu_overlay = null
