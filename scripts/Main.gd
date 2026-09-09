extends Node2D

const MenuSkin = preload("res://scripts/MenuSkin.gd")

@onready var ground: Node2D = $Ground
@onready var props: Node2D = $Props
@onready var player: Node2D = $Player
@onready var spawner: Node2D = $EnemySpawner

var title_layer: CanvasLayer
var outpost_layer: CanvasLayer
var fork_layer: CanvasLayer
var level: Dictionary = {}
var lit: Dictionary = {}
var taken_motes: Dictionary = {}
var taken_blooms: Dictionary = {}
var chests_open: Dictionary = {}
var way_attuned := false
var way_used := false
var world: Node2D
var gate_node: Sprite2D
var picked_weapon := "pulse"
var picked_weapon_b := ""
var daily_toggle := false
var clearing := false
var last_lit_pos := Vector2.ZERO
var sky: CanvasModulate
var ghost_line: Line2D
var weapon_btns: Array = []
var hold_need := 2.5
var wisp: Node2D
var wisp_home := Vector2.ZERO
var wisp_dark := 0.0
var wisp_done := false
var teach_step: int = 0
var teach_t: float = 0.0

func _ready() -> void:
	add_to_group("level_root")
	GameManager.reset()
	GameManager.started = false
	GameManager.level_applied.connect(_apply_level)
	GameManager.wave_cleared.connect(_on_cleared)
	GameManager.upgrade_picked.connect(_show_forks)
	if ground and ground.get_script() == null:
		ground.set_script(load("res://scripts/Terrain.gd"))
	if not world:
		world = Node2D.new()
		world.name = "World"
		world.y_sort_enabled = true
		world.z_index = 1
		add_child(world)
	if player.get_parent() != world:
		var keep := player.position
		remove_child(player)
		world.add_child(player)
		player.position = keep
	sky = CanvasModulate.new()
	add_child(sky)
	var fx := Node2D.new()
	fx.name = "FloorFX"
	fx.z_as_relative = false
	fx.z_index = -2
	fx.set_script(load("res://scripts/WorldFX.gd"))
	add_child(fx)
	fx.z_index = -2
	ghost_line = Line2D.new()
	ghost_line.width = 2.0
	ghost_line.default_color = Color(1, 1, 1, 0.18)
	ghost_line.z_index = 0
	add_child(ghost_line)
	_apply_level(1)
	_build_title()
	_build_outpost()
	_build_fork()

func _tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var im := Image.new()
	if im.load(path) == OK:
		return ImageTexture.create_from_image(im)
	return null

func _atlas(tex: Texture2D, col: int, row: int, cols: int, rows: int) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	if tex == null:
		return a
	var cw := tex.get_width() / cols
	var ch := tex.get_height() / rows
	a.region = Rect2(col * cw, row * ch, cw, ch)
	return a

func _apply_level(n: int) -> void:
	var biome_id: String = GameManager.biome_id if GameManager.biome_id != "" else "meadow"
	if n == 1:
		biome_id = "meadow"
		GameManager.biome_id = "meadow"
	level = LevelGen.build(n, biome_id, GameManager.run_seed)
	GameManager.biome = level.biome
	hold_need = float(level.get("hold_time", 2.5))
	lit.clear()
	taken_motes.clear()
	taken_blooms.clear()
	chests_open.clear()
	way_attuned = false
	way_used = false
	clearing = false
	GameManager.holding_gate = false
	GameManager.hold_progress = 0.0
	last_lit_pos = level.start
	for c in ground.get_children():
		c.queue_free()
	if world:
		for c in world.get_children():
			if c == player:
				continue
			c.queue_free()
	for b in get_tree().get_nodes_in_group("bullets"):
		b.queue_free()
	for b in get_tree().get_nodes_in_group("beacons"):
		b.queue_free()
	var floor_fx := get_node_or_null("FloorFX")
	if floor_fx:
		for c in floor_fx.get_children():
			c.queue_free()
	_build_tiles()
	_build_world()
	player.global_position = level.start
	if GameManager.started:
		player.battery = 100.0
		player.dash_charges = player.dash_charges_max
		player.broadcasting = false
	if n > 1:
		teach_step = 99
		if player:
			player.teach_id = ""
	if spawner and spawner.has_method("load_level"):
		spawner.load_level(level)
	GameManager.gate_open = not level.giant
	var grade: Color = level.biome.sky
	sky.color = Color(0.62 + grade.r * 0.38, 0.62 + grade.g * 0.38, 0.58 + grade.b * 0.42, 1.0)
	_draw_ghost()
	if Meta.has("warm_lantern") and GameManager.started:
		light_lantern(0)
	_spawn_wisp()

