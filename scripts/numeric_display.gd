class_name NumericDisplay
extends Node3D

@export_group("References")
@export var sub_viewport: SubViewport
@export var mesh: MeshInstance3D
@export var label: Label
@export var user_wave: UserWave

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	var viewport_tex := sub_viewport.get_texture()
	
	mat.albedo_texture = viewport_tex
	mat.emission_enabled = true
	mat.emission_texture = viewport_tex
	mat.emission_energy_multiplier = 0.4
	
	mesh.material_override = mat

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clear()

func set_value(value: float) -> void:
	var int_value : int = (roundi(value * 100.0))
	label.text = "%3d" % clampi(int_value, 0, 100)

func clear() -> void:
	set_value(0)

