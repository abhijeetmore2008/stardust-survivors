extends Node2D

const TILE := 48
const MAP := 44

@onready var ground: Node2D = $Ground
@onready var props: Node2D = $Props

var title_layer: CanvasLayer

func _ready() -> void:
	GameManager.reset()
	GameManager.started = false
	_build_ground()
	_build_props()
	_build_title()

func _on_deploy() -> void:
	if title_layer:
		title_layer.visible = false
	GameManager.start_run()

func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var alt := path.replace("res://sprites/", "res://assets/sprites/")
	if ResourceLoader.exists(alt):
		return load(alt)
	return null

func _build_title() -> void:
	title_layer = CanvasLayer.new()
	title_layer.layer = 20
	add_child(title_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.22)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_layer.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(400, 190)
	panel.size = Vector2(480, 340)
	title_layer.add_child(panel)
	var title := Label.new()
	title.text = "Signal Radius"
	title.position = Vector2(24, 36)
	title.size = Vector2(432, 48)
	title.add_theme_font_size_override("font_size", 36)
	panel.add_child(title)
	var blurb := Label.new()
	blurb.text = "Hold the outpost. Your gun keeps the shades back. Chain kills to charge Signal — dump it for seven seconds of raw light.\n\nWASD move · mouse aim · hold click to fire\nFill combo, then F / B to drop Signal"
	blurb.position = Vector2(24, 96)
	blurb.size = Vector2(432, 140)
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(blurb)
	var deploy := Button.new()
	deploy.text = "Deploy"
	deploy.position = Vector2(24, 250)
	deploy.size = Vector2(432, 46)
	deploy.pressed.connect(_on_deploy)
	panel.add_child(deploy)

func _build_ground() -> void:
	var tiles: Array[Texture2D] = []
	for r in range(4):
		for c in range(4):
			tiles.append(_tex("res://sprites/tiles/tile-%d-%d.png" % [r, c]))
	if tiles[0] == null:
		return
	var origin := -MAP * TILE / 2
	for y in range(MAP):
		for x in range(MAP):
			var cx := x - MAP / 2.0
			var cy := y - MAP / 2.0
			var d := Vector2(cx, cy).length()
			var id := 0
			if d < 3.0:
				id = 8 + ((x + y) % 4)
			elif absf(cx) < 1.2 or absf(cy) < 1.2:
				id = 4 + ((x * 3 + y) % 4)
			elif (x * 13 + y * 7) % 17 == 0:
				id = 12 + ((x + y) % 4)
			else:
				id = (x * 5 + y * 3) % 4
			var s := Sprite2D.new()
			s.texture = tiles[id]
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.centered = false
			s.position = Vector2(origin + x * TILE + 640, origin + y * TILE + 360)
			s.scale = Vector2(TILE / 64.0, TILE / 64.0)
			ground.add_child(s)

func _build_props() -> void:
	var sheet := _tex("res://sprites/props.png")
	if sheet == null:
		return
	for i in range(70):
		var a := (i / 70.0) * TAU + (i % 5) * 0.2
		var r := 140.0 + (i % 9) * 70.0 + float((i * 17) % 40)
		var pos := Vector2(cos(a) * r, sin(a) * r) + Vector2(640, 360)
		if pos.distance_to(Vector2(640, 360)) < 90.0:
			continue
		var cell := 0 if i % 3 == 0 else (1 if i % 3 == 1 else 2)
		_add_prop(sheet, pos, cell, 3)
	for i in range(8):
		var a := (i / 8.0) * TAU
		_add_prop(sheet, Vector2(640, 360) + Vector2(cos(a), sin(a)) * 86.0, 5, 3)

func _add_prop(sheet: Texture2D, pos: Vector2, cell: int, cols: int) -> void:
	var s := Sprite2D.new()
	s.texture = sheet
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.hframes = cols
	s.vframes = cols
	s.frame = cell
	s.position = pos
	s.scale = Vector2(0.45, 0.45) if cell < 3 else Vector2(0.32, 0.32)
	props.add_child(s)
