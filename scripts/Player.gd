extends CharacterBody2D

const COMBO_MAX := 8.0
const SIGNAL_SECS := 7.0
const BATTERY_MAX := 100.0

@export var move_speed: float = 210.0
@export var max_hp: float = 100.0
@export var fire_rate: float = 4.2
@export var damage: float = 16.0
@export var bullet_scene: PackedScene

var hp: float = 100.0
var fire_cooldown: float = 0.0
var fire_cooldown_b: float = 0.0
var acquired_upgrades: Array[String] = []
var hurt_cd: float = 0.0
var combo: float = 0.0
var combo_idle: float = 0.0
var signal_t: float = 0.0
var anim: float = 0.0
var facing: int = 0
var dash_t: float = 0.0
var dash_charges: int = 1
var dash_charges_max: int = 1
var dash_recharge: float = 0.0
var overclock_t: float = 0.0
var weapon: Dictionary = {}
var weapon_b: Dictionary = {}
var last_dir := Vector2.RIGHT
var battery: float = 100.0
var broadcasting: bool = false
var f_down: bool = false
var f_held: float = 0.0
var e_down: bool = false
var e_held: float = 0.0
var bonus_angle: float = 0.0
var bonus_range: float = 0.0
var bonus_radius: float = 0.0
var lighthouse: bool = false
var lighthouse_mul: float = 1.0
var louder: bool = false
var darkroom: bool = false
var overclock_leak: bool = false
var moth_ward: bool = false
var mote_count: int = 0
var radius_now: float = 108.0
var echo_timer: float = 0.0
var signal_cd: float = 0.0
var spark_cd: float = 0.0
var stain_t: float = 0.0
var stains: Array = []
var prompt: String = ""
var ghost_acc: float = 0.0
var teach_id: String = "move"

@onready var vision: Node2D = $VisionCone
@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	hp = max_hp
	add_to_group("player")
	GameManager.kill_registered.connect(add_combo)
	GameManager.run_started.connect(_on_run_started)
	if bullet_scene == null and ResourceLoader.exists("res://scenes/Bullet.tscn"):
		bullet_scene = load("res://scenes/Bullet.tscn")
	_load_sprite()
	set_weapon("pulse")
	if camera:
		camera.make_current()
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0
		camera.zoom = Vector2(1.15, 1.15)
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = LevelGen.MAP_W * LevelGen.TILE
		camera.limit_bottom = LevelGen.MAP_H * LevelGen.TILE
		camera.limit_smoothed = true

func _load_sprite() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.hframes = 4
	sprite.vframes = 4
	if ResourceLoader.exists("res://sprites/player.png"):
		sprite.texture = load("res://sprites/player.png")
	if ResourceLoader.exists("res://sprites/player-de.png"):
		sprite.texture = load("res://sprites/player-de.png")
	else:
		var im := Image.new()
		if im.load("res://sprites/player-de.png") == OK:
			sprite.texture = ImageTexture.create_from_image(im)
	sprite.centered = true
	sprite.scale = Vector2(0.5, 0.5)
	var h := 96.0
	if sprite.texture:
		h = float(sprite.texture.get_height()) / maxf(1.0, float(sprite.vframes))
	sprite.offset.y = -h * 0.45
	if vision:
		vision.z_as_relative = false
		vision.z_index = -3

func set_weapon(id: String) -> void:
	weapon = Weapons.def(id)
	fire_rate = weapon.fire_rate
	damage = weapon.damage

func set_weapon_b(id: String) -> void:
	if id == "" or id == weapon.get("id", ""):
		weapon_b = {}
		return
	weapon_b = Weapons.def(id)

func _on_run_started() -> void:
	move_speed = 210.0
	max_hp = 100.0
	set_weapon(GameManager.weapon_id)
	set_weapon_b(GameManager.weapon_b_id)
	hp = max_hp
	fire_cooldown = 0.0
	fire_cooldown_b = 0.0
	acquired_upgrades.clear()
	hurt_cd = 0.0
	combo = 0.0
	signal_t = 0.0
	dash_t = 0.0
	dash_charges_max = 2 if Meta.has("spare_dash") else 1
	dash_charges = dash_charges_max
	dash_recharge = 0.0
	overclock_t = 0.0
	battery = BATTERY_MAX
	broadcasting = false
	f_down = false
	bonus_angle = 0.0
	bonus_range = 0.0
	bonus_radius = 0.0
	lighthouse = false
	lighthouse_mul = 1.0
	louder = false
	darkroom = false
	overclock_leak = false
	moth_ward = false
	mote_count = 0
	spark_cd = 0.0
	stain_t = 0.0
	stains.clear()
	echo_timer = 0.0
	signal_cd = 0.0
	_ensure_hound()

