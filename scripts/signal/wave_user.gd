extends Node


@export_group("References")
@export var wave_plotter_user : WavePlotter
@export var enemy : EnemyWave
@export var progress_bar : CustomProgressBar

var selected_wave_id: int = 0
var total_wave: CompositeWave 

func _ready() -> void:
	# Tempory to test
	var single_wave1 = SingleWave.new(1.0, 0.4, 0.0) 
	var single_wave2 = SingleWave.new(0.3, 2, 0.0) 
	total_wave = CompositeWave.new()
	total_wave.add_wave(single_wave1)
	total_wave.add_wave(single_wave2)
	wave_plotter_user.set_wave(total_wave)
	wave_plotter_user.redraw_plot()

func _score() -> void:
	#TODO! unhardcode this
	var score : float = total_wave.get_accuracy(enemy.total_wave, -10, 10, 0.05)
	progress_bar.set_score(score)
	print("SCORE: " ,score )

#TODO! adjust the ranges of freq and phase to be sensible
# Signals to modify selected wave
# Amplitude of waves goes from 0-1
func _on_amplitude_knob_value_changed(value: float) -> void:
	if !total_wave: return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.amplitude = value
		wave_plotter_user.redraw_plot()
		print("Amp:" , selected_wave.amplitude)
		_score()

func _on_freq_knob_value_changed(value: float) -> void:
	if !total_wave: return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.frequency = lerpf(0.05, 2.0, value)
		wave_plotter_user.redraw_plot()
		print("Freq: ", selected_wave.frequency)
		_score()

func _on_phase_knob_value_changed(value: float) -> void:
	if !total_wave: return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.calc_and_set_phase(value)
		wave_plotter_user.redraw_plot()
		print("Phase: ", selected_wave.phase)
		_score()
