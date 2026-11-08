class_name SingleWave
extends Wave

# Wave parameters (ALL normalized 0-1)
var _frequency: float = 1.0
var _amplitude: float = 1.0
var _phase: float = 0.0  # mapped to -PI, PI

var min_frequency: float = 0.05
var max_frequency: float = 2.0

func _init(amp_normalized: float = 1.0, freq: float = 1.0, phase_normalized: float = 0.0):
	set_frequency(freq)
	set_amplitude(amp_normalized)
	set_phase(phase_normalized)


func sample(t: float) -> float:
	var mapped_phase := lerpf(-PI, PI, _phase)
	var mapped_freq := lerpf(min_frequency, max_frequency, _frequency)
	return _amplitude * sin(2.0 * PI * mapped_freq * t + mapped_phase)

# Map 0-1 to one full cycle (-PI..PI). A wider range just repeats the same shapes.
# Setters
func set_phase(value: float) -> void:
	_phase = snapped(clampf(value, 0.0, 1.0), 0.01)

func set_amplitude(value: float) -> void:
	_amplitude = snapped(clampf(value, 0.0, 1.0), 0.01)

func set_frequency(value: float) -> void:
	_frequency = snapped(clampf(value, 0.0, 1.0), 0.01)

# Getters
func get_frequency() -> float:
	return _frequency

func get_amplitude() -> float:
	return _amplitude

func get_phase() -> float:
	return _phase

func print_parameters() -> void:
	print("Amplitude: ", _amplitude, " Frequency: ", _frequency, " Phase: ", _phase)


