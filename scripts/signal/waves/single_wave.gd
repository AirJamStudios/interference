class_name SingleWave
extends Wave

enum WaveType { SINE, SQUARE, TRIANGLE }

# Wave parameters (ALL normalized 0-1)
var _wave_type: WaveType = WaveType.SINE
var _frequency: float = 1.0
var _amplitude: float = 1.0
var _phase: float = 0.0  # mapped to 0, 2PI

var min_frequency: float = 0.05
var max_frequency: float = 2.0

func _init(amp_normalized: float = 1.0, freq: float = 1.0, phase_normalized: float = 0.0, wave_type: WaveType = WaveType.SINE) -> void:
	set_frequency(freq)
	set_amplitude(amp_normalized)
	set_phase(phase_normalized)
	set_wave_type(wave_type)


func sample(t: float) -> float:
	var mapped_freq := lerpf(min_frequency, max_frequency, _frequency)

	# limit cycle from 0 to 1
	var cycle_pos : float = fposmod(mapped_freq * t + _phase, 1.0)
	
	var raw_value: float = 0.0
	match _wave_type:
		WaveType.SINE:
			raw_value = sin(cycle_pos * TAU)
		WaveType.SQUARE:
			raw_value = 1.0 if cycle_pos < 0.5 else -1.0
		WaveType.TRIANGLE:
			# for tirangle 0-1 to -1 to 1 and shifted so it lines up with sin
			# this pingpongs the values to generate the triangle shape
			raw_value = 1.0 - 4.0 * absf(roundf(cycle_pos - 0.25) - (cycle_pos - 0.25))

			
	return _amplitude * raw_value

# Map 0-1 to one full cycle (-PI..PI). A wider range just repeats the same shapes.
# Setters
func set_phase(value: float) -> void:
	_phase = snapped(clampf(value, 0.0, 1.0), 0.0001)

func set_amplitude(value: float) -> void:
	_amplitude = snapped(clampf(value, 0.0, 1.0), 0.0001)

func set_frequency(value: float) -> void:
	_frequency = snapped(clampf(value, 0.0, 1.0), 0.0001)

func set_wave_type(type: WaveType) -> void:
	_wave_type = type

# Getters
func get_frequency() -> float:
	return _frequency

func get_amplitude() -> float:
	return _amplitude

func get_phase() -> float:
	return _phase

func get_wave_type() -> WaveType:
	return _wave_type

func print_parameters() -> void:
	var type_name: String = WaveType.keys()[_wave_type]
	print("Type: ", type_name,  "Amplitude: ", _amplitude, " Frequency: ", _frequency, " Phase: ", _phase)
