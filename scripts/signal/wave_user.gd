class_name UserWave
extends Node

signal target_reached

@export_group("References")
@export var wave_plotter_user : WavePlotter
@export var enemy : EnemyWave
@export var progress_bar : CustomProgressBar
@export var wave_selection_panel : WaveSelectionPanel
@export var sub_plotters : Array[WavePlotter] = []

@export var display_amp : NumericDisplay
@export var display_freq : NumericDisplay
@export var display_phase : NumericDisplay
@export var display_wave_type : NumericDisplay

# For animation and level completion
var is_locked: bool = false

const MAX_WAVES: int = 3

# Score needed to complete the level, maybe make it configurable per level instead of hardcoded
const TARGET_SCORE: float = 95.0

var selected_wave_id: int = 0
var total_wave: CompositeWave

func _ready() -> void:
	wave_selection_panel.plus_pressed.connect(_plus_button_pressed)
	wave_selection_panel.minus_pressed.connect(_minus_button_pressed)
	wave_selection_panel.left_pressed.connect(_left_button_pressed)
	wave_selection_panel.right_pressed.connect(_right_button_pressed)

func setup() -> void:
	total_wave = CompositeWave.new()
	selected_wave_id = 0
	wave_plotter_user.set_wave(total_wave)
	_refresh_plots()
	_update_displays()
	_score()

func _plus_button_pressed() -> void:
	if !total_wave: return
	if total_wave.waves.size() >= MAX_WAVES:
		return
	# TODO: I left this default wave, maybe is not the best default one i dunno
	total_wave.add_wave(SingleWave.new(1.0, 0.4, 0.0))
	_select_wave(total_wave.waves.size() - 1)
	_score()

func _left_button_pressed() -> void:
	if !total_wave: return
	_select_wave(selected_wave_id - 1)

func _right_button_pressed() -> void:
	if !total_wave: return
	_select_wave(selected_wave_id + 1)

func _minus_button_pressed() -> void:
	if !total_wave: return
	if total_wave.waves.is_empty():
		return
	total_wave.remove_wave(total_wave.waves[selected_wave_id])
	_select_wave(selected_wave_id - 1)
	_score()

func _on_wave_type_button_pressed() -> void:
	if !total_wave or total_wave.waves.is_empty():
		return
	display_wave_type.cycle_wave_type()
	_score()

func _select_wave(id: int) -> void:
	var last_id: int = maxi(total_wave.waves.size() - 1, 0)
	selected_wave_id = clampi(id, 0, last_id)
	_refresh_plots()
	_update_displays()

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
	if !enemy.total_wave:
		progress_bar.set_score(0.0)
		return
	if is_locked:
		return

	# Adjusted score calculation for the main window screen space
	var score : float = total_wave.get_accuracy(enemy.total_wave, wave_plotter_user.t_min, wave_plotter_user.t_max, wave_plotter_user.dt)
	progress_bar.set_score(score)
	# print("SCORE: " ,score )
	if score >= TARGET_SCORE:
		target_reached.emit()

#TODO! adjust the ranges of freq and phase to be sensible
# Signals to modify selected wave
# Amplitude of waves goes from 0-1
func _on_amplitude_knob_value_changed(delta_value: float) -> void:
	if !total_wave or is_locked: return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.set_amplitude(selected_wave.get_amplitude() + delta_value)
		_refresh_selected_plot()
		_score()
		_update_displays() 

func _on_freq_knob_value_changed(delta_value: float) -> void:
	if !total_wave or is_locked: return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.set_frequency(selected_wave.get_frequency() + delta_value)
		_refresh_selected_plot()
		_score()
		_update_displays() 

func _on_phase_knob_value_changed(delta_value: float) -> void:
	if !total_wave or is_locked: return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.set_phase(selected_wave.get_phase() + delta_value)
		_refresh_selected_plot()
		_score()
		_update_displays() 

func _update_displays() -> void:
	if total_wave.waves.is_empty():
		display_amp.clear()
		display_freq.clear()
		display_phase.clear()
		return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	display_amp.set_value(selected_wave.get_amplitude())
	display_freq.set_value(selected_wave.get_frequency())
	display_phase.set_value(selected_wave.get_phase())
	display_wave_type.set_wave_type(selected_wave.get_wave_type())

func get_wave_type() -> SingleWave.WaveType:
	if !total_wave or total_wave.waves.is_empty():
		return SingleWave.WaveType.SINE
	return total_wave.get_wave(selected_wave_id).get_wave_type()

func set_wave_type(type: SingleWave.WaveType) -> void:
	if !total_wave or is_locked or total_wave.waves.is_empty():
		return
	var selected_wave = total_wave.get_wave(selected_wave_id)
	if selected_wave:
		selected_wave.set_wave_type(type)
		_refresh_selected_plot()
		_score()

func play_validation_flash() -> void:
	is_locked = true
	var plotter: WavePlotter = wave_plotter_user
	var orig_width: float = plotter.line_thickness
	var orig_color: Color = plotter.wave_color
	
	# Flash 3 times
	var tween := create_tween()
	for i in range(3):
		tween.tween_property(plotter, "width", orig_width * 3.0, 0.12)
		tween.parallel().tween_property(plotter, "default_color", Color(1.8, 2.2, 1.8, 1.0), 0.12)
		tween.tween_property(plotter, "width", orig_width, 0.12)
		tween.parallel().tween_property(plotter, "default_color", orig_color, 0.12)
	
	await tween.finished
	is_locked = false

# If enemy wave is drifint trigger score recalc
func _process(delta: float) -> void:
	if enemy.total_wave != null and enemy.total_wave.is_drifting():
		_score()