func _ensure_hound() -> void:
	var existing := get_node_or_null("Hound")
	if Meta.has("hound"):
		if existing == null:
			var h := Node2D.new()
			h.name = "Hound"
			h.set_script(load("res://scripts/Hound.gd"))
			add_child(h)
	elif existing:
		existing.queue_free()

func _physics_process(delta: float) -> void:
	hurt_cd = maxf(0.0, hurt_cd - delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	fire_cooldown_b = maxf(0.0, fire_cooldown_b - delta)
	signal_t = maxf(0.0, signal_t - delta)
	dash_t = maxf(0.0, dash_t - delta)
	overclock_t = maxf(0.0, overclock_t - delta)
	echo_timer = maxf(0.0, echo_timer - delta)
	signal_cd = maxf(0.0, signal_cd - delta)
	spark_cd = maxf(0.0, spark_cd - delta)
	combo_idle += delta
	_tick_stains(delta)
	var decay := 1.2 if not louder else 0.6
	if combo_idle > 3.5 and signal_t <= 0.0:
		combo = maxf(0.0, combo - delta * decay)

	if dash_charges < dash_charges_max:
		dash_recharge += delta
		if dash_recharge >= 1.15:
			dash_charges += 1
			dash_recharge = 0.0

	if GameManager.started and GameManager.state == GameManager.State.PLAYING:
		_handle_holds(delta)
		_handle_movement()
		_refresh_cone()
		_handle_battery(delta)
		_paint_cone()
		_handle_gun()
		_handle_resonance()
		_handle_glass_echo(delta)
		_handle_signal()
		_ghost(delta)
	else:
		velocity = Vector2.ZERO
		broadcasting = false

	_update_sprite(delta)
	move_and_slide()
	if camera:
		if GameManager.shake > 0.0:
			var k := GameManager.shake / 0.18
			camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * GameManager.shake_mag * k
		else:
			camera.offset = Vector2.ZERO
	var mx := float(LevelGen.MAP_W * LevelGen.TILE)
	var my := float(LevelGen.MAP_H * LevelGen.TILE)
	global_position.x = clampf(global_position.x, 16.0, mx - 16.0)
	global_position.y = clampf(global_position.y, 16.0, my - 16.0)

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.started or GameManager.state != GameManager.State.PLAYING:
		return
	if event is InputEventKey and not event.echo:
		if event.physical_keycode == KEY_F:
			if event.pressed:
				f_down = true
				f_held = 0.0
			else:
				if f_down and f_held < 0.22:
					_tap_f()
				f_down = false
				broadcasting = false
		if event.physical_keycode == KEY_E:
			if event.pressed:
				e_down = true
				e_held = 0.0
			else:
				if e_down and e_held < 0.45:
					_tap_e()
				e_down = false
		if event.pressed and (event.physical_keycode == KEY_SHIFT or event.physical_keycode == KEY_Q):
			try_dash()
		if event.pressed and event.physical_keycode == KEY_G:
			try_plant()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		try_spark()

func _handle_holds(delta: float) -> void:
	if f_down:
		f_held += delta
		if f_held >= 0.22:
			broadcasting = battery > 1.0
	if e_down:
		e_held += delta
		if e_held >= 0.5:
			_hold_e()
			e_down = false

func _tap_f() -> void:
	if combo >= COMBO_MAX and signal_t <= 0.0:
		try_signal()
	elif combo >= 1.0:
		try_ping()

func _tap_e() -> void:
	var main := get_tree().get_first_node_in_group("level_root")
	if main and main.has_method("try_waystone"):
		main.try_waystone("rewind")

func _hold_e() -> void:
	var main := get_tree().get_first_node_in_group("level_root")
	if main and main.has_method("try_waystone"):
		main.try_waystone("turret")

func _handle_movement() -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("move_up"):
		dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("move_down"):
		dir.y += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("move_right"):
		dir.x += 1
	if dir.length() > 0.001:
		last_dir = dir.normalized()
		velocity = last_dir * move_speed
	else:
		velocity = Vector2.ZERO
	if dash_t > 0.0:
		var d := last_dir if last_dir.length() > 0.1 else Vector2.RIGHT
		velocity = d * move_speed * 3.4
	if lighthouse:
		if velocity.length() < 12.0:
			lighthouse_mul = move_toward(lighthouse_mul, 1.8, 0.35 * get_physics_process_delta_time())
		else:
			lighthouse_mul = move_toward(lighthouse_mul, 0.7, 0.5 * get_physics_process_delta_time())
	else:
		lighthouse_mul = 1.0

func try_dash() -> void:
	if dash_charges <= 0 or dash_t > 0.0:
		return
	if GameManager.state != GameManager.State.PLAYING:
		return
	dash_charges -= 1
	dash_t = 0.16
	hurt_cd = maxf(hurt_cd, 0.16)
	Audio.play("dash", -8.0)
	GameManager.bump(3.5)
	get_tree().call_group("enemies", "on_player_dashed", last_dir)

func _refresh_cone() -> void:
	var b: Dictionary = GameManager.biome if GameManager.biome.size() > 0 else LevelGen.biome(GameManager.biome_id, GameManager.current_level)
	var jam := _jammer_factor()
	var flood: bool = weapon.get("id", "") == "scatter"
	var ang := (48.0 + bonus_angle + (22.0 if flood else 0.0)) * float(b.get("cone_mul", 1.0)) * jam
	var rng := (170.0 + bonus_range) * float(b.get("cone_mul", 1.0)) * jam
	vision.cone_angle_deg = clampf(ang, 18.0, 120.0)
	vision.cone_range = clampf(rng, 80.0, 340.0)
	radius_now = (108.0 + bonus_radius) * lighthouse_mul * jam * float(b.get("radius_mul", 1.0))
	vision.radius_px = radius_now
	vision.broadcasting = broadcasting
	vision.super_on = signal_t > 0.0
	vision.flicker = bool(b.get("flicker", false))

func _jammer_factor() -> float:
	var f := 1.0
	var lanterns := GameManager.lit_count()
	for e in get_tree().get_nodes_in_group("enemies"):
		var k := str(e.get("kind"))
		if k == "jammer" and global_position.distance_to(e.global_position) < 90.0:
			f *= 0.62
		if k == "giant" and lanterns < 3 and global_position.distance_to(e.global_position) < 160.0:
			f *= 0.72
	return clampf(f, 0.4, 1.0)

func in_any_light(p: Vector2) -> bool:
	if vision.in_radius(p):
		return true
	for n in get_tree().get_nodes_in_group("lit_lights"):
		if p.distance_to(n.global_position) <= 130.0:
			return true
	for n in get_tree().get_nodes_in_group("beacons"):
		if p.distance_to(n.global_position) <= float(n.get("radius")):
			return true
	for s in stains:
		if p.distance_to(s.pos) <= float(s.r):
			return true
	return false

func in_own_radius(p: Vector2) -> bool:
	return global_position.distance_to(p) <= radius_now

func _handle_battery(delta: float) -> void:
	if broadcasting and signal_t <= 0.0:
		battery = maxf(0.0, battery - 16.0 * delta)
		if battery <= 0.0:
			broadcasting = false
	elif signal_t <= 0.0:
		var rate := 11.0
		if _near_lantern():
			rate = 24.0
		battery = minf(BATTERY_MAX, battery + rate * delta)

func _near_lantern() -> bool:
	for n in get_tree().get_nodes_in_group("lit_lights"):
		if global_position.distance_to(n.global_position) < 140.0:
			return true
	return false

func _paint_cone() -> void:
	var now := Time.get_ticks_msec() * 0.001
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("phase") == "hide":
			continue
		if vision.contains_point(e.global_position):
			e.painted_until = now + 1.2
		if str(e.get("kind")) == "giant" and e.has_method("heart_pos"):
			e.heart_exposed = vision.contains_point(e.heart_pos())

func _outside_mul() -> float:
	return 1.0 if in_any_light(global_position) else 0.72

func _gun_jam() -> float:
	var b: Dictionary = GameManager.biome
	if bool(b.get("jam_gun", false)) and not in_any_light(global_position):
		return 0.35
	return 1.0

func _handle_gun() -> void:
	var want := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("fire") or Input.is_physical_key_pressed(KEY_SPACE)
	if want:
		_try_fire(weapon, false)
		if not weapon_b.is_empty():
			_try_fire(weapon_b, true)

func _handle_resonance() -> void:
	if weapon.get("id", "") != "pulse":
		return
	if not (broadcasting or signal_t > 0.0):
		return
	_try_fire(weapon, false, true)

func _try_fire(w: Dictionary, secondary: bool, quiet: bool = false) -> void:
	if w.is_empty() or bullet_scene == null:
		return
	if secondary:
		if fire_cooldown_b > 0.0:
			return
	elif fire_cooldown > 0.0:
		return
	var mouse := get_global_mouse_position()
	var aim := (mouse - global_position).normalized()
	if aim.length() < 0.001:
		aim = Vector2.RIGHT
	var n: int = int(w.get("count", 1))
	var spread: float = float(w.get("spread", 0.05))
	var shot_dmg := float(w.get("damage", damage))
	if w.get("id", "") == weapon.get("id", ""):
		shot_dmg = damage
	shot_dmg *= _outside_mul()
	if darkroom:
		shot_dmg *= 2.4
	var rate: float = float(w.get("fire_rate", fire_rate))
	if w.get("id", "") == weapon.get("id", ""):
		rate = fire_rate
	rate *= (1.55 if overclock_t > 0.0 else 1.0) * _gun_jam()
	if secondary:
		rate *= 0.55
	for i in n:
		var bullet := bullet_scene.instantiate()
		var off := (i - (n - 1) / 2.0) * (spread / maxf(1.0, n - 1.0))
		var a := aim.rotated(off)
		bullet.global_position = global_position + a * 16.0
		bullet.vel = a * w.get("speed", 520.0)
		bullet.dmg = shot_dmg
		bullet.life = w.get("life", 0.55)
		bullet.pierce = w.get("pierce", 0)
		bullet.homing = w.get("homing", 0.0)
		bullet.lock_only = w.get("id", "") == "coil"
		bullet.darkroom = darkroom
		bullet.source = "gun"
		get_parent().add_child(bullet)
	var cd := 1.0 / maxf(0.2, rate)
	if secondary:
		fire_cooldown_b = cd
	else:
		fire_cooldown = cd
	if not quiet:
		Audio.play("fire", -10.0, 0.94 + randf() * 0.12)

func _handle_glass_echo(delta: float) -> void:
	if weapon.get("id", "") != "bow":
		return
	if not (broadcasting or signal_t > 0.0):
		return
	echo_timer -= delta
	if echo_timer > 0.0 or bullet_scene == null:
		return
	echo_timer = 0.55
	var facing := Vector2.RIGHT.rotated(vision.global_rotation)
	var origin: Vector2 = global_position + facing * vision.cone_range
	var bullet := bullet_scene.instantiate()
	bullet.global_position = origin
	bullet.vel = facing * 820.0
	bullet.dmg = damage * 0.85
	bullet.life = 0.28
	bullet.pierce = 3
	bullet.homing = 0.0
	bullet.source = "signal"
	get_parent().add_child(bullet)

func _handle_signal() -> void:
	if not (broadcasting or signal_t > 0.0):
		return
	if signal_cd > 0.0:
		return
	signal_cd = 0.08 if signal_t > 0.0 else 0.14
	var mul := 0.28 if signal_t <= 0.0 else 0.9
	if weapon.get("id", "") == "scatter":
		mul *= 0.55
	if overclock_t > 0.0 and overclock_leak:
		mul *= 1.3
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.get("phase") == "hide":
			if vision.contains_point(enemy.global_position) and enemy.has_method("_pop"):
				var nx: Vector2 = (enemy.global_position - global_position).normalized()
				enemy._pop(nx if nx.length() > 0.1 else Vector2.RIGHT)
			continue
		if not vision.contains_point(enemy.global_position):
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage * mul * _outside_mul(), "signal")