func _build_tiles() -> void:
	if ground and ground.has_method("build"):
		ground.build(level)

func _fit_height(s: Sprite2D, target: float) -> void:
	if s.texture == null:
		return
	var h := float(s.texture.get_height())
	var sc := target / maxf(1.0, h)
	s.scale = Vector2(sc, sc)

func _path_neighbor(tx: int, ty: int) -> bool:
	var grid: Array = level.get("path", [])
	if grid.is_empty():
		return false
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx := tx + dx
			var ny := ty + dy
			if ny >= 0 and ny < grid.size() and nx >= 0 and nx < grid[ny].size() and bool(grid[ny][nx]):
				return true
	return false

func _stand(s: Sprite2D, sink: float = 6.0) -> void:
	s.centered = true
	var h := 64.0
	if s.texture is AtlasTexture:
		h = (s.texture as AtlasTexture).region.size.y
	elif s.texture:
		h = float(s.texture.get_height()) / maxf(1.0, float(s.vframes))
	s.offset.y = -h * 0.5 + sink

func _scenery(s: Node, shadow_r: float) -> void:
	s.add_to_group("scenery")
	s.set_meta("shadow_r", shadow_r)

func _orb(parent: Node, local: Vector2, col: Color, r: float = 5.0) -> Node2D:
	var n := Node2D.new()
	n.set_script(load("res://scripts/Wisp.gd"))
	n.position = local
	parent.add_child(n)
	n.set("hue", col)
	n.set("radius", r)
	return n

