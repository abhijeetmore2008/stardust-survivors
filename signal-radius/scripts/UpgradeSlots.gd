extends Control

@export var slot_size: float = 40.0
@export var slot_spacing: float = 46.0
@export var slot_count: int = 5

var frame_color := Color(0.42, 0.13, 0.13, 1)
var bg_color := Color(0.1, 0.06, 0.05, 0.9)
var fill_color := Color(0.28, 0.45, 0.26, 1)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var owned := 0
	if player != null and "acquired_upgrades" in player:
		owned = player.acquired_upgrades.size()
	for i in range(slot_count):
		var pos := Vector2(i * slot_spacing, 0.0)
		var rect := Rect2(pos, Vector2(slot_size, slot_size))
		draw_rect(rect, bg_color, true)
		draw_rect(rect, frame_color, false, 2.0)
		if i < owned:
			draw_rect(Rect2(pos + Vector2(6, 6), Vector2(slot_size - 12, slot_size - 12)), fill_color, true)