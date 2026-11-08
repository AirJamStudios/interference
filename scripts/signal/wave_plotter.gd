class_name WavePlotter
extends Line2D

var wave: Wave

@export_group("Wave Aspect")
@export var wave_color: Color = Color.html("#33FF33")
@export var line_thickness: float = 1.5
@export_range(0.0, 1.0) var dim_amount: float = 0.6

@export_group("Time Domain")
@export var t_min: float = -10.0
@export var t_max: float = 10.0
@export var dt: float = 0.05

var _dimmed: bool = false

func _ready() -> void:
	width = line_thickness
	set_dimmed(_dimmed)
	position = Vector2.ZERO


#Plot total wave
func redraw_plot() -> void:
	# Clear first so a removed wave also disappears from the screen
	clear_points()
	if not wave: return
	var panel_size: Vector2 = get_parent().size

	var t = t_min
	while t <= t_max:
		var y = wave.sample(t)

		var percentage = (t - t_min) / (t_max - t_min)
		var x_pixel = percentage * panel_size.x

		var amplitude_scale = panel_size.y * 0.5
		var y_pixel = (panel_size.y / 2.0) - (y * amplitude_scale)

		add_point(Vector2(x_pixel, y_pixel))
		t += dt


func set_wave(wave_in: Wave) -> void:
	wave = wave_in


func set_dimmed(dimmed: bool) -> void:
	_dimmed = dimmed
	default_color = wave_color.darkened(dim_amount) if dimmed else wave_color