func _build_world() -> void:
	var deco := _tex("res://sprites/deco.png")
	var pick := _tex("res://sprites/pickups.png")
	var props_tex := _tex("res://sprites/props.png")
	var bush_tex := _tex("res://sprites/bush.png")
	var gate_tex := _tex("res://sprites/gate.png")
	for f in level.flowers:
		var s := Sprite2D.new()
		s.texture = _atlas(deco, 1, 0, 2, 2)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = f
		s.scale = Vector2(0.38, 0.38)
		_stand(s, 8.0)
		world.add_child(s)
	for rk in level.rocks:
		var s := Sprite2D.new()
		s.texture = _atlas(deco, 0, 1, 2, 2)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = rk
		s.scale = Vector2(0.48, 0.48)
		_stand(s, 10.0)
		_scenery(s, 10.0)
		world.add_child(s)
	var tree_tex: Array = [
		_tex("res://sprites/trees/oak.png"),
		_tex("res://sprites/trees/leaf.png"),
		_tex("res://sprites/trees/pine.png"),
	]
	for t in level.trees:
		var s := Sprite2D.new()
		var ti: int = int(t.cell) % 3
		if tree_tex[ti]:
			s.texture = tree_tex[ti]
			s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			s.position = t.pos
			_fit_height(s, 132.0 if ti == 2 else 118.0)
		else:
			s.texture = _atlas(props_tex, ti, 0, 3, 3)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = t.pos
			s.scale = Vector2(0.95, 0.95)
		_stand(s, 8.0)
		_scenery(s, 20.0 if ti == 2 else 18.0)
		world.add_child(s)
	var bush_de := _tex("res://sprites/trees/bush.png")
	for b in level.bushes:
		var s := Sprite2D.new()
		if bush_de:
			s.texture = bush_de
			s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			s.position = b.pos
			_fit_height(s, 72.0)
		else:
			s.texture = _atlas(bush_tex, 0, 0, 2, 2)
			s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			s.position = b.pos
			s.scale = Vector2(0.86, 0.86)
		_stand(s, 8.0)
		_scenery(s, 14.0)
		world.add_child(s)
	for i in level.lanterns.size():
		var s := Sprite2D.new()
		s.texture = _atlas(deco, 0, 0, 2, 2)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = level.lanterns[i]
		s.scale = Vector2(0.64, 0.64)
		_stand(s, 6.0)
		s.set_meta("lantern", i)
		s.modulate = Color(0.55, 0.55, 0.6)
		_scenery(s, 8.0)
		world.add_child(s)
	for i in level.motes.size():
		var s := Sprite2D.new()
		s.texture = _atlas(pick, 0, 0, 2, 2)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = level.motes[i]
		s.scale = Vector2(0.3, 0.3)
		_stand(s, 8.0)
		s.set_meta("mote", i)
		world.add_child(s)
	for i in level.blooms.size():
		var s := Sprite2D.new()
		s.texture = _atlas(pick, 1, 0, 2, 2)
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		s.position = level.blooms[i]
		s.scale = Vector2(0.34, 0.34)
		_stand(s, 8.0)
		s.set_meta("bloom", i)
		world.add_child(s)
	var way := Sprite2D.new()
	way.texture = _atlas(deco, 1, 1, 2, 2)
	way.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	way.position = level.waystone
	way.scale = Vector2(0.64, 0.64)
	_stand(way, 8.0)
	way.set_meta("way", true)
	_scenery(way, 12.0)
	world.add_child(way)
	var chests: Array = level.get("chests", [level.chest])
	for i in chests.size():
		var chest := Sprite2D.new()
		chest.texture = _atlas(pick, 0, 1, 2, 2)
		chest.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		chest.position = chests[i]
		chest.scale = Vector2(0.44, 0.44)
		_stand(chest, 8.0)
		chest.set_meta("chest", i)
		_scenery(chest, 10.0)
		world.add_child(chest)
	gate_node = Sprite2D.new()
	gate_node.texture = gate_tex
	gate_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	gate_node.position = level.exit
	gate_node.centered = true
	gate_node.offset.y = -120
	gate_node.scale = Vector2(0.92, 0.92)
	gate_node.add_to_group("gate")
	_scenery(gate_node, 22.0)
	world.add_child(gate_node)
	var crystal_orb := _orb(gate_node, Vector2(0, -200), Color(0.7, 0.98, 1.0, 0.9), 4.5)
	crystal_orb.name = "Crystal"

func _draw_ghost() -> void:
	ghost_line.clear_points()

func light_near(pos: Vector2, reach: float) -> void:
	for i in level.lanterns.size():
		if pos.distance_to(level.lanterns[i]) < reach:
			light_lantern(i)

func _spawn_wisp() -> void:
	if wisp and is_instance_valid(wisp):
		wisp.queue_free()
	wisp = null
	wisp_done = false
	wisp_dark = 0.0
	wisp_home = level.waystone + Vector2(36, 0)
	wisp = Node2D.new()
	wisp.add_to_group("wisp")
	wisp.position = wisp_home
	world.add_child(wisp)
	_orb(wisp, Vector2(0, -10), Color(0.78, 1.0, 1.0, 0.95), 5.0)

func _update_wisp(delta: float, p: Vector2) -> void:
	if wisp == null or wisp_done or not is_instance_valid(wisp):
		return
	if player.in_any_light(wisp.global_position):
		wisp_dark = 0.0
		wisp.global_position = wisp.global_position.lerp(p + Vector2(0, -18), minf(1.0, delta * 3.2))
		if wisp.global_position.distance_to(level.exit) < 46.0:
			wisp_done = true
			player.add_combo(4)
			player.hp = minf(player.max_hp, player.hp + 24.0)
			GameManager.add_score(70)
			wisp.queue_free()
			wisp = null
	else:
		wisp_dark += delta
		if wisp_dark > 2.8:
			wisp.global_position = wisp.global_position.lerp(wisp_home, minf(1.0, delta * 1.6))

