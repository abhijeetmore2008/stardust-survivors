extends Node2D

var baked: Texture2D
var hill: Texture2D
var sun: Texture2D
var map_size := Vector2.ZERO

func _ready() -> void:
	z_index = -8
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hill = _make_hill()
	sun = _make_sun()

func _make_hill() -> ImageTexture:
	var img := Image.create(2, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var t := float(y) / 63.0
		var a := t * 0.18
		var c := Color(0.04, 0.08, 0.03, a)
		img.set_pixel(0, y, c)
		img.set_pixel(1, y, c)
	return ImageTexture.create_from_image(img)

func _make_sun() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var t := (float(x) + float(y)) / 126.0
			var a := 0.11 * (1.0 - t)
			img.set_pixel(x, y, Color(1.0, 0.93, 0.72, a))
	return ImageTexture.create_from_image(img)

func _img(path: String) -> Image:
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		if tex:
			var got: Image = tex.get_image()
			if got:
				got.convert(Image.FORMAT_RGBA8)
				return got
	var im := Image.new()
	if im.load(path) != OK:
		return null
	im.convert(Image.FORMAT_RGBA8)
	return im

func _blit_wrap(dst: Image, src: Image, dx: int, dy: int, dw: int, dh: int) -> void:
	if src == null or dw <= 0 or dh <= 0:
		return
	var sw: int = src.get_width()
	var sh: int = src.get_height()
	var sx: int = ((dx % sw) + sw) % sw
	var sy: int = ((dy % sh) + sh) % sh
	var cw: int = mini(dw, sw - sx)
	var ch: int = mini(dh, sh - sy)
	dst.blit_rect(src, Rect2i(sx, sy, cw, ch), Vector2i(dx, dy))
	if cw < dw:
		dst.blit_rect(src, Rect2i(0, sy, dw - cw, ch), Vector2i(dx + cw, dy))
	if ch < dh:
		dst.blit_rect(src, Rect2i(sx, 0, cw, dh - ch), Vector2i(dx, dy + ch))
	if cw < dw and ch < dh:
		dst.blit_rect(src, Rect2i(0, 0, dw - cw, dh - ch), Vector2i(dx + cw, dy + ch))

func build(level: Dictionary) -> void:
	var bid := "meadow"
	if level.has("biome") and typeof(level.biome) == TYPE_DICTIONARY:
		bid = str(level.biome.get("id", "meadow"))
	match bid:
		"gold":
			modulate = Color(1.07, 0.9, 0.62)
		"grove":
			modulate = Color(0.76, 0.9, 0.7)
		"harvest":
			modulate = Color(1.06, 0.84, 0.56)
		"dusk":
			modulate = Color(0.7, 0.68, 0.88)
		_:
			modulate = Color(1, 1, 1)
	var tsz: int = LevelGen.TILE
	var mw: int = LevelGen.MAP_W
	var mh: int = LevelGen.MAP_H
	var w: int = mw * tsz
	var h: int = mh * tsz
	map_size = Vector2(w, h)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.28, 0.42, 0.18, 1))
	var grass: Image = _img("res://sprites/terrain/grass-1.png")
	if grass == null:
		grass = _img("res://sprites/terrain/grass-0.png")
	if grass == null:
		grass = _img("res://sprites/tiles/tile-0-0.png")
	var dirt: Image = _img("res://sprites/terrain/dirt.png")
	var patch: Image = _img("res://sprites/terrain/dirt-patch.png")
	var path: Array = level.get("path", [])
	if grass:
		for ty in mh:
			for tx in mw:
				_blit_wrap(img, grass, tx * tsz, ty * tsz, tsz, tsz)
	if patch and path.size() == mh:
		var ps: int = patch.get_width()
		for ty in mh:
			for tx in mw:
				if tx >= (path[ty] as Array).size():
					continue
				if not bool(path[ty][tx]):
					continue
				var dx: int = tx * tsz + int(tsz * 0.5) - int(ps * 0.5)
				var dy: int = ty * tsz + int(tsz * 0.5) - int(ps * 0.5)
				img.blend_rect(patch, Rect2i(0, 0, ps, ps), Vector2i(dx, dy))
	if dirt and path.size() == mh:
		for ty in mh:
			for tx in mw:
				if tx >= (path[ty] as Array).size():
					continue
				if not bool(path[ty][tx]):
					continue
				_blit_wrap(img, dirt, tx * tsz, ty * tsz, tsz, tsz)
	baked = ImageTexture.create_from_image(img)
	queue_redraw()

func _draw() -> void:
	if baked:
		draw_texture(baked, Vector2.ZERO)
	if hill and map_size.x > 1.0:
		draw_texture_rect(hill, Rect2(Vector2.ZERO, map_size), false)
	if sun and map_size.x > 1.0:
		draw_texture_rect(sun, Rect2(Vector2.ZERO, map_size), false)
