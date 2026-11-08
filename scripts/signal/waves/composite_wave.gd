class_name CompositeWave
extends Wave


var waves: Array[SingleWave] = []

# Use the known amount of waves needed to return
# correctly normalized wave from the start
var solution_waves_count: int = 1

func _init(n: int):
	solution_waves_count = n

func add_wave(wave: SingleWave) -> void:
	waves.append(wave)
	if(wave_count()>solution_waves_count):
		print("Warning, wave amount does not match config!!")

func remove_wave(wave: SingleWave) -> void:
	waves.erase(wave)

func clear_waves() -> void:
	waves.clear()

func wave_count() -> int:
	return len(waves)

# Normalize so that amplitude is between 0-1
# Normalize with total amount of waves needed (NOT current amount)
func sample(t: float) -> float:
	var total_wave: float = 0.0
	for wave in waves:
		total_wave += wave.sample(t)
	if waves:
		total_wave /= solution_waves_count
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

	# Remap 30.0..95.0 to 0.0..100.0 
	var accuracy: float = remap(raw_accuracy, 45.0, 95.0, 0.0, 100.0)

	return clampf(accuracy, 0.0, 100.0)


func print_parameters() -> void:
	print("Composite wave with ", len(waves), " waves:")
	for wave in waves:
		wave.print_parameters()
