extends Node2D

@export var cone_angle_deg: float = 45.0
@export var cone_range: float = 280.0

func _process(_delta: float) -> void:
	look_at(get_global_mouse_position())
	queue_redraw() 

func _draw() -> void:
	var half_angle := deg_to_rad(cone_angle_deg * 0.5)
	var points := PackedVector2Array([Vector2.ZERO])
	for i in range(29):
		var a := -half_angle + (half_angle * 2.0) * float(i) / 28.0
		points.append(Vector2(cos(a), sin(a)) * cone_range)
	draw_colored_polygon(points, Color(0.4, 0.9, 1.0, 0.12))
    
func contains_point(global_point: Vector2) -> bool:
	var to_target := global_point - global_position
	if to_target.length() > cone_range:
		return false
	var facing := Vector2.RIGHT.rotated(global_rotation)
	return abs(facing.angle_to(to_target)) <= deg_to_rad(cone_angle_deg * 0.5)