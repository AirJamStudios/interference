extends Line2D

var active_wave: Wave 

#TODO, differentiate displayed wave vs selected wave

@export var t_min: float = -10.0
@export var t_max: float = 10.0
@export var dt: float = 0.05    

func _ready() -> void:
	#Temporary color for wave
	width = 1.5               
	default_color = Color.BLUE
	
	# Tempory to test
	active_wave = SingleWave.new(1.0, 1.0, 0.0) 
	
	position = Vector2.ZERO
	redraw_plot()

func redraw_plot() -> void:
	clear_points()
	var panel_size: Vector2 = get_parent().size
	
	var t = t_min
	while t <= t_max:
		var y = active_wave.sample(t)
		
		var percentage = (t - t_min) / (t_max - t_min)
		var x_pixel = percentage * panel_size.x
		
		# 0.5 so that when wave has amplitude of 1.0 it fills screen
		var amplitude_scale = panel_size.y * 0.5
		var y_pixel = (panel_size.y / 2.0) - (y * amplitude_scale)
		
		add_point(Vector2(x_pixel, y_pixel))
		t += dt


# Signals to modify selected wave

func _on_amplitude_knob_value_changed(value: float) -> void:
	if active_wave:
		active_wave.amplitude = value
		redraw_plot()

func _on_freq_knob_value_changed(value: float) -> void:
	if active_wave:
		active_wave.frequency = lerpf(0.05, 2.0, value)
		redraw_plot()

func _on_phase_knob_value_changed(value: float) -> void:
	if active_wave:
		active_wave.phase = lerpf(0, 50.0, value)
		redraw_plot()