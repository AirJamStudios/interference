class_name Oscilloscope
extends Node3D

signal level_completed

@export_group("References")
@export var enemy_wave : EnemyWave
@export var user_wave : UserWave

func _ready() -> void:
	user_wave.target_reached.connect(_on_user_target_reached)

func set_enemy_wave(wave : CompositeWave) -> void:
	enemy_wave.set_wave(wave)
	user_wave.setup(wave)

func _on_user_target_reached() -> void:
	level_completed.emit()
