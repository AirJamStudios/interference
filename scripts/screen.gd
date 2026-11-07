extends MeshInstance3D

@export var sub_viewport: SubViewport

func _ready() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = sub_viewport.get_texture()
	material_override = mat