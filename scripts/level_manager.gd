class_name LevelManager
extends Node

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"

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
@export var next_level_delay : float = 1.0
@export var camera_transition_time: float = 0.8

@export_group("Lights")
@export var wall_light_1: OmniLight3D
@export var wall_light_2 : OmniLight3D
@export var ceiling_light: OmniLight3D
@export var alarm: Alarm

enum LevelOutcome {
	NONE,
	PASS,
	FAIL
}
var _pending_outcome: LevelOutcome = LevelOutcome.NONE
enum TriggerType {
	LEVEL_START,
	TIMER_COMPLETED,
	ATTACK_DEFEATED,
	ATTACK_REACHED,
	DIALOGUE_COMPLETED,
	CNT_ATTACK_REACHED,		# check against total attacks that werend defeated and hit in current level
	CNT_ATTACK_DEFEATED,	# check against total defeated attacks in current level
	CNT_ATTACK_GONE,		# check against sum cnt CNT_ATTACK_REACHED and CNT_ATTACK_DEFEATED
	CNT_ATTACK_INBOUND		# check against attacks that are currently inbound
}

enum ActionType {
	DIALOGUE,
	SPAWN_ATTACK,
	START_TIMER,
	CANCEL_TIMER,
	DISABLE_EVENT,
	FAIL_LEVEL, 	# override to fails level
	PASS_LEVEL, 	# override to pass level, 1-3 stars
}

class Attack:
	var id : String
	var angle_deg : float
	var start_distance : float
	var start_eta : float
	var enemy_wave : CompositeWave

	func _init(p_id: String, p_angle_deg: float, waves: Array, p_distance: float = 1.0, p_start_eta: float = 0.0, drift: CompositeWave.DriftMode = CompositeWave.DriftMode.NONE) -> void:
		id = p_id
		angle_deg = p_angle_deg
		start_distance = p_distance
		start_eta = p_start_eta
		enemy_wave = CompositeWave.new()
		for wave: SingleWave in waves:
			enemy_wave.add_wave(wave)
		
		if drift != CompositeWave.DriftMode.NONE:
			enemy_wave.set_drift(drift)

class LevelAction:
	var type : ActionType
	var data : Variant

	func _init(p_type: ActionType, p_data: Variant) -> void:
		type = p_type
		data = p_data

	static func dialogue(lines: Array, id: String = "") -> LevelAction:
		return LevelAction.new(ActionType.DIALOGUE, {"id": id, "lines": lines})

	static func spawn(attack: Attack) -> LevelAction:
		return LevelAction.new(ActionType.SPAWN_ATTACK, attack)

	static func start_timer(id: String, duration: float) -> LevelAction:
		return LevelAction.new(ActionType.START_TIMER, {"id": id, "duration": duration})

	static func cancel_timer(id: String) -> LevelAction:
		return LevelAction.new(ActionType.CANCEL_TIMER, id)

	static func disable_event(event_id: String) -> LevelAction:
		return LevelAction.new(ActionType.DISABLE_EVENT, event_id)
	
	static func pass_level() -> LevelAction:
		return LevelAction.new(ActionType.PASS_LEVEL, null)

	static func fail_level() -> LevelAction:
		return LevelAction.new(ActionType.FAIL_LEVEL, null)

class LevelEvent:
	var id : String
	var trigger : TriggerType
	var trigger_param : Variant
	var actions : Array[LevelAction] = []
	var one_shot : bool = true
	var _fired : bool = false

	func _init(p_trig: TriggerType, p_param: Variant, p_actions: Array, p_one_shot: bool = true, p_id: String = "") -> void:
		trigger = p_trig
		trigger_param = p_param
		actions.assign(p_actions)
		one_shot = p_one_shot
		id = p_id

class Level:
	var events : Array[LevelEvent] = []
	
	func _init(p_events: Array) -> void:
		events.assign(p_events)

# State variables for tracking level progress
var level_list : Array[Level] = []
var active_attacks : Array[Attack] = []
var current_level_events : Array[LevelEvent] = []
var active_timers : Dictionary = {} # { timer_id (String): remaining_time (float) }

var _current_level_id : int = 0
var _hits_taken: int = 0
var _hits_saved: int = 0
var _elapsed_time: float = 0.0
var _is_transitioning: bool = false

var is_simulation_paused: bool = false # paused or unpaused
var is_playing: bool = false #in level manager or in level