func add_combo(n: float = 1.0) -> void:
	combo = minf(COMBO_MAX, combo + n)
	combo_idle = 0.0

func try_signal() -> void:
	if combo < COMBO_MAX or signal_t > 0.0:
		return
	if GameManager.state != GameManager.State.PLAYING:
		return
	combo = 0.0
	signal_t = SIGNAL_SECS
	battery = minf(BATTERY_MAX, battery + 20.0)
	Audio.play("overcharge", -7.0)
	GameManager.bump(5.0)

func try_ping() -> void:
	if combo < 1.0:
		return
	combo = maxf(0.0, combo - 1.0)
	combo_idle = 0.0
	Audio.play("ping", -8.0)
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("phase") == "hide" and e.has_method("ping_flash"):
			e.ping_flash()

func try_plant() -> void:
	if mote_count < 3:
		return
	if GameManager.state != GameManager.State.PLAYING:
		return
	mote_count -= 3
	Audio.play("mote", -10.0)
	var main := get_tree().get_first_node_in_group("level_root")
	if main and main.has_method("plant_beacon"):
		main.plant_beacon(global_position, "puck", 4.0, 90.0)

func try_spark() -> void:
	if spark_cd > 0.0:
		return
	if GameManager.state != GameManager.State.PLAYING:
		return
	spark_cd = 6.5
	Audio.play("spark", -8.0)
	GameManager.bump(3.0)
	var aim := (get_global_mouse_position() - global_position).normalized()
	if aim.length() < 0.001:
		aim = Vector2.RIGHT
	var dest: Vector2 = global_position + aim * 128.0
	GameManager.add_puff(dest)
	var main := get_tree().get_first_node_in_group("level_root")
	if main and main.has_method("plant_beacon"):
		main.plant_beacon(dest, "spark", 4.2, 108.0)
	if main and main.has_method("light_near"):
		main.light_near(dest, 92.0)

