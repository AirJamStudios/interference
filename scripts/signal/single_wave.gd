class_name SingleWave
extends Wave

# Wave parameters
var frequency: float = 1.0
var amplitude: float = 1.0
var phase: float = 0.0 

func _init(freq: float = 1.0, amp: float = 1.0, ph: float = 0.0):
	frequency = freq
	amplitude = amp
	phase = ph


func sample(t: float) -> float:
	return amplitude * sin(2.0 * PI * frequency * t + phase)
