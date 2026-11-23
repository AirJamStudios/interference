class_name CompositeWave
extends Wave

#Drift allowed if one wave 
enum DriftMode { NONE, AMPLITUDE, FREQUENCY, PHASE }
var drift_mode: DriftMode = DriftMode.NONE
var drift_min: float = 0.0
var drift_max: float = 1.0
var drift_speed: float = 1.0
var _drift_time: float = 0.0

var waves: Array[SingleWave] = []

var max_waves: int = 3

func add_wave(wave: SingleWave) -> void:
	if(wave_count()>=max_waves):
		print("Warning, too many waves!!")
		return
	waves.append(wave)

func remove_wave(wave: SingleWave) -> void:
	waves.erase(wave)

func clear_waves() -> void:
	waves.clear()

func wave_count() -> int:
	return len(waves)

# Normalize so that amplitude is between 0-1
# Normalize with total max waves
func sample(t: float) -> float:
	var total_wave: float = 0.0
	for wave in waves:
		total_wave += wave.sample(t)
	if waves:
		total_wave /= max_waves
	return total_wave

func get_wave(i: int) -> SingleWave:
	if i < len(waves):
		return waves[i]
	else:
		return null

#0-100 score
const TARGET_SCORE: float = 95.0
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
	
	# RMSE to percentage
	var raw_accuracy: float =  clampf((1.0 - rmse) * 100.0, 0.0, 100.0)

	# Remap 30.0..95.0 to 0.0..100.0 
	var accuracy: float = remap(raw_accuracy, 45.0, TARGET_SCORE, 0.0, 100.0)

	return clampf(accuracy, 0.0, 100.0)


func print_parameters() -> void:
	print("Composite wave with ", len(waves), " waves:")
	for wave in waves:
		wave.print_parameters()


func set_drift(drift: DriftMode, min_val : float = 0.2, max_val: float = 1.0, speed: float = 1.0) -> void:
	if wave_count() != 1:
		print("Warning: Drift mode only with one wave!!!")
		drift_mode = DriftMode.NONE
		return
		
	drift_mode = drift
	drift_min = clampf(min_val, 0.0, 1.0)
	drift_max = clampf(max_val, 0.0, 1.0)
	drift_speed = speed
	_drift_time = 0.0


func is_drifting() -> bool:
	return drift_mode != DriftMode.NONE

func update(delta: float) -> void:
	# No need to update static waves
	if not is_drifting():
		return
	_drift_time += delta * drift_speed
	
	# Smooth oscilation between values
	var weight: float = (sin(_drift_time - PI * 0.5) + 1.0) * 0.5
	var val: float = lerpf(drift_min, drift_max, weight)
	var w: SingleWave = waves[0]
	
	match drift_mode:
		DriftMode.AMPLITUDE:
			w.set_amplitude(val)
		DriftMode.FREQUENCY:
			w.set_frequency(val)
		DriftMode.PHASE:
			w.set_phase(fposmod(w.get_phase() + delta * drift_speed, 1.0))