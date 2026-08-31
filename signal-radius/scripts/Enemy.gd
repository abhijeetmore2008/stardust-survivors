extends CharacterBody2D

@export var max_hp: float = 30.0
@export var move_speed: float = 90.0
@export var contact_damage: float = 10.0

var hp: float = max_hp

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")

func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var direction := (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	if global_position.distance_to(player.global_position) < 24.0:
		if player.has_method("take_damage"):
			player.take_damage(contact_damage)

func take_damage(amount: float) -> void: 
    hp -= amount 
    if hp <= 0.0:
        GameManager .add_score(10)
        queue_free() 