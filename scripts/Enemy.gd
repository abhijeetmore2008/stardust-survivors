extends CharacterBody2D

var kind: String = "walker"
var max_hp: float = 30.0
var move_speed: float = 78.0
var contact_damage: float = 12.0
var hp: float = 30.0
var phase: String = "chase"
var timer: float = 0.0
var orbit: float = 0.0
var flash: float = 0.0
var knock: float = 0.0
var anim: float = 0.0
var facing: int = 0
var radius: float = 11.0
var pop_range: float = 78.0
var painted_until: float = 0.0
var eat_t: float = 0.0
var ping_t: float = 0.0
var echo_dir := Vector2.ZERO
var heart_exposed: bool = false

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.hframes = 4
	sprite.vframes = 4

func setup(p_kind: String, level: int, hidden: bool = false) -> void:
	kind = p_kind
	phase = "hide" if hidden else ("orbit" if kind == "flanker" else "chase")
	timer = 0.4 + randf() * 0.5
	orbit = randf() * TAU
	var st := LevelGen.stats(level)
	match kind:
		"rusher":
			max_hp = (20.0 + level * 5.0) * st.hp
			move_speed = (90.0 + level * 5.0) * st.spd
			contact_damage = (13.0 + level * 1.3) * st.dmg
			radius = 10.0
		"flanker":
			max_hp = (24.0 + level * 6.0) * st.hp
			move_speed = (84.0 + level * 4.5) * st.spd
			contact_damage = (12.0 + level * 1.2) * st.dmg
			radius = 11.0
		"brute":
			max_hp = (70.0 + level * 14.0) * st.hp
			move_speed = (48.0 + level * 3.0) * st.spd
			contact_damage = (20.0 + level * 1.8) * st.dmg
			radius = 16.0
		"jammer":
			max_hp = (80.0 + level * 16.0) * st.hp
			move_speed = (44.0 + level * 2.6) * st.spd
			contact_damage = (18.0 + level * 1.5) * st.dmg
			radius = 16.0
		"giant":
			max_hp = (160.0 + level * 32.0) * st.hp
			move_speed = (36.0 + level * 2.2) * st.spd
			contact_damage = (26.0 + level * 2.2) * st.dmg
			radius = 22.0
			pop_range = 96.0
		"moth":
			max_hp = (12.0 + level * 3.0) * st.hp
			move_speed = (110.0 + level * 6.0) * st.spd
			contact_damage = (16.0 + level * 1.1) * st.dmg
			radius = 8.0
		"mite":
			max_hp = (14.0 + level * 3.5) * st.hp
			move_speed = (96.0 + level * 5.0) * st.spd
			contact_damage = (8.0 + level * 0.6) * st.dmg
			radius = 7.0
		"wraith":
			max_hp = (28.0 + level * 7.0) * st.hp
			move_speed = (88.0 + level * 4.8) * st.spd
			contact_damage = (14.0 + level * 1.3) * st.dmg
			radius = 11.0
		"mimic":
			max_hp = (60.0 + level * 12.0) * st.hp
			move_speed = (52.0 + level * 3.2) * st.spd
			contact_damage = (18.0 + level * 1.6) * st.dmg
			radius = 15.0
		_:
			max_hp = (26.0 + level * 6.0) * st.hp
			move_speed = (68.0 + level * 4.0) * st.spd
			contact_damage = (11.0 + level * 1.1) * st.dmg
			radius = 11.0
	hp = max_hp
	var sh: Shape2D = $CollisionShape2D.shape
	if sh is CircleShape2D:
		var circ: CircleShape2D = sh.duplicate()
		$CollisionShape2D.shape = circ
		circ.radius = radius
	_load_kind_sprite()
	if kind == "mimic" and phase == "hide":
		visible = true
		$CollisionShape2D.disabled = true
	else:
		visible = phase != "hide"
		$CollisionShape2D.disabled = phase == "hide"

