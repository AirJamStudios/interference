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
	# Update score also when new enemy wave
	user_wave.calc_score()


# User and enemy wave overlap higher than score!
# Plays animation of 3 flashes
func _on_user_target_reached() -> void:
	if _completing_attack:
		return
	_completing_attack = true
	enemy_wave.is_locked = true
	GameManager.play_sfx(GameManager.Sfx.WAVE_COMPLETE)
	await user_wave.play_validation_flash()
	enemy_wave.is_locked = false
	_completing_attack = false
	attack_completed.emit()
