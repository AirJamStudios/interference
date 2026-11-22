extends "res://scripts/level_manager.gd"

func _build_levels() ->void:
	level_list = [

		#! TUTORIAL LEVEL: TEACHES KNOBS
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "OH MY GOD, WE'RE UNDER ATTACK!"},
					{"speaker": "Soldier", "text": "Look at the rada, contacts are popping up everywhere! They're closing in fast!"},
					{"speaker": "Soldier", "text": "[SYSTEM ALERT: Automated Electronic Warfare offline. Manual Antenna & Radar arrays operational.]"},
					{"speaker": "Soldier", "text": "Our auto-jammers are fried! We have to manually match their signal frequencies to cancel them out!"},
					{"speaker": "Soldier", "text": "Recon drones approaching from the South! Jam them before they lock our coordinates!"},
					{"speaker": "Soldier", "text": "Twist the AMPLITUDE knob until the two waves match up! Just keep turning them till it works!"}]),
				LevelAction.spawn(Attack.new("drone_1", 90.0, [SingleWave.new(0.2, 0.4, 0.0)], 1.0, 90)),
				LevelAction.spawn(Attack.new("drone_2", 80.0, [SingleWave.new(0.6, 0.4, 0.0)], 1.0, 90)),
				LevelAction.spawn(Attack.new("drone_3", 105.0, [SingleWave.new(1.0, 0.4, 0.0)], 1.0, 90)),
				LevelAction.start_timer("hurry_warning", 45.0)
			]),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "drone_3", [
				LevelAction.cancel_timer("hurry_warning"),
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Good job! Theres more drones incoming, but we can handle them!"},
					{"speaker": "Soldier", "text": "Twist the FREQUENCY knob until the two waves match up!"}
				]),
				LevelAction.spawn(Attack.new("drone_4", 110.0, [SingleWave.new(1.0, 0.2, 0.0)], 1.0, 90)),
				LevelAction.spawn(Attack.new("drone_5", 120.0, [SingleWave.new(1.0, 0.8, 0.0)], 1.0, 90)),
				LevelAction.spawn(Attack.new("drone_6", 130.0, [SingleWave.new(1.0, 0.05, 0.0)], 1.0, 90)),
			]),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "drone_6", [
				LevelAction.cancel_timer("hurry_warning"),
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Good job! Theres more drones incoming, but we can handle them!"},
					{"speaker": "Soldier", "text": "Twist the PHASE knob until the two waves match up!"}
				]),
				LevelAction.spawn(Attack.new("drone_7", 30.0, [SingleWave.new(1.0, 0.05, 0.5)], 1.0, 90)),
				LevelAction.spawn(Attack.new("drone_8", 50.0, [SingleWave.new(1.0, 0.05, 0.2)], 1.0, 90)),
				LevelAction.spawn(Attack.new("drone_9", 60.0, [SingleWave.new(1.0, 0.05, 0.8)], 1.0, 90)),
			]),
		]),

		#! TUTORIAL LEVEL: TEACHES TIME CHANGE
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),


		#! TUTORIAL LEVEL: TEACHES TWO WAVES
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a heavy bomber's on the radar, and its signal is double layered!"},
					{"speaker": "Soldier", "text": "One wave won't be enough!"},
				]),
				LevelAction.spawn(Attack.new("bomber_2", 20.0, [SingleWave.new(1.0, 0.05, 0.0), SingleWave.new(0.25, 0.9, 0.0)], 1.0, 90)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_2", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),

		Level.new([
			# 1 spawn recon
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Recon drone inbound! Jam it!"}]),
				LevelAction.spawn(Attack.new("drone_1", 90.0, [SingleWave.new(0.2, 0.4, 0.0)], 1.0, 90)),
				LevelAction.start_timer("hurry_warning", 15.0)
			]),

			# 2. 15swarning
			LevelEvent.new(TriggerType.TIMER_COMPLETED, "hurry_warning", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Hurry up, it's getting close!"}])
			]),

			# 3A. defeated drone_1 -> cancel hurry timer and start ambush
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "drone_1", [
				LevelAction.cancel_timer("hurry_warning"),
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}]),
				LevelAction.start_timer("ambush_timer", 5.0)
			]),

			# 3B. (Hit): drone_1 hit us -> cancel hurry timer & disable ambush event
			LevelEvent.new(TriggerType.ATTACK_REACHED, "drone_1", [
				LevelAction.cancel_timer("hurry_warning"),
				LevelAction.disable_event("ambush_event"),
				LevelAction.dialogue([{"speaker": "Soldier", "text": "We took a hit! Falling back to defensive scan."}])
			]),

			# 4. Ambush spawns 5s after drone_1 is defeated (never runs if Branch B disabled it)
			LevelEvent.new(TriggerType.TIMER_COMPLETED, "ambush_timer", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Ambush! Two signals just popped up!"},
				{"speaker": "Soldier", "text": "Quick, switch to the one thats closing in fast using the radar dial!"}]),
				LevelAction.spawn(Attack.new("drone_2", 120.0, [SingleWave.new(0.5, 0.2, 0.0)], 1.0, 80)),
				LevelAction.spawn(Attack.new("drone_3", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 30))
			], true, "ambush_event")
		]),
		Level.new([
			# carrier spawn
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Heavy carrier drone on a suicide run—ETA 3 minutes!"},
					{"speaker": "Soldier", "text": "It's launching cruise missiles! Jam the missiles or take down the carrier to stop the launches!"}
				]),
				LevelAction.spawn(Attack.new("carrier", 180.0, [SingleWave.new(1.0, 0.05, 0.2,), SingleWave.new(0.25, 0.7, 0.5)], 1.0, 180.0, CompositeWave.DriftMode.AMPLITUDE)),
				LevelAction.start_timer("m1_timer", 2.0)
			]),

			# missiles 1-4
			LevelEvent.new(TriggerType.TIMER_COMPLETED, "m1_timer", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Cruise missile launched! Jam it before impact!"}]),
				LevelAction.spawn(Attack.new("missile_1", 170.0, [SingleWave.new(0.3, 0.5, 0.0)], 0.9, 90.0)),
				LevelAction.start_timer("m2_timer", 30.0)
			], true, "ev_m1"),
			LevelEvent.new(TriggerType.TIMER_COMPLETED, "m2_timer", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Halfway through its payload! Keep tracking that carrier!"}]),
				LevelAction.spawn(Attack.new("missile_2", 190.0, [SingleWave.new(0.7, 0.4, 0.0)], 0.85, 75.0)),
				LevelAction.start_timer("m3_timer", 30.0)
			], true, "ev_m2"),
			LevelEvent.new(TriggerType.TIMER_COMPLETED, "m3_timer", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Another cruise missile launched! Jam it before impact!"}]),
				LevelAction.spawn(Attack.new("missile_3", 165.0, [SingleWave.new(0.5, 0.6, 0.0)], 0.8, 60.0)),
				LevelAction.start_timer("m4_timer", 30.0)
			], true, "ev_m3"),
			LevelEvent.new(TriggerType.TIMER_COMPLETED, "m4_timer", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "This must be the last cruise missile! It's coming in hot"}]),
				LevelAction.spawn(Attack.new("missile_4", 195.0, [SingleWave.new(0.9, 0.3, 0.0)], 0.75, 45.0)),
			], true, "ev_m4"),

			# defeated carrier
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "carrier", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Carrier signal fried! No more missiles incoming!"}]),
				LevelAction.cancel_timer("m1_timer"), LevelAction.disable_event("ev_m1"),
				LevelAction.cancel_timer("m2_timer"), LevelAction.disable_event("ev_m2"),
				LevelAction.cancel_timer("m3_timer"), LevelAction.disable_event("ev_m3"),
				LevelAction.cancel_timer("m4_timer"), LevelAction.disable_event("ev_m4")
			]),

			# carrier reached player
			LevelEvent.new(TriggerType.ATTACK_REACHED, "carrier", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "CRITICAL HIT! The carrier slammed into us!"}]),
				LevelAction.cancel_timer("m1_timer"), LevelAction.disable_event("ev_m1"),
				LevelAction.cancel_timer("m2_timer"), LevelAction.disable_event("ev_m2"),
				LevelAction.cancel_timer("m3_timer"), LevelAction.disable_event("ev_m3"),
				LevelAction.cancel_timer("m4_timer"), LevelAction.disable_event("ev_m4")
			]),

			# missile reached
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Cruise missile impact!"}])
			], false)
		]),

		# DUMMY LEVEL FILLERS BELLOW FOR UI
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),
		Level.new([
			LevelEvent.new(TriggerType.LEVEL_START, null, [
				LevelAction.dialogue([
					{"speaker": "Soldier", "text": "Wait, a strike aircraft is on the radar, and its signal is shifting on its own!"},
					{"speaker": "Soldier", "text": "Don't let it slip away, keep twisting the knobs to track its movement"},
				]),
				LevelAction.spawn(Attack.new("bomber_1", 130.0, [SingleWave.new(1.0, 0.1, 0.5)], 1.0, 50, CompositeWave.DriftMode.AMPLITUDE)),
			]),
			LevelEvent.new(TriggerType.ATTACK_REACHED, null, [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "It's direcely over us we are doomed..."}])
			], false),
			LevelEvent.new(TriggerType.ATTACK_DEFEATED, "bomber_1", [
				LevelAction.dialogue([{"speaker": "Soldier", "text": "Good job! Area clear... for now."}])
			]),
		]),

	]
