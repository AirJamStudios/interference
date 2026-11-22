class_name LevelManager
extends Node

@export_group("References")
@export var dialogue_manager : DialogueManager
@export var oscilloscope : Oscilloscope
@export var scene_fx : SceneFx
@export var radar : Radar

@export_group("UI and Cameras")
@export var overview_camera: Camera3D
@export var desk_camera: Camera3D
@export var level_select_ui: Control

@export_group("Settings")
@export var max_hits_allowed: int = 3
@export var next_level_delay : float = 1.5
@export var camera_transition_time: float = 0.8

class Attack:
	var angle_deg : float
	var start_distance : float
	var start_eta : float
	var enemy_wave : CompositeWave

	func _init(p_angle_deg: float, waves: Array, p_distance: float = 1.0, p_start_eta: float = 0.0, drift: CompositeWave.DriftMode = CompositeWave.DriftMode.NONE) -> void:
		angle_deg = p_angle_deg
		start_distance = p_distance
		start_eta = p_start_eta
		enemy_wave = CompositeWave.new()
		for wave: SingleWave in waves:
			enemy_wave.add_wave(wave)
		
		if drift!=CompositeWave.DriftMode.NONE:
			enemy_wave.set_drift(drift)

class Level:
	var dialogue_lines : Array[Dictionary] = []
	var attacks : Array[Attack] = []

	func _init(lines: Array, p_attacks: Array[Attack]) -> void:
		dialogue_lines.assign(lines)
		attacks = p_attacks.duplicate()
		# Make sure they are reversed ordered for dial to make sense
		attacks.sort_custom(func(a: Attack, b: Attack) -> bool:
			return fposmod(a.angle_deg, 360.0) > fposmod(b.angle_deg, 360.0)
		)

# State variables for tracking level progress
var level_list : Array[Level] = []
var active_attacks : Array[Attack] = []

var _current_level_id : int = 0
var _hits_taken: int = 0
var _elapsed_time: float = 0.0
var _is_playing: bool = false
var _is_transitioning: bool = false

func _ready() -> void:
	_build_levels()

	oscilloscope.attack_completed.connect(_on_attack_completed)
	radar.attack_missed.connect(_on_attack_missed)
	radar.target_changed.connect(_on_target_changed)
	level_select_ui.level_chosen.connect(start_level)
	level_select_ui.back_pressed.connect(_on_back_to_menu)
	
	open_level_select()

func _process(delta: float) -> void:
	if _is_playing and not _is_transitioning:
		_elapsed_time += delta

func open_level_select() -> void:
	_is_playing = false
	active_attacks.clear()
	radar.blips.clear()
	
	overview_camera.make_current()
	level_select_ui.refresh_cards(level_list.size())
	level_select_ui.visible = true

func start_level(index: int) -> void:
	_current_level_id = index
	level_select_ui.visible = false
	
	await _tween_camera(overview_camera, desk_camera, camera_transition_time)
	_load_level(_current_level_id)

func _load_level(index: int) -> void:
	var level : Level = level_list[index]
	dialogue_manager.start_dialogue(level.dialogue_lines)

	active_attacks = level.attacks.duplicate()
	_elapsed_time = 0.0
	_is_playing = true
	_hits_taken = 0

	#Spawn blips
	radar.blips.clear()
	for attack: Attack in active_attacks:
		radar.add_blip(deg_to_rad(attack.angle_deg), attack.start_distance, attack.start_eta)

	if not active_attacks.is_empty():
		oscilloscope.set_enemy_wave(active_attacks[radar.selected_index].enemy_wave)


#! COMBAT EVENTS  - attack compelted or missed
func _on_attack_completed() -> void:
	if _is_transitioning  or not _is_playing:
		return

	# Attack jammed successfully
	var target_idx: int = radar.selected_index
	active_attacks.remove_at(target_idx)
	radar.remove_blip_at(target_idx)

	# Check if any attacks remain
	if active_attacks.is_empty():
		_complete_level()

func _on_attack_missed(hit_idx: int) -> void:
	if _is_transitioning or not _is_playing:
		return

	_hits_taken += 1
	_remove_attack_at(hit_idx)

	if _hits_taken >= max_hits_allowed:
		_fail_level()
	elif active_attacks.is_empty():
		_complete_level()
	else:
		_sync_oscilloscope_to_radar()

#! LEVEL EVENTS  - level completed or failed
func _complete_level() -> void:
	_is_transitioning  = true
	_is_playing = false
	
	# hits to stars
	var stars: int = clampi(3 - _hits_taken, 1, 3)
	# TODO: save data here in storage
	print("Level ", _current_level_id + 1, " passed! Stars: ", stars, " | Time: %.1fs" % _elapsed_time)

	await get_tree().create_timer(next_level_delay).timeout

	_current_level_id += 1
	if _current_level_id >= level_list.size():
		_on_game_completed()
	else:
		_load_level(_current_level_id)
	_is_transitioning  = false

