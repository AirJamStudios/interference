class_name SceneFx
extends Node

@export_group("References")
@export var camera : Camera3D
@export var light  : OmniLight3D
@export var radar : Radar

@export_group("Camera Shake")
@export var shake_duration  : float = 0.4
@export var shake_strength  : float = 0.05
@export var shake_roll_deg  : float = 1.5
@export var shake_frequency : float = 25.0

@export_group("Light Flicker")
@export var flicker_duration  : float = 0.6
@export var flicker_min_ratio : float = 0.1
@export var flicker_step_min  : float = 0.03
@export var flicker_step_max  : float = 0.09

@export_group("Hit Flicker")
@export var hit_flicker_lights : Array[Light3D] = []
@export var hit_flicker_meshes : Array[MeshInstance3D] = []
@export var hit_flicker_duration : float = 0.8

var _noise := FastNoiseLite.new()
var _shake_time_left : float = 0.0
var _shake_t : float = 0.0
var _cam_base_roll : float = 0.0

var _light_base_energy : float = 0.0
var _flicker_tween : Tween

var _hit_tween : Tween
var _hit_light_base : Array[float] = []
var _hit_mats : Array[BaseMaterial3D] = []
var _hit_mat_base : Array[float] = []

var _prev_blips : Array = []
var _prev_at_center : Dictionary = {}


func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0
	_noise.seed = randi()
	if camera:
		_cam_base_roll = camera.rotation.z
	if light:
		_light_base_energy = light.light_energy

	for l in hit_flicker_lights:
		_hit_light_base.append(l.light_energy)
	for m in hit_flicker_meshes:
		_setup_emissive_mesh(m)


func _process(delta: float) -> void:
	_update_shake(delta)
	_watch_radar_hits(delta)


func _update_shake(delta: float) -> void:
	if not camera or _shake_time_left <= 0.0:
		return

	_shake_time_left -= delta
	if _shake_time_left <= 0.0:
		_reset_camera()
		return

	_shake_t += delta * shake_frequency
	var k := _shake_time_left / shake_duration
	k *= k

	camera.h_offset = _noise.get_noise_2d(_shake_t, 0.0) * shake_strength * k
	camera.v_offset = _noise.get_noise_2d(0.0, _shake_t) * shake_strength * k
	camera.rotation.z = _cam_base_roll + deg_to_rad(shake_roll_deg) * _noise.get_noise_2d(_shake_t, _shake_t) * k


func camera_shake() -> void:
	if not camera:
		push_warning("SceneFx: camera_shake called without a camera assigned.")
		return

	_shake_time_left = shake_duration


func light_flicker() -> void:
	if not light:
		push_warning("SceneFx: light_flicker called without a light assigned.")
		return

	# If already flickering, stop and restart from the base energy.
	if _flicker_tween and _flicker_tween.is_valid():
		_flicker_tween.kill()
	light.light_energy = _light_base_energy

	_flicker_tween = create_tween()
	var elapsed := 0.0
	while elapsed < flicker_duration:
		var step := randf_range(flicker_step_min, flicker_step_max)
		var target := _light_base_energy * randf_range(flicker_min_ratio, 1.0)
		_flicker_tween.tween_property(light, "light_energy", target, step)
		elapsed += step
	_flicker_tween.tween_property(light, "light_energy", _light_base_energy, flicker_step_max)


func hit_flicker() -> void:
	if hit_flicker_lights.is_empty() and _hit_mats.is_empty():
		return

	if _hit_tween and _hit_tween.is_valid():
		_hit_tween.kill()
	_set_hit_ratio(1.0)

	_hit_tween = create_tween()
	var elapsed := 0.0
	while elapsed < hit_flicker_duration:
		var step := randf_range(flicker_step_min, flicker_step_max)
		var target := 0.0 if randf() < 0.25 else randf_range(flicker_min_ratio, 1.0)
		_hit_tween.tween_method(_set_hit_ratio, _current_hit_ratio, target, step)
		_current_hit_ratio = target
		elapsed += step
	_hit_tween.tween_method(_set_hit_ratio, _current_hit_ratio, 1.0, flicker_step_max)
	_current_hit_ratio = 1.0


var _current_hit_ratio : float = 1.0

func _set_hit_ratio(ratio: float) -> void:
	for i in hit_flicker_lights.size():
		hit_flicker_lights[i].light_energy = _hit_light_base[i] * ratio
	for i in _hit_mats.size():
		_hit_mats[i].emission_energy_multiplier = _hit_mat_base[i] * ratio


func _setup_emissive_mesh(m: MeshInstance3D) -> void:
	if not m or not m.mesh:
		return
	for s in m.mesh.get_surface_count():
		var mat := m.get_active_material(s) as BaseMaterial3D
		if mat and mat.emission_enabled:
			var dup := mat.duplicate() as BaseMaterial3D
			m.set_surface_override_material(s, dup)
			_hit_mats.append(dup)
			_hit_mat_base.append(dup.emission_energy_multiplier)


func _watch_radar_hits(delta: float) -> void:
	if not radar:
		return

	var current : Array = radar.blips
	for b in _prev_blips:
		if not current.has(b) and _prev_at_center.get(b, false):
			hit_flicker()
			break

	var step : float = delta * (1.0 / float(radar.rings)) / (radar.minutes_per_ring * 60.0) * 3.0
	_prev_at_center.clear()
	for b in current:
		var at_center : bool
		if b.start_eta == 0:
			at_center = b.pos.length() <= step
		else:
			at_center = b.eta <= delta * 3.0
		_prev_at_center[b] = at_center
	_prev_blips = current.duplicate()


func _reset_camera() -> void:
	camera.h_offset = 0.0
	camera.v_offset = 0.0
	camera.rotation.z = _cam_base_roll
