extends Node3D

signal toggled(is_on: bool)

@export var knob_mesh: MeshInstance3D
@export var click_area: Area3D
@export var toggle_angle_deg: float = -88

var is_on: bool = true

func _ready() -> void:
	if click_area:
		click_area.input_event.connect(_on_area_input_event)

func _on_area_input_event(_camera: Node, event: InputEvent, _pos: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_power()

func toggle_power() -> void:
	is_on = !is_on
	if knob_mesh:
		knob_mesh.rotation_degrees.x = toggle_angle_deg if !is_on else 0.0
	toggled.emit(is_on)
