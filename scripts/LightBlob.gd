extends Node2D

var radius: float = 130.0
var col := Color(1.0, 0.78, 0.35, 0.22)
var pulse: float = 0.0
var glow: Texture2D

func _ready() -> void:
	z_index = 0
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var c := 48.0
	for y in 96:
		for x in 96:
			var d := Vector2(x - c, y - c).length() / c
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	glow = ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	pulse += delta * 2.4
	queue_redraw()

func _draw() -> void:
	var r := radius * (1.0 + 0.05 * sin(pulse))
	if glow:
		var rect := Rect2(Vector2(-r, -r), Vector2(r * 2.0, r * 2.0))
		draw_texture_rect(glow, rect, false, Color(col.r, col.g, col.b, 0.55))
		draw_texture_rect(glow, Rect2(Vector2(-22, -22), Vector2(44, 44)), false, Color(1.0, 0.95, 0.7, 0.45 + 0.12 * sin(pulse * 3.0)))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.92, 0.55, 0.7))
