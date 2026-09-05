extends CharacterBody2D

enum Kind { WALKER, RUSHER, FLANKER, BRUTE }

@export var max_hp: float = 30.0
@export var move_speed: float = 78.0
@export var contact_damage: float = 12.0

var kind: Kind = Kind.WALKER
var hp: float = 30.0
var phase: String = "chase"
var timer: float = 0.0
var orbit: float = 0.0
var flash: float = 0.0
var knock: float = 0.0
var anim: float = 0.0
var facing: int = 0
var radius: float = 11.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.hframes = 4
	sprite.vframes = 4

func setup(p_kind: Kind, wave: int) -> void:
	kind = p_kind
	phase = "orbit" if kind == Kind.FLANKER else "chase"
	timer = 0.4 + randf() * 0.5
	orbit = randf() * TAU
	flash = 0.0
	knock = 0.0
	var w := wave - 1
	match kind:
		Kind.WALKER:
			max_hp = 26.0 + w * 8.0
			move_speed = 72.0 + w * 11.0
			contact_damage = 12.0 + w * 1.5
			radius = 11.0
			sprite.texture = load("res://sprites/walker.png")
		Kind.RUSHER:
			max_hp = 20.0 + w * 6.0
			move_speed = 96.0 + w * 14.0
			contact_damage = 14.0 + w * 2.0
			radius = 10.0
			sprite.texture = load("res://sprites/rusher.png")
		Kind.FLANKER:
			max_hp = 24.0 + w * 7.0
			move_speed = 88.0 + w * 12.0
			contact_damage = 13.0 + w * 1.8
			radius = 11.0
			sprite.texture = load("res://sprites/rusher.png")
		Kind.BRUTE:
			max_hp = 70.0 + w * 18.0
			move_speed = 52.0 + w * 7.0
			contact_damage = 22.0 + w * 2.5
			radius = 16.0
			sprite.texture = load("res://sprites/brute.png")
	hp = max_hp
	sprite.hframes = 4
	sprite.vframes = 4

func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		return
	flash = maxf(0.0, flash - delta)
	knock = maxf(0.0, knock - delta)
	timer -= delta

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var to_p: Vector2 = player.global_position - global_position
	var dist := to_p.length()
	if dist < 0.001:
		dist = 0.001
	var nx := to_p / dist

	var sep := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self:
			continue
		var d: float = global_position.distance_to(other.global_position)
		if d > 0.1 and d < 36.0:
			sep += (global_position - other.global_position).normalized() * ((36.0 - d) / 36.0)

	var steer := nx
	var spd := move_speed

	if kind == Kind.RUSHER:
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
	elif kind == Kind.FLANKER:
		orbit += delta * 1.7
		var desired := 78.0
		steer = nx * (1.0 if dist > desired else -0.35) + Vector2(cos(orbit), sin(orbit)) * 0.95
		if dist < 70.0 and timer <= 0.0:
			phase = "dash"
			timer = 0.22
		if phase == "dash":
			steer = nx
			spd = move_speed * 2.4
			if timer <= 0.0:
				phase = "orbit"
				timer = 1.1
	elif kind == Kind.BRUTE:
		if dist < 48.0 and phase != "smash":
			phase = "smash"
			timer = 0.45
		if phase == "smash":
			spd = 12.0 if timer > 0.18 else move_speed * 1.8
			if timer <= 0.0:
				phase = "chase"

	if knock > 0.0:
		velocity = -nx * 140.0
	else:
		velocity = (steer.normalized() + sep * 0.85) * spd

	move_and_slide()

	if absf(velocity.y) >= absf(velocity.x):
		facing = 0 if velocity.y > 0.0 else 3
	else:
		facing = 1 if velocity.x < 0.0 else 2
	anim += delta * (14.0 if phase == "dash" else 7.0)
	sprite.frame = facing * 4 + int(anim) % 4
	sprite.modulate = Color(1, 0.6, 0.6) if flash > 0.0 else Color.WHITE
	if phase == "wind" or phase == "smash":
		sprite.modulate = Color(1.0, 0.45, 0.35)

	if dist < radius + 11.0:
		if player.has_method("take_damage"):
			if kind == Kind.BRUTE:
				if phase == "smash" and timer < 0.18:
					player.take_damage(contact_damage)
			else:
				player.take_damage(contact_damage)

func take_damage(amount: float) -> void:
	hp -= amount
	flash = 0.12
	knock = 0.08
	if hp <= 0.0:
		GameManager.add_score(25 if kind == Kind.BRUTE else 10)
		GameManager.register_kill()
		queue_free()
