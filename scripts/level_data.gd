extends LevelManager

const LEVELS_DIR := "res://levels"

func _build_levels() -> void:
	level_list.clear()
	
	if not DirAccess.dir_exists_absolute(LEVELS_DIR):
		push_error("Levels folder not found: " + LEVELS_DIR)
		return
		
	var files := Array(DirAccess.get_files_at(LEVELS_DIR))
	files = files.filter(func(f: String) -> bool: return f.ends_with(".json"))
	files.sort() 
	
	for file_name: String in files:
		var path := LEVELS_DIR.path_join(file_name)
		var raw_text := FileAccess.get_file_as_string(path)
		var parsed = JSON.parse_string(raw_text)
		
		if typeof(parsed) != TYPE_DICTIONARY:
			push_error("Invalid JSON in level file: " + path)
			continue
			
		level_list.append(_parse_level(parsed))

func _parse_level(lvl_dict: Dictionary) -> Level:
	var events: Array[LevelEvent] = []
	
	for ev_dict in lvl_dict.get("events", []):
		var trigger_name: String = ev_dict.get("trigger", "LEVEL_START")
		var trigger: TriggerType = TriggerType.get(trigger_name, TriggerType.LEVEL_START)
		var target: Variant = ev_dict.get("target", null)
		var one_shot: bool = ev_dict.get("one_shot", true)
		
		var actions: Array[LevelAction] = []
		for act_dict in ev_dict.get("actions", []):
			var parsed_act := _parse_action(act_dict)
			if parsed_act:
				actions.append(parsed_act)
				
		events.append(LevelEvent.new(trigger, target, actions, one_shot))
		
	return Level.new(events)

func _parse_action(d: Dictionary) -> LevelAction:
	match d.get("type", ""):
		"DIALOGUE":
			return LevelAction.dialogue(d.get("lines", []),d.get("id", ""))
		"SPAWN":
			var waves: Array[SingleWave] = []
			for w in d.get("waves", []):
				waves.append(SingleWave.new(w[0], w[1], w[2]))
				
			var drift_name: String = d.get("drift", "NONE")
			var drift: CompositeWave.DriftMode = CompositeWave.DriftMode.get(drift_name, CompositeWave.DriftMode.NONE)
			
			var atk := Attack.new(
				d["id"],
				d.get("angle", 90.0),
				waves,
				d.get("speed", 1.0),
				d.get("eta", 90),
				drift
			)
			return LevelAction.spawn(atk)
		"START_TIMER":
			return LevelAction.start_timer(d["id"], d["duration"])
		"CANCEL_TIMER":
			return LevelAction.cancel_timer(d["id"])
		"DISABLE_EVENT":
			return LevelAction.disable_event(d["id"])
			
	push_warning("Unknown action type in JSON: " + str(d))
	return null
