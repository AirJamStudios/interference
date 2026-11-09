class_name Oscilloscope
extends Node3D

@export_group("References")
@export var enemy_wave : EnemyWave
@export var user_wave : UserWave

func set_enemy_wave(wave : CompositeWave) -> void:
	enemy_wave.set_wave(wave)
	user_wave.setup(wave)