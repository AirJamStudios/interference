class_name EnemyWave
extends Node

var total_wave: CompositeWave 
@export var wave_plotter_enemy : WavePlotter

func _ready() -> void:
	# Tempory to test
	var single_wave1 = SingleWave.new(1.0, 0.1, 0.5) 
	var single_wave2 = SingleWave.new(0.3, 1.0, 0.0) 
	total_wave = CompositeWave.new(2)
	total_wave.add_wave(single_wave1)
	total_wave.add_wave(single_wave2)
	wave_plotter_enemy.set_wave(total_wave)
	wave_plotter_enemy.redraw_plot()
