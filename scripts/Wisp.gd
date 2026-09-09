extends Node2D

var hue: Color = Color(0.78, 1.0, 1.0, 0.95)
var radius: float = 5.0
var pulse: float = 0.0
var glow: Texture2D

func _ready() -> void:
	glow = _make_glow(48)

func _make_glow(size: int) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x - c, y - c).length() / c
			var a := clampf(1.0 - d, 0.0, 1.0)
			a = a * a * a
			img.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var r := 16.0 + 3.0 * sin(pulse * 3.2)
	if glow:
		draw_texture_rect(glow, Rect2(Vector2(-r, -r) * 1.6, Vector2(r, r) * 3.2), false, Color(hue.r, hue.g, hue.b, 0.55))
	draw_circle(Vector2.ZERO, radius + 1.4 * sin(pulse * 6.0), hue)