func light_lantern(i: int) -> void:
	if i < 0 or i >= level.lanterns.size():
		return
	if lit.has(i):
		return
	lit[i] = true
	last_lit_pos = level.lanterns[i]
	GameManager.add_score(12)
	GameManager.lantern_changed.emit()
	Audio.play("lantern", -7.0)
	GameManager.bump(4.0)
	GameManager.add_puff(level.lanterns[i])
	var blob := Node2D.new()
	blob.set_script(load("res://scripts/LightBlob.gd"))
	blob.position = level.lanterns[i]
	blob.add_to_group("lit_lights")
	blob.set_meta("lantern_index", i)
	var floor_fx := get_node_or_null("FloorFX")
	if floor_fx:
		floor_fx.add_child(blob)
	else:
		world.add_child(blob)
	if world:
		for s in world.get_children():
			if s.has_meta("lantern") and int(s.get_meta("lantern")) == i:
				s.modulate = Color(1.2, 1.05, 0.7)
				if s.get_node_or_null("Flame") == null:
					var flame := _orb(s, Vector2(0, -100), Color(1.0, 0.82, 0.4, 0.95), 3.5)
					flame.name = "Flame"

func unlight_lantern(i: int) -> void:
	if not lit.has(i):
		return
	lit.erase(i)
	GameManager.lantern_changed.emit()
	for n in get_tree().get_nodes_in_group("lit_lights"):
		if int(n.get_meta("lantern_index", -1)) == i:
			n.queue_free()
	if world:
		for s in world.get_children():
			if s.has_meta("lantern") and int(s.get_meta("lantern")) == i:
				s.modulate = Color(0.55, 0.55, 0.6)
				var flame := s.get_node_or_null("Flame")
				if flame:
					flame.queue_free()

func plant_beacon(pos: Vector2, kind: String, life: float, radius: float) -> void:
	var b := Node2D.new()
	b.set_script(load("res://scripts/Beacon.gd"))
	b.position = pos
	var floor_fx := get_node_or_null("FloorFX")
	if floor_fx:
		floor_fx.add_child(b)
	else:
		world.add_child(b)
	b.kind = kind
	b.life = life
	b.radius = radius

func try_waystone(mode: String) -> void:
	if not GameManager.started or GameManager.state != GameManager.State.PLAYING:
		return
	if player.global_position.distance_to(level.waystone) > 34.0:
		return
	if not way_attuned:
		return
	if way_used:
		return
	if player.combo < 4.0:
		return
	player.combo = maxf(0.0, player.combo - 4.0)
	way_used = true
	if mode == "turret":
		plant_beacon(level.waystone, "turret", 8.0, 110.0)
		GameManager.add_score(20)
	else:
		player.global_position = last_lit_pos
		player.hurt_cd = maxf(player.hurt_cd, 0.35)

func _process(delta: float) -> void:
	if not GameManager.started or GameManager.state != GameManager.State.PLAYING:
		return
	var p: Vector2 = player.global_position
	if player.broadcasting or player.signal_t > 0.0:
		for i in level.lanterns.size():
			if lit.has(i):
				continue
			if p.distance_to(level.lanterns[i]) < 78:
				light_lantern(i)
	for i in level.motes.size():
		if taken_motes.has(i):
			continue
		if p.distance_to(level.motes[i]) < 28:
			taken_motes[i] = true
			GameManager.add_score(18)
			Audio.play("mote", -10.0)
			if player.has_method("add_combo"):
				player.add_combo(1)
			player.mote_count += 1
	for i in level.blooms.size():
		if taken_blooms.has(i):
			continue
		if p.distance_to(level.blooms[i]) < 26:
			taken_blooms[i] = true
			player.hp = minf(player.max_hp, player.hp + 20)
	_update_wisp(delta, p)
	if not way_attuned and p.distance_to(level.waystone) < 26:
		way_attuned = true
		player.add_combo(3)
		GameManager.add_score(25)
	var chests: Array = level.get("chests", [level.chest])
	for i in chests.size():
		if chests_open.has(i):
			continue
		if p.distance_to(chests[i]) < 24:
			chests_open[i] = true
			player.overclock_t = 7.0
			GameManager.add_score(40)
			if player.overclock_leak and spawner and spawner.has_method("pop_all_hidden"):
				spawner.pop_all_hidden()
				spawner.spawn_kind("moth", p + Vector2(80, 0), false)
				spawner.spawn_kind("moth", p + Vector2(-80, 0), false)
	if world:
		for s in world.get_children():
			if s.has_meta("mote") and taken_motes.has(s.get_meta("mote")):
				s.visible = false
			if s.has_meta("bloom") and taken_blooms.has(s.get_meta("bloom")):
				s.visible = false
			if s.has_meta("chest") and chests_open.has(s.get_meta("chest")):
				s.modulate = Color(1, 1, 1, 0.45)
	if spawner and spawner.has_method("giants_alive"):
		GameManager.gate_open = spawner.giants_alive() == 0
	if gate_node:
		var crystal_orb := gate_node.get_node_or_null("Crystal")
		if crystal_orb:
			crystal_orb.modulate.a = 1.0 if GameManager.gate_open else 0.38
	_update_hold(delta)
	_update_teach(delta)
	_update_prompt()

