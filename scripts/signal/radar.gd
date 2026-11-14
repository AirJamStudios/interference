class_name Radar
extends Node3D

@export_group("References")
@export var sub_viewport: SubViewport
@export var mesh: MeshInstance3D
@export var canvas: Control

@export_group("Colors")
@export var bg_color: Color = Color.html("#092E10")
@export var grid_color: Color = Color.html("#228B34")
@export var axis_color: Color = Color.html("#39D353")
@export var sweep_color: Color = Color.html("#5CFF75")
@export var blip_color: Color = Color.html("#D4FFDC")

@export_group("Settings")
@export_range(0.1, 1.0) var radius_scale: float = 0.94
@export var rings: int = 4
@export var ticks: int = 8
@export var line_width: float = 2.0
@export var sweep_speed: float = 1.8
@export var sweep_trail: float = 0.65

# x, y position from -1 to 1
@export var blips: Array[Vector2] = [Vector2(0.0, -0.52), Vector2(0.32, -0.25), Vector2(-0.42, 0.45)]

var _angle: float = 0.0

func _ready() -> void:
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_radar)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = sub_viewport.get_texture()
	mat.emission_enabled = true
	mat.emission_texture = mat.albedo_texture
	mat.roughness = 0.25
	# Center because of cylindrical mesh
	mat.uv1_scale = Vector3(2.0, 2.0, 1.0)
	mat.uv1_offset = Vector3(-1.0, 0.0, 0.0)
	mesh.material_override = mat

func _process(delta: float) -> void:
	_angle = wrapf(_angle + sweep_speed * delta, 0.0, TAU)
	canvas.queue_redraw()

func _draw_radar() -> void:
	var center: Vector2 = Vector2(sub_viewport.size) * 0.5
	var r: float = center.x * radius_scale
	
	# Background
	canvas.draw_circle(center, r, bg_color)
	# Rings
	for i in range(1, rings + 1):
		# Outer more intense color
		var ring_color: Color = axis_color if (i == rings) else grid_color
		var ring_thickness_factor: float = 1.4 if (i == rings) else 1.0
		canvas.draw_arc(center, r * i / rings, 0.0, 2*PI, 96, ring_color, line_width * ring_thickness_factor, true)
		
	# Axis lines
	canvas.draw_line(center - Vector2(r, 0), center + Vector2(r, 0), axis_color, line_width * 1.3, true)
	canvas.draw_line(center - Vector2(0, r), center + Vector2(0, r), axis_color, line_width * 1.3, true)
	
	# Trailing sweep
	var total_slices := 20
	var slice_angle := sweep_trail / total_slices
	for i in range(total_slices):
		# Brightness 0 and the back and 1 at the front (squared falloff)
		var brightness: float = float(i + 1) / total_slices
		var trail_color := Color(sweep_color, brightness * brightness * 0.5)
		var start_angle: float = _angle - sweep_trail + (i * slice_angle)
		var end_angle: float = start_angle + slice_angle
		# Triangle slice
		canvas.draw_colored_polygon([center, center + Vector2.from_angle(start_angle) * r, center + Vector2.from_angle(end_angle) * r], trail_color)
		
	# Draw the bright leading sweep line at the front of the wedge
	var line_end := center + Vector2.from_angle(_angle) * r
	canvas.draw_line(center, line_end, sweep_color, line_width * 2.2, true)
	
	# Enemy blips
	for blip in blips:
		var pos: Vector2 = center + blip * r
		var angle_since_scan: float = fposmod(_angle - blip.angle(), TAU)
		var time_since_scan: float = angle_since_scan / TAU
		var brightness: float = clampf(1.0 - time_since_scan * 1.3, 0.15, 1.0)
		var outer_glow := Color(sweep_color, brightness * 0.35)
		var inner_dot := Color(blip_color, brightness)

		canvas.draw_circle(pos, 14.0, outer_glow)
		canvas.draw_circle(pos, 5.5, inner_dot)
