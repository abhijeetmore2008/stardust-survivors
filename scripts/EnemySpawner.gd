extends Node2D

@export var enemy_scene: PackedScene
var pending: Array = []
var spawn_timer: float = 0.4
var louder_timer: float = 4.0
var moth_timer: float = 2.8
var pressure_timer: float = 1.2

func load_level(data: Dictionary) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		e.queue_free()
	pending = data.get("spawns", []).duplicate()
	pending.sort_custom(func(a, b) -> bool:
		return not bool(a.get("hidden", false)) and bool(b.get("hidden", false))
	)
	spawn_timer = 0.45
	louder_timer = 4.0
	moth_timer = 4.5
	pressure_timer = 3.5
	if GameManager.started and pending.size() > 0:
		_spawn_next()

func giants_alive() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("kind") == "giant":
			n += 1
	for s in pending:
		if s.get("kind") == "giant":
			n += 1
	return n

func count_kind(k: String) -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if str(e.get("kind")) == k:
			n += 1
	return n

func pop_all_hidden() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("phase") == "hide" and e.has_method("_pop"):
			var player := get_tree().get_first_node_in_group("player")
			var nx := Vector2.RIGHT
			if player:
				nx = (player.global_position - e.global_position).normalized()
			e._pop(nx)

func spawn_kind(kind: String, pos: Vector2, hidden: bool = false) -> void:
	if enemy_scene == null:
		return
	var live := get_tree().get_nodes_in_group("enemies").size()
	var cap: int = LevelGen.stats(GameManager.current_level).max_alive + 1
	if live >= cap:
		return
	var enemy := enemy_scene.instantiate()
	_host().add_child(enemy)
	enemy.global_position = pos
	if enemy.has_method("setup"):
		enemy.setup(kind, GameManager.current_level, hidden)

func _host() -> Node:
	var n := get_parent().get_node_or_null("World")
	return n if n else get_parent()

func _process(delta: float) -> void:
	if not GameManager.started:
		return
	if GameManager.state != GameManager.State.PLAYING:
		return
	spawn_timer -= delta
	var live := get_tree().get_nodes_in_group("enemies").size()
	var cap: int = LevelGen.stats(GameManager.current_level).max_alive
	if spawn_timer <= 0.0 and live < cap and pending.size() > 0:
		_spawn_next()
		spawn_timer = LevelGen.stats(GameManager.current_level).interval
	_maybe_louder(delta)
	_maybe_moth(delta)
	_maybe_pressure(delta)

func _spawn_next() -> void:
	if enemy_scene == null or pending.is_empty():
		return
	var spec: Dictionary = pending.pop_front()
	var enemy := enemy_scene.instantiate()
	_host().add_child(enemy)
	enemy.global_position = spec.pos
	if enemy.has_method("setup"):
		enemy.setup(spec.kind, GameManager.current_level, spec.get("hidden", false))

func _maybe_louder(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not bool(player.get("louder")):
		return
	if float(player.get("combo")) <= 5.0:
		return
	louder_timer -= delta
	if louder_timer > 0.0:
		return
	louder_timer = 4.0
	var pos: Vector2 = player.global_position + Vector2(420, 0).rotated(randf() * TAU)
	spawn_kind("walker", pos, false)

func _maybe_moth(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var broadcasting := bool(player.get("broadcasting")) or float(player.get("signal_t")) > 0.0
	if not broadcasting:
		return
	if count_kind("moth") >= 2:
		return
	moth_timer -= delta
	if moth_timer > 0.0:
		return
	var bias := 0.08
	if GameManager.biome.has("moth_bias"):
		bias = float(GameManager.biome.moth_bias)
	if str(player.get("weapon").get("id", "")) == "scatter":
		bias += 0.12
	moth_timer = 4.8
	if randf() > bias + 0.08:
		return
	var vis = player.get("vision")
	var facing := Vector2.RIGHT
	if vis:
		facing = Vector2.RIGHT.rotated(vis.global_rotation)
	var pos: Vector2 = player.global_position + facing * 210.0 + Vector2(0, 80).rotated(randf() * TAU)
	spawn_kind("moth", pos, false)

func _visible_count() -> int:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.get("phase") != "hide":
			n += 1
	return n

func _maybe_pressure(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var broadcasting := bool(player.get("broadcasting")) or float(player.get("signal_t")) > 0.0
	if not broadcasting:
		return
	pressure_timer -= delta
	if pressure_timer > 0.0:
		return
	var lv := GameManager.current_level
	var cap: int = mini(4, LevelGen.stats(lv).max_alive)
	pressure_timer = maxf(3.6, 5.2 - lv * 0.08)
	if _visible_count() >= cap:
		return
	var kind := "walker"
	var v := randf()
	if lv >= 8 and v < 0.12:
		kind = "brute"
	elif lv >= 5 and v < 0.32:
		kind = "flanker"
	elif lv >= 2 and v < 0.58:
		kind = "rusher"
	var exit: Vector2 = player.global_position + Vector2.RIGHT * 200.0
	var root := get_tree().get_first_node_in_group("level_root")
	if root != null and root.get("level") != null:
		var lvdata = root.get("level")
		if typeof(lvdata) == TYPE_DICTIONARY and lvdata.has("exit"):
			exit = lvdata.exit
	var to_exit: Vector2 = (exit - player.global_position).normalized()
	var roll := randf()
	var dir := to_exit
	if roll < 0.55:
		dir = to_exit.rotated((randf() - 0.5) * 0.9)
	elif roll < 0.85:
		dir = to_exit.rotated((1.0 if randf() < 0.5 else -1.0) * (1.15 + randf() * 0.5))
	else:
		dir = to_exit.rotated(PI + (randf() - 0.5) * 0.7)
	var dist := 190.0 + randf() * 90.0
	var pos: Vector2 = player.global_position + dir * dist
	pos.x = clampf(pos.x, 24.0, LevelGen.MAP_W * LevelGen.TILE - 24.0)
	pos.y = clampf(pos.y, 24.0, LevelGen.MAP_H * LevelGen.TILE - 24.0)
	spawn_kind(kind, pos, false)
