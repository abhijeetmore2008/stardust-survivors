extends Node2D

@export var cone_angle_deg: float = 48.0
@export var cone_range: float = 170.0

var radius_px: float = 108.0
var broadcasting: bool = false
var super_on: bool = false
var flicker: bool = false
var t: float = 0.0

func _process(delta: float) -> void:
	t += delta
	look_at(get_global_mouse_position())
	var player := get_parent()
	visible = player != null and GameManager.started and GameManager.state != GameManager.State.GAME_OVER
	queue_redraw()

func _alpha() -> float:
	var a := 0.18
	if broadcasting:
		a = 0.34
	if super_on:
		a = 0.46
	if flicker:
		a *= 0.62 + 0.38 * absf(sin(t * 7.5))
	return a

func _draw() -> void:
	if not visible:
		return
	var a := _alpha()
	for i in 4:
		var f := 1.0 - float(i) / 4.0
		var rr := radius_px * (0.55 + 0.45 * f)
		draw_circle(Vector2.ZERO, rr, Color(0.45, 0.85, 1.0, (0.035 + a * 0.06) * f))
	draw_arc(Vector2.ZERO, radius_px, 0.0, TAU, 64, Color(0.7, 0.95, 1.0, 0.28 + a * 0.3), 2.2, true)
	var half_angle := deg_to_rad(cone_angle_deg * 0.5)
	var layers := 3
	for layer in layers:
		var fall := 1.0 - float(layer) / float(layers)
		var reach := cone_range * (0.55 + 0.45 * fall)
		var points := PackedVector2Array([Vector2.ZERO])
		for i in range(36):
			var ang := -half_angle + (half_angle * 2.0) * float(i) / 35.0
			points.append(Vector2(cos(ang), sin(ang)) * reach)
		var fill := Color(0.55, 0.92, 1.0, a * (0.22 + 0.28 * fall))
		if super_on:
			fill = Color(0.85, 0.98, 1.0, a * (0.28 + 0.32 * fall))
		draw_colored_polygon(points, fill)
	var rim := PackedVector2Array([Vector2.ZERO])
	for i in range(36):
		var ang := -half_angle + (half_angle * 2.0) * float(i) / 35.0
		rim.append(Vector2(cos(ang), sin(ang)) * cone_range)
	draw_polyline(rim, Color(0.85, 1.0, 1.0, 0.5 + a * 0.4), 2.0, true)
	var spark_n := 6 if broadcasting or super_on else 3
	for i in spark_n:
		var u := fmod(t * 0.35 + float(i) * 0.17, 1.0)
		var ang := -half_angle + (half_angle * 2.0) * (0.15 + 0.7 * absf(sin(t + i)))
		var pt := Vector2(cos(ang), sin(ang)) * (cone_range * u)
		draw_circle(pt, 1.6 + 1.2 * (1.0 - u), Color(1, 1, 1, 0.35 * (1.0 - u) + a * 0.25))

func contains_point(global_point: Vector2) -> bool:
	var to_target := global_point - global_position
	if to_target.length() > cone_range:
		return false
	var facing := Vector2.RIGHT.rotated(global_rotation)
	return abs(facing.angle_to(to_target)) <= deg_to_rad(cone_angle_deg * 0.5)

func overlaps_circle(center: Vector2, radius: float) -> bool:
	var to := center - global_position
	var dist := to.length()
	if dist <= radius:
		return true
	if dist > cone_range + radius:
		return false
	var facing := Vector2.RIGHT.rotated(global_rotation)
	var ang: float = absf(facing.angle_to(to))
	var extra: float = asin(clampf(radius / maxf(dist, 0.001), 0.0, 1.0))
	return ang <= deg_to_rad(cone_angle_deg * 0.5) + extra

func in_radius(global_point: Vector2) -> bool:
	return global_position.distance_to(global_point) <= radius_px
