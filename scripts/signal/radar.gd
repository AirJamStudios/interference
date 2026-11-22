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
@export var target_color: Color = Color.html("#FF3B30")

@export_group("Settings")
@export_range(0.1, 1.0) var radius_scale: float = 0.94
@export var rings: int = 4
@export var ticks: int = 8
@export var line_width: float = 2.0
@export var sweep_speed: float = 1.8
@export var sweep_trail: float = 0.65
@export var minutes_per_ring: int = 1
@export var knob_step_threshold: float = 0.2

signal target_changed(index: int)
signal attack_missed

class Blip:
	var start_pos: Vector2
	var start_eta: float = 0
	var pos: Vector2
	var eta: float = 0

	func _init(p_start_pos: Vector2, p_start_eta: float = 0.0) -> void:
		start_pos = p_start_pos
		start_eta = p_start_eta
		pos = p_start_pos
		eta = p_start_eta

# x, y position from -1 to 1,  remaing time until impact in sec
var blips: Array[Blip] = []
var selected_index: int = 0
var _knob_accumulator: float = 0.0

var _angle: float = 0.0

func _ready() -> void:
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_radar)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = sub_viewport.get_texture()
	mat.emission_enabled = true
	mat.emission_texture = mat.albedo_texture
	mat.emission_energy_multiplier = 1.6
	mat.roughness = 0.25
	# Center because of cylindrical mesh
	mat.uv1_scale = Vector3(2.0, 2.0, 1.0)
	mat.uv1_offset = Vector3(-1.0, 0.0, 0.0)
	mesh.material_override = mat

func _process(delta: float) -> void:
	_angle = wrapf(_angle + sweep_speed * delta, 0.0, TAU)
	canvas.queue_redraw()
	_advance_blips(delta)

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
	for i in range(blips.size()):
		var blip: Blip = blips[i]
		var pos: Vector2 = center + blip.pos * r
		var is_selected: bool = (i == selected_index)
		
		var angle_since_scan: float = fposmod(_angle - blip.pos.angle(), TAU)
		var time_since_scan: float = angle_since_scan / TAU
		var brightness: float = clampf(1.0 - time_since_scan * 1.3, 0.15, 1.0)
		var outer_glow := Color(sweep_color, brightness * 0.35)
		var inner_dot := Color(blip_color, brightness)

		canvas.draw_circle(pos, 14.0, outer_glow)
		canvas.draw_circle(pos, 5.5, inner_dot)
		
		# Red targeting thing on the selected blip
		if is_selected:
			var circle_r: float = 20.0
			var tick_len: float = 20.0
			canvas.draw_arc(pos, circle_r, 0.0, TAU, 32, target_color, line_width * 2.2, true)
			canvas.draw_line(pos - Vector2(circle_r + tick_len, 0), pos - Vector2(circle_r - 3.0, 0), target_color, line_width * 2.2, true)
			canvas.draw_line(pos + Vector2(circle_r - 3.0, 0), pos + Vector2(circle_r + tick_len, 0), target_color, line_width * 2.2, true)
			canvas.draw_line(pos - Vector2(0, circle_r + tick_len), pos - Vector2(0, circle_r - 3.0), target_color, line_width * 2.2, true)
			canvas.draw_line(pos + Vector2(0, circle_r - 3.0), pos + Vector2(0, circle_r + tick_len), target_color, line_width * 2.2, true)

			var remaining_sec: float = blip.eta
			if blip.start_eta <= 0.0:
				var ring_width: float = 1.0 / float(rings)
				var speed: float = ring_width / (minutes_per_ring * 60.0)
				remaining_sec = blip.pos.length() / speed

			var mins: int = int(remaining_sec) / 60
			var secs: int = int(remaining_sec) % 60
			var eta_text: String = "ETA %02d:%02d" % [mins, secs]

			var font: Font = ThemeDB.fallback_font
			var font_size: int = 25
			var text_size: Vector2 = font.get_string_size(eta_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var offset: float = circle_r + 8.0

			# Always place the label to the cnter to see it properly
			var on_right: bool = pos.x >= center.x
			var on_bottom: bool = pos.y >= center.y
			var text_x: float = pos.x - offset - text_size.x if on_right else pos.x + offset
			var text_y: float = pos.y - offset if on_bottom else pos.y + offset + font.get_ascent(font_size)
			canvas.draw_string(font, Vector2(text_x, text_y), eta_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, target_color)


func add_blip(angle_rad: float, start_distance: float = 1.0, start_eta: float = 0) -> void:
	var pos: Vector2 = Vector2.from_angle(angle_rad) * clampf(start_distance, 0.0, 1.0)
	var new_blip: Blip = Blip.new(pos, start_eta)
	blips.append(new_blip)

func remove_blip_at(index: int) -> void:
	if index < 0 or index >= blips.size():
		return
	blips.remove_at(index)
	attack_missed.emit(index)
	if blips.is_empty():
		selected_index = 0
	else:
		selected_index = clampi(selected_index, 0, blips.size() - 1)
		target_changed.emit(selected_index)

func _advance_blips(dt: float) -> void:
	var ring_width: float = 1.0 / float(rings)
	var step: float = dt * ring_width / (minutes_per_ring * 60.0)
	
	var reached_blips: Array[Blip] = []
	for i in range(blips.size()):
		if (blips[i].start_eta == 0):
			var dist: float = blips[i].pos.length()
			if dist <= step:
				reached_blips.append(blips[i])
			else:
				blips[i].pos = blips[i].pos.normalized() * (dist - step)
		else:
			blips[i].eta -= dt
			if blips[i].eta <= 0.0:
				blips[i].eta = 0.0
				reached_blips.append(blips[i])
			else:
				blips[i].pos = blips[i].start_pos * (blips[i].eta / blips[i].start_eta)

	
	for reached in reached_blips:
		var idx: int = blips.find(reached)
		if idx != -1:
			remove_blip_at(idx)

func _on_knob_value_changed(value: float) -> void:
	if blips.is_empty():
		_knob_accumulator = 0.0
		return
		
	_knob_accumulator += value
	
	if absf(_knob_accumulator) >= knob_step_threshold:
		var steps: int = int(_knob_accumulator / knob_step_threshold)
		_knob_accumulator = fmod(_knob_accumulator, knob_step_threshold)
		
		selected_index = posmod(selected_index + steps, blips.size())
		target_changed.emit(selected_index)