func _update_hold(delta: float) -> void:
	if clearing or gate_node == null:
		return
	var p: Vector2 = player.global_position
	var crystal: Vector2 = gate_node.position + Vector2(0, -96)
	var dist := p.distance_to(level.exit)
	var near: bool = dist < GameManager.GATE_NEAR
	GameManager.near_gate = near
	var aiming: bool = false
	if near and player.vision:
		aiming = player.vision.overlaps_circle(level.exit, GameManager.GATE_LOCK_R)
		aiming = aiming or player.vision.overlaps_circle(crystal, GameManager.GATE_LOCK_R * 0.7)
		if dist < GameManager.GATE_FACE:
			var facing := Vector2.RIGHT.rotated(player.vision.global_rotation)
			var to_g: Vector2 = (level.exit - p).normalized()
			if abs(facing.angle_to(to_g)) < deg_to_rad(80.0):
				aiming = true
	if GameManager.gate_open and near and aiming:
		GameManager.holding_gate = true
		GameManager.hold_progress = minf(1.0, GameManager.hold_progress + delta / maxf(0.8, hold_need))
		if GameManager.hold_progress >= 1.0:
			clearing = true
			GameManager.add_score(50 + GameManager.current_level * 4)
			GameManager.complete_level()
	elif GameManager.hold_progress > 0.0:
		GameManager.hold_progress = maxf(0.0, GameManager.hold_progress - delta * 0.22)
		if GameManager.hold_progress <= 0.0:
			GameManager.holding_gate = false
			GameManager.near_gate = near

func _update_teach(delta: float) -> void:
	if Meta.taught or GameManager.current_level != 1:
		player.teach_id = ""
		return
	teach_t += delta
	match teach_step:
		0:
			player.teach_id = "WASD — walk the dirt path"
			if player.velocity.length() > 24.0:
				teach_step = 1
				teach_t = 0.0
		1:
			player.teach_id = "The cone is always on. Aim with the mouse."
			if teach_t > 2.4:
				teach_step = 2
				teach_t = 0.0
		2:
			player.teach_id = "Click to fire. The gun is backup."
			if float(player.fire_cooldown) > 0.0:
				teach_step = 3
				teach_t = 0.0
		3:
			player.teach_id = "Hold F to broadcast — it lights lanterns and pops bushes."
			if player.broadcasting or lit.size() > 0:
				teach_step = 4
				teach_t = 0.0
		4:
			player.teach_id = "Shift dashes. Tap F spends combo to ping hidden bushes."
			if player.dash_t > 0.0 or teach_t > 10.0:
				teach_step = 5
				teach_t = 0.0
		5:
			player.teach_id = "Walk to the stone arch. Sweep the beam across it to lock the road."
			if GameManager.near_gate or GameManager.hold_progress > 0.02:
				teach_step = 6
				teach_t = 0.0
				Meta.taught = true
				Meta.save_cfg()
		_:
			player.teach_id = ""

