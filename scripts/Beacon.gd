extends Node2D

var kind: String = "puck"
var life: float = 4.0
var radius: float = 90.0
var tick: float = 0.0

func _ready() -> void:
	add_to_group("beacons")
	z_index = 0

func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	life -= delta
	tick -= delta
	queue_redraw()
	if kind == "turret" and tick <= 0.0:
		tick = 0.16
		var player := get_tree().get_first_node_in_group("player")
		var dmg := 8.0
		if player != null and "damage" in player:
			dmg = float(player.damage) * 0.22
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.get("phase") == "hide":
				continue
			if global_position.distance_to(e.global_position) <= radius and e.has_method("take_damage"):
				e.take_damage(dmg, "signal")
	if life <= 0.0:
		queue_free()

func _draw() -> void:
	var a := clampf(life / 4.0, 0.15, 1.0)
	var c := Color(0.45, 0.92, 1.0, 0.16 * a)
	if kind == "spark":
		c = Color(0.75, 0.95, 1.0, 0.22 * a)
	elif kind == "turret":
		c = Color(0.7, 0.55, 1.0, 0.18 * a)
	draw_circle(Vector2.ZERO, radius, c)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, Color(c.r, c.g, c.b, 0.55 * a), 2.0, true)
	draw_circle(Vector2.ZERO, 6.0, Color(1, 1, 1, 0.7 * a))
