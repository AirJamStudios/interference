class_name DialogueManager
extends CanvasLayer

@export_group("References")
@export var portrait_rect: TextureRect
@export var text_label: RichTextLabel

@export_group("Settings")
@export var soldier_portrait: Texture2D
@export var seconds_per_character : float = 0.03

var current_lines: Array = []
var current_index: int = 0
var is_typing: bool = false
var _dialogue_active: bool = false
var tween: Tween
var id: String = ""

signal dialogue_completed(id: String)

func _ready() -> void:
	hide()

func reset() -> void:
	current_lines = []
	current_index = 0
	is_typing = false
	_dialogue_active = false
	id = ""

func start_dialogue(lines: Array, p_id: String = "") -> void:
	id = p_id
	current_lines = lines
	current_index = 0
	_dialogue_active = true
	show()
	_show_line()

func _show_line() -> void:
	if current_index >= len(current_lines):
		end_dialogue()
		return
	
	portrait_rect.texture = soldier_portrait
	text_label.text = current_lines[current_index]
	
	text_label.visible_characters = 0
	is_typing = true
	
	# Animate typing like 
	if tween:
		tween.kill()
	tween = create_tween()
	var total_chars = text_label.get_total_character_count()
	var duration = total_chars * seconds_per_character
	tween.tween_property(text_label, "visible_characters", total_chars, duration)
	tween.finished.connect(func(): is_typing = false)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if get_tree().paused: 
		return
	
	# To skip forward
	var is_left_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if event.is_action_pressed("ui_accept") or is_left_click:
		get_viewport().set_input_as_handled()
		#Finish typing or skip to next line
		if is_typing:
			tween.kill()
			text_label.visible_characters = -1 
			is_typing = false
		else:
			current_index += 1
			_show_line()

func end_dialogue() -> void:
	hide()
	_dialogue_active = false
	dialogue_completed.emit(id)

func is_dialogue_active() -> bool:
	return _dialogue_active
