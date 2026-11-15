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
	var enemy_wave : CompositeWave

	func _init(p_angle_deg: float, waves: Array, p_distance: float = 1.0) -> void:
		angle_deg = p_angle_deg
		start_distance = p_distance
		enemy_wave = CompositeWave.new()
		for wave: SingleWave in waves:
			enemy_wave.add_wave(wave)

class Level:
	var dialogue_lines : Array[Dictionary] = []
	var attacks : Array[Attack] = []

	func _init(lines: Array, p_attacks: Array[Attack]) -> void:
		dialogue_lines.assign(lines)
		attacks = p_attacks

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
		Level.new(
			[
				{"speaker": "Soldier", "text": "DUMMY LEVEL"},
			],
			[
				Attack.new(120.0, [SingleWave.new(1.0, 0.1, 0.5)]),
				Attack.new(310.0, [SingleWave.new(0.5, 0.4, 0.5)]),
			]
		),
		Level.new(
			[
				{"speaker": "Soldier", "text": "Sir! Two incoming signals at 20 and 250 degrees. Cancel their waves before they reach us!"},
			],
			[
				Attack.new(20.0, [SingleWave.new(1.0, 0.1, 0.5), SingleWave.new(0.3, 1.0, 0.0)]),
				Attack.new(250.0, [SingleWave.new(0.7, 0.3, 0.0), SingleWave.new(0.5, 0.6, 0.25)]),
			]
		),
		Level.new(
			[
				{"speaker": "Soldier", "text": "Level 2: Three tanks incoming!"},
			],
			[
				Attack.new(45.0, [SingleWave.new(1.0, 0.2, 0.75)], 1.0),
				Attack.new(160.0, [SingleWave.new(0.6, 0.8, 0.5)], 0.85),
				Attack.new(310.0, [SingleWave.new(0.8, 0.15, 0.0), SingleWave.new(0.5, 0.45, 0.3)], 1.0),
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
		radar.add_blip(deg_to_rad(attack.angle_deg), attack.start_distance)

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
