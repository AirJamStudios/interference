class_name SingleWave
extends Wave

# Wave parameters
var frequency: float = 1.0
var amplitude: float = 1.0
var phase: float = 0.0 

func _init(amp: float = 1.0, freq: float = 1.0, phase_normalized: float = 0.0):
	frequency = freq
	amplitude = clampf(amp, 0.0, 1.0)
	calc_and_set_phase(phase_normalized)


func sample(t: float) -> float:
	return amplitude * sin(2.0 * PI * frequency * t + phase)

# Map 0-1 to one full cycle (-PI..PI). A wider range just repeats the same shapes.
func calc_and_set_phase(value: float) -> void:
	phase = lerpf(-PI, PI, clampf(value, 0.0, 1.0))