func _update_prompt() -> void:
	var p: Vector2 = player.global_position
	var t := ""
	if wisp and is_instance_valid(wisp) and not wisp_done and p.distance_to(wisp.global_position) < 80.0:
		if player.in_any_light(wisp.global_position):
			t = "The wisp follows your light — take it to the gate"
		else:
			t = "The lost wisp is going dark"
	elif p.distance_to(level.waystone) < 36.0:
		if not way_attuned:
			t = "Waystone attuning…"
		elif way_used:
			t = "Waystone spent"
		elif player.combo >= 4.0:
			t = "E rewind to last lamp · hold E turret (4 combo)"
		else:
			t = "Need 4 combo to spend the waystone"
	elif not GameManager.gate_open and p.distance_to(level.exit) < GameManager.GATE_NEAR:
		t = "The Giant holds the gate — put its heart in the beam"
	elif GameManager.gate_open and p.distance_to(level.exit) < GameManager.GATE_NEAR:
		if GameManager.holding_gate:
			t = "Keep the beam on the arch — locking"
		else:
			t = "Stand in the ring and sweep the beam across the gate"
	elif player.mote_count >= 3:
		t = "G / right-click plant a signal puck (3 motes)"
	player.prompt = t

func _on_cleared() -> void:
	pass

func _panel_style() -> StyleBoxFlat:
	return MenuSkin.cream_panel()

func _btn_style() -> StyleBoxFlat:
	return MenuSkin.card(false)

