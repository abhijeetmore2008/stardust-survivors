extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 500.0
@export var base_spawn_interval: float = 2.0

var spawn_timer: float = 0.0

func _process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = maxf(0.4, base_spawn_interval - GameManager.current_wave * 0.1)

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate()
	var player := get_tree().get_first_node_in_group("player")
	var origin: Vector2 = player.global_position if player else Vector2.ZERO
	var angle := randf() * TAU
	enemy.global_position = origin + Vector2(cos(angle), sin(angle)) * spawn_radius
	get_parent().add_child(enemy) 
