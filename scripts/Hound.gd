extends Node2D

var ang: float = 0.0
var bark_cd: float = 0.0
var sprite: Sprite2D

func _ready() -> void:
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists("res://sprites/rusher.png"):
		sprite.texture = load("res://sprites/rusher.png")
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.frame = 0
	sprite.scale = Vector2(0.30, 0.30)
	sprite.centered = true
	var h := 96.0
	if sprite.texture:
		h = float(sprite.texture.get_height()) / maxf(1.0, float(sprite.vframes))
	sprite.offset.y = -h * 0.45
	sprite.modulate = Color(0.85, 0.72, 0.45, 1)
	add_child(sprite)

func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	ang += delta * 2.1
	position = Vector2(cos(ang) * 26.0, sin(ang) * 16.0)
	bark_cd = maxf(0.0, bark_cd - delta)
	if bark_cd > 0.0:
		sprite.modulate = Color(1.0, 0.9, 0.4)
	else:
		sprite.modulate = Color(0.85, 0.72, 0.45, 1)
	if bark_cd > 0.0:
		return
	var origin: Vector2 = get_parent().global_position
	for e in get_tree().get_nodes_in_group("enemies"):
		if str(e.get("kind")) != "mimic":
			continue
		if e.get("phase") != "hide":
			continue
		if origin.distance_to(e.global_position) < 140.0:
			bark_cd = 2.2
			Audio.play("ping", -10.0, 0.8)
			if e.has_method("ping_flash"):
				e.ping_flash()
			break
