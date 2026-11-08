class_name SceneFx
extends Node

@export_group("References")
@export var camera : Camera3D
@export var light  : OmniLight3D

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

var _noise := FastNoiseLite.new()
var _shake_time_left : float = 0.0
var _shake_t : float = 0.0
var _cam_base_roll : float = 0.0

var _light_base_energy : float = 0.0
var _flicker_tween : Tween


func _ready() -> void:
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0
	_noise.seed = randi()
	if camera:
		_cam_base_roll = camera.rotation.z
	if light:
		_light_base_energy = light.light_energy
	set_process(false)

func _process(delta: float) -> void:
	if not camera:
		set_process(false)
		return

	_shake_time_left -= delta
	if _shake_time_left <= 0.0:
		_reset_camera()
		set_process(false)
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
	set_process(true)


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


func _reset_camera() -> void:
	camera.h_offset = 0.0
	camera.v_offset = 0.0
	camera.rotation.z = _cam_base_roll
