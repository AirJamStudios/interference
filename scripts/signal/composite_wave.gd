class_name CompositeWave
extends Wave


var waves: Array[SingleWave] = []

func add_wave(wave: SingleWave) -> void:
	waves.append(wave)

func remove_wave(wave: SingleWave) -> void:
	waves.erase(wave)

func clear_waves() -> void:
	waves.clear()

#Normalize so that amplitude is between 0-1
func sample(t: float) -> float:
	var total_wave: float = 0.0
	for wave in waves:
		total_wave += wave.sample(t)
	if waves:
		total_wave /= len(waves)
	return total_wave
