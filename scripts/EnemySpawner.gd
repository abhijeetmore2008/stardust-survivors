extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 420.0

var spawn_timer: float = 0.25

func _process(delta: float) -> void:
	if not GameManager.started:
		return
	if GameManager.state != GameManager.State.PLAYING:
		return
	spawn_timer -= delta
	var live := get_tree().get_nodes_in_group("enemies").size()
	if spawn_timer <= 0.0 and live < max_alive():
		_spawn_enemy()
		spawn_timer = interval()

func interval() -> float:
	var w := GameManager.current_wave
	var haste := minf(0.35, GameManager.total_kills * 0.008)
	return maxf(0.16, 1.05 * pow(0.82, w - 1.0) - haste)

func max_alive() -> int:
	return mini(38, 5 + GameManager.current_wave * 4 + GameManager.total_kills / 12)

func pick_kind() -> int:
	var w := GameManager.current_wave
	var r := randf()
	if w >= 4 and r < 0.16 + minf(0.12, GameManager.total_kills * 0.004):
		return 3
	if w >= 3 and r < 0.38:
		return 2
	if w >= 2 and r < 0.55:
		return 1
	if r < 0.18:
		return 1
	return 0

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate()
	var player := get_tree().get_first_node_in_group("player")
	var origin: Vector2 = player.global_position if player else Vector2(640, 360)
	var angle := randf() * TAU
	enemy.global_position = origin + Vector2(cos(angle), sin(angle)) * spawn_radius
	get_parent().add_child(enemy)
	if enemy.has_method("setup"):
		enemy.setup(pick_kind(), GameManager.current_wave)
