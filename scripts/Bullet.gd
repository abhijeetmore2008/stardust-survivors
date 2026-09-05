extends Area2D

var vel: Vector2 = Vector2.ZERO
var life: float = 0.55
var dmg: float = 16.0

func _ready() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite and sprite.texture == null:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if ResourceLoader.exists("res://sprites/projectile.png"):
			sprite.texture = load("res://sprites/projectile.png")
		elif ResourceLoader.exists("res://assets/sprites/projectile.png"):
			sprite.texture = load("res://assets/sprites/projectile.png")

func _physics_process(delta: float) -> void:
	position += vel * delta
	life -= delta
	rotation = vel.angle()
	if life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(dmg)
		queue_free()
