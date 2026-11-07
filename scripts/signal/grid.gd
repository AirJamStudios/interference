extends Control
class_name OscilloscopeGrid

@export var grid_color: Color = Color.html("#0E3A16")
@export var axis_color: Color = Color.html("#195E26")
@export var columns: int = 10
@export var rows: int = 8
@export var line_width: float = 1.0
@export var show_center_cross: bool = true

func _ready() -> void:
	# Fill parent
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var cell_width: float = size.x / columns
	var cell_height: float = size.y / rows
	
	# Vertical lines
	for i in range(1, columns):
		var x: float = i * cell_width
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, line_width)
		
	# Hoz lines
	for j in range(1, rows):
		var y: float = j * cell_height
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, line_width)
		
	# Center axis and ticks
	if show_center_cross:
		var center_x: float = size.x / 2.0
		var center_y: float = size.y / 2.0
		
		draw_line(Vector2(center_x, 0), Vector2(center_x, size.y), axis_color, line_width * 1.5)
		draw_line(Vector2(0, center_y), Vector2(size.x, center_y), axis_color, line_width * 1.5)
		
		var tick_size: float = 4.0
		var sub_divisions: int = 5
		
		var x_step: float = cell_width / sub_divisions
		for i in range(columns * sub_divisions):
			var tx: float = i * x_step
			draw_line(Vector2(tx, center_y - tick_size), Vector2(tx, center_y + tick_size), axis_color, line_width)
			
		var y_step: float = cell_height / sub_divisions
		for j in range(rows * sub_divisions):
			var ty: float = j * y_step
			draw_line(Vector2(center_x - tick_size, ty), Vector2(center_x + tick_size, ty), axis_color, line_width)