func _fail_level() -> void:
	_is_transitioning = true
	_is_playing = false
	
	await get_tree().create_timer(next_level_delay).timeout
	await _tween_camera(desk_camera, overview_camera, camera_transition_time)
	
	open_level_select()
	_is_transitioning = false


func _on_target_changed(index: int) -> void:
	if index >= 0 and index < active_attacks.size():
		oscilloscope.set_enemy_wave(active_attacks[index].enemy_wave)

# Whole game done
func _on_game_completed() -> void:
	await _tween_camera(desk_camera, overview_camera, camera_transition_time)
	open_level_select()

func _on_back_to_menu() -> void:
	#TODO connect still
	print("Back button pressed")

func _remove_attack_at(index: int) -> void:
	if index >= 0 and index < active_attacks.size():
		active_attacks.remove_at(index)
		radar.remove_blip_at(index)

func _sync_oscilloscope_to_radar() -> void:
	if not active_attacks.is_empty():
		oscilloscope.set_enemy_wave(active_attacks[radar.selected_index].enemy_wave)

func _tween_camera(from_cam: Camera3D, to_cam: Camera3D, duration: float) -> void:
	var temp_cam := Camera3D.new()
	add_child(temp_cam)
	temp_cam.global_transform = from_cam.global_transform
	temp_cam.fov = from_cam.fov
	temp_cam.make_current()
	
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(temp_cam, "global_transform", to_cam.global_transform, duration)
	tween.tween_property(temp_cam, "fov", to_cam.fov, duration)
	await tween.finished
	
	to_cam.make_current()
	temp_cam.queue_free()

func _build_levels() -> void:
	level_list = [
		#! TUTORIAL LEVEL: TEACHES KNOBS
		Level.new(
			[
				{"speaker": "Soldier", "text": "OH MY GOD, WE'RE UNDER ATTACK!"},
				{"speaker": "Soldier", "text": "Look at the rada, contacts are popping up everywhere! They're closing in fast!"},
				{"speaker": "Soldier", "text": "[SYSTEM ALERT: Automated Electronic Warfare offline. Manual Antenna & Radar arrays operational.]"},
				{"speaker": "Soldier", "text": "Our auto-jammers are fried! We have to manually match their signal frequencies to cancel them out!"},
				{"speaker": "Soldier", "text": "Recon drones approaching from the South! Jam them before they lock our coordinates!"},
				{"speaker": "Soldier", "text": "Twist the FREQUENCY, AMPLITUDE, and PHASE knobs until the two waves match up! Just keep turning them till it works!"}
			],
			[
				Attack.new(90.0, [SingleWave.new(0.2, 0.4, 0.0)], 1.0, 90),
				Attack.new(95.0, [SingleWave.new(0.6, 0.4, 0.0)], 1.0, 90),
				Attack.new(85.0, [SingleWave.new(1.0, 0.4, 0.0)], 1.0, 90),

				Attack.new(120.0, [SingleWave.new(1.0, 0.2, 0.0)], 1.0, 120),
				Attack.new(130.0, [SingleWave.new(1.0, 0.8, 0.0)], 1.0, 120),
				Attack.new(125.0, [SingleWave.new(1.0, 0.05, 0.0)], 1.0, 120),

				Attack.new(40.0, [SingleWave.new(1.0, 0.05, 0.5)], 1.0, 150),
				Attack.new(50.0, [SingleWave.new(1.0, 0.05, 0.2)], 1.0, 150),
				Attack.new(45.0, [SingleWave.new(1.0, 0.05, 0.8)], 1.0, 150),

			]
		),
		#! TUTORIAL LEVEL: TEACHES TIME CHANGE
		Level.new(
			[
				{"speaker": "Soldier", "text": "Wow! Their signal is shifting on its own!"},
				{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
			],
			[
				#TODO: make the time shift mode more configurable form here right now all default
				Attack.new(130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 0.0, CompositeWave.DriftMode.AMPLITUDE),			
			]
		),
		#! TUTORIAL LEVEL: TEACHES TWO WAVES
		Level.new(
			[
				{"speaker": "Soldier", "text": "YES! It's jammed! Wait, a heavy bomber's on the radar, and its signal is double layered!"},
				{"speaker": "Soldier", "text": "One wave won't be enough!"},
			],
			[
				Attack.new(20.0, [SingleWave.new(1.0, 0.05, 0.0), SingleWave.new(0.25, 0.9, 0.0)], 1.0),
			]
		),
		
	]

#Debug only skip attacks
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S:
			if not active_attacks.is_empty() and not _is_transitioning:
				_on_attack_completed()

func get_level_info(index: int) -> Dictionary:
	#TODO use local saved data
	return {
		"unlocked": index == 0,
		"stars": 2,
		"best_time": 35.2
	}