func _ready() -> void:
	_build_levels()

	oscilloscope.attack_completed.connect(_on_attack_completed)
	radar.attack_missed.connect(_on_attack_missed)
	radar.target_changed.connect(_on_target_changed)
	dialogue_manager.dialogue_completed.connect(_on_dialogue_completed)
	level_select_ui.level_chosen.connect(start_level)
	level_select_ui.back_pressed.connect(_on_back_to_menu)
	
	# Give the level manager time to initialze cards ( in the ready function)
	open_level_select.call_deferred()

func _process(delta: float) -> void:
	if not is_playing or _is_transitioning or is_simulation_paused:
		return

	_elapsed_time += delta

	if not active_timers.is_empty():
		var expired: Array[String] = []
		for timer_id: String in active_timers.keys():
			active_timers[timer_id] -= delta
			if active_timers[timer_id] <= 0.0:
				expired.append(timer_id)

		for timer_id: String in expired:
			active_timers.erase(timer_id)
			_fire_trigger(TriggerType.TIMER_COMPLETED, timer_id)
			_evaluate_level_state()

func open_level_select() -> void:
	dialogue_manager.hide()
	GameManager.set_game_state_active(false)
	is_playing = false
	active_attacks.clear()
	radar.blips.clear()
	overview_camera.make_current()
	level_select_ui.refresh_cards(level_list.size())
	level_select_ui.visible = true

func start_level(index: int) -> void:
	_pending_outcome = LevelOutcome.NONE
	_current_level_id = index
	level_select_ui.visible = false

	# clear all waves before level
	oscilloscope.clear_waves()

	await _tween_camera(overview_camera, desk_camera, camera_transition_time)
	_load_level(_current_level_id)
	GameManager.set_game_state_active(true)

func _load_level(index: int) -> void:
	
	var level : Level = level_list[index]
	_elapsed_time = 0.0
	is_playing = true
	_hits_taken = 0
	_hits_saved = 0

	active_timers.clear()
	active_attacks.clear()
	current_level_events.clear()
	radar.blips.clear()
	
	for ev: LevelEvent in level.events:
		var new_event := LevelEvent.new(
			ev.trigger,
			ev.trigger_param,
			ev.actions,
			ev.one_shot,
			ev.id
		)
		current_level_events.append(new_event)

	for ev: LevelEvent in current_level_events:
		ev._fired = false

	_fire_trigger(TriggerType.LEVEL_START)

#! COMBAT EVENTS  - attack compelted or missed
func _on_attack_completed() -> void:
	if _is_transitioning or not is_playing or active_attacks.is_empty():
		return

	var target_idx: int = radar.selected_index

	if target_idx < 0 or target_idx >= active_attacks.size():
		push_warning("Invalid radar selection: %d" % target_idx)
		return

	var defeated_attack: Attack = active_attacks[target_idx]

	active_attacks.remove_at(target_idx)
	radar.remove_blip_at(target_idx)
	_hits_saved += 1

	_fire_trigger(TriggerType.ATTACK_DEFEATED, defeated_attack.id)
	_fire_trigger(TriggerType.CNT_ATTACK_DEFEATED, _hits_saved)
	_fire_trigger(TriggerType.CNT_ATTACK_GONE, _hits_saved + _hits_taken)
	_fire_trigger(TriggerType.CNT_ATTACK_INBOUND, active_attacks.size())

	_evaluate_level_state()

func _on_attack_missed(id: int) -> void:
	if _is_transitioning or not is_playing or id < 0 or id >= active_attacks.size():
		return

	var missed_attack: Attack = active_attacks[id]
	active_attacks.remove_at(id)
	_hits_taken += 1
	if(_hits_taken >= 2):
		_alarm_lights_on(true)

	_fire_trigger(TriggerType.ATTACK_REACHED, missed_attack.id)
	_fire_trigger(TriggerType.CNT_ATTACK_REACHED, _hits_taken)
	_fire_trigger(TriggerType.CNT_ATTACK_GONE, _hits_saved + _hits_taken)
	_fire_trigger(TriggerType.CNT_ATTACK_INBOUND, active_attacks.size())

	_evaluate_level_state()

func _on_dialogue_completed(dialogue_id: String = "") -> void:
	if _is_transitioning or not is_playing:
		return
	
	_fire_trigger(TriggerType.DIALOGUE_COMPLETED, dialogue_id)

	if _pending_outcome == LevelOutcome.PASS:
		_complete_level()
	elif _pending_outcome == LevelOutcome.FAIL:
		_fail_level()
	else:
		_evaluate_level_state()