func _tick_stains(delta: float) -> void:
	if broadcasting or signal_t > 0.0:
		stain_t -= delta
		if stain_t <= 0.0:
			stain_t = 0.38
			var aim := (get_global_mouse_position() - global_position).normalized()
			var d := 48.0 + randf() * 90.0
			stains.append({"pos": global_position + aim * d, "r": 36.0, "life": 2.1})
	var i := 0
	while i < stains.size():
		stains[i].life = float(stains[i].life) - delta
		if float(stains[i].life) <= 0.0:
			stains.remove_at(i)
		else:
			i += 1

func apply_upgrade(id: String) -> void:
	match id:
		"move_speed":
			move_speed += 38.0
		"damage":
			damage += 7.0
		"fire_rate":
			fire_rate += 0.9
		"beam_width":
			bonus_angle += 12.0
		"beam_range":
			bonus_range += 55.0
		"max_hp":
			max_hp += 20.0
			hp = minf(hp + 20.0, max_hp)
		"louder":
			louder = true
		"darkroom":
			darkroom = true
		"lighthouse":
			lighthouse = true
		"overclock_leak":
			overclock_leak = true
		"battery_cell":
			bonus_radius += 24.0
		"second_wind":
			dash_charges_max += 1
			dash_charges = dash_charges_max
		"moth_ward":
			moth_ward = true
	if not acquired_upgrades.has(id) or id in ["move_speed", "damage", "fire_rate", "beam_width", "beam_range", "max_hp", "battery_cell"]:
		acquired_upgrades.append(id)

