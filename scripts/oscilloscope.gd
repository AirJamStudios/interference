class_name Oscilloscope
extends Node3D

signal attack_completed

@export_group("References")
@export var enemy_wave : EnemyWave
@export var user_wave : UserWave

# Animate the wave on complete
var _completing_attack: bool = false

func _ready() -> void:
	user_wave.target_reached.connect(_on_user_target_reached)
	user_wave.setup()

func set_enemy_wave(wave : CompositeWave) -> void:
	enemy_wave.set_wave(wave)

# User and enemy wave overlap higher than score!
# Plays animation of 3 flashes
func _on_user_target_reached() -> void:
	if _completing_attack:
		return
	_completing_attack = true
	await user_wave.play_validation_flash()
	_completing_attack = false
	attack_completed.emit()