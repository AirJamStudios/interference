extends Control

signal closed

const AUDIO_SAVE_DELAY := 0.25
const RESOLUTION_OPTIONS: Array[Vector2i] = [
	Vector2i(1920, 1080),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1440, 900),
	Vector2i(3840, 2160),
]

@export_group("References")
@export var window_resolution_option_button: OptionButton
@export var vsync_enabled_check_button: CheckBox
@export var sound_fx_volume_slider: HSlider
@export var music_volume_slider: HSlider
@export var back_button: Button

var _audio_save_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_setup_resolution_options()
	_setup_volume_slider(sound_fx_volume_slider)
	_setup_volume_slider(music_volume_slider)
	_sync_controls_with_settings()
	_setup_audio_save_timer()

	window_resolution_option_button.item_selected.connect(_on_window_resolution_item_selected)
	vsync_enabled_check_button.toggled.connect(_on_vsync_enabled_toggled)
	sound_fx_volume_slider.value_changed.connect(_on_sound_fx_volume_changed)
	music_volume_slider.value_changed.connect(_on_music_volume_changed)
	back_button.pressed.connect(_on_back_button_pressed)


func _exit_tree() -> void:
	_save_pending_audio_settings()


func _setup_resolution_options() -> void:
	window_resolution_option_button.clear()

	for resolution in RESOLUTION_OPTIONS:
		window_resolution_option_button.add_item(_format_resolution(resolution))
		var index := window_resolution_option_button.item_count - 1
		window_resolution_option_button.set_item_metadata(index, resolution)


func _setup_volume_slider(slider: HSlider) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01


func _setup_audio_save_timer() -> void:
	_audio_save_timer = Timer.new()
	_audio_save_timer.one_shot = true
	_audio_save_timer.wait_time = AUDIO_SAVE_DELAY
	add_child(_audio_save_timer)
	_audio_save_timer.timeout.connect(_on_audio_save_timer_timeout)


func _sync_controls_with_settings() -> void:
	var resolution_index := _get_resolution_index(OptionsManager.window_resolution)
	if resolution_index == -1:
		window_resolution_option_button.add_item(_format_resolution(OptionsManager.window_resolution))
		resolution_index = window_resolution_option_button.item_count - 1
		window_resolution_option_button.set_item_metadata(resolution_index, OptionsManager.window_resolution)

	window_resolution_option_button.select(resolution_index)
	vsync_enabled_check_button.button_pressed = OptionsManager.vsync_enabled
	sound_fx_volume_slider.value = OptionsManager.sound_fx_volume
	music_volume_slider.value = OptionsManager.music_volume


func _get_resolution_index(resolution: Vector2i) -> int:
	for index in range(window_resolution_option_button.item_count):
		if window_resolution_option_button.get_item_metadata(index) == resolution:
			return index

	return -1


func _format_resolution(resolution: Vector2i) -> String:
	return "%d x %d" % [resolution.x, resolution.y]


func _on_window_resolution_item_selected(index: int) -> void:
	var resolution: Vector2i = window_resolution_option_button.get_item_metadata(index)
	OptionsManager.set_window_resolution(resolution)


func _on_vsync_enabled_toggled(enabled: bool) -> void:
	OptionsManager.set_vsync_enabled(enabled)


func _on_sound_fx_volume_changed(volume: float) -> void:
	OptionsManager.set_sound_fx_volume(volume, false)
	_queue_audio_settings_save()


func _on_music_volume_changed(volume: float) -> void:
	OptionsManager.set_music_volume(volume, false)
	_queue_audio_settings_save()


func _on_back_button_pressed() -> void:
	_save_pending_audio_settings()
	closed.emit()
	queue_free()


func _queue_audio_settings_save() -> void:
	_audio_save_timer.start()


func _save_pending_audio_settings() -> void:
	if _audio_save_timer == null or _audio_save_timer.is_stopped():
		return

	_audio_save_timer.stop()
	OptionsManager.save_settings()


func _on_audio_save_timer_timeout() -> void:
	OptionsManager.save_settings()
