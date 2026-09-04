extends Control

@export var heart_size: float = 22.0
@export var heart_spacing: float = 26.0
@export var hp_per_heart: float = 20.0

var full_color := Color(0.85, 0.18, 0.18, 1)
var empty_color := Color(0.22, 0.1, 0.1, 1)
var outline_color := Color(0.12, 0.06, 0.06, 1)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var total_hearts := int(ceil(player.max_hp / hp_per_heart))
	var full_hearts := int(floor(player.hp / hp_per_heart))
	for i in range(total_hearts):
		var origin := Vector2(i * heart_spacing, 0.0)
		_draw_heart(origin, heart_size, full_color if i < full_hearts else empty_color)

func _draw_heart(origin: Vector2, size: float, color: Color) -> void:
	var s := size / 16.0
	var pts := PackedVector2Array([
		Vector2(8, 15), Vector2(2, 9), Vector2(1, 6), Vector2(2, 3),
		Vector2(5, 2), Vector2(8, 5), Vector2(11, 2), Vector2(14, 3),
		Vector2(15, 6), Vector2(14, 9)
	])
	var scaled := PackedVector2Array()
	for p in pts:
		scaled.append(origin + p * s)
	draw_colored_polygon(scaled, color)
	var closed := scaled.duplicate()
	closed.append(scaled[0])
	draw_polyline(closed, outline_color, maxf(1.0, s))