extends Node

@export_group("References")
@export var wave_plotter_user : WavePlotter
@export var enemy : EnemyWave
@export var progress_bar : CustomProgressBar
@export var wave_selection_panel : WaveSelectionPanel
@export var sub_plotters : Array[WavePlotter] = []

const MAX_WAVES: int = 3

var selected_wave_id: int = 0
var total_wave: CompositeWave

func _ready() -> void:
	total_wave = CompositeWave.new(enemy.total_wave.wave_count())

	wave_selection_panel.plus_pressed.connect(_plus_button_pressed)
	wave_selection_panel.minus_pressed.connect(_minus_button_pressed)
	wave_selection_panel.left_pressed.connect(_left_button_pressed)
	wave_selection_panel.right_pressed.connect(_right_button_pressed)

	wave_plotter_user.set_wave(total_wave)
	_refresh_plots()

func _plus_button_pressed() -> void:
	if total_wave.waves.size() >= MAX_WAVES:
		return
	# TODO: I left this default wave, maybe is not the best default one i dunno
	total_wave.add_wave(SingleWave.new(1.0, 0.4, 0.0))
	_select_wave(total_wave.waves.size() - 1)

func _left_button_pressed() -> void:
	_select_wave(selected_wave_id - 1)

func _right_button_pressed() -> void:
	_select_wave(selected_wave_id + 1)

func _minus_button_pressed() -> void:
	if total_wave.waves.is_empty():
		return
	total_wave.remove_wave(total_wave.waves[selected_wave_id])
	_select_wave(selected_wave_id - 1)

func _select_wave(id: int) -> void:
	var last_id: int = maxi(total_wave.waves.size() - 1, 0)
	selected_wave_id = clampi(id, 0, last_id)
	print("Selected wave: ", selected_wave_id)
	_refresh_plots()
	total_wave.print_parameters()
	enemy.total_wave.print_parameters()

# Redraw the composed wave plus every sub wave slot (selected one bright, rest dimmed)
func _refresh_plots() -> void:
	wave_plotter_user.redraw_plot()
	for i in sub_plotters.size():
		var plotter: WavePlotter = sub_plotters[i]
		plotter.set_wave(total_wave.get_wave(i))
		plotter.set_dimmed(i != selected_wave_id)
		plotter.redraw_plot()

# Only the selected wave changed, so only it and the composed wave need redrawing
func _refresh_selected_plot() -> void:
	wave_plotter_user.redraw_plot()
	if selected_wave_id < sub_plotters.size():
		sub_plotters[selected_wave_id].redraw_plot()

func _score() -> void:
	# Adjusted score calculation for the main window screen space
	var score : float = total_wave.get_accuracy(enemy.total_wave, wave_plotter_user.t_min, wave_plotter_user.t_max, wave_plotter_user.dt)
	progress_bar.set_score(score)
	print("SCORE: " ,score )

#TODO! adjust the ranges of freq and phase to be sensible
# Signals to modify selected wave
# Amplitude of waves goes from 0-1
func _on_amplitude_knob_value_changed(value: float) -> void:
	if !total_wave: return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.set_amplitude(value)
		_refresh_selected_plot()
		_score()

func _on_freq_knob_value_changed(value: float) -> void:
	if !total_wave: return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.set_frequency(lerpf(0.05, 2.0, value))
		_refresh_selected_plot()
		_score()

func _on_phase_knob_value_changed(value: float) -> void:
	if !total_wave: return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.calc_and_set_phase(value)
		_refresh_selected_plot()
		_score()
