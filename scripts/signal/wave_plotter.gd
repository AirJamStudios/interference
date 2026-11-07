class_name WavePlotter
extends Line2D

var wave: Wave 

@export_group("Wave Aspect")
@export var wave_color: Color = Color.html("#33FF33")
@export var line_thickness: float = 1.5

@export_group("Time Domain")
@export var t_min: float = -10.0
@export var t_max: float = 10.0
@export var dt: float = 0.05    

func _ready() -> void:
	#Temporary color for wave
	width = line_thickness     
	default_color = wave_color
	position = Vector2.ZERO


#Plot total wave
func redraw_plot() -> void:
	if not wave: return
	clear_points()
	var panel_size: Vector2 = get_parent().size
	
	var t = t_min
	while t <= t_max:
		var y = wave.sample(t)		
		
		var percentage = (t - t_min) / (t_max - t_min)
		var x_pixel = percentage * panel_size.x
		
		# 0.5 so that when wave has amplitude of 1.0 it fills screen
		var amplitude_scale = panel_size.y * 0.5
		var y_pixel = (panel_size.y / 2.0) - (y * amplitude_scale)
		
		add_point(Vector2(x_pixel, y_pixel))
		t += dt


func set_wave(wave_in: Wave) -> void:
	wave = wave_in
