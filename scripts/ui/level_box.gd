class_name LevelBox
extends PanelContainer

signal selected(index: int)

@export var gold_star: Texture2D
@export var gray_star: Texture2D

#TODO the lock icon and logic


@export_group("UI References")
@export var number_label: Label
@export var unlocked_box: VBoxContainer
@export var lock_icon: TextureRect
@export var time_label: Label
@export var button: Button
@export var stars: Array[TextureRect] = []

var _index: int = 0

func setup(index: int, info: Dictionary) -> void:
	_index = index
	number_label.text = str(index + 1)
	
	var unlocked: bool = info.get("unlocked", false)
	unlocked_box.visible = unlocked
	lock_icon.visible = not unlocked
	button.disabled = not unlocked
	
	#TODO: display the time of the level with best stars
	if unlocked:
		var earned: int = info.get("stars", 0)
		for i in range(3):
			stars[i].texture = gold_star if i < earned else gray_star
			
		var t: float = info.get("best_time", -1.0)
		if t >= 0.0:
			time_label.text = "%d:%02d" % [int(t) / 60, int(t) % 60]
		else:
			time_label.text = "--:--"

func _on_button_pressed() -> void:
	selected.emit(_index)