func _evaluate_level_state() -> void:

	if _pending_outcome == LevelOutcome.PASS:
		_complete_level()
		return
	elif _pending_outcome == LevelOutcome.FAIL:
		_fail_level()
		return

	# 1. Immediate fail check
	if _hits_taken >= max_hits_allowed:
		_fail_level()
		return

	# 2. If attacks are still active, keep fighting and sync oscilloscope
	if not active_attacks.is_empty():
		_sync_oscilloscope_to_radar()
		return

	# 3. Wait if timers or future wave spawns are still pending
	if not active_timers.is_empty():
		return

	for ev: LevelEvent in current_level_events:
		if not ev._fired:
			for act: LevelAction in ev.actions:
				if act.type == ActionType.SPAWN_ATTACK:
					return

	# 4. Everything is cleared—evaluate win vs fail
	if _hits_saved >= 1:
		_complete_level()
	else:
		_fail_level()

#! LEVEL EVENTS  - level completed or failed
func _complete_level() -> void:
	if _is_transitioning or dialogue_manager.is_dialogue_active():
		return
	
	GameManager.set_game_state_active(false)
	var stars: int = clampi(3 - _hits_taken, 1, 3)
	SaveLevelData.save_level_result(_current_level_id, _elapsed_time, stars)
	await go_to_level_select(next_level_delay)

func _fail_level() -> void:
	if _is_transitioning or dialogue_manager.is_dialogue_active():
		return
	await go_to_level_select(next_level_delay)

func _on_game_completed() -> void:
	await go_to_level_select()

func go_to_level_select(delay: float = 0.0) -> void:
	if _is_transitioning:
		return
	
	_is_transitioning = true
	is_playing = false
	
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	
	_alarm_lights_on(false)
	await _tween_camera(desk_camera, overview_camera, camera_transition_time)
	open_level_select()
	
	_is_transitioning = false

func _on_target_changed(index: int) -> void:
	if index >= 0 and index < active_attacks.size():
		oscilloscope.set_enemy_wave(active_attacks[index].enemy_wave)

func _on_back_to_menu() -> void:
	await SceneManager.change_scene(MAIN_MENU_SCENE_PATH, SceneManager.TransitionType.CRT)

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
	var data = preload("res://scripts/level_data.gd").new()
	data._build_levels()
	level_list = data.level_list

func _fire_trigger(type: TriggerType, param: Variant = null) -> void:
	for ev: LevelEvent in current_level_events:
		if ev._fired and ev.one_shot:
			continue
		if ev.trigger != type:
			continue
		if ev.trigger_param != null and ev.trigger_param != param:
			continue
			
		ev._fired = true
		for act: LevelAction in ev.actions:
			_execute_action(act)

func _execute_action(act: LevelAction) -> void:
	match act.type:
		ActionType.DIALOGUE:
			dialogue_manager.start_dialogue(act.data["lines"], act.data["id"])
		ActionType.SPAWN_ATTACK:
			_spawn_attack(act.data)
		ActionType.START_TIMER:
			active_timers[act.data["id"]] = float(act.data["duration"])
		ActionType.CANCEL_TIMER:
			active_timers.erase(act.data)
		ActionType.DISABLE_EVENT:
			for ev: LevelEvent in current_level_events:
				if ev.id == act.data:
					ev._fired = true
		ActionType.PASS_LEVEL:
			_pending_outcome = LevelOutcome.PASS
			_complete_level()
		ActionType.FAIL_LEVEL:
			_pending_outcome = LevelOutcome.FAIL
			_fail_level()

func _spawn_attack(new_attack: Attack) -> void:
	active_attacks.append(new_attack)
	radar.add_blip(deg_to_rad(new_attack.angle_deg), new_attack.start_distance, new_attack.start_eta)
	
	_fire_trigger(TriggerType.CNT_ATTACK_INBOUND, active_attacks.size())

	if active_attacks.size() == 1:
		oscilloscope.set_enemy_wave(active_attacks[0].enemy_wave)

func set_simulation_paused(paused: bool) -> void:
	is_simulation_paused = paused
	radar.paused = paused

func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S:
			if not active_attacks.is_empty() and not _is_transitioning:
				_on_attack_completed()

func _alarm_lights_on(is_alarm_active: bool) -> void:
	wall_light_1.visible = not is_alarm_active
	wall_light_2.visible = not is_alarm_active
	ceiling_light.visible = not is_alarm_active
	
	if is_alarm_active:
		alarm.activate()
	else:
		alarm.deactivate()
