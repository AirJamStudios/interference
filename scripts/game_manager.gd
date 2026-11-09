extends Node

@export_group("References")
@export var dialogueManage : DialogueManager
@export var oscilloscope : Oscilloscope
@export var scene_fx : SceneFx

@export_group("Settings")
@export var next_level_delay : float = 1.5

class Level:
	var dialogue_lines : Array[Dictionary] = []
	var enemy_wave : CompositeWave

	func _init(lines: Array, waves: Array) -> void:
		dialogue_lines.assign(lines)
		enemy_wave = CompositeWave.new(waves.size())
		for wave: SingleWave in waves:
			enemy_wave.add_wave(wave)

var level_list : Array[Level] = []
var current_level : int = 0
var _changing_level : bool = false

func _ready() -> void:
	_build_levels()
	oscilloscope.level_completed.connect(_on_level_completed)
	_load_level(current_level)

func _build_levels() -> void:
	level_list = [
		Level.new(
			[
				{"speaker": "Soldier", "text": "Sir! We are getting attacked, cancel out the enemy's waves. Hurry we don't have much time!"},
				{"speaker": "Soldier", "text": "Hi"},
			],
			[SingleWave.new(1.0, 0.1, 0.5), SingleWave.new(0.3, 1.0, 0.0)]
		),
		Level.new(
			[
				{"speaker": "Soldier", "text": "Level 2 text"},
			],
			[SingleWave.new(0.7, 0.3, 0.0), SingleWave.new(0.5, 0.6, 0.25)]
		),
		Level.new(
			[
				{"speaker": "Soldier", "text": "Level 3 text"},
			],
			[SingleWave.new(1.0, 0.2, 0.75), SingleWave.new(0.6, 0.8, 0.5)]
		),
		Level.new(
			[
				{"speaker": "Soldier", "text": "Level 4 text"},
			],
			[SingleWave.new(0.8, 0.15, 0.0), SingleWave.new(0.5, 0.45, 0.3)]
		),
		Level.new(
			[
				{"speaker": "Soldier", "text": "Level 5 text"},
			],
			[SingleWave.new(1.0, 0.25, 0.5), SingleWave.new(0.7, 0.55, 0.1), SingleWave.new(0.4, 0.85, 0.9)]
		),
	]

func _load_level(index: int) -> void:
	var level : Level = level_list[index]
	dialogueManage.start_dialogue(level.dialogue_lines)
	oscilloscope.set_enemy_wave(level.enemy_wave)

func _on_level_completed() -> void:
	if _changing_level:
		return
	_changing_level = true
	print("Level ", current_level + 1, " completed!")

	await get_tree().create_timer(next_level_delay).timeout

	current_level += 1
	if current_level >= level_list.size():
		_on_all_levels_completed()
	else:
		_load_level(current_level)
	_changing_level = false

func _on_all_levels_completed() -> void:
	# TODO: end screen / credits
	print("All levels completed!")
