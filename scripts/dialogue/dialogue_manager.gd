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
var tween: Tween

signal dialogue_completed(index: int)

func _ready() -> void:
	hide()

func start_dialogue(lines: Array) -> void:
	current_lines = lines
	current_index = 0
	show()
	_show_line()

func _show_line() -> void:
	if current_index >= len(current_lines):
		end_dialogue()
		return
	
	#TODO: encode in map the character or character animatoin and change between soldier sprites
	var line_data = current_lines[current_index]
	portrait_rect.texture = soldier_portrait
	text_label.text = line_data["text"]
	
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
	dialogue_completed.emit(null)