class_name CustomProgressBar
extends Node3D

@export_group("References")
@export var body_mesh : MeshInstance3D

@export_group("Settings")
@export var left_color: Color = Color.RED
@export var right_color: Color = Color.GREEN
@export var off_color: Color = Color(0.12, 0.12, 0.12)
@export var leds_amount: int = 16
@export var bulb_radius: float = 0.02
@export var emission_strength: float = 2.5 #to make it glowy

var led_materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	# Mesh for the leds
	var bulb_mesh = SphereMesh.new()
	bulb_mesh.radius = bulb_radius
	bulb_mesh.height = bulb_radius * 2.0
	bulb_mesh.radial_segments = 16
	bulb_mesh.rings = 8
	
	# Place the leds along the bar
	var bar_width: float = body_mesh.mesh.size.z
	var spacing: float = bar_width / float(leds_amount)
	var start_z: float = bar_width / 2.0 - (spacing / 2.0)
	
	for i in range(leds_amount):
		var led = MeshInstance3D.new()
		led.mesh = bulb_mesh
		led.position = Vector3(0.0, 0.0, start_z - (i * spacing))
		
		var material = StandardMaterial3D.new()
		material.albedo_color = off_color
		material.roughness = 0.3
		led.material_override = material
		
		add_child(led)
		# Save material for colo change
		led_materials.append(material)


# Input score between 0-100
func set_score(score: float) -> void:
	var active_leds: int = roundi(  led_materials.size() * score / 100.0)
	
	for i in range(led_materials.size()):
		var mat: StandardMaterial3D = led_materials[i]
		if i < active_leds:
			var pos_ratio: float = float(i) / max(1, led_materials.size() - 1)
			var active_color: Color = left_color.lerp(right_color, pos_ratio)
			
			mat.albedo_color = active_color
			mat.emission_enabled = true
			mat.emission = active_color
			mat.emission_energy_multiplier = emission_strength
		else:
			mat.albedo_color = off_color
			mat.emission_enabled = false
