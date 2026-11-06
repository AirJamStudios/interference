extends Node3D

signal value_changed(value: float)

@export_group("Settings")
@export var min_angle_deg := 0.0
@export var max_angle_deg := 360.0
@export var sensitivity := 0.5
@export var rotation_axis := Vector3(0, -1, 0)
@export_range(0.0, 1.0) var start_value := 0.0

@export_group("References")
@export var pivot: Node3D
@export var body: StaticBody3D

# Internal vars
var _dragging := false
var _angle := 0.0
var _base_basis: Basis

func _ready() -> void:
	get_viewport().physics_object_picking = true
	_base_basis = pivot.transform.basis

	# Signals
	body.input_event.connect(_on_body_input_event)
	body.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	body.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

	set_value(start_value)

func _on_body_input_event(_camera, event, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dragging = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion:
		# drag right or up = turn clockwise
		var delta: float = (event.relative.x - event.relative.y) * sensitivity
		set_angle(_angle + delta)

func set_angle(deg: float) -> void:
	_angle = clampf(deg, min_angle_deg, max_angle_deg)
	pivot.transform.basis = _base_basis * Basis(rotation_axis.normalized(), deg_to_rad(_angle))
	value_changed.emit(get_value())

func get_value() -> float:
	if is_equal_approx(min_angle_deg, max_angle_deg):
		return 0.0
	return inverse_lerp(min_angle_deg, max_angle_deg, _angle)

func set_value(value: float) -> void:
	set_angle(lerpf(min_angle_deg, max_angle_deg, clampf(value, 0.0, 1.0)))
