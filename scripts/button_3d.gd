class_name PressButton3D
extends Node3D

signal pressed
signal released

@export var body: StaticBody3D
@export var press_offset := Vector3(-0.15, 0, 0)
@export var press_time := 0.09

var _rest_position: Vector3
var _is_down := false
var _tween: Tween

func _ready() -> void:
	get_viewport().physics_object_picking = true
	_rest_position = position

	if body == null:
		for child in get_children():
			if child is StaticBody3D:
				body = child
				break
	assert(body != null, "%s: no StaticBody3D found" % name)

	body.input_event.connect(_on_body_input_event)
	body.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	body.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

func _on_body_input_event(_camera, event, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_press()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if _is_down and event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release()

func _press() -> void:
	_is_down = true
	GameManager.play_sfx(GameManager.Sfx.BUTTON_PRESS)
	_move_to(_rest_position + press_offset)
	pressed.emit()

func _release() -> void:
	_is_down = false
	_move_to(_rest_position)
	released.emit()

func _move_to(target: Vector3) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", target, press_time) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)