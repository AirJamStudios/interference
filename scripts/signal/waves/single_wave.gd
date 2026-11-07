class_name SingleWave
extends Wave

# Wave parameters
var frequency: float = 1.0
var amplitude: float = 1.0
var phase: float = 0.0 

func _init(amp: float = 1.0, freq: float = 1.0, ph: float = 0.0):
	frequency = freq
	amplitude = clampf(amp, 0.0, 1.0)
	phase = ph


func sample(t: float) -> float:
	return amplitude * sin(2.0 * PI * frequency * t + phase)
