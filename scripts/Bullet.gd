extends Area2D

var vel: Vector2 = Vector2.ZERO
var life: float = 0.55
var dmg: float = 16.0
var pierce: int = 0
var homing: float = 0.0
var lock_only: bool = false
var darkroom: bool = false
var source: String = "gun"

func _ready() -> void:
	add_to_group("bullets")
	z_index = 6
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture == null:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if ResourceLoader.exists("res://sprites/projectile.png"):
			sprite.texture = load("res://sprites/projectile.png")

func _physics_process(delta: float) -> void:
	if homing > 0.0:
		var best: Node2D = null
		var best_d := 220.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.get("phase") == "hide":
				continue
			if lock_only and float(e.get("painted_until")) <= Time.get_ticks_msec() * 0.001:
				continue
			var d: float = global_position.distance_to(e.global_position)
			if d < best_d:
				best_d = d
				best = e
		if best:
			var spd := vel.length()
			var dir := (best.global_position - global_position).normalized()
			vel += dir * homing * spd * delta
			vel = vel.normalized() * spd
	position += vel * delta
	life -= delta
	rotation = vel.angle()
	if life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var amount := dmg
		if darkroom:
			var player := get_tree().get_first_node_in_group("player")
			var vis = player.get("vision") if player != null else null
			if vis == null or not vis.contains_point(body.global_position):
				amount = 0.0
			else:
				amount = dmg
		body.take_damage(amount, source)
		if pierce > 0:
			pierce -= 1
		else:
			queue_free()
