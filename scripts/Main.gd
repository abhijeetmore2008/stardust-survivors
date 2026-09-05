extends Node2D

const TILE := 48
const MAP := 44

@onready var ground: Node2D = $Ground
@onready var props: Node2D = $Props
@onready var title: CanvasLayer = $TitleScreen

func _ready() -> void:
	GameManager.reset()
	GameManager.started = false
	_build_ground()
	_build_props()
	title.visible = true
	$TitleScreen/Panel/Deploy.pressed.connect(_on_deploy)

func _on_deploy() -> void:
	title.visible = false
	GameManager.start_run()

func _build_ground() -> void:
	var tiles: Array[Texture2D] = []
	for r in range(4):
		for c in range(4):
			tiles.append(load("res://sprites/tiles/tile-%d-%d.png" % [r, c]))
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
	var sheet: Texture2D = load("res://sprites/props.png")
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
	if cell < 3:
		var body := StaticBody2D.new()
		var col := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 22.0 if cell < 3 else 12.0
		col.shape = circle
		body.add_child(col)
		s.add_child(body)
