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

func get_wave(i: int) -> SingleWave:
	if i < len(waves):
		return waves[i]
	else:
		return null

#0-100 score
func get_accuracy(other_wave: CompositeWave, t_min: float, t_max: float, dt: float) -> float:
		
	var squared_error_sum: float = 0.0
	var sample_count: int = 0
	
	var t: float = t_min
	while t <= t_max:
		var y1: float = sample(t)
		var y2: float = other_wave.sample(t)
		
		var diff: float = y1 - y2
		squared_error_sum += diff * diff
		sample_count += 1
		t += dt
		
	if sample_count == 0:
		return 0.0
		
	# Root mean square error (0 identical, 1 is wrong)
	var rmse: float = sqrt(squared_error_sum / sample_count)
	
	# RMSE to percentage (!TODO: more forigving?)
	var raw_accuracy: float =  clampf((1.0 - rmse) * 100.0, 0.0, 100.0)
	# Remap 30.0..100.0 to 0.0..100.0 because 30 is awful wave lgn up

	var accuracy: float = remap(raw_accuracy, 30.0, 100.0, 0.0, 100.0)

	return clampf(accuracy, 0.0, 100.0)