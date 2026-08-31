extends CharacterBody2D

# config 
@export var move_speed: float = 220.0
@export var max_hp: float = 100.0
@export var fire_rate: float = 3.0   # shots per second
@export var damage: float = 15.0 

# state
var hp: float = max_hp
var fire_cooldown: float = 0.0 

# node refs 
@onready var vision: Node2D = $VisionCone

func _ready() -> void:
	hp = max_hp
	add_to_group("player")

func _physics_process(delta: float) -> void:
    _handle_movement() 
    _handle_firing(delta) 

# movement
func _handle_movement() -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S):
		dir.y += 1
	if Input.is_physical_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D):
		dir.x += 1 

    velocity = dir.normalized() * move_speed 
    move_and_slide() 

# combat 
func _handle_firing(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if fire_cooldown > 0.0:
		return

	var target := _nearest_visible_enemy()
	if target == null:
		return

	target.take_damage(damage)
	fire_cooldown = 1.0 / fire_rate

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

# taking damage
func take_damage(amount: float) -> void:
	hp = maxf(0.0, hp - amount)
	if hp <= 0.0:
		get_tree().reload_current_scene()   # placeholder until GameOver screen exists


 