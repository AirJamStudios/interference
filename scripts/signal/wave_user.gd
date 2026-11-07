extends Node

@export_group("References")
@export var wave_plotter_user : WavePlotter
@export var enemy : EnemyWave
@export var progress_bar : CustomProgressBar
@export var wave_selection_panel : WaveSelectionPanel

var selected_wave_id: int = 0
var total_wave: CompositeWave

func _ready() -> void:
	total_wave = CompositeWave.new()

	wave_selection_panel.plus_pressed.connect(_plus_button_pressed)
	wave_selection_panel.minus_pressed.connect(_minus_button_pressed)
	wave_selection_panel.left_pressed.connect(_left_button_pressed)
	wave_selection_panel.right_pressed.connect(_right_button_pressed)

	wave_plotter_user.set_wave(total_wave)
	wave_plotter_user.redraw_plot()

func _plus_button_pressed() -> void:
	# TODO: I left this default wave, maybe is not the best default one i dunno
	total_wave.add_wave(SingleWave.new(1.0, 0.4, 0.0))
	_select_wave(total_wave.waves.size() - 1)
	wave_plotter_user.redraw_plot()

func _left_button_pressed() -> void:
	_select_wave(selected_wave_id - 1)

func _right_button_pressed() -> void:
	_select_wave(selected_wave_id + 1)

func _minus_button_pressed() -> void:
	if total_wave.waves.is_empty():
		return
	total_wave.remove_wave(total_wave.waves[selected_wave_id])
	_select_wave(selected_wave_id - 1)
	wave_plotter_user.redraw_plot()

func _select_wave(id: int) -> void:
	var last_id: int = maxi(total_wave.waves.size() - 1, 0)
	selected_wave_id = clampi(id, 0, last_id)
	print("Selected wave: ", selected_wave_id)

# Score over the same time window the plotter draws
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