func _label(text: String, pos: Vector2, size: Vector2, px: int, col: Color, wrap := false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", col)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _build_title() -> void:
	title_layer = CanvasLayer.new()
	title_layer.layer = 20
	title_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(title_layer)
	MenuSkin.add_landscape(title_layer)
	var board := Panel.new()
	board.name = "Panel"
	board.position = Vector2(270, 58)
	board.size = Vector2(740, 604)
	board.add_theme_stylebox_override("panel", MenuSkin.cream_panel())
	title_layer.add_child(board)
	MenuSkin.add_frame(board, board.size)
	board.add_child(_label("TWENTY ROADS", Vector2(48, 28), Vector2(300, 18), 12, MenuSkin.MOSS))
	var title := _label("Signal Radius", Vector2(48, 46), Vector2(640, 52), 42, MenuSkin.TERRACOTTA)
	title.name = "Title"
	board.add_child(title)
	var blurb := _label("Walk the dirt path. Bushes hide shades. The Giant holds the gate.", Vector2(48, 100), Vector2(640, 28), 16, MenuSkin.INK, true)
	blurb.name = "Blurb"
	board.add_child(blurb)
	var best := _label("Best 0", Vector2(48, 130), Vector2(400, 22), 16, MenuSkin.TERRACOTTA)
	best.name = "Best"
	board.add_child(best)
	var dust := _label("Dust 0", Vector2(500, 28), Vector2(190, 22), 14, MenuSkin.MUTED)
	dust.name = "Dust"
	dust.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	board.add_child(dust)
	weapon_btns.clear()
	var ids := Weapons.all_ids()
	for i in ids.size():
		var id := ids[i]
		var w := Weapons.def(id)
		var btn := Button.new()
		btn.text = "   %s\n   %s\n   %s" % [w.name, w.tag, w.blurb]
		btn.position = Vector2(48 + (i % 2) * 322, 164 + int(i / 2.0) * 118)
		btn.size = Vector2(310, 108)
		btn.icon = MenuSkin.weapon_icon(id)
		btn.expand_icon = true
		btn.add_theme_constant_override("icon_max_width", 56)
		btn.add_theme_color_override("font_color", MenuSkin.INK)
		btn.add_theme_font_size_override("font_size", 14)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_stylebox_override("normal", MenuSkin.card(id == "pulse"))
		btn.add_theme_stylebox_override("hover", MenuSkin.card(true))
		btn.add_theme_stylebox_override("pressed", MenuSkin.card(true))
		btn.pressed.connect(_pick_weapon.bind(id, btn))
		board.add_child(btn)
		weapon_btns.append(btn)
	var daily := Button.new()
	daily.name = "Daily"
	daily.text = "Daily road"
	daily.position = Vector2(48, 408)
	daily.size = Vector2(150, 36)
	daily.add_theme_stylebox_override("normal", MenuSkin.ghost_btn())
	daily.add_theme_color_override("font_color", MenuSkin.INK)
	daily.pressed.connect(_toggle_daily.bind(daily))
	board.add_child(daily)
	var outp := Button.new()
	outp.text = "Outpost"
	outp.position = Vector2(208, 408)
	outp.size = Vector2(120, 36)
	outp.add_theme_stylebox_override("normal", MenuSkin.ghost_btn())
	outp.add_theme_color_override("font_color", MenuSkin.INK)
	outp.pressed.connect(_open_outpost)
	board.add_child(outp)
	var deploy := Button.new()
	deploy.text = "Walk the first road"
	deploy.position = Vector2(48, 456)
	deploy.size = Vector2(644, 58)
	deploy.add_theme_stylebox_override("normal", MenuSkin.terra_btn())
	deploy.add_theme_stylebox_override("hover", MenuSkin.terra_btn())
	deploy.add_theme_color_override("font_color", Color("f6efe0"))
	deploy.add_theme_font_size_override("font_size", 20)
	deploy.pressed.connect(_on_deploy)
	board.add_child(deploy)
	var controls := _label("WASD · mouse · click fire · right-click throw spark · hold F broadcast · Shift dash", Vector2(48, 526), Vector2(644, 22), 13, MenuSkin.MUTED)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	board.add_child(controls)
	_refresh_title()
	_paint_weapon_cards()

func _refresh_title() -> void:
	if title_layer == null:
		return
	var panel := title_layer.get_node_or_null("Panel")
	if panel == null:
		return
	var dust: Label = panel.get_node_or_null("Dust")
	if dust:
		dust.text = "Dust %d" % Meta.dust
	var best: Label = panel.get_node_or_null("Best")
	if best:
		best.text = "Best %d" % Meta.best
	var blurb: Label = panel.get_node_or_null("Blurb")
	if blurb:
		if Meta.has("second_kit"):
			blurb.text = "Pick two kits. Walk the dirt path. Bushes hide shades. The Giant holds the gate."
		else:
			blurb.text = "Walk the dirt path. Bushes hide shades. The Giant holds the gate."

func _paint_weapon_cards() -> void:
	var ids := Weapons.all_ids()
	for i in ids.size():
		if i >= weapon_btns.size():
			break
		var id := ids[i]
		var on := id == picked_weapon
		var alt := id == picked_weapon_b
		weapon_btns[i].add_theme_stylebox_override("normal", MenuSkin.card(on, alt))
		weapon_btns[i].modulate = Color.WHITE

func _pick_weapon(id: String, _btn: Button) -> void:
	Audio.ui()
	if Meta.has("second_kit"):
		if picked_weapon == id:
			picked_weapon = picked_weapon_b if picked_weapon_b != "" else id
			picked_weapon_b = ""
		elif picked_weapon_b == id:
			picked_weapon_b = ""
		elif picked_weapon_b == "":
			picked_weapon_b = id
		else:
			picked_weapon = id
	else:
		picked_weapon = id
		picked_weapon_b = ""
	_paint_weapon_cards()

func _toggle_daily(btn: Button) -> void:
	daily_toggle = not daily_toggle
	btn.text = "Daily · %d" % Meta.daily_seed() if daily_toggle else "Daily road"

func _on_deploy() -> void:
	if title_layer:
		title_layer.visible = false
	if outpost_layer:
		outpost_layer.visible = false
	if fork_layer:
		fork_layer.visible = false
	Audio.ui()
	GameManager.start_run(picked_weapon, daily_toggle, picked_weapon_b)
	player.set_weapon(picked_weapon)
	player.set_weapon_b(picked_weapon_b)
	player.global_position = level.start
	teach_step = 0
	teach_t = 0.0
	if Meta.taught:
		teach_step = 99

func _build_outpost() -> void:
	outpost_layer = CanvasLayer.new()
	outpost_layer.layer = 21
	outpost_layer.visible = false
	outpost_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(outpost_layer)
	MenuSkin.add_landscape(outpost_layer)
	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(310, 70)
	panel.size = Vector2(660, 580)
	panel.add_theme_stylebox_override("panel", MenuSkin.cream_panel())
	outpost_layer.add_child(panel)
	MenuSkin.add_frame(panel, panel.size)
	panel.add_child(_label("Outpost", Vector2(48, 28), Vector2(560, 40), 32, MenuSkin.TERRACOTTA))
	var dust := _label("Dust 0", Vector2(48, 72), Vector2(560, 24), 16, MenuSkin.MUTED)
	dust.name = "Dust"
	panel.add_child(dust)
	var y := 110
	for id in Meta.COSTS.keys():
		var btn := Button.new()
		btn.name = id
		btn.position = Vector2(48, y)
		btn.size = Vector2(564, 72)
		btn.add_theme_stylebox_override("normal", MenuSkin.card(false))
		btn.add_theme_color_override("font_color", MenuSkin.INK)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_buy_outpost.bind(id))
		panel.add_child(btn)
		y += 80
	var back := Button.new()
	back.text = "Back"
	back.position = Vector2(48, 490)
	back.size = Vector2(564, 50)
	back.add_theme_stylebox_override("normal", MenuSkin.wood_btn())
	back.add_theme_color_override("font_color", Color("f6efe0"))
	back.pressed.connect(func() -> void: outpost_layer.visible = false)
	panel.add_child(back)

