extends Node3D

signal value_changed(value: float)

@export_group("Settings")
@export var value_per_degree := 1/360.0  # 360 degree rotation is 0 to 100
@export var sensitivity := 0.25
@export var rotation_axis := Vector3(0, -1, 0)
@export var start_angle_deg := 0.0

@export_group("References")
@export var pivot: Node3D
@export var body: StaticBody3D

# Internal vars
var _dragging := false
var _angle := 0.0
var _base_basis: Basis
var _saved_mouse_pos: Vector2

func _ready() -> void:
	get_viewport().physics_object_picking = true
	_base_basis = pivot.transform.basis

	# Signals
	body.input_event.connect(_on_body_input_event)
	body.mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND))
	body.mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW))

	set_angle(start_angle_deg)

func _on_body_input_event(_camera, event, _pos, _normal, _shape_idx) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_dragging = true
		_saved_mouse_pos = get_viewport().get_mouse_position()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().warp_mouse(_saved_mouse_pos)
	elif event is InputEventMouseMotion:
		# drag right or up = turn clockwise
		var delta: float = (event.relative.x - event.relative.y) * sensitivity
		rotate_by(delta)

func rotate_by(delta_deg: float) -> void:
	set_angle(_angle + delta_deg)
	value_changed.emit(delta_deg * value_per_degree)

func set_angle(deg: float) -> void:
	_angle = fposmod(deg, 360.0)
	pivot.transform.basis = _base_basis * Basis(rotation_axis.normalized(), deg_to_rad(_angle))