func _load_kind_sprite() -> void:
	var file := "walker"
	if kind == "mimic" and phase == "hide":
		file = "bush"
	elif kind == "rusher" or kind == "flanker" or kind == "wraith":
		file = "rusher"
	elif kind == "brute" or kind == "jammer":
		file = "brute"
	elif kind == "giant":
		file = "giant" if ResourceLoader.exists("res://sprites/giant.png") else "brute"
	elif kind == "moth":
		file = "rusher"
	elif kind == "mite":
		file = "walker"
	var path := "res://sprites/%s.png" % file
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
	if kind == "mimic" and phase == "hide":
		sprite.hframes = 2
		sprite.vframes = 2
		sprite.frame = 0
		sprite.scale = Vector2(0.68, 0.68)
		sprite.modulate = Color.WHITE
		_plant_feet()
		return
	sprite.hframes = 4
	sprite.vframes = 4
	match kind:
		"giant":
			sprite.scale = Vector2(0.82, 0.82)
		"brute", "jammer", "mimic":
			sprite.scale = Vector2(0.56, 0.56)
		"moth":
			sprite.scale = Vector2(0.32, 0.32)
		"mite":
			sprite.scale = Vector2(0.30, 0.30)
		_:
			sprite.scale = Vector2(0.46, 0.46)
	if kind == "wraith":
		sprite.modulate = Color(0.65, 0.9, 1.0, 0.72)
	elif kind == "moth":
		sprite.modulate = Color(0.95, 0.55, 1.0, 1)
	elif kind == "mite":
		sprite.modulate = Color(0.75, 1.0, 0.45, 1)
	elif kind == "jammer":
		sprite.modulate = Color(0.72, 0.5, 1.0, 1)
	_plant_feet()

func _plant_feet() -> void:
	sprite.centered = true
	var h := 96.0
	if sprite.texture:
		h = float(sprite.texture.get_height()) / maxf(1.0, float(sprite.vframes))
	sprite.offset.y = -h * 0.45

func heart_pos() -> Vector2:
	return global_position + Vector2(0, -32)

func is_shade() -> bool:
	return kind == "moth" or kind == "wraith"

func ping_flash() -> void:
	ping_t = 0.45
	if kind != "mimic":
		visible = true

func on_player_dashed(dir: Vector2) -> void:
	if kind != "wraith" or phase == "hide":
		return
	echo_dir = dir.normalized() if dir.length() > 0.1 else Vector2.RIGHT
	phase = "echo"
	timer = 0.34

func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		return
	flash = maxf(0.0, flash - delta)
	knock = maxf(0.0, knock - delta)
	ping_t = maxf(0.0, ping_t - delta)
	timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var to_p: Vector2 = player.global_position - global_position
	var dist := to_p.length()
	if dist < 0.001:
		dist = 0.001
	var nx := to_p / dist

	if phase == "hide":
		if ping_t <= 0.0 and kind != "mimic":
			visible = false
		if dist < pop_range:
			_pop(nx)
		return
	if phase == "pop":
		velocity = nx * 140.0
		move_and_slide()
		if timer <= 0.0:
			phase = "orbit" if kind == "flanker" else "chase"
		_anim(delta)
		return

	var outside := true
	if player.has_method("in_any_light"):
		outside = not player.in_any_light(global_position)
	var spd := move_speed
	if outside:
		spd *= 1.18
	if player.get("stains") != null:
		for s in player.stains:
			if global_position.distance_to(s.pos) <= float(s.r):
				spd *= 0.52
				break

	if GameManager.holding_gate:
		spd *= 1.45
		if phase == "hide":
			_pop(nx)

	var sep := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var d: float = global_position.distance_to(other.global_position)
		if d > 0.1 and d < 36.0:
			sep += (global_position - other.global_position).normalized() * ((36.0 - d) / 36.0)

	var steer := nx
	if kind == "rusher":
		if phase == "chase" and dist < 92.0 and timer <= 0.0:
			phase = "wind"
			timer = 0.38
		elif phase == "wind":
			spd = 18.0
			if timer <= 0.0:
				phase = "dash"
				timer = 0.28
		elif phase == "dash":
			spd = move_speed * 3.1
			if timer <= 0.0:
				phase = "chase"
				timer = 0.7 + randf() * 0.5
	elif kind == "flanker":
		orbit += delta * 1.7
		steer = nx * (1.0 if dist > 78.0 else -0.35) + Vector2(cos(orbit), sin(orbit)) * 0.95
		if dist < 70.0 and timer <= 0.0:
			phase = "dash"
			timer = 0.22
		if phase == "dash":
			steer = nx
			spd = move_speed * 2.4
			if timer <= 0.0:
				phase = "orbit"
				timer = 1.1
	elif kind == "brute" or kind == "giant" or kind == "jammer" or kind == "mimic":
		if dist < (64.0 if kind == "giant" else 48.0) and phase != "smash":
			phase = "smash"
			timer = 0.45
		if phase == "smash":
			spd = 12.0 if timer > 0.18 else move_speed * 1.8
			if timer <= 0.0:
				phase = "chase"
	elif kind == "moth":
		var vis = player.get("vision")
		var broadcasting := bool(player.get("broadcasting")) or float(player.get("signal_t")) > 0.0
		if broadcasting and vis != null:
			var facing := Vector2.RIGHT.rotated(vis.global_rotation)
			var lure: Vector2 = player.global_position + facing * 90.0
			steer = (lure - global_position).normalized()
			spd *= 1.25
		if dist < radius + 14.0:
			var boom := contact_damage
			if bool(player.get("moth_ward")):
				boom *= 0.5
			if player.has_method("take_damage"):
				player.take_damage(boom)
			GameManager.add_score(6)
			queue_free()
			return
	elif kind == "mite":
		var lamp := _nearest_lit()
		if lamp != null:
			var to_l: Vector2 = lamp.global_position - global_position
			var ld := to_l.length()
			if ld > 1.0:
				steer = to_l / ld
			if ld < 22.0:
				eat_t += delta
				spd = 8.0
				if eat_t >= 2.0:
					get_tree().call_group("level_root", "unlight_lantern", int(lamp.get_meta("lantern_index", -1)))
					eat_t = 0.0
			else:
				eat_t = 0.0
		else:
			steer = nx
	elif kind == "wraith":
		if phase == "echo":
			steer = echo_dir
			spd = move_speed * 3.2
			if timer <= 0.0:
				phase = "chase"
				timer = 0.8

	if knock > 0.0:
		velocity = -nx * 140.0
	else:
		var s := steer.normalized() if steer.length() > 0.001 else nx
		velocity = (s + sep * 0.85) * spd
	move_and_slide()
	_anim(delta)

	if dist < radius + 11.0 and player.has_method("take_damage"):
		if kind == "moth":
			pass
		elif (kind == "brute" or kind == "giant" or kind == "jammer" or kind == "mimic") and phase == "smash" and timer < 0.18:
			player.take_damage(contact_damage)
		elif kind != "brute" and kind != "giant" and kind != "jammer" and kind != "mimic":
			player.take_damage(contact_damage)

