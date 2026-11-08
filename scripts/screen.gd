extends MeshInstance3D

@export var sub_viewport: SubViewport
const CRT_SHADER := preload("res://shaders/crt.gdshader")

func _ready() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = CRT_SHADER
	mat.set_shader_parameter("screen_tex", sub_viewport.get_texture())
	material_override = mat