func take_damage(amount: float) -> void:
	if GameManager.state == GameManager.State.GAME_OVER or GameManager.state == GameManager.State.VICTORY:
		return
	if hurt_cd > 0.0:
		return
	if moth_ward:
		amount *= 0.85
	hp = maxf(0.0, hp - amount)
	hurt_cd = 0.5
	combo = maxf(0.0, combo - 3.0)
	Audio.play("hurt", -6.0)
	GameManager.bump(7.0)
	if hp <= 0.0:
		GameManager.trigger_game_over()

func _ghost(delta: float) -> void:
	ghost_acc += delta
	if ghost_acc >= 0.2:
		ghost_acc = 0.0
		GameManager.ghost_log.append(global_position)

func _update_sprite(delta: float) -> void:
	var mouse := get_global_mouse_position()
	var aim := mouse - global_position
	if absf(aim.y) >= absf(aim.x):
		facing = 0 if aim.y > 0.0 else 3
	else:
		facing = 1 if aim.x < 0.0 else 2
	if velocity.length() > 12.0:
		anim += delta * 8.0
	var col := int(anim) % 4 if velocity.length() > 12.0 else 0
	sprite.frame = facing * 4 + col
	if hurt_cd > 0.0:
		sprite.modulate.a = 0.45 if int(hurt_cd * 20.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0