func _pop(nx: Vector2) -> void:
	phase = "pop"
	timer = 0.28
	visible = true
	$CollisionShape2D.disabled = false
	if kind == "mimic":
		_load_kind_sprite()
	velocity = nx * 140.0

func _nearest_lit() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for n in get_tree().get_nodes_in_group("lit_lights"):
		var d: float = global_position.distance_to(n.global_position)
		if d < best_d:
			best_d = d
			best = n
	return best

func _anim(delta: float) -> void:
	if absf(velocity.y) >= absf(velocity.x):
		facing = 0 if velocity.y > 0.0 else 3
	else:
		facing = 1 if velocity.x < 0.0 else 2
	anim += delta * (14.0 if phase == "dash" or phase == "echo" else 7.0)
	if sprite.hframes == 4:
		sprite.frame = facing * 4 + int(anim) % 4
	var mod := Color.WHITE
	if kind == "wraith":
		mod = Color(0.65, 0.9, 1.0, 0.72)
	elif kind == "moth":
		mod = Color(0.95, 0.55, 1.0, 1)
	elif kind == "mite":
		mod = Color(0.75, 1.0, 0.45, 1)
	elif kind == "jammer":
		mod = Color(0.72, 0.5, 1.0, 1)
	if flash > 0.0:
		mod = Color(1, 0.6, 0.6)
	if phase == "wind" or phase == "smash":
		mod = Color(1.0, 0.45, 0.35)
	if ping_t > 0.0:
		mod = Color(1.0, 1.0, 0.6)
	if kind == "giant" and heart_exposed:
		mod = Color(0.65, 1.0, 1.15)
	sprite.modulate = mod

func take_damage(amount: float, source: String = "gun") -> void:
	if phase == "hide":
		return
	if amount <= 0.0:
		return
	if kind == "giant":
		var player := get_tree().get_first_node_in_group("player")
		var vis = player.get("vision") if player != null else null
		heart_exposed = vis != null and vis.contains_point(heart_pos())
		if source == "gun" and not heart_exposed:
			amount *= 0.35
		elif source == "signal" and heart_exposed:
			amount *= 1.6
	if is_shade():
		if source == "signal":
			amount *= 1.5
		else:
			amount *= 0.5
	hp -= amount
	flash = 0.12
	knock = 0.08
	Audio.play("hit", -12.0, 0.9 + randf() * 0.2)
	if hp <= 0.0:
		var pts := 10
		match kind:
			"giant": pts = 80
			"brute": pts = 25
			"jammer": pts = 28
			"mimic": pts = 30
			"wraith": pts = 18
			"moth": pts = 6
			"mite": pts = 8
			_: pts = 10
		GameManager.add_score(pts)
		GameManager.register_kill()
		Audio.play("kill", -8.0)
		GameManager.add_puff(global_position)
		GameManager.bump(2.5)
		queue_free()
