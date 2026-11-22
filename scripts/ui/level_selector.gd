class_name LevelSelectUI
extends Control

signal level_chosen(index: int)
signal back_pressed

@export_group("References")
@export var card_scene: PackedScene
@export var grid: GridContainer
@export var level_manager: LevelManager

@export_group("References - Pagination UI")
@export var prev_button: Button
@export var next_button: Button
@export var page_label: Label

var _total_levels: int = 0
var _current_page: int = 0
var _cards: Array[LevelBox] = []

#4 rows with 3 columns
const items_per_page: int = 12

func _ready() -> void:
	prev_button.pressed.connect(_on_prev_button_pressed)
	next_button.pressed.connect(_on_next_button_pressed)
		
	for child in grid.get_children():
		child.queue_free()
		
	for i in range(items_per_page):
		var card: LevelBox = card_scene.instantiate()
		grid.add_child(card)
		card.selected.connect(func(idx: int): level_chosen.emit(idx))
		_cards.append(card)

func refresh_cards(total_levels: int) -> void:
	_total_levels = total_levels
	_current_page = clampi(_current_page, 0, _get_total_pages() - 1)
	_update_page()

func _update_page() -> void:
	var start_index: int = _current_page * items_per_page
	
	for i in range(items_per_page):
		var level_index := start_index + i
		var card := _cards[i]
		
		if level_index < _total_levels:
			card.modulate.a = 1.0
			card.mouse_filter = Control.MOUSE_FILTER_STOP
			card.setup(level_index, SaveLevelData.get_level_info(level_index))
		else:
			# keep the slot
			card.modulate.a = 0.0
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.button.disabled = true
			
	var total_pages := _get_total_pages()
	if page_label:
		page_label.text = "%d / %d" % [_current_page + 1, total_pages]
	if prev_button:
		prev_button.disabled = (_current_page == 0)
	if next_button:
		next_button.disabled = (_current_page >= total_pages - 1)

func _get_total_pages() -> int:
	return maxi(1, ceili(float(_total_levels) / items_per_page))

func _on_prev_button_pressed() -> void:
	if _current_page > 0:
		_current_page -= 1
		_update_page()

func _on_next_button_pressed() -> void:
	if _current_page < _get_total_pages() - 1:
		_current_page += 1
		_update_page()

func _on_back_button_pressed() -> void:
	back_pressed.emit()
