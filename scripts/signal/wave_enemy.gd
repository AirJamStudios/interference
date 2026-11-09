class_name EnemyWave
extends Node

var total_wave: CompositeWave 
@export var wave_plotter_enemy : WavePlotter

func set_wave(wave: CompositeWave) -> void:
	total_wave = wave
	wave_plotter_enemy.set_wave(total_wave)
	wave_plotter_enemy.redraw_plot()
