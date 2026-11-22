extends Node

const SAVE_PATH := "user://operation_save.cfg"

# level_index: { "unlocked": bool, "stars": int, "best_time": float } 
var progress: Dictionary = {}

func _ready() -> void:
	load_data()


func get_level_info(index: int) -> Dictionary:
	if not progress.has(index):
		progress[index] = {
			"unlocked": index == 0, #first level unlocked
			"stars": 0,
			"best_time": -1.0
		}
	return progress[index]


func save_level_result(index: int, elapsed_time: float, stars: int) -> void:
	var info: Dictionary = get_level_info(index)
	info["unlocked"] = true
	
	# Only overwrite for the best starts and what time it took
	if stars > info["stars"]:
		info["stars"] = stars
		info["best_time"] = elapsed_time
		
	# Unlock the next level
	var next_info: Dictionary = get_level_info(index + 1)
	next_info["unlocked"] = true
	
	save_data()


func save_data() -> void:
	var cfg := ConfigFile.new()
	for idx in progress.keys():
		cfg.set_value("levels", str(idx), progress[idx])
	
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_error("Failed to save game, error: " + str(err))


func load_data() -> void:
	# For debug to reset data everytime
	# reset_all_data() 
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK and cfg.has_section("levels"):
		for key in cfg.get_section_keys("levels"):
			progress[int(key)] = cfg.get_value("levels", key)
	else:
		# First time the level 0 is ready
		get_level_info(0)


#For debuggin reset data
func reset_all_data() -> void:
	progress.clear()
	get_level_info(0)
	save_data()
