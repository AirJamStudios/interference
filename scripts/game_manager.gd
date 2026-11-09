extends Node

@export_group("References")
@export var dialogueManage : DialogueManager
@export var oscilloscope : Oscilloscope
@export var scene_fx : SceneFx

class Level:
	var dialogue_lines : Array[Dictionary] = []
	var enemy_wave : CompositeWave 

var level_list : Array[Level] = []
var current_level : int = 0

func _ready() -> void:
	var initial_level := Level.new()
	initial_level.dialogue_lines = [
	{"speaker": "Soldier", "text": "Sir! We are getting attacked, cancel out the enemy's waves. Hurry we don't have much time!"},
	{"speaker": "Soldier", "text": "Hi"}
	]
	initial_level.enemy_wave = CompositeWave.new(2)
	initial_level.enemy_wave.add_wave(SingleWave.new(1.0, 0.1, 0.5))
	initial_level.enemy_wave.add_wave(SingleWave.new(0.3, 1.0, 0.0))

	_load_level(initial_level)

func _load_level(level: Level) -> void:
	dialogueManage.start_dialogue(level.dialogue_lines)
	oscilloscope.set_enemy_wave(level.enemy_wave)
