extends Node

const SETTINGS_PATH := "user://settings.cfg"
const VIDEO_SECTION := "video"
const AUDIO_SECTION := "audio"

@export_group("Defaults")
@export var default_window_resolution := Vector2i(1280, 720)
@export var default_vsync_enabled := true
@export_range(0.0, 1.0, 0.01) var default_sound_fx_volume := 1.0
@export_range(0.0, 1.0, 0.01) var default_music_volume := 1.0

@export_group("Audio Buses")
@export var sound_fx_bus_name := "SFX"
@export var music_bus_name := "Music"

var window_resolution := default_window_resolution
var vsync_enabled := default_vsync_enabled
var sound_fx_volume := default_sound_fx_volume
var music_volume := default_music_volume


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)

	if err != OK:
		reset_to_defaults()
		save_settings()
		return

	window_resolution = _get_vector2i(config, VIDEO_SECTION, "window_resolution", default_window_resolution)
	vsync_enabled = bool(config.get_value(VIDEO_SECTION, "vsync_enabled", default_vsync_enabled))
	sound_fx_volume = _get_normalized_value(config, AUDIO_SECTION, "sound_fx_volume", default_sound_fx_volume)
	music_volume = _get_normalized_value(config, AUDIO_SECTION, "music_volume", default_music_volume)

	apply_settings()


func save_settings() -> int:
	var config := ConfigFile.new()
	config.set_value(VIDEO_SECTION, "window_resolution", window_resolution)
	config.set_value(VIDEO_SECTION, "vsync_enabled", vsync_enabled)
	config.set_value(AUDIO_SECTION, "sound_fx_volume", sound_fx_volume)
	config.set_value(AUDIO_SECTION, "music_volume", music_volume)

	return config.save(SETTINGS_PATH)


func save_current_settings() -> int:
	read_current_settings()
	return save_settings()


func read_current_settings() -> void:
	window_resolution = DisplayServer.window_get_size()
	vsync_enabled = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	sound_fx_volume = get_bus_volume_normalized(sound_fx_bus_name, sound_fx_volume)
	music_volume = get_bus_volume_normalized(music_bus_name, music_volume)


func apply_settings() -> void:
	DisplayServer.window_set_size(window_resolution)
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)
	set_bus_volume_normalized(sound_fx_bus_name, sound_fx_volume)
	set_bus_volume_normalized(music_bus_name, music_volume)


func reset_to_defaults(save_immediately := false) -> void:
	window_resolution = default_window_resolution
	vsync_enabled = default_vsync_enabled
	sound_fx_volume = default_sound_fx_volume
	music_volume = default_music_volume

	apply_settings()

	if save_immediately:
		save_settings()


func set_window_resolution(resolution: Vector2i, save_immediately := true) -> void:
	window_resolution = resolution
	DisplayServer.window_set_size(window_resolution)

	if save_immediately:
		save_settings()


func set_vsync_enabled(enabled: bool, save_immediately := true) -> void:
	vsync_enabled = enabled
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)

	if save_immediately:
		save_settings()


func set_sound_fx_volume(volume: float, save_immediately := true) -> void:
	sound_fx_volume = clampf(volume, 0.0, 1.0)
	set_bus_volume_normalized(sound_fx_bus_name, sound_fx_volume)

	if save_immediately:
		save_settings()


func set_music_volume(volume: float, save_immediately := true) -> void:
	music_volume = clampf(volume, 0.0, 1.0)
	set_bus_volume_normalized(music_bus_name, music_volume)

	if save_immediately:
		save_settings()


func set_bus_volume_normalized(bus_name: String, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return

	var normalized_volume := clampf(volume, 0.0, 1.0)
	if normalized_volume <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, -80.0)
		return

	AudioServer.set_bus_mute(bus_index, false)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(normalized_volume))


func get_bus_volume_normalized(bus_name: String, fallback: float = 1.0) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return clampf(fallback, 0.0, 1.0)

	if AudioServer.is_bus_mute(bus_index):
		return 0.0

	return clampf(db_to_linear(AudioServer.get_bus_volume_db(bus_index)), 0.0, 1.0)


func _get_vector2i(config: ConfigFile, section: String, key: String, fallback: Vector2i) -> Vector2i:
	var value = config.get_value(section, key, fallback)

	if value is Vector2i:
		return value

	if value is Vector2:
		return Vector2i(value)

	return fallback


func _get_normalized_value(config: ConfigFile, section: String, key: String, fallback: float) -> float:
	return clampf(float(config.get_value(section, key, fallback)), 0.0, 1.0)
