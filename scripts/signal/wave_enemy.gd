class_name EnemyWave
extends Node

var total_wave: CompositeWave 
@export var wave_plotter_enemy : WavePlotter

# For animation and level completion
var is_locked: bool = false

func clear() -> void:
	total_wave = null
	wave_plotter_enemy.set_wave(null) # Or whatever your WavePlotter expects when empty
	wave_plotter_enemy.redraw_plot()

func set_wave(wave: CompositeWave) -> void:
	total_wave = wave
	wave_plotter_enemy.set_wave(total_wave)
	wave_plotter_enemy.redraw_plot()

# Redraw and update for drifting waves
func _process(delta: float) -> void:
	if is_locked:
		return
		
	if total_wave != null and total_wave.is_drifting():
		total_wave.update(delta)
		wave_plotter_enemy.redraw_plot()
