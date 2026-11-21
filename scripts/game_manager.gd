extends Node

@export_group("References")
@export var dialogueManage : DialogueManager
@export var oscilloscope : Oscilloscope
@export var scene_fx : SceneFx
@export var radar : Radar

@export_group("Settings")
@export var next_level_delay : float = 1.5

var active_attacks : Array[Attack] = []

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

var level_list : Array[Level] = []
var current_level : int = 0
var _changing_level : bool = false

func _ready() -> void:
	_build_levels()
	oscilloscope.attack_completed.connect(_on_attack_completed)
	radar.target_changed.connect(_on_target_changed)
	_load_level(current_level)

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

func _load_level(index: int) -> void:
	var level : Level = level_list[index]
	dialogueManage.start_dialogue(level.dialogue_lines)

	active_attacks = level.attacks.duplicate()

	#Spawn blips
	radar.blips.clear()
	for attack: Attack in active_attacks:
		radar.add_blip(deg_to_rad(attack.angle_deg), attack.start_distance, attack.start_eta)

	if not active_attacks.is_empty():
		oscilloscope.set_enemy_wave(active_attacks[radar.selected_index].enemy_wave)

func _on_attack_completed() -> void:
	if _changing_level:
		return

	# Attack done
	var target_idx: int = radar.selected_index
	active_attacks.remove_at(target_idx)
	radar.remove_blip_at(target_idx)

	# Continue level
	if not active_attacks.is_empty():
		return
	
	# Level done
	_changing_level = true
	print("Level ", current_level + 1, " completed!")

	await get_tree().create_timer(next_level_delay).timeout

	current_level += 1
	if current_level >= level_list.size():
		_on_all_levels_completed()
	else:
		_load_level(current_level)
	_changing_level = false

func _on_target_changed(index: int) -> void:
	if index >= 0 and index < active_attacks.size():
		oscilloscope.set_enemy_wave(active_attacks[index].enemy_wave)

func _on_all_levels_completed() -> void:
	# TODO: end screen / credits
	print("All levels completed!")

	
# func _physics_process(delta):
# 	var level : Level = level_list[current_level]
# 	dialogueManage.start_dialogue(level.dialogue_lines)

# 	active_attacks = level.attacks.duplicate()
# 	radar.blips.clear()
# 	for attack: Attack in active_attacks:



#Debug only skip attacks
func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S:
			if not active_attacks.is_empty() and not _changing_level:
				_on_attack_completed()
