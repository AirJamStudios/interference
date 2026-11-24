class_name Alarm
extends Node3D

@export var spinner_pivot: Node3D
@export var omni_light: OmniLight3D
@export var spinner_light: SpotLight3D
@export var spin_speed: float = 6.0
@export var is_active: bool = true

func _ready() -> void:
	# Make sure the alarm starts turned off
	set_alarm_active(false)

func _process(delta: float) -> void:
	if is_active:
		# Adjust rotate_y to rotate_z or rotate_x depending on your wall orientation
		spinner_pivot.rotate_y(spin_speed * delta)

func activate() -> void:
	set_alarm_active(true)

func deactivate() -> void:
	set_alarm_active(false)

func set_alarm_active(active: bool) -> void:
	is_active = active
	spinner_light.visible = active
	omni_light.visible = active