func _open_outpost() -> void:
	Audio.ui()
	_refresh_outpost()
	outpost_layer.visible = true

func _refresh_outpost() -> void:
	if outpost_layer == null:
		return
	var panel := outpost_layer.get_node("Panel")
	var dust: Label = panel.get_node("Dust")
	dust.text = "Dust %d  —  spent on the outpost, kept between runs" % Meta.dust
	for id in Meta.COSTS.keys():
		var btn: Button = panel.get_node(id)
		var cost: int = int(Meta.COSTS[id])
		var label: String = str(Meta.LABELS[id])
		if Meta.has(id):
			btn.text = "OWNED  ·  %s" % label
			btn.disabled = true
			btn.modulate = Color(0.7, 0.9, 0.7)
		else:
			btn.text = "Buy  %d dust\n%s" % [cost, label]
			btn.disabled = Meta.dust < cost
			btn.modulate = Color.WHITE

func _buy_outpost(id: String) -> void:
	Audio.ui()
	if Meta.buy(id):
		_refresh_outpost()
		_refresh_title()

func _build_fork() -> void:
	fork_layer = CanvasLayer.new()
	fork_layer.layer = 13
	fork_layer.visible = false
	fork_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(fork_layer)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.offset_right = 1280
	dim.offset_bottom = 720
	dim.color = Color(0.08, 0.05, 0.03, 0.35)
	fork_layer.add_child(dim)
	var panel := Panel.new()
	panel.name = "Panel"
	panel.position = Vector2(200, 80)
	panel.size = Vector2(880, 560)
	panel.add_theme_stylebox_override("panel", MenuSkin.cream_panel())
	fork_layer.add_child(panel)
	MenuSkin.add_frame(panel, panel.size)
	var title := _label("The road splits", Vector2(48, 28), Vector2(784, 40), 28, MenuSkin.TERRACOTTA)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

func _show_forks() -> void:
	var next_level := GameManager.current_level + 1
	var opts: Array = LevelGen.fork_options(next_level, GameManager.run_seed)
	var panel: Panel = fork_layer.get_node("Panel")
	for c in panel.get_children():
		if str(c.name).begins_with("Fork"):
			c.queue_free()
	var n: int = opts.size()
	var w := 240.0
	var gap := 16.0
	var total := n * w + (n - 1) * gap
	var x0 := (880.0 - total) * 0.5
	for i in n:
		var b: Dictionary = opts[i]
		var btn := Button.new()
		btn.name = "Fork_%s_%d" % [str(b.id), next_level]
		btn.position = Vector2(x0 + i * (w + gap), 88)
		btn.size = Vector2(w, 400)
		btn.add_theme_stylebox_override("normal", MenuSkin.card(false))
		btn.add_theme_stylebox_override("hover", MenuSkin.card(true))
		btn.add_theme_color_override("font_color", MenuSkin.INK)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.text = "%s\n\n%s\n\nHold %.1fs" % [b.name, b.blurb, b.hold_time]
		btn.pressed.connect(_pick_fork.bind(str(b.id)))
		panel.add_child(btn)
	fork_layer.visible = true
	get_tree().paused = true

func _pick_fork(biome_id: String) -> void:
	Audio.ui()
	fork_layer.visible = false
	get_tree().paused = false
	GameManager.start_next_wave(biome_id)
