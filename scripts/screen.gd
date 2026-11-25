extends MeshInstance3D

@export var sub_viewport: SubViewport
const CRT_SHADER := preload("res://shaders/crt.gdshader")

var crt_mat: ShaderMaterial
var off_mat: StandardMaterial3D

func _ready() -> void:
	crt_mat = ShaderMaterial.new()
	crt_mat.shader = CRT_SHADER
	crt_mat.set_shader_parameter("screen_tex", sub_viewport.get_texture())

	off_mat = StandardMaterial3D.new()
	off_mat.albedo_color = Color.BLACK
	off_mat.roughness = 0.2 

	set_power(true)

func set_power(is_on: bool) -> void:
	if is_on:
			material_override = crt_mat
	else:
		material_override = off_mat