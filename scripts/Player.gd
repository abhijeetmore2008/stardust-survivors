extends CharacterBody2D

const COMBO_MAX := 8.0
const SIGNAL_SECS := 7.0

@export var move_speed: float = 210.0
@export var max_hp: float = 100.0
@export var fire_rate: float = 4.2
@export var damage: float = 16.0
@export var bullet_scene: PackedScene

var hp: float = 100.0
var fire_cooldown: float = 0.0
var acquired_upgrades: Array[String] = []
var hurt_cd: float = 0.0
var combo: float = 0.0
var combo_idle: float = 0.0
var signal_t: float = 0.0
var anim: float = 0.0
var facing: int = 0

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
	if camera:
		camera.make_current()
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0

func _load_sprite() -> void:
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.hframes = 4
	sprite.vframes = 4
	if ResourceLoader.exists("res://sprites/player.png"):
		sprite.texture = load("res://sprites/player.png")
	elif ResourceLoader.exists("res://assets/sprites/player.png"):
		sprite.texture = load("res://assets/sprites/player.png")

func _on_run_started() -> void:
	move_speed = 210.0
	max_hp = 100.0
	fire_rate = 4.2
	damage = 16.0
	hp = max_hp
	fire_cooldown = 0.0
	acquired_upgrades.clear()
	hurt_cd = 0.0
	combo = 0.0
	signal_t = 0.0
	global_position = Vector2(640, 360)
	vision.cone_angle_deg = 48.0
	vision.cone_range = 170.0

func _physics_process(delta: float) -> void:
	hurt_cd = maxf(0.0, hurt_cd - delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	signal_t = maxf(0.0, signal_t - delta)
	combo_idle += delta
	if combo_idle > 3.5 and signal_t <= 0.0:
		combo = maxf(0.0, combo - delta * 1.2)

	if GameManager.started and GameManager.state == GameManager.State.PLAYING:
		_handle_movement()
		_handle_gun()
		if signal_t > 0.0:
			_handle_signal()
	else:
		velocity = Vector2.ZERO

	_update_sprite(delta)
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		try_signal()

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
		velocity = dir.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

func _handle_gun() -> void:
	if fire_cooldown > 0.0:
		return
	if not (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("fire") or Input.is_physical_key_pressed(KEY_SPACE)):
		return
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	var mouse := get_global_mouse_position()
	var aim := (mouse - global_position).normalized()
	if aim.length() < 0.001:
		aim = Vector2.RIGHT
	bullet.global_position = global_position + aim * 16.0
	bullet.vel = aim * 520.0
	bullet.dmg = damage
	get_parent().add_child(bullet)
	fire_cooldown = 1.0 / fire_rate

func _handle_signal() -> void:
	var target := _nearest_visible_enemy()
	if target == null:
		return
	if fire_cooldown > 0.08:
		return
	target.take_damage(damage * 1.4)
	fire_cooldown = 0.08

func _nearest_visible_enemy() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not vision.contains_point(enemy.global_position):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < best_dist:
			best_dist = d
			best = enemy
	return best

func add_combo() -> void:
	combo = minf(COMBO_MAX, combo + 1.0)
	combo_idle = 0.0

func try_signal() -> void:
	if combo < COMBO_MAX or signal_t > 0.0:
		return
	if GameManager.state != GameManager.State.PLAYING:
		return
	combo = 0.0
	signal_t = SIGNAL_SECS

func apply_upgrade(id: String) -> void:
	match id:
		"move_speed":
			move_speed += 38.0
		"damage":
			damage += 7.0
		"fire_rate":
			fire_rate += 0.9
		"beam_width":
			vision.cone_angle_deg += 12.0
		"beam_range":
			vision.cone_range += 55.0
		"max_hp":
			max_hp += 20.0
			hp = minf(hp + 20.0, max_hp)
	acquired_upgrades.append(id)

func take_damage(amount: float) -> void:
	if GameManager.state == GameManager.State.GAME_OVER:
		return
	if hurt_cd > 0.0:
		return
	hp = maxf(0.0, hp - amount)
	hurt_cd = 0.5
	combo = maxf(0.0, combo - 3.0)
	if hp <= 0.0:
		GameManager.trigger_game_over()

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
