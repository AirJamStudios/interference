class_name NumericDisplay
extends Node3D

@export_group("References")
@export var sub_viewport: SubViewport
@export var mesh: MeshInstance3D
@export var label: Label
@export var icon_rect: TextureRect
@export var user_wave: UserWave

@export_group("Wave Icons")
@export var sine_texture: Texture2D
@export var square_texture: Texture2D
@export var triangle_texture: Texture2D

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	var viewport_tex := sub_viewport.get_texture()
	
	mat.albedo_texture = viewport_tex
	mat.emission_enabled = true
	mat.emission_texture = viewport_tex
	mat.emission_energy_multiplier = 0.4
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	mesh.material_override = mat

	if label:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		clear()
	
	# start in correct mode
	if user_wave:
		set_wave_type(user_wave.get_wave_type())

func set_value(value: float) -> void:
	_show_label_mode()
	var int_value: int = roundi(value * 100.0)
	label.text = "%3d" % clampi(int_value, 0, 100)

func cycle_wave_type() -> void:
	var current_type := user_wave.get_wave_type()
	var next_type := ((current_type + 1) % 3) as SingleWave.WaveType
	set_wave_type(next_type)

func set_wave_type(type: SingleWave.WaveType) -> void:
	_show_icon_mode()
	user_wave.set_wave_type(type)
	user_wave.wave_type = type
	match type:
		SingleWave.WaveType.SINE:
			icon_rect.texture = sine_texture
		SingleWave.WaveType.SQUARE:
			icon_rect.texture = square_texture
		SingleWave.WaveType.TRIANGLE:
			icon_rect.texture = triangle_texture

func clear() -> void:
	set_value(0)

func _show_label_mode() -> void:
	if label:
		label.visible = true
	if icon_rect:
		icon_rect.visible = false

func _show_icon_mode() -> void:
	if label:
		label.visible = false
	if icon_rect:
		icon_rect.visible = true
