class_name WaveSelectionPanel
extends Node3D

signal minus_pressed
signal plus_pressed
signal left_pressed
signal right_pressed

@export var left_button: PressButton3D
@export var right_button: PressButton3D
@export var minus_button: PressButton3D
@export var plus_button: PressButton3D


func _ready() -> void:
	left_button.pressed.connect(func(): left_pressed.emit())
	right_button.pressed.connect(func(): right_pressed.emit())
	minus_button.pressed.connect(func(): minus_pressed.emit())
	plus_button.pressed.connect(func(): plus_pressed.emit())
