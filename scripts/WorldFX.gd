extends Node2D

var pollen: Array = []
var pulse: float = 0.0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 56:
		pollen.append({
			"p": Vector2(rng.randf() * LevelGen.MAP_W * LevelGen.TILE, rng.randf() * LevelGen.MAP_H * LevelGen.TILE),
			"s": 0.6 + rng.randf() * 1.6,
			"v": Vector2(8.0 + rng.randf() * 14.0, -6.0 - rng.randf() * 10.0),
			"ph": rng.randf() * TAU,
		})

func _process(delta: float) -> void:
	pulse += delta
	var bounds := Vector2(LevelGen.MAP_W * LevelGen.TILE, LevelGen.MAP_H * LevelGen.TILE)
	for d in pollen:
		d.p += d.v * delta
		d.ph += delta * 1.4
		if d.p.x > bounds.x:
			d.p.x = 0.0
		if d.p.y < 0.0:
			d.p.y = bounds.y
	queue_redraw()

func _draw() -> void:
	if not GameManager.started:
		return
	for d in pollen:
		var a := 0.18 + 0.16 * sin(d.ph)
		draw_circle(d.p, d.s, Color(1.0, 0.95, 0.7, a))
	for puff in GameManager.puffs:
		var a := clampf(float(puff.t) / 0.42, 0.0, 1.0)
		var pp := to_local(puff.p)
		draw_arc(pp, 8.0 + (1.0 - a) * 22.0, 0.0, TAU, 24, Color(1.0, 0.85, 0.55, 0.55 * a), 2.0, true)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and player.get("stains") != null:
		for s in player.stains:
			var sp := to_local(s.pos)
			var a := clampf(float(s.life) / 2.1, 0.0, 1.0)
			draw_circle(sp, float(s.r), Color(0.45, 0.85, 1.0, 0.12 * a))
	var sun := Vector2(12.0, 9.0)
	if player:
		var lp := to_local(player.global_position) + sun
		draw_set_transform(lp, 0.0, Vector2(1.25, 0.32))
		draw_circle(Vector2.ZERO, 13.0, Color(0, 0, 0, 0.3))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("phase") == "hide" and str(e.get("kind")) != "mimic":
			continue
		var ep := to_local(e.global_position) + sun
		draw_set_transform(ep, 0.0, Vector2(1.25, 0.32))
		var er := 18.0 if str(e.get("kind")) == "giant" else 11.0
		draw_circle(Vector2.ZERO, er, Color(0, 0, 0, 0.26))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for n in get_tree().get_nodes_in_group("scenery"):
		var sp := to_local(n.global_position)
		var sr := 16.0
		if n.has_meta("shadow_r"):
			sr = float(n.get_meta("shadow_r"))
		draw_set_transform(sp + sun * 0.35, 0.0, Vector2(1.15, 0.42))
		draw_circle(Vector2.ZERO, sr * 1.15, Color(0, 0, 0, 0.16))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_set_transform(sp + sun, 0.0, Vector2(1.28, 0.3))
		draw_circle(Vector2.ZERO, sr, Color(0, 0, 0, 0.24))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var gates := get_tree().get_nodes_in_group("gate")
	if gates.is_empty():
		return
	var g: Node2D = gates[0]
	var gp := to_local(g.global_position)
	var lock_r := GameManager.GATE_LOCK_R
	var open := GameManager.gate_open
	var col := Color(0.45, 0.85, 1.0, 0.16) if open else Color(1.0, 0.35, 0.3, 0.12)
	if GameManager.holding_gate:
		col = Color(0.7, 0.98, 1.0, 0.32 + 0.1 * sin(pulse * 6.0))
	draw_arc(gp, lock_r, 0.0, TAU, 64, Color(col.r, col.g, col.b, col.a + 0.25), 3.0, true)
	draw_circle(gp, lock_r, col)
	if GameManager.hold_progress > 0.01:
		var span := TAU * GameManager.hold_progress
		draw_arc(gp, lock_r + 8.0, -PI / 2.0, -PI / 2.0 + span, 48, Color(0.85, 1.0, 1.0, 0.95), 4.0, true)
