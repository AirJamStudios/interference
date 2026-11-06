extends CanvasLayer

enum TransitionType { FADE, LEFT_TO_RIGHT, RIGHT_TO_LEFT, SWIRL }

@export_group("Settings")
@export var duration := 0.35
@export var transition_color := Color.BLACK


var _overlay: ColorRect
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	layer = RenderingServer.CANVAS_LAYER_MAX

	_overlay = ColorRect.new()
	add_child(_overlay)

	_overlay.color = transition_color
	_overlay.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	get_viewport().size_changed.connect(_resize_overlay)
	_resize_overlay()


func change_scene(scene_path: String, transition_type: TransitionType = TransitionType.FADE) -> void:
	if _busy:
		return

	_busy = true

	await _transition_in(transition_type)

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("Could not change scene to: " + scene_path)
		await _transition_out(transition_type)
		_busy = false
		return

	await get_tree().process_frame
	await _transition_out(transition_type)

	_busy = false


func _resize_overlay() -> void:
	_overlay.position = Vector2.ZERO
	_overlay.size = get_viewport().get_visible_rect().size
	_overlay.pivot_offset = _overlay.size * 0.5


func _transition_in(type: TransitionType) -> void:
	_resize_overlay()
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