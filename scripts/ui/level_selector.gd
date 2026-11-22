class_name LevelSelectUI
extends Control

signal level_chosen(index: int)
signal back_pressed

@export var card_scene: PackedScene
@export var grid: GridContainer
@export var level_manager: LevelManager

func refresh_cards(total_levels: int) -> void:
	for child in grid.get_children():
		child.queue_free()
		
	for i in range(total_levels):
		var card: LevelBox = card_scene.instantiate()
		grid.add_child(card)
		card.setup(i, level_manager.get_level_info(i))
		card.selected.connect(func(idx: int): level_chosen.emit(idx))

func _on_back_button_pressed() -> void:
	back_pressed.emit()
