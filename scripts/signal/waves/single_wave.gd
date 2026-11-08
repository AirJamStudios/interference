class_name SingleWave
extends Wave

# Wave parameters
var _frequency: float = 1.0
var _amplitude: float = 1.0
var _phase: float = 0.0 

func _init(amp_normalized: float = 1.0, freq: float = 1.0, phase_normalized: float = 0.0):
	_frequency = freq
	_amplitude = clampf(amp_normalized, 0.0, 1.0)
	calc_and_set_phase(phase_normalized)


func sample(t: float) -> float:
	return _amplitude * sin(2.0 * PI * _frequency * t + _phase)

# Map 0-1 to one full cycle (-PI..PI). A wider range just repeats the same shapes.
func calc_and_set_phase(value: float) -> void:
	value = lerpf(-PI, PI, clampf(value, 0.0, 1.0))
	_phase = snapped(value, 0.01)

func set_amplitude(value: float) -> void:
	value =  clampf(value, 0.0, 1.0)
	_amplitude = snapped(value, 0.01)

func set_frequency(value: float) -> void:
	_frequency = snapped(value, 0.01)

func print_parameters() -> void:
	print("Amplitude: ", _amplitude, " Frequency: ", _frequency, " Phase: ", _phase)