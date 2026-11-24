extends CanvasLayer

enum TransitionType { FADE, LEFT_TO_RIGHT, RIGHT_TO_LEFT, SWIRL, CRT }

const CRT_SHADER := preload("res://shaders/crt_power.gdshader")

# Frames to wait behind the overlay after switching, before revealing the new scene.
const SETTLE_FRAMES := 3

@export_group("Settings")
@export var duration := 0.35
@export var transition_color := Color.BLACK

@export_group("CRT")
@export var crt_off_duration := 0.7
@export var crt_on_duration := 0.55
@export var crt_flicker_duration := 0.3


var _overlay: ColorRect
var _crt_overlay: ColorRect
var _crt_material: ShaderMaterial
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	layer = RenderingServer.CANVAS_LAYER_MAX

	_overlay = ColorRect.new()
	add_child(_overlay)

	_overlay.color = transition_color
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	# Full-screen rect whose shader reads the current screen and collapses it like a CRT.
	_crt_material = ShaderMaterial.new()
	_crt_material.shader = CRT_SHADER
	_crt_overlay = ColorRect.new()
	_crt_overlay.material = _crt_material
	_crt_overlay.visible = false
	_crt_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_crt_overlay)

	get_viewport().size_changed.connect(_resize_overlay)
	_resize_overlay()


func change_scene(scene_path: String, transition_type: TransitionType = TransitionType.CRT) -> void:
	if _busy:
		return

	_busy = true

	# Start loading on a background thread so the fade-in keeps animating while the scene loads.
	var request_err := ResourceLoader.load_threaded_request(scene_path)
	if request_err != OK:
		push_error("Could not start loading scene: " + scene_path)
		_busy = false
		return

	await _transition_in(transition_type)

	var status := ResourceLoader.load_threaded_get_status(scene_path)
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(scene_path)

	var packed_scene := ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if status != ResourceLoader.THREAD_LOAD_LOADED or packed_scene == null:
		push_error("Could not load scene: " + scene_path)
		await _transition_out(transition_type)
		_busy = false
		return

	var err := get_tree().change_scene_to_packed(packed_scene)
	if err != OK:
		push_error("Could not change scene to: " + scene_path)
		await _transition_out(transition_type)
		_busy = false
		return

	# Let the new scene's slow first frames happen behind the overlay
	for i in SETTLE_FRAMES:
		await get_tree().process_frame

	await _transition_out(transition_type)

	_busy = false


func _resize_overlay() -> void:
	_overlay.position = Vector2.ZERO
	_overlay.size = get_viewport().get_visible_rect().size
	_overlay.pivot_offset = _overlay.size * 0.5
	_crt_overlay.position = Vector2.ZERO
	_crt_overlay.size = _overlay.size


func _transition_in(type: TransitionType) -> void:
	_resize_overlay()

	if type == TransitionType.CRT:
		await _crt_power_off()
		return

	_overlay.visible = true

	var tween := create_tween()

	match type:
		TransitionType.FADE:
			_overlay.position = Vector2.ZERO
			_overlay.scale = Vector2.ONE
			_overlay.color = Color(transition_color, 0.0)
			tween.tween_property(_overlay, "color:a", 1.0, duration)

		TransitionType.LEFT_TO_RIGHT:
			_overlay.color = transition_color
			_overlay.position = Vector2(-_overlay.size.x, 0)
			_overlay.scale = Vector2.ONE
			tween.tween_property(_overlay, "position:x", 0.0, duration)

		TransitionType.RIGHT_TO_LEFT:
			_overlay.color = transition_color
			_overlay.position = Vector2(_overlay.size.x, 0)
			_overlay.scale = Vector2.ONE
			tween.tween_property(_overlay, "position:x", 0.0, duration)

		TransitionType.SWIRL:
			_overlay.color = transition_color
			_overlay.position = Vector2.ZERO
			_overlay.scale = Vector2.ZERO
			_overlay.rotation = 0.0
			tween.parallel().tween_property(_overlay, "scale", Vector2.ONE * 1.6, duration)
			tween.parallel().tween_property(_overlay, "rotation", TAU, duration)

	await tween.finished


func _transition_out(type: TransitionType) -> void:
	if type == TransitionType.CRT:
		await _crt_power_on()
		return

	var tween := create_tween()

	match type:
		TransitionType.FADE:
			tween.tween_property(_overlay, "color:a", 0.0, duration)

		TransitionType.LEFT_TO_RIGHT:
			tween.tween_property(_overlay, "position:x", _overlay.size.x, duration)

		TransitionType.RIGHT_TO_LEFT:
			tween.tween_property(_overlay, "position:x", -_overlay.size.x, duration)

		TransitionType.SWIRL:
			tween.parallel().tween_property(_overlay, "scale", Vector2.ZERO, duration)
			tween.parallel().tween_property(_overlay, "rotation", TAU * 2.0, duration)

	await tween.finished
	_overlay.visible = false


func _crt_power_off() -> void:
	_crt_material.set_shader_parameter("progress", 0.0)
	_crt_material.set_shader_parameter("flicker", 0.0)
	_crt_overlay.visible = true

	var tween := create_tween()
	tween.tween_method(_set_crt_progress, 0.0, 1.0, crt_off_duration)
	await tween.finished


func _crt_power_on() -> void:
	_crt_material.set_shader_parameter("flicker", 0.0)
	GameManager.play_sfx(GameManager.Sfx.FADE_IN)

	var tween := create_tween()
	tween.tween_method(_set_crt_progress, 1.0, 0.0, crt_on_duration)
	tween.tween_method(_set_crt_flicker, 1.0, 0.0, crt_flicker_duration)
	await tween.finished

	_crt_overlay.visible = false


func _set_crt_progress(value: float) -> void:
	_crt_material.set_shader_parameter("progress", value)


func _set_crt_flicker(value: float) -> void:
	_crt_material.set_shader_parameter("flicker", value)
