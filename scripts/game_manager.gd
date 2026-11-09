extends Node

@export_group("References")
@export var dialogueManage : DialogueManager
@export var oscilloscope : Oscilloscope
@export var scene_fx : SceneFx

var dialogue_lines = [
	{"speaker": "Soldier", "text": "Sir! We are getting attacked, cancel out the enemy's waves. Hurry we don't have much time!"},
	{"speaker": "Soldier", "text": "Hi"}
]

func _ready() -> void:
	# Start initial dialogue
	dialogueManage.start_dialogue(dialogue_lines)
	
	# Create initial enemy wave
	var single_wave1 = SingleWave.new(1.0, 0.1, 0.5) 
	var single_wave2 = SingleWave.new(0.3, 1.0, 0.0) 
	var total_wave = CompositeWave.new(2)
	total_wave.add_wave(single_wave1)
	total_wave.add_wave(single_wave2)
	oscilloscope.set_enemy_wave(total_wave)
