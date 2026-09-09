extends Object

const CREAM := Color("f6efe0")
const INK := Color("3b2a1c")
const MUTED := Color("6d5c4a")
const TERRACOTTA := Color("c45c32")
const MOSS := Color("5b7a38")
const WOOD := Color("6b3e22")
const CARD := Color("fffcf6")
const CARD_ON := Color("f3e4c4")
const LINE := Color("e2d3b6")

static func cream_panel() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = CREAM
	s.border_color = Color("623c22")
	s.set_border_width_all(12)
	s.set_corner_radius_all(8)
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 22
	s.content_margin_bottom = 18
	s.shadow_color = Color(0, 0, 0, 0.28)
	s.shadow_size = 18
	s.shadow_offset = Vector2(0, 8)
	return s

static func card(selected: bool = false, secondary: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color("e8dff8") if secondary else (CARD_ON if selected else CARD)
	s.border_color = Color("7a62c4") if secondary else (Color("c4a36a") if selected else LINE)
	s.border_width_left = 5 if selected or secondary else 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = MOSS if selected and not secondary else s.border_color
	if selected and not secondary:
		s.border_color = MOSS
		s.border_width_left = 5
	s.set_corner_radius_all(4)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

static func terra_btn() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = TERRACOTTA
	s.border_color = Color("8f3d1c")
	s.set_border_width_all(2)
	s.set_corner_radius_all(5)
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

static func wood_btn() -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	var path := "res://sprites/ui/wood-btn-strip.png"
	if not ResourceLoader.exists(path):
		path = "res://sprites/ui/wood-btn.png"
	if ResourceLoader.exists(path):
		s.texture = load(path)
	s.texture_margin_left = 48
	s.texture_margin_right = 48
	s.texture_margin_top = 18
	s.texture_margin_bottom = 18
	return s

static func ghost_btn() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.35)
	s.border_color = Color("c4b496")
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	return s

static func weapon_icon(id: String) -> AtlasTexture:
	var a := AtlasTexture.new()
	if ResourceLoader.exists("res://sprites/ui/weapons.png"):
		a.atlas = load("res://sprites/ui/weapons.png")
	var col := 0
	var row := 0
	match id:
		"bow":
			col = 1
		"scatter":
			row = 1
		"coil":
			col = 1
			row = 1
	a.region = Rect2(col * 128, row * 128, 128, 128)
	return a

static func add_landscape(parent: Node) -> void:
	var bg := TextureRect.new()
	bg.name = "Landscape"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_right = 1280
	bg.offset_bottom = 720
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://sprites/title.jpg"):
		bg.texture = load("res://sprites/title.jpg")
	parent.add_child(bg)

static func add_frame(host: Control, size: Vector2) -> void:
	var corner_tex: Texture2D = null
	if ResourceLoader.exists("res://sprites/ui/frame-corner.png"):
		corner_tex = load("res://sprites/ui/frame-corner.png")
	var edge_tex: Texture2D = null
	if ResourceLoader.exists("res://sprites/ui/frame-edge.png"):
		edge_tex = load("res://sprites/ui/frame-edge.png")
	var cs := 72.0
	var specs := [
		[Vector2(0, 0), false, false],
		[Vector2(1, 0), true, false],
		[Vector2(0, 1), false, true],
		[Vector2(1, 1), true, true],
	]
	for c in specs:
		var s := TextureRect.new()
		s.texture = corner_tex
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		s.flip_h = bool(c[1])
		s.flip_v = bool(c[2])
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.z_index = 4
		host.add_child(s)
		s.position = Vector2(float(c[0].x) * (size.x - cs), float(c[0].y) * (size.y - cs))
		s.size = Vector2(cs, cs)
	if edge_tex:
		for i in 2:
			var s := TextureRect.new()
			s.texture = edge_tex
			s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			s.stretch_mode = TextureRect.STRETCH_TILE
			s.mouse_filter = Control.MOUSE_FILTER_IGNORE
			s.z_index = 3
			host.add_child(s)
			s.position = Vector2(64, 10 if i == 0 else size.y - 24)
			s.size = Vector2(size.x - 128, 16)
		for i in 2:
			var s := TextureRect.new()
			s.texture = edge_tex
			s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			s.stretch_mode = TextureRect.STRETCH_TILE
			s.mouse_filter = Control.MOUSE_FILTER_IGNORE
			s.z_index = 3
			s.rotation_degrees = 90
			host.add_child(s)
			s.position = Vector2(26 if i == 0 else size.x - 10, 64)
			s.size = Vector2(size.y - 128, 